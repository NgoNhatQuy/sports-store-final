// Import thực thể User đại diện cho dữ liệu người dùng ở tầng Domain
import '../../domain/entities/user.dart';
// Import interface AuthRepositoryInterface mà class này triển khai
import '../../domain/repositories/auth_repository_interface.dart';
// Import AuthService để gọi trực tiếp các hàm thao tác database SQLite
import '../datasources/auth_service.dart';

/// ============================================================================
/// AUTH REPOSITORY IMPLEMENTATION (DATA LAYER)
/// ============================================================================
/// Triển khai cụ thể của [AuthRepositoryInterface], đóng vai trò cầu nối
/// chuyển tiếp các yêu cầu từ UseCase sang [AuthService] để xử lý dữ liệu.
class AuthRepository implements AuthRepositoryInterface {
  // Constructor nhận vào instance của AuthService (hỗ trợ Dependency Injection)
  const AuthRepository({required this.authService});

  // Tham chiếu tới dịch vụ xác thực dữ liệu cục bộ AuthService
  final AuthService authService;

  /// Phương thức xử lý đăng nhập tài khoản
  @override
  Future<User?> login({required String email, required String password}) {
    // Gọi hàm authenticate của AuthService để tra cứu tài khoản trong cơ sở dữ liệu
    return authService.authenticate(email: email, password: password);
  }

  /// Phương thức xử lý đăng ký tài khoản người dùng mới (UC-02)
  @override
  Future<User> register({
    required String fullname,    // Họ và tên người đăng ký
    required String email,       // Địa chỉ email người đăng ký
    required String phoneNumber, // Số điện thoại liên hệ
    required String password,    // Mật khẩu tài khoản
  }) {
    // Chuyển tiếp toàn bộ tham số sang AuthService.register để kiểm tra trùng lặp và ghi vào SQLite
    return authService.register(
      fullname: fullname,       // Họ và tên
      email: email,             // Email
      phoneNumber: phoneNumber, // Số điện thoại
      password: password,       // Mật khẩu
    );
  }

  /// Phương thức xử lý đăng xuất khỏi ứng dụng
  Future<void> logout() async {
    // Mô phỏng độ trễ dọn dẹp phiên kết nối và dữ liệu xác thực cục bộ
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}
