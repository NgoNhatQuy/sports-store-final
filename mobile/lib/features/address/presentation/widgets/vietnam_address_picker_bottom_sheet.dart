// Import thư viện Material Design của Flutter
import 'package:flutter/material.dart';

// Import bảng màu giao diện chuẩn thương hiệu thể thao của dự án
import '../../../../core/constants/app_colors.dart';
// Import dữ liệu địa giới hành chính 63 tỉnh thành Việt Nam
import '../../data/datasources/vietnam_divisions_data.dart';

/// ============================================================================
/// ADDRESS PICKER RESULT & BOTTOM SHEET (SELECTION CHO ĐỊA CHỈ 3 CẤP VIỆT NAM)
/// ============================================================================

/// Lớp đóng gói kết quả chọn địa chỉ hành chính 3 cấp
class AddressPickerResult {
  // Tên Tỉnh / Thành phố được chọn
  final String province;

  // Tên Quận / Huyện được chọn
  final String district;

  // Tên Phường / Xã được chọn
  final String ward;

  // Constructor khởi tạo kết quả
  const AddressPickerResult({
    required this.province,
    required this.district,
    required this.ward,
  });

  /// Getter trả về chuỗi tóm tắt dạng: "Phường/Xã, Quận/Huyện, Tỉnh/Thành phố"
  String get summary => '$ward, $district, $province';
}

/// Modal BottomSheet chọn địa chỉ 3 cấp chuẩn hành chính Việt Nam (Tỉnh -> Huyện -> Xã)
class VietnamAddressPickerBottomSheet extends StatefulWidget {
  // Tỉnh/Thành ban đầu đã chọn trước đó (nếu có)
  final String? initialProvince;

  // Quận/Huyện ban đầu đã chọn trước đó (nếu có)
  final String? initialDistrict;

  // Phường/Xã ban đầu đã chọn trước đó (nếu có)
  final String? initialWard;

  // Constructor nhận các giá trị khởi tạo
  const VietnamAddressPickerBottomSheet({
    super.key,
    this.initialProvince,
    this.initialDistrict,
    this.initialWard,
  });

  /// Phương thức tĩnh hiển thị BottomSheet lên màn hình
  static Future<AddressPickerResult?> show(
    BuildContext context, {
    String? initialProvince, // Tỉnh ban đầu
    String? initialDistrict, // Huyện ban đầu
    String? initialWard,     // Xã ban đầu
  }) {
    // Hiển thị modal bottom sheet có thể tùy biến chiều cao
    return showModalBottomSheet<AddressPickerResult>(
      context: context,
      isScrollControlled: true,           // Cho phép chiếm tối đa chiều cao màn hình
      backgroundColor: Colors.transparent,// Nền trong suốt để lộ bo góc container
      builder: (ctx) => VietnamAddressPickerBottomSheet(
        initialProvince: initialProvince,
        initialDistrict: initialDistrict,
        initialWard: initialWard,
      ),
    );
  }

  @override
  State<VietnamAddressPickerBottomSheet> createState() =>
      _VietnamAddressPickerBottomSheetState();
}

