// Import thực thể UserProfileEntity chứa dữ liệu hồ sơ người dùng
import '../entities/user_profile_entity.dart';
// Import interface trừu tượng ProfileRepository
import '../repositories/profile_repository.dart';

/// ============================================================================
/// GET USER PROFILE USECASE (DOMAIN LAYER - UC-26: XEM THÔNG TIN CÁ NHÂN)
/// ============================================================================
/// Đóng gói toàn bộ logic nghiệp vụ lấy thông tin hồ sơ của người dùng hiện tại đang đăng nhập.
class GetUserProfileUseCase {
  // Biến tham chiếu tới ProfileRepository được tiêm thông qua constructor
  final ProfileRepository repository;

  // Constructor tiêm ProfileRepository vào UseCase
  GetUserProfileUseCase(this.repository);

  /// Kích hoạt UseCase khi được gọi như một callable class
  /// Trả về thực thể [UserProfileEntity] hoàn chỉnh từ tầng dữ liệu
  Future<UserProfileEntity> call() async {
    // Chuyển tiếp yêu cầu lấy dữ liệu hồ sơ cá nhân sang repository
    return await repository.getUserProfile();
  }
}
