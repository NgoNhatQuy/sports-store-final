// Import thực thể AddressEntity đại diện cho địa chỉ giao hàng
import '../entities/address_entity.dart';
// Import giao diện trừu tượng AddressRepository
import '../repositories/address_repository.dart';

/// ============================================================================
/// ADD ADDRESS USECASE (DOMAIN LAYER - UC-29: THÊM ĐỊA CHỈ MỚI)
/// ============================================================================
/// Đóng gói nghiệp vụ thêm một địa chỉ giao hàng mới vào sổ địa chỉ.
class AddAddressUseCase {
  // Biến lưu trữ thể hiện của AddressRepository
  final AddressRepository repository;

  // Constructor tiêm phụ thuộc repository vào UseCase
  AddAddressUseCase(this.repository);

  /// Phương thức thực thi UseCase:
  /// Nhận vào [address] mới và chuyển tiếp sang repository để lưu trữ
  Future<AddressEntity> call(AddressEntity address) async {
    // Gọi phương thức addAddress trên repository và trả về thực thể địa chỉ đã được tạo
    return await repository.addAddress(address);
  }
}
