import 'auth_api_service.dart';
import 'collaborator_api_service.dart';
import 'session_service.dart';

class LoginResult {
  final UserSession? session;
  final String? error;

  /// Tài khoản chưa kích hoạt (chưa xác thực OTP) - có thể chuyển sang màn OTP
  final bool notActivated;

  /// CTV chưa có hồ sơ và app vừa tạo hồ sơ rỗng
  final bool profileCreated;

  const LoginResult._({
    this.session,
    this.error,
    this.notActivated = false,
    this.profileCreated = false,
  });

  factory LoginResult.ok(UserSession s, {bool profileCreated = false}) =>
      LoginResult._(session: s, profileCreated: profileCreated);
  factory LoginResult.fail(String msg, {bool notActivated = false}) =>
      LoginResult._(error: msg, notActivated: notActivated);

  bool get success => session != null;
}

/// Luồng đăng nhập chung: gọi API, kiểm tra đúng vai trò, lấy/tạo hồ sơ, lưu phiên.
class AuthFlow {
  static final AuthApiService _auth = AuthApiService();
  static final CollaboratorApiService _ctv = CollaboratorApiService();

  static int _int(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;

  static Future<LoginResult> login({
    required String phone,
    required String password,
    required bool asCustomer,
  }) async {
    final username = SessionService.normalizePhone(phone);
    final res = await _auth.login(username: username, matKhau: password);

    if (!res.success || res.data == null) {
      final msg = res.message ?? 'Đăng nhập thất bại. Vui lòng kiểm tra lại!';
      return LoginResult.fail(
        msg,
        notActivated: msg.toLowerCase().contains('chưa được kích hoạt'),
      );
    }

    final d = res.data!;
    final loai = d['loaiTaiKhoan']?.toString() ?? '';
    final taiKhoanId = _int(d['taiKhoanId']);
    final fullName = d['fullName']?.toString() ?? '';

    if (asCustomer) {
      if (loai != 'KhachHang') {
        return LoginResult.fail(
            'Tài khoản này không phải tài khoản Khách hàng. Vui lòng chọn đúng vai trò.');
      }
      final khachHangId = _int(d['khachHangId']);
      if (khachHangId == 0) {
        return LoginResult.fail(
            'Không tìm thấy hồ sơ khách hàng của tài khoản này. Vui lòng liên hệ hỗ trợ.');
      }
      final session = UserSession(
        role: UserSession.roleCustomer,
        userId: khachHangId,
        taiKhoanId: taiKhoanId,
        fullName: fullName,
        soDienThoai: d['soDienThoai']?.toString() ?? username,
        email: d['email']?.toString(),
        maNguoiDung: d['maKhachHang']?.toString(),
      );
      await SessionService.save(session);
      return LoginResult.ok(session);
    }

    // ---- Cộng tác viên ----
    if (loai != 'CongTacVien') {
      return LoginResult.fail(
          'Tài khoản này không phải tài khoản Cộng tác viên. Vui lòng chọn đúng vai trò.');
    }

    int ctvId = _int(d['congTacVienId']);
    String? maCtv = d['maCongTacVien']?.toString();
    String name = fullName;
    bool created = false;

    // Chưa có hồ sơ -> nhờ backend tạo hồ sơ rỗng (có rồi thì trả về hồ sơ đó)
    if (ctvId == 0) {
      final ensure = await _ctv.ensureProfile(taiKhoanId);
      if (!ensure.success || ensure.data == null) {
        return LoginResult.fail(
            ensure.message ?? 'Không thể khởi tạo hồ sơ Cộng tác viên.');
      }
      final p = ensure.data!;
      ctvId = _int(p['id']);
      maCtv = p['maCongTacVien']?.toString();
      created = p['daTaoMoi'] == true;
      final hoTen = p['hoTen']?.toString() ?? '';
      if (hoTen.isNotEmpty) name = hoTen;
    }

    final session = UserSession(
      role: UserSession.roleCollaborator,
      userId: ctvId,
      taiKhoanId: taiKhoanId,
      fullName: name,
      soDienThoai: username,
      maNguoiDung: maCtv,
    );
    await SessionService.save(session);
    return LoginResult.ok(session, profileCreated: created);
  }
}
