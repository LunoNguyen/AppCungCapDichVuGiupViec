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

  /// Sửa đánh giá (trong 7 ngày sau khi gửi). PUT /v1/reviews/order/{donDatId}
  Future<ApiResponse<Map<String, dynamic>>> updateReview({
    required int donDatId,
    required int khachHangId,
    required int diemChatLuong,
    required int diemThaiDo,
    String? nhanXet,
  }) {
    return _apiClient.put<Map<String, dynamic>>(
      '/v1/reviews/order/$donDatId',
      body: {
        'donDatId': donDatId,
        'khachHangId': khachHangId,
        'diemChatLuong': diemChatLuong,
        'diemThaiDo': diemThaiDo,
        if (nhanXet != null) 'nhanXet': nhanXet,
      },
    );
  }

  /// Khách bình luận / phản hồi thêm dưới đánh giá. POST /v1/reviews/order/{donDatId}/comments
  Future<ApiResponse<Map<String, dynamic>>> comment({
    required int donDatId,
    required int khachHangId,
    required String noiDung,
  }) {
    return _apiClient.post<Map<String, dynamic>>(
      '/v1/reviews/order/$donDatId/comments',
      body: {'khachHangId': khachHangId, 'noiDung': noiDung},
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
