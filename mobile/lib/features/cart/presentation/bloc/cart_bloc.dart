import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/cart_item_entity.dart';
import '../../domain/usecases/add_to_cart_usecase.dart';
import '../../domain/usecases/clear_cart_usecase.dart';
import '../../domain/usecases/get_cart_usecase.dart';
import '../../domain/usecases/remove_from_cart_usecase.dart';
import '../../domain/usecases/update_cart_quantity_usecase.dart';
import 'cart_event.dart';
import 'cart_state.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/cart_item_entity.dart';
import '../../domain/usecases/add_to_cart_usecase.dart';
import '../../domain/usecases/clear_cart_usecase.dart';
import '../../domain/usecases/get_cart_usecase.dart';
import '../../domain/usecases/remove_from_cart_usecase.dart';
import '../../domain/usecases/update_cart_quantity_usecase.dart';
import 'cart_event.dart';
import 'cart_state.dart';

/// ============================================================================
/// USE CASES: UC-11 (Add to cart), UC-12 (View cart), UC-13 (Remove from cart)
/// Đảm nhận: Thái San Yo (CE190435)
/// Mô tả: BLoC trung tâm quản lý toàn bộ vòng đời của giỏ hàng người dùng:
///        - Nạp dữ liệu giỏ hàng từ Local Storage (SQLite / SharedPreferences)
///        - Thêm sản phẩm (cộng dồn số lượng nếu trùng biến thể Size + Màu)
///        - Cập nhật số lượng (+ / -) và tính toán lại tổng tiền VNĐ
///        - Xóa từng món (kèm dialog/dismissible) hoặc xóa toàn bộ giỏ
/// Kiến trúc: Feature-First Clean Architecture (Presentation Layer)
/// ============================================================================
class CartBloc extends Bloc<CartEvent, CartState> {
  // UseCases thuộc tầng Domain chịu trách nhiệm từng tác vụ độc lập
  final GetCartUseCase getCartUseCase;
  final AddToCartUseCase addToCartUseCase;
  final UpdateCartQuantityUseCase updateCartQuantityUseCase;
  final RemoveFromCartUseCase removeFromCartUseCase;
  final ClearCartUseCase clearCartUseCase;

  CartBloc({
    required this.getCartUseCase,
    required this.addToCartUseCase,
    required this.updateCartQuantityUseCase,
    required this.removeFromCartUseCase,
    required this.clearCartUseCase,
  }) : super(const CartInitial()) {
    // Đăng ký các handler tương ứng với từng sự kiện
    on<LoadCartEvent>(_onLoadCart);
    on<AddToCartEvent>(_onAddToCart);
    on<UpdateCartItemQuantityEvent>(_onUpdateQuantity);
    on<RemoveCartItemEvent>(_onRemoveItem);
    on<ClearCartEvent>(_onClearCart);
    on<ResetCartEvent>(_onResetCart);
  }

  /// --------------------------------------------------------------------------
  /// UC-12: Hàm _onLoadCart
  /// Mục đích: Khởi tạo dữ liệu giỏ hàng khi người dùng mở màn hình Cart hoặc khởi động app.
  /// Luồng:
  ///   1. Phát CartLoading để hiển thị vòng xoay tải dữ liệu.
  ///   2. Gọi getCartUseCase() đọc dữ liệu từ Local Storage.
  ///   3. Phát CartLoaded chứa danh sách sản phẩm (tự động tính tổng tiền & số lượng).
  /// --------------------------------------------------------------------------
  Future<void> _onLoadCart(
    LoadCartEvent event,
    Emitter<CartState> emit,
  ) async {
    emit(const CartLoading());
    try {
      final items = await getCartUseCase();
      emit(CartLoaded(items: items));
    } catch (e) {
      emit(CartError('Không thể tải giỏ hàng: ${e.toString()}'));
    }
  }

