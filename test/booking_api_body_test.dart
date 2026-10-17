import 'package:app_cung_cap_dich_vu_giup_viec/services/booking_api_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Thân request tạo đơn: phương thức thanh toán phải gửi đúng tên trường máy chủ đọc.
void main() {
  test('Gửi hinhThucThanhToan, không gửi phuongThucThanhToan', () {
    final body = BookingApiService.bodyTaoDon(
      khachHangId: 1,
      dichVuId: 2,
      ngayThucHien: '2026-10-20',
      gioBatDau: '09:00',
      loaiHinhDat: 'TheoLan',
      hinhThucThanhToan: 'ChuyenKhoan',
    );
    expect(body['hinhThucThanhToan'], 'ChuyenKhoan');
    expect(body.containsKey('phuongThucThanhToan'), isFalse);
    expect(body['gioBatDau'], '09:00:00');
  });
}
