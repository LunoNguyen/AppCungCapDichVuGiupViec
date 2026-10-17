import 'package:app_cung_cap_dich_vu_giup_viec/services/dong_ho.dart';
import 'package:flutter_test/flutter_test.dart';

/// Đồng hồ đếm lùi từ số giây máy chủ trả (hạn chuyển khoản, hạn có người nhận).
void main() {
  test('Định dạng mm:ss', () {
    expect(DongHo.mmss(907), '15:07');
    expect(DongHo.mmss(59), '00:59');
  });

  test('Hết giờ, số âm hoặc không có hạn đều là 00:00', () {
    expect(DongHo.mmss(0), '00:00');
    expect(DongHo.mmss(-5), '00:00');
    expect(DongHo.mmss(null), '00:00');
    expect(DongHo.hetGio(1), isFalse);
    expect(DongHo.hetGio(0), isTrue);
    expect(DongHo.hetGio(null), isTrue);
  });
}
