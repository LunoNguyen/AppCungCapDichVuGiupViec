import 'package:app_cung_cap_dich_vu_giup_viec/screens/customer/gio_hang_screen.dart';
import 'package:app_cung_cap_dich_vu_giup_viec/services/gio_hang.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Màn giỏ hàng: mọi dịch vụ đều tick được (không có nút Đặt riêng), đếm và tổng tiền đã chọn (giống web).
void main() {
  MonGio mon(int id, {String loai = 'TheoLan'}) =>
      MonGio(id: id, ten: 'Dịch vụ $id', gia: 100000, phut: 120, loaiHinhDat: loai, danhMucId: 1);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await GioHang.instance.tai();
    await GioHang.instance.xoaTatCa();
  });

  testWidgets('không có nút Đặt riêng, gói tháng chọn chung thì báo lý do', (tester) async {
    await GioHang.instance.them(mon(1));
    await GioHang.instance.them(mon(2));
    await GioHang.instance.them(mon(3, loai: 'GoiThang'));
    await tester.pumpWidget(const MaterialApp(home: GioHangScreen()));
    await tester.pump();

    expect(find.text('Giỏ hàng (3)'), findsOneWidget);
    expect(find.text('Đặt riêng'), findsNothing);
    expect(find.byType(Checkbox), findsNWidgets(4)); // 3 dịch vụ + chọn tất cả
    expect(find.text('Đặt dịch vụ (3)'), findsOneWidget);
    expect(find.text('300.000đ'), findsOneWidget);
    expect(find.text('Gói tháng không đặt chung với dịch vụ khác, hãy chọn riêng gói tháng.'), findsOneWidget);
  });

  testWidgets('giỏ trống thì mời khám phá dịch vụ', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: GioHangScreen()));
    await tester.pump();
    expect(find.text('Giỏ hàng của bạn đang trống'), findsOneWidget);
  });
}
