/// Một dịch vụ (dòng chi tiết) trong đơn nhiều dịch vụ mà cộng tác viên thấy ở danh sách đơn chờ
/// (API /v1/collaborators/.../available-orders, trường `dichVus`).
class DichVuDon {
  final int chiTietId;
  final String ten;
  final int phut;
  final bool daCoNguoi;
  final bool coKyNang;

  const DichVuDon({
    required this.chiTietId,
    required this.ten,
    required this.phut,
    required this.daCoNguoi,
    required this.coKyNang,
  });

  factory DichVuDon.fromJson(Map<String, dynamic> j) => DichVuDon(
        chiTietId: (j['chiTietId'] as num?)?.toInt() ?? 0,
        ten: j['tenDichVu']?.toString() ?? 'Dịch vụ',
        phut: (j['thoiGianPhut'] as num?)?.toInt() ?? 0,
        // Thiếu dữ liệu thì coi như đã có người / không có kỹ năng: không cho nhận nhầm
        daCoNguoi: j['daCoNguoiNhan'] != false,
        coKyNang: j['ctvCoKyNang'] == true,
      );

  /// CTV nhận được dịch vụ này: còn trống và CTV đã đăng ký kỹ năng.
  bool get nhanDuoc => !daCoNguoi && coKyNang;

  /// Dịch vụ chọn sẵn khi CTV bấm nhận: mọi dịch vụ nhận được.
  static List<int> chonMacDinh(List<DichVuDon> ds) =>
      [for (final d in ds) if (d.nhanDuoc) d.chiTietId];

  /// Danh sách dịch vụ của một đơn chờ (rỗng = đơn một dịch vụ).
  static List<DichVuDon> tuDonCho(Map<String, dynamic> don) {
    final ds = don['dichVus'];
    if (ds is! List) return const [];
    return [for (final x in ds) if (x is Map) DichVuDon.fromJson(Map<String, dynamic>.from(x))];
  }
}
