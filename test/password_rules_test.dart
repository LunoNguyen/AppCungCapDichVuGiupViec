import 'package:app_cung_cap_dich_vu_giup_viec/core/password_rules.dart';
import 'package:app_cung_cap_dich_vu_giup_viec/widgets/password_checklist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Cùng bộ ca với QuyTacMatKhauTest phía server
void main() {
  const sdt = '0912345678';
  final c = {for (final x in PasswordRules.criteria) x.key: x.error};

  test('mật khẩu đạt đủ tiêu chí là hợp lệ', () {
    expect(PasswordRules.isValid('matkhau1', sdt), isTrue);
    expect(PasswordRules.isValid('Abc12345', sdt), isTrue);
    expect(PasswordRules.isValid('đẹptrai9', sdt), isTrue);
    expect(PasswordRules.isValid('a1!@#\$%^'), isTrue);
  });

  test('ngắn hơn 8 ký tự bị từ chối', () {
    expect(PasswordRules.errors('abc1234', sdt), [c['doDai']]);
    expect(PasswordRules.isValid('abc12345', sdt), isTrue);
  });

  test('thiếu chữ cái hoặc chữ số', () {
    expect(PasswordRules.errors('12345678'), [c['chuCai']]);
    expect(PasswordRules.errors('abcdefgh'), [c['chuSo']]);
  });

  test('không được chứa khoảng trắng', () {
    expect(PasswordRules.errors('abc 12345'), [c['khoangTrang']]);
  });

  test('không được chứa số điện thoại', () {
    expect(PasswordRules.errors('a0912345678', sdt), [c['soDienThoai']]);
    expect(PasswordRules.errors('x912345678', sdt), [c['soDienThoai']]);
    expect(PasswordRules.errors('a0912345678', '+84 912 345 678'), [c['soDienThoai']]);
    expect(PasswordRules.isValid('a091234567', sdt), isTrue);
    expect(PasswordRules.isValid('abc12345', '123'), isTrue);
  });

  test('validate trả lỗi đầu tiên hoặc null', () {
    expect(PasswordRules.validate('123456', sdt), 'Mật khẩu cần ít nhất 8 ký tự.');
    expect(PasswordRules.validate(null), 'Mật khẩu cần ít nhất 8 ký tự.');
    expect(PasswordRules.validate('matkhau1', sdt), isNull);
  });

  testWidgets('danh sách tiêu chí đánh dấu tiêu chí đạt', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: PasswordChecklist(password: 'abc', phone: sdt)),
    ));
    expect(find.text('Ít nhất 8 ký tự'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsNWidgets(3)); // chữ cái, khoảng trắng, SĐT
    expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(2));
  });
}
