import 'api_client.dart';
import 'api_response.dart';

class ReviewApiService {
  final ApiClient _apiClient = ApiClient();

  /// Khách hàng gửi đánh giá sao và nhận xét cho đơn hoàn thành (UC-KH07)
  /// POST /v1/reviews
  Future<ApiResponse<Map<String, dynamic>>> createReview({
    required int donDatId,
    required int khachHangId,
    required int soSao, // 1 -> 5
    required String noiDung,
    List<String>? hinhAnhUrls,
  }) async {
    return _apiClient.post<Map<String, dynamic>>(
      '/v1/reviews',
      body: {
        'donDatId': donDatId,
        'khachHangId': khachHangId,
        'soSao': soSao,
        'noiDung': noiDung,
        'hinhAnhUrls': hinhAnhUrls ?? [],
      },
    );
  }

  /// Xem các đánh giá công khai của một dịch vụ
  /// GET /v1/reviews/service/{dichVuId}
  Future<ApiResponse<List<Map<String, dynamic>>>> getReviewsByService(
      int dichVuId) async {
    return _apiClient.get<List<Map<String, dynamic>>>(
      '/v1/reviews/service/$dichVuId',
      fromJsonT: (json) {
        if (json is List) {
          return json.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
        return [];
      },
    );
  }
}
