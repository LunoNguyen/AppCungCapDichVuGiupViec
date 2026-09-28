class ApiConfig {
  /// Base URL của Backend Spring Boot
  /// - Dùng 'http://10.0.2.2:8080' khi chạy trên Android Emulator
  /// - Dùng 'http://localhost:8080' khi chạy Web hoặc Windows Desktop
  /// - Dùng IP mạng LAN (ví dụ: 'http://192.168.1.100:8080') khi chạy trên điện thoại thật
  static String baseUrl = 'http://192.168.0.102:8083';

  /// Base URL cho MinIO Storage API
  static String get storageUrl => '$baseUrl/api/storage';

  /// Base URL cho v1 API
  static String get v1Url => '$baseUrl/v1';

  /// Cấu hình thời gian timeout kết nối (giây)
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  /// Cập nhật địa chỉ Backend khi cần thay đổi động trong ứng dụng
  static void setBaseUrl(String newUrl) {
    if (newUrl.endsWith('/')) {
      baseUrl = newUrl.substring(0, newUrl.length - 1);
    } else {
      baseUrl = newUrl;
    }
  }
}
