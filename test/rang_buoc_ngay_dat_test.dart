import 'package:app_cung_cap_dich_vu_giup_viec/services/rang_buoc_ngay_dat.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ràng buộc ngày đặt: cùng quy tắc và câu lỗi với máy chủ (RangBuocNgayDat.java).
void main() {
  final bayGio = DateTime(2026, 1, 31, 8, 0);

  test('Cộng tháng kẹp về ngày cuối tháng như Java plusMonths', () {
    expect(RangBuocNgayDat.congThang(DateTime(2026, 1, 31), 1), DateTime(2026, 2, 28));
    expect(RangBuocNgayDat.congThang(DateTime(2028, 1, 31), 1), DateTime(2028, 2, 29));
    expect(RangBuocNgayDat.congThang(DateTime(2026, 11, 30), 3), DateTime(2027, 2, 28));
  });

  test('Ngày tối đa: theo lần 1 tháng, gói tháng 3 tháng', () {
    expect(RangBuocNgayDat.ngayToiDa('TheoLan', DateTime(2026, 1, 31)), DateTime(2026, 2, 28));
    expect(RangBuocNgayDat.ngayToiDa('GoiThang', DateTime(2026, 1, 31)), DateTime(2026, 4, 30));
  });

  test('Theo lần chỉ trong vòng 1 tháng', () {
    expect(RangBuocNgayDat.loiNgayDat('TheoLan', DateTime(2026, 2, 28), 9, 0, bayGio), isNull);
    expect(RangBuocNgayDat.loiNgayDat('TheoLan', DateTime(2026, 3, 1), 9, 0, bayGio),
        'Đặt theo lần chỉ được chọn ngày trong vòng 1 tháng tới (đến 28/02/2026).');
  });

  test('Gói tháng bắt đầu trong vòng 3 tháng', () {
    expect(RangBuocNgayDat.loiNgayDat('GoiThang', DateTime(2026, 4, 30), 9, 0, bayGio), isNull);
    expect(RangBuocNgayDat.loiNgayDat('GoiThang', DateTime(2026, 5, 1), 9, 0, bayGio),
        'Gói tháng chỉ được bắt đầu trong vòng 3 tháng tới (đến 30/04/2026).');
  });

  test('Không chọn quá khứ, giờ bắt đầu sau hiện tại ít nhất 1 giờ', () {
    expect(RangBuocNgayDat.loiNgayDat('TheoLan', DateTime(2026, 1, 30), 9, 0, bayGio),
        'Ngày thực hiện không được ở quá khứ.');
    expect(RangBuocNgayDat.loiNgayDat('TheoLan', DateTime(2026, 1, 31), 8, 30, bayGio),
        'Giờ bắt đầu cần sau thời điểm hiện tại ít nhất 1 giờ.');
    expect(RangBuocNgayDat.loiNgayDat('TheoLan', DateTime(2026, 1, 31), 9, 0, bayGio), isNull);
  });

  test('Thiếu ngày hoặc giờ', () {
    expect(RangBuocNgayDat.loiNgayDat('TheoLan', null, 9, 0, bayGio), 'Vui lòng chọn ngày và giờ bắt đầu.');
    expect(RangBuocNgayDat.loiNgayDat('TheoLan', DateTime(2026, 2, 1), null, null, bayGio),
        'Vui lòng chọn ngày và giờ bắt đầu.');
  });
}
