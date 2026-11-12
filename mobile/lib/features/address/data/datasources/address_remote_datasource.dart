// Import thư viện chuẩn json chuyển đổi dữ liệu chuỗi và Map
import 'dart:convert';
// Import thư viện Dio để gửi các request HTTP mạng
import 'package:dio/dio.dart';
// Import SharedPreferences để lưu trữ cục bộ khi chạy offline hoặc mock
import 'package:shared_preferences/shared_preferences.dart';

// Import cấu hình API endpoints
import '../../../../core/constants/api_endpoints.dart';
// Import ngoại lệ máy chủ ServerException của dự án
import '../../../../core/errors/exceptions.dart';
// Import AddressModel đại diện cho cấu trúc dữ liệu địa chỉ
import '../models/address_model.dart';
// Import AddressLabel từ Domain layer
import '../../domain/entities/address_entity.dart';

/// ============================================================================
/// ADDRESS REMOTE DATA SOURCE (TƯƠNG TÁC API BACKEND & DỰ PHÒNG OFFLINE)
/// ============================================================================
/// Giao diện trừu tượng định nghĩa các hành động lấy, thêm, sửa, xóa địa chỉ từ API
abstract class AddressRemoteDataSource {
  // Lấy danh sách địa chỉ từ máy chủ API
  Future<List<AddressModel>> getAddresses();

  // Thêm địa chỉ mới lên máy chủ API
  Future<AddressModel> addAddress(AddressModel address);

  // Cập nhật thông tin địa chỉ trên máy chủ API
  Future<AddressModel> updateAddress(AddressModel address);

  // Xóa địa chỉ trên máy chủ API theo ID
  Future<void> deleteAddress(String addressId);

  // Thiết lập địa chỉ mặc định trên máy chủ API
  Future<void> setDefaultAddress(String addressId);
}

/// Triển khai nguồn dữ liệu từ xa kết hợp lưu trữ SharedPreferences làm bộ nhớ đệm
class AddressRemoteDataSourceImpl implements AddressRemoteDataSource {
  // Khóa lưu danh sách địa chỉ trong SharedPreferences
  static const String _storageKey = 'sports_store_shipping_addresses_v1';

  // Client gọi HTTP API Dio
  final Dio dio;

  // Đối tượng truy cập SharedPreferences
  final SharedPreferences sharedPreferences;

  // Constructor khởi tạo nhận Dio và SharedPreferences
  AddressRemoteDataSourceImpl({
    required this.dio,
    required this.sharedPreferences,
  });

