import 'package:app_cung_cap_dich_vu_giup_viec/screens/customer/dat_dich_vu/thanh_buoc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Thanh bước của màn đặt: chỉ 3 bước, đánh số 1–3 (dịch vụ và hình thức đã chọn ở trang chi tiết).
void main() {
  testWidgets('Chỉ hiện Thời gian, Xác nhận, Thanh toán', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: ThanhBuoc(buoc: 3, daToi: 3, onChon: (_) {})),
    ));
    expect(find.text('Thời gian'), findsOneWidget);
    expect(find.text('Xác nhận'), findsOneWidget);
    expect(find.text('Thanh toán'), findsOneWidget);
    expect(find.text('Dịch vụ'), findsNothing);
    expect(find.text('Hình thức'), findsNothing);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('4'), findsNothing);
  });
}
