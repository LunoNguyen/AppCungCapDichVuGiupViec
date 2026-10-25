/// Quy tắc mật khẩu MỚI (đăng ký, đổi, đặt lại mật khẩu).
/// Cùng tiêu chí và câu báo lỗi với QuyTacMatKhau trên server (server mới là nơi quyết định).
/// Đăng nhập không kiểm tra quy tắc này: mật khẩu cũ vẫn dùng được.
class PasswordCriterion {
  final String key;
  final String label; // hiện trong danh sách tiêu chí
  final String error; // câu báo lỗi khi chưa đạt

  const PasswordCriterion(this.key, this.label, this.error);
}

class PasswordRules {
  PasswordRules._();

  static const int minLength = 8;

  static const List<PasswordCriterion> criteria = [
    PasswordCriterion('doDai', 'Ít nhất $minLength ký tự',
        'Mật khẩu cần ít nhất $minLength ký tự.'),
    PasswordCriterion(
        'chuCai', 'Có chữ cái', 'Mật khẩu cần có ít nhất một chữ cái.'),
    PasswordCriterion(
        'chuSo', 'Có chữ số', 'Mật khẩu cần có ít nhất một chữ số.'),
    PasswordCriterion('khoangTrang', 'Không có khoảng trắng',
        'Mật khẩu không được chứa khoảng trắng.'),
    PasswordCriterion('soDienThoai', 'Không chứa số điện thoại',
        'Mật khẩu không được chứa số điện thoại.'),
  ];

  static final RegExp _letter = RegExp(r'\p{L}', unicode: true);
  static final RegExp _digit = RegExp(r'[0-9]');
  static final RegExp _space = RegExp(r'\s');

  /// Kết quả từng tiêu chí, true là đạt.
  static Map<String, bool> evaluate(String password, [String? phone]) {
    return {
      'doDai': password.length >= minLength,
      'chuCai': _letter.hasMatch(password),
      'chuSo': _digit.hasMatch(password),
      'khoangTrang': !_space.hasMatch(password),
      'soDienThoai': !containsPhone(password, phone),
    };
  }

  /// Câu báo lỗi của các tiêu chí chưa đạt (rỗng khi hợp lệ).
  static List<String> errors(String password, [String? phone]) {
    final result = evaluate(password, phone);
    return [
      for (final c in criteria)
        if (result[c.key] != true) c.error,
    ];
  }

  static bool isValid(String password, [String? phone]) =>
      errors(password, phone).isEmpty;

  /// Dùng làm validator cho TextFormField: null khi hợp lệ.
  static String? validate(String? password, [String? phone]) {
    final list = errors(password ?? '', phone);
    return list.isEmpty ? null : list.first;
  }

  /// Chứa số điện thoại (chỉ lấy chữ số), kể cả dạng bỏ số 0 đầu.
  static bool containsPhone(String password, String? phone) {
    var sdt = (phone ?? '').replaceAll(RegExp(r'\D'), '');
    if (sdt.startsWith('84') && sdt.length >= 11) sdt = '0${sdt.substring(2)}';
    if (sdt.length < 6) return false;
    if (password.contains(sdt)) return true;
    return sdt.startsWith('0') && password.contains(sdt.substring(1));
  }
}
