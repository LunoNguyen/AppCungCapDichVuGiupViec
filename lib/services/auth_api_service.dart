import 'api_client.dart';
import 'api_response.dart';

/// Các API xác thực - khớp với CustomerAuthController / CollaboratorRegistrationController ở backend.
class AuthApiService {
  final ApiClient _apiClient = ApiClient();

  /// Đăng ký tài khoản Khách hàng (UC-KH01)
  /// POST /v1/auth/customer/register
  /// Trả về: taiKhoanId, khachHangId, soDienThoai, email, otpCode (demo), thoiGianHetHanPhut
  Future<ApiResponse<Map<String, dynamic>>> registerCustomer({
    required String hoTen,
    required String soDienThoai,
    String? email,
    required String matKhau,
    String? ngaySinh, // yyyy-MM-dd
    String? gioiTinh, // Nam | Nu | Khac
    String? diaChiChiTiet,
    int? khuVucId,
  }) async {
    return _apiClient.post<Map<String, dynamic>>(
      '/v1/auth/customer/register',
      body: {
        'hoTen': hoTen,
        'soDienThoai': soDienThoai,
        if (email != null && email.isNotEmpty) 'email': email,
        'matKhau': matKhau,
        if (ngaySinh != null) 'ngaySinh': ngaySinh,
        if (gioiTinh != null) 'gioiTinh': gioiTinh,
        if (diaChiChiTiet != null && diaChiChiTiet.isNotEmpty)
          'diaChiChiTiet': diaChiChiTiet,
        if (khuVucId != null) 'khuVucId': khuVucId,
      },
    );
  }

  /// Đăng ký làm Cộng tác viên (UC-KH02) - tài khoản ở trạng thái chờ duyệt
  /// POST /v1/collaborators/register
  Future<ApiResponse<Map<String, dynamic>>> registerCollaborator({
    required String hoTen,
    required String soDienThoai,
    String? email,
    required String matKhau,
    required String ngaySinh, // yyyy-MM-dd
    String? gioiTinh,
    required String noiCuTru,
  }) async {
    return _apiClient.post<Map<String, dynamic>>(
      '/v1/collaborators/register',
      body: {
        'hoTen': hoTen,
        'soDienThoai': soDienThoai,
        if (email != null && email.isNotEmpty) 'email': email,
        'matKhau': matKhau,
        'ngaySinh': ngaySinh,
        if (gioiTinh != null) 'gioiTinh': gioiTinh,
        'noiCuTru': noiCuTru,
      },
    );
  }

  /// Xác thực mã OTP và kích hoạt tài khoản
  /// POST /v1/auth/otp/verify
  Future<ApiResponse<Map<String, dynamic>>> verifyOtp({
    required String identifier, // SĐT / Email / tên đăng nhập
    required String maCode,
    String mucDich = 'DangKy', // DangKy | DatLaiMatKhau | XacNhanGD
  }) async {
    return _apiClient.post<Map<String, dynamic>>(
      '/v1/auth/otp/verify',
      body: {
        'identifier': identifier,
        'maCode': maCode,
        'mucDich': mucDich,
      },
    );
  }

  /// Gửi lại mã OTP
  /// POST /v1/auth/otp/send
  Future<ApiResponse<Map<String, dynamic>>> sendOtp({
    required String identifier,
    String mucDich = 'DangKy',
  }) async {
    return _apiClient.post<Map<String, dynamic>>(
      '/v1/auth/otp/send',
      body: {
        'identifier': identifier,
        'mucDich': mucDich,
      },
    );
  }

  /// Đăng nhập Mobile (Khách hàng / Cộng tác viên)
  /// POST /v1/auth/login
  /// Trả về: taiKhoanId, tenDangNhap, loaiTaiKhoan (KhachHang | CongTacVien), fullName,
  /// + khachHangId... (Khách hàng) hoặc congTacVienId... (CTV, nếu đã có hồ sơ)
  Future<ApiResponse<Map<String, dynamic>>> login({
    required String username, // tên đăng nhập (mặc định là SĐT)
    required String matKhau,
  }) async {
    return _apiClient.post<Map<String, dynamic>>(
      '/v1/auth/login',
      body: {
        'tenDangNhap': username,
        'matKhau': matKhau,
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
