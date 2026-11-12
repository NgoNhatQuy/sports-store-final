import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../address/domain/entities/address_entity.dart';
import '../../../address/domain/usecases/get_addresses_usecase.dart';
import '../../../voucher/domain/entities/voucher_entity.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/usecases/create_order_usecase.dart';
import 'checkout_event.dart';
import 'checkout_state.dart';

/// ============================================================================
/// USE CASE: UC-08 - Order Items (Checkout & Place Order)
/// Đảm nhận: Thái San Yo (CE190435)
/// Tầng: Presentation Layer (BLoC State Management)
/// Mô tả: Quản lý toàn bộ quy trình thanh toán và đặt hàng:
///        - Nạp địa chỉ giao hàng mặc định (kết nối UC-10/18 Sổ địa chỉ 3 cấp)
///        - Chọn phương thức thanh toán (COD / Chuyển khoản)
///        - Chọn phương thức vận chuyển (Tiêu chuẩn / Hỏa tốc)
///        - Áp dụng voucher / mã giảm giá (UC-22)
///        - Kiểm tra tính hợp lệ và gọi UseCase tạo đơn hàng gửi lên hệ thống
/// ============================================================================
class CheckoutBloc extends Bloc<CheckoutEvent, CheckoutState> {
  final CreateOrderUseCase createOrderUseCase;
  final GetAddressesUseCase? getAddressesUseCase;

  CheckoutBloc({
    required this.createOrderUseCase,
    this.getAddressesUseCase,
  }) : super(const CheckoutState()) {
    on<LoadCheckoutDataEvent>(_onLoadCheckoutData);
    on<SelectShippingAddressEvent>(_onSelectShippingAddress);
    on<SelectPaymentMethodEvent>(_onSelectPaymentMethod);
    on<SelectShippingMethodEvent>(_onSelectShippingMethod);
    on<ApplyVoucherEvent>(_onApplyVoucher);
    on<RemoveVoucherEvent>(_onRemoveVoucher);
    on<PlaceOrderEvent>(_onPlaceOrder);
  }

  /// --------------------------------------------------------------------------
  /// Hàm: _onLoadCheckoutData
  /// Mục đích: Khởi tạo thông tin thanh toán, tự động lấy địa chỉ mặc định của người dùng.
  /// --------------------------------------------------------------------------
  Future<void> _onLoadCheckoutData(
    LoadCheckoutDataEvent event,
    Emitter<CheckoutState> emit,
  ) async {
    emit(state.copyWith(
        status: CheckoutStatus.loadingAddress, clearError: true));
    try {
      AddressEntity? defaultAddress;
      if (getAddressesUseCase != null) {
        final addresses = await getAddressesUseCase!();
        if (addresses.isNotEmpty) {
          defaultAddress = addresses.firstWhere(
            (addr) => addr.isDefault,
            orElse: () => addresses.first,
          );
        }
      }
      emit(state.copyWith(
        status: CheckoutStatus.ready,
        selectedAddress: defaultAddress,
        clearError: true,
      ));
    } catch (_) {
      emit(state.copyWith(status: CheckoutStatus.ready, clearError: true));
    }
  }

  /// --------------------------------------------------------------------------
  /// Hàm: _onSelectShippingAddress
  /// Mục đích: Cập nhật địa chỉ nhận hàng được chọn từ màn hình sổ địa chỉ AddressListScreen.
  /// --------------------------------------------------------------------------
  void _onSelectShippingAddress(
    SelectShippingAddressEvent event,
    Emitter<CheckoutState> emit,
  ) {
    emit(state.copyWith(
      status: CheckoutStatus.ready,
      selectedAddress: event.address,
      clearError: true,
    ));
  }

  /// --------------------------------------------------------------------------
  /// Hàm: _onSelectPaymentMethod
  /// Mục đích: Lựa chọn phương thức thanh toán (COD - Thanh toán khi nhận hàng, VNPAY...).
  /// --------------------------------------------------------------------------
  void _onSelectPaymentMethod(
    SelectPaymentMethodEvent event,
    Emitter<CheckoutState> emit,
  ) {
    emit(state.copyWith(
      status: CheckoutStatus.ready,
      paymentMethod: event.paymentMethod,
      clearError: true,
    ));
  }

