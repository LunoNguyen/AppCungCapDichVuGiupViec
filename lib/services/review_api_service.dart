import 'api_client.dart';
import 'api_response.dart';

class ReviewApiService {
  final ApiClient _apiClient = ApiClient();

  /// Khách hàng gửi đánh giá cho đơn hoàn thành (UC-KH07)
  /// POST /v1/reviews — khớp ReviewCreateRequest
  Future<ApiResponse<Map<String, dynamic>>> createReview({
    required int donDatId,
    required int khachHangId,
    required int diemChatLuong, // 1 -> 5
    required int diemThaiDo, // 1 -> 5
    String? nhanXet,
  }) async {
    return _apiClient.post<Map<String, dynamic>>(
      '/v1/reviews',
      body: {
        'donDatId': donDatId,
        'khachHangId': khachHangId,
        'diemChatLuong': diemChatLuong,
        'diemThaiDo': diemThaiDo,
        if (nhanXet != null) 'nhanXet': nhanXet,
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
