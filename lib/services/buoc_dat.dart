import 'nhom_dich_vu.dart';
import 'rang_buoc_ngay_dat.dart';

/// Những gì khách đã chọn trên màn đặt, đủ để biết được sang bước sau hay chưa.
class DuLieuDat {
  final NhomDichVu? nhom;
  final String? loaiHinhDat;
  final int? dichVuId;
  final bool daChonGio;
  final bool coDiaChiTrongKhuVuc;
  final bool coDiaChiNao;
  final bool goiDuBuoi;
  final String? hinhThucThanhToan;

  const DuLieuDat({
    this.nhom,
    this.loaiHinhDat,
    this.dichVuId,
    this.daChonGio = false,
    this.coDiaChiTrongKhuVuc = false,
    this.coDiaChiNao = false,
    this.goiDuBuoi = false,
    this.hinhThucThanhToan,
  });
}

/// Quy tắc 5 bước của màn đặt (giống website):
/// 1 Dịch vụ → 2 Hình thức → 3 Thời gian → 4 Xác nhận → 5 Thanh toán.
class BuocDat {
  BuocDat._();

  static const soBuoc = 5;

  /// Dịch vụ chỉ có một hình thức (chỉ theo lần hoặc chỉ gói tháng) thì không cần bước 2.
  static bool boQuaBuoc2(NhomDichVu nhom) => !(nhom.coTheoLan && nhom.coGoiThang);

  static String loaiMacDinh(NhomDichVu nhom, {String? uuTien}) {
    if (uuTien == 'GoiThang' && nhom.coGoiThang) return 'GoiThang';
    if (uuTien == 'TheoLan' && nhom.coTheoLan) return 'TheoLan';
    return nhom.coTheoLan ? 'TheoLan' : 'GoiThang';
  }

  /// Mở màn đặt từ trang chi tiết dịch vụ: dịch vụ đã chọn sẵn nên bắt đầu ở bước 2 (hoặc 3).
  static int buocMoDau(NhomDichVu nhom) => boQuaBuoc2(nhom) ? 3 : 2;

  static int buocKe(int buoc, NhomDichVu nhom) {
    var ke = buoc + 1;
    if (ke == 2 && boQuaBuoc2(nhom)) ke = 3;
    return ke > soBuoc ? soBuoc : ke;
  }

  static int buocLui(int buoc, NhomDichVu nhom) {
    var lui = buoc - 1;
    if (lui == 2 && boQuaBuoc2(nhom)) lui = 1;
    return lui < 1 ? 1 : lui;
  }

  /// Câu lỗi chặn bước [buoc] (giống website), null nếu được sang bước sau.
  static String? loiBuoc(int buoc, DuLieuDat d) {
    switch (buoc) {
      case 1:
        return d.nhom == null ? 'Vui lòng chọn dịch vụ.' : null;
      case 2:
        final n = d.nhom;
        final hopLe = n != null &&
            ((d.loaiHinhDat == 'TheoLan' && n.coTheoLan) || (d.loaiHinhDat == 'GoiThang' && n.coGoiThang));
        return hopLe ? null : 'Vui lòng chọn theo lần hoặc gói tháng.';
      case 3:
        if (d.dichVuId == null) return 'Vui lòng chọn thời lượng / gói.';
        if (!d.daChonGio) return 'Vui lòng chọn giờ bắt đầu.';
        if (d.loaiHinhDat == 'GoiThang' && !d.goiDuBuoi) return 'Các thứ đã chọn chưa đủ số buổi của gói.';
        if (!d.coDiaChiNao) return 'Vui lòng chọn địa chỉ làm việc.';
        if (!d.coDiaChiTrongKhuVuc) {
          return 'Các địa chỉ đã lưu nằm ngoài khu vực phục vụ. Vui lòng thêm địa chỉ khác.';
        }
        return null;
      case 5:
        return d.hinhThucThanhToan == null ? 'Vui lòng chọn phương thức thanh toán.' : null;
      default:
        return null;
    }
  }

  /// Đổi hình thức đặt: ngày đang chọn vượt mốc tối đa của hình thức mới thì kéo về mốc đó.
  static DateTime keoNgay(DateTime ngay, String loaiHinhDat, DateTime homNay) {
    final toiDa = RangBuocNgayDat.ngayToiDa(loaiHinhDat, homNay);
    return ngay.isAfter(toiDa) ? toiDa : ngay;
  }
}
