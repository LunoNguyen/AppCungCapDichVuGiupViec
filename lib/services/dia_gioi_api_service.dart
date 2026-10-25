import 'api_client.dart';
import 'api_response.dart';

/// Tỉnh, thành phố.
class TinhThanh {
  final int ma;
  final String ten;
  const TinhThanh(this.ma, this.ten);
}

/// Quận, huyện (Địa chỉ cũ v1).
class QuanHuyenV1 {
  final int ma;
  final String ten;
  final int maTinh;
  final int? khuVucId;
  final String? tenKhuVuc;
  const QuanHuyenV1({
    required this.ma,
    required this.ten,
    required this.maTinh,
    this.khuVucId,
    this.tenKhuVuc,
  });
}

/// Phường, xã (Địa chỉ cũ v1).
class PhuongXaV1 {
  final int ma;
  final String ten;
  final int maQuan;
  const PhuongXaV1({
    required this.ma,
    required this.ten,
    required this.maQuan,
  });

  /// "Phường Tây Thạnh" → "Tây Thạnh (Phường)" để dễ tìm kiếm.
  String get nhan {
    final m = RegExp(r'^(Phường|Xã|Đặc khu|Thị trấn) (.*)$').firstMatch(ten);
    return m == null ? ten : '${m.group(2)} (${m.group(1)})';
  }
}

/// Khu vực = quận, huyện nơi đơn được đặt / CTV nhận việc.
class KhuVucNho {
  final int id;
  final String ten;
  const KhuVucNho(this.id, this.ten);
}

/// Tâm toạ độ GPS của một quận/huyện (đồng bộ từ API /v1/dia-gioi/tam-quan).
class TamQuan {
  final String ten;
  final double viDo;
  final double kinhDo;
  const TamQuan({
    required this.ten,
    required this.viDo,
    required this.kinhDo,
  });

  factory TamQuan.fromJson(Map<String, dynamic> j) => TamQuan(
        ten: '${j['ten'] ?? ''}',
        viDo: double.tryParse('${j['viDo']}') ?? 0,
        kinhDo: double.tryParse('${j['kinhDo']}') ?? 0,
      );
}

/// Phường, xã mới (Địa chỉ mới v2 sau sáp nhập).
class PhuongXa {
  final int ma;
  final String ten;
  final List<KhuVucNho> khuVuc;
  const PhuongXa(this.ma, this.ten, this.khuVuc);

  String get nhan {
    final m = RegExp(r'^(Phường|Xã|Đặc khu|Thị trấn) (.*)$').firstMatch(ten);
    return m == null ? ten : '${m.group(2)} (${m.group(1)})';
  }
}

/// Dịch vụ gọi danh mục địa giới:
/// - API v1 (3 cấp cũ: Tỉnh → Quận/Huyện → Phường/Xã)
/// - API v2 (2 cấp mới: Tỉnh → Phường/Xã)
class DiaGioiApiService {
  static const maHcm = 79;

  // Cache V2
  static List<TinhThanh>? _tinhV2;
  static final Map<int, List<PhuongXa>> _phuongV2 = {};

  // Cache V1
  static List<TinhThanh>? _tinhV1;
  static final Map<int, List<QuanHuyenV1>> _quanV1 = {};
  static final Map<int, List<PhuongXaV1>> _phuongV1 = {};

  // Cache tâm toạ độ GPS quận/huyện từ API /v1/dia-gioi/tam-quan
  static List<TamQuan>? _tamQuan;

