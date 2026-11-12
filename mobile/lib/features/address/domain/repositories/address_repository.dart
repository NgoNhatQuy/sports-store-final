// Import thực thể AddressEntity dùng làm kiểu dữ liệu truyền nhận trong repository
import '../entities/address_entity.dart';

/// ============================================================================
/// ADDRESS REPOSITORY INTERFACE (DOMAIN LAYER - SỔ ĐỊA CHỈ NHẬN HÀNG)
/// ============================================================================
/// Hợp đồng trừu tượng định nghĩa các hành vi nghiệp vụ CRUD trên sổ địa chỉ.
abstract class AddressRepository {
  /// 1. Phương thức lấy toàn bộ danh sách địa chỉ giao hàng của người dùng hiện tại (UC-28)
  /// Trả về một Future chứa danh sách [AddressEntity]
  Future<List<AddressEntity>> getAddresses();

  /// 2. Phương thức thêm một địa chỉ giao hàng mới vào sổ địa chỉ (UC-29)
  /// Nhận vào [address] mới và trả về thực thể [AddressEntity] đã được tạo
  Future<AddressEntity> addAddress(AddressEntity address);

  /// 3. Phương thức cập nhật thông tin địa chỉ giao hàng đã có (UC-30)
  /// Nhận vào [address] chứa thông tin mới và trả về [AddressEntity] sau cập nhật
  Future<AddressEntity> updateAddress(AddressEntity address);

  /// 4. Phương thức xóa vĩnh viễn một địa chỉ giao hàng khỏi sổ địa chỉ (UC-31)
  /// Nhận vào [addressId] định danh của địa chỉ cần xóa
  Future<void> deleteAddress(String addressId);

  /// 5. Phương thức đặt một địa chỉ làm địa chỉ nhận hàng mặc định
  /// Nhận vào [addressId] định danh của địa chỉ được chọn làm mặc định
  Future<void> setDefaultAddress(String addressId);
}
