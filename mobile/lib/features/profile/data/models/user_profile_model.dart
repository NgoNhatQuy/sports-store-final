// Import thực thể UserProfileEntity từ tầng Domain làm lớp cha
import '../../domain/entities/user_profile_entity.dart';

/// ============================================================================
/// USER PROFILE MODEL - MÔ HÌNH DỮ LIỆU HỒ SƠ NGƯỜI DÙNG (DATA LAYER)
/// ============================================================================
/// Kế thừa từ [UserProfileEntity] và bổ sung các hàm phân tích JSON / ánh xạ database:
/// - [fromJson]: Phân tích Map trả về từ SQLite hoặc API Backend thành Model.
/// - [toJson]: Đóng gói Model thành Map JSON để gửi qua HTTP PUT/POST hoặc lưu trữ.
/// - [fromEntity]: Chuyển đổi từ Domain Entity sang Data Model.
class UserProfileModel extends UserProfileEntity {
  // Constructor khởi tạo UserProfileModel kế thừa toàn bộ thuộc tính từ UserProfileEntity cha
  const UserProfileModel({
    required super.id,          // Mã ID người dùng
    required super.fullname,    // Họ và tên
    required super.email,       // Địa chỉ email
    super.phoneNumber = '',     // Số điện thoại (mặc định rỗng)
    super.gender = 'Nam',       // Giới tính (mặc định Nam)
    super.dateOfBirth,          // Ngày sinh
    super.avatarUrl,            // URL ảnh đại diện
    super.createdAt,            // Thời điểm tạo tài khoản
    super.status = 'ACTIVE',    // Trạng thái tài khoản (mặc định ACTIVE)
  });

  /// Factory chuyển đổi dữ liệu từ Map (JSON API hoặc dòng bản ghi SQLite) sang [UserProfileModel]
  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    // 1. Xử lý id (hỗ trợ nhiều kiểu int hoặc string và các biến thể key id, userId, user_id)
    final rawId = json['id'] ?? json['userId'] ?? json['user_id'] ?? '';
    final id = rawId.toString(); // Ép kiểu về chuỗi String

    // 2. Xử lý họ và tên (hỗ trợ nhiều định dạng key fullname, fullName, full_name, name)
    final fullname = (json['fullname'] ??
            json['fullName'] ??
            json['full_name'] ??
            json['name'] ??
            '')
        .toString();

    // Lấy chuỗi email
    final email = (json['email'] ?? '').toString();

    // 3. Xử lý số điện thoại (hỗ trợ phoneNumber, phone_number, phone)
    final phoneNumber = (json['phoneNumber'] ??
            json['phone_number'] ??
            json['phone'] ??
            '')
        .toString();

    // 4. Xử lý giới tính: hỗ trợ boolean (true = Nam, false = Nữ) hoặc chuỗi String
    String genderStr = 'Nam';
    if (json['gender'] is bool) {
      genderStr = (json['gender'] as bool) ? 'Nam' : 'Nữ';
    } else if (json['gender'] != null) {
      genderStr = json['gender'].toString();
    }

    // 5. Xử lý ngày tạo tài khoản: epoch milliseconds (int) hoặc chuỗi ISO 8601 String
    DateTime? createdAt;
    final rawCreatedAt = json['createdAt'] ?? json['created_at'];
    if (rawCreatedAt is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(rawCreatedAt);
    } else if (rawCreatedAt is String && rawCreatedAt.isNotEmpty) {
      createdAt = DateTime.tryParse(rawCreatedAt);
    }

    // 6. Xử lý ngày sinh: epoch milliseconds (int) hoặc chuỗi ISO 8601 String
    DateTime? dob;
    final rawDob = json['dateOfBirth'] ?? json['date_of_birth'] ?? json['dob'];
    if (rawDob is int) {
      dob = DateTime.fromMillisecondsSinceEpoch(rawDob);
    } else if (rawDob is String && rawDob.isNotEmpty) {
      dob = DateTime.tryParse(rawDob);
    }

    // Lấy chuỗi URL avatar nếu có
    final avatar = (json['avatarUrl'] ?? json['avatar_url'] ?? json['avatar'])?.toString();
    // Lấy trạng thái tài khoản (mặc định là ACTIVE nếu không có)
    final status = (json['status'] ?? 'ACTIVE').toString();

    // Trả về đối tượng UserProfileModel hoàn chỉnh đã bóc tách
    return UserProfileModel(
      id: id,
      fullname: fullname,
      email: email,
      phoneNumber: phoneNumber,
      gender: genderStr,
      dateOfBirth: dob,
      avatarUrl: avatar,
      createdAt: createdAt,
      status: status,
    );
  }

  /// Chuyển đổi đối tượng Model sang Map JSON để lưu SQLite hoặc gửi HTTP Request lên server
  Map<String, dynamic> toJson() {
    return {
      'id': id,                                                              // Ghi ID
      'fullname': fullname,                                                  // Ghi họ và tên
      'email': email,                                                        // Ghi email
      'phoneNumber': phoneNumber,                                            // Ghi số điện thoại
      'gender': gender,                                                      // Ghi giới tính
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth!.toIso8601String(),// Ghi ngày sinh ISO nếu có
      if (avatarUrl != null) 'avatarUrl': avatarUrl,                          // Ghi avatar nếu có
      if (createdAt != null) 'createdAt': createdAt!.millisecondsSinceEpoch, // Ghi ngày tạo timestamp nếu có
      'status': status,                                                      // Ghi trạng thái
    };
  }

  /// Factory tạo Data Model từ Domain Entity
  factory UserProfileModel.fromEntity(UserProfileEntity entity) {
    return UserProfileModel(
      id: entity.id,                   // Sao chép ID
      fullname: entity.fullname,       // Sao chép họ tên
      email: entity.email,             // Sao chép email
      phoneNumber: entity.phoneNumber, // Sao chép số điện thoại
      gender: entity.gender,           // Sao chép giới tính
      dateOfBirth: entity.dateOfBirth, // Sao chép ngày sinh
      avatarUrl: entity.avatarUrl,     // Sao chép avatar URL
      createdAt: entity.createdAt,     // Sao chép ngày tạo
      status: entity.status,           // Sao chép trạng thái
    );
  }
}
