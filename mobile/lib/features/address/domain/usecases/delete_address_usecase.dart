// Import giao diện trừu tượng AddressRepository
import '../repositories/address_repository.dart';

/// ============================================================================
/// DELETE ADDRESS USECASE (DOMAIN LAYER - UC-31: XÓA ĐỊA CHỈ)
/// ============================================================================
/// Đóng gói nghiệp vụ xóa một địa chỉ giao hàng khỏi sổ địa chỉ.
class DeleteAddressUseCase {
  // Biến lưu trữ thể hiện của AddressRepository
  final AddressRepository repository;

  // Constructor tiêm phụ thuộc repository vào UseCase
  DeleteAddressUseCase(this.repository);

  /// Phương thức thực thi UseCase:
  /// Nhận vào [addressId] của địa chỉ cần xóa và yêu cầu repository thực hiện xóa
  Future<void> call(String addressId) async {
    // Gọi phương thức deleteAddress trên repository để xóa bản ghi địa chỉ
    await repository.deleteAddress(addressId);
  }
}
