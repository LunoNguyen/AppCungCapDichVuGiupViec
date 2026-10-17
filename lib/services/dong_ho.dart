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

  /// Số giây còn lại sau khi đã trôi [daQua] kể từ lúc nhận [giay] từ máy chủ (đo bằng Stopwatch,
  /// nên vẫn đúng khi app chạy nền và Timer bị dừng). Không âm; null nếu không có hạn.
  static int? conLai(int? giay, Duration daQua) {
    if (giay == null) return null;
    final c = giay - daQua.inSeconds;
    return c < 0 ? 0 : c;
  }

  /// Đơn chuyển khoản đang chờ thanh toán (chưa phát hành cho CTV): máy chủ chỉ trả
  /// soGiayConLaiThanhToan cho những đơn này, kể cả khi đã về 0 và đang chờ hệ thống hủy.
  static bool choThanhToan(Map<String, dynamic>? don) => don?['soGiayConLaiThanhToan'] != null;
}