  /// --------------------------------------------------------------------------
  /// Hàm: _onSelectShippingMethod
  /// Mục đích: Lựa chọn đơn vị vận chuyển (Tiêu chuẩn / Nhanh) và cập nhật lại phí ship.
  /// --------------------------------------------------------------------------
  void _onSelectShippingMethod(
    SelectShippingMethodEvent event,
    Emitter<CheckoutState> emit,
  ) {
    double updatedDiscount = state.discountAmount;

    // Nếu đang áp dụng voucher Freeship, cập nhật lại số tiền giảm theo phí ship mới
    if (state.appliedVoucher != null &&
        state.appliedVoucher!.type == VoucherType.freeShipping) {
      final shippingFee = event.shippingMethod.fee;
      updatedDiscount = state.appliedVoucher!.discountValue > shippingFee
          ? shippingFee
          : state.appliedVoucher!.discountValue;
    }

    emit(state.copyWith(
      status: CheckoutStatus.ready,
      shippingMethod: event.shippingMethod,
      discountAmount: updatedDiscount,
      clearError: true,
    ));
  }

  // Xử lý sự kiện áp dụng voucher vào đơn hàng và tính toán số tiền giảm giá (UC-22)
  void _onApplyVoucher(
    ApplyVoucherEvent event,
    Emitter<CheckoutState> emit,
  ) {
    final voucher = event.voucher;
    final subtotal = event.subtotal;

    // 1. Kiểm tra hạn dùng
    // Kiểm tra nếu voucher đã hết hạn sử dụng thì báo lỗi và dừng xử lý
    if (voucher.isExpired) {
      emit(state.copyWith(
        status: CheckoutStatus.failure,
        errorMessage: 'Mã giảm giá "${voucher.code}" đã hết hạn sử dụng.',
      ));
      return;
    }

    // 2. Kiểm tra giá trị đơn hàng tối thiểu
    // Kiểm tra nếu tổng tiền đơn hàng chưa đạt giá trị tối thiểu thì báo lỗi và dừng xử lý
    if (subtotal < voucher.minOrderValue) {
      emit(state.copyWith(
        status: CheckoutStatus.failure,
        errorMessage:
            'Đơn hàng chưa đạt giá trị tối thiểu ${voucher.formattedMinOrder}.',
      ));
      return;
    }

    // 3. Tính toán số tiền chiết khấu
    // Tính toán số tiền giảm giá theo loại voucher (% đơn hàng, số tiền cố định, hoặc miễn phí ship)
    double calculatedDiscount = 0.0;
    final shippingFee = state.shippingMethod.fee;

    switch (voucher.type) {
      case VoucherType.percentage:
        calculatedDiscount = subtotal * (voucher.discountValue / 100);
        if (voucher.maxDiscountAmount != null &&
            calculatedDiscount > voucher.maxDiscountAmount!) {
          calculatedDiscount = voucher.maxDiscountAmount!;
        }
        break;

      case VoucherType.fixedAmount:
        calculatedDiscount = voucher.discountValue;
        if (calculatedDiscount > subtotal) {
          calculatedDiscount = subtotal;
        }
        break;

      case VoucherType.freeShipping:
        calculatedDiscount = voucher.discountValue > shippingFee
            ? shippingFee
            : voucher.discountValue;
        break;
    }

    // Cập nhật state với voucher đã chọn và số tiền chiết khấu để giao diện tính lại tổng thanh toán
    emit(state.copyWith(
      status: CheckoutStatus.ready,
      appliedVoucher: voucher,
      discountAmount: calculatedDiscount,
      clearError: true,
    ));
  }

  // Xử lý sự kiện gỡ bỏ voucher khỏi đơn hàng và khôi phục giá trị thanh toán gốc (UC-22)
  void _onRemoveVoucher(
    RemoveVoucherEvent event,
    Emitter<CheckoutState> emit,
  ) {
    // Reset voucher và mức giảm giá trong state về trạng thái ban đầu
    emit(state.copyWith(
      status: CheckoutStatus.ready,
      clearVoucher: true,
      clearError: true,
    ));
  }

