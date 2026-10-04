import 'api_client.dart';
import 'api_response.dart';
import '../models/cong_tac_vien.dart';

class CollaboratorApiService {
  final ApiClient _apiClient = ApiClient();

  /// Lấy danh sách đơn được phân công cho CTV
  Future<ApiResponse<List<Map<String, dynamic>>>> getAssignments({
    required int congTacVienId,
    String? trangThai,
  }) async {
    return _apiClient.get<List<Map<String, dynamic>>>(
      '/v1/collaborators/assignments', // Sử dụng số nhiều /collaborators
      queryParams: {
        'congTacVienId': congTacVienId,
        if (trangThai != null) 'trangThai': trangThai,
      },
      fromJsonT: (json) {
        if (json is List) {
          return json.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
        return [];
      },
    );
  }

  /// CTV xác nhận nhận đơn
  Future<ApiResponse<Map<String, dynamic>>> acceptAssignment(int phanCongId) async {
    return _apiClient.put<Map<String, dynamic>>(
      '/v1/collaborators/assignments/$phanCongId/accept',
    );
  }

  /// CTV từ chối đơn
  Future<ApiResponse<Map<String, dynamic>>> rejectAssignment({
    required int id,
    String? lyDo,
  }) async {
    return _apiClient.put<Map<String, dynamic>>(
      '/v1/collaborators/assignments/$id/reject',
      body: {'lyDoTuChoi': lyDo ?? 'Bận lịch cá nhân'},
    );
  }

  /// CTV hoàn thành đơn
  Future<ApiResponse<Map<String, dynamic>>> completeAssignment({
    required int id,
    String? ghiChu,
  }) async {
    return _apiClient.put<Map<String, dynamic>>(
      '/v1/collaborators/assignments/$id/complete',
      body: {'ketQuaThucHien': ghiChu},
    );
  }

  /// Lấy lịch làm việc
  Future<ApiResponse<List<Map<String, dynamic>>>> getSchedules({
    required int congTacVienId,
  }) async {
    return _apiClient.get<List<Map<String, dynamic>>>(
      '/v1/collaborators/schedules',
      queryParams: {'congTacVienId': congTacVienId},
      fromJsonT: (json) {
        if (json is List) {
          return json.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
        return [];
      },
    );
  }

  /// Lấy hồ sơ CTV
  Future<ApiResponse<CongTacVien>> getProfile(int id) async {
    return _apiClient.get<CongTacVien>(
      '/v1/collaborators/$id',
      fromJsonT: (json) => CongTacVien.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Lấy hồ sơ CTV theo tài khoản; nếu chưa có backend tạo hồ sơ rỗng.
  /// Trả về hồ sơ + cờ daTaoMoi.
  Future<ApiResponse<Map<String, dynamic>>> ensureProfile(int taiKhoanId) async {
    return _apiClient.post<Map<String, dynamic>>(
      '/v1/collaborators/profile/ensure',
      body: {'taiKhoanId': taiKhoanId},
    );
  }

  /// Cập nhật trạng thái hoạt động (Sẵn sàng/Tạm dừng)
  Future<ApiResponse<Map<String, dynamic>>> updateStatus(int id, String trangThai) async {
    return _apiClient.put<Map<String, dynamic>>(
      '/v1/collaborators/$id/status',
      body: {'trangThai': trangThai},
    );
  }

  /// GPS: gửi vị trí hiện tại của CTV
  /// PUT /v1/collaborators/{id}/location
  Future<ApiResponse<Map<String, dynamic>>> updateLocation(
      int id, double viDo, double kinhDo) async {
    return _apiClient.put<Map<String, dynamic>>(
      '/v1/collaborators/$id/location',
      body: {'viDo': viDo, 'kinhDo': kinhDo},
    );
  }
}
