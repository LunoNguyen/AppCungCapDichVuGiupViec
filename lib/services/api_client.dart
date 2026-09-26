import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'api_response.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final http.Client _client = http.Client();

  Map<String, String> _buildHeaders([Map<String, String>? extraHeaders]) {
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
    };
    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }
    return headers;
  }

  /// GET Request
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    T Function(dynamic json)? fromJsonT,
  }) async {
    try {
      final uri = _buildUri(path, queryParams);
      log('GET: $uri');
      final response = await _client
          .get(uri, headers: _buildHeaders(headers))
          .timeout(ApiConfig.connectTimeout);

      return _handleResponse<T>(response, fromJsonT);
    } catch (e) {
      log('GET Error [$path]: $e');
      return ApiResponse.err('Lỗi kết nối mạng: $e');
    }
  }

  /// POST Request
  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    T Function(dynamic json)? fromJsonT,
  }) async {
    try {
      final uri = _buildUri(path, queryParams);
      final jsonBody = body != null ? jsonEncode(body) : null;
      log('POST: $uri | Body: $jsonBody');
      final response = await _client
          .post(uri, headers: _buildHeaders(headers), body: jsonBody)
          .timeout(ApiConfig.connectTimeout);

      return _handleResponse<T>(response, fromJsonT);
    } catch (e) {
      log('POST Error [$path]: $e');
      return ApiResponse.err('Lỗi kết nối mạng: $e');
    }
  }

  /// PUT Request
  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    T Function(dynamic json)? fromJsonT,
  }) async {
    try {
      final uri = _buildUri(path, queryParams);
      final jsonBody = body != null ? jsonEncode(body) : null;
      log('PUT: $uri | Body: $jsonBody');
      final response = await _client
          .put(uri, headers: _buildHeaders(headers), body: jsonBody)
          .timeout(ApiConfig.connectTimeout);

      return _handleResponse<T>(response, fromJsonT);
    } catch (e) {
      log('PUT Error [$path]: $e');
      return ApiResponse.err('Lỗi kết nối mạng: $e');
    }
  }

  /// DELETE Request
  Future<ApiResponse<T>> delete<T>(
    String path, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    T Function(dynamic json)? fromJsonT,
  }) async {
    try {
      final uri = _buildUri(path, queryParams);
      log('DELETE: $uri');
      final response = await _client
          .delete(uri, headers: _buildHeaders(headers))
          .timeout(ApiConfig.connectTimeout);

      return _handleResponse<T>(response, fromJsonT);
    } catch (e) {
      log('DELETE Error [$path]: $e');
      return ApiResponse.err('Lỗi kết nối mạng: $e');
    }
  }

  Uri _buildUri(String path, Map<String, dynamic>? queryParams) {
    String fullUrl;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      fullUrl = path;
    } else {
      fullUrl = '${ApiConfig.baseUrl}${path.startsWith('/') ? path : '/$path'}';
    }

    final uri = Uri.parse(fullUrl);
    if (queryParams != null && queryParams.isNotEmpty) {
      final stringParams = queryParams.map(
        (key, value) => MapEntry(key, value?.toString() ?? ''),
      );
      return uri.replace(queryParameters: stringParams);
    }
    return uri;
  }

  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(dynamic json)? fromJsonT,
  ) {
    try {
      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) {
        return ApiResponse.fromJson(decoded, fromJsonT);
      } else {
        // Primitive or List JSON array directly
        return ApiResponse.ok(
          fromJsonT != null ? fromJsonT(decoded) : decoded as T?,
        );
      }
    } catch (e) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.ok(null, 'Thao tác thành công');
      }
      return ApiResponse.err(
        'Lỗi máy chủ (${response.statusCode}): ${response.reasonPhrase}',
      );
    }
  }
}
