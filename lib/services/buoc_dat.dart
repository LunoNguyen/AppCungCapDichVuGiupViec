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

/// Quy tắc các bước của màn đặt (giống website). Dịch vụ (bước 1) và hình thức & thời lượng (bước 2)
/// đã chọn ở trang chi tiết dịch vụ nên màn đặt chỉ hiện: 3 Thời gian → 4 Xác nhận → 5 Thanh toán
/// (đánh số 1–3 trên thanh bước). Bước 1, 2 vẫn được kiểm trong [loiBuoc] để chặn dữ liệu thiếu.
class BuocDat {
  BuocDat._();

  static const soBuoc = 5;
  static const buocDau = 3;
  static const cacBuoc = [3, 4, 5];

  static String loaiMacDinh(NhomDichVu nhom, {String? uuTien}) {
    if (uuTien == 'GoiThang' && nhom.coGoiThang) return 'GoiThang';
    if (uuTien == 'TheoLan' && nhom.coTheoLan) return 'TheoLan';
    return nhom.coTheoLan ? 'TheoLan' : 'GoiThang';
  }

  static int buocKe(int buoc) => buoc >= soBuoc ? soBuoc : buoc + 1;

  /// Ở bước đầu thì giữ nguyên: màn hình tự quay về trang chi tiết dịch vụ.
  static int buocLui(int buoc) => buoc <= buocDau ? buocDau : buoc - 1;

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
