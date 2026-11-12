// Import thực thể UserProfileEntity chứa thông tin hồ sơ
import '../entities/user_profile_entity.dart';
// Import interface trừu tượng ProfileRepository
import '../repositories/profile_repository.dart';

/// ============================================================================
/// UPDATE USER PROFILE USECASE (DOMAIN LAYER - UC-27: CHỈNH SỬA HỒ SƠ)
/// ============================================================================
/// Đóng gói nghiệp vụ cập nhật thông tin hồ sơ của người dùng (Họ tên, SĐT, Giới tính, v.v.).
class UpdateUserProfileUseCase {
  // Biến tham chiếu tới ProfileRepository
  final ProfileRepository repository;

  // Constructor tiêm phụ thuộc ProfileRepository vào UseCase
  UpdateUserProfileUseCase(this.repository);

  /// Kích hoạt UseCase cập nhật hồ sơ khi được gọi như một callable class:
  /// Nhận vào [profile] chứa thông tin mới và trả về [UserProfileEntity] sau khi lưu thành công
  Future<UserProfileEntity> call(UserProfileEntity profile) async {
    // Chuyển tiếp yêu cầu cập nhật hồ sơ người dùng sang repository
    return await repository.updateUserProfile(profile);
  }
}
