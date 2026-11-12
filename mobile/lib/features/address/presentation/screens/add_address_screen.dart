// Import thư viện Material Design cung cấp giao diện chuẩn Flutter
import 'package:flutter/material.dart';
// Import thư viện flutter_bloc để kết nối Cubit và State
import 'package:flutter_bloc/flutter_bloc.dart';

// Import bảng màu giao diện chuẩn thương hiệu thể thao
import '../../../../core/constants/app_colors.dart';
// Import thực thể AddressEntity và enum AddressLabel
import '../../domain/entities/address_entity.dart';
// Import AddressCubit quản lý thêm địa chỉ
import '../cubit/address_cubit.dart';
// Import các trạng thái AddressState
import '../cubit/address_state.dart';
// Import BottomSheet chọn địa chỉ 3 cấp Việt Nam
import '../widgets/vietnam_address_picker_bottom_sheet.dart';

/// ============================================================================
/// MÀN HÌNH THÊM ĐỊA CHỈ GIAO HÀNG MỚI (ADD ADDRESS SCREEN - UC-29)
/// ============================================================================
/// Màn hình này chịu trách nhiệm:
/// 1. Cung cấp form nhập thông tin người nhận hàng:
///    - Họ và tên người nhận, Số điện thoại liên hệ.
///    - Bộ chọn địa giới hành chính Việt Nam 3 cấp: Tỉnh/Thành phố -> Quận/Huyện -> Phường/Xã.
///    - Địa chỉ chi tiết (Số nhà, tên đường, tòa nhà).
///    - Phân loại địa chỉ: Nhà riêng / Văn phòng.
///    - Tùy chọn đặt làm địa chỉ mặc định.
/// 2. Xác thực (validation) dữ liệu:
///    - Tên người nhận >= 2 ký tự.
///    - SĐT chuẩn 10 số nhà mạng VN (+84, 03x, 05x, 07x, 08x, 09x).
///    - Bắt buộc chọn đầy đủ 3 cấp hành chính.
///    - Địa chỉ chi tiết >= 5 ký tự.
/// 3. Gửi thông tin qua [AddressCubit.addAddress], lưu vào SQLite / API và đóng màn hình.
class AddAddressScreen extends StatefulWidget {
  // Thể hiện tùy chọn của AddressCubit nếu được truyền từ màn hình trước
  final AddressCubit? cubit;

  // Constructor khởi tạo màn hình Thêm địa chỉ
  const AddAddressScreen({super.key, this.cubit});

  /// Phương thức static tạo Route điều hướng đến AddAddressScreen.
  /// Hỗ trợ tái sử dụng [AddressCubit] từ màn hình gọi nếu có.
  static Route<AddressEntity?> route({AddressCubit? cubit}) {
    // Trả về MaterialPageRoute bọc màn hình
    return MaterialPageRoute<AddressEntity?>(
      builder: (_) {
        // Nếu có truyền cubit thì dùng BlocProvider.value để tránh hủy cubit khi pop
        if (cubit != null) {
          return BlocProvider.value(
            value: cubit,
            child: const AddAddressScreen(),
          );
        }
        // Nếu không có thì tạo trực tiếp
        return const AddAddressScreen();
      },
    );
  }

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  /// Controller quản lý trường nhập Họ và tên người nhận
  final _nameController = TextEditingController();

  /// Controller quản lý trường nhập Số điện thoại người nhận
  final _phoneController = TextEditingController();

  /// Controller quản lý trường nhập Số nhà, tên đường chi tiết
  final _streetController = TextEditingController();

  /// Biến lưu tên Tỉnh / Thành phố được chọn từ BottomSheet
  String? _selectedProvince;

  /// Biến lưu tên Quận / Huyện được chọn từ BottomSheet
  String? _selectedDistrict;

  /// Biến lưu tên Phường / Xã được chọn từ BottomSheet
  String? _selectedWard;

  /// Phân loại địa chỉ: Nhà riêng hoặc Văn phòng (mặc định Nhà riêng)
  AddressLabel _selectedLabel = AddressLabel.home;

  /// Trạng thái bật/tắt đặt làm địa chỉ mặc định (mặc định false)
  bool _isDefault = false;