class _VietnamAddressPickerBottomSheetState
    extends State<VietnamAddressPickerBottomSheet> {
  // Bước hiện tại trong quy trình chọn 3 cấp:
  // 0: Chọn Tỉnh / Thành phố
  // 1: Chọn Quận / Huyện
  // 2: Chọn Phường / Xã
  int _currentStep = 0;

  // Đối tượng Tỉnh / Thành phố đang được chọn
  ProvinceData? _selectedProvince;

  // Đối tượng Quận / Huyện đang được chọn
  DistrictData? _selectedDistrict;

  // Chuỗi tên Phường / Xã đang được chọn
  String? _selectedWard;

  // Controller quản lý ô tìm kiếm
  final TextEditingController _searchController = TextEditingController();

  // Biến lưu trữ từ khóa tìm kiếm theo thời gian thực
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Khôi phục lại trạng thái đã chọn trước đó nếu có dữ liệu ban đầu
    if (widget.initialProvince != null) {
      try {
        // Tìm tỉnh khớp với tên initialProvince
        _selectedProvince = VietnamAdministrativeData.provinces.firstWhere(
          (p) => p.name == widget.initialProvince,
        );
        // Nếu có huyện và tỉnh tồn tại -> Tìm huyện khớp với initialDistrict
        if (widget.initialDistrict != null && _selectedProvince != null) {
          _selectedDistrict = _selectedProvince!.districts.firstWhere(
            (d) => d.name == widget.initialDistrict,
          );
          // Nếu có xã và huyện tồn tại -> Gán xã
          if (widget.initialWard != null && _selectedDistrict != null) {
            _selectedWard = widget.initialWard;
          }
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    // Giải phóng controller tìm kiếm khi đóng BottomSheet
    _searchController.dispose();
    super.dispose();
  }

  /// Lọc danh sách địa danh hiển thị theo từ khóa tìm kiếm và bước hiện tại
  List<String> _getFilteredItems() {
    // Chuẩn hóa từ khóa tìm kiếm về chữ thường và cắt khoảng trắng
    final query = _searchQuery.toLowerCase().trim();

    // Bước 0: Đang ở màn hình chọn Tỉnh / Thành phố
    if (_currentStep == 0) {
      final names =
          VietnamAdministrativeData.provinces.map((p) => p.name).toList();
      if (query.isEmpty) return names; // Nếu không tìm kiếm thì trả về toàn bộ tỉnh
      return names.where((n) => n.toLowerCase().contains(query)).toList();
    }
    // Bước 1: Đang ở màn hình chọn Quận / Huyện
    else if (_currentStep == 1) {
      final districts =
          _selectedProvince?.districts.map((d) => d.name).toList() ?? [];
      if (query.isEmpty) return districts; // Trả về tất cả quận/huyện của tỉnh đã chọn
      return districts.where((n) => n.toLowerCase().contains(query)).toList();
    }
    // Bước 2: Đang ở màn hình chọn Phường / Xã
    else {
      final wards = _selectedDistrict?.wards ?? [];
      if (query.isEmpty) return wards; // Trả về tất cả phường/xã của quận/huyện đã chọn
      return wards.where((n) => n.toLowerCase().contains(query)).toList();
    }
  }

  /// Xử lý khi người dùng nhấn chọn một địa danh trong danh sách
  void _onItemSelected(String item) {
    // Xóa từ khóa tìm kiếm trong ô nhập
    _searchController.clear();
    _searchQuery = '';

    // Nếu vừa chọn xong Tỉnh / Thành phố
    if (_currentStep == 0) {
      setState(() {
        _selectedProvince = VietnamAdministrativeData.provinces.firstWhere(
          (p) => p.name == item,
        );
        _selectedDistrict = null; // Reset huyện cũ
        _selectedWard = null;     // Reset xã cũ
        _currentStep = 1;         // Tự động chuyển sang bước 1 (chọn Quận / Huyện)
      });
    }
    // Nếu vừa chọn xong Quận / Huyện
    else if (_currentStep == 1) {
      setState(() {
        _selectedDistrict = _selectedProvince?.districts.firstWhere(
          (d) => d.name == item,
        );
        _selectedWard = null; // Reset xã cũ
        _currentStep = 2;     // Tự động chuyển sang bước 2 (chọn Phường / Xã)
      });
    }
    // Nếu vừa chọn xong Phường / Xã -> Hoàn tất quy trình chọn 3 cấp
    else {
      setState(() {
        _selectedWard = item;
      });
      // Nếu đã có đủ dữ liệu tỉnh và huyện
      if (_selectedProvince != null && _selectedDistrict != null) {
        // Đóng BottomSheet và trả kết quả về cho màn hình gọi
        Navigator.of(context).pop(
          AddressPickerResult(
            province: _selectedProvince!.name,
            district: _selectedDistrict!.name,
            ward: item,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lấy danh sách địa danh đã lọc
    final items = _getFilteredItems();

    return Container(
      // Chiều cao chiếm 78% màn hình
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)), // Bo tròn góc trên
      ),
      child: Column(
        children: [
          // Thanh kéo ngang nhỏ phía trên BottomSheet
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),

          // Tiêu đề BottomSheet & Nút đóng
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chọn khu vực giao hàng',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                // Nút dấu X đóng BottomSheet
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 22),
                  onPressed: () => Navigator.of(context).pop(),
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),
          // Đường kẻ ngang phân cách
          const Divider(height: 1, color: AppColors.divider),

          // Thanh điều hướng tiến trình 3 bước (Breadcrumbs: Tỉnh -> Huyện -> Xã)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: AppColors.background,
            child: Row(
              children: [
                // Tab Bước 1: Tỉnh / Thành
                _buildStepTab(
                  index: 0,
                  label: _selectedProvince?.name ?? 'Tỉnh / Thành phố',
                  isSelected: _currentStep == 0,
                  isDone: _selectedProvince != null,
                ),
                const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                // Tab Bước 2: Quận / Huyện
                _buildStepTab(
                  index: 1,
                  label: _selectedDistrict?.name ?? 'Quận / Huyện',
                  isSelected: _currentStep == 1,
                  isDone: _selectedDistrict != null,
                  isEnabled: _selectedProvince != null,
                ),
                const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                // Tab Bước 3: Phường / Xã
                _buildStepTab(
                  index: 2,
                  label: _selectedWard ?? 'Phường / Xã',
                  isSelected: _currentStep == 2,
                  isDone: _selectedWard != null,
                  isEnabled: _selectedDistrict != null,
                ),
              ],
            ),
          ),

          // Ô nhập tìm kiếm địa danh
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                // Cập nhật từ khóa tìm kiếm khi người dùng gõ
                setState(() {
                  _searchQuery = val;
                });
              },
              decoration: InputDecoration(
                hintText: _currentStep == 0
                    ? 'Tìm Tỉnh / Thành phố...'
                    : _currentStep == 1
                        ? 'Tìm Quận / Huyện...'
                        : 'Tìm Phường / Xã...',
                hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                // Nút xóa nhanh nội dung tìm kiếm
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Danh sách các địa danh để chọn
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      'Không tìm thấy kết quả phù hợp',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: items.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, color: AppColors.divider),
                    itemBuilder: (context, index) {
                      final name = items[index];
                      // Kiểm tra xem item này có đang được chọn không
                      final isSelected = (_currentStep == 0 &&
                              _selectedProvince?.name == name) ||
                          (_currentStep == 1 &&
                              _selectedDistrict?.name == name) ||
                          (_currentStep == 2 && _selectedWard == name);

                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        // Tên địa danh
                        title: Text(
                          name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                        // Biểu tượng dấu tick tròn nếu đang chọn
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.primary,
                                size: 20,
                              )
                            : null,
                        // Khi nhấn chọn item
                        onTap: () => _onItemSelected(name),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Hàm phụ trợ dựng tab từng bước trong thanh Breadcrumb
  Widget _buildStepTab({
    required int index,      // Chỉ số bước (0, 1, 2)
    required String label,   // Nhãn hiển thị tên bước hoặc tên địa danh đã chọn
    required bool isSelected,// Có đang chọn bước này không
    required bool isDone,    // Bước này đã hoàn thành chọn chưa
    bool isEnabled = true,   // Bước này có cho phép bấm chuyển sang không
  }) {
    return Expanded(
      child: GestureDetector(
        // Cho phép bấm vào tab để chuyển về bước đó nếu đã thỏa điều kiện
        onTap: isEnabled
            ? () {
                setState(() {
                  _currentStep = index;      // Đổi bước
                  _searchController.clear(); // Xóa tìm kiếm
                  _searchQuery = '';
                });
              }
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tiêu đề số bước
              Text(
                'Bước ${index + 1}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? AppColors.primary
                      : isEnabled
                          ? Colors.grey.shade600
                          : Colors.grey.shade400,
                ),
              ),
              // Tên địa danh hoặc nhãn bước
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.primary
                      : isDone
                          ? AppColors.textPrimary
                          : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
