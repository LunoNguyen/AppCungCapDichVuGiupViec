import 'catalog_ui.dart';

/// Một dịch vụ ở bước 1 của màn đặt: các biến thể cùng mã dịch vụ (VD DV101: 2 giờ, 3 giờ, 4 giờ, gói tháng)
/// gom thành một thẻ, giống website.
class NhomDichVu {
  final String ma;
  final String ten;
  final String? anh;
  final int giaTu;
  final bool coTheoLan;
  final bool coGoiThang;
  final List<Map<String, dynamic>> bienThe;

  const NhomDichVu({
    required this.ma,
    required this.ten,
    this.anh,
    required this.giaTu,
    required this.coTheoLan,
    required this.coGoiThang,
    required this.bienThe,
  });

  /// Biến thể của một hình thức đặt (TheoLan | GoiThang), đã sắp theo giá tăng dần.
  List<Map<String, dynamic>> bienTheTheoLoai(String loaiHinhDat) =>
      bienThe.where((b) => (b['loaiHinhDat'] ?? 'TheoLan') == loaiHinhDat).toList();

  /// Biến thể mở khi bấm thẻ nhóm: rẻ nhất của hình thức đang lọc, không có thì biến thể đầu tiên.
  Map<String, dynamic> bienTheDaiDien(String? loaiHinhDat) {
    final ds = loaiHinhDat == null ? const <Map<String, dynamic>>[] : bienTheTheoLoai(loaiHinhDat);
    return ds.isNotEmpty ? ds.first : bienThe.first;
  }

  /// "Theo lần · Gói tháng" – các hình thức nhóm có.
  String get nhanHinhThuc => [if (coTheoLan) 'Theo lần', if (coGoiThang) 'Gói tháng'].join(' · ');

  /// Nhãn ngắn của biến thể: phần trong ngoặc của tên ("2 giờ", "Gói 8 buổi/tháng, 2 giờ/buổi"),
  /// không có thì theo thời lượng, cuối cùng là tên dịch vụ.
  static String nhanBienThe(Map<String, dynamic> b) {
    final ten = b['tenDichVu']?.toString() ?? '';
    final m = RegExp(r'\(([^)]+)\)\s*$').firstMatch(ten);
    if (m != null) return m.group(1)!;
    final phut = CatalogUi.toInt(b['thoiGianThucHienPhut']);
    if (phut > 0) return phut % 60 == 0 ? '${phut ~/ 60} giờ' : '$phut phút';
    return ten.isEmpty ? 'Dịch vụ' : ten;
  }

  /// Tên chung của nhóm: bỏ phần biến thể " (…)" ở cuối tên.
  static String tenNhom(String tenDichVu) {
    final ngoac = tenDichVu.indexOf(' (');
    return ngoac > 0 ? tenDichVu.substring(0, ngoac) : tenDichVu;
  }

  static String _ma(Map<String, dynamic> dv) {
    final ma = dv['maDichVu']?.toString() ?? '';
    return ma.isEmpty ? 'id-${CatalogUi.toInt(dv['id'])}' : ma;
  }

  static int _gia(Map<String, dynamic> dv) => CatalogUi.toInt(
      (num.tryParse(dv['donGiaThamKhao']?.toString() ?? '') ?? 0).round());

  /// Gom danh sách /v1/services theo mã dịch vụ; giữ thứ tự xuất hiện đầu tiên của mỗi mã.
  static List<NhomDichVu> gom(List<Map<String, dynamic>> dichVus) {
    final theoMa = <String, List<Map<String, dynamic>>>{};
    for (final dv in dichVus) {
      theoMa.putIfAbsent(_ma(dv), () => []).add(dv);
    }
    return [
      for (final e in theoMa.entries) _taoNhom(e.key, e.value),
    ];
  }

  static NhomDichVu _taoNhom(String ma, List<Map<String, dynamic>> ds) {
    final sap = [...ds]..sort((a, b) {
        final la = (a['loaiHinhDat'] ?? 'TheoLan') == 'GoiThang' ? 1 : 0;
        final lb = (b['loaiHinhDat'] ?? 'TheoLan') == 'GoiThang' ? 1 : 0;
        return la != lb ? la - lb : _gia(a).compareTo(_gia(b));
      });
    final giaDuong = ds.map(_gia).where((g) => g > 0);
    String? anh;
    for (final dv in ds) {
      final a = dv['hinhAnhUrl']?.toString();
      if (a != null && a.isNotEmpty) {
        anh = a;
        break;
      }
    }
    return NhomDichVu(
      ma: ma,
      ten: tenNhom(ds.first['tenDichVu']?.toString() ?? 'Dịch vụ'),
      anh: anh,
      giaTu: giaDuong.isEmpty ? 0 : giaDuong.reduce((x, y) => x < y ? x : y),
      coTheoLan: ds.any((d) => (d['loaiHinhDat'] ?? 'TheoLan') == 'TheoLan'),
      coGoiThang: ds.any((d) => d['loaiHinhDat'] == 'GoiThang'),
      bienThe: sap,
    );
  }

  /// Nhóm chứa dịch vụ có id này (dịch vụ khách vừa xem), null nếu không có.
  static NhomDichVu? timTheoDichVuId(List<NhomDichVu> ds, int dichVuId) {
    for (final g in ds) {
      if (g.bienThe.any((b) => CatalogUi.toInt(b['id']) == dichVuId)) return g;
    }
    return null;
  }
}
