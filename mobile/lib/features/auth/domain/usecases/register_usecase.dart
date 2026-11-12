// Import thực thể User đại diện cho thông tin người dùng trong hệ thống
import '../entities/user.dart';
// Import interface của AuthRepository để UseCase gọi hàm đăng ký mà không phụ thuộc vào data layer cụ thể
import '../repositories/auth_repository_interface.dart';

/// ============================================================================
/// REGISTER PARAMS & USECASE (DOMAIN LAYER - UC-02: ĐĂNG KÝ TÀI KHOẢN)
/// ============================================================================

/// Lớp đóng gói các tham số đầu vào cần thiết cho nghiệp vụ đăng ký tài khoản
class RegisterParams {
  // Họ và tên đầy đủ của người đăng ký
  final String fullname;

  // Địa chỉ email của người đăng ký (dùng làm tài khoản đăng nhập)
  final String email;

  // Số điện thoại liên lạc của người đăng ký
  final String phoneNumber;

  // Mật khẩu tài khoản mà người dùng thiết lập
  final String password;

  // Constructor khởi tạo đối tượng RegisterParams với các trường bắt buộc (required)
  const RegisterParams({
    required this.fullname,     // Yêu cầu truyền họ tên
    required this.email,        // Yêu cầu truyền email
    required this.phoneNumber,  // Yêu cầu truyền số điện thoại
    required this.password,     // Yêu cầu truyền mật khẩu
  });
}

/// UseCase nghiệp vụ Đăng ký tài khoản:
/// Đóng gói toàn bộ logic kích hoạt việc tạo tài khoản mới từ phía Domain layer.
class RegisterUseCase {
  // Tham chiếu tới repository interface để tương tác với tầng dữ liệu
  final AuthRepositoryInterface repository;

  // Constructor tiêm (inject) repository interface vào UseCase
  RegisterUseCase(this.repository);

  /// Phương thức thực thi UseCase khi được gọi như một hàm (callable class)
  /// Nhận vào [params] chứa các thông tin đăng ký và trả về Future chứa thực thể [User]
  Future<User> call(RegisterParams params) {
    // Ủy quyền cho repository thực hiện đăng ký với các tham số tương ứng
    return repository.register(
      fullname: params.fullname,       // Truyền họ tên
      email: params.email,             // Truyền email
      phoneNumber: params.phoneNumber, // Truyền số điện thoại
      password: params.password,       // Truyền mật khẩu
    );
  }
}
