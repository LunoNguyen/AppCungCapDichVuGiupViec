import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_cung_cap_dich_vu_giup_viec/widgets/app_time_picker.dart';

void main() {
  testWidgets('showAppTimePicker opens and allows selecting time', (tester) async {
    TimeOfDay? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  result = await showAppTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 8, minute: 0),
                  );
                },
                child: const Text('Mở chọn giờ'),
              );
            },
          ),
        ),
      ),
    );

    // Bấm nút mở time picker
    await tester.tap(find.text('Mở chọn giờ'));
    await tester.pumpAndSettle();

    // Kiểm tra hiển thị tiêu đề và đồng hồ số
    expect(find.text('Chọn giờ bắt đầu ca làm'), findsOneWidget);
    expect(find.text('08 : 00'), findsOneWidget);
    expect(find.text('☀️ Buổi sáng'), findsOneWidget);

    // Chạm chọn nhanh khung giờ 14:00 (buổi chiều)
    expect(find.text('14:00'), findsOneWidget);
    await tester.tap(find.text('14:00'));
    await tester.pumpAndSettle();

    // Kiểm tra đồng hồ số cập nhật sang 14 : 00 và Buổi chiều
    expect(find.text('14 : 00'), findsOneWidget);
    expect(find.text('🌤️ Buổi chiều'), findsOneWidget);

    // Bấm nút Xác nhận
    await tester.tap(find.text('Xác nhận giờ: 14:00'));
    await tester.pumpAndSettle();

    // Modal đóng và trả về đúng TimeOfDay(14, 0)
    expect(result, const TimeOfDay(hour: 14, minute: 0));
  });
}