  /// Chuỗi lưu thông báo lỗi kiểm tra Họ và tên
  String? _nameError;

  /// Chuỗi lưu thông báo lỗi kiểm tra Số điện thoại
  String? _phoneError;

  /// Chuỗi lưu thông báo lỗi kiểm tra Khu vực hành chính 3 cấp
  String? _areaError;

  /// Chuỗi lưu thông báo lỗi kiểm tra Địa chỉ đường phố chi tiết
  String? _streetError;

  @override
  void dispose() {
    // Giải phóng controller họ tên
    _nameController.dispose();
    // Giải phóng controller số điện thoại
    _phoneController.dispose();
    // Giải phóng controller địa chỉ chi tiết
    _streetController.dispose();
    // Gọi dispose lớp cha State
    super.dispose();
  }

  /// Hàm kiểm tra tính hợp lệ của toàn bộ dữ liệu nhập vào form trước khi submit
  bool _validateInputs() {
    // Lấy chuỗi họ tên đã loại bỏ khoảng trắng thừa
    final name = _nameController.text.trim();
    // Lấy chuỗi số điện thoại đã loại bỏ khoảng trắng thừa
    final phone = _phoneController.text.trim();
    // Lấy chuỗi số nhà tên đường đã loại bỏ khoảng trắng thừa
    final street = _streetController.text.trim();

    // Khởi tạo các biến lỗi cục bộ tạm thời
    String? nameErr;
    String? phoneErr;
    String? areaErr;
    String? streetErr;

    // 1. Kiểm tra Họ và tên người nhận (không để trống, ít nhất 2 ký tự)
    if (name.isEmpty) {
      nameErr = 'Vui lòng nhập họ và tên người nhận';
    } else if (name.length < 2) {
      nameErr = 'Họ và tên phải có ít nhất 2 ký tự';
    }

    // 2. Kiểm tra Số điện thoại chuẩn Việt Nam (+84 hoặc 03x, 05x, 07x, 08x, 09x - 10 chữ số)
    final phoneRegex = RegExp(
      r'^(?:(?:\+84)|0)(3[2-9]|5[25689]|7[06-9]|8[1-9]|9[0-9])[0-9]{7}$',
    );
    final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
    if (phone.isEmpty) {
      phoneErr = 'Vui lòng nhập số điện thoại người nhận';
    } else if (!phoneRegex.hasMatch(cleanPhone)) {
      phoneErr = 'Số điện thoại không hợp lệ (ví dụ: 0901234567)';
    }

    // 3. Kiểm tra Khu vực 3 cấp (Bắt buộc phải chọn đủ cả Tỉnh, Huyện, Xã)
    if (_selectedProvince == null ||
        _selectedDistrict == null ||
        _selectedWard == null) {
      areaErr = 'Vui lòng chọn Tỉnh/Thành phố, Quận/Huyện, Phường/Xã';
    }

    // 4. Kiểm tra Địa chỉ cụ thể (tối thiểu 5 ký tự để tránh nhập sơ sài)
    if (street.isEmpty) {
      streetErr = 'Vui lòng nhập số nhà, tên đường cụ thể';
    } else if (street.length < 5) {
      streetErr = 'Địa chỉ chi tiết cần cụ thể hơn (tối thiểu 5 ký tự)';
    }

    // Cập nhật trạng thái lỗi lên giao diện UI
    setState(() {
      _nameError = nameErr;
      _phoneError = phoneErr;
      _areaError = areaErr;
      _streetError = streetErr;
    });

    // Trả về true nếu không có bất kỳ trường nào bị lỗi
    return nameErr == null &&
        phoneErr == null &&
        areaErr == null &&
        streetErr == null;
  }

  /// Phương thức mở BottomSheet chọn địa giới hành chính 3 cấp Việt Nam
  Future<void> _openAreaPicker() async {
    // Hiển thị modal chọn địa chỉ 3 cấp và chờ kết quả
    final result = await VietnamAddressPickerBottomSheet.show(
      context,
      initialProvince: _selectedProvince,
      initialDistrict: _selectedDistrict,
      initialWard: _selectedWard,
    );

    // Nếu người dùng đã chọn xong đủ 3 cấp
    if (result != null) {
      setState(() {
        _selectedProvince = result.province; // Cập nhật Tỉnh/Thành
        _selectedDistrict = result.district; // Cập nhật Quận/Huyện
        _selectedWard = result.ward;         // Cập nhật Phường/Xã
        _areaError = null;                   // Xóa thông báo lỗi khu vực nếu có
      });
    }
  }

