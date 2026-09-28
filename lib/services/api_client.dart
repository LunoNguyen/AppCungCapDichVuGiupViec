import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';
import 'api_response.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  // Sử dụng Client có cấu hình không tự động redirect để giữ method PUT/POST
  final http.Client _client = http.Client();

  Future<Map<String, String>> _buildHeaders([Map<String, String>? extraHeaders]) async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }
    return headers;
  }

  Future<ApiResponse<T>> get<T>(String path, {Map<String, dynamic>? queryParams, Map<String, String>? headers, T Function(dynamic json)? fromJsonT}) async {
    try {
      final uri = _buildUri(path, queryParams);
      final finalHeaders = await _buildHeaders(headers);
      log('GET: $uri');
      final response = await _client.get(uri, headers: finalHeaders).timeout(ApiConfig.connectTimeout);
      return _handleResponse<T>(response, fromJsonT);
    } catch (e) {
      return ApiResponse.err('Lỗi kết nối: $e');
    }
  }

  Future<ApiResponse<T>> post<T>(String path, {dynamic body, Map<String, dynamic>? queryParams, Map<String, String>? headers, T Function(dynamic json)? fromJsonT}) async {
    try {
      final uri = _buildUri(path, queryParams);
      final finalHeaders = await _buildHeaders(headers);
      final jsonBody = body != null ? jsonEncode(body) : null;
      log('POST: $uri');
      final response = await _client.post(uri, headers: finalHeaders, body: jsonBody).timeout(ApiConfig.connectTimeout);
      return _handleResponse<T>(response, fromJsonT);
    } catch (e) {
      return ApiResponse.err('Lỗi kết nối: $e');
    }
  }

  Future<ApiResponse<T>> put<T>(String path, {dynamic body, Map<String, dynamic>? queryParams, Map<String, String>? headers, T Function(dynamic json)? fromJsonT}) async {
    try {
      final uri = _buildUri(path, queryParams);
      final finalHeaders = await _buildHeaders(headers);
      // Backend Java có thể bị lỗi nếu PUT Body null, gửi {} nếu trống
      final jsonBody = jsonEncode(body ?? {});
      log('PUT: $uri');
      
      // Tạo Request thủ công để kiểm soát redirect
      final request = http.Request('PUT', uri)
        ..headers.addAll(finalHeaders)
        ..followRedirects = false // QUAN TRỌNG: Không cho tự đổi sang GET
        ..body = jsonBody;

      final streamedResponse = await _client.send(request).timeout(ApiConfig.connectTimeout);
      final response = await http.Response.fromStream(streamedResponse);
      
      return _handleResponse<T>(response, fromJsonT);
    } catch (e) {
      return ApiResponse.err('Lỗi kết nối: $e');
    }
  }

  Future<ApiResponse<T>> delete<T>(String path, {Map<String, dynamic>? queryParams, Map<String, String>? headers, T Function(dynamic json)? fromJsonT}) async {
    try {
      final uri = _buildUri(path, queryParams);
      final finalHeaders = await _buildHeaders(headers);
      log('DELETE: $uri');
      final response = await _client.delete(uri, headers: finalHeaders).timeout(ApiConfig.connectTimeout);
      return _handleResponse<T>(response, fromJsonT);
    } catch (e) {
      return ApiResponse.err('Lỗi kết nối: $e');
    }
  }

  Uri _buildUri(String path, Map<String, dynamic>? queryParams) {
    // Làm sạch path để tránh double slash //
    String cleanPath = path.startsWith('/') ? path.substring(1) : path;
    String baseUrl = ApiConfig.baseUrl;
    if (!baseUrl.endsWith('/')) baseUrl += '/';
    
    String fullUrl = path.startsWith('http') ? path : '$baseUrl$cleanPath';
    final uri = Uri.parse(fullUrl);
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: queryParams.map((k, v) => MapEntry(k, v?.toString() ?? '')));
    }
    return uri;
  }

  ApiResponse<T> _handleResponse<T>(http.Response response, T Function(dynamic json)? fromJsonT) {
    final String body = utf8.decode(response.bodyBytes);
    
    // Nếu bị 301/302 Redirect hoặc lỗi HTML
    if (response.statusCode >= 300 && response.statusCode < 400) {
      return ApiResponse.err('Lỗi 3xx: Backend đang Redirect yêu cầu. Hãy kiểm tra lại URL hoặc phân quyền!');
    }

    if (body.trim().startsWith('<!DOCTYPE html>') || body.contains('<html')) {
      return ApiResponse.err('Lỗi server (${response.statusCode}): Phản hồi HTML không mong muốn. Hãy kiểm tra Security ở Backend!');
    }

    try {
      final dynamic decoded = jsonDecode(body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (decoded is Map<String, dynamic>) {
          return ApiResponse.fromJson(decoded, fromJsonT);
        }
        return ApiResponse.ok(fromJsonT != null ? fromJsonT(decoded) : decoded as T?);
      }
      return ApiResponse.fromJson(decoded, fromJsonT);
    } catch (e) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.ok(null, 'Thao tác thành công');
      }
      return ApiResponse.err('Lỗi (${response.statusCode}): ${response.reasonPhrase}');
    }
  }
}
