import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'api_response.dart';
import 'api_client.dart';

class StorageApiService {
  final ApiClient _apiClient = ApiClient();

  /// Upload file chung lên MinIO
  /// Param: bytes, fileName, folder (VD: "ctv/avatar/", "khieu-nai/tai-lieu/", "ho-so/")
  Future<ApiResponse<Map<String, dynamic>>> uploadFile({
    required Uint8List bytes,
    required String fileName,
    String folder = 'ho-so/',
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.storageUrl}/upload');
      final request = http.MultipartRequest('POST', uri)
        ..fields['folder'] = folder
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: fileName,
          ),
        );

      final streamedResponse =
          await request.send().timeout(ApiConfig.connectTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.ok(
          data as Map<String, dynamic>,
          'Tải lên file thành công',
        );
      } else {
        return ApiResponse.err(data['error']?.toString() ?? 'Lỗi tải lên file');
      }
    } catch (e) {
      return ApiResponse.err('Lỗi kết nối MinIO Storage: $e');
    }
  }

  /// Upload avatar CTV lên MinIO
  /// POST /api/storage/upload/ctv-avatar/{ctvId}
  Future<ApiResponse<Map<String, dynamic>>> uploadCTVAvatar({
    required int ctvId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.storageUrl}/upload/ctv-avatar/$ctvId');
      final request = http.MultipartRequest('POST', uri)
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: fileName,
          ),
        );

      final streamedResponse =
          await request.send().timeout(ApiConfig.connectTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.ok(data as Map<String, dynamic>);
      } else {
        return ApiResponse.err(
            data['error']?.toString() ?? 'Lỗi tải ảnh đại diện CTV');
      }
    } catch (e) {
      return ApiResponse.err('Lỗi tải ảnh avatar CTV: $e');
    }
  }

  /// Upload chứng chỉ / bằng cấp CTV
  /// POST /api/storage/upload/ctv-chung-chi/{ctvId}
  Future<ApiResponse<Map<String, dynamic>>> uploadChungChi({
    required int ctvId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final uri =
          Uri.parse('${ApiConfig.storageUrl}/upload/ctv-chung-chi/$ctvId');
      final request = http.MultipartRequest('POST', uri)
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: fileName,
          ),
        );

      final streamedResponse =
          await request.send().timeout(ApiConfig.connectTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.ok(data as Map<String, dynamic>);
      } else {
        return ApiResponse.err(
            data['error']?.toString() ?? 'Lỗi tải chứng chỉ CTV');
      }
    } catch (e) {
      return ApiResponse.err('Lỗi tải chứng chỉ CTV: $e');
    }
  }

  /// Upload tài liệu / hình ảnh bằng chứng khiếu nại
  /// POST /api/storage/upload/khieu-nai/{khieuNaiId}
  Future<ApiResponse<Map<String, dynamic>>> uploadTaiLieuKhieuNai({
    required int khieuNaiId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final uri =
          Uri.parse('${ApiConfig.storageUrl}/upload/khieu-nai/$khieuNaiId');
      final request = http.MultipartRequest('POST', uri)
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: fileName,
          ),
        );

      final streamedResponse =
          await request.send().timeout(ApiConfig.connectTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.ok(data as Map<String, dynamic>);
      } else {
        return ApiResponse.err(
            data['error']?.toString() ?? 'Lỗi tải ảnh khiếu nại');
      }
    } catch (e) {
      return ApiResponse.err('Lỗi tải ảnh khiếu nại: $e');
    }
  }

  /// Lấy presigned URL để xem hoặc tải ảnh từ MinIO
  /// GET /api/storage/url?object=...
  Future<String?> getPresignedUrl(String objectName) async {
    final res = await _apiClient.get<Map<String, dynamic>>(
      '/api/storage/url',
      queryParams: {'object': objectName},
    );
    if (res.success && res.data != null) {
      return res.data!['url'] as String?;
    }
    return null;
  }

  /// Xóa file trên MinIO
  /// DELETE /api/storage/delete?object=...
  Future<bool> deleteFile(String objectName) async {
    final res = await _apiClient.delete<Map<String, dynamic>>(
      '/api/storage/delete',
      queryParams: {'object': objectName},
    );
    return res.success;
  }
}
