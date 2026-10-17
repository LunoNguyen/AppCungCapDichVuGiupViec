import 'package:app_cung_cap_dich_vu_giup_viec/widgets/danh_gia_don.dart';
import 'package:app_cung_cap_dich_vu_giup_viec/widgets/phan_hoi_btaskee.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('nhãn trạng thái', () {
    expect(nhanTrangThaiDanhGia('ChoDuyet'), 'Đang chờ bTaskee duyệt');
    expect(nhanTrangThaiDanhGia('HienThi'), 'Đang hiển thị công khai');
    expect(nhanTrangThaiDanhGia('An'), 'Không hiển thị công khai');
    expect(nhanTrangThaiDanhGia(null), isNull);
    expect(nhanTrangThaiDanhGia('DaDuyet'), isNull);
  });

  test('PhanHoiBTaskee.tuJson an toàn', () {
    expect(PhanHoiBTaskee.tuJson(null), isNull);
    expect(PhanHoiBTaskee.tuJson('abc'), isNull);
    expect(PhanHoiBTaskee.tuJson({'noiDung': ''}), isNull);
    expect(PhanHoiBTaskee.tuJson({'noiDung': 'Cảm ơn bạn'})?.noiDung, 'Cảm ơn bạn');
  });

  testWidgets('hiện khối phản hồi', (t) async {
    await t.pumpWidget(const MaterialApp(home: Scaffold(body: PhanHoiBTaskee(noiDung: 'Cảm ơn bạn'))));
    expect(find.text('Phản hồi từ bTaskee'), findsOneWidget);
    expect(find.text('Cảm ơn bạn'), findsOneWidget);
  });
}
