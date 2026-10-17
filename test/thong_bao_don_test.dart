import 'package:app_cung_cap_dich_vu_giup_viec/services/thong_bao_don.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lấy mã đơn từ tiêu đề / nội dung thông báo', () {
    expect(maDonTrongThongBao('Đơn DD-HNAHFYF09K đã hoàn thành'), 'DD-HNAHFYF09K');
    expect(maDonTrongThongBao('bTaskee đã phản hồi đánh giá đơn DD-ABC123'), 'DD-ABC123');
    expect(maDonTrongThongBao('Đơn DD-X1 (Dọn dẹp nhà, 17:00 ngày 17/10/2026)'), 'DD-X1');
  });

  test('không phải thông báo đơn thì trả null', () {
    expect(maDonTrongThongBao('Ưu đãi mới: giảm 20% với mã KM-ABC'), isNull);
    expect(maDonTrongThongBao(''), isNull);
    expect(maDonTrongThongBao('ADD-123 không phải mã đơn'), isNull);
  });

  test('tìm id đơn theo mã trong danh sách đơn của khách', () {
    final ds = [
      {'id': 5, 'maDonDat': 'DD-AAA'},
      {'id': '7', 'maDonDat': 'DD-BBB'},
    ];
    expect(idDonTheoMa(ds, 'DD-AAA'), 5);
    expect(idDonTheoMa(ds, 'DD-BBB'), 7);
    expect(idDonTheoMa(ds, 'DD-CCC'), isNull);
  });
}
