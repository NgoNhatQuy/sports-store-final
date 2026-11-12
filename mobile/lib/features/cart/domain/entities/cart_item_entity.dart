import 'package:equatable/equatable.dart';

/// ============================================================================
/// USE CASE: UC-11 & UC-12 - Cart Item Entity
/// Đảm nhận: Thái San Yo (CE190435)
/// Tầng: Domain Layer (Pure Dart Entity)
/// Mô tả: Đối tượng nghiệp vụ đại diện cho một món hàng trong giỏ.
///        Đặc trưng bởi khóa phức hợp duy nhất: {productId}_{size}_{color}
/// ============================================================================
class CartItemEntity extends Equatable {
  final String id;             // ID duy nhất của item trong giỏ (tạo bởi generateId)
  final String productId;      // Mã định danh sản phẩm gốc
  final String name;           // Tên hiển thị của sản phẩm
  final String brand;          // Thương hiệu (Nike, Adidas, Puma...)
  final double price;          // Đơn giá sản phẩm (VNĐ)
  final String imageUrl;       // Đường dẫn ảnh sản phẩm
  final String selectedSize;   // Kích cỡ người dùng đã chọn (VD: "41", "42")
  final int selectedColor;     // Mã màu (dạng Hex ARGB integer)
  final int quantity;          // Số lượng chọn mua trong giỏ
  final int stock;             // Số lượng tồn kho tối đa có thể mua

  const CartItemEntity({
    required this.id,
    required this.productId,
    required this.name,
    required this.brand,
    required this.price,
    required this.imageUrl,
    required this.selectedSize,
    required this.selectedColor,
    required this.quantity,
    this.stock = 99,
  });

  /// --------------------------------------------------------------------------
  /// Hàm: generateId
  /// Mục đích: Tạo ID duy nhất cho một biến thể sản phẩm trong giỏ hàng.
  /// Quy luật: Khóa kết hợp `${productId}_${size}_$color`.
  /// Ý nghĩa nghiệp vụ: Nếu người dùng thêm cùng 1 đôi giày nhưng khác Size hoặc
  /// khác Màu thì sẽ được coi là 2 mục riêng biệt trong giỏ hàng.
  /// --------------------------------------------------------------------------
  static String generateId(String productId, String size, int color) {
    return '${productId}_${size}_$color';
  }

  /// Thuộc tính tính toán: Tổng thành tiền của item này = đơn giá * số lượng
  double get totalPrice => price * quantity;

  /// Tạo bản sao mới với các thuộc tính cập nhật (thường dùng khi đổi số lượng quantity)
  CartItemEntity copyWith({
    String? id,
    String? productId,
    String? name,
    String? brand,
    double? price,
    String? imageUrl,
    String? selectedSize,
    int? selectedColor,
    int? quantity,
    int? stock,
  }) {
    return CartItemEntity(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      selectedSize: selectedSize ?? this.selectedSize,
      selectedColor: selectedColor ?? this.selectedColor,
      quantity: quantity ?? this.quantity,
      stock: stock ?? this.stock,
    );
  }

  @override
  List<Object?> get props => [
        id,
        productId,
        name,
        brand,
        price,
        imageUrl,
        selectedSize,
        selectedColor,
        quantity,
        stock,
      ];
}

