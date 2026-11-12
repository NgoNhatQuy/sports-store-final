// Import thư viện Material Design cung cấp các UI component chuẩn của Flutter
import 'package:flutter/material.dart';
// Import thư viện flutter_bloc để quản lý và lắng nghe state transitions
import 'package:flutter_bloc/flutter_bloc.dart';

// Import bảng màu giao diện chuẩn thương hiệu thể thao của dự án
import '../../../../core/constants/app_colors.dart';
// Import service locator getIt để tự động tiêm các dependency cần thiết
import '../../../../core/di/injection.dart';
// Import màn hình danh sách sản phẩm để điều hướng sau khi đăng ký thành công nếu cần
import '../../../product/presentation/screens/product_list_screen.dart';
// Import thực thể User đại diện cho người dùng
import '../../domain/entities/user.dart';
// Import RegisterCubit quản lý luồng trạng thái đăng ký
import '../cubit/register_cubit.dart';
// Import các trạng thái RegisterState (Initial, Loading, Success, Failure)
import '../cubit/register_state.dart';

/// ============================================================================
/// MÀN HÌNH ĐĂNG KÝ TÀI KHOẢN (REGISTER SCREEN - UC-02)
/// ============================================================================
/// Màn hình này chịu trách nhiệm:
/// 1. Cung cấp giao diện form đăng ký tài khoản phong cách thể thao Adidas:
///    - Họ và tên, Email, Số điện thoại Việt Nam, Mật khẩu, Xác nhận mật khẩu.
///    - Checkbox đồng ý Điều khoản dịch vụ & Chính sách bảo mật.
/// 2. Thực hiện xác thực (validation) dữ liệu cục bộ thời gian thực:
///    - Họ tên tối thiểu 2 ký tự.
///    - Email đúng định dạng regex.
///    - Số điện thoại đúng 10 số của các nhà mạng Việt Nam (+84, 03x, 05x, 07x, 08x, 09x).
///    - Mật khẩu tối thiểu 6 ký tự và khớp với mật khẩu xác nhận.
///    - Bắt buộc tích chọn đồng ý điều khoản.
/// 3. Kết nối với [RegisterCubit] gửi yêu cầu tạo tài khoản xuống SQLite database.
/// 4. Xử lý phản hồi: thông báo SnackBar thành công/thất bại, điều hướng hợp lý.
class RegisterScreen extends StatefulWidget {
  /// Callback tùy chọn được gọi khi đăng ký tài khoản thành công
  final void Function(User user)? onRegisterSuccess;

  // Constructor khởi tạo RegisterScreen nhận key và callback tùy chọn
  const RegisterScreen({super.key, this.onRegisterSuccess});

  /// Phương thức static tạo Route điều hướng đến RegisterScreen.
  /// Tự động tiêm [RegisterCubit] thông qua GetIt dependency injection.
  static Route<void> route({void Function(User user)? onRegisterSuccess}) {
    // Trả về một MaterialPageRoute bọc màn hình trong BlocProvider
    return MaterialPageRoute<void>(
      builder: (_) => BlocProvider(
        // Khởi tạo RegisterCubit từ hệ thống Dependency Injection GetIt
        create: (_) => getIt<RegisterCubit>(),
        // Tạo màn hình RegisterScreen với callback kèm theo
        child: RegisterScreen(onRegisterSuccess: onRegisterSuccess),
      ),
    );
  }

  // Tạo đối tượng State liên kết với StatefulWidget RegisterScreen
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  /// Khóa định danh toàn cục để quản lý và kiểm tra trạng thái của Form
  final _formKey = GlobalKey<FormState>();

  /// Bộ điều khiển trường nhập Họ và tên
  final _fullnameController = TextEditingController();

  /// Bộ điều khiển trường nhập Địa chỉ email
  final _emailController = TextEditingController();

  /// Bộ điều khiển trường nhập Số điện thoại
  final _phoneController = TextEditingController();

  /// Bộ điều khiển trường nhập Mật khẩu
  final _passwordController = TextEditingController();

