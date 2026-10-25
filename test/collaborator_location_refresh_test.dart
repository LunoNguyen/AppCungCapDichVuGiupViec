import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_cung_cap_dich_vu_giup_viec/services/ctv_location_tracker.dart';
import 'package:app_cung_cap_dich_vu_giup_viec/services/location_service.dart';
import 'package:app_cung_cap_dich_vu_giup_viec/screens/collaborator/collaborator_location_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Khu vực CTV - Chuyển từ Quận Bình Thạnh sang Quận Tân Phú khi refresh', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'userId': 1,
        'userRole': 'CONG_TAC_VIEN',
        'ctv_last_district_1': 'Quận Bình Thạnh',
      });
    });

    test('1. Ban đầu tài khoản lưu cache Quận Bình Thạnh trong SharedPreferences', () async {
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('ctv_last_district_1'), equals('Quận Bình Thạnh'));

      // Đặt giá trị ban đầu là Bình Thạnh
      CtvLocationTracker.instance.setDistrictForTest('Quận Bình Thạnh');
      expect(CtvLocationTracker.instance.currentDistrict, equals('Quận Bình Thạnh'));
    });

    test('2. Khi quét toạ độ Tân Phú, LocationService đoán đúng Quận Tân Phú', () {
      final quan = LocationService.doanQuanTheoToaDo(10.7901, 106.6281);
      expect(quan, equals('Quận Tân Phú'));
    });

    test('3. Khi refresh định vị sang Tân Phú, CtvLocationTracker phát thông báo và đổi sang Tân Phú', () async {
      final tracker = CtvLocationTracker.instance;
      tracker.setDistrictForTest('Quận Bình Thạnh');
      expect(tracker.currentDistrict, equals('Quận Bình Thạnh'));

      bool listenerNotified = false;
      tracker.addListener(() {
        listenerNotified = true;
      });

      // Kích hoạt cập nhật sang Quận Tân Phú
      tracker.setDistrictForTest('Quận Tân Phú');

      expect(listenerNotified, isTrue);
      expect(tracker.currentDistrict, equals('Quận Tân Phú'));
    });

    testWidgets('4. Widget giao diện tự động nhảy từ Quận Bình Thạnh sang Quận Tân Phú ngay lập tức', (tester) async {
      final tracker = CtvLocationTracker.instance;
      tracker.setDistrictForTest('Quận Bình Thạnh');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedBuilder(
              animation: tracker,
              builder: (context, _) {
                final district = tracker.currentDistrict ?? 'Đang lấy vị trí...';
                return Column(
                  children: [
                    Text('Khu vực hiện tại: $district'),
                  ],
                );
              },
            ),
          ),
        ),
      );

      // Ban đầu hiển thị Quận Bình Thạnh
      expect(find.text('Khu vực hiện tại: Quận Bình Thạnh'), findsOneWidget);
      expect(find.text('Khu vực hiện tại: Quận Tân Phú'), findsNothing);

      // Kích hoạt làm mới vị trí sang Tân Phú
      tracker.setDistrictForTest('Quận Tân Phú');
      await tester.pump();

      // Giao diện tự động cập nhật sang Quận Tân Phú mà không cần chuyển màn hình
      expect(find.text('Khu vực hiện tại: Quận Bình Thạnh'), findsNothing);
      expect(find.text('Khu vực hiện tại: Quận Tân Phú'), findsOneWidget);
    });

    testWidgets('5. Màn hình CollaboratorLocationScreen hiển thị đúng giao diện, không hiện kinh độ vĩ độ', (tester) async {
      final tracker = CtvLocationTracker.instance;
      tracker.setDistrictForTest('Quận Tân Phú');

      await tester.pumpWidget(
        const MaterialApp(
          home: CollaboratorLocationScreen(),
        ),
      );
      await tester.pump();

      // Kiểm tra tiêu đề và thông tin hiển thị
      expect(find.text('Khu vực & Vị trí nhận việc'), findsOneWidget);
      expect(find.text('Khu vực nhận việc hiện tại'), findsOneWidget);
      expect(find.text('Quận Tân Phú'), findsOneWidget);
      expect(find.text('Thành phố Hồ Chí Minh'), findsOneWidget);
      expect(find.text('Làm mới vị trí GPS ngay'), findsOneWidget);
      expect(find.text('Xem vị trí trên Google Maps'), findsOneWidget);

      // Đảm bảo không hiển thị kinh độ vĩ độ theo yêu cầu của người dùng
      expect(find.textContaining('Vĩ độ'), findsNothing);
      expect(find.textContaining('Kinh độ'), findsNothing);
      expect(find.textContaining('Latitude'), findsNothing);
      expect(find.textContaining('Longitude'), findsNothing);
    });
  });
}
