import 'package:app_cung_cap_dich_vu_giup_viec/services/buoc_dat.dart';
import 'package:app_cung_cap_dich_vu_giup_viec/services/nhom_dich_vu.dart';
import 'package:flutter_test/flutter_test.dart';

/// Quy tắc chuyển giữa 5 bước của màn đặt (giống website).
void main() {
  NhomDichVu nhom({required bool theoLan, required bool goi}) => NhomDichVu(
        ma: 'DV101',
        ten: 'Dọn dẹp nhà theo giờ',
        giaTu: 216000,
        coTheoLan: theoLan,
        coGoiThang: goi,
        bienThe: const [],
      );

  test('Dịch vụ chỉ có gói tháng: bỏ qua bước 2, mở ở bước 3', () {
    final n = nhom(theoLan: false, goi: true);
    expect(BuocDat.boQuaBuoc2(n), isTrue);
    expect(BuocDat.buocMoDau(n), 3);
    expect(BuocDat.loaiMacDinh(n), 'GoiThang');
    expect(BuocDat.buocKe(1, n), 3);
    expect(BuocDat.buocLui(3, n), 1);
  });

  test('Dịch vụ có đủ hai hình thức: đi đủ 5 bước', () {
    final n = nhom(theoLan: true, goi: true);
    expect(BuocDat.buocMoDau(n), 2);
    expect(BuocDat.buocKe(1, n), 2);
    expect(BuocDat.buocLui(3, n), 2);
    expect(BuocDat.buocKe(5, n), 5);
    expect(BuocDat.buocLui(1, n), 1);
    expect(BuocDat.loaiMacDinh(n, uuTien: 'GoiThang'), 'GoiThang');
    expect(BuocDat.loaiMacDinh(n), 'TheoLan');
  });

  test('Điều kiện chặn từng bước', () {
    final n = nhom(theoLan: true, goi: true);
    expect(BuocDat.loiBuoc(1, DuLieuDat()), 'Vui lòng chọn dịch vụ.');
    expect(BuocDat.loiBuoc(2, DuLieuDat(nhom: n)), 'Vui lòng chọn theo lần hoặc gói tháng.');
    expect(BuocDat.loiBuoc(3, DuLieuDat(nhom: n, loaiHinhDat: 'TheoLan')), 'Vui lòng chọn thời lượng / gói.');
    expect(BuocDat.loiBuoc(3, DuLieuDat(nhom: n, loaiHinhDat: 'TheoLan', dichVuId: 1)), 'Vui lòng chọn giờ bắt đầu.');
    expect(
        BuocDat.loiBuoc(3, DuLieuDat(nhom: n, loaiHinhDat: 'GoiThang', dichVuId: 1, daChonGio: true,
            coDiaChiNao: true, coDiaChiTrongKhuVuc: true, goiDuBuoi: false)),
        'Các thứ đã chọn chưa đủ số buổi của gói.');
    expect(
        BuocDat.loiBuoc(3, DuLieuDat(nhom: n, loaiHinhDat: 'TheoLan', dichVuId: 1, daChonGio: true,
            coDiaChiNao: true, coDiaChiTrongKhuVuc: false)),
        'Các địa chỉ đã lưu nằm ngoài khu vực phục vụ. Vui lòng thêm địa chỉ khác.');
    expect(
        BuocDat.loiBuoc(3, DuLieuDat(nhom: n, loaiHinhDat: 'TheoLan', dichVuId: 1, daChonGio: true)),
        'Vui lòng chọn địa chỉ làm việc.');
    expect(
        BuocDat.loiBuoc(3, DuLieuDat(nhom: n, loaiHinhDat: 'TheoLan', dichVuId: 1, daChonGio: true,
            coDiaChiNao: true, coDiaChiTrongKhuVuc: true)),
        isNull);
    expect(BuocDat.loiBuoc(4, DuLieuDat()), isNull);
    expect(BuocDat.loiBuoc(5, DuLieuDat()), 'Vui lòng chọn phương thức thanh toán.');
    expect(BuocDat.loiBuoc(5, DuLieuDat(hinhThucThanhToan: 'TienMat')), isNull);
  });

  test('Đổi hình thức thì kéo ngày về mốc tối đa', () {
    final homNay = DateTime(2026, 1, 31);
    expect(BuocDat.keoNgay(DateTime(2026, 3, 20), 'TheoLan', homNay), DateTime(2026, 2, 28));
    expect(BuocDat.keoNgay(DateTime(2026, 3, 20), 'GoiThang', homNay), DateTime(2026, 3, 20));
  });
}
