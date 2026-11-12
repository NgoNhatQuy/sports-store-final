// Import thư viện Equatable để so sánh bình đẳng theo giá trị thuộc tính giữa các trạng thái
import 'package:equatable/equatable.dart';
// Import thực thể AddressEntity để mang dữ liệu địa chỉ trong các trạng thái
import '../../domain/entities/address_entity.dart';

/// ============================================================================
/// ADDRESS STATE - CÁC TRẠNG THÁI GIAO DIỆN SỔ ĐỊA CHỈ (UC-28, 29, 30, 31)
/// ============================================================================

/// Lớp cơ sở trừu tượng cho tất cả các trạng thái của AddressCubit
abstract class AddressState extends Equatable {
  // Constructor hằng số cho lớp cha
  const AddressState();

  // Danh sách thuộc tính dùng để kiểm tra sự thay đổi của State
  @override
  List<Object?> get props => [];
}

/// Trạng thái khởi tạo ban đầu khi mở màn hình
class AddressInitial extends AddressState {
  // Constructor trạng thái Initial
  const AddressInitial();
}

/// Trạng thái đang tải danh sách địa chỉ từ cơ sở dữ liệu
class AddressLoading extends AddressState {
  // Constructor trạng thái Loading
  const AddressLoading();
}

/// Trạng thái đã tải danh sách địa chỉ thành công
class AddressLoaded extends AddressState {
  // Danh sách các thực thể địa chỉ nhận hàng
  final List<AddressEntity> addresses;

  // Constructor nhận danh sách địa chỉ
  const AddressLoaded({required this.addresses});

  // So sánh trạng thái dựa trên danh sách địa chỉ
  @override
  List<Object?> get props => [addresses];
}

/// Trạng thái đang thực hiện thêm địa chỉ mới (hiển thị loading trên nút lưu)
class AddressAddLoading extends AddressState {
  // Constructor trạng thái AddLoading
  const AddressAddLoading();
}

/// Trạng thái thêm địa chỉ mới thành công
class AddressAddSuccess extends AddressState {
  // Thực thể địa chỉ vừa được thêm mới thành công
  final AddressEntity newAddress;

  // Danh sách toàn bộ địa chỉ sau khi đã bổ sung địa chỉ mới
  final List<AddressEntity> addresses;

  // Constructor nhận địa chỉ mới và danh sách cập nhật
  const AddressAddSuccess({
    required this.newAddress,
    required this.addresses,
  });

  // So sánh trạng thái theo địa chỉ mới và danh sách cập nhật
  @override
  List<Object?> get props => [newAddress, addresses];
}

/// Trạng thái đang thực hiện cập nhật địa chỉ đã có
class AddressUpdateLoading extends AddressState {
  // Constructor trạng thái UpdateLoading
  const AddressUpdateLoading();
}

/// Trạng thái cập nhật thông tin địa chỉ thành công
class AddressUpdateSuccess extends AddressState {
  // Thực thể địa chỉ sau khi được cập nhật
  final AddressEntity updatedAddress;

  // Danh sách toàn bộ địa chỉ sau khi cập nhật
  final List<AddressEntity> addresses;

  // Constructor nhận địa chỉ cập nhật và danh sách cập nhật
  const AddressUpdateSuccess({
    required this.updatedAddress,
    required this.addresses,
  });

  // So sánh trạng thái theo địa chỉ cập nhật và danh sách
  @override
  List<Object?> get props => [updatedAddress, addresses];
}

/// Trạng thái đang thực hiện xóa địa chỉ khỏi hệ thống
class AddressDeleteLoading extends AddressState {
  // Constructor trạng thái DeleteLoading
  const AddressDeleteLoading();
}

/// Trạng thái xóa địa chỉ thành công
class AddressDeleteSuccess extends AddressState {
  // Mã định danh của địa chỉ vừa bị xóa
  final String deletedAddressId;

  // Danh sách các địa chỉ còn lại sau khi xóa
  final List<AddressEntity> addresses;

  // Constructor nhận ID đã xóa và danh sách còn lại
  const AddressDeleteSuccess({
    required this.deletedAddressId,
    required this.addresses,
  });

  // So sánh trạng thái theo ID bị xóa và danh sách
  @override
  List<Object?> get props => [deletedAddressId, addresses];
}

/// Trạng thái xảy ra lỗi trong quá trình thao tác địa chỉ (thêm/sửa/xóa/tải)
class AddressError extends AddressState {
  // Chuỗi thông báo lỗi chi tiết hiển thị cho người dùng
  final String message;

  // Constructor nhận thông báo lỗi
  const AddressError(this.message);

  // So sánh trạng thái theo thông báo lỗi
  @override
  List<Object?> get props => [message];
}