  /// Phương thức xử lý gửi form thêm địa chỉ mới
  void _submit() {
    // Nếu kiểm tra validation thất bại thì dừng lại
    if (!_validateInputs()) return;

    // Gọi hàm addAddress trên AddressCubit để lưu vào cơ sở dữ liệu
    context.read<AddressCubit>().addAddress(
          recipientName: _nameController.text.trim(), // Tên người nhận
          phoneNumber: _phoneController.text.trim(),   // Số điện thoại
          province: _selectedProvince!,               // Tỉnh thành
          district: _selectedDistrict!,               // Quận huyện
          ward: _selectedWard!,                       // Phường xã
          streetAddress: _streetController.text.trim(),// Số nhà tên đường
          label: _selectedLabel,                      // Loại địa chỉ
          isDefault: _isDefault,                      // Đặt làm mặc định
        );
  }

  @override
  Widget build(BuildContext context) {
    // Sử dụng BlocConsumer để lắng nghe sự kiện thành công và vẽ lại giao diện
    return BlocConsumer<AddressCubit, AddressState>(
      listener: (context, state) {
        // TRƯỜNG HỢP 1: Thêm địa chỉ thành công
        if (state is AddressAddSuccess) {
          // Hiển thị SnackBar thông báo thành công màu xanh lá
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã thêm địa chỉ giao hàng thành công!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          // Đóng màn hình Thêm và trả địa chỉ mới tạo về cho màn hình gọi
          Navigator.of(context).pop(state.newAddress);
        } 
        // TRƯỜNG HỢP 2: Thất bại, xảy ra lỗi
        else if (state is AddressError) {
          // Hiển thị SnackBar thông báo lỗi màu đỏ
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        // Cờ kiểm tra đang gửi dữ liệu
        final isSubmitting = state is AddressAddLoading;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text(
              'Địa chỉ mới',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                fontSize: 18,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                size: 20,
                color: AppColors.textPrimary,
              ),
              onPressed: () => Navigator.of(context).pop(), // Quay về
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20), // Đệm viền 20px
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // PHẦN 1: THÔNG TIN LIÊN HỆ
                        _buildSectionHeader('Liên hệ'),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Ô nhập Họ và tên người nhận
                              _buildTextField(
                                keyName: 'recipientNameField',
                                controller: _nameController,
                                label: 'Họ và tên người nhận',
                                hint: 'Ví dụ: Nguyễn Văn A',
                                icon: Icons.person_outline_rounded,
                                errorText: _nameError,
                                textCapitalization: TextCapitalization.words,
                              ),
                              const Divider(height: 24, color: AppColors.divider),
                              // Ô nhập Số điện thoại người nhận
                              _buildTextField(
                                keyName: 'phoneNumberField',
                                controller: _phoneController,
                                label: 'Số điện thoại',
                                hint: 'Ví dụ: 0901234567',
                                icon: Icons.phone_outlined,
                                errorText: _phoneError,
                                keyboardType: TextInputType.phone,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // PHẦN 2: THÔNG TIN ĐỊA CHỈ NHẬN HÀNG
                        _buildSectionHeader('Địa chỉ nhận hàng'),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Khung chọn Tỉnh/Thành, Quận/Huyện, Phường/Xã
                              _buildAreaSelector(),
                              const Divider(height: 24, color: AppColors.divider),
                              // Ô nhập Tên đường, tòa nhà, số nhà chi tiết
                              _buildTextField(
                                keyName: 'streetAddressField',
                                controller: _streetController,
                                label: 'Tên đường, Tòa nhà, Số nhà',
                                hint: 'Ví dụ: 123 Lê Duẩn, Tòa nhà Bitexco...',
                                icon: Icons.home_work_outlined,
                                errorText: _streetError,
                                maxLines: 2,
                                textCapitalization: TextCapitalization.sentences,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // PHẦN 3: CÀI ĐẶT (Loại địa chỉ & Mặc định)
                        _buildSectionHeader('Cài đặt'),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Tiêu đề chọn loại địa chỉ
                              const Text(
                                'Loại địa chỉ',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Hai nút chip chọn: Nhà riêng hoặc Văn phòng
                              Row(
                                children: [
                                  // Nút chip Nhà riêng
                                  _buildTypeChip(
                                    label: AddressLabel.home.displayName,
                                    icon: Icons.home_outlined,
                                    isSelected:
                                        _selectedLabel == AddressLabel.home,
                                    onTap: () {
                                      setState(() {
                                        _selectedLabel = AddressLabel.home;
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 12),
                                  // Nút chip Văn phòng
                                  _buildTypeChip(
                                    label: AddressLabel.office.displayName,
                                    icon: Icons.business_outlined,
                                    isSelected:
                                        _selectedLabel == AddressLabel.office,
                                    onTap: () {
                                      setState(() {
                                        _selectedLabel = AddressLabel.office;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              const Divider(height: 24, color: AppColors.divider),

                              // Switch chuyển đổi: Đặt làm địa chỉ mặc định
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Đặt làm địa chỉ mặc định',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Tự động chọn khi thanh toán đơn hàng',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Nút gạt Switch
                                  Switch(
                                    value: _isDefault,
                                    activeThumbColor: AppColors.primary,
                                    onChanged: (val) {
                                      setState(() {
                                        _isDefault = val;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // NÚT BẤM HOÀN THÀNH LƯU ĐỊA CHỈ
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      key: const Key('saveAddressButton'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 1,
                      ),
                      // Khi đang gửi request thì vô hiệu hóa nút
                      onPressed: isSubmitting ? null : _submit,
                      child: isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'HOÀN THÀNH',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Hàm phụ trợ hiển thị tiêu đề từng phân mục
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  /// Hàm phụ trợ tạo khung nhập văn bản TextField tùy biến
  Widget _buildTextField({
    required String keyName,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? errorText,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hàng icon và nhãn tiêu đề
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Ô nhập văn bản
        TextField(
          key: Key(keyName),
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
            errorText: errorText,
            filled: true,
            fillColor: AppColors.background,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  /// Khung lựa chọn Tỉnh/Thành, Quận/Huyện, Phường/Xã (Mở BottomSheet)
  Widget _buildAreaSelector() {
    // Kiểm tra xem đã chọn đủ 3 cấp hay chưa
    final hasSelected = _selectedProvince != null &&
        _selectedDistrict != null &&
        _selectedWard != null;

    // Chuỗi văn bản hiển thị
    final displayText = hasSelected
        ? '$_selectedWard, $_selectedDistrict, $_selectedProvince'
        : 'Chọn Tỉnh/Thành phố, Quận/Huyện, Phường/Xã';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hàng nhãn tiêu đề
        const Row(
          children: [
            Icon(Icons.location_on_outlined, size: 16, color: AppColors.primary),
            SizedBox(width: 6),
            Text(
              'Tỉnh/Thành phố, Quận/Huyện, Phường/Xã',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Ô bấm để mở BottomSheet chọn 3 cấp
        InkWell(
          key: const Key('areaSelectorTile'),
          onTap: _openAreaPicker, // Bấm vào để mở bộ chọn
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _areaError != null
                    ? Colors.red.shade400
                    : Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    displayText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          hasSelected ? FontWeight.w600 : FontWeight.w400,
                      color: hasSelected
                          ? AppColors.textPrimary
                          : Colors.grey.shade400,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Icon mũi tên chuyển trang
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
        // Hiển thị lỗi đỏ nếu chưa chọn đủ 3 cấp
        if (_areaError != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              _areaError!,
              style: TextStyle(color: Colors.red.shade700, fontSize: 12),
            ),
          ),
        ],
      ],
    );
  }

  /// Chip lựa chọn loại địa chỉ (Nhà riêng hoặc Văn phòng)
  Widget _buildTypeChip({
    required String label,       // Tên hiển thị loại
    required IconData icon,      // Icon đại diện
    required bool isSelected,   // Trạng thái đang được chọn
    required VoidCallback onTap, // Hàm callback khi chạm vào chip
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey.shade300,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? AppColors.primary : Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
