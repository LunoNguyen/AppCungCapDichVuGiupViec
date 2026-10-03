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
    final cleanReason = lyDo?.trim().replaceAll(RegExp(r'\s+'), ' ');
    final reasonToSend = (cleanReason != null && cleanReason.isNotEmpty)
        ? cleanReason
        : 'Bận lịch cá nhân';
    return _apiClient.put<Map<String, dynamic>>(
      '/v1/collaborators/assignments/$id/reject',
      body: {
        'lyDoTuChoi': reasonToSend,
        'lyDo': reasonToSend,
      },
    );
  }

  /// CTV hoàn thành đơn
  Future<ApiResponse<Map<String, dynamic>>> completeAssignment({
    required int id,
    String? ghiChu,
  }) async {
    final cleanGhiChu = ghiChu?.trim().replaceAll(RegExp(r'\s+'), ' ');
    return _apiClient.put<Map<String, dynamic>>(
      '/v1/collaborators/assignments/$id/complete',
      body: {
        'ketQuaThucHien': cleanGhiChu ?? 'Hoàn thành qua ứng dụng',
        'ghiChu': cleanGhiChu ?? 'Hoàn thành qua ứng dụng',
      },
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

  /// Cập nhật trạng thái hoạt động (Sẵn sàng/Tạm dừng)
  Future<ApiResponse<Map<String, dynamic>>> updateStatus(int id, String trangThai) async {
    return _apiClient.put<Map<String, dynamic>>(
      '/v1/collaborators/$id/status',
      body: {'trangThai': trangThai},
    );
  }
}