  /// Bộ điều khiển trường nhập Xác nhận lại mật khẩu
  final _confirmPasswordController = TextEditingController();

  /// Biến cờ boolean xác định ẩn hay hiện mật khẩu (mặc định ẩn)
  bool _obscurePassword = true;

  /// Biến cờ boolean xác định ẩn hay hiện mật khẩu xác nhận (mặc định ẩn)
  bool _obscureConfirmPassword = true;

  /// Biến cờ boolean xác định người dùng đã tick chọn đồng ý điều khoản hay chưa
  bool _agreeTerms = true;

  /// Biến lưu thông báo lỗi kiểm tra cho trường Họ và tên
  String? _fullnameError;

  /// Biến lưu thông báo lỗi kiểm tra cho trường Email
  String? _emailError;

  /// Biến lưu thông báo lỗi kiểm tra cho trường Số điện thoại
  String? _phoneError;

  /// Biến lưu thông báo lỗi kiểm tra cho trường Mật khẩu
  String? _passwordError;

  /// Biến lưu thông báo lỗi kiểm tra cho trường Xác nhận mật khẩu
  String? _confirmPasswordError;

  /// Biến lưu thông báo lỗi khi chưa đồng ý Điều khoản dịch vụ
  String? _termsError;

  // Giải phóng tài nguyên bộ nhớ khi widget bị gỡ khỏi cây widget tree
  @override
  void dispose() {
    // Giải phóng controller họ tên
    _fullnameController.dispose();
    // Giải phóng controller email
    _emailController.dispose();
    // Giải phóng controller số điện thoại
    _phoneController.dispose();
    // Giải phóng controller mật khẩu
    _passwordController.dispose();
    // Giải phóng controller xác nhận mật khẩu
    _confirmPasswordController.dispose();
    // Gọi phương thức dispose của lớp cha State
    super.dispose();
  }

  /// Hàm kiểm tra tính hợp lệ của tất cả các trường dữ liệu trước khi gửi:
  /// Trả về `true` nếu tất cả hợp lệ, ngược lại trả về `false` và hiển thị lỗi.
  bool _validateInputs() {
    // Lấy chuỗi họ tên đã loại bỏ khoảng trắng thừa ở hai đầu
    final fullname = _fullnameController.text.trim();
    // Lấy chuỗi email đã loại bỏ khoảng trắng thừa
    final email = _emailController.text.trim();
    // Lấy chuỗi số điện thoại đã loại bỏ khoảng trắng thừa
    final phone = _phoneController.text.trim();
    // Lấy chuỗi mật khẩu nguyên bản
    final password = _passwordController.text;
    // Lấy chuỗi mật khẩu xác nhận
    final confirmPassword = _confirmPasswordController.text;

    // Khởi tạo các biến cục bộ tạm thời chứa lỗi của từng trường
    String? nameErr;
    String? emailErr;
    String? phoneErr;
    String? passErr;
    String? confirmErr;
    String? termsErr;

    // 1. Kiểm tra Họ và tên (không được để trống và tối thiểu 2 ký tự)
    if (fullname.isEmpty) {
      nameErr = 'Vui lòng nhập họ và tên';
    } else if (fullname.length < 2) {
      nameErr = 'Họ và tên phải có ít nhất 2 ký tự';
    }

    // 2. Kiểm tra Địa chỉ Email (chuẩn RFC biểu thức chính quy Regex)
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (email.isEmpty) {
      emailErr = 'Vui lòng nhập địa chỉ email';
    } else if (!emailRegex.hasMatch(email)) {
      emailErr = 'Email không hợp lệ (ví dụ: user@example.com)';
    }

    // 3. Kiểm tra Số điện thoại chuẩn Việt Nam (+84 hoặc 03x, 05x, 07x, 08x, 09x - đủ 10 chữ số)
    final phoneRegex = RegExp(r'^(?:(?:\+84)|0)(3[2-9]|5[25689]|7[06-9]|8[1-9]|9[0-9])[0-9]{7}$');
    // Loại bỏ tất cả khoảng trắng giữa các con số
    final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
    if (phone.isEmpty) {
      phoneErr = 'Vui lòng nhập số điện thoại';
    } else if (!phoneRegex.hasMatch(cleanPhone)) {
      phoneErr = 'Số điện thoại không hợp lệ.';
    }

    // 4. Kiểm tra Mật khẩu (yêu cầu độ dài tối thiểu 6 ký tự)
    if (password.isEmpty) {
      passErr = 'Vui lòng nhập mật khẩu';
    } else if (password.length < 6) {
      passErr = 'Mật khẩu phải chứa ít nhất 6 ký tự';
    }

    // 5. Kiểm tra Xác nhận mật khẩu (phải trùng khớp chính xác với mật khẩu ở trên)
    if (confirmPassword.isEmpty) {
      confirmErr = 'Vui lòng xác nhận lại mật khẩu';
    } else if (confirmPassword != password) {
      confirmErr = 'Mật khẩu xác nhận không trùng khớp';
    }

    // 6. Kiểm tra Đồng ý điều khoản dịch vụ (bắt buộc phải tick chọn)
    if (!_agreeTerms) {
      termsErr = 'Bạn cần đồng ý với Điều khoản dịch vụ để tiếp tục';
    }

    // Cập nhật các biến lỗi vào State để giao diện hiển thị thông báo đỏ
    setState(() {
      _fullnameError = nameErr;
      _emailError = emailErr;
      _phoneError = phoneErr;
      _passwordError = passErr;
      _confirmPasswordError = confirmErr;
      _termsError = termsErr;
    });

    // Trả về true nếu tất cả các biến lỗi đều là null (dữ liệu hoàn toàn hợp lệ)
    return nameErr == null &&
        emailErr == null &&
        phoneErr == null &&
        passErr == null &&
        confirmErr == null &&
        termsErr == null;
  }

