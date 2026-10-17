/// Ràng buộc ngày giờ khi đặt dịch vụ, cùng quy tắc và câu lỗi với máy chủ (RangBuocNgayDat.java):
/// - không chọn ngày quá khứ, giờ bắt đầu sau hiện tại ít nhất 1 giờ;
/// - đặt theo lần: ngày làm trong vòng 1 tháng tới;
/// - gói tháng (kéo dài 1 tháng): ngày bắt đầu gói trong vòng 3 tháng tới.
/// Máy chủ vẫn kiểm lại khi tạo đơn.
class RangBuocNgayDat {
  RangBuocNgayDat._();

  /// Cộng tháng như Java plusMonths: ngày vượt số ngày của tháng đích thì kẹp về ngày cuối tháng
  /// (31/01 + 1 tháng = 28/02 hoặc 29/02). Chỉ giữ phần ngày.
  static DateTime congThang(DateTime ngay, int soThang) {
    final dauThangDich = DateTime(ngay.year, ngay.month + soThang, 1);
    final soNgayThangDich = DateTime(dauThangDich.year, dauThangDich.month + 1, 0).day;
    final ngayDich = ngay.day <= soNgayThangDich ? ngay.day : soNgayThangDich;
    return DateTime(dauThangDich.year, dauThangDich.month, ngayDich);
  }

  /// Ngày muộn nhất được chọn (gói tháng: ngày bắt đầu gói).
  static DateTime ngayToiDa(String loaiHinhDat, DateTime homNay) =>
      loaiHinhDat == 'GoiThang' ? congThang(homNay, 3) : congThang(homNay, 1);

  static String _dd(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  /// null nếu ngày giờ hợp lệ; ngược lại là câu lỗi cho khách.
  static String? loiNgayDat(String loaiHinhDat, DateTime? ngay, int? gio, int? phut, DateTime bayGio) {
    if (ngay == null || gio == null) return 'Vui lòng chọn ngày và giờ bắt đầu.';
    final homNay = DateTime(bayGio.year, bayGio.month, bayGio.day);
    final ngayChon = DateTime(ngay.year, ngay.month, ngay.day);
    if (ngayChon.isBefore(homNay)) return 'Ngày thực hiện không được ở quá khứ.';
    final toiDa = ngayToiDa(loaiHinhDat, homNay);
    if (ngayChon.isAfter(toiDa)) {
      return loaiHinhDat == 'GoiThang'
          ? 'Gói tháng chỉ được bắt đầu trong vòng 3 tháng tới (đến ${_dd(toiDa)}).'
          : 'Đặt theo lần chỉ được chọn ngày trong vòng 1 tháng tới (đến ${_dd(toiDa)}).';
    }
    final batDau = DateTime(ngay.year, ngay.month, ngay.day, gio, phut ?? 0);
    if (batDau.isBefore(bayGio.add(const Duration(hours: 1)))) {
      return 'Giờ bắt đầu cần sau thời điểm hiện tại ít nhất 1 giờ.';
    }
    return null;
  }
}
