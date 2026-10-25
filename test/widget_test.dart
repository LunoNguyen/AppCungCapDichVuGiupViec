import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_cung_cap_dich_vu_giup_viec/screens/customer/booking_screen.dart';

/// Smoke test màn đặt: mở từ trang chi tiết dịch vụ thì vào thẳng bước Thời gian (thanh 3 bước),
/// có thẻ "Dịch vụ đã chọn"; "Đổi" quay về trang chi tiết. Gọi mạng trong test luôn lỗi.
void main() {
  testWidgets('Màn đặt mở ở bước Thời gian, chỉ 3 bước, "Đổi" quay về trang trước', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const BookingScreen(service: {
                  'id': 2,
                  'dichVuId': 2,
                  'maDichVu': 'DV101',
                  'tenDichVu': 'Dọn dẹp nhà theo giờ (2 giờ)',
                  'title': 'Dọn dẹp nhà theo giờ (2 giờ)',
                  'loaiDichVuId': 1,
                  'loaiHinhDat': 'TheoLan',
                  'thoiGianThucHienPhut': 120,
                  'donGiaThamKhao': 200000,
                }),
              ),
            ),
            child: const Text('Trang chi tiết'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Trang chi tiết'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5));

    // Thanh bước: 3 bước, không còn Dịch vụ / Hình thức
    expect(find.text('Thời gian'), findsOneWidget);
    expect(find.text('Xác nhận'), findsOneWidget);
    expect(find.text('Thanh toán'), findsOneWidget);
    expect(find.text('Hình thức'), findsNothing);
    // Thẻ dịch vụ đã chọn ở đầu bước Thời gian
    expect(find.text('Dịch vụ đã chọn'), findsOneWidget);
    expect(find.text('Ngày làm việc'), findsOneWidget);

    await tester.tap(find.text('Đổi'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5));
    expect(find.text('Trang chi tiết'), findsOneWidget);
    expect(find.text('Dịch vụ đã chọn'), findsNothing);

    // Xả các yêu cầu mạng đang chờ (timeout) trước khi kết thúc test
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 2));
  });
}
