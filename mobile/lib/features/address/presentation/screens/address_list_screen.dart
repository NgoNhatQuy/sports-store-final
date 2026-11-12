// Import thư viện Material Design của Flutter
import 'package:flutter/material.dart';
// Import thư viện flutter_bloc để quản lý và lắng nghe AddressState
import 'package:flutter_bloc/flutter_bloc.dart';

// Import cấu hình màu sắc giao diện chuẩn thương hiệu thể thao
import '../../../../core/constants/app_colors.dart';
// Import GetIt dependency injection để tiêm AddressCubit
import '../../../../core/di/injection.dart';
// Import thực thể AddressEntity đại diện cho địa chỉ
import '../../domain/entities/address_entity.dart';
// Import AddressCubit quản lý trạng thái sổ địa chỉ
import '../cubit/address_cubit.dart';
// Import các trạng thái AddressState (Loading, Loaded, Error, Success)
import '../cubit/address_state.dart';
// Import widget thẻ hiển thị địa chỉ AddressCard
import '../widgets/address_card.dart';
// Import màn hình thêm địa chỉ mới AddAddressScreen
import 'add_address_screen.dart';
// Import màn hình chỉnh sửa địa chỉ EditAddressScreen
import 'edit_address_screen.dart';

/// ============================================================================
/// MÀN HÌNH DANH SÁCH ĐỊA CHỈ GIAO HÀNG (ADDRESS LIST SCREEN - UC-28)
/// ============================================================================
/// Màn hình này phục vụ cho cả 2 luồng:
/// 1. Quản lý sổ địa chỉ trong tab Profile (xem, thêm, sửa, xóa địa chỉ).
/// 2. Chọn địa chỉ giao hàng trong luồng thanh toán đơn hàng (Checkout flow - `isSelectMode = true`).
class AddressListScreen extends StatelessWidget {
  /// Cubit tùy chọn (nếu truyền từ ngoài vào sẽ tái sử dụng thay vì khởi tạo mới)
  final AddressCubit? cubit;

  /// Chế độ chọn địa chỉ để thanh toán hay chỉ quản lý danh sách
  final bool isSelectMode;

  /// ID của địa chỉ đang được chọn trước đó trong Checkout
  final String? selectedAddressId;

  // Constructor khởi tạo màn hình danh sách địa chỉ
  const AddressListScreen({
    super.key,
    this.cubit,
    this.isSelectMode = false,
    this.selectedAddressId,
  });

  /// Phương thức static tạo Route điều hướng đến màn hình danh sách địa chỉ.
  /// Trả về [AddressEntity?] khi người dùng ở chế độ chọn và bấm vào 1 địa chỉ.
  static Route<AddressEntity?> route({
    AddressCubit? cubit,
    bool isSelectMode = false,
    String? selectedAddressId,
  }) {
    // Trả về MaterialPageRoute bọc AddressListScreen
    return MaterialPageRoute<AddressEntity?>(
      builder: (_) => AddressListScreen(
        cubit: cubit,
        isSelectMode: isSelectMode,
        selectedAddressId: selectedAddressId,
      ),
    );
  }

  // Dựng giao diện bọc BlocProvider tương ứng
  @override
  Widget build(BuildContext context) {
    final activeCubit = cubit;
    // Nếu đã có Cubit từ màn hình cha truyền sang, tái sử dụng bằng BlocProvider.value
    if (activeCubit != null) {
      return BlocProvider.value(
        value: activeCubit,
        child: _AddressListView(
          isSelectMode: isSelectMode,
          selectedAddressId: selectedAddressId,
        ),
      );
    }

    // Nếu chưa có Cubit, khởi tạo mới thông qua GetIt và gọi ngay loadAddresses()
    return BlocProvider<AddressCubit>(
      create: (_) => getIt<AddressCubit>()..loadAddresses(),
      child: _AddressListView(
        isSelectMode: isSelectMode,
        selectedAddressId: selectedAddressId,
      ),
    );
  }
}

/// Widget hiển thị nội dung giao diện danh sách địa chỉ
class _AddressListView extends StatelessWidget {
  // Cờ xác định có đang ở chế độ chọn địa chỉ thanh toán không
  final bool isSelectMode;

  // ID của địa chỉ đang chọn trước đó
  final String? selectedAddressId;

