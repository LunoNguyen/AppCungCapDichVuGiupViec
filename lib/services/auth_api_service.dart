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
    // Địa chỉ nơi ở: số nhà + mã tỉnh, phường (provinces.open-api.vn v2); khu vực suy ra từ phường
    String? soNhaTenDuong,
    int? maTinh,
    int? maQuan,
    int? maPhuong,
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
        if (soNhaTenDuong != null) 'soNhaTenDuong': soNhaTenDuong,
        if (maTinh != null) 'maTinh': maTinh,
        if (maQuan != null) 'maQuan': maQuan,
        if (maPhuong != null) 'maPhuong': maPhuong,
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
    // ĐỊA CHỈ nơi ở hiện tại: số nhà + mã tỉnh, phường (provinces.open-api.vn v2)
    String? noiCuTru,
    String? soNhaTenDuong,
    int? maTinh,
    int? maQuan,
    int? maPhuong,
    String? tinhThanh,
    String? phuongXa,
    // KHU VỰC nhận việc: 1 đến 5 quận, huyện
    List<int>? danhSachKhuVucId,
    List<int>? danhSachDichVuId,
    List<Map<String, dynamic>>? danhSachHoSo, // [{loaiTaiLieu, duongDanFile}]
    List<Map<String, dynamic>>? danhSachChungChi, // [{loaiChungChi, tenChungChi, noiCap, ngayCap, duongDanFile}]
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
        if (noiCuTru != null) 'noiCuTru': noiCuTru,
        if (soNhaTenDuong != null) 'soNhaTenDuong': soNhaTenDuong,
        if (maTinh != null) 'maTinh': maTinh,
        if (maQuan != null) 'maQuan': maQuan,
        if (maPhuong != null) 'maPhuong': maPhuong,
        if (danhSachKhuVucId != null) 'danhSachKhuVucId': danhSachKhuVucId,
        if (tinhThanh != null && tinhThanh.isNotEmpty) 'tinhThanh': tinhThanh,
        if (phuongXa != null && phuongXa.isNotEmpty) 'phuongXa': phuongXa,
        if (danhSachDichVuId != null) 'danhSachDichVuId': danhSachDichVuId,
        if (danhSachHoSo != null) 'danhSachHoSo': danhSachHoSo,
        if (danhSachChungChi != null) 'danhSachChungChi': danhSachChungChi,
      },
    );
  }

  /// Tra cứu kết quả xét duyệt hồ sơ CTV theo số điện thoại
  /// GET /v1/collaborators/application-status?soDienThoai=...
  Future<ApiResponse<Map<String, dynamic>>> getCollaboratorApplicationStatus(
      String soDienThoai) async {
    return _apiClient.get<Map<String, dynamic>>(
      '/v1/collaborators/application-status',
      queryParams: {'soDienThoai': soDienThoai},
      fromJsonT: (json) => Map<String, dynamic>.from(json as Map),
    );
  }

  /// Đổi mật khẩu sau khi đăng nhập
  /// POST /v1/auth/change-password
  Future<ApiResponse<Map<String, dynamic>>> changePassword({
    required int taiKhoanId,
    required String matKhauHienTai,
    required String matKhauMoi,
  }) async {
    return _apiClient.post<Map<String, dynamic>>(
      '/v1/auth/change-password',
      body: {
        'taiKhoanId': taiKhoanId,
        'matKhauHienTai': matKhauHienTai,
        'matKhauMoi': matKhauMoi,
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

  /// Gửi (lại) mã OTP qua tin nhắn SMS tới SĐT của tài khoản
  /// POST /v1/auth/otp/send
  /// [loaiTaiKhoan] (KhachHang | CongTacVien): SĐT có cả tài khoản khách hàng và tài khoản CTV riêng thì chọn tài khoản nào.
  Future<ApiResponse<Map<String, dynamic>>> sendOtp({
    required String identifier,
    String mucDich = 'DangKy',
    String? loaiTaiKhoan,
  }) async {
    return _apiClient.post<Map<String, dynamic>>(
      '/v1/auth/otp/send',
      body: {
        'identifier': identifier,
        'mucDich': mucDich,
        if (loaiTaiKhoan != null) 'loaiTaiKhoan': loaiTaiKhoan,
      },
    );
  }

  /// Quên mật khẩu: OTP (mucDich DatLaiMatKhau, nhận qua SMS từ [sendOtp]) + mật khẩu mới
  /// POST /v1/auth/password/reset
  Future<ApiResponse<Map<String, dynamic>>> resetPassword({
    required String identifier,
    required String maCode,
    required String matKhauMoi,
    String? loaiTaiKhoan,
  }) async {
    return _apiClient.post<Map<String, dynamic>>(
      '/v1/auth/password/reset',
      body: {
        'identifier': identifier,
        'maCode': maCode,
        'matKhauMoi': matKhauMoi,
        if (loaiTaiKhoan != null) 'loaiTaiKhoan': loaiTaiKhoan,
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
    String? vaiTro, // KhachHang | CongTacVien: một SĐT có thể có cả hai vai trò
  }) async {
    return _apiClient.post<Map<String, dynamic>>(
      '/v1/auth/login',
      body: {
        'tenDangNhap': username,
        'matKhau': matKhau,
        if (vaiTro != null) 'vaiTro': vaiTro,
      },
    );
  }
}
