// Import flutter_bloc để quản lý luồng trạng thái Cubit
import 'package:flutter_bloc/flutter_bloc.dart';
// Import thực thể AddressEntity và enum AddressLabel
import '../../domain/entities/address_entity.dart';
// Import nghiệp vụ thêm địa chỉ AddAddressUseCase
import '../../domain/usecases/add_address_usecase.dart';
// Import nghiệp vụ xóa địa chỉ DeleteAddressUseCase
import '../../domain/usecases/delete_address_usecase.dart';
// Import nghiệp vụ lấy danh sách địa chỉ GetAddressesUseCase
import '../../domain/usecases/get_addresses_usecase.dart';
// Import nghiệp vụ cập nhật địa chỉ UpdateAddressUseCase
import '../../domain/usecases/update_address_usecase.dart';
// Import các trạng thái AddressState
import 'address_state.dart';

/// ============================================================================
/// ADDRESS CUBIT - QUẢN LÝ TRẠNG THÁI SỔ ĐỊA CHỈ NHẬN HÀNG (UC-28, 29, 30, 31)
/// ============================================================================
/// Chịu trách nhiệm:
/// 1. Tải danh sách địa chỉ của người dùng hiện tại ([loadAddresses]).
/// 2. Thêm địa chỉ nhận hàng mới ([addAddress]).
/// 3. Cập nhật thông tin địa chỉ đã có ([updateAddress]).
/// 4. Xóa địa chỉ khỏi sổ địa chỉ ([deleteAddress]).
class AddressCubit extends Cubit<AddressState> {
  // UseCase lấy danh sách địa chỉ
  final GetAddressesUseCase getAddressesUseCase;

  // UseCase thêm địa chỉ mới
  final AddAddressUseCase addAddressUseCase;

  // UseCase cập nhật địa chỉ
  final UpdateAddressUseCase updateAddressUseCase;

  // UseCase xóa địa chỉ
  final DeleteAddressUseCase deleteAddressUseCase;

  // Constructor tiêm 4 UseCase và đặt trạng thái ban đầu là AddressInitial
  AddressCubit({
    required this.getAddressesUseCase,
    required this.addAddressUseCase,
    required this.updateAddressUseCase,
    required this.deleteAddressUseCase,
  }) : super(const AddressInitial());

  /// 1. LẤY DANH SÁCH ĐỊA CHỈ GIAO HÀNG (UC-28: VIEW ADDRESS LIST)
  Future<void> loadAddresses() async {
    // Bước 1: Phát trạng thái đang tải dữ liệu để hiển thị shimmer/loading
    emit(const AddressLoading());
    try {
      // Bước 2: Gọi UseCase lấy toàn bộ danh sách địa chỉ
      final list = await getAddressesUseCase();
      // Bước 3: Phát trạng thái đã tải thành công kèm danh sách địa chỉ
      emit(AddressLoaded(addresses: list));
    } catch (e) {
      // Bước 4: Phát trạng thái lỗi nếu xảy ra ngoại lệ
      emit(AddressError(e.toString()));
    }
  }

  /// 2. THÊM ĐỊA CHỈ GIAO HÀNG MỚI (UC-29: CREATE ADDRESS)
  Future<void> addAddress({
    required String recipientName,       // Họ tên người nhận
    required String phoneNumber,         // Số điện thoại
    required String province,            // Tỉnh / Thành phố
    required String district,            // Quận / Huyện
    required String ward,                // Phường / Xã
    required String streetAddress,       // Số nhà, tên đường
    AddressLabel label = AddressLabel.home, // Loại địa chỉ (mặc định nhà riêng)
    bool isDefault = false,              // Có đặt làm mặc định không
  }) async {
    // Bước 1: Phát trạng thái đang thêm địa chỉ
    emit(const AddressAddLoading());
    try {
      // Bước 2: Đóng gói các thông tin thành đối tượng AddressEntity
      final newAddress = AddressEntity(
        id: '',                                  // ID tạm thời rỗng, Data layer sẽ tự sinh
        recipientName: recipientName.trim(),     // Cắt khoảng trắng họ tên
        phoneNumber: phoneNumber.trim(),         // Cắt khoảng trắng SĐT
        province: province.trim(),               // Tỉnh thành
        district: district.trim(),               // Quận huyện
        ward: ward.trim(),                       // Phường xã
        streetAddress: streetAddress.trim(),     // Địa chỉ chi tiết
        label: label,                            // Phân loại địa chỉ
        isDefault: isDefault,                    // Cờ mặc định
      );

      // Bước 3: Gọi UseCase thêm địa chỉ vào cơ sở dữ liệu
      final created = await addAddressUseCase(newAddress);

      // Bước 4: Tải lại danh sách địa chỉ mới nhất sau khi thêm
      final updatedList = await getAddressesUseCase();

      // Bước 5: Phát trạng thái thêm thành công để UI phản hồi (SnackBar, pop màn hình)
      emit(AddressAddSuccess(newAddress: created, addresses: updatedList));

      // Bước 6: Chuyển ngay về trạng thái Loaded để hiển thị danh sách cập nhật
      emit(AddressLoaded(addresses: updatedList));
    } catch (e) {
      // Bước 7: Bắt lỗi và phát trạng thái thông báo lỗi
      emit(AddressError('Không thể thêm địa chỉ: ${e.toString()}'));
    }
  }