  /// --------------------------------------------------------------------------
  /// UC-11: Hàm _onAddToCart
  /// Mục đích: Xử lý sự kiện khi người dùng bấm "Thêm vào giỏ hàng" tại ProductDetailScreen.
  /// Quy luật nghiệp vụ:
  ///   - Nếu sản phẩm cùng ID + Size + Color đã có: Tăng quantity += event.item.quantity.
  ///   - Nếu chưa có: Nối vào danh sách giỏ hàng.
  ///   - Đồng bộ xuống Local Storage (Cache/SQLite).
  ///   - Phát CartLoaded kèm notificationMessage để UI hiển thị SnackBar chúc mừng.
  /// --------------------------------------------------------------------------
  Future<void> _onAddToCart(
    AddToCartEvent event,
    Emitter<CartState> emit,
  ) async {
    // Lấy danh sách item hiện có từ state
    final currentItems =
        state is CartLoaded ? (state as CartLoaded).items : <CartItemEntity>[];
    try {
      // Gọi UseCase để thực hiện kiểm tra biến thể và lưu trữ
      final updatedList = await addToCartUseCase(
        currentItems: currentItems,
        newItem: event.item,
      );
      // Phát state mới kèm thông báo SnackBar và tham chiếu món đồ vừa thêm
      emit(CartLoaded(
        items: updatedList,
        lastAddedItem: event.item,
        notificationMessage: 'Đã thêm ${event.item.name} vào giỏ hàng!',
      ));
    } catch (e) {
      emit(CartError('Không thể thêm vào giỏ hàng: ${e.toString()}'));
    }
  }

  /// --------------------------------------------------------------------------
  /// UC-12: Hàm _onUpdateQuantity
  /// Mục đích: Tăng/giảm số lượng của một món hàng (+/-) tại CartScreen.
  /// Quy luật:
  ///   - Số lượng mới phải >= 1 và <= số lượng tồn kho (stock).
  ///   - Lưu lại vào Local Storage và tự động tính lại tổng thanh toán.
  /// --------------------------------------------------------------------------
  Future<void> _onUpdateQuantity(
    UpdateCartItemQuantityEvent event,
    Emitter<CartState> emit,
  ) async {
    final currentItems =
        state is CartLoaded ? (state as CartLoaded).items : <CartItemEntity>[];
    try {
      final updatedList = await updateCartQuantityUseCase(
        currentItems: currentItems,
        itemId: event.itemId,
        newQuantity: event.quantity,
      );
      emit(CartLoaded(items: updatedList));
    } catch (e) {
      emit(CartError('Không thể cập nhật số lượng: ${e.toString()}'));
    }
  }

  /// --------------------------------------------------------------------------
  /// UC-13: Hàm _onRemoveItem
  /// Mục đích: Xóa một món đồ khỏi giỏ hàng (khi vuốt Dismissible hoặc bấm icon thùng rác).
  /// Luồng:
  ///   1. Lọc bỏ item có ID trùng khớp khỏi danh sách.
  ///   2. Cập nhật Local Storage.
  ///   3. Phát CartLoaded với danh sách mới, tổng tiền và badge icon cập nhật ngay lập tức.
  /// --------------------------------------------------------------------------
  Future<void> _onRemoveItem(
    RemoveCartItemEvent event,
    Emitter<CartState> emit,
  ) async {
    final currentItems =
        state is CartLoaded ? (state as CartLoaded).items : <CartItemEntity>[];
    try {
      final updatedList = await removeFromCartUseCase(
        currentItems: currentItems,
        itemId: event.itemId,
      );
      emit(CartLoaded(items: updatedList));
    } catch (e) {
      emit(CartError('Không thể xóa sản phẩm khỏi giỏ hàng: ${e.toString()}'));
    }
  }

  /// --------------------------------------------------------------------------
  /// UC-13: Hàm _onClearCart
  /// Mục đích: Xóa toàn bộ giỏ hàng (khi bấm nút "Xóa hết" trên AppBar hoặc sau khi đặt hàng thành công).
  /// Luồng:
  ///   1. Gọi clearCartUseCase() dọn sạch cơ sở dữ liệu giỏ hàng.
  ///   2. Phát CartLoaded(items: []) đưa giao diện về trạng thái Empty Cart.
  /// --------------------------------------------------------------------------
  Future<void> _onClearCart(
    ClearCartEvent event,
    Emitter<CartState> emit,
  ) async {
    try {
      await clearCartUseCase();
      emit(const CartLoaded(items: []));
    } catch (e) {
      emit(CartError('Không thể làm trống giỏ hàng: ${e.toString()}'));
    }
  }

  /// --------------------------------------------------------------------------
  /// Hàm: _onResetCart
  /// Mục đích: Reset state giỏ hàng trong bộ nhớ (ví dụ khi user đăng xuất Logout).
  /// --------------------------------------------------------------------------
  void _onResetCart(
    ResetCartEvent event,
    Emitter<CartState> emit,
  ) {
    emit(const CartLoaded(items: []));
  }
}
