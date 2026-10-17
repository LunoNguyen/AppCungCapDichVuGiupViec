import 'package:app_cung_cap_dich_vu_giup_viec/services/ctv_location_tracker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t0 = DateTime(2026, 10, 17, 9, 0, 0);

  test('chưa tra lần nào thì tra ngay', () {
    expect(canTraLaiDiaChi(null, null, null, 10.80, 106.70, t0), isTrue);
  });

  test('đứng gần chỗ cũ và chưa đủ 60 giây thì dùng lại quận đã tra', () {
    // ~50 m, sau 20 giây
    expect(canTraLaiDiaChi(10.8000, 106.7000, t0, 10.8004, 106.7001, t0.add(const Duration(seconds: 20))), isFalse);
  });

  test('đi xa hơn 200 m thì tra lại', () {
    // ~550 m về phía bắc
    expect(canTraLaiDiaChi(10.8000, 106.7000, t0, 10.8050, 106.7000, t0.add(const Duration(seconds: 10))), isTrue);
  });

  test('đủ 60 giây thì tra lại dù đứng yên', () {
    expect(canTraLaiDiaChi(10.8000, 106.7000, t0, 10.8000, 106.7000, t0.add(const Duration(seconds: 60))), isTrue);
  });
}
