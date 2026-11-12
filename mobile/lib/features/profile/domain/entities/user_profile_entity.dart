// Import thư viện Equatable để hỗ trợ so sánh hai đối tượng hồ sơ dựa trên giá trị các thuộc tính
import 'package:equatable/equatable.dart';

/// ============================================================================
/// USER PROFILE ENTITY - THỰC THỂ HỒ SƠ NGƯỜI DÙNG (DOMAIN LAYER - UC-26, UC-27)
/// ============================================================================
/// Là đối tượng cốt lõi của tầng Domain, hoàn toàn độc lập với SQLite hay API.
/// Đại diện cho toàn bộ thông tin hồ sơ của khách hàng trong ứng dụng Sports Store.
class UserProfileEntity extends Equatable {
  /// Mã định danh duy nhất của người dùng trong hệ thống (ID người dùng)
  final String id;

  /// Họ và tên đầy đủ hiển thị trên ứng dụng
  final String fullname;

  /// Địa chỉ email đăng ký tài khoản (định danh duy nhất, không thể chỉnh sửa)
  final String email;

  /// Số điện thoại liên hệ nhận hàng
  final String phoneNumber;

  /// Giới tính của người dùng: 'Nam', 'Nữ', hoặc 'Khác'
  final String gender;

  /// Ngày tháng năm sinh của người dùng (tùy chọn / nullable)
  final DateTime? dateOfBirth;

  /// Đường dẫn file ảnh cục bộ hoặc URL ảnh đại diện trên cloud
  final String? avatarUrl;

  /// Ngày tài khoản được khởi tạo (ngày bắt đầu tham gia hệ thống)
  final DateTime? createdAt;

  /// Trạng thái hoạt động của tài khoản (VD: 'ACTIVE', 'INACTIVE', 'BANNED')
  final String status;

  // Constructor khởi tạo thực thể UserProfileEntity với các giá trị mặc định hợp lý
  const UserProfileEntity({
    required this.id,          // Bắt buộc truyền ID
    required this.fullname,    // Bắt buộc truyền họ và tên
    required this.email,       // Bắt buộc truyền email
    this.phoneNumber = '',     // Mặc định chuỗi rỗng nếu chưa cập nhật
    this.gender = 'Nam',       // Mặc định là Nam
    this.dateOfBirth,          // Ngày sinh có thể null
    this.avatarUrl,            // URL ảnh đại diện có thể null
    this.createdAt,            // Thời điểm tạo tài khoản
    this.status = 'ACTIVE',    // Mặc định tài khoản kích hoạt ACTIVE
  });

  /// Phương thức sao chép và ghi đè các thuộc tính khi cần tạo thực thể mới sau chỉnh sửa (UC-27)
  UserProfileEntity copyWith({
    String? id,               // ID mới nếu có
    String? fullname,         // Họ tên mới nếu có
    String? email,            // Email mới nếu có
    String? phoneNumber,      // Số điện thoại mới nếu có
    String? gender,           // Giới tính mới nếu có
    DateTime? dateOfBirth,    // Ngày sinh mới nếu có
    String? avatarUrl,        // Ảnh đại diện mới nếu có
    DateTime? createdAt,      // Ngày tạo mới nếu có
    String? status,           // Trạng thái mới nếu có
  }) {
    // Trả về một thực thể UserProfileEntity mới với các trường được cập nhật hoặc giữ nguyên cũ
    return UserProfileEntity(
      id: id ?? this.id,
      fullname: fullname ?? this.fullname,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  // Danh sách các trường được dùng để so sánh hai instance UserProfileEntity có giống nhau không
  @override
  List<Object?> get props => [
        id,          // So sánh theo ID
        fullname,    // So sánh theo họ tên
        email,       // So sánh theo email
        phoneNumber, // So sánh theo số điện thoại
        gender,      // So sánh theo giới tính
        dateOfBirth, // So sánh theo ngày sinh
        avatarUrl,   // So sánh theo ảnh đại diện
        createdAt,   // So sánh theo ngày tạo
        status,      // So sánh theo trạng thái
      ];
}
