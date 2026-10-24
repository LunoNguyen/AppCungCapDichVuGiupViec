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

  final ApiClient _api = ApiClient();

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
