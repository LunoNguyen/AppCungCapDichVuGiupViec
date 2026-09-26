import 'api_client.dart';
import 'api_response.dart';

class ServiceCatalogApiService {
  final ApiClient _apiClient = ApiClient();

  /// Lấy danh sách dịch vụ kèm bộ lọc (UC-KH03)
  /// Backend có sử dụng Redis Caching để tăng tốc độ phản hồi
  /// GET /v1/services
  Future<ApiResponse<List<Map<String, dynamic>>>> getServices({
    int? loaiDichVuId,
    int? khuVucId,
    String? loaiHinhDat, // THEO_GIO, THEO_GOI, DINH_KY
    String? tuKhoa,
    double? minPrice,
    double? maxPrice,
  }) async {
    final queryParams = <String, dynamic>{};
    if (loaiDichVuId != null) queryParams['loaiDichVuId'] = loaiDichVuId;
    if (khuVucId != null) queryParams['khuVucId'] = khuVucId;
    if (loaiHinhDat != null && loaiHinhDat.isNotEmpty) {
      queryParams['loaiHinhDat'] = loaiHinhDat;
    }
    if (tuKhoa != null && tuKhoa.isNotEmpty) queryParams['tuKhoa'] = tuKhoa;
    if (minPrice != null) queryParams['minPrice'] = minPrice;
    if (maxPrice != null) queryParams['maxPrice'] = maxPrice;

    return _apiClient.get<List<Map<String, dynamic>>>(
      '/v1/services',
      queryParams: queryParams,
      fromJsonT: (json) {
        if (json is List) {
          return json.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
        return [];
      },
    );
  }

  /// Lấy chi tiết dịch vụ kèm bảng giá, gói tháng, CTV và đánh giá
  /// GET /v1/services/{id}
  Future<ApiResponse<Map<String, dynamic>>> getServiceDetail(int id) async {
    return _apiClient.get<Map<String, dynamic>>(
      '/v1/services/$id',
      fromJsonT: (json) => Map<String, dynamic>.from(json as Map),
    );
  }

  /// Danh mục loại dịch vụ
  /// GET /v1/service-types
  Future<ApiResponse<List<Map<String, dynamic>>>> getServiceTypes() async {
    return _apiClient.get<List<Map<String, dynamic>>>(
      '/v1/service-types',
      fromJsonT: (json) {
        if (json is List) {
          return json.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
        return [];
      },
    );
  }

  /// Danh mục khu vực phục vụ (Quận/Huyện)
  /// GET /v1/areas
  Future<ApiResponse<List<Map<String, dynamic>>>> getAreas() async {
    return _apiClient.get<List<Map<String, dynamic>>>(
      '/v1/areas',
      fromJsonT: (json) {
        if (json is List) {
          return json.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
        return [];
      },
    );
  }
}
