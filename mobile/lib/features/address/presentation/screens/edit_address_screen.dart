// Import thư viện Material Design cung cấp giao diện chuẩn Flutter
import 'package:flutter/material.dart';
// Import thư viện flutter_bloc để kết nối Cubit và State
import 'package:flutter_bloc/flutter_bloc.dart';

// Import cấu hình bảng màu thương hiệu thể thao
import '../../../../core/constants/app_colors.dart';
// Import thực thể AddressEntity và enum AddressLabel
import '../../domain/entities/address_entity.dart';
// Import AddressCubit quản lý cập nhật và xóa địa chỉ
import '../cubit/address_cubit.dart';
// Import các trạng thái AddressState
import '../cubit/address_state.dart';
// Import BottomSheet chọn địa giới hành chính 3 cấp Việt Nam
import '../widgets/vietnam_address_picker_bottom_sheet.dart';

/// ============================================================================
/// MÀN HÌNH CHỈNH SỬA / XÓA ĐỊA CHỈ GIAO HÀNG (EDIT ADDRESS SCREEN - UC-30, UC-31)
/// ============================================================================
/// Màn hình này chịu trách nhiệm:
/// 1. Nhận thông tin địa chỉ hiện tại (`address`), điền trước vào các ô nhập.
/// 2. Cho phép sửa: Họ tên, Số điện thoại, Địa giới hành chính 3 cấp, Số nhà/đường,
///    Loại địa chỉ (Nhà riêng/Văn phòng), và Trạng thái mặc định.
/// 3. Xác thực (validation) dữ liệu trước khi gửi cập nhật.
/// 4. Hỗ trợ thao tác Xóa địa chỉ kèm hộp thoại xác nhận (AlertDialog) tránh xóa nhầm.
/// 5. Đồng bộ kết quả qua [AddressCubit.updateAddress] hoặc [AddressCubit.deleteAddress].
class EditAddressScreen extends StatefulWidget {
  // Thực thể địa chỉ cần chỉnh sửa
  final AddressEntity address;

  // Thể hiện tùy chọn của AddressCubit nếu được truyền từ màn trước
  final AddressCubit? cubit;

  // Constructor nhận địa chỉ và cubit tùy chọn
  const EditAddressScreen({
    super.key,
    required this.address,
    this.cubit,
  });

  /// Phương thức static tạo Route điều hướng đến EditAddressScreen.
  /// Hỗ trợ tái sử dụng [AddressCubit] từ màn hình gọi nếu có.
  static Route<AddressEntity?> route({
    required AddressEntity address,
    AddressCubit? cubit,
  }) {
    // Trả về MaterialPageRoute bọc màn hình
    return MaterialPageRoute<AddressEntity?>(
      builder: (_) {
        // Nếu có cubit thì dùng BlocProvider.value để không bị đóng cubit khi pop màn hình
        if (cubit != null) {
          return BlocProvider.value(
            value: cubit,
            child: EditAddressScreen(address: address),
          );
        }
        // Nếu không có thì tạo trực tiếp
        return EditAddressScreen(address: address);
      },
    );
  }

  @override
  State<EditAddressScreen> createState() => _EditAddressScreenState();
}

class _EditAddressScreenState extends State<EditAddressScreen> {
  /// Controller quản lý trường nhập Họ và tên người nhận
  late final TextEditingController _nameController;

  /// Controller quản lý trường nhập Số điện thoại người nhận
  late final TextEditingController _phoneController;

  /// Controller quản lý trường nhập Địa chỉ chi tiết (số nhà, tên đường)
  late final TextEditingController _streetController;

  /// Biến lưu tên Tỉnh / Thành phố
  String? _selectedProvince;

  /// Biến lưu tên Quận / Huyện
  String? _selectedDistrict;

  /// Biến lưu tên Phường / Xã
  String? _selectedWard;

  /// Loại địa chỉ: Nhà riêng hoặc Văn phòng
  late AddressLabel _selectedLabel;

  /// Trạng thái đặt làm địa chỉ mặc định
  late bool _isDefault;

  /// Chuỗi lưu thông báo lỗi kiểm tra Họ và tên
  String? _nameError;

  /// Chuỗi lưu thông báo lỗi kiểm tra Số điện thoại
  String? _phoneError;

