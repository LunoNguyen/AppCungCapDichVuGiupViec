import 'package:flutter_test/flutter_test.dart';
import 'package:app_cung_cap_dich_vu_giup_viec/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const HousekeepingApp());

    // Verify that our app header renders.
    expect(find.text('ỨNG DỤNG GIÚP VIỆC TIỆN ÍCH'), findsOneWidget);
  });
}