  /// 1. LẤY DANH SÁCH ĐỊA CHỈ TỪ API HOẶC BỘ NHỚ CỤC BỘ
  @override
  Future<List<AddressModel>> getAddresses() async {
    try {
      // Gửi yêu cầu GET đến endpoint danh sách địa chỉ
      final response = await dio.get(ApiEndpoints.addresses);
      // Nếu mã trạng thái là 200 OK
      if (response.statusCode == 200) {
        // Lấy dữ liệu phản hồi
        final data = response.data;
        // Bóc tách danh sách các item từ response map hoặc list trực tiếp
        final List<dynamic> items = data is Map<String, dynamic>
            ? (data['data'] as List<dynamic>? ?? data['items'] as List<dynamic>? ?? [])
            : (data as List<dynamic>? ?? []);
        // Ánh xạ từng phần tử sang AddressModel
        final list = items
            .map((item) => AddressModel.fromJson(item as Map<String, dynamic>))
            .toList();
        // Đồng bộ lưu danh sách vào SharedPreferences
        await _saveToLocal(list);
        // Trả về danh sách địa chỉ
        return list;
      } else {
        // Ném ngoại lệ lỗi máy chủ nếu status code khác 200
        throw ServerException(
          message: 'Lỗi máy chủ khi lấy danh sách địa chỉ: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException {
      // Nếu mất mạng hoặc backend chưa sẵn sàng, đọc dữ liệu từ SharedPreferences dự phòng
      return _getLocalAddresses();
    } catch (e) {
      // Nếu là ngoại lệ ServerException đã ném thì tiếp tục rethrow
      if (e is ServerException) rethrow;
      // Với các lỗi khác, đọc dữ liệu từ SharedPreferences để app không bị crash
      return _getLocalAddresses();
    }
  }

  /// 2. THÊM ĐỊA CHỈ MỚI LÊN MÁY CHỦ HOẶC LƯU LOCAL NẾU CHƯA CÓ BACKEND
  @override
  Future<AddressModel> addAddress(AddressModel address) async {
    try {
      // Gửi yêu cầu POST chứa dữ liệu địa chỉ mới lên API
      final response = await dio.post(
        ApiEndpoints.addresses,
        data: address.toJson(),
      );
      // Nếu thêm thành công (mã 200 hoặc 201 Created)
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        // Bóc tách JSON đối tượng vừa tạo
        final json = data is Map<String, dynamic> && data.containsKey('data')
            ? data['data'] as Map<String, dynamic>
            : data as Map<String, dynamic>;
        // Tạo đối tượng AddressModel từ JSON phản hồi
        final created = AddressModel.fromJson(json);
        // Đồng bộ vào bộ nhớ đệm SharedPreferences
        await _syncAddLocal(created);
        // Trả về đối tượng vừa tạo
        return created;
      }
    } on DioException {
      // Khi gặp lỗi mạng hoặc backend chưa nối, chuyển sang lưu trực tiếp vào SharedPreferences
    } catch (_) {
      // Bỏ qua ngoại lệ khác và tiếp tục lưu dự phòng
    }

    // Xử lý tạo ID tự động nếu địa chỉ chưa có mã định danh
    final resolvedAddress = address.id.isEmpty
        ? AddressModel(
            id: 'addr_${DateTime.now().millisecondsSinceEpoch}', // Sinh ID theo timestamp
            recipientName: address.recipientName,
            phoneNumber: address.phoneNumber,
            province: address.province,
            district: address.district,
            ward: address.ward,
            streetAddress: address.streetAddress,
            label: address.label,
            isDefault: address.isDefault,
          )
        : address;

    // Lưu vào SharedPreferences
    await _syncAddLocal(resolvedAddress);
    // Trả về địa chỉ vừa thêm
    return resolvedAddress;
  }

  /// 3. CẬP NHẬT ĐỊA CHỈ TRONG BỘ NHỚ ĐỆM
  @override
  Future<AddressModel> updateAddress(AddressModel address) async {
    // Lấy danh sách địa chỉ hiện tại từ bộ nhớ
    final list = _getLocalAddresses();
    // Tìm vị trí của địa chỉ cần sửa theo ID
    final index = list.indexWhere((a) => a.id == address.id);
    // Nếu tìm thấy địa chỉ trong danh sách
    if (index != -1) {
      // Sao chép danh sách để chỉnh sửa an toàn
      var updatedList = List<AddressModel>.from(list);
      // Nếu địa chỉ này được đặt làm mặc định
      if (address.isDefault) {
        // Cập nhật lại toàn bộ danh sách, chỉ có địa chỉ này giữ cờ isDefault: true
        updatedList = updatedList
            .map((a) => a.copyWith(isDefault: a.id == address.id))
            .map((e) => AddressModel.fromEntity(e))
            .toList();
      }
      // Gán địa chỉ mới vào vị trí tương ứng
      updatedList[index] = address;
      // Lưu lại danh sách mới vào SharedPreferences
      await _saveToLocal(updatedList);
    }
    // Trả về địa chỉ sau cập nhật
    return address;
  }

  /// 4. XÓA ĐỊA CHỈ KHỎI BỘ NHỚ ĐỆM
  @override
  Future<void> deleteAddress(String addressId) async {
    // Lấy danh sách địa chỉ hiện tại
    final list = _getLocalAddresses();
    // Lọc bỏ địa chỉ có ID trùng khớp với địa chỉ cần xóa
    final updatedList = list.where((a) => a.id != addressId).toList();
    // Nếu sau khi xóa, danh sách còn phần tử nhưng không có địa chỉ nào là mặc định
    if (updatedList.isNotEmpty && !updatedList.any((a) => a.isDefault)) {
      // Tự động gán địa chỉ đầu tiên làm địa chỉ mặc định mới
      final first = updatedList.first;
      updatedList[0] = AddressModel.fromEntity(first.copyWith(isDefault: true));
    }
    // Lưu lại danh sách mới vào bộ nhớ SharedPreferences
    await _saveToLocal(updatedList);
  }

  /// 5. ĐẶT ĐỊA CHỈ LÀM MẶC ĐỊNH
  @override
  Future<void> setDefaultAddress(String addressId) async {
    // Lấy danh sách địa chỉ hiện tại
    final list = _getLocalAddresses();
    // Duyệt qua từng địa chỉ và cập nhật cờ isDefault: true nếu id == addressId, ngược lại là false
    final updatedList = list.map((a) {
      final isDef = a.id == addressId;
      return AddressModel.fromEntity(a.copyWith(isDefault: isDef));
    }).toList();
    // Lưu lại danh sách vào SharedPreferences
    await _saveToLocal(updatedList);
  }

  // --- CÁC HÀM TIỆN ÍCH HỖ TRỢ LƯU TRỮ VỚI SHAREDPREFERENCES ---

  /// Lấy danh sách địa chỉ từ SharedPreferences, nếu chưa có thì khởi tạo danh sách mẫu
  List<AddressModel> _getLocalAddresses() {
    // Đọc chuỗi JSON từ SharedPreferences
    final rawJson = sharedPreferences.getString(_storageKey);
    // Nếu có chuỗi dữ liệu hợp lệ
    if (rawJson != null && rawJson.trim().isNotEmpty) {
      try {
        // Giải mã JSON sang danh sách List
        final List<dynamic> decoded = jsonDecode(rawJson) as List<dynamic>;
        // Ánh xạ sang danh sách AddressModel
        return decoded
            .map((item) => AddressModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    // Dữ liệu địa chỉ mẫu ban đầu chuẩn thông tin Việt Nam
    final initialList = [
      // Địa chỉ nhà riêng mẫu mặc định
      const AddressModel(
        id: 'addr_sample_01',
        recipientName: 'Trần Hoàng Nhật',
        phoneNumber: '0905123456',
        province: 'TP. Hồ Chí Minh',
        district: 'Quận 1',
        ward: 'Phường Bến Nghé',
        streetAddress: '123 Đường Lê Duẩn',
        label: AddressLabel.home,
        isDefault: true,
      ),
      // Địa chỉ văn phòng mẫu phụ
      const AddressModel(
        id: 'addr_sample_02',
        recipientName: 'Trần Hoàng Nhật',
        phoneNumber: '0905123456',
        province: 'TP. Hồ Chí Minh',
        district: 'Quận 7',
        ward: 'Phường Tân Phong',
        streetAddress: 'Tòa nhà văn phòng Cobi Tower, Đường Hoàng Văn Thái',
        label: AddressLabel.office,
        isDefault: false,
      ),
    ];

    // Lưu dữ liệu mẫu này vào SharedPreferences để dùng cho các lần sau
    _saveToLocal(initialList);
    // Trả về danh sách mẫu
    return initialList;
  }

  /// Đồng bộ thêm một địa chỉ mới vào danh sách trong SharedPreferences
  Future<void> _syncAddLocal(AddressModel newAddress) async {
    // Lấy danh sách hiện tại
    final list = _getLocalAddresses();
    var updatedList = List<AddressModel>.from(list);

    // Nếu địa chỉ mới được đặt làm mặc định hoặc danh sách đang rỗng
    if (newAddress.isDefault || updatedList.isEmpty) {
      // Hủy cờ mặc định của tất cả các địa chỉ cũ
      updatedList = updatedList
          .map((a) => AddressModel.fromEntity(a.copyWith(isDefault: false)))
          .toList();
      // Đặt cờ mặc định cho địa chỉ mới và chèn lên đầu danh sách
      final forcedDefault = newAddress.copyWith(isDefault: true);
      updatedList.insert(0, AddressModel.fromEntity(forcedDefault));
    } else {
      // Nếu không phải mặc định thì thêm vào cuối danh sách
      updatedList.add(newAddress);
    }

    // Lưu danh sách sau khi bổ sung vào SharedPreferences
    await _saveToLocal(updatedList);
  }

  /// Mã hóa và lưu danh sách AddressModel thành chuỗi JSON trong SharedPreferences
  Future<void> _saveToLocal(List<AddressModel> list) async {
    // Mã hóa danh sách model sang chuỗi JSON string
    final raw = jsonEncode(list.map((e) => e.toJson()).toList());
    // Ghi vào bộ nhớ SharedPreferences theo khóa _storageKey
    await sharedPreferences.setString(_storageKey, raw);
  }
}
