import 'api_client.dart';
import 'api_response.dart';

class ComplaintApiService {
  final ApiClient _apiClient = ApiClient();

  /// Khách hàng gửi khiếu nại kèm file bằng chứng đã upload MinIO (UC-KH08)
  /// POST /v1/complaints — khớp ComplaintCreateRequest
  Future<ApiResponse<Map<String, dynamic>>> createComplaint({
    required int khachHangId,
    required int donDatId,
    required String loaiVanDe,
    required String noiDung,
    List<String>? danhSachFileDinhKem, // object key/URL từ /api/storage/upload/khieu-nai
  }) async {
    return _apiClient.post<Map<String, dynamic>>(
      '/v1/complaints',
      body: {
        'khachHangId': khachHangId,
        'donDatId': donDatId,
        'loaiVanDe': loaiVanDe,
        'noiDung': noiDung,
        'danhSachFileDinhKem': danhSachFileDinhKem ?? [],
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
