import 'api_client.dart';
import 'api_response.dart';

class CollaboratorApiService {
  final ApiClient _apiClient = ApiClient();

  /// Danh sách đơn dịch vụ được phân công cho CTV (UC-CTV01)
  /// GET /v1/collaborator/assignments
  Future<ApiResponse<List<Map<String, dynamic>>>> getAssignments({
    required int congTacVienId,
    String? trangThai, // CHO_XAC_NHAN, DA_XAC_NHAN, DANG_THUC_HIEN, HOAN_THANH
  }) async {
    final queryParams = <String, dynamic>{
      'congTacVienId': congTacVienId,
    };
    if (trangThai != null && trangThai.isNotEmpty) {
      queryParams['trangThai'] = trangThai;
    }

    return _apiClient.get<List<Map<String, dynamic>>>(
      '/v1/collaborator/assignments',
      queryParams: queryParams,
      fromJsonT: (json) {
        if (json is List) {
          return json.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
        return [];
      },
    );
  }

  /// Xem chi tiết đơn được phân công (UC-CTV01)
  /// GET /v1/collaborator/assignments/{id}
  Future<ApiResponse<Map<String, dynamic>>> getAssignmentDetail(int id) async {
    return _apiClient.get<Map<String, dynamic>>(
      '/v1/collaborator/assignments/$id',
      fromJsonT: (json) => Map<String, dynamic>.from(json as Map),
    );
  }

  /// CTV xác nhận nhận đơn (UC-CTV01)
  /// PUT /v1/collaborator/assignments/{id}/accept
  Future<ApiResponse<Map<String, dynamic>>> acceptAssignment(int id) async {
    return _apiClient.put<Map<String, dynamic>>(
      '/v1/collaborator/assignments/$id/accept',
    );
  }

  /// CTV từ chối đơn kèm lý do (UC-CTV01)
  /// PUT /v1/collaborator/assignments/{id}/reject
  Future<ApiResponse<Map<String, dynamic>>> rejectAssignment({
    required int id,
    String? lyDo,
  }) async {
    return _apiClient.put<Map<String, dynamic>>(
      '/v1/collaborator/assignments/$id/reject',
      body: {
        'lyDo': lyDo ?? 'Bận lịch cá nhân',
      },
    );
  }

  /// CTV cập nhật trạng thái Hoàn thành kèm kết quả thực hiện (UC-CTV01)
  /// PUT /v1/collaborator/assignments/{id}/complete
  Future<ApiResponse<Map<String, dynamic>>> completeAssignment({
    required int id,
    String? ghiChu,
    List<String>? hinhAnhBaoCaoUrls, // URLs ảnh lưu trên MinIO
  }) async {
    return _apiClient.put<Map<String, dynamic>>(
      '/v1/collaborator/assignments/$id/complete',
      body: {
        'ghiChu': ghiChu,
        'hinhAnhBaoCaoUrls': hinhAnhBaoCaoUrls ?? [],
      },
    );
  }

  /// Xem thời gian biểu làm việc (ngày/tuần/tháng) (UC-CTV03)
  /// GET /v1/collaborator/schedules
  Future<ApiResponse<List<Map<String, dynamic>>>> getSchedules({
    required int congTacVienId,
    String? fromDate, // YYYY-MM-DD
    String? toDate, // YYYY-MM-DD
    String? trangThai,
  }) async {
    final queryParams = <String, dynamic>{
      'congTacVienId': congTacVienId,
    };
    if (fromDate != null) queryParams['fromDate'] = fromDate;
    if (toDate != null) queryParams['toDate'] = toDate;
    if (trangThai != null) queryParams['trangThai'] = trangThai;

    return _apiClient.get<List<Map<String, dynamic>>>(
      '/v1/collaborator/schedules',
      queryParams: queryParams,
      fromJsonT: (json) {
        if (json is List) {
          return json.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
        return [];
      },
    );
  }

  /// Xem chi tiết ca làm việc (UC-CTV03)
  /// GET /v1/collaborator/schedules/{id}
  Future<ApiResponse<Map<String, dynamic>>> getScheduleDetail(int id) async {
    return _apiClient.get<Map<String, dynamic>>(
      '/v1/collaborator/schedules/$id',
      fromJsonT: (json) => Map<String, dynamic>.from(json as Map),
    );
  }

  /// Ứng viên gửi hồ sơ đăng ký làm CTV kèm file MinIO (CCCD, chứng chỉ) (UC-KH02)
  /// POST /v1/collaborators/register
  Future<ApiResponse<Map<String, dynamic>>> registerCollaborator({
    required String hoTen,
    required String soDienThoai,
    required String soCccd,
    required String gioiTinh,
    required String diaChi,
    String? khuVucHoatDong,
    String? kinhNghiem,
    List<int>? dichVuIds,
    String? anhCccdMatTruocUrl,
    String? anhCccdMatSauUrl,
    String? anhChanDungUrl,
  }) async {
    return _apiClient.post<Map<String, dynamic>>(
      '/v1/collaborators/register',
      body: {
        'hoTen': hoTen,
        'soDienThoai': soDienThoai,
        'soCccd': soCccd,
        'gioiTinh': gioiTinh,
        'diaChi': diaChi,
        'khuVucHoatDong': khuVucHoatDong,
        'kinhNghiem': kinhNghiem,
        'dichVuIds': dichVuIds ?? [],
        'anhCccdMatTruocUrl': anhCccdMatTruocUrl,
        'anhCccdMatSauUrl': anhCccdMatSauUrl,
        'anhChanDungUrl': anhChanDungUrl,
      },
    );
  }

  /// Tra cứu kết quả xét duyệt hồ sơ theo số điện thoại (UC-KH02)
  /// GET /v1/collaborators/application-status?soDienThoai=...
  Future<ApiResponse<Map<String, dynamic>>> checkApplicationStatus(
      String soDienThoai) async {
    return _apiClient.get<Map<String, dynamic>>(
      '/v1/collaborators/application-status',
      queryParams: {'soDienThoai': soDienThoai},
      fromJsonT: (json) => Map<String, dynamic>.from(json as Map),
    );
  }
}
