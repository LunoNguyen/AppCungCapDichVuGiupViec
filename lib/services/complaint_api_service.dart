import 'api_client.dart';
import 'api_response.dart';

class ComplaintApiService {
  final ApiClient _apiClient = ApiClient();

  /// Khách hàng gửi khiếu nại kèm link file/ảnh bằng chứng (lưu trên MinIO) (UC-KH08)
  /// POST /v1/complaints
  Future<ApiResponse<Map<String, dynamic>>> createComplaint({
    required int khachHangId,
    required int donDatId,
    required String tieuDe,
    required String noiDung,
    required String mucDoUuTien, // THAP, TRUNG_BINH, CAO, KHAN_CAP
    List<String>? hinhAnhBangChungUrls, // URLs ảnh đã upload lên MinIO qua StorageController
  }) async {
    return _apiClient.post<Map<String, dynamic>>(
      '/v1/complaints',
      body: {
        'khachHangId': khachHangId,
        'donDatId': donDatId,
        'tieuDe': tieuDe,
        'noiDung': noiDung,
        'mucDoUuTien': mucDoUuTien,
        'hinhAnhBangChungUrls': hinhAnhBangChungUrls ?? [],
      },
    );
  }

  /// Xem danh sách khiếu nại và kết quả giải quyết của khách hàng (UC-KH08)
  /// GET /v1/complaints/customer/{khachHangId}
  Future<ApiResponse<List<Map<String, dynamic>>>> getCustomerComplaints(
      int khachHangId) async {
    return _apiClient.get<List<Map<String, dynamic>>>(
      '/v1/complaints/customer/$khachHangId',
      fromJsonT: (json) {
        if (json is List) {
          return json.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
        return [];
      },
    );
  }
}
