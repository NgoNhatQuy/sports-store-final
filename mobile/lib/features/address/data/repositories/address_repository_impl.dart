// Import thực thể AddressEntity từ Domain layer
import '../../domain/entities/address_entity.dart';
// Import giao diện trừu tượng AddressRepository mà class này triển khai
import '../../domain/repositories/address_repository.dart';
// Import nguồn dữ liệu từ xa AddressRemoteDataSource
import '../datasources/address_remote_datasource.dart';
// Import mô hình dữ liệu AddressModel ở tầng Data
import '../models/address_model.dart';

/// ============================================================================
/// ADDRESS REPOSITORY IMPLEMENTATION (DATA LAYER - SỔ ĐỊA CHỈ NHẬN HÀNG)
/// ============================================================================
/// Triển khai [AddressRepository], làm cầu nối giữa UseCase và DataSource.
class AddressRepositoryImpl implements AddressRepository {
  // Tham chiếu tới đối tượng nguồn dữ liệu DataSource
  final AddressRemoteDataSource remoteDataSource;

  // Constructor nhận vào instance của AddressRemoteDataSource
  AddressRepositoryImpl({required this.remoteDataSource});

  /// 1. Lấy toàn bộ danh sách địa chỉ nhận hàng của người dùng (UC-28)
  @override
  Future<List<AddressEntity>> getAddresses() async {
    // Gọi datasource để lấy danh sách model và trả về dưới dạng List<AddressEntity>
    return await remoteDataSource.getAddresses();
  }

  /// 2. Thêm một địa chỉ mới vào sổ địa chỉ (UC-29)
  @override
  Future<AddressEntity> addAddress(AddressEntity address) async {
    // Chuyển đổi từ Domain Entity sang Data Model trước khi gửi xuống DataSource
    final model = AddressModel.fromEntity(address);
    // Gửi model xuống DataSource để lưu và nhận lại đối tượng đã được lưu
    return await remoteDataSource.addAddress(model);
  }

  /// 3. Cập nhật thông tin địa chỉ đã tồn tại (UC-30)
  @override
  Future<AddressEntity> updateAddress(AddressEntity address) async {
    // Chuyển đổi từ Domain Entity sang Data Model
    final model = AddressModel.fromEntity(address);
    // Gửi cập nhật xuống DataSource
    return await remoteDataSource.updateAddress(model);
  }

  /// 4. Xóa địa chỉ theo ID (UC-31)
  @override
  Future<void> deleteAddress(String addressId) async {
    // Yêu cầu DataSource xóa bản ghi có ID tương ứng
    await remoteDataSource.deleteAddress(addressId);
  }

  /// 5. Đặt địa chỉ làm mặc định
  @override
  Future<void> setDefaultAddress(String addressId) async {
    // Yêu cầu DataSource cập nhật cờ mặc định
    await remoteDataSource.setDefaultAddress(addressId);
  }
}
