// Import thực thể UserProfileEntity làm đối tượng truyền nhận dữ liệu của repository
import '../entities/user_profile_entity.dart';

/// ============================================================================
/// PROFILE REPOSITORY INTERFACE (DOMAIN LAYER - UC-26, UC-27)
/// ============================================================================
/// Hợp đồng giao tiếp (Contract) trừu tượng định nghĩa các hành động với hồ sơ người dùng.
/// Tách rời hoàn toàn tầng Domain khỏi tầng Data (SQLite, Dio HTTP, SharedPreferences).
abstract class ProfileRepository {
  /// 1. Lấy thông tin chi tiết hồ sơ của người dùng hiện tại đang đăng nhập (UC-26: XEM HỒ SƠ)
  /// Trả về một Future chứa thực thể [UserProfileEntity]
  Future<UserProfileEntity> getUserProfile();

  /// 2. Cập nhật thông tin hồ sơ người dùng và trả về hồ sơ sau khi cập nhật (UC-27: CHỈNH SỬA HỒ SƠ)
  /// Nhận vào [profile] chứa các thông tin chỉnh sửa mới và trả về [UserProfileEntity] đã cập nhật
  Future<UserProfileEntity> updateUserProfile(UserProfileEntity profile);
}
