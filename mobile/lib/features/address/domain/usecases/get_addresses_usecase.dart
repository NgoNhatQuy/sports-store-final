// Import thực thể AddressEntity đại diện cho địa chỉ giao hàng
import '../entities/address_entity.dart';
// Import giao diện trừu tượng AddressRepository để UseCase gọi hàm lấy dữ liệu
import '../repositories/address_repository.dart';

/// ============================================================================
/// GET ADDRESSES USECASE (DOMAIN LAYER - UC-28: XEM SỔ ĐỊA CHỈ)
/// ============================================================================
/// Đóng gói nghiệp vụ lấy danh sách địa chỉ giao hàng của người dùng hiện tại.
class GetAddressesUseCase {
  // Biến lưu trữ thể hiện của AddressRepository được tiêm vào
  final AddressRepository repository;

  // Constructor khởi tạo nhận repository
  GetAddressesUseCase(this.repository);

  /// Phương thức thực thi UseCase: gọi trực tiếp repository để lấy danh sách địa chỉ
  Future<List<AddressEntity>> call() async {
    // Chuyển tiếp yêu cầu lấy danh sách địa chỉ sang repository và trả về kết quả
    return await repository.getAddresses();
  }
}
