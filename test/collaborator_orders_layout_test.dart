import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_cung_cap_dich_vu_giup_viec/screens/collaborator/collaborator_orders_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'userId': 1,
    });
  });

  group('CollaboratorOrdersScreen - Layout Responsive Tests', () {
    testWidgets('Giao diện không bị overflow trên màn hình hẹp 320px', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: CollaboratorOrdersScreen(),
        ),
      );
      await tester.pump();

      // Kiểm tra tiêu đề và tabs xuất hiện không gây lỗi render
      expect(find.text('Quản lý công việc'), findsOneWidget);
      expect(find.text('Đã xong'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Giao diện không bị overflow trên màn hình 360px', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: CollaboratorOrdersScreen(),
        ),
      );
      await tester.pump();

      expect(find.text('Quản lý công việc'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
