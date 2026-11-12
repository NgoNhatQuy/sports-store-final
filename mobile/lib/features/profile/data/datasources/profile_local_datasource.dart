// Import database singleton AppDatabase để kết nối và thao tác với SQLite
import '../../../../core/database/app_database.dart';
// Import LocalStorageService để truy xuất và lưu thông tin người dùng trong SharedPreferences
import '../../../../core/storage/local_storage_service.dart';
// Import UserProfileModel đại diện cho bản ghi người dùng ở tầng dữ liệu
import '../models/user_profile_model.dart';
// Import interface ProfileRemoteDataSource để đồng bộ giao diện
import 'profile_remote_datasource.dart';

/// ============================================================================
/// PROFILE LOCAL DATA SOURCE (SQLITE BẢNG users + CACHE SHAREDPREFERENCES)
/// ============================================================================
/// Định nghĩa các thao tác trực tiếp với cơ sở dữ liệu SQLite cục bộ (Bảng users)
/// và bộ nhớ tạm SharedPreferences.
abstract class ProfileLocalDataSource {
  // Lấy thông tin hồ sơ người dùng từ SQLite hoặc cache
  Future<UserProfileModel> getUserProfile();

  // Cập nhật thông tin hồ sơ người dùng vào SQLite và cache
  Future<UserProfileModel> updateUserProfile(UserProfileModel profile);

  // Đổi mật khẩu tài khoản trong SQLite
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  });
}

/// Triển khai nguồn dữ liệu cục bộ sử dụng [AppDatabase] (SQLite) và [LocalStorageService]
class ProfileLocalDataSourceImpl
    implements ProfileLocalDataSource, ProfileRemoteDataSource {
  // Thể hiện quản lý kết nối cơ sở dữ liệu SQLite
  final AppDatabase appDatabase;

  // Dịch vụ lưu trữ session và profile cục bộ
  final LocalStorageService storageService;

  // Constructor khởi tạo nhận AppDatabase và LocalStorageService
  ProfileLocalDataSourceImpl({
    AppDatabase? appDatabase,
    required this.storageService,
  }) : appDatabase = appDatabase ?? AppDatabase.instance;

  /// Phương thức phụ trợ: Lấy ID người dùng hiện tại đang đăng nhập từ Session SharedPreferences
  String _getEffectiveUserId() {
    // Trả về ID từ local storage, nếu null trả về mặc định '1'
    return storageService.getUserId() ?? '1';
  }

  /// 1. LẤY HỒ SƠ NGƯỜI DÙNG TỪ SQLITE (Bảng 'users' - UC-26: VIEW PROFILE)
  @override
  Future<UserProfileModel> getUserProfile() async {
    // Mở kết nối tới database SQLite
    final db = await appDatabase.database;
    // Lấy mã người dùng hiện tại
    final userId = _getEffectiveUserId();

    // Truy vấn dữ liệu từ bảng users dựa vào ID người dùng hiện tại
    final results = await db.query(
      'users',              // Tên bảng
      where: 'id = ?',      // Điều kiện lọc theo ID
      whereArgs: [userId],  // Tham số ID
    );

    // Nếu chưa có bản ghi nào trong database, trả về dữ liệu mẫu mặc định
    if (results.isEmpty) {
      return const UserProfileModel(
        id: '1',
        fullname: 'Nguyễn Văn A',
        email: 'a@gmail.com',
        phoneNumber: '0901234567',
        gender: 'Nam',
      );
    }

    // Ánh xạ bản ghi đầu tiên của SQLite row sang UserProfileModel
    final row = results.first;
    final profile = UserProfileModel(
      id: row['id'] as String,                                   // Mã ID người dùng
      fullname: row['fullname'] as String? ?? '',                // Họ và tên
      email: row['email'] as String? ?? '',                      // Địa chỉ email
      phoneNumber: row['phone_number'] as String? ?? '',         // Số điện thoại
      gender: row['gender'] as String? ?? 'Nam',                 // Giới tính
      dateOfBirth: row['date_of_birth'] != null                  // Ngày tháng năm sinh
          ? DateTime.tryParse(row['date_of_birth'].toString())
          : null,
      avatarUrl: row['avatar_url'] as String?,                   // Ảnh đại diện
      createdAt: row['created_at'] != null                       // Ngày tham gia
          ? DateTime.tryParse(row['created_at'].toString())
          : null,
      status: row['status'] as String? ?? 'ACTIVE',              // Trạng thái tài khoản
    );

    // Đồng bộ thông tin vừa tải vào cache SharedPreferences để các màn hình khác truy xuất nhanh
    await storageService.saveUserProfile(
      userId: profile.id,
      name: profile.fullname,
      email: profile.email,
      phone: profile.phoneNumber,
      gender: profile.gender,
      createdAt: profile.createdAt?.toIso8601String(),
      avatar: profile.avatarUrl,
    );

    // Trả về model hồ sơ người dùng
    return profile;
  }

  /// 2. CẬP NHẬT HỒ SƠ NGƯỜI DÙNG VÀO SQLITE & CACHE (UC-27: EDIT PROFILE)
  @override
  Future<UserProfileModel> updateUserProfile(UserProfileModel profile) async {
    // Mở kết nối cơ sở dữ liệu SQLite
    final db = await appDatabase.database;
    // Xác định mã ID người dùng cần cập nhật
    final userId = profile.id.isNotEmpty ? profile.id : _getEffectiveUserId();

    // Bước 1: Thực thi câu lệnh UPDATE trực tiếp vào bảng 'users' của SQLite
    await db.update(
      'users',
      {
        'fullname': profile.fullname,                             // Cập nhật họ tên mới
        'phone_number': profile.phoneNumber,                     // Cập nhật số điện thoại mới
        'gender': profile.gender,                                 // Cập nhật giới tính mới
        'date_of_birth': profile.dateOfBirth?.toIso8601String(), // Cập nhật ngày sinh mới (chuỗi ISO)
        if (profile.avatarUrl != null) 'avatar_url': profile.avatarUrl, // Cập nhật avatar nếu có
      },
      where: 'id = ?',                                            // Điều kiện lọc theo ID người dùng
      whereArgs: [userId],                                        // Tham số ID
    );

    // Bước 2: Đồng bộ ngay thông tin mới nhất vào bộ nhớ cache SharedPreferences
    await storageService.saveUserProfile(
      userId: userId,
      name: profile.fullname,
      email: profile.email,
      phone: profile.phoneNumber,
      gender: profile.gender,
      createdAt: profile.createdAt?.toIso8601String(),
      avatar: profile.avatarUrl,
    );

    // Trả về hồ sơ người dùng sau khi đã cập nhật thành công
    return profile;
  }

  /// 3. ĐỔI MẬT KHẨU TÀI KHOẢN TRONG SQLITE
  @override
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    // Mở kết nối SQLite
    final db = await appDatabase.database;
    // Lấy ID tài khoản đang đăng nhập
    final userId = _getEffectiveUserId();

    // Kiểm tra mật khẩu cũ có khớp trong bảng 'users' không
    final results = await db.query(
      'users',
      where: 'id = ? AND password = ?',
      whereArgs: [userId, oldPassword],
    );

    // Nếu không khớp mật khẩu cũ thì ném thông báo lỗi
    if (results.isEmpty) {
      throw Exception('Mật khẩu hiện tại không chính xác');
    }

    // Cập nhật mật khẩu mới vào bảng 'users'
    await db.update(
      'users',
      {'password': newPassword},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }
}
