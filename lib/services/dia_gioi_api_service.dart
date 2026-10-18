import 'api_client.dart';
import 'api_response.dart';

/// Tỉnh, thành (provinces.open-api.vn v2 qua máy chủ bTaskee).
class TinhThanh {
  final int ma;
  final String ten;
  const TinhThanh(this.ma, this.ten);
}

/// Khu vực = quận, huyện (lớn hơn phường, nhỏ hơn tỉnh) – nơi đơn được đặt / CTV nhận việc.
class KhuVucNho {
  final int id;
  final String ten;
  const KhuVucNho(this.id, this.ten);
}

/// Phường, xã kèm các khu vực chứa nó (rỗng = ngoài khu vực bTaskee phục vụ).
class PhuongXa {
  final int ma;
  final String ten;
  final List<KhuVucNho> khuVuc;
  const PhuongXa(this.ma, this.ten, this.khuVuc);

  /// "Phường Bến Thành" → "Bến Thành (Phường)" để dễ tìm trong danh sách dài.
  String get nhan {
    final m = RegExp(r'^(Phường|Xã|Đặc khu|Thị trấn) (.*)$').firstMatch(ten);
    return m == null ? ten : '${m.group(2)} (${m.group(1)})';
  }
}

/// GET /v1/dia-gioi/tinh và /v1/dia-gioi/tinh/{ma}/phuong-xa, giữ trong bộ nhớ khi app chạy.
class DiaGioiApiService {
  static const maHcm = 79;
  static List<TinhThanh>? _tinh;
  static final Map<int, List<PhuongXa>> _phuong = {};

  final ApiClient _api = ApiClient();

  Future<ApiResponse<List<TinhThanh>>> tinhThanh() async {
    if (_tinh != null) return ApiResponse.ok(_tinh);
    final res = await _api.get<List<TinhThanh>>('/v1/dia-gioi/tinh',
        fromJsonT: (j) => j is List
            ? j.map((e) => TinhThanh(int.parse('${e['ma']}'), '${e['ten']}')).toList()
            : <TinhThanh>[]);
    if (res.success && res.data != null && res.data!.isNotEmpty) _tinh = res.data;
    return res;
  }

  Future<ApiResponse<List<PhuongXa>>> phuongXa(int maTinh) async {
    final coSan = _phuong[maTinh];
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
    if (res.success && res.data != null) _phuong[maTinh] = res.data!;
    return res;
  }
}