  /// Hàm gửi yêu cầu đăng ký:
  /// - Kiểm tra validate trước.
  /// - Gọi [RegisterCubit.register] để ghi thông tin vào database.
  void _submit() {
    // Nếu kiểm tra validation không đạt thì dừng lại ngay lập tức
    if (!_validateInputs()) {
      return;
    }

    // Lấy thể hiện RegisterCubit từ context và kích hoạt hàm register với dữ liệu người dùng nhập
    context.read<RegisterCubit>().register(
          fullname: _fullnameController.text.trim(),    // Họ và tên
          email: _emailController.text.trim(),          // Email
          phoneNumber: _phoneController.text.trim(),    // Số điện thoại
          password: _passwordController.text,           // Mật khẩu
        );
  }

  // Phương thức dựng giao diện widget
  @override
  Widget build(BuildContext context) {
    // Sử dụng BlocConsumer để vừa lắng nghe sự kiện chuyển state vừa vẽ lại giao diện
    return BlocConsumer<RegisterCubit, RegisterState>(
      // Khối listener: Xử lý hiệu ứng phụ (side effects) như SnackBar và chuyển màn hình
      listener: (context, state) {
        // TRƯỜNG HỢP 1: Đăng ký tài khoản thành công
        if (state is RegisterSuccess) {
          // Hiển thị thanh thông báo nổi SnackBar chúc mừng người dùng
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Đăng ký thành công! Chào mừng ${state.user.fullname}',
              ),
              backgroundColor: Colors.green.shade700, // Màu xanh lá biểu thị thành công
              behavior: SnackBarBehavior.floating,    // Nổi phía trên chân màn hình
            ),
          );

          // Xử lý điều hướng sau khi tạo tài khoản thành công
          if (widget.onRegisterSuccess != null) {
            // Nếu có truyền callback tùy chọn thì gọi callback kèm thực thể user
            widget.onRegisterSuccess!(state.user);
          } else if (Navigator.of(context).canPop()) {
            // Nếu màn hình này được đẩy vào stack thì pop về màn hình trước (thường là Login)
            Navigator.of(context).pop();
          } else {
            // Nếu không thể pop thì thay thế hẳn bằng màn hình Danh sách sản phẩm chính
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => const ProductListScreen(),
              ),
            );
          }
        } 
        // TRƯỜNG HỢP 2: Đăng ký thất bại (ví dụ: email hoặc SĐT đã tồn tại)
        else if (state is RegisterFailure) {
          // Hiển thị SnackBar màu đỏ cảnh báo lỗi cho người dùng
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đăng ký thất bại: ${state.errorMessage}'),
              backgroundColor: Colors.red.shade700, // Màu đỏ cảnh báo lỗi
              behavior: SnackBarBehavior.floating,  // Kiểu nổi trên giao diện
            ),
          );
        }
      },
      // Khối builder: Vẽ giao diện tùy thuộc vào state hiện tại
      builder: (context, state) {
        // Kiểm tra xem trạng thái hiện tại có đang xử lý (loading) hay không
        final isLoading = state is RegisterLoading;

        // Khung màn hình Scaffold chính
        return Scaffold(
          backgroundColor: AppColors.background, // Màu nền ứng dụng
          // Thanh AppBar trong suốt
          appBar: AppBar(
            backgroundColor: Colors.transparent, // Nền trong suốt
            elevation: 0,                        // Không đổ bóng
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20), // Icon mũi tên quay lại
              onPressed: () => Navigator.of(context).pop(),         // Quay về màn hình trước
            ),
          ),
          // Vùng hiển thị an toàn tránh tai thỏ, viền dưới
          body: SafeArea(
            child: Center(
              // Cho phép cuộn khi mở bàn phím ảo
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8), // Padding viền
                child: ConstrainedBox(
                  // Giới hạn chiều rộng tối đa 440px trên màn hình lớn / tablet
                  constraints: const BoxConstraints(maxWidth: 440),
                  // Khung Form chứa các trường nhập liệu
                  child: Form(
                    key: _formKey, // Gán form key
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch, // Căn giãn hết chiều ngang
                      children: [
                        // Biểu tượng Logo thể thao nhận diện thương hiệu
                        Center(
                          child: Container(
                            width: 64,  // Chiều rộng logo
                            height: 64, // Chiều cao logo
                            decoration: BoxDecoration(
                              color: AppColors.textPrimary,            // Màu nền đen
                              borderRadius: BorderRadius.circular(16), // Bo góc vuông thể thao
                            ),
                            child: const Icon(
                              Icons.sports_basketball, // Icon bóng rổ thể thao
                              size: 36,                 // Kích cỡ icon
                              color: Colors.white,      // Màu icon trắng
                            ),
                          ),
                        ),
                        const SizedBox(height: 20), // Khoảng đệm 20px

                        // Tiêu đề chữ in hoa phong cách thể thao Adidas
                        const Text(
                          'TẠO TÀI KHOẢN',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,                // Cỡ chữ 24
                            fontWeight: FontWeight.w900, // Độ đậm tối đa
                            letterSpacing: 1.2,          // Giãn cách chữ
                            color: AppColors.textPrimary,// Màu chữ chính
                          ),
                        ),
                        const SizedBox(height: 6), // Khoảng đệm 6px
                        // Phụ đề mô tả quyền lợi người dùng
                        Text(
                          'Gia nhập cộng đồng thể thao và tận hưởng ưu đãi đặc quyền',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600, // Màu xám nhạt
                          ),
                        ),
                        const SizedBox(height: 28), // Khoảng đệm 28px

                        // Trường 1: Nhập Họ và tên
                        _buildInputField(
                          keyName: 'fullnameField',
                          controller: _fullnameController,
                          label: 'Họ và tên',
                          hintText: 'VD: Trần Hoàng Nhật',
                          icon: Icons.person_outline,
                          errorText: _fullnameError,
                          keyboardType: TextInputType.name,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16), // Khoảng đệm giữa các ô

                        // Trường 2: Nhập Địa chỉ Email
                        _buildInputField(
                          keyName: 'emailField',
                          controller: _emailController,
                          label: 'Địa chỉ Email',
                          hintText: 'VD: hoangnhat@example.com',
                          icon: Icons.email_outlined,
                          errorText: _emailError,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16), // Khoảng đệm 16px

                        // Trường 3: Nhập Số điện thoại
                        _buildInputField(
                          keyName: 'phoneField',
                          controller: _phoneController,
                          label: 'Số điện thoại',
                          hintText: 'VD: 0901234567',
                          icon: Icons.phone_android_outlined,
                          errorText: _phoneError,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16), // Khoảng đệm 16px

                        // Trường 4: Nhập Mật khẩu (Có icon ẩn/hiện)
                        _buildInputField(
                          keyName: 'passwordField',
                          controller: _passwordController,
                          label: 'Mật khẩu',
                          hintText: 'Tối thiểu 6 ký tự',
                          icon: Icons.lock_outline,
                          errorText: _passwordError,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          // Nút bấm ẩn/hiện mật khẩu
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              size: 20,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              // Đảo ngược trạng thái ẩn/hiện mật khẩu
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 16), // Khoảng đệm 16px

                        // Trường 5: Nhập Xác nhận mật khẩu (Có icon ẩn/hiện)
                        _buildInputField(
                          keyName: 'confirmPasswordField',
                          controller: _confirmPasswordController,
                          label: 'Xác nhận mật khẩu',
                          hintText: 'Nhập lại mật khẩu phía trên',
                          icon: Icons.lock_clock_outlined,
                          errorText: _confirmPasswordError,
                          obscureText: _obscureConfirmPassword,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(), // Nhấn enter trên bàn phím để submit
                          // Nút bấm ẩn/hiện mật khẩu xác nhận
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              size: 20,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              // Đảo ngược trạng thái ẩn/hiện mật khẩu xác nhận
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 14), // Khoảng đệm 14px

                        // Khối Checkbox: Đồng ý Điều khoản dịch vụ & Chính sách bảo mật
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                key: const Key('termsCheckbox'),
                                value: _agreeTerms,
                                activeColor: AppColors.primary,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                onChanged: (value) {
                                  // Cập nhật trạng thái tick chọn checkbox
                                  setState(() {
                                    _agreeTerms = value ?? false;
                                    // Xóa thông báo lỗi điều khoản nếu người dùng đã tick chọn
                                    if (_agreeTerms) {
                                      _termsError = null;
                                    }
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 10), // Khoảng cách giữa checkbox và chữ
                            Expanded(
                              // Cho phép chạm vào dòng chữ để đảo trạng thái checkbox
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _agreeTerms = !_agreeTerms;
                                    if (_agreeTerms) _termsError = null;
                                  });
                                },
                                child: Text.rich(
                                  TextSpan(
                                    text: 'Tôi đồng ý với ',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: Colors.grey.shade700,
                                    ),
                                    children: const [
                                      // Nhấn mạnh liên kết Điều khoản dịch vụ
                                      TextSpan(
                                        text: 'Điều khoản dịch vụ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                      TextSpan(text: ' & '),
                                      // Nhấn mạnh liên kết Chính sách bảo mật
                                      TextSpan(
                                        text: 'Chính sách bảo mật',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Khối hiển thị thông báo lỗi màu đỏ nếu người dùng chưa tích chọn điều khoản
                        if (_termsError != null) ...[
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.only(left: 34),
                            child: Text(
                              _termsError!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 26), // Khoảng đệm 26px

                        // Nút CTA Đăng ký phong cách thể thao
                        ElevatedButton(
                          key: const Key('registerButton'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.textPrimary,           // Nền đen tuyền
                            foregroundColor: Colors.white,                    // Chữ trắng
                            padding: const EdgeInsets.symmetric(vertical: 16),// Chiều cao nút bấm
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),       // Bo góc 10px
                            ),
                            elevation: 0,                                     // Phẳng, không bóng
                          ),
                          // Vô hiệu hóa nút khi đang gửi request loading
                          onPressed: isLoading ? null : _submit,
                          // Khi đang tải thì hiển thị vòng xoay tròn, ngược lại hiện text CTA
                          child: isLoading
                              ? const SizedBox.square(
                                  dimension: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'ĐĂNG KÝ NGAY',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 22), // Khoảng đệm 22px

                        // Dòng liên kết chuyển hướng sang màn hình Đăng nhập
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center, // Căn giữa dòng chữ
                          children: [
                            Text(
                              'Đã có tài khoản? ',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13.5,
                              ),
                            ),
                            // Chạm vào chữ để đóng màn hình đăng ký quay về đăng nhập
                            GestureDetector(
                              key: const Key('goToLoginLink'),
                              onTap: () => Navigator.of(context).pop(), // Quay lại màn hình đăng nhập
                              child: const Text(
                                'Đăng nhập ngay',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                  color: AppColors.primary,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16), // Khoảng đệm đáy trang
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Hàm phụ trợ tạo trường nhập văn bản TextField kèm nhãn tiêu đề, icon và xử lý hiển thị lỗi
  Widget _buildInputField({
    required String keyName,                   // Khóa định danh kiểm thử cho widget
    required TextEditingController controller, // Bộ điều khiển văn bản
    required String label,                     // Nhãn tên trường phía trên
    required String hintText,                  // Gợi ý hiển thị mờ trong ô nhập
    required IconData icon,                    // Biểu tượng icon tiền tố
    String? errorText,                         // Chuỗi thông báo lỗi (nếu có)
    bool obscureText = false,                  // Cờ ẩn văn bản (dùng cho mật khẩu)
    TextInputType keyboardType = TextInputType.text, // Kiểu bàn phím tương ứng
    TextInputAction textInputAction = TextInputAction.next, // Nút hành động trên bàn phím ảo
    void Function(String)? onSubmitted,       // Hàm gọi khi nhấn submit trên bàn phím
    Widget? suffixIcon,                        // Widget hậu tố (ví dụ icon con mắt ẩn/hiện)
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // Căn lề trái
      children: [
        // Nhãn tiêu đề trường nhập liệu
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6), // Khoảng cách giữa nhãn và ô nhập
        // Trường nhập liệu TextField
        TextField(
          key: Key(keyName),                      // Khóa định danh
          controller: controller,                 // Gán controller
          obscureText: obscureText,               // Thiết lập ẩn/hiện text
          keyboardType: keyboardType,             // Thiết lập kiểu bàn phím
          textInputAction: textInputAction,       // Thiết lập phím hành động
          onSubmitted: onSubmitted,               // Xử lý gửi biểu mẫu
          decoration: InputDecoration(
            hintText: hintText,                   // Chuỗi placeholder gợi ý
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13.5),
            prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade600), // Icon tiền tố
            suffixIcon: suffixIcon,               // Icon hậu tố
            filled: true,                         // Kích hoạt màu nền
            fillColor: Colors.white,              // Màu nền trắng
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), // Đệm lề
            // Viền mặc định
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10), // Bo góc 10px
              borderSide: BorderSide(
                color: errorText != null ? Colors.red : Colors.grey.shade300, // Đổi màu khi có lỗi
              ),
            ),
            // Viền khi ở trạng thái bình thường (enable)
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: errorText != null ? Colors.red : Colors.grey.shade300,
              ),
            ),
            // Viền khi người dùng focus con trỏ vào ô nhập
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: errorText != null ? Colors.red : AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
        // Khối hiển thị thông báo lỗi màu đỏ kèm icon cảnh báo dưới ô nhập
        if (errorText != null) ...[
          const SizedBox(height: 5), // Khoảng cách nhỏ
          Padding(
            padding: const EdgeInsets.only(left: 4), // Đệm lề trái
            child: Row(
              children: [
                const Icon(Icons.error_outline, size: 14, color: Colors.red), // Icon lỗi
                const SizedBox(width: 4), // Khoảng cách
                Expanded(
                  child: Text(
                    errorText,
                    style: const TextStyle(color: Colors.red, fontSize: 12), // Text lỗi màu đỏ
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
