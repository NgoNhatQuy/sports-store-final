// Import thực thể AddressEntity và AddressLabel từ tầng Domain
import '../../domain/entities/address_entity.dart';

/// ============================================================================
/// ADDRESS MODEL (DATA LAYER - SỔ ĐỊA CHỈ NHẬN HÀNG)
/// ============================================================================
/// Mô hình dữ liệu địa chỉ kế thừa từ [AddressEntity], chịu trách nhiệm
/// chuyển đổi qua lại với JSON API hoặc bản ghi bảng SQLite `shipping_addresses`.
class AddressModel extends AddressEntity {
  // Constructor khởi tạo AddressModel kế thừa toàn bộ thuộc tính từ AddressEntity cha
  const AddressModel({
    required super.id,            // ID địa chỉ
    required super.recipientName, // Tên người nhận hàng
    required super.phoneNumber,   // Số điện thoại người nhận
    required super.province,      // Tỉnh / Thành phố
    required super.district,      // Quận / Huyện
    required super.ward,          // Phường / Xã
    required super.streetAddress, // Số nhà, tên đường
    super.label = AddressLabel.home, // Mặc định là Nhà riêng
    super.isDefault = false,         // Mặc định không phải địa chỉ mặc định
  });

  /// Factory constructor chuyển đổi từ Map (dữ liệu dòng SQLite hoặc JSON trả về từ API) sang [AddressModel]
  factory AddressModel.fromJson(Map<String, dynamic> json) {
    // Trả về một đối tượng AddressModel được bóc tách từ các khóa Map tương ứng
    return AddressModel(
      // Lấy id dạng chuỗi, hỗ trợ nhiều kiểu dữ liệu trả về từ DB hoặc API
      id: json['id']?.toString() ?? '',
      // Lấy tên người nhận từ các key có thể có: recipientName, recipient_name hoặc name
      recipientName: json['recipientName'] ?? json['recipient_name'] ?? json['name'] ?? '',
      // Lấy số điện thoại từ các key: phoneNumber, phone_number hoặc phone
      phoneNumber: json['phoneNumber'] ?? json['phone_number'] ?? json['phone'] ?? '',
      // Lấy tỉnh/thành phố từ key: province hoặc city
      province: json['province'] ?? json['city'] ?? '',
      // Lấy quận/huyện từ key: district
      district: json['district'] ?? '',
      // Lấy phường/xã từ key: ward hoặc commune
      ward: json['ward'] ?? json['commune'] ?? '',
      // Lấy địa chỉ đường phố cụ thể từ key: streetAddress, street_address hoặc street
      streetAddress: json['streetAddress'] ?? json['street_address'] ?? json['street'] ?? '',
      // Chuyển đổi chuỗi label sang kiểu enum AddressLabel
      label: AddressLabel.fromString(json['label']?.toString()),
      // Lấy cờ mặc định isDefault từ key: isDefault hoặc is_default (mặc định false)
      isDefault: json['isDefault'] ?? json['is_default'] ?? false,
    );
  }

  /// Phương thức đóng gói thông tin Model thành đối tượng Map JSON để gửi lên server hoặc lưu cache
  Map<String, dynamic> toJson() {
    // Trả về một Map chứa các cặp key-value chuẩn hóa
    return {
      'id': id,                       // Mã định danh địa chỉ
      'recipientName': recipientName, // Tên người nhận
      'phoneNumber': phoneNumber,     // Số điện thoại
      'province': province,           // Tỉnh / Thành phố
      'district': district,           // Quận / Huyện
      'ward': ward,                   // Phường / Xã
      'streetAddress': streetAddress, // Số nhà, tên đường
      'label': label.name,            // Tên của enum label ('home' hoặc 'office')
      'isDefault': isDefault,         // Trạng thái mặc định boolean
    };
  }

  /// Factory constructor chuyển đổi từ đối tượng Domain Entity sang Data Model
  factory AddressModel.fromEntity(AddressEntity entity) {
    // Sao chép toàn bộ các trường từ entity sang model
    return AddressModel(
      id: entity.id,                       // ID địa chỉ
      recipientName: entity.recipientName, // Tên người nhận
      phoneNumber: entity.phoneNumber,     // Số điện thoại
      province: entity.province,           // Tỉnh / Thành phố
      district: entity.district,           // Quận / Huyện
      ward: entity.ward,                   // Phường / Xã
      streetAddress: entity.streetAddress, // Tên đường, số nhà
      label: entity.label,                 // Loại địa chỉ
      isDefault: entity.isDefault,         // Cờ mặc định
    );
  }
}
