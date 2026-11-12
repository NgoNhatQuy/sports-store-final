// Import thư viện Material Design cung cấp các UI component
import 'package:flutter/material.dart';

// Import bảng màu giao diện chuẩn thương hiệu thể thao của dự án
import '../../../../core/constants/app_colors.dart';
// Import thực thể AddressEntity và enum AddressLabel
import '../../domain/entities/address_entity.dart';

/// ============================================================================
/// ADDRESS CARD WIDGET - THẺ HIỂN THỊ ĐỊA CHỈ NHẬN HÀNG (UC-28)
/// ============================================================================
/// Widget hiển thị thông tin tóm tắt của một địa chỉ giao hàng:
/// - Tên người nhận & Số điện thoại.
/// - Địa chỉ chi tiết và địa chỉ 3 cấp (Phường/Xã, Quận/Huyện, Tỉnh/Thành phố).
/// - Badge loại địa chỉ (Nhà riêng / Văn phòng) và Badge "Mặc định".
/// - Viền đậm nếu đang được chọn ([isSelected = true]) trong quy trình Checkout.
class AddressCard extends StatelessWidget {
  // Thực thể địa chỉ cần hiển thị dữ liệu
  final AddressEntity address;

  // Callback sự kiện khi người dùng nhấn vào thẻ (thường dùng để chọn địa chỉ khi Checkout)
  final VoidCallback? onTap;

  // Callback sự kiện khi người dùng nhấn nút "Chỉnh sửa"
  final VoidCallback? onEdit;

  // Cờ boolean xác định thẻ địa chỉ này có đang được chọn hay không
  final bool isSelected;

  // Constructor khởi tạo nhận các thuộc tính của thẻ địa chỉ
  const AddressCard({
    super.key,                 // Khóa widget
    required this.address,     // Bắt buộc truyền thực thể địa chỉ
    this.onTap,                // Callback khi nhấn thẻ
    this.onEdit,               // Callback khi nhấn nút sửa
    this.isSelected = false,   // Mặc định là không được chọn
  });

