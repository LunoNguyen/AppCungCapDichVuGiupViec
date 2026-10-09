/// Lịch buổi làm của gói tháng: khách chọn ngày bắt đầu và các thứ trong tuần
/// (vd T3, T5, T7, CN), lấy lần lượt các ngày khớp thứ trong vòng 1 tháng cho đủ số buổi.
/// Cùng thuật toán với máy chủ (LichGoiThang.java), máy chủ kiểm lại khi tạo đơn.
///
/// Thứ dùng DateTime.weekday: 1 = Thứ 2 … 7 = Chủ nhật.
/// Mã gửi lên máy chủ: "2".."7" là Thứ 2..Thứ 7, "CN" là Chủ nhật (vd "3,5,7,CN").
class LichGoiThang {
  LichGoiThang._();

  static const nhanThu = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  /// Mẫu chọn nhanh.
  static const mau = <String, Set<int>>{
    'T3 · T5 · T7 · CN': {2, 4, 6, 7},
    'T2 · T4 · T6 · CN': {1, 3, 5, 7},
    'T2 → T6': {1, 2, 3, 4, 5},
    'Cả tuần': {1, 2, 3, 4, 5, 6, 7},
  };

  /// Số buổi của gói: cột soBuoi, chưa có thì đọc từ tên ("… 13 buổi/tháng").
  static int soBuoi(dynamic soBuoiCot, String? ten) {
    final n = int.tryParse(soBuoiCot?.toString() ?? '');
    if (n != null && n > 0) return n;
    final m = RegExp(r'(\d+)\s*(buổi|ngày|lần)\s*/\s*tháng', caseSensitive: false)
        .firstMatch(ten ?? '');
    return m != null ? int.parse(m.group(1)!) : 4;
  }

  /// {2, 4, 6, 7} -> "3,5,7,CN"
  static String maThu(Set<int> thu) {
    final list = thu.toList()..sort();
    return list.map((w) => w == 7 ? 'CN' : '${w + 1}').join(',');
  }

  /// {2, 4, 6, 7} -> "T3, T5, T7, CN"
  static String nhan(Set<int> thu) {
    final list = thu.toList()..sort();
    return list.map((w) => nhanThu[w - 1]).join(', ');
  }

  /// Các ngày khớp thứ, từ ngày bắt đầu tới trước cùng ngày tháng sau, tối đa [soBuoi] ngày.
  static List<DateTime> tinhLich(DateTime batDau, Set<int> thu, int soBuoi) {
    final ngays = <DateTime>[];
    if (thu.isEmpty) return ngays;
    final start = DateTime(batDau.year, batDau.month, batDau.day);
    // Cộng 1 tháng như LocalDate.plusMonths: 31/01 -> 28/02 (không tràn sang tháng 3)
    final soNgayThangSau = DateTime(start.year, start.month + 2, 0).day;
    final ketThuc = DateTime(start.year, start.month + 1,
        start.day > soNgayThangSau ? soNgayThangSau : start.day);
    for (var d = start; d.isBefore(ketThuc) && ngays.length < soBuoi; d = DateTime(d.year, d.month, d.day + 1)) {
      if (thu.contains(d.weekday)) ngays.add(d);
    }
    return ngays;
  }

  /// Câu báo khi thiếu buổi, null nếu đủ.
  static String? loiThieu(List<DateTime> ngays, int soBuoi, Set<int> thu) {
    if (thu.isEmpty) return 'Chọn các thứ trong tuần sẽ làm.';
    if (ngays.length >= soBuoi) return null;
    final canThem = ((soBuoi - ngays.length) / 4).ceil();
    return 'Các thứ đã chọn chỉ có ${ngays.length} buổi trong 1 tháng, gói cần $soBuoi buổi. '
        'Hãy chọn thêm ít nhất $canThem thứ.';
  }
}
