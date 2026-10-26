import 'package:app_cung_cap_dich_vu_giup_viec/screens/customer/gio_hang_screen.dart';
import 'package:app_cung_cap_dich_vu_giup_viec/services/gio_hang.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Màn giỏ hàng: gói tháng đặt riêng, đếm và tổng tiền các dịch vụ đã chọn (giống web).
void main() {
  MonGio mon(int id, {String loai = 'TheoLan'}) =>
      MonGio(id: id, ten: 'Dịch vụ $id', gia: 100000, phut: 120, loaiHinhDat: loai, danhMucId: 1);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await GioHang.instance.tai();
    await GioHang.instance.xoaTatCa();
  });

  testWidgets('gói tháng có nút Đặt riêng, nút đặt đếm dịch vụ theo lần', (tester) async {
    await GioHang.instance.them(mon(1));
    await GioHang.instance.them(mon(2));
    await GioHang.instance.them(mon(3, loai: 'GoiThang'));
    await tester.pumpWidget(const MaterialApp(home: GioHangScreen()));
    await tester.pump();

    expect(find.text('Giỏ hàng (3)'), findsOneWidget);
    expect(find.text('Đặt riêng'), findsOneWidget);
    expect(find.text('Đặt dịch vụ (2)'), findsOneWidget);
    expect(find.text('200.000đ'), findsOneWidget);
  });

  testWidgets('giỏ trống thì mời khám phá dịch vụ', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: GioHangScreen()));
    await tester.pump();
    expect(find.text('Giỏ hàng của bạn đang trống'), findsOneWidget);
  });
}