  // Dữ liệu dự phòng khi chạy offline / unit test không mở server
  static const List<TamQuan> _duPhongTamQuan = [
    TamQuan(ten: 'Quận 1', viDo: 10.7769, kinhDo: 106.7009),
    TamQuan(ten: 'Quận 3', viDo: 10.7843, kinhDo: 106.6844),
    TamQuan(ten: 'Quận 4', viDo: 10.7578, kinhDo: 106.7013),
    TamQuan(ten: 'Quận 5', viDo: 10.7540, kinhDo: 106.6634),
    TamQuan(ten: 'Quận 6', viDo: 10.7480, kinhDo: 106.6352),
    TamQuan(ten: 'Quận 7', viDo: 10.7340, kinhDo: 106.7215),
    TamQuan(ten: 'Quận 8', viDo: 10.7240, kinhDo: 106.6286),
    TamQuan(ten: 'Quận 10', viDo: 10.7746, kinhDo: 106.6670),
    TamQuan(ten: 'Quận 11', viDo: 10.7629, kinhDo: 106.6505),
    TamQuan(ten: 'Quận 12', viDo: 10.8672, kinhDo: 106.6413),
    TamQuan(ten: 'Quận Bình Thạnh', viDo: 10.8106, kinhDo: 106.7091),
    TamQuan(ten: 'Quận Bình Tân', viDo: 10.7653, kinhDo: 106.6036),
    TamQuan(ten: 'Quận Gò Vấp', viDo: 10.8387, kinhDo: 106.6653),
    TamQuan(ten: 'Quận Phú Nhuận', viDo: 10.7991, kinhDo: 106.6803),
    TamQuan(ten: 'Quận Tân Bình', viDo: 10.8015, kinhDo: 106.6527),
    TamQuan(ten: 'Quận Tân Phú', viDo: 10.7901, kinhDo: 106.6281),
    TamQuan(ten: 'Thành phố Thủ Đức', viDo: 10.8231, kinhDo: 106.7710),
    TamQuan(ten: 'Huyện Bình Chánh', viDo: 10.6874, kinhDo: 106.5939),
    TamQuan(ten: 'Huyện Cần Giờ', viDo: 10.4113, kinhDo: 106.9547),
    TamQuan(ten: 'Huyện Củ Chi', viDo: 11.0067, kinhDo: 106.5135),
    TamQuan(ten: 'Huyện Hóc Môn', viDo: 10.8862, kinhDo: 106.5923),
    TamQuan(ten: 'Huyện Nhà Bè', viDo: 10.6950, kinhDo: 106.7400),
  ];

  static List<TamQuan> get danhSachTamQuan => _tamQuan ?? _duPhongTamQuan;

  final ApiClient _api = ApiClient();

  /// Lấy danh sách tâm toạ độ GPS các quận/huyện TP.HCM từ API Backend (/v1/dia-gioi/tam-quan).
  Future<ApiResponse<List<TamQuan>>> tamQuanHcm() async {
    if (_tamQuan != null && _tamQuan!.isNotEmpty) {
      return ApiResponse.ok(_tamQuan);
    }
    final res = await _api.get<List<TamQuan>>(
      '/v1/dia-gioi/tam-quan',
      fromJsonT: (j) => j is List
          ? j.map((e) => TamQuan.fromJson(Map<String, dynamic>.from(e as Map))).toList()
          : <TamQuan>[],
    );
    if (res.success && res.data != null && res.data!.isNotEmpty) {
      _tamQuan = res.data;
    }
    return res;
  }

  /// Đồng bộ dữ liệu từ cả 2 API (v1 Quận/Huyện cũ + v2 Phường/Xã mới + Tâm toạ độ).
  Future<void> dongBoDuLieuDinhVi() async {
    await Future.wait([
      if (_quanV1[maHcm] == null) quanHuyenV1(maHcm).catchError((_) => ApiResponse<List<QuanHuyenV1>>.err('')),
      if (_phuongV2[maHcm] == null) phuongXa(maHcm).catchError((_) => ApiResponse<List<PhuongXa>>.err('')),
      if (_tamQuan == null) tamQuanHcm().catchError((_) => ApiResponse<List<TamQuan>>.err('')),
    ]);
  }

