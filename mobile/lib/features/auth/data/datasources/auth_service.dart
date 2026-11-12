// Import database singleton AppDatabase để mở kết nối SQLite
import '../../../../core/database/app_database.dart';
// Import thực thể User đại diện cho tài khoản người dùng
import '../../domain/entities/user.dart';

/// ============================================================================
/// AUTH SERVICE - DỊCH VỤ XÁC THỰC & ĐĂNG KÝ TÀI KHOẢN (DATA LAYER - SQLITE)
/// ============================================================================
/// Thao tác trực tiếp với bảng 'users' trong cơ sở dữ liệu SQLite cục bộ [AppDatabase].
class AuthService {
  // Lấy thể hiện duy nhất (singleton) của AppDatabase
  final AppDatabase _db = AppDatabase.instance;

  /// 1. Phương thức xác thực đăng nhập qua Email & Mật khẩu
  Future<User?> authenticate({
    required String email,    // Email người dùng nhập
    required String password, // Mật khẩu người dùng nhập
  }) async {
    // Mở kết nối cơ sở dữ liệu SQLite
    final db = await _db.database;
    // Chuẩn hóa email: loại bỏ khoảng trắng thừa và chuyển về chữ thường để so khớp chính xác
    final cleanEmail = email.trim().toLowerCase();

    // Thực hiện truy vấn tìm người dùng có email trùng khớp và mật khẩu đúng
    final results = await db.query(
      'users',
      where: 'LOWER(email) = ? AND password = ?',
      whereArgs: [cleanEmail, password],
    );

    // Nếu không tìm thấy dòng nào phù hợp trong DB -> Trả về null (đăng nhập thất bại)
    if (results.isEmpty) return null;

    // Lấy bản ghi đầu tiên khớp kết quả
    final row = results.first;
    // Ánh xạ dòng dữ liệu từ SQLite Map sang thực thể User
    return User(
      id: int.tryParse(row['id'].toString()) ?? 1,                                  // Ép kiểu ID sang int
      fullname: row['fullname'] as String? ?? '',                                   // Họ và tên
      email: row['email'] as String? ?? '',                                         // Địa chỉ email
      password: row['password'] as String? ?? '',                                   // Mật khẩu
      phoneNumber: row['phone_number'] as String? ?? '',                            // Số điện thoại
      createdAt: DateTime.tryParse(row['created_at'].toString()) ?? DateTime.now(), // Thời điểm tạo
    );
  }

  /// 2. Phương thức đăng ký tài khoản người dùng mới (UC-02)
  Future<User> register({
    required String fullname,    // Họ và tên đăng ký
    required String email,       // Email đăng ký
    required String phoneNumber, // Số điện thoại đăng ký
    required String password,    // Mật khẩu tài khoản
  }) async {
    // Mở kết nối cơ sở dữ liệu SQLite
    final db = await _db.database;
    // Chuẩn hóa chuỗi email (chữ thường, xóa khoảng trắng)
    final cleanEmail = email.trim().toLowerCase();
    // Chuẩn hóa chuỗi số điện thoại
    final cleanPhone = phoneNumber.trim();

    // Bước 1: Kiểm tra tính duy nhất của Email trong bảng users (tránh trùng lặp tài khoản)
    final emailCheck = await db.query(
      'users',
      where: 'LOWER(email) = ?',
      whereArgs: [cleanEmail],
    );
    // Nếu email đã tồn tại trong hệ thống thì ném ngoại lệ thông báo
    if (emailCheck.isNotEmpty) {
      throw Exception('Email này đã được sử dụng');
    }

    // Bước 2: Kiểm tra tính duy nhất của Số điện thoại trong bảng users
    final phoneCheck = await db.query(
      'users',
      where: 'phone_number = ?',
      whereArgs: [cleanPhone],
    );
    // Nếu số điện thoại đã tồn tại trong hệ thống thì ném ngoại lệ thông báo
    if (phoneCheck.isNotEmpty) {
      throw Exception('Số điện thoại này đã được sử dụng');
    }

    // Bước 3: Đếm tổng số lượng bản ghi users hiện có để sinh ID tiếp theo
    final countResult = await db.rawQuery('SELECT COUNT(*) as count FROM users');
    // Lấy số đếm hiện tại, mặc định bằng 0 nếu null
    final count = (countResult.first['count'] as num?)?.toInt() ?? 0;
    // ID mới tăng dần: count + 1
    final newId = count + 1;
    // Lấy thời điểm hiện tại làm ngày tạo tài khoản
    final now = DateTime.now();

    // Bước 4: Lưu thông tin tài khoản người dùng mới vào bảng 'users' của SQLite
    await db.insert('users', {
      'id': newId.toString(),             // Lưu mã định danh ID dưới dạng chuỗi
      'fullname': fullname.trim(),        // Lưu họ và tên đã cắt khoảng trắng
      'email': cleanEmail,                // Lưu email đã chuẩn hóa
      'phone_number': cleanPhone,         // Lưu số điện thoại
      'password': password,               // Lưu mật khẩu
      'gender': 'Nam',                    // Giới tính mặc định ban đầu là Nam
      'created_at': now.toIso8601String(),// Lưu thời gian tạo dạng chuỗi ISO 8601
      'status': 'ACTIVE',                 // Đặt trạng thái tài khoản là ACTIVE
    });

    // Bước 5: Trả về đối tượng thực thể User hoàn chỉnh cho các tầng bên trên sử dụng
    return User(
      id: newId,                 // ID vừa cấp phát
      fullname: fullname.trim(), // Họ tên
      email: cleanEmail,         // Email
      phoneNumber: cleanPhone,   // Số điện thoại
      password: password,        // Mật khẩu
      createdAt: now,            // Ngày tạo
    );
  }
}
