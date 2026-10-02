import 'package:shared_preferences/shared_preferences.dart';

/// Phiên đăng nhập đã lưu trên máy.
/// [userId] là id theo vai trò: khachHangId (Khách hàng) hoặc congTacVienId (CTV).
class UserSession {
  static const roleCustomer = 'KHACH_HANG';
  static const roleCollaborator = 'CONG_TAC_VIEN';

  final String role;
  final int userId;
  final int taiKhoanId;
  final String fullName;
  final String soDienThoai;
  final String? email;
  final String? maNguoiDung;

  const UserSession({
    required this.role,
    required this.userId,
    required this.taiKhoanId,
    required this.fullName,
    required this.soDienThoai,
    this.email,
    this.maNguoiDung,
  });

  bool get isCustomer => role == roleCustomer;
  bool get isCollaborator => role == roleCollaborator;
}

/// Lưu / đọc / xoá phiên đăng nhập để lần sau mở app không cần đăng nhập lại.
class SessionService {
  static const _kRole = 'userRole';
  static const _kUserId = 'userId'; // các màn CTV đang đọc key này làm congTacVienId
  static const _kTaiKhoanId = 'taiKhoanId';
  static const _kFullName = 'fullName';
  static const _kPhone = 'soDienThoai';
  static const _kEmail = 'email';
  static const _kMa = 'maNguoiDung';
  static const _kToken = 'token';

  static Future<void> save(UserSession s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kRole, s.role);
    await prefs.setInt(_kUserId, s.userId);
    await prefs.setInt(_kTaiKhoanId, s.taiKhoanId);
    await prefs.setString(_kFullName, s.fullName);
    await prefs.setString(_kPhone, s.soDienThoai);
    if (s.email != null) await prefs.setString(_kEmail, s.email!);
    if (s.maNguoiDung != null) await prefs.setString(_kMa, s.maNguoiDung!);
  }

  /// Trả về null nếu chưa đăng nhập.
  static Future<UserSession?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString(_kRole);
    final userId = prefs.getInt(_kUserId) ?? 0;
    if (role == null || userId == 0) return null;
    return UserSession(
      role: role,
      userId: userId,
      taiKhoanId: prefs.getInt(_kTaiKhoanId) ?? 0,
      fullName: prefs.getString(_kFullName) ?? '',
      soDienThoai: prefs.getString(_kPhone) ?? '',
      email: prefs.getString(_kEmail),
      maNguoiDung: prefs.getString(_kMa),
    );
  }

  static Future<void> updateFullName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kFullName, name);
  }

  /// Xoá phiên đăng nhập, giữ lại các cài đặt khác (VD: bật/tắt thông báo).
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    for (final k in [_kRole, _kUserId, _kTaiKhoanId, _kFullName, _kPhone, _kEmail, _kMa, _kToken]) {
      await prefs.remove(k);
    }
  }

  /// Chuẩn hoá SĐT về dạng 0xxxxxxxxx (backend dùng SĐT làm tên đăng nhập).
  static String normalizePhone(String raw) {
    var p = raw.replaceAll(RegExp(r'[\s.\-()]'), '');
    if (!RegExp(r'^\+?\d+$').hasMatch(p)) return raw.trim(); // không phải SĐT -> giữ nguyên
    if (p.startsWith('+84')) p = '0${p.substring(3)}';
    if (p.startsWith('84') && p.length == 11) p = '0${p.substring(2)}';
    if (!p.startsWith('0') && p.length == 9) p = '0$p';
    return p;
  }
}
