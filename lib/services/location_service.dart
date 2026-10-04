import 'package:flutter/widgets.dart' show Locale;
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

/// Kết quả lấy vị trí: có [position] hoặc [error] (thông điệp hiển thị cho người dùng).
class LocationResult {
  final Position? position;
  final String? error;
  const LocationResult._(this.position, this.error);

  bool get ok => position != null;
}

/// GPS dùng chung cho Khách hàng (lấy toạ độ địa chỉ) và Cộng tác viên (gửi vị trí, chỉ đường).
class LocationService {
  /// Xin quyền và lấy vị trí hiện tại.
  static Future<LocationResult> getCurrentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationResult._(
            null, 'Vui lòng bật định vị (GPS) trên điện thoại.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return const LocationResult._(
            null, 'Bạn chưa cho phép ứng dụng truy cập vị trí.');
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationResult._(null,
            'Quyền vị trí đã bị tắt. Vui lòng bật lại trong Cài đặt của điện thoại.');
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return LocationResult._(pos, null);
    } catch (e) {
      return LocationResult._(null, 'Không lấy được vị trí: $e');
    }
  }

  /// Đổi toạ độ thành địa chỉ dạng chữ (cần mạng). Trả null nếu không tra được.
  static Future<String?> reverseGeocode(double lat, double lng) async {
    try {
      final marks = await Geocoding(locale: const Locale('vi', 'VN'))
          .placemarkFromCoordinates(lat, lng);
      if (marks.isEmpty) return null;
      final p = marks.first;
      final parts = <String?>[
        <String?>[p.subThoroughfare, p.thoroughfare]
            .where((s) => s != null && s.isNotEmpty)
            .join(' '),
        p.subLocality,
        p.locality,
        p.subAdministrativeArea,
        p.administrativeArea,
      ].where((s) => s != null && s.trim().isNotEmpty).cast<String>();
      // Bỏ phần trùng lặp liền kề (một số máy trả locality == subAdministrativeArea)
      final out = <String>[];
      for (final s in parts) {
        if (out.isEmpty || out.last != s) out.add(s);
      }
      return out.isEmpty ? null : out.join(', ');
    } catch (_) {
      return null;
    }
  }

  static final Map<String, List<double>?> _geoCache = {};

  /// Đổi địa chỉ dạng chữ thành toạ độ [vĩ độ, kinh độ] (cần mạng, có cache). Null nếu không tra được.
  static Future<List<double>?> forwardGeocode(String address) async {
    final key = address.trim();
    if (key.isEmpty) return null;
    if (_geoCache.containsKey(key)) return _geoCache[key];
    List<double>? out;
    try {
      final locs = await Geocoding(locale: const Locale('vi', 'VN'))
          .locationFromAddress(key);
      if (locs.isNotEmpty) out = [locs.first.latitude, locs.first.longitude];
    } catch (_) {}
    _geoCache[key] = out;
    return out;
  }

  /// Khoảng cách đường chim bay (km).
  static double distanceKm(double lat1, double lng1, double lat2, double lng2) =>
      Geolocator.distanceBetween(lat1, lng1, lat2, lng2) / 1000;

  static String formatKm(double km) =>
      km < 1 ? '${(km * 1000).round()} m' : '${km.toStringAsFixed(1)} km';

  /// Mở Google Maps chỉ đường tới toạ độ, hoặc tìm theo địa chỉ khi không có toạ độ.
  static Future<bool> openDirections(
      {double? lat, double? lng, String? address}) async {
    final String dest;
    if (lat != null && lng != null) {
      dest = '$lat,$lng';
    } else if (address != null && address.trim().isNotEmpty) {
      dest = address.trim();
    } else {
      return false;
    }
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': dest,
    });
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Mở bản đồ tại một điểm (xem vị trí CTV).
  static Future<bool> openMap(double lat, double lng) {
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': '$lat,$lng',
    });
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static double? toDouble(dynamic v) =>
      v == null ? null : double.tryParse(v.toString());
}
