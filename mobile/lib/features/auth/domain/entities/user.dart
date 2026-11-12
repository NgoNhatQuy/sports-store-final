// Import thư viện Equatable để so sánh bình đẳng theo giá trị thuộc tính thay vì theo con trỏ bộ nhớ
import 'package:equatable/equatable.dart';

/// ============================================================================
/// USER ENTITY (DOMAIN LAYER - AUTH & USER MANAGEMENT)
/// ============================================================================
/// Thực thể đại diện cho tài khoản người dùng trong toàn bộ ứng dụng
class User extends Equatable {
  // Constructor hằng số khởi tạo thực thể User với các thuộc tính bắt buộc và tùy chọn
  const User({
    required this.id,          // Mã định danh duy nhất của người dùng
    required this.fullname,    // Họ và tên người dùng
    required this.email,       // Địa chỉ email của người dùng
    required this.password,    // Mật khẩu (đã được lưu trữ trong DB)
    required this.createdAt,   // Thời gian khởi tạo tài khoản
    this.phoneNumber,          // Số điện thoại người dùng (tùy chọn / nullable)
  });

  // Mã định danh số nguyên duy nhất của tài khoản người dùng
  final int id;

  // Họ và tên đầy đủ hiển thị trên ứng dụng
  final String fullname;

  // Địa chỉ email duy nhất sử dụng để đăng nhập và nhận thông báo
  final String email;

  // Chuỗi mật khẩu tài khoản
  final String password;

  // Thời điểm tài khoản được khởi tạo thành công trên hệ thống
  final DateTime createdAt;

  // Số điện thoại liên hệ của người dùng
  final String? phoneNumber;

  // Danh sách các trường được dùng để so sánh hai đối tượng User bằng nhau
  @override
  List<Object?> get props => [
        id,          // So sánh mã định danh
        fullname,    // So sánh họ và tên
        email,       // So sánh email
        password,    // So sánh mật khẩu
        createdAt,   // So sánh ngày tạo
        phoneNumber, // So sánh số điện thoại
      ];
}
