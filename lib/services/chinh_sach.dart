import 'api_client.dart';
import 'api_response.dart';

/// Một khối nội dung của tài liệu chính sách (cùng cấu trúc với resources/chinh-sach.json phía máy chủ).
sealed class KhoiChinhSach {
  const KhoiChinhSach();

  /// null khi loại khối không biết (bỏ qua, không làm hỏng cả trang).
  static KhoiChinhSach? tuJson(dynamic j) {
    if (j is! Map) return null;
    String chu(dynamic v) => v?.toString() ?? '';
    List<String> dsChu(dynamic v) => v is List ? v.map(chu).toList() : const [];
    switch (j['loai']) {
      case 'tieuDe':
        return KhoiTieuDe(chu(j['noiDung']));
      case 'tieuDeNho':
        return KhoiTieuDeNho(chu(j['noiDung']));
      case 'doan':
        return KhoiDoan(chu(j['noiDung']));
      case 'ds':
        return KhoiDanhSach(dsChu(j['muc']));
      case 'bang':
        final dong = j['dong'];
        return KhoiBang(dsChu(j['cot']), dong is List ? dong.map(dsChu).toList() : const []);
      default:
        return null;
    }
  }
}

class KhoiTieuDe extends KhoiChinhSach {
  final String noiDung;
  const KhoiTieuDe(this.noiDung);
}

class KhoiTieuDeNho extends KhoiChinhSach {
  final String noiDung;
  const KhoiTieuDeNho(this.noiDung);
}

class KhoiDoan extends KhoiChinhSach {
  final String noiDung;
  const KhoiDoan(this.noiDung);
}

class KhoiDanhSach extends KhoiChinhSach {
  final List<String> muc;
  const KhoiDanhSach(this.muc);
}

class KhoiBang extends KhoiChinhSach {
  final List<String> cot;
  final List<List<String>> dong;
  const KhoiBang(this.cot, this.dong);
}

/// Điều khoản sử dụng / Quy trình khiếu nại / Chính sách bảo mật.
class TaiLieuChinhSach {
  final String ma;
  final String ten;
  final String moTa;
  final List<KhoiChinhSach> khoi;

  const TaiLieuChinhSach({required this.ma, required this.ten, required this.moTa, required this.khoi});

  static List<TaiLieuChinhSach> danhSachTuJson(dynamic json) {
    if (json is! List) return const [];
    return [
      for (final t in json)
        if (t is Map)
          TaiLieuChinhSach(
            ma: t['ma']?.toString() ?? '',
            ten: t['ten']?.toString() ?? '',
            moTa: t['moTa']?.toString() ?? '',
            khoi: [
              for (final k in (t['noiDung'] is List ? t['noiDung'] as List : const []))
                if (KhoiChinhSach.tuJson(k) case final khoi?) khoi,
            ],
          ),
    ];
  }
}

/// GET /v1/chinh-sach (không cần đăng nhập).
class ChinhSachApiService {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<List<TaiLieuChinhSach>>> danhSach() {
    return _apiClient.get<List<TaiLieuChinhSach>>(
      '/v1/chinh-sach',
      fromJsonT: TaiLieuChinhSach.danhSachTuJson,
    );
  }
}
