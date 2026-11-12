// Import thư viện Equatable để hỗ trợ so sánh giá trị giữa các instance của state
import 'package:equatable/equatable.dart';
// Import thực thể User để truyền thông tin người dùng khi đăng ký thành công
import '../../domain/entities/user.dart';

/// ============================================================================
/// REGISTER STATE - CÁC TRẠNG THÁI GIAO DIỆN CỦA NGHIỆP VỤ ĐĂNG KÝ TÀI KHOẢN (UC-02)
/// ============================================================================

/// Lớp cơ sở trừu tượng đại diện cho tất cả các trạng thái trong quy trình Đăng ký
abstract class RegisterState extends Equatable {
  // Constructor hằng số cho lớp cha trừu tượng
  const RegisterState();

  // Danh sách các thuộc tính dùng để so sánh hai state có bằng nhau hay không
  @override
  List<Object?> get props => [];
}

/// Trạng thái khởi tạo ban đầu khi người dùng mới mở màn hình Đăng ký
class RegisterInitial extends RegisterState {
  // Constructor khởi tạo trạng thái Initial
  const RegisterInitial();
}

/// Trạng thái đang xử lý yêu cầu đăng ký (hiển thị loading spinner trên nút CTA)
class RegisterLoading extends RegisterState {
  // Constructor khởi tạo trạng thái Loading
  const RegisterLoading();
}

/// Trạng thái đăng ký tài khoản thành công
class RegisterSuccess extends RegisterState {
  // Đối tượng người dùng vừa được tạo thành công trong hệ thống
  final User user;

  // Constructor nhận thông tin user vừa tạo
  const RegisterSuccess(this.user);

  // Đưa user vào props để Equatable phân biệt sự khác nhau giữa các lần thành công
  @override
  List<Object?> get props => [user];
}

/// Trạng thái đăng ký thất bại (ví dụ: trùng email, trùng số điện thoại, lỗi mạng, lỗi database)
class RegisterFailure extends RegisterState {
  // Chuỗi thông báo lỗi chi tiết để hiển thị lên SnackBar hoặc Alert cho người dùng
  final String errorMessage;

  // Constructor nhận chuỗi thông báo lỗi
  const RegisterFailure(this.errorMessage);

  // Đưa errorMessage vào props để Equatable theo dõi thay đổi thông báo lỗi
  @override
  List<Object?> get props => [errorMessage];
}
