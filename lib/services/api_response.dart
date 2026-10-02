class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final String? error;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.error,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json, [
    T Function(dynamic json)? fromJsonT,
  ]) {
    // Ưu tiên cờ "success" do backend trả về; chỉ đoán khi không có cờ này
    final bool isSuccess = json.containsKey('success')
        ? json['success'] == true
        : (json['code'] == 200 ||
            (json.containsKey('error') ? json['error'] == null : true));

    T? parsedData;
    if (json.containsKey('data') && json['data'] != null) {
      if (fromJsonT != null) {
        parsedData = fromJsonT(json['data']);
      } else {
        parsedData = json['data'] as T?;
      }
    }

    return ApiResponse<T>(
      success: isSuccess,
      message: json['message'] as String?,
      data: parsedData,
      error: json['error'] as String?,
    );
  }

  factory ApiResponse.ok(T? data, [String? message]) {
    return ApiResponse<T>(
      success: true,
      message: message,
      data: data,
    );
  }

  factory ApiResponse.err(String error) {
    return ApiResponse<T>(
      success: false,
      message: error,
      error: error,
    );
  }
}