  // Phương thức dựng giao diện của thẻ địa chỉ
  @override
  Widget build(BuildContext context) {
    // Khung chứa Container bên ngoài với bo góc, viền và đổ bóng
    return Container(
      margin: const EdgeInsets.only(bottom: 14), // Khoảng cách đệm dưới giữa các thẻ
      decoration: BoxDecoration(
        color: Colors.white,                     // Màu nền trắng sạch sẽ
        borderRadius: BorderRadius.circular(18), // Bo góc 18px mềm mại
        border: Border.all(
          // Đổi màu viền: nếu được chọn thì dùng primary, nếu là mặc định thì dùng primary nhạt, ngược lại trong suốt
          color: isSelected
              ? AppColors.primary
              : (address.isDefault
                  ? AppColors.primary.withValues(alpha: 0.35)
                  : Colors.transparent),
          // Độ dày viền: 2px nếu được chọn, 1.5px nếu mặc định, 0px nếu bình thường
          width: isSelected ? 2 : (address.isDefault ? 1.5 : 0),
        ),
        boxShadow: [
          // Đổ bóng nhẹ tạo chiều sâu cho thẻ
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04), // Màu bóng đen mờ 4%
            blurRadius: 10,                              // Bán kính mờ 10px
            offset: const Offset(0, 4),                  // Hướng bóng dịch xuống dưới 4px
          ),
        ],
      ),
      // Bọc Material để hiệu ứng gợn sóng InkWell hiển thị đẹp trên nền bo góc
      child: Material(
        color: Colors.transparent,               // Màu nền trong suốt
        borderRadius: BorderRadius.circular(18), // Bo góc khớp với Container cha
        child: InkWell(
          onTap: onTap,                          // Bắt sự kiện chạm vào thẻ
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(18),   // Đệm viền trong toàn bộ nội dung 18px
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // Căn lề trái
              children: [
                // Hàng 1: Hiển thị Tên người nhận & Số điện thoại
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center, // Căn giữa theo chiều dọc
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            // Hiển thị tên người nhận chữ đậm, tự rút gọn dấu ... nếu quá dài
                            child: Text(
                              address.recipientName,
                              style: const TextStyle(
                                fontSize: 16,                // Cỡ chữ 16
                                fontWeight: FontWeight.w800, // Chữ rất đậm
                                color: AppColors.textPrimary,// Màu đen chính
                              ),
                              overflow: TextOverflow.ellipsis,// Rút gọn bằng 3 chấm
                            ),
                          ),
                          // Vạch phân cách mảnh giữa tên và số điện thoại
                          Container(
                            height: 14,                                          // Chiều cao vạch 14px
                            width: 1,                                            // Bề ngang vạch 1px
                            color: Colors.grey.shade400,                         // Màu xám
                            margin: const EdgeInsets.symmetric(horizontal: 8),   // Đệm ngang 8px
                          ),
                          // Hiển thị số điện thoại người nhận
                          Text(
                            address.phoneNumber,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700, // Màu xám đậm
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Khu vực dự phòng nếu cần đặt icon chỉnh sửa góc phải trên
                    if (onEdit != null)
                      GestureDetector(
                        onTap: onEdit,
                        child: const Padding(
                          padding: EdgeInsets.only(left: 8),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8), // Khoảng cách 8px

                // Hàng 2: Địa chỉ cụ thể (Số nhà, tên đường, tòa nhà)
                Text(
                  address.streetAddress,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.3, // Chiều cao dòng
                  ),
                ),
                const SizedBox(height: 4), // Khoảng cách 4px

                // Hàng 3: Chuỗi địa chỉ 3 cấp (Phường/Xã, Quận/Huyện, Tỉnh/Thành phố)
                Text(
                  '${address.ward}, ${address.district}, ${address.province}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600, // Màu xám nhạt
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12), // Khoảng cách 12px

                // Hàng 4: Các Tag nhãn phân loại (Loại địa chỉ & Mặc định) cùng nút Sửa
                Row(
                  children: [
                    // Badge nhãn: Phân biệt Nhà riêng hoặc Văn phòng
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8, // Đệm ngang 8px
                        vertical: 4,   // Đệm dọc 4px
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,             // Nền xám nhạt
                        borderRadius: BorderRadius.circular(6),  // Bo góc 6px
                        border: Border.all(color: Colors.grey.shade300), // Viền xám mảnh
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min, // Kích thước vừa khít nội dung
                        children: [
                          // Biểu tượng icon tương ứng: Tòa nhà văn phòng hoặc Ngôi nhà
                          Icon(
                            address.label == AddressLabel.office
                                ? Icons.business_outlined
                                : Icons.home_outlined,
                            size: 13,
                            color: Colors.grey.shade700,
                          ),
                          const SizedBox(width: 4), // Khoảng cách icon và chữ
                          // Chuỗi text tên hiển thị tiếng Việt của nhãn
                          Text(
                            address.label.displayName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Badge nhãn: Đánh dấu địa chỉ Mặc định (nếu có isDefault == true)
                    if (address.isDefault) ...[
                      const SizedBox(width: 8), // Khoảng cách giữa các tag
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1), // Nền primary mờ 10%
                          borderRadius: BorderRadius.circular(6),          // Bo góc 6px
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3), // Viền primary mờ 30%
                          ),
                        ),
                        child: const Text(
                          'Mặc định',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary, // Màu chữ primary nổi bật
                          ),
                        ),
                      ),
                    ],

                    // Khoảng trống đẩy nút Chỉnh sửa về sát lề phải
                    const Spacer(),

                    // Nút bấm văn bản "Chỉnh sửa" địa chỉ
                    if (onEdit != null)
                      GestureDetector(
                        onTap: onEdit, // Bắt sự kiện chạm vào chữ Chỉnh sửa
                        child: Text(
                          'Chỉnh sửa',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.blue.shade700, // Màu xanh dương thể hiện liên kết
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
