// Import AppDatabase singleton để quản lý kết nối và thực thi các câu lệnh SQLite
import '../../../../core/database/app_database.dart';
// Import LocalStorageService để lấy thông tin phiên người dùng đăng nhập hiện tại
import '../../../../core/storage/local_storage_service.dart';
// Import AddressLabel từ Domain layer để phân loại địa chỉ
import '../../domain/entities/address_entity.dart';
// Import AddressModel đại diện cho bản ghi bảng shipping_addresses
import '../models/address_model.dart';
// Import AddressRemoteDataSource nếu lớp này dùng chung hợp đồng
import 'address_remote_datasource.dart';

/// ============================================================================
/// ADDRESS LOCAL DATA SOURCE (SQLITE BẢNG shipping_addresses)
/// ============================================================================
/// Thao tác trực tiếp với bảng `shipping_addresses` trong cơ sở dữ liệu SQLite cục bộ.
abstract class AddressLocalDataSource {
  // Lấy danh sách địa chỉ nhận hàng từ DB cục bộ
  Future<List<AddressModel>> getAddresses();

  // Thêm một địa chỉ nhận hàng mới vào DB cục bộ
  Future<AddressModel> addAddress(AddressModel address);

  // Cập nhật thông tin địa chỉ đã có trong DB cục bộ
  Future<AddressModel> updateAddress(AddressModel address);

  // Xóa địa chỉ khỏi DB cục bộ theo id
  Future<void> deleteAddress(String addressId);

  // Thiết lập địa chỉ mặc định trong DB cục bộ
  Future<void> setDefaultAddress(String addressId);
}