  /// 3. CẬP NHẬT THÔNG TIN ĐỊA CHỈ GIAO HÀNG (UC-30: UPDATE ADDRESS)
  Future<void> updateAddress({
    required String id,                  // Mã định danh địa chỉ cần sửa
    required String recipientName,       // Họ tên người nhận mới
    required String phoneNumber,         // Số điện thoại mới
    required String province,            // Tỉnh / Thành phố mới
    required String district,            // Quận / Huyện mới
    required String ward,                // Phường / Xã mới
    required String streetAddress,       // Số nhà tên đường mới
    AddressLabel label = AddressLabel.home, // Loại địa chỉ mới
    bool isDefault = false,              // Trạng thái mặc định mới
  }) async {
    // Bước 1: Phát trạng thái đang cập nhật
    emit(const AddressUpdateLoading());
    try {
      // Bước 2: Tạo đối tượng AddressEntity chứa dữ liệu cập nhật
      final updatedAddress = AddressEntity(
        id: id,                                  // Giữ nguyên ID của bản ghi
        recipientName: recipientName.trim(),     // Họ tên mới
        phoneNumber: phoneNumber.trim(),         // SĐT mới
        province: province.trim(),               // Tỉnh thành mới
        district: district.trim(),               // Quận huyện mới
        ward: ward.trim(),                       // Phường xã mới
        streetAddress: streetAddress.trim(),     // Đường phố mới
        label: label,                            // Phân loại mới
        isDefault: isDefault,                    // Cờ mặc định mới
      );

      // Bước 3: Gọi UseCase cập nhật dữ liệu vào SQLite/API
      final updated = await updateAddressUseCase(updatedAddress);

      // Bước 4: Lấy lại danh sách địa chỉ sau khi cập nhật
      final updatedList = await getAddressesUseCase();

      // Bước 5: Phát trạng thái cập nhật thành công
      emit(AddressUpdateSuccess(
        updatedAddress: updated,
        addresses: updatedList,
      ));

      // Bước 6: Chuyển về trạng thái Loaded để UI hiển thị danh sách mới
      emit(AddressLoaded(addresses: updatedList));
    } catch (e) {
      // Bước 7: Phát thông báo lỗi nếu xảy ra ngoại lệ
      emit(AddressError('Không thể cập nhật địa chỉ: ${e.toString()}'));
    }
  }

  /// 4. XÓA ĐỊA CHỈ KHỎI SỔ ĐỊA CHỈ (UC-31: DELETE ADDRESS)
  Future<void> deleteAddress(String addressId) async {
    // Bước 1: Phát trạng thái đang xóa
    emit(const AddressDeleteLoading());
    try {
      // Bước 2: Gọi UseCase xóa địa chỉ theo ID
      await deleteAddressUseCase(addressId);

      // Bước 3: Lấy lại danh sách địa chỉ mới nhất sau khi xóa
      final updatedList = await getAddressesUseCase();

      // Bước 4: Phát trạng thái xóa thành công
      emit(AddressDeleteSuccess(
        deletedAddressId: addressId,
        addresses: updatedList,
      ));

      // Bước 5: Cập nhật lại giao diện danh sách với dữ liệu mới
      emit(AddressLoaded(addresses: updatedList));
    } catch (e) {
      // Bước 6: Bắt lỗi nếu không thể xóa
      emit(AddressError('Không thể xóa địa chỉ: ${e.toString()}'));
    }
  }
}
