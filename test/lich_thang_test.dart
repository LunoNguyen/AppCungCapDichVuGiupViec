import 'package:app_cung_cap_dich_vu_giup_viec/services/lich_goi_thang.dart';
import 'package:app_cung_cap_dich_vu_giup_viec/widgets/lich_thang.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget boc(Widget w) => MaterialApp(home: Scaffold(body: SingleChildScrollView(child: w)));

  testWidgets('Chỉ chọn được ngày trong khoảng, ngày ngoài khoảng không phản hồi', (tester) async {
    final dau = DateTime(2026, 10, 12);
    final cuoi = DateTime(2026, 10, 20);
    DateTime? chon;
    await tester.pumpWidget(boc(LichThang(
      ngayChon: dau,
      ngayDau: dau,
      ngayCuoi: cuoi,
      onChon: (d) => chon = d,
    )));

    expect(find.text('Tháng 10, 2026'), findsOneWidget);
    // 15/10 trong khoảng
    await tester.tap(find.text('15'));
    expect(chon, DateTime(2026, 10, 15));
    // 5/10 trước ngày đầu: không chọn được
    chon = null;
    await tester.tap(find.text('5'));
    expect(chon, isNull);
    // 25/10 sau ngày cuối: không chọn được
    await tester.tap(find.text('25'));
    expect(chon, isNull);
  });

  testWidgets('Không lùi về tháng trước ngày đầu, không tiến quá tháng của ngày cuối', (tester) async {
    await tester.pumpWidget(boc(LichThang(
      ngayChon: DateTime(2026, 10, 12),
      ngayDau: DateTime(2026, 10, 12),
      ngayCuoi: DateTime(2026, 11, 30),
      onChon: (_) {},
    )));
    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pump();
    expect(find.text('Tháng 10, 2026'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pump();
    expect(find.text('Tháng 11, 2026'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pump();
    expect(find.text('Tháng 11, 2026'), findsOneWidget);
  });

  test('Mẫu T2 · T4 · T6 và T3 · T5 · T7 xếp đủ 12 buổi trong 1 tháng', () {
    final batDau = DateTime(2026, 10, 12); // thứ Hai
    final l246 = LichGoiThang.tinhLich(batDau, LichGoiThang.mau['T2 · T4 · T6']!, 12);
    expect(l246.length, 12);
    expect(l246.first, DateTime(2026, 10, 12));
    expect(l246.every((d) => {1, 3, 5}.contains(d.weekday)), isTrue);
    expect(LichGoiThang.loiThieu(l246, 12, {1, 3, 5}), isNull);

    final l357 = LichGoiThang.tinhLich(batDau, LichGoiThang.mau['T3 · T5 · T7']!, 12);
    expect(l357.first, DateTime(2026, 10, 13));
    expect(LichGoiThang.maThu({2, 4, 6}), '3,5,7');
  });
}