  // Constructor nhận cờ chế độ và ID đã chọn
  const _AddressListView({required this.isSelectMode, this.selectedAddressId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // Màu nền xám nhạt thể thao
      appBar: AppBar(
        // Đổi tiêu đề thanh AppBar tùy thuộc vào chế độ chọn hay xem thông thường
        title: Text(
          isSelectMode ? 'Chọn địa chỉ nhận hàng' : 'Địa chỉ của tôi',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            fontSize: 18,
          ),
        ),
        centerTitle: true,             // Căn giữa tiêu đề
        backgroundColor: Colors.white, // Nền trắng sạch sẽ
        elevation: 0,                  // Không đổ bóng
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(), // Quay về màn hình trước
        ),
      ),
      // Lắng nghe trạng thái của AddressCubit để render giao diện
      body: BlocBuilder<AddressCubit, AddressState>(
        builder: (context, state) {
          // Trạng thái 1: Đang tải danh sách địa chỉ từ SQLite/API
          if (state is AddressLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          // Trạng thái 2: Xảy ra lỗi khi tải danh sách địa chỉ
          if (state is AddressError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center, // Căn giữa màn hình
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 54,
                      color: Colors.red.shade400, // Icon lỗi màu đỏ
                    ),
                    const SizedBox(height: 14),
                    // Hiển thị chuỗi thông báo lỗi
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    // Nút Thử lại tải lại dữ liệu
                    ElevatedButton(
                      onPressed: () =>
                          context.read<AddressCubit>().loadAddresses(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Trích xuất danh sách địa chỉ từ trạng thái hiện tại
          List<AddressEntity> addresses = [];
          if (state is AddressLoaded) {
            addresses = state.addresses;
          } else if (state is AddressAddSuccess) {
            addresses = state.addresses;
          }

          // Trạng thái 3: Danh sách rỗng chưa có địa chỉ nào -> Hiển thị Empty View
          if (addresses.isEmpty) {
            return _buildEmptyView(context);
          }

          // Trạng thái 4: Hiển thị danh sách địa chỉ dạng ListView hỗ trợ kéo làm mới (Pull-to-refresh)
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => context.read<AddressCubit>().loadAddresses(), // Tải lại danh sách
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90), // Đệm dưới 90px tránh che nút bottom
              itemCount: addresses.length,                        // Số lượng địa chỉ
              itemBuilder: (context, index) {
                final item = addresses[index];                    // Lấy địa chỉ tại vị trí index
                final isSelected = isSelectMode && item.id == selectedAddressId; // Kiểm tra có đang chọn

                return AddressCard(
                  address: item,         // Dữ liệu địa chỉ
                  isSelected: isSelected,// Trạng thái được chọn
                  onTap: () {
                    // Nếu ở chế độ chọn địa chỉ nhận hàng trong Checkout: trả item về màn Checkout
                    if (isSelectMode) {
                      Navigator.of(context).pop(item);
                    } else {
                      // Nếu ở chế độ quản lý bình thường: bấm vào để mở màn hình chỉnh sửa địa chỉ
                      final cubit = context.read<AddressCubit>();
                      Navigator.of(context).push(
                        EditAddressScreen.route(address: item, cubit: cubit),
                      );
                    }
                  },
                  onEdit: () {
                    // Nút chỉnh sửa địa chỉ
                    final cubit = context.read<AddressCubit>();
                    Navigator.of(context).push(
                      EditAddressScreen.route(address: item, cubit: cubit),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
      // Nút ghim cố định dưới chân trang: Thêm địa chỉ mới
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            // Đổ bóng ngược lên trên
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            key: const Key('addNewAddressButton'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary, // Màu chủ đạo
              foregroundColor: Colors.white,       // Chữ trắng
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 1,
            ),
            icon: const Icon(Icons.add_rounded, size: 22),
            label: const Text(
              'Thêm địa chỉ mới',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            onPressed: () async {
              // Mở màn hình Thêm địa chỉ mới kèm Cubit hiện tại
              final cubit = context.read<AddressCubit>();
              await Navigator.of(context)
                  .push(AddAddressScreen.route(cubit: cubit));
            },
          ),
        ),
      ),
    );
  }

  /// Giao diện hiển thị khi người dùng chưa lưu bất kỳ địa chỉ nào trong sổ
  Widget _buildEmptyView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Căn giữa toàn bộ
          children: [
            // Vòng tròn chứa icon địa chỉ trống
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_off_outlined,
                size: 44,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            // Tiêu đề thông báo
            const Text(
              'Chưa có địa chỉ giao hàng nào',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            // Lời nhắc nhở người dùng
            Text(
              'Hãy thêm địa chỉ nhận hàng để việc đặt đồ thể thao trở nên nhanh chóng và thuận tiện nhất.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            // Nút bấm thêm địa chỉ ngay
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
              ),
              icon: const Icon(Icons.add_location_alt_outlined, size: 20),
              label: const Text(
                'Thêm địa chỉ ngay',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              onPressed: () async {
                final cubit = context.read<AddressCubit>();
                await Navigator.of(context)
                    .push(AddAddressScreen.route(cubit: cubit));
              },
            ),
          ],
        ),
      ),
    );
  }
}
