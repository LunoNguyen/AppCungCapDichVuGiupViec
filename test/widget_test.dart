import 'package:flutter_test/flutter_test.dart';
import 'package:app_cung_cap_dich_vu_giup_viec/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const HousekeepingApp());

    // Mở app là vào thẳng Trang chủ Khách hàng.
    expect(find.text('Trang chủ'), findsOneWidget);
    expect(find.text('Đăng nhập / Tạo tài khoản'), findsOneWidget);
  });
}
