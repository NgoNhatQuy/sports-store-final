// Import flutter_bloc để sử dụng lớp cơ sở Cubit và phương thức emit
import 'package:flutter_bloc/flutter_bloc.dart';
// Import RegisterUseCase để gọi nghiệp vụ đăng ký tài khoản từ Domain layer
import '../../domain/usecases/register_usecase.dart';
// Import các trạng thái RegisterState (Initial, Loading, Success, Failure)
import 'register_state.dart';

/// ============================================================================
/// REGISTER CUBIT - QUẢN LÝ TRẠNG THÁI NGHIỆP VỤ ĐĂNG KÝ TÀI KHOẢN (UC-02)
/// ============================================================================
/// Đảm nhiệm vai trò:
/// 1. Nhận thông tin người dùng từ form giao diện RegisterScreen.
/// 2. Phát (emit) trạng thái đang tải [RegisterLoading].
/// 3. Gọi [RegisterUseCase] để xử lý lưu trữ người dùng vào cơ sở dữ liệu.
/// 4. Phát [RegisterSuccess] nếu đăng ký thành công hoặc [RegisterFailure] nếu xảy ra lỗi.
class RegisterCubit extends Cubit<RegisterState> {
  // UseCase nghiệp vụ đăng ký được tiêm vào thông qua constructor
  final RegisterUseCase registerUseCase;

  // Constructor khởi tạo Cubit với trạng thái ban đầu là RegisterInitial
  RegisterCubit({required this.registerUseCase})
      : super(const RegisterInitial());

  /// Hàm thực thi nghiệp vụ đăng ký tài khoản mới:
  /// - [fullname]: Họ và tên của người dùng.
  /// - [email]: Địa chỉ email đăng ký.
  /// - [phoneNumber]: Số điện thoại liên hệ.
  /// - [password]: Mật khẩu tài khoản.
  Future<void> register({
    required String fullname,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    // Bước 1: Phát trạng thái đang xử lý để UI hiển thị vòng xoay tải dữ liệu (loading)
    emit(const RegisterLoading());
    try {
      // Bước 2: Gọi UseCase thực thi kiểm tra tính hợp lệ, trùng lặp và lưu vào SQLite database
      final user = await registerUseCase(
        RegisterParams(
          fullname: fullname,       // Truyền họ tên
          email: email,             // Truyền email
          phoneNumber: phoneNumber, // Truyền số điện thoại
          password: password,       // Truyền mật khẩu
        ),
      );
      // Bước 3: Phát trạng thái thành công kèm theo đối tượng User vừa được tạo
      emit(RegisterSuccess(user));
    } catch (e) {
      // Bước 4: Bắt ngoại lệ (ví dụ email đã tồn tại, số điện thoại đã tồn tại)
      // Lọc bỏ tiền tố 'Exception: ' để thông báo ngắn gọn và thân thiện với người dùng
      final message = e.toString().replaceFirst('Exception: ', '');
      // Phát trạng thái thất bại kèm thông báo lỗi cụ thể
      emit(RegisterFailure(message));
    }
  }

  /// Hàm đặt lại trạng thái ban đầu của Cubit (Reset state về RegisterInitial)
  void reset() {
    // Phát lại trạng thái khởi tạo ban đầu để xóa bỏ thông báo lỗi hoặc dữ liệu cũ
    emit(const RegisterInitial());
  }
}
