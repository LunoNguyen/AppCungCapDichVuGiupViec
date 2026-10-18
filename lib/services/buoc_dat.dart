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

  /// Câu lỗi ngày giờ của RangBuocNgayDat (trùng máy chủ), null nếu hợp lệ.
  final String? loiNgayGio;

  const DuLieuDat({
    this.nhom,
    this.loaiHinhDat,
    this.dichVuId,
    this.daChonGio = false,
    this.coDiaChiTrongKhuVuc = false,
    this.coDiaChiNao = false,
    this.goiDuBuoi = false,
    this.hinhThucThanhToan,
    this.loiNgayGio,
  });
}

/// Quy tắc 5 bước của màn đặt (giống website):
/// 1 Dịch vụ → 2 Hình thức & thời lượng → 3 Thời gian → 4 Xác nhận → 5 Thanh toán.
class BuocDat {
  BuocDat._();

  static const soBuoc = 5;

  /// Bước 2 chọn hình thức và thời lượng / gói: dịch vụ chỉ có đúng một lựa chọn thì không cần bước này.
  static bool boQuaBuoc2(NhomDichVu nhom) => nhom.bienThe.length <= 1;

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
        if (!hopLe) return 'Vui lòng chọn theo lần hoặc gói tháng.';
        return d.dichVuId == null ? 'Vui lòng chọn thời lượng / gói.' : null;
      case 3:
        if (!d.daChonGio) return 'Vui lòng chọn giờ bắt đầu.';
        if (d.loiNgayGio != null) return d.loiNgayGio;
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

  /// Bước đầu tiên trước [den] còn chặn (đi thẳng qua thanh bước hoặc gửi đơn với [den] = 6), null nếu đi được.
  static int? buocChan(int den, DuLieuDat d) {
    for (var b = 1; b < den && b <= soBuoc; b++) {
      if (loiBuoc(b, d) != null) return b;
    }
    return null;
  }

  /// Đổi hình thức đặt: ngày đang chọn vượt mốc tối đa của hình thức mới thì kéo về mốc đó.
  static DateTime keoNgay(DateTime ngay, String loaiHinhDat, DateTime homNay) {
    final toiDa = RangBuocNgayDat.ngayToiDa(loaiHinhDat, homNay);
    return ngay.isAfter(toiDa) ? toiDa : ngay;
  }
}
