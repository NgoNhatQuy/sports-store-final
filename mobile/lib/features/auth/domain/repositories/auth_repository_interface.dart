// Import thực thể User đại diện cho kết quả trả về của các thao tác xác thực
import '../entities/user.dart';

/// ============================================================================
/// AUTH REPOSITORY INTERFACE (DOMAIN LAYER)
/// ============================================================================
/// Giao diện trừu tượng định nghĩa các hợp đồng nghiệp vụ xác thực tài khoản.
/// Tách rời hoàn toàn tầng Domain khỏi tầng Data (SQLite, API, Cache).
abstract class AuthRepositoryInterface {
  /// Phương thức xử lý đăng nhập vào hệ thống
  /// Nhận email và password, trả về thực thể User nếu đúng thông tin hoặc null nếu thất bại
  Future<User?> login({
    required String email,    // Email tài khoản đăng nhập
    required String password, // Mật khẩu tài khoản
  });

  /// Phương thức xử lý đăng ký tài khoản mới (UC-02)
  /// Nhận đầy đủ thông tin: họ tên, email, số điện thoại, mật khẩu
  /// Trả về thực thể User mới được tạo thành công
  Future<User> register({
    required String fullname,    // Họ và tên người dùng đăng ký
    required String email,       // Địa chỉ email người dùng đăng ký
    required String phoneNumber, // Số điện thoại liên hệ
    required String password,    // Mật khẩu thiết lập cho tài khoản
  });
}
