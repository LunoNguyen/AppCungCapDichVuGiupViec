/// Đồng hồ đếm lùi trên app: luôn đếm từ số giây máy chủ trả (soGiayConLaiThanhToan, soGiayConLaiNhan),
/// không tự tính từ giờ thiết bị.
class DongHo {
  DongHo._();

  static bool hetGio(int? giay) => giay == null || giay <= 0;

  /// "MM:SS"; hết giờ, số âm hoặc không có hạn thì "00:00".
  static String mmss(int? giay) {
    if (hetGio(giay)) return '00:00';
    final g = giay!;
    return '${(g ~/ 60).toString().padLeft(2, '0')}:${(g % 60).toString().padLeft(2, '0')}';
  }
}