  /// Chuỗi lưu thông báo lỗi kiểm tra Khu vực 3 cấp
  String? _areaError;

  /// Chuỗi lưu thông báo lỗi kiểm tra Địa chỉ đường phố chi tiết
  String? _streetError;

  @override
  void initState() {
    super.initState();
    // Đổ dữ liệu có sẵn từ widget.address vào form nhập
    _nameController = TextEditingController(text: widget.address.recipientName);
    _phoneController = TextEditingController(text: widget.address.phoneNumber);
    _streetController = TextEditingController(text: widget.address.streetAddress);
    _selectedProvince = widget.address.province;
    _selectedDistrict = widget.address.district;
    _selectedWard = widget.address.ward;
    _selectedLabel = widget.address.label;
    _isDefault = widget.address.isDefault;
  }

  @override
  void dispose() {
    // Giải phóng bộ nhớ của các TextEditingController
    _nameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  /// Kiểm tra tính hợp lệ của dữ liệu trước khi gửi yêu cầu cập nhật
  bool _validateInputs() {
    // Chuẩn hóa cắt khoảng trắng họ tên
    final name = _nameController.text.trim();
    // Chuẩn hóa cắt khoảng trắng số điện thoại
    final phone = _phoneController.text.trim();
    // Chuẩn hóa cắt khoảng trắng địa chỉ đường phố
    final street = _streetController.text.trim();

    // Khởi tạo các biến lỗi cục bộ tạm thời
    String? nameErr;
    String? phoneErr;
    String? areaErr;
    String? streetErr;

    // 1. Kiểm tra Họ và tên người nhận (không rỗng, ít nhất 2 ký tự)
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

    // 3. Kiểm tra Khu vực 3 cấp (Bắt buộc chọn đủ cả Tỉnh, Huyện, Xã)
    if (_selectedProvince == null ||
        _selectedDistrict == null ||
        _selectedWard == null) {
      areaErr = 'Vui lòng chọn Tỉnh/Thành phố, Quận/Huyện, Phường/Xã';
    }

    // 4. Kiểm tra Địa chỉ cụ thể (tối thiểu 5 ký tự)
    if (street.isEmpty) {
      streetErr = 'Vui lòng nhập số nhà, tên đường cụ thể';
    } else if (street.length < 5) {
      streetErr = 'Địa chỉ chi tiết cần cụ thể hơn (tối thiểu 5 ký tự)';
    }

    // Cập nhật state hiển thị lỗi lên giao diện
    setState(() {
      _nameError = nameErr;
      _phoneError = phoneErr;
      _areaError = areaErr;
      _streetError = streetErr;
    });

    // Trả về true nếu không có lỗi nào phát sinh
    return nameErr == null &&
        phoneErr == null &&
        areaErr == null &&
        streetErr == null;
  }

  /// Mở BottomSheet chọn địa giới hành chính 3 cấp Việt Nam
  Future<void> _openAreaPicker() async {
    // Gọi bottom sheet chọn địa chỉ kèm theo dữ liệu tỉnh/huyện/xã hiện tại
    final result = await VietnamAddressPickerBottomSheet.show(
      context,
      initialProvince: _selectedProvince,
      initialDistrict: _selectedDistrict,
      initialWard: _selectedWard,
    );

    // Nếu người dùng chọn địa chỉ mới thành công
    if (result != null) {
      setState(() {
        _selectedProvince = result.province; // Cập nhật Tỉnh/Thành
        _selectedDistrict = result.district; // Cập nhật Quận/Huyện
        _selectedWard = result.ward;         // Cập nhật Phường/Xã
        _areaError = null;                   // Xóa lỗi khu vực
      });
    }
  }

  /// Hộp thoại xác nhận trước khi xóa địa chỉ (UC-31)
  Future<void> _confirmDelete() async {
    // Hiển thị AlertDialog cảnh báo thao tác xóa
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text(
          'Xóa địa chỉ',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        content: const Text(
          'Bạn có chắc chắn muốn xóa địa chỉ này không? Thao tác này không thể hoàn tác.',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          // Nút bấm Hủy bỏ
          TextButton(
            key: const Key('cancelDeleteButton'),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Hủy',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Nút bấm Xóa màu đỏ
          TextButton(
            key: const Key('confirmDeleteButton'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Xóa',
              style: TextStyle(
                color: Color(0xFFE53935),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    // Nếu người dùng xác nhận Xóa -> Gọi deleteAddress qua AddressCubit
    if (confirm == true && mounted) {
      context.read<AddressCubit>().deleteAddress(widget.address.id);
    }
  }

  /// Xử lý gửi form cập nhật thông tin địa chỉ
  void _submit() {
    // Dừng lại nếu dữ liệu không đạt chuẩn validation
    if (!_validateInputs()) return;

    // Kích hoạt hàm updateAddress trên AddressCubit
    context.read<AddressCubit>().updateAddress(
          id: widget.address.id,                      // Giữ nguyên ID
          recipientName: _nameController.text.trim(), // Tên mới
          phoneNumber: _phoneController.text.trim(),   // SĐT mới
          province: _selectedProvince!,               // Tỉnh mới
          district: _selectedDistrict!,               // Huyện mới
          ward: _selectedWard!,                       // Xã mới
          streetAddress: _streetController.text.trim(),// Đường phố mới
          label: _selectedLabel,                      // Loại địa chỉ mới
          isDefault: _isDefault,                      // Trạng thái mặc định mới
        );
  }

  @override
  Widget build(BuildContext context) {
    // Sử dụng BlocConsumer để xử lý phản hồi thành công và dựng giao diện
    return BlocConsumer<AddressCubit, AddressState>(
      listener: (context, state) {
        // TRƯỜNG HỢP 1: Cập nhật thành công
        if (state is AddressUpdateSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã cập nhật địa chỉ giao hàng thành công!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          // Đóng màn hình và trả địa chỉ đã cập nhật về
          Navigator.of(context).pop(state.updatedAddress);
        } 
        // TRƯỜNG HỢP 2: Xóa thành công
        else if (state is AddressDeleteSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xóa địa chỉ giao hàng thành công!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          // Đóng màn hình chỉnh sửa
          Navigator.of(context).pop();
        } 
        // TRƯỜNG HỢP 3: Xảy ra lỗi
        else if (state is AddressError) {
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
        // Cờ kiểm tra đang cập nhật
        final isSubmitting = state is AddressUpdateLoading;
        // Cờ kiểm tra đang xóa
        final isDeleting = state is AddressDeleteLoading;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text(
              'Chỉnh sửa địa chỉ',
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
            actions: [
              // Nút icon thùng rác trên thanh AppBar để xóa nhanh
              IconButton(
                key: const Key('appBarDeleteButton'),
                icon: isDeleting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFE53935),
                        ),
                      )
                    : const Icon(
                        Icons.delete_outline_rounded,
                        color: Color(0xFFE53935),
                        size: 22,
                      ),
                tooltip: 'Xóa địa chỉ',
                onPressed: (isSubmitting || isDeleting) ? null : _confirmDelete,
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
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
                                keyName: 'editRecipientNameField',
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
                                keyName: 'editPhoneNumberField',
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
                                keyName: 'editStreetAddressField',
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
                                    key: const Key('editDefaultSwitch'),
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
                        const SizedBox(height: 20),

                        // NÚT BẤM XÓA ĐỊA CHỈ NỔI BẬT VIỀN ĐỎ
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            key: const Key('deleteAddressButton'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFE53935),
                              side: BorderSide(
                                color: const Color(0xFFE53935).withValues(alpha: 0.5),
                                width: 1.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.delete_outline_rounded, size: 20),
                            label: const Text(
                              'Xóa địa chỉ này',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            onPressed:
                                (isSubmitting || isDeleting) ? null : _confirmDelete,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // NÚT BẤM HOÀN THÀNH CẬP NHẬT ĐỊA CHỈ
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
                      key: const Key('updateAddressButton'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 1,
                      ),
                      // Vô hiệu hóa nút khi đang xử lý cập nhật
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
                              'CẬP NHẬT',
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

  /// Tiêu đề phân mục
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

  /// Khung nhập text tùy biến
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
    final hasSelected = _selectedProvince != null &&
        _selectedDistrict != null &&
        _selectedWard != null;

    final displayText = hasSelected
        ? '$_selectedWard, $_selectedDistrict, $_selectedProvince'
        : 'Chọn Tỉnh/Thành phố, Quận/Huyện, Phường/Xã';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        InkWell(
          key: const Key('editAreaSelectorTile'),
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
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
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
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
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
