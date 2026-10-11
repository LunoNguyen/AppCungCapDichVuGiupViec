import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Base URL của Backend Spring Boot (cổng 8083), tự chọn theo nơi chạy app:
  /// - Android Emulator: 'http://10.0.2.2:8083' (10.0.2.2 = máy tính đang chạy emulator)
  /// - Web, Windows Desktop: 'http://localhost:8083'
  /// - Điện thoại thật (cùng Wi-Fi với máy chạy server): truyền IP LAN lúc chạy, không sửa file này:
  ///     flutter run --dart-define=API_URL=http://192.168.x.x:8083
  /// Nhờ vậy mỗi máy trong nhóm dùng địa chỉ riêng mà không ghi đè nhau khi merge.
  static String baseUrl = _diaChiMacDinh();

  static String _diaChiMacDinh() {
    const tuChon = String.fromEnvironment('API_URL');
    if (tuChon.isNotEmpty) return tuChon;
    if (kIsWeb) return 'http://localhost:8083';
    if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:8083';
    return 'http://localhost:8083';
  }

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
