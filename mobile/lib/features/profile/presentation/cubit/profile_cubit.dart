// Import flutter_bloc để quản lý luồng trạng thái Cubit
import 'package:flutter_bloc/flutter_bloc.dart';
// Import thực thể UserProfileEntity chứa thông tin hồ sơ
import '../../domain/entities/user_profile_entity.dart';
// Import nghiệp vụ GetUserProfileUseCase từ tầng Domain
import '../../domain/usecases/get_user_profile_usecase.dart';
// Import các trạng thái ProfileState (Initial, Loading, Loaded, Error)
import 'profile_state.dart';

/// ============================================================================
/// PROFILE CUBIT - QUẢN LÝ TRẠNG THÁI MÀN HÌNH XEM HỒ SƠ (UC-26: VIEW PROFILE)
/// ============================================================================
/// Chịu trách nhiệm:
/// 1. Tải dữ liệu hồ sơ cá nhân khi màn hình khởi chạy (`loadProfile`).
/// 2. Hỗ trợ làm mới dữ liệu khi người dùng kéo màn hình (`refreshProfile`).
/// 3. Cập nhật trực tiếp dữ liệu hiển thị (`updateLoadedProfile`) khi nhận được
///    thông tin mới từ màn hình Chỉnh sửa hồ sơ (UC-27) mà không cần truy vấn lại DB.
class ProfileCubit extends Cubit<ProfileState> {
  /// UseCase nghiệp vụ lấy thông tin hồ sơ người dùng
  final GetUserProfileUseCase getUserProfileUseCase;

  // Constructor tiêm GetUserProfileUseCase và gán trạng thái ban đầu là ProfileInitial
  ProfileCubit({
    required this.getUserProfileUseCase,
  }) : super(const ProfileInitial());

  /// 1. Tải thông tin hồ sơ người dùng (UC-26):
  /// - Phát [ProfileLoading] để hiển thị vòng quay tiến trình.
  /// - Gọi [GetUserProfileUseCase] lấy dữ liệu từ SQLite/API.
  /// - Nếu thành công: phát [ProfileLoaded] kèm thông tin [UserProfileEntity].
  /// - Nếu có lỗi: phát [ProfileError] kèm thông điệp lỗi.
  Future<void> loadProfile() async {
    // Bước 1: Phát trạng thái Loading để hiển thị shimmer hoặc vòng tròn quay
    emit(const ProfileLoading());
    try {
      // Bước 2: Gọi UseCase truy xuất thông tin hồ sơ cá nhân
      final profile = await getUserProfileUseCase();
      // Bước 3: Phát trạng thái Loaded thành công mang theo thông tin hồ sơ
      emit(ProfileLoaded(profile: profile));
    } catch (e) {
      // Bước 4: Phát trạng thái lỗi nếu xảy ra ngoại lệ
      emit(ProfileError(e.toString()));
    }
  }

  /// 2. Làm mới hồ sơ (Pull-to-refresh):
  /// - Tải lại thông tin mới nhất mà không phát trạng thái toàn màn hình loading
  ///   để giữ trải nghiệm mượt mà cho RefreshIndicator.
  Future<void> refreshProfile() async {
    try {
      // Gọi UseCase lấy lại dữ liệu mới nhất
      final profile = await getUserProfileUseCase();
      // Phát trạng thái Loaded với dữ liệu mới
      emit(ProfileLoaded(profile: profile));
    } catch (e) {
      // Phát lỗi nếu làm mới thất bại
      emit(ProfileError(e.toString()));
    }
  }

  /// 3. Cập nhật nhanh hồ sơ đang hiển thị:
  /// - Nhận đối tượng [UserProfileEntity] đã được cập nhật thành công từ màn hình Sửa.
  /// - Phát trực tiếp [ProfileLoaded] mới giúp UI đổi tức thì mà không cần load lại từ DB.
  void updateLoadedProfile(UserProfileEntity profile) {
    // Phát ngay trạng thái Loaded với thực thể profile mới
    emit(ProfileLoaded(profile: profile));
  }
}
