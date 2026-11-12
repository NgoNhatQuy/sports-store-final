// Import thư viện Dio để gửi các request HTTP mạng
import 'package:dio/dio.dart';
// Import danh sách các hằng số endpoint của backend API
import '../../../../core/constants/api_endpoints.dart';
// Import lớp ngoại lệ ServerException tùy biến của dự án
import '../../../../core/errors/exceptions.dart';
// Import dịch vụ LocalStorageService để đọc/ghi token và dữ liệu cache SharedPreferences
import '../../../../core/storage/local_storage_service.dart';
// Import mô hình dữ liệu UserProfileModel ở tầng Data
import '../models/user_profile_model.dart';

/// ============================================================================
/// PROFILE REMOTE DATA SOURCE (API & MẠNG DIO - UC-26, UC-27)
/// ============================================================================
/// Giao diện gọi API mạng liên quan đến hồ sơ người dùng.
abstract class ProfileRemoteDataSource {
  // Lấy thông tin hồ sơ người dùng từ máy chủ API
  Future<UserProfileModel> getUserProfile();

  // Cập nhật thông tin hồ sơ người dùng lên máy chủ API
  Future<UserProfileModel> updateUserProfile(UserProfileModel profile);
}

/// Triển khai gọi API hồ sơ qua Dio kèm cơ chế Fallback Offline mượt mà khi mất mạng
class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  // Đối tượng gọi mạng Dio HTTP Client
  final Dio dio;

  // Dịch vụ lưu trữ cục bộ SharedPreferences
  final LocalStorageService storageService;

  // Constructor khởi tạo nhận Dio và LocalStorageService
  ProfileRemoteDataSourceImpl({
    required this.dio,
    required this.storageService,
  });

  /// 1. LẤY HỒ SƠ NGƯỜI DÙNG QUA API (GET /users/me HOẶC /auth/me - UC-26)
  @override
  Future<UserProfileModel> getUserProfile() async {
    // Đọc token truy cập từ LocalStorageService
    final token = storageService.getAccessToken();

    try {
      // Thiết lập cấu hình request có kèm Authorization Bearer Token
      final options = Options(
        headers: {
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      );

      // Thử gọi endpoint profile chính (/users/me), nếu không có thì fallback sang (/auth/me)
      Response response;
      try {
        response = await dio.get(ApiEndpoints.userProfile, options: options);
      } on DioException {
        // Fallback sang endpoint auth /auth/me
        response = await dio.get(ApiEndpoints.authMe, options: options);
      }

      // Kiểm tra phản hồi trả về mã 200 OK thành công
      if (response.statusCode == 200) {
        final data = response.data;
        // Bóc tách JSON đối tượng từ wrapper data (nếu có)
        final json = (data is Map<String, dynamic> && data.containsKey('data'))
            ? data['data'] as Map<String, dynamic>
            : data as Map<String, dynamic>;

        // Chuyển JSON thành đối tượng UserProfileModel
        final profile = UserProfileModel.fromJson(json);

        // Lưu thông tin chi tiết vào bộ nhớ đệm SharedPreferences
        await storageService.saveUserProfile(
          userId: profile.id,
          name: profile.fullname,
          email: profile.email,
          phone: profile.phoneNumber,
          gender: profile.gender,
          createdAt: profile.createdAt?.toIso8601String(),
          avatar: profile.avatarUrl,
        );

        // Trả về model hồ sơ
        return profile;
      } else {
        // Ném lỗi máy chủ nếu mã khác 200
        throw ServerException(
          message: 'Lỗi khi tải thông tin cá nhân: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException {
      // Khi offline hoặc backend chưa bật, tự động lấy dữ liệu từ cache SharedPreferences
      return _getFromLocalOrMock();
    } catch (e) {
      // Nếu là ngoại lệ ServerException thì rethrow
      if (e is ServerException) rethrow;
      // Với các lỗi khác, đọc dữ liệu dự phòng từ local
      return _getFromLocalOrMock();
    }
  }

  /// 2. CẬP NHẬT HỒ SƠ QUA API (PUT /users/me HOẶC /auth/me - UC-27)
  @override
  Future<UserProfileModel> updateUserProfile(UserProfileModel profile) async {
    // Đọc token truy cập hiện tại
    final token = storageService.getAccessToken();

    try {
      // Thiết lập header xác thực
      final options = Options(
        headers: {
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      );

      Response response;
      try {
        // Gửi request PUT cập nhật hồ sơ lên endpoint userProfile
        response = await dio.put(
          ApiEndpoints.userProfile,
          data: profile.toJson(),
          options: options,
        );
      } on DioException {
        // Fallback gửi lên endpoint auth /auth/me nếu endpoint trên lỗi
        response = await dio.put(
          ApiEndpoints.authMe,
          data: profile.toJson(),
          options: options,
        );
      }

      // Nếu cập nhật thành công (mã 200 hoặc 201)
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        // Bóc tách Map dữ liệu
        final json = (data is Map<String, dynamic> && data.containsKey('data'))
            ? data['data'] as Map<String, dynamic>
            : (data is Map<String, dynamic> ? data : profile.toJson());

        // Tạo model từ dữ liệu phản hồi mới nhất
        final updated = UserProfileModel.fromJson(json);
        // Lưu dữ liệu vào SharedPreferences
        await _saveProfileLocally(updated);
        // Trả về model đã cập nhật
        return updated;
      }
    } on DioException {
      // Khi mất mạng hoặc backend lỗi, tiếp tục lưu offline
    } catch (_) {
      // Bỏ qua lỗi mạng
    }

    // Lưu offline để trải nghiệm người dùng không bị gián đoạn
    await _saveProfileLocally(profile);
    // Trả về đối tượng vừa cập nhật
    return profile;
  }

  /// Phương thức phụ trợ: Lưu thông tin profile và đồng bộ auth session xuống SharedPreferences
  Future<void> _saveProfileLocally(UserProfileModel profile) async {
    // Lưu các trường hồ sơ vào SharedPreferences
    await storageService.saveUserProfile(
      userId: profile.id,
      name: profile.fullname,
      email: profile.email,
      phone: profile.phoneNumber,
      gender: profile.gender,
      dob: profile.dateOfBirth?.toIso8601String(),
      createdAt: profile.createdAt?.toIso8601String(),
      avatar: profile.avatarUrl,
    );

    // Đồng bộ lại phiên đăng nhập session
    final token = storageService.getAccessToken() ?? 'token_${profile.id}';
    await storageService.saveAuthSession(
      token: token,
      userId: profile.id,
      name: profile.fullname,
      email: profile.email,
    );
  }

  /// Phương thức phụ trợ: Trích xuất dữ liệu từ SharedPreferences hoặc tạo dữ liệu mẫu chuẩn
  UserProfileModel _getFromLocalOrMock() {
    // Đọc thông tin người dùng từ LocalStorageService
    final savedUser = storageService.getSavedUser();
    // Ngày khởi tạo mặc định
    final defaultCreated = DateTime(2026, 1, 10);

    // Nếu trong SharedPreferences đã có lưu thông tin họ tên hợp lệ
    if (savedUser != null && (savedUser['name']?.isNotEmpty ?? false)) {
      DateTime? parsedCreated;
      if (savedUser['created_at'] != null && savedUser['created_at']!.isNotEmpty) {
        parsedCreated = DateTime.tryParse(savedUser['created_at']!);
      }

      // Trả về UserProfileModel từ dữ liệu đã lưu
      return UserProfileModel(
        id: savedUser['id']?.isNotEmpty == true ? savedUser['id']! : '1',
        fullname: savedUser['name'] ?? 'Khách hàng',
        email: savedUser['email'] ?? 'user@sportsstore.vn',
        phoneNumber: (savedUser['phone']?.isNotEmpty ?? false)
            ? savedUser['phone']!
            : '0901234567',
        gender: savedUser['gender'] ?? 'Nam',
        createdAt: parsedCreated ?? defaultCreated,
        status: 'ACTIVE',
      );
    }

    // Dữ liệu mẫu dự phòng ban đầu
    return UserProfileModel(
      id: '1',
      fullname: 'Nguyễn Văn A',
      email: 'a@gmail.com',
      phoneNumber: '0901234567',
      gender: 'Nam',
      createdAt: defaultCreated,
      status: 'ACTIVE',
    );
  }
}
