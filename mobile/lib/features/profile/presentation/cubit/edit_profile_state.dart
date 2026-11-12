// Import thư viện Equatable để so sánh bình đẳng theo giá trị giữa các trạng thái
import 'package:equatable/equatable.dart';
// Import thực thể UserProfileEntity chứa thông tin hồ sơ người dùng
import '../../domain/entities/user_profile_entity.dart';

/// ============================================================================
/// EDIT PROFILE STATE - CÁC TRẠNG THÁI GIAO DIỆN CHỈNH SỬA HỒ SƠ (UC-27)
/// ============================================================================

/// Lớp cơ sở trừu tượng cho tất cả các trạng thái trong quy trình Chỉnh sửa hồ sơ
abstract class EditProfileState extends Equatable {
  // Constructor hằng số cho lớp cha
  const EditProfileState();

  // Danh sách các thuộc tính để Equatable so sánh hai State
  @override
  List<Object?> get props => [];
}

/// Trạng thái khởi tạo ban đầu khi người dùng mới mở màn hình Chỉnh sửa hồ sơ
class EditProfileInitial extends EditProfileState {
  // Constructor trạng thái Initial
  const EditProfileInitial();
}

/// Trạng thái đang thực hiện lưu thông tin xuống database/mạng (hiển thị loading trên nút CTA)
class EditProfileLoading extends EditProfileState {
  // Constructor trạng thái Loading
  const EditProfileLoading();
}

/// Trạng thái cập nhật thành công, mang theo thông tin hồ sơ mới và thông báo phản hồi
class EditProfileSuccess extends EditProfileState {
  // Thực thể hồ sơ người dùng sau khi đã được lưu thành công
  final UserProfileEntity updatedProfile;

  // Chuỗi thông báo thành công hiển thị cho người dùng
  final String message;

  // Constructor nhận hồ sơ cập nhật và thông báo
  const EditProfileSuccess({
    required this.updatedProfile,
    this.message = 'Cập nhật hồ sơ thành công!',
  });

  // So sánh trạng thái theo hồ sơ cập nhật và thông điệp
  @override
  List<Object?> get props => [updatedProfile, message];
}

/// Trạng thái cập nhật thất bại, mang theo chuỗi thông điệp lỗi để hiển thị SnackBar đỏ
class EditProfileFailure extends EditProfileState {
  // Chuỗi mô tả lỗi chi tiết
  final String error;

  // Constructor nhận thông điệp lỗi
  const EditProfileFailure(this.error);

  // So sánh trạng thái theo chuỗi lỗi
  @override
  List<Object?> get props => [error];
}
