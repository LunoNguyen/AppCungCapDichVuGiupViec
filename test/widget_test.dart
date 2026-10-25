import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_cung_cap_dich_vu_giup_viec/screens/customer/booking_screen.dart';

/// Smoke test màn đặt: mở từ trang chi tiết dịch vụ thì thấy thanh 5 bước, đang ở bước 2.
/// Gọi mạng trong test luôn lỗi – bước 1 hiện khung lỗi + Thử lại, dịch vụ vẫn chọn sẵn.
void main() {
  testWidgets('Màn đặt mở ở bước Hình thức với thanh 5 bước', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(
      home: BookingScreen(service: {
        'id': 2,
        'dichVuId': 2,
        'maDichVu': 'DV101',
        'tenDichVu': 'Dọn dẹp nhà theo giờ (2 giờ)',
        'title': 'Dọn dẹp nhà theo giờ (2 giờ)',
        'loaiDichVuId': 1,
        'loaiHinhDat': 'TheoLan',
        'donGiaThamKhao': 200000,
      }),
    ));
    await tester.pump();

    expect(find.text('Dịch vụ'), findsWidgets);
    expect(find.text('Thanh toán'), findsWidgets);
    expect(find.text('Hình thức'), findsOneWidget);
    // Bước 2: thanh chọn hình thức (một hàng) và dòng gợi ý của hình thức đang chọn
    expect(find.text('Theo lần'), findsOneWidget);
    expect(find.text('Gói tháng'), findsOneWidget);
    expect(find.text('Một buổi làm, chọn ngày trong vòng 1 tháng tới.'), findsOneWidget);

    // Xả các yêu cầu mạng đang chờ (timeout) trước khi kết thúc test
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 2));
  });
}
