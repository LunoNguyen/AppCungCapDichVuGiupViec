import 'package:app_cung_cap_dich_vu_giup_viec/services/buoc_dat.dart';
import 'package:app_cung_cap_dich_vu_giup_viec/services/nhom_dich_vu.dart';
import 'package:flutter_test/flutter_test.dart';

/// Quy tắc chuyển giữa các bước của màn đặt (giống website).
void main() {
  // Biến thể mặc định: theo lần 2 giờ + gói tháng (tuỳ cờ)
  NhomDichVu nhom({required bool theoLan, required bool goi, List<Map<String, dynamic>>? bienThe}) => NhomDichVu(
        ma: 'DV101',
        ten: 'Dọn dẹp nhà theo giờ',
        giaTu: 216000,
        coTheoLan: theoLan,
        coGoiThang: goi,
        bienThe: bienThe ??
            [
              if (theoLan) {'id': 1, 'loaiHinhDat': 'TheoLan'},
              if (goi) {'id': 2, 'loaiHinhDat': 'GoiThang'},
            ],
      );

  test('Màn đặt chỉ còn 3 bước: Thời gian → Xác nhận → Thanh toán (dịch vụ chọn ở trang chi tiết)', () {
    expect(BuocDat.buocDau, 3);
    expect(BuocDat.cacBuoc, [3, 4, 5]);
    expect(BuocDat.buocKe(3), 4);
    expect(BuocDat.buocKe(4), 5);
    expect(BuocDat.buocKe(5), 5);
    expect(BuocDat.buocLui(5), 4);
    expect(BuocDat.buocLui(4), 3);
    expect(BuocDat.buocLui(3), 3); // bước đầu: màn hình tự quay về trang chi tiết
  });

  test('Hình thức mặc định theo biến thể đã chọn', () {
    final n = nhom(theoLan: true, goi: true);
    expect(BuocDat.loaiMacDinh(n, uuTien: 'GoiThang'), 'GoiThang');
    expect(BuocDat.loaiMacDinh(n), 'TheoLan');
    expect(BuocDat.loaiMacDinh(nhom(theoLan: false, goi: true)), 'GoiThang');
  });

  test('Điều kiện chặn từng bước', () {
    final n = nhom(theoLan: true, goi: true);
    expect(BuocDat.loiBuoc(1, DuLieuDat()), 'Vui lòng chọn dịch vụ.');
    expect(BuocDat.loiBuoc(2, DuLieuDat(nhom: n)), 'Vui lòng chọn theo lần hoặc gói tháng.');
    // Thời lượng / gói chọn ở bước 2, cùng hình thức
    expect(BuocDat.loiBuoc(2, DuLieuDat(nhom: n, loaiHinhDat: 'TheoLan')), 'Vui lòng chọn thời lượng / gói.');
    expect(BuocDat.loiBuoc(2, DuLieuDat(nhom: n, loaiHinhDat: 'TheoLan', dichVuId: 1)), isNull);
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

  test('Nhảy tới bước sau qua thanh bước: chặn ở bước đầu tiên chưa hợp lệ', () {
    final n = nhom(theoLan: true, goi: true);
    final d = DuLieuDat(
      nhom: n,
      loaiHinhDat: 'TheoLan',
      dichVuId: 7,
      daChonGio: true,
      coDiaChiNao: true,
      coDiaChiTrongKhuVuc: true,
      hinhThucThanhToan: 'TienMat',
    );
    expect(BuocDat.buocChan(5, d), isNull);
    expect(BuocDat.buocChan(6, d), isNull); // gửi đơn: kiểm cả 5 bước

    final chuaGio = DuLieuDat(nhom: n, loaiHinhDat: 'TheoLan', dichVuId: 7, coDiaChiNao: true, coDiaChiTrongKhuVuc: true);
    expect(BuocDat.buocChan(5, chuaGio), 3);
    expect(BuocDat.buocChan(3, chuaGio), isNull);

    // Lỗi ngày giờ (câu của RangBuocNgayDat) cũng chặn bước 3
    final quaHan = DuLieuDat(
      nhom: n,
      loaiHinhDat: 'TheoLan',
      dichVuId: 7,
      daChonGio: true,
      coDiaChiNao: true,
      coDiaChiTrongKhuVuc: true,
      loiNgayGio: 'Ngày thực hiện không được ở quá khứ.',
    );
    expect(BuocDat.loiBuoc(3, quaHan), 'Ngày thực hiện không được ở quá khứ.');
    expect(BuocDat.buocChan(4, quaHan), 3);

    // Thiếu phương thức thanh toán chỉ chặn khi gửi đơn
    expect(BuocDat.buocChan(6, chuaGio), 3);
    final chuaTT = DuLieuDat(nhom: n, loaiHinhDat: 'TheoLan', dichVuId: 7, daChonGio: true, coDiaChiNao: true, coDiaChiTrongKhuVuc: true);
    expect(BuocDat.buocChan(5, chuaTT), isNull);
    expect(BuocDat.buocChan(6, chuaTT), 5);
  });
}
