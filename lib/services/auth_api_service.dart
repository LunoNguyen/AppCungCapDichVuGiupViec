import 'api_client.dart';
import 'api_response.dart';

class AuthApiService {
  final ApiClient _apiClient = ApiClient();

  /// Đăng ký tài khoản Khách hàng (UC-KH01)
  /// POST /v1/auth/customer/register
  Future<ApiResponse<Map<String, dynamic>>> registerCustomer({
    required String hoTen,
    required String soDienThoai,
    required String email,
    required String matKhau,
    String? ngaySinh,
    String? diaChi,
    String? khuVucPhucVu,
  }) async {
    return _apiClient.post<Map<String, dynamic>>(
      '/v1/auth/customer/register',
      body: {
        'hoTen': hoTen,
        'soDienThoai': soDienThoai,
        'email': email,
        'matKhau': matKhau,
        'ngaySinh': ngaySinh,
        'diaChi': diaChi,
        'khuVucPhucVu': khuVucPhucVu,
      },
    );
  }

  /// Xác thực mã OTP và kích hoạt tài khoản (UC-KH01)
  /// POST /v1/auth/otp/verify
  Future<ApiResponse<Map<String, dynamic>>> verifyOtp({
    required String destination, // SĐT hoặc Email
    required String otpCode,
    String? loaiXacThuc, // DANG_KY, DANG_NHAP, QUEN_MAT_KHAU
  }) async {
    return _apiClient.post<Map<String, dynamic>>(
      '/v1/auth/otp/verify',
      body: {
        'destination': destination,
        'otpCode': otpCode,
        'loaiXacThuc': loaiXacThuc ?? 'DANG_KY',
      },
    );
  }

  /// Gửi lại mã OTP
  /// POST /v1/auth/otp/send
  Future<ApiResponse<Map<String, dynamic>>> sendOtp({
    required String destination,
    String? loaiXacThuc,
  }) async {
    return _apiClient.post<Map<String, dynamic>>(
      '/v1/auth/otp/send',
      body: {
        'destination': destination,
        'loaiXacThuc': loaiXacThuc ?? 'DANG_KY',
      },
    );
  }

  /// Đăng nhập Mobile (Khách hàng / Cộng tác viên)
  /// POST /v1/auth/login
  Future<ApiResponse<Map<String, dynamic>>> login({
    required String username, // SĐT hoặc Email
    required String matKhau,
    String? vaiTro, // KHACH_HANG, CONG_TAC_VIEN
  }) async {
    return _apiClient.post<Map<String, dynamic>>(
      '/v1/auth/login',
      body: {
        'tenDangNhap': username,
        'matKhau': matKhau,
        'vaiTro': vaiTro,
      },
    );
  }

  /// Đăng nhập mạng xã hội (Google / Facebook)
  /// POST /v1/auth/social-login
  Future<ApiResponse<Map<String, dynamic>>> socialLogin({
    required String provider, // GOOGLE, FACEBOOK
    required String token,
    String? email,
    String? hoTen,
  }) async {
    return _apiClient.post<Map<String, dynamic>>(
      '/v1/auth/social-login',
      body: {
        'provider': provider,
        'token': token,
        'email': email,
        'hoTen': hoTen,
      },
    );
  }
}
