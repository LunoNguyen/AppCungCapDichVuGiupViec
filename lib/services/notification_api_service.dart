import 'api_client.dart';
import 'api_response.dart';

class NotificationApiService {
  final ApiClient _apiClient = ApiClient();

  // ── Khách hàng (UC-KH09) ──────────────────────────────────────────

  /// Lấy danh sách thông báo của khách hàng
  /// GET /v1/customer/notifications?taiKhoanId=...
  Future<ApiResponse<List<Map<String, dynamic>>>> getCustomerNotifications(
      int taiKhoanId) async {
    return _apiClient.get<List<Map<String, dynamic>>>(
      '/v1/customer/notifications',
      queryParams: {'taiKhoanId': taiKhoanId},
      fromJsonT: (json) {
        if (json is List) {
          return json.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
        return [];
      },
    );
  }

  /// Đánh dấu một thông báo khách hàng đã đọc
  /// PUT /v1/customer/notifications/{id}/read?taiKhoanId=...
  Future<ApiResponse<void>> markCustomerNotificationRead({
    required int id,
    required int taiKhoanId,
  }) async {
    return _apiClient.put<void>(
      '/v1/customer/notifications/$id/read',
      queryParams: {'taiKhoanId': taiKhoanId},
    );
  }

  /// Đánh dấu tất cả thông báo khách hàng đã đọc
  /// PUT /v1/customer/notifications/read-all?taiKhoanId=...
  Future<ApiResponse<void>> markAllCustomerNotificationsRead(
      int taiKhoanId) async {
    return _apiClient.put<void>(
      '/v1/customer/notifications/read-all',
      queryParams: {'taiKhoanId': taiKhoanId},
    );
  }

  // ── Cộng tác viên (UC-CTV02) ──────────────────────────────────────

  /// Lấy danh sách thông báo của CTV
  /// GET /v1/collaborator/notifications?taiKhoanId=...
  Future<ApiResponse<List<Map<String, dynamic>>>> getCollaboratorNotifications(
      int taiKhoanId) async {
    return _apiClient.get<List<Map<String, dynamic>>>(
      '/v1/collaborator/notifications',
      queryParams: {'taiKhoanId': taiKhoanId},
      fromJsonT: (json) {
        if (json is List) {
          return json.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
        return [];
      },
    );
  }

  /// Đánh dấu một thông báo CTV đã đọc
  /// PUT /v1/collaborator/notifications/{id}/read?taiKhoanId=...
  Future<ApiResponse<void>> markCollaboratorNotificationRead({
    required int id,
    required int taiKhoanId,
  }) async {
    return _apiClient.put<void>(
      '/v1/collaborator/notifications/$id/read',
      queryParams: {'taiKhoanId': taiKhoanId},
    );
  }

  /// Đánh dấu tất cả thông báo CTV đã đọc
  /// PUT /v1/collaborator/notifications/read-all?taiKhoanId=...
  Future<ApiResponse<void>> markAllCollaboratorNotificationsRead(
      int taiKhoanId) async {
    return _apiClient.put<void>(
      '/v1/collaborator/notifications/read-all',
      queryParams: {'taiKhoanId': taiKhoanId},
    );
  }
}
