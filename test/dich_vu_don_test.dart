import 'package:app_cung_cap_dich_vu_giup_viec/services/dich_vu_don.dart';
import 'package:flutter_test/flutter_test.dart';

/// Đơn nhiều dịch vụ: CTV chọn dịch vụ muốn nhận; mặc định mọi dịch vụ còn trống mà CTV làm được.
void main() {
  test('chonMacDinh lấy dòng còn trống và có kỹ năng', () {
    final ds = [
      DichVuDon.fromJson({'chiTietId': 10, 'tenDichVu': 'A', 'thoiGianPhut': 120, 'daCoNguoiNhan': false, 'ctvCoKyNang': true}),
      DichVuDon.fromJson({'chiTietId': 11, 'tenDichVu': 'B', 'thoiGianPhut': 45, 'daCoNguoiNhan': true, 'ctvCoKyNang': true}),
      DichVuDon.fromJson({'chiTietId': 12, 'tenDichVu': 'C', 'thoiGianPhut': 60, 'daCoNguoiNhan': false, 'ctvCoKyNang': false}),
    ];
    expect(DichVuDon.chonMacDinh(ds), [10]);
  });

  test('thiếu trường thì coi như không nhận được', () {
    expect(DichVuDon.fromJson({'chiTietId': 1}).nhanDuoc, isFalse);
  });
}