  /// Đối chiếu kết quả chữ từ Geocoder với dữ liệu từ 2 API:
  /// 1. API v1: Quận/Huyện cũ (quanHuyenV1)
  /// 2. API v2: Phường/Xã mới sau sáp nhập (phuongXa -> khuVuc)
  /// 3. Danh sách tâm quận/huyện
  static String? timQuanTuDiaGioi(Iterable<String?> texts) {
    final dsQuanV1 = _quanV1[maHcm] ?? const <QuanHuyenV1>[];
    final dsPhuongV2 = _phuongV2[maHcm] ?? const <PhuongXa>[];
    final dsTam = danhSachTamQuan;

    // Tập hợp danh sách tên chuẩn của các quận/huyện từ API v1 + API tâm quận
    final tatCaTenQuan = <String>{
      for (final q in dsQuanV1)
        if ((q.tenKhuVuc ?? q.ten).trim().isNotEmpty) (q.tenKhuVuc ?? q.ten).trim(),
      for (final q in dsTam) q.ten,
    }.toList();

    for (final raw in texts) {
      if (raw == null || raw.trim().isEmpty) continue;
      final t = raw.trim().toLowerCase();
      if (t == 'thành phố hồ chí minh' ||
          t == 'thành phố hcm' ||
          t == 'tp. hcm' ||
          t == 'tp.hcm' ||
          t == 'ho chi minh city' ||
          t == 'hồ chí minh') {
        continue;
      }

      // 1. Khớp chính xác tên đầy đủ ("quận 1", "quận tân phú", "quận bình thạnh"...)
      // Ưu tiên tên dài hơn trước để "quận 10", "quận 11", "quận 12" không bị khớp nhầm vào "quận 1"
      final sapXepTheoDoDai = List<String>.from(tatCaTenQuan)
        ..sort((a, b) => b.length.compareTo(a.length));
      for (final ten in sapXepTheoDoDai) {
        final qTen = ten.toLowerCase();
        if (RegExp('${RegExp.escape(qTen)}(?!\\d)').hasMatch(t)) {
          return ten;
        }
      }

      // 2. Khớp quận số viết tắt ("q.1", "q1", "q. 10")
      final matchQuanSo = RegExp(r'\b(?:quận|quan|q)\s*\.?\s*(\d{1,2})(?!\d)').firstMatch(t);
      if (matchQuanSo != null) {
        final so = int.tryParse(matchQuanSo.group(1) ?? '');
        if (so != null) {
          final tenQuanSo = 'Quận $so';
          if (tatCaTenQuan.contains(tenQuanSo)) {
            return tenQuanSo;
          }
        }
      }

      // 3. Khớp tên rút gọn cho các quận/huyện có chữ ("bình thạnh", "tân phú", "thủ đức", "củ chi"...)
      for (final ten in sapXepTheoDoDai) {
        final qTen = ten.toLowerCase();
        final qRutGon = qTen.replaceFirst(RegExp(r'^(quận|huyện|thành phố)\s+'), '').trim();
        // Bỏ qua quận số ("1", "3", "5"...) để không khớp nhầm với số nhà hoặc "Phường 25"
        if (RegExp(r'^\d+$').hasMatch(qRutGon)) continue;
        if (t == qRutGon || t.contains(qRutGon)) {
          return ten;
        }
      }

      // 4. Tra cứu theo danh sách Phường/Xã mới từ API v2 -> suy ra Quận/Khu vực tương ứng
      for (final p in dsPhuongV2) {
        if (p.khuVuc.isEmpty) continue;
        final pTen = p.ten.toLowerCase();
        final pRutGon = pTen.replaceFirst(RegExp(r'^(phường|xã|thị trấn|đặc khu)\s+'), '').trim();
        if (RegExp(r'^\d+$').hasMatch(pRutGon)) continue;
        if (t == pTen || t.contains(pTen) || (pRutGon.length > 3 && t == pRutGon)) {
          return p.khuVuc.first.ten;
        }
      }
    }
    return null;
  }

