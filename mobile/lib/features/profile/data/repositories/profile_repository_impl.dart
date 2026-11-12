// Import các lớp ngoại lệ nghiệp vụ ServerException
import '../../../../core/errors/exceptions.dart';
// Import các lớp thất bại Failure dùng cho kiến trúc Clean Architecture
import '../../../../core/errors/failures.dart';
// Import thực thể UserProfileEntity ở tầng Domain
import '../../domain/entities/user_profile_entity.dart';
// Import interface ProfileRepository mà class này triển khai
import '../../domain/repositories/profile_repository.dart';
// Import nguồn dữ liệu ProfileRemoteDataSource
import '../datasources/profile_remote_datasource.dart';
// Import mô hình dữ liệu UserProfileModel ở tầng Data
import '../models/user_profile_model.dart';

/// ============================================================================
/// PROFILE REPOSITORY IMPLEMENTATION (DATA LAYER - UC-26, UC-27)
/// ============================================================================
/// Cầu nối giữa Domain Layer (UseCase) và Data Layer (DataSource).
/// Chịu trách nhiệm:
/// 1. Nhận yêu cầu từ UseCase.
/// 2. Chuyển đổi qua lại giữa [UserProfileEntity] và [UserProfileModel].
/// 3. Gọi DataSource để truy vấn SQLite hoặc gọi API mạng.
/// 4. Bắt Exception và chuyển thành Failure phù hợp cho tầng BLoC.
class ProfileRepositoryImpl implements ProfileRepository {
  // Tham chiếu tới đối tượng nguồn dữ liệu ProfileRemoteDataSource
  final ProfileRemoteDataSource remoteDataSource;

  // Constructor tiêm ProfileRemoteDataSource vào repository
  ProfileRepositoryImpl({required this.remoteDataSource});

  /// 1. Lấy thông tin hồ sơ người dùng (UC-26: VIEW PROFILE)
  @override
  Future<UserProfileEntity> getUserProfile() async {
    try {
      // Gọi DataSource lấy model hồ sơ người dùng
      final model = await remoteDataSource.getUserProfile();
      // Trả về model (tương thích kiểu UserProfileEntity)
      return model;
    } on ServerException catch (e) {
      // Chuyển ServerException thành ServerFailure để tầng Presentation dễ xử lý
      throw ServerFailure(e.message);
    } catch (e) {
      // Bắt các ngoại lệ khác và đóng gói vào ServerFailure
      throw ServerFailure('Không thể tải thông tin cá nhân: ${e.toString()}');
    }
  }

  /// 2. Cập nhật thông tin hồ sơ người dùng (UC-27: EDIT PROFILE)
  @override
  Future<UserProfileEntity> updateUserProfile(UserProfileEntity profile) async {
    try {
      // Chuyển Entity sang Model để DataSource dễ dàng phân tích và lưu trữ
      final model = UserProfileModel.fromEntity(profile);
      // Gửi model xuống DataSource để lưu và nhận về model đã cập nhật
      final updated = await remoteDataSource.updateUserProfile(model);
      // Trả về thực thể sau cập nhật
      return updated;
    } on ServerException catch (e) {
      // Bắt ngoại lệ máy chủ và ném ServerFailure
      throw ServerFailure(e.message);
    } catch (e) {
      // Bắt ngoại lệ tổng quát và ném ServerFailure
      throw ServerFailure('Không thể cập nhật hồ sơ: ${e.toString()}');
    }
  }
}
