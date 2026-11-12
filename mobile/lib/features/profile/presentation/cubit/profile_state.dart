// Import thư viện Equatable để so sánh bằng giá trị giữa các trạng thái ProfileState
import 'package:equatable/equatable.dart';
// Import thực thể UserProfileEntity chứa thông tin hồ sơ
import '../../domain/entities/user_profile_entity.dart';

/// ============================================================================
/// PROFILE STATE - CÁC TRẠNG THÁI GIAO DIỆN XEM HỒ SƠ (UC-26: VIEW PROFILE)
/// ============================================================================

/// Lớp cơ sở trừu tượng cho toàn bộ trạng thái trong quy trình xem hồ sơ cá nhân
abstract class ProfileState extends Equatable {
  // Constructor hằng số cho lớp cha
  const ProfileState();

  // Danh sách các thuộc tính để Equatable so sánh hai State
  @override
  List<Object?> get props => [];
}

/// Trạng thái ban đầu khi Cubit mới được tạo và chưa có thao tác tải nào diễn ra
class ProfileInitial extends ProfileState {
  // Constructor trạng thái Initial
  const ProfileInitial();
}

/// Trạng thái đang tải dữ liệu hồ sơ cá nhân (hiển thị CircularProgressIndicator trên UI)
class ProfileLoading extends ProfileState {
  // Constructor trạng thái Loading
  const ProfileLoading();
}

/// Trạng thái đã tải dữ liệu hồ sơ thành công, mang theo dữ liệu [UserProfileEntity]
class ProfileLoaded extends ProfileState {
  // Dữ liệu thực thể hồ sơ người dùng tải về thành công
  final UserProfileEntity profile;

  // Constructor nhận thông tin hồ sơ người dùng
  const ProfileLoaded({required this.profile});

  // So sánh trạng thái theo đối tượng profile
  @override
  List<Object?> get props => [profile];
}

/// Trạng thái xảy ra lỗi khi tải hồ sơ (lỗi kết nối, không tìm thấy user, v.v.)
class ProfileError extends ProfileState {
  // Chuỗi thông báo lỗi chi tiết hiển thị cho người dùng
  final String message;

  // Constructor nhận thông báo lỗi
  const ProfileError(this.message);

  // So sánh trạng thái theo chuỗi thông báo lỗi
  @override
  List<Object?> get props => [message];
}