/// Triển khai cụ thể các thao tác SQLite cho sổ địa chỉ
class AddressLocalDataSourceImpl
    implements AddressLocalDataSource, AddressRemoteDataSource {
  // Đối tượng quản lý kết nối SQLite
  final AppDatabase appDatabase;

  // Dịch vụ truy xuất bộ nhớ cục bộ (lưu token, userId)
  final LocalStorageService? storageService;

  // Constructor khởi tạo, mặc định lấy thể hiện singleton của AppDatabase nếu không truyền vào
  AddressLocalDataSourceImpl({
    AppDatabase? appDatabase,
    this.storageService,
  }) : appDatabase = appDatabase ?? AppDatabase.instance;

  /// Phương thức phụ trợ: Lấy ID của người dùng đang đăng nhập hiện tại từ LocalStorageService
  String? _getEffectiveUserId() {
    // Truy xuất mã ID người dùng từ bộ nhớ SharedPreferences
    return storageService?.getUserId();
  }

  /// Phương thức phụ trợ: Ánh xạ một dòng kết quả dạng Map từ SQLite sang đối tượng AddressModel
  AddressModel _mapRowToAddress(Map<String, dynamic> row) {
    return AddressModel(
      id: row['id'] as String,                                   // Lấy ID địa chỉ
      recipientName: row['recipient_name'] as String? ?? '',     // Lấy tên người nhận
      phoneNumber: row['phone_number'] as String? ?? '',         // Lấy số điện thoại
      province: row['province'] as String? ?? '',                // Lấy tỉnh / thành phố
      district: row['district'] as String? ?? '',                // Lấy quận / huyện
      ward: row['ward'] as String? ?? '',                        // Lấy phường / xã
      streetAddress: row['street_address'] as String? ?? '',     // Lấy số nhà, tên đường
      label: AddressLabel.fromString(row['label'] as String?),   // Chuyển chuỗi sang enum AddressLabel
      isDefault: (row['is_default'] as num?)?.toInt() == 1,      // 1 là true (mặc định), 0 là false
    );
  }

  /// 1. LẤY DANH SÁCH ĐỊA CHỈ TỪ SQLITE (Ưu tiên địa chỉ mặc định lên hàng đầu)
  @override
  Future<List<AddressModel>> getAddresses() async {
    // Mở kết nối tới database SQLite
    final db = await appDatabase.database;
    // Lấy mã người dùng hiện tại
    final userId = _getEffectiveUserId();

    // Biến lưu danh sách các bản ghi kết quả truy vấn
    final List<Map<String, dynamic>> results;
    // Nếu có userId thì truy vấn các địa chỉ của user đó (hoặc địa chỉ chung user_id IS NULL)
    if (userId != null && userId.isNotEmpty) {
      results = await db.query(
        'shipping_addresses',                  // Tên bảng địa chỉ
        where: 'user_id = ? OR user_id IS NULL',// Điều kiện lọc
        whereArgs: [userId],                   // Tham số lọc theo userId
        orderBy: 'is_default DESC, id ASC',    // Sắp xếp: địa chỉ mặc định lên trước
      );
    } else {
      // Nếu là khách vãng lai, truy vấn tất cả địa chỉ hiện có
      results = await db.query(
        'shipping_addresses',
        orderBy: 'is_default DESC, id ASC',    // Sắp xếp mặc định lên đầu
      );
    }

    // Ánh xạ từng dòng dữ liệu thành một AddressModel và trả về danh sách
    return results.map(_mapRowToAddress).toList();
  }

  /// 2. THÊM ĐỊA CHỈ MỚI VÀO SQLITE
  @override
  Future<AddressModel> addAddress(AddressModel address) async {
    // Mở kết nối tới database SQLite
    final db = await appDatabase.database;
    // Lấy mã người dùng hiện tại, nếu rỗng thì gán mặc định '1'
    final userId = _getEffectiveUserId() ?? '1';
    // Sinh ID tự động nếu ID truyền vào rỗng hoặc là 'default'
    final generatedId = address.id.isEmpty || address.id == 'default'
        ? 'addr_${DateTime.now().millisecondsSinceEpoch}'
        : address.id;

    // Nếu địa chỉ mới được đánh dấu làm mặc định (isDefault == true)
    // -> Bắt buộc hủy cờ mặc định của tất cả các địa chỉ cũ của người dùng này
    if (address.isDefault) {
      await db.update(
        'shipping_addresses',
        {'is_default': 0},       // Đặt tất cả về 0 (không mặc định)
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    }

    // Chèn bản ghi địa chỉ mới vào bảng 'shipping_addresses'
    await db.insert('shipping_addresses', {
      'id': generatedId,                      // Khóa chính ID
      'user_id': userId,                      // Khóa ngoại liên kết người dùng
      'recipient_name': address.recipientName,// Tên người nhận
      'phone_number': address.phoneNumber,    // Số điện thoại
      'province': address.province,           // Tỉnh / Thành phố
      'district': address.district,           // Quận / Huyện
      'ward': address.ward,                   // Phường / Xã
      'street_address': address.streetAddress,// Số nhà tên đường
      'label': address.label.name,            // Tên enum nhãn địa chỉ
      'is_default': address.isDefault ? 1 : 0,// Cờ mặc định (1: có, 0: không)
    });

    // Trả về đối tượng AddressModel hoàn chỉnh vừa được thêm
    return AddressModel(
      id: generatedId,
      recipientName: address.recipientName,
      phoneNumber: address.phoneNumber,
      province: address.province,
      district: address.district,
      ward: address.ward,
      streetAddress: address.streetAddress,
      label: address.label,
      isDefault: address.isDefault,
    );
  }

  /// 3. CẬP NHẬT ĐỊA CHỈ TRONG SQLITE
  @override
  Future<AddressModel> updateAddress(AddressModel address) async {
    // Mở kết nối cơ sở dữ liệu SQLite
    final db = await appDatabase.database;
    // Lấy mã người dùng hiện tại
    final userId = _getEffectiveUserId() ?? '1';

    // Nếu người dùng chọn địa chỉ này làm mặc định mới
    // -> Reset cờ mặc định của các địa chỉ khác về 0
    if (address.isDefault) {
      await db.update(
        'shipping_addresses',
        {'is_default': 0},
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    }

    // Cập nhật các cột thông tin mới vào bản ghi có id tương ứng
    await db.update(
      'shipping_addresses',
      {
        'recipient_name': address.recipientName, // Tên người nhận mới
        'phone_number': address.phoneNumber,     // Số điện thoại mới
        'province': address.province,            // Tỉnh / Thành mới
        'district': address.district,            // Quận / Huyện mới
        'ward': address.ward,                    // Phường / Xã mới
        'street_address': address.streetAddress, // Số nhà tên đường mới
        'label': address.label.name,             // Phân loại mới
        'is_default': address.isDefault ? 1 : 0, // Cờ mặc định mới
      },
      where: 'id = ?',                           // Điều kiện lọc theo ID địa chỉ
      whereArgs: [address.id],                   // Tham số ID
    );

    // Trả về địa chỉ đã được cập nhật thành công
    return address;
  }

  /// 4. XÓA ĐỊA CHỈ KHỎI SQLITE
  @override
  Future<void> deleteAddress(String addressId) async {
    // Mở kết nối cơ sở dữ liệu SQLite
    final db = await appDatabase.database;
    // Thực thi câu lệnh DELETE xóa bản ghi có id trùng khớp
    await db.delete(
      'shipping_addresses',
      where: 'id = ?',        // Điều kiện lọc theo ID
      whereArgs: [addressId], // Tham số ID địa chỉ cần xóa
    );
  }

  /// 5. ĐẶT ĐỊA CHỈ LÀM MẶC ĐỊNH
  @override
  Future<void> setDefaultAddress(String addressId) async {
    // Mở kết nối cơ sở dữ liệu SQLite
    final db = await appDatabase.database;
    // Lấy mã người dùng hiện tại
    final userId = _getEffectiveUserId() ?? '1';

    // Bước 1: Hủy cờ mặc định (đặt về 0) cho toàn bộ địa chỉ của user này
    await db.update(
      'shipping_addresses',
      {'is_default': 0},
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    // Bước 2: Bật cờ mặc định (đặt về 1) cho duy nhất địa chỉ có mã addressId
    await db.update(
      'shipping_addresses',
      {'is_default': 1},
      where: 'id = ?',
      whereArgs: [addressId],
    );
  }
}
