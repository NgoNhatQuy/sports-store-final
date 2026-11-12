// Import thư viện Equatable để so sánh bằng giá trị thuộc tính giữa các đối tượng địa chỉ
import 'package:equatable/equatable.dart';

/// ============================================================================
/// ADDRESS LABEL & ENTITY (DOMAIN LAYER - SỔ ĐỊA CHỈ NHẬN HÀNG)
/// ============================================================================

/// Kiểu liệt kê phân loại địa chỉ giao nhận: Nhà riêng hoặc Văn phòng
enum AddressLabel {
  // Loại địa chỉ nhà riêng
  home('Nhà riêng'),
  // Loại địa chỉ công ty / văn phòng làm việc
  office('Văn phòng');

  // Chuỗi nhãn hiển thị tiếng Việt trên giao diện
  final String displayName;

  // Constructor khởi tạo giá trị enum kèm tên hiển thị
  const AddressLabel(this.displayName);

  /// Hàm tiện ích chuyển đổi từ chuỗi string bất kỳ sang AddressLabel tương ứng
  static AddressLabel fromString(String? value) {
    // Nếu giá trị null thì mặc định trả về nhà riêng (home)
    if (value == null) return AddressLabel.home;
    // Chuyển chuỗi về chữ thường và cắt bỏ khoảng trắng hai đầu
    final lower = value.toLowerCase().trim();
    // Kiểm tra các định dạng chuỗi đại diện cho văn phòng
    if (lower == 'office' || lower == 'văn phòng' || lower == 'van phong') {
      return AddressLabel.office;
    }
    // Ngược lại trả về nhà riêng
    return AddressLabel.home;
  }
}

/// Thực thể địa chỉ giao nhận hàng của khách hàng (Domain Entity)
class AddressEntity extends Equatable {
  /// Mã định danh duy nhất của địa chỉ (dạng chuỗi UUID hoặc tiền tố addr_...)
  final String id;

  /// Họ và tên đầy đủ của người nhận hàng
  final String recipientName;

  /// Số điện thoại liên hệ khi giao hàng
  final String phoneNumber;

  /// Tên Tỉnh / Thành phố trực thuộc trung ương
  final String province;

  /// Tên Quận / Huyện / Thị xã / Thành phố trực thuộc tỉnh
  final String district;

  /// Tên Phường / Xã / Thị trấn
  final String ward;

  /// Số nhà, tên đường phố, tòa nhà cụ thể
  final String streetAddress;

  /// Phân loại địa chỉ: Nhà riêng hoặc Văn phòng
  final AddressLabel label;

  /// Cờ xác định đây có phải địa chỉ mặc định được ưu tiên chọn khi đặt hàng không
  final bool isDefault;

  // Constructor khởi tạo đối tượng AddressEntity
  const AddressEntity({
    required this.id,            // ID địa chỉ
    required this.recipientName, // Tên người nhận
    required this.phoneNumber,   // Số điện thoại
    required this.province,      // Tỉnh / Thành phố
    required this.district,      // Quận / Huyện
    required this.ward,          // Phường / Xã
    required this.streetAddress, // Địa chỉ chi tiết
    this.label = AddressLabel.home, // Mặc định là Nhà riêng
    this.isDefault = false,         // Mặc định không phải địa chỉ mặc định
  });

  /// Getter tạo chuỗi địa chỉ hoàn chỉnh bằng cách ghép các cấp hành chính cách nhau bởi dấu phẩy
  String get fullAddress {
    // Lọc lấy các thành phần địa chỉ không rỗng
    final parts = [streetAddress, ward, district, province]
        .where((s) => s.trim().isNotEmpty) // Loại bỏ chuỗi rỗng hoặc chỉ có khoảng trắng
        .toList();                         // Chuyển thành danh sách
    // Ghép các thành phần lại bằng dấu phẩy và khoảng trắng
    return parts.join(', ');
  }

  /// Phương thức sao chép và tạo mới đối tượng AddressEntity với các trường được cập nhật
  AddressEntity copyWith({
    String? id,                 // ID mới nếu có
    String? recipientName,      // Tên người nhận mới nếu có
    String? phoneNumber,        // Số điện thoại mới nếu có
    String? province,           // Tỉnh / Thành phố mới nếu có
    String? district,           // Quận / Huyện mới nếu có
    String? ward,               // Phường / Xã mới nếu có
    String? streetAddress,      // Địa chỉ chi tiết mới nếu có
    AddressLabel? label,        // Loại địa chỉ mới nếu có
    bool? isDefault,            // Trạng thái mặc định mới nếu có
  }) {
    // Trả về một đối tượng AddressEntity mới với dữ liệu được cập nhật hoặc giữ nguyên cũ
    return AddressEntity(
      id: id ?? this.id,
      recipientName: recipientName ?? this.recipientName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      province: province ?? this.province,
      district: district ?? this.district,
      ward: ward ?? this.ward,
      streetAddress: streetAddress ?? this.streetAddress,
      label: label ?? this.label,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  // Danh sách thuộc tính để Equatable kiểm tra so sánh hai địa chỉ bằng nhau
  @override
  List<Object?> get props => [
        id,            // So sánh mã định danh
        recipientName, // So sánh tên người nhận
        phoneNumber,   // So sánh số điện thoại
        province,      // So sánh tỉnh / thành
        district,      // So sánh quận / huyện
        ward,          // So sánh phường / xã
        streetAddress, // So sánh số nhà tên đường
        label,         // So sánh loại địa chỉ
        isDefault,     // So sánh cờ mặc định
      ];
}
