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
    try {
      final res = await _apiClient.put<Map<String, dynamic>>(
        '/v1/collaborators/assignments/$id/complete',
        body: {
          'ketQuaThucHien': cleanGhiChu ?? 'Hoàn thành qua ứng dụng',
          'ghiChu': cleanGhiChu ?? 'Hoàn thành qua ứng dụng',
        },
      );
      if (res.success) return res;
    } catch (_) {}

    return _apiClient.put<Map<String, dynamic>>(
      '/v1/customer/bookings/$id',
      body: {
        'trangThai': 'HoanThanh',
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

  // ====================================================
  // POOL ORDERS — Đơn hàng chung cho tất cả CTV
  // ====================================================

  /// Lấy danh sách đơn đang tìm CTV (pool chung — tất cả CTV đều thấy)
  Future<ApiResponse<List<Map<String, dynamic>>>> getAvailableOrders({
    required int congTacVienId,
  }) async {
    try {
      final res = await _apiClient.get<List<Map<String, dynamic>>>(
        '/v1/customer/bookings',
        fromJsonT: (json) {
          if (json is List) {
            return json.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          }
          return [];
        },
      );
      if (res.success && res.data != null) {
        final unassigned = res.data!.where((item) {
          final ctvId = item['congTacVienId'] ?? item['ctvId'];
          final status = (item['trangThai'] ?? item['trangThaiDon'] ?? '').toString().toLowerCase();
          final isNotDoneOrCancelled = status != 'hoanthanh' &&
              status != 'hoan_thanh' &&
              status != 'completed' &&
              status != 'dahuy' &&
              status != 'da_huy' &&
              status != 'cancelled';
          return (ctvId == null || ctvId == 0) && isNotDoneOrCancelled;
        }).toList();
        return ApiResponse(success: true, data: unassigned);
      }
    } catch (_) {}
    return ApiResponse(success: true, data: []);
  }

  /// CTV nhận đơn từ pool (atomic — first-come-first-served)
  /// Trả về 409 nếu đơn đã có người nhận trước
  Future<ApiResponse<Map<String, dynamic>>> acceptOrderFromPool({
    required int donDatId,
    required int congTacVienId,
  }) async {
    try {
      final res = await _apiClient.post<Map<String, dynamic>>(
        '/v1/collaborators/orders/$donDatId/accept',
        body: {'congTacVienId': congTacVienId},
      );
      if (res.success) return res;
    } catch (_) {}

    return _apiClient.put<Map<String, dynamic>>(
      '/v1/customer/bookings/$donDatId',
      body: {
        'congTacVienId': congTacVienId,
        'trangThai': 'DangThucHien',
      },
    );
  }

  /// CTV từ chối đơn từ pool (đơn vẫn ở pool cho người khác)
  Future<ApiResponse<Map<String, dynamic>>> rejectOrderFromPool({
    required int donDatId,
    required int congTacVienId,
    String? lyDo,
  }) async {
    final cleanReason = lyDo?.trim().replaceAll(RegExp(r'\s+'), ' ');
    final reasonToSend = (cleanReason != null && cleanReason.isNotEmpty)
        ? cleanReason
        : 'Bận lịch cá nhân';
    return _apiClient.post<Map<String, dynamic>>(
      '/v1/collaborators/orders/$donDatId/reject',
      body: {
        'congTacVienId': congTacVienId,
        'lyDo': reasonToSend,
      },
    );
  }
}
