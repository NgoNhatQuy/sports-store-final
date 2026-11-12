// Import thư viện Material Design của Flutter
import 'package:flutter/material.dart';
// Import thư viện flutter_bloc để lắng nghe trạng thái đăng nhập AuthCubit
import 'package:flutter_bloc/flutter_bloc.dart';

// Import bảng màu giao diện chuẩn thương hiệu thể thao
import '../../../../core/constants/app_colors.dart';
// Import GetIt dependency injection
import '../../../../core/di/injection.dart';
// Import AuthService để dự phòng khởi tạo AuthRepository
import '../../../auth/data/datasources/auth_service.dart';
// Import AuthRepository để truyền vào LoginScreen
import '../../../auth/data/repositories/auth_repository.dart';
// Import AuthCubit để quản lý phiên xác thực
import '../../../auth/presentation/cubit/auth_cubit.dart';
// Import các trạng thái AuthState (Authenticated, Unauthenticated)
import '../../../auth/presentation/cubit/auth_state.dart';
// Import màn hình Đăng nhập LoginScreen
import '../../../auth/presentation/screens/login_screen.dart';
// Import màn hình danh sách Voucher
import '../../../voucher/presentation/screens/voucher_list_screen.dart';
// Import màn hình sổ địa chỉ nhận hàng AddressListScreen (CRUD Address)
import '../../../address/presentation/screens/address_list_screen.dart';
// Import màn hình lịch sử đơn hàng OrderHistoryScreen
import '../../../order/presentation/screens/order_history_screen.dart';
// Import màn hình Đổi mật khẩu
import 'change_password_screen.dart';
// Import màn hình Xem hồ sơ cá nhân UserProfileScreen (UC-26)
import 'user_profile_screen.dart';

/// ============================================================================
/// MÀN HÌNH TAB TÀI KHOẢN (PROFILE TAB SCREEN)
/// ============================================================================
/// Đóng vai trò là trung tâm quản lý tài khoản của người dùng:
/// - Khi chưa đăng nhập (Khách vãng lai): hiển thị màn hình chào mừng và nút Đăng nhập / Đăng ký.
/// - Khi đã đăng nhập: hiển thị thanh thông tin tóm tắt cá nhân (Bấm vào mở UC-26 View Profile),
///   danh mục Lịch sử đơn hàng, Kho Voucher, Sổ địa chỉ (CRUD Address), Đổi mật khẩu, Đăng xuất.
class ProfileScreen extends StatelessWidget {
  // Tiêu đề của màn hình (mặc định 'Tài khoản')
  final String title;

  // Constructor khởi tạo nhận tiêu đề tùy chọn
  const ProfileScreen({
    super.key,
    this.title = 'Tài khoản',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // Màu nền ứng dụng
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,             // Căn giữa tiêu đề
        backgroundColor: Colors.white, // Nền trắng
        elevation: 0,                  // Phẳng không bóng
      ),
      // Lắng nghe trạng thái AuthCubit để hiển thị giao diện phù hợp
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          // Nếu đã đăng nhập thành công -> Hiển thị màn hình tài khoản
          if (state is AuthAuthenticated) {
            return _buildUserView(context, state);
          }
          // Ngược lại nếu chưa đăng nhập -> Hiển thị màn hình dành cho khách vãng lai
          return _buildGuestView(context);
        },
      ),
    );
  }

  /// Nút bấm mở màn hình Lịch sử đơn hàng
  Widget _buildOrderHistoryButton(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          // Mở màn hình lịch sử đơn hàng
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const OrderHistoryScreen()),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon đơn hàng đóng khung bo tròn
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lịch sử đơn hàng',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text('Xem danh sách đơn hàng'),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }

  /// Giao diện cho Khách vãng lai (Chưa đăng nhập)
  Widget _buildGuestView(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon người dùng khách
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300, width: 2),
              ),
              child: Icon(
                Icons.person_outline_rounded,
                size: 54,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 24),
            // Lời chào
            const Text(
              'Chào mừng đến với Sports Store',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Đăng nhập để theo dõi giỏ hàng, nhận voucher ưu đãi và quản lý đơn hàng của bạn.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            // Nút bấm Đăng nhập / Đăng ký
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                onPressed: () {
                  // Điều hướng sang màn hình LoginScreen
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => LoginScreen(
                        authRepository: getIt.isRegistered<AuthRepository>()
                            ? getIt<AuthRepository>()
                            : AuthRepository(authService: AuthService()),
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Đăng nhập / Đăng ký',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Giao diện khi người dùng đã Đăng nhập thành công (AuthAuthenticated)
  Widget _buildUserView(BuildContext context, AuthAuthenticated state) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // 1. Thẻ thông tin tài khoản (Avatar, Tên, Email) - Bấm vào xem Profile chi tiết (UC-26)
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              // Chạm vào thẻ hồ sơ để mở màn hình xem chi tiết hồ sơ cá nhân UserProfileScreen (UC-26)
              Navigator.of(context).push(UserProfileScreen.route());
            },
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Avatar tròn hiển thị chữ cái đầu của tên người dùng
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: const Color(0xFFFFE8D6),
                    child: Text(
                      state.userName.isNotEmpty
                          ? state.userName.substring(0, 1).toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFE65100),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Họ và tên người dùng
                        Text(
                          state.userName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Email tài khoản
                        Text(
                          state.userEmail.isNotEmpty
                              ? state.userEmail
                              : 'user@gmail.com',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Mũi tên điều hướng sang màn hình Profile chi tiết
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.grey,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Nút mở lịch sử đơn hàng
        _buildOrderHistoryButton(context),
        const SizedBox(height: 16),

        // 2. Thẻ Kho Voucher & Ưu đãi
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              // Mở màn hình danh sách Voucher (UC-21)
              Navigator.of(context).push(VoucherListScreen.route());
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.confirmation_number_outlined,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kho Voucher & Ưu đãi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Xem mã giảm giá & freeship có sẵn',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.grey,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 3. Thẻ Sổ địa chỉ nhận hàng (CRUD Address - UC-28)
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              // Mở màn hình danh sách sổ địa chỉ nhận hàng AddressListScreen (UC-28)
              Navigator.of(context).push(AddressListScreen.route());
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.location_on_outlined,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Địa chỉ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Quản lý địa chỉ nhận đồ thể thao',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.grey,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 4. Thẻ Đổi mật khẩu
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              // Mở màn hình Đổi mật khẩu ChangePasswordScreen
              Navigator.of(context).push(ChangePasswordScreen.route());
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đổi mật khẩu',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Cập nhật mật khẩu bảo vệ tài khoản',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.grey,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 5. Thẻ Đăng xuất tài khoản
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _confirmLogout(context), // Mở dialog xác nhận đăng xuất
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFE53935),
                    size: 22,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Đăng xuất',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE53935),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Hộp thoại xác nhận đăng xuất (UC-03)
  Future<void> _confirmLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Đăng xuất',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
        actions: [
          // Nút Hủy
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          // Nút Đăng xuất xác nhận
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Đăng xuất',
              style: TextStyle(
                color: Color(0xFFE53935),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    // Nếu người dùng chọn đồng ý đăng xuất
    if (confirm == true && context.mounted) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      // Gọi AuthCubit để xóa token và đưa state về Unauthenticated
      await context.read<AuthCubit>().logout();
      if (!context.mounted) return;
      // Hiển thị thông báo hoàn tất
      messenger?.showSnackBar(
        const SnackBar(
          content: Text('Đã đăng xuất thành công'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