  // ==================== API V2 ====================
  Future<ApiResponse<List<TinhThanh>>> tinhThanh() async {
    if (_tinhV2 != null) return ApiResponse.ok(_tinhV2);
    final res = await _api.get<List<TinhThanh>>('/v1/dia-gioi/tinh',
        fromJsonT: (j) => j is List
            ? j.map((e) => TinhThanh(int.parse('${e['ma']}'), '${e['ten']}')).toList()
            : <TinhThanh>[]);
    if (res.success && res.data != null && res.data!.isNotEmpty) _tinhV2 = res.data;
    return res;
  }

  Future<ApiResponse<List<PhuongXa>>> phuongXa(int maTinh) async {
    final coSan = _phuongV2[maTinh];
    if (coSan != null) return ApiResponse.ok(coSan);
    final res = await _api.get<List<PhuongXa>>('/v1/dia-gioi/tinh/$maTinh/phuong-xa',
        fromJsonT: (j) => j is List
            ? j
                .map((e) => PhuongXa(
                      int.parse('${e['ma']}'),
                      '${e['ten']}',
                      ((e['khuVuc'] as List?) ?? const [])
                          .map((k) => KhuVucNho(int.parse('${k['id']}'), '${k['tenKhuVuc']}'))
                          .toList(),
                    ))
                .toList()
            : <PhuongXa>[]);
    if (res.success && res.data != null) _phuongV2[maTinh] = res.data!;
    return res;
  }

  // ==================== API V1 ====================
  Future<ApiResponse<List<TinhThanh>>> tinhThanhV1() async {
    if (_tinhV1 != null) return ApiResponse.ok(_tinhV1);
    final res = await _api.get<List<TinhThanh>>('/v1/dia-gioi/v1/tinh',
        fromJsonT: (j) => j is List
            ? j.map((e) => TinhThanh(int.parse('${e['ma']}'), '${e['ten']}')).toList()
            : <TinhThanh>[]);
    if (res.success && res.data != null && res.data!.isNotEmpty) _tinhV1 = res.data;
    return res;
  }

  Future<ApiResponse<List<QuanHuyenV1>>> quanHuyenV1(int maTinh) async {
    final coSan = _quanV1[maTinh];
    if (coSan != null) return ApiResponse.ok(coSan);
    final res = await _api.get<List<QuanHuyenV1>>('/v1/dia-gioi/v1/tinh/$maTinh/quan-huyen',
        fromJsonT: (j) => j is List
            ? j
                .map((e) => QuanHuyenV1(
                      ma: int.parse('${e['ma']}'),
                      ten: '${e['ten']}',
                      maTinh: int.parse('${e['maTinh']}'),
                      khuVucId: e['khuVucId'] != null ? int.parse('${e['khuVucId']}') : null,
                      tenKhuVuc: e['tenKhuVuc']?.toString(),
                    ))
                .toList()
            : <QuanHuyenV1>[]);
    if (res.success && res.data != null) _quanV1[maTinh] = res.data!;
    return res;
  }

  Future<ApiResponse<List<PhuongXaV1>>> phuongXaV1(int maQuan) async {
    final coSan = _phuongV1[maQuan];
    if (coSan != null) return ApiResponse.ok(coSan);
    final res = await _api.get<List<PhuongXaV1>>('/v1/dia-gioi/v1/quan-huyen/$maQuan/phuong-xa',
        fromJsonT: (j) => j is List
            ? j
                .map((e) => PhuongXaV1(
                      ma: int.parse('${e['ma']}'),
                      ten: '${e['ten']}',
                      maQuan: int.parse('${e['maQuan']}'),
                    ))
                .toList()
            : <PhuongXaV1>[]);
    if (res.success && res.data != null) _phuongV1[maQuan] = res.data!;
    return res;
  }
}