  /// --------------------------------------------------------------------------
  /// UC-08: Hàm _onPlaceOrder
  /// Mục đích: Thực thi quy trình chốt đơn hàng (Place Order).
  /// Luồng xử lý nghiệp vụ:
  ///   1. Kiểm tra validation: Giỏ hàng không được rỗng (event.items.isNotEmpty).
  ///   2. Kiểm tra validation: Bắt buộc phải có địa chỉ nhận hàng (shippingAddress != null).
  ///   3. Phát state CheckoutStatus.submitting (UI vô hiệu hóa nút bấm, hiển thị loading xoay).
  ///   4. Chuyển đổi danh sách CartItemEntity thành OrderItemEntity.
  ///   5. Tính toán Tạm tính (subtotal = sum(price * quantity)).
  ///   6. Gọi createOrderUseCase(...) với các tham số: món hàng, địa chỉ, thanh toán, phí ship, giảm giá, ghi chú.
  ///   7. Nếu thành công: Phát CheckoutStatus.success(createdOrder: order).
  ///      UI sẽ lắng nghe state này để điều hướng sang OrderedScreen (hoặc OrderDetailScreen)
  ///      và kích hoạt ClearCartEvent để làm trống giỏ hàng.
  ///   8. Nếu thất bại: Phát CheckoutStatus.failure kèm thông điệp lỗi cụ thể.
  /// --------------------------------------------------------------------------
  Future<void> _onPlaceOrder(
    PlaceOrderEvent event,
    Emitter<CheckoutState> emit,
  ) async {
    // 1. Kiểm tra giỏ hàng có rỗng không
    if (event.items.isEmpty) {
      emit(state.copyWith(
        status: CheckoutStatus.failure,
        errorMessage: 'Giỏ hàng trống, không thể đặt hàng.',
      ));
      return;
    }

    // 2. Kiểm tra người dùng đã chọn địa chỉ nhận hàng chưa
    final shippingAddress = state.selectedAddress;
    if (shippingAddress == null) {
      emit(state.copyWith(
        status: CheckoutStatus.failure,
        errorMessage: 'Vui lòng chọn địa chỉ nhận hàng trước khi đặt hàng.',
      ));
      return;
    }

    // 3. Chuyển sang trạng thái submitting để UI khóa nút và hiện loading
    emit(state.copyWith(status: CheckoutStatus.submitting, clearError: true));

    try {
      // 4. Chuyển đổi danh sách CartItemEntity sang OrderItemEntity
      final orderItems = event.items
          .map((cartItem) => OrderItemEntity.fromCartItem(cartItem))
          .toList();

      // 5. Tính toán tiền tạm tính subtotal
      final subtotal = event.items.fold<double>(
        0.0,
        (sum, item) => sum + item.totalPrice,
      );

      // 6. Gọi CreateOrderUseCase gửi payload tạo đơn hàng
      final order = await createOrderUseCase(
        CreateOrderParams(
          items: orderItems,
          shippingAddress: shippingAddress,
          paymentMethod: state.paymentMethod,
          shippingMethod: state.shippingMethod,
          subtotal: subtotal,
          shippingFee: state.shippingMethod.fee,
          discountAmount: state.discountAmount,
          note: event.note?.trim().isEmpty == true ? null : event.note?.trim(),
        ),
      );

      // 7. Phát CheckoutStatus.success mang theo thực thể Order vừa được tạo
      emit(state.copyWith(
        status: CheckoutStatus.success,
        createdOrder: order,
        clearError: true,
      ));
    } catch (e) {
      // 8. Bắt lỗi (mất mạng, server timeout, hết hàng) và hiển thị thông báo lỗi
      emit(state.copyWith(
        status: CheckoutStatus.failure,
        errorMessage: 'Đặt hàng thất bại: ${e.toString()}',
      ));
    }
  }
}
