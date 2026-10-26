import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Một dịch vụ (biến thể) trong giỏ hàng.
class MonGio {
  final int id; // id biến thể dịch vụ (DichVu)
  final String ten;
  final int gia;
  final int phut; // thời lượng một buổi
  final String loaiHinhDat; // TheoLan | GoiThang
  final int danhMucId;
  final String? anh;
  bool chon;

  MonGio({
    required this.id,
    required this.ten,
    required this.gia,
    required this.phut,
    required this.loaiHinhDat,
    required this.danhMucId,
    this.anh,
    this.chon = true,
  });

  /// Gói tháng không đặt chung với dịch vụ khác (đặt riêng).
  bool get laGoi => loaiHinhDat == 'GoiThang';

  Map<String, dynamic> toJson() => {
        'id': id,
        'ten': ten,
        'gia': gia,
        'phut': phut,
        'loaiHinhDat': loaiHinhDat,
        'danhMucId': danhMucId,
        'anh': anh,
        'chon': chon,
      };

  /// Món giỏ từ một biến thể dịch vụ của API /v1/services (giá tham khảo, thời lượng, danh mục, ảnh).
  factory MonGio.tuDichVu(Map<String, dynamic> dv) {
    int so(dynamic v) => (num.tryParse(v?.toString() ?? '') ?? 0).round();
    return MonGio(
      id: so(dv['dichVuId'] ?? dv['id']),
      ten: dv['tenDichVu']?.toString() ?? dv['title']?.toString() ?? 'Dịch vụ',
      gia: so(dv['donGiaThamKhao'] ?? dv['giaHienTai']),
      phut: so(dv['thoiGianThucHienPhut']),
      loaiHinhDat: dv['loaiHinhDat']?.toString() ?? 'TheoLan',
      danhMucId: so(dv['loaiDichVuId']),
      anh: dv['hinhAnhUrl']?.toString(),
    );
  }

  factory MonGio.fromJson(Map<String, dynamic> j) => MonGio(
        id: (j['id'] as num?)?.toInt() ?? 0,
        ten: j['ten']?.toString() ?? 'Dịch vụ',
        gia: (j['gia'] as num?)?.toInt() ?? 0,
        phut: (j['phut'] as num?)?.toInt() ?? 0,
        loaiHinhDat: j['loaiHinhDat']?.toString() ?? 'TheoLan',
        danhMucId: (j['danhMucId'] as num?)?.toInt() ?? 0,
        anh: j['anh']?.toString(),
        chon: j['chon'] != false,
      );
}

/// Giỏ hàng lưu trên máy (SharedPreferences), cùng quy tắc với giỏ hàng web:
/// chỉ dịch vụ theo lần đặt chung, tối đa 5 dịch vụ, tổng tối đa 8 giờ (máy chủ: DatNhieuDichVu).
class GioHang extends ChangeNotifier {
  GioHang._();
  static final GioHang instance = GioHang._();

  static const khoa = 'btaskee.gioHang';
  static const soDichVuToiDa = 5;
  static const tongPhutToiDa = 480;
  static const phutMacDinh = 120;

  List<MonGio> _mon = [];
  List<MonGio> get mon => List.unmodifiable(_mon);
  int get soLuong => _mon.length;

  /// Dịch vụ đã tick để đặt chung (bỏ gói tháng).
  List<MonGio> get daChon => [for (final m in _mon) if (m.chon && !m.laGoi) m];
  int get tongGia => daChon.fold(0, (s, m) => s + m.gia);
  int get tongPhut => daChon.fold(0, (s, m) => s + (m.phut > 0 ? m.phut : phutMacDinh));

  Future<void> tai() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(khoa);
      final ds = raw == null ? const [] : jsonDecode(raw);
      _mon = [for (final x in (ds is List ? ds : const [])) if (x is Map) MonGio.fromJson(Map<String, dynamic>.from(x))];
    } catch (_) {
      _mon = [];
    }
    notifyListeners();
  }

  Future<void> _luu() async {
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(khoa, jsonEncode([for (final m in _mon) m.toJson()]));
    } catch (_) {}
  }

  /// false nếu dịch vụ đã có trong giỏ (chỉ tick lại).
  Future<bool> them(MonGio m) async {
    final daCo = _mon.where((x) => x.id == m.id).firstOrNull;
    if (daCo != null) {
      daCo.chon = !daCo.laGoi;
      await _luu();
      return false;
    }
    m.chon = !m.laGoi;
    _mon.add(m);
    await _luu();
    return true;
  }

  Future<void> xoa(int id) async {
    _mon.removeWhere((m) => m.id == id);
    await _luu();
  }

  /// Bỏ các dịch vụ vừa đặt xong khỏi giỏ.
  Future<void> xoaNhieu(Iterable<int> ids) async {
    final bo = ids.toSet();
    _mon.removeWhere((m) => bo.contains(m.id));
    await _luu();
  }

  Future<void> xoaTatCa() async {
    _mon.clear();
    await _luu();
  }

  Future<void> doiChon(int id) async {
    final m = _mon.where((x) => x.id == id).firstOrNull;
    if (m == null || m.laGoi) return;
    m.chon = !m.chon;
    await _luu();
  }

  Future<void> chonTatCa(bool chon) async {
    for (final m in _mon) {
      m.chon = chon && !m.laGoi;
    }
    await _luu();
  }

  /// null nếu các dịch vụ đặt chung được; ngược lại là lý do (cùng câu với web).
  static String? loiDatChung(List<MonGio> chon) {
    if (chon.length > soDichVuToiDa) return 'Mỗi lần đặt tối đa $soDichVuToiDa dịch vụ.';
    final tong = chon.fold(0, (s, m) => s + (m.phut > 0 ? m.phut : phutMacDinh));
    if (tong > tongPhutToiDa) return 'Tổng thời lượng tối đa 8 giờ (đang chọn ${thoiLuong(tong)}).';
    return null;
  }

  /// "8 giờ", "8 giờ 30 phút", "45 phút".
  static String thoiLuong(int phut) {
    final g = phut ~/ 60, p = phut % 60;
    if (g == 0) return '$p phút';
    return p == 0 ? '$g giờ' : '$g giờ $p phút';
  }
}
