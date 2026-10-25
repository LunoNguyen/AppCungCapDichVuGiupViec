import 'package:app_cung_cap_dich_vu_giup_viec/widgets/anh_khong_cat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ảnh dịch vụ hiện trọn: lớp chính là BoxFit.contain (không cắt), lớp nền mờ là BoxFit.cover.
void main() {
  testWidgets('Ảnh chính không bị cắt, có nền mờ phía sau', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: SizedBox(
        width: 300,
        height: 120,
        child: AnhKhongCat(url: 'http://localhost/a.webp', thayThe: Icon(Icons.image)),
      ),
    ));
    final anh = tester.widgetList<Image>(find.byType(Image)).toList();
    expect(anh.map((i) => i.fit), [BoxFit.cover, BoxFit.contain]);
    expect(find.byType(ImageFiltered), findsOneWidget);
  });
}
