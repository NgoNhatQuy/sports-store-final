// Import thực thể AddressEntity đại diện cho địa chỉ giao hàng
import '../entities/address_entity.dart';
// Import giao diện trừu tượng AddressRepository
import '../repositories/address_repository.dart';

/// ============================================================================
/// UPDATE ADDRESS USECASE (DOMAIN LAYER - UC-30: CẬP NHẬT ĐỊA CHỈ)
/// ============================================================================
/// Đóng gói nghiệp vụ cập nhật thông tin địa chỉ giao hàng đã tồn tại.
class UpdateAddressUseCase {
  // Biến lưu trữ thể hiện của AddressRepository
  final AddressRepository repository;

  // Constructor tiêm phụ thuộc repository vào UseCase
  UpdateAddressUseCase(this.repository);

  /// Phương thức thực thi UseCase:
  /// Nhận vào [address] chứa thông tin cần cập nhật và gửi xuống repository
  Future<AddressEntity> call(AddressEntity address) async {
    // Gọi phương thức updateAddress trên repository và trả về thực thể địa chỉ sau khi cập nhật
    return await repository.updateAddress(address);
  }
}
