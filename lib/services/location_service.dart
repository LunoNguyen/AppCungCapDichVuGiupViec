import 'package:flutter/widgets.dart' show Locale;
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import 'dia_gioi_api_service.dart';

/// Kết quả lấy vị trí: có [position] hoặc [error] (thông điệp hiển thị cho người dùng).
class LocationResult {
  final Position? position;
  final String? error;
  const LocationResult._(this.position, this.error);

  bool get ok => position != null;
}

/// GPS dùng chung cho Khách hàng (lấy toạ độ địa chỉ) và Cộng tác viên (gửi vị trí, chỉ đường).
class LocationService {
  static final DiaGioiApiService _diaGioiApi = DiaGioiApiService();
  static Future<LocationResult>? _inFlightPosition;
  static Position? _lastPosition;

  /// Vị trí GPS gần nhất đã lấy được trong phiên làm việc (giúp mở Google Maps tức thì).
  static Position? get lastKnownPosition => _lastPosition;

  /// Xin quyền và lấy vị trí hiện tại (gộp các yêu cầu gọi trùng cùng lúc để tránh treo GPS).
  static Future<LocationResult> getCurrentPosition() {
    final pending = _inFlightPosition;
    if (pending != null) return pending;
    final future = _fetchCurrentPositionInternal();
    _inFlightPosition = future;
    return future.whenComplete(() {
      if (identical(_inFlightPosition, future)) {
        _inFlightPosition = null;
      }
    });
  }

  static Future<LocationResult> _fetchCurrentPositionInternal() async {
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
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 5),
          ),
        );
      } catch (_) {
        // Dự phòng khi GPS vệ tinh bị timeout hoặc trong nhà: lấy vị trí đã biết gần nhất
        pos = await Geolocator.getLastKnownPosition();
      }
      pos ??= await Geolocator.getLastKnownPosition();
      pos ??= _lastPosition;

      if (pos != null) {
        _lastPosition = pos;
        return LocationResult._(pos, null);
      }
      return const LocationResult._(
          null, 'Chưa lấy được vị trí GPS. Vui lòng bật định vị và thử lại.');
    } catch (e) {
      if (_lastPosition != null) {
        return LocationResult._(_lastPosition, null);
      }
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

  /// Đoán quận/huyện TP.HCM từ toạ độ thông qua dữ liệu của [DiaGioiApiService] (bán kính 30km).
  static String? doanQuanTheoToaDo(double lat, double lng) {
    final dsTamQuan = DiaGioiApiService.danhSachTamQuan;
    TamQuan? gan;
    double min = double.infinity;
    for (int i = 0; i < dsTamQuan.length; i++) {
      final t = dsTamQuan[i];
      final d = distanceKm(lat, lng, t.viDo, t.kinhDo);
      if (d < min) {
        min = d;
        gan = t;
      }
    }
    return (gan != null && min <= 30) ? gan.ten : null;
  }

  /// Tìm tên quận từ danh sách các trường địa chỉ của Geocoder dựa trên dữ liệu 2 API (v1 & v2).
  static String? _timTenQuan(Iterable<String?> texts) {
    return DiaGioiApiService.timQuanTuDiaGioi(texts);
  }

  /// Lấy chi tiết thông tin hành chính (quận huyện, tỉnh thành, địa chỉ) từ toạ độ GPS.
  static Future<Map<String, String>> getAddressDetails(double lat, double lng) async {
    try {
      // Đồng bộ danh mục địa giới từ 2 API (v1 Quận/Huyện cũ + v2 Phường/Xã mới + Tâm toạ độ)
      try {
        await _diaGioiApi.dongBoDuLieuDinhVi().timeout(const Duration(seconds: 2));
      } catch (_) {}

      final marks = await Geocoding(locale: const Locale('vi', 'VN'))
          .placemarkFromCoordinates(lat, lng);
      Placemark? p = marks.isNotEmpty ? marks.first : null;

      String? quanHuyen;
      if (p != null) {
        quanHuyen = _timTenQuan([
          p.subAdministrativeArea,
          p.subLocality,
          p.locality,
          p.thoroughfare,
          p.street,
          p.name,
        ]);
      }

      quanHuyen ??= doanQuanTheoToaDo(lat, lng);
      quanHuyen ??= '';

      String tinhThanh = p?.administrativeArea ?? '';
      if (tinhThanh.isEmpty && quanHuyen.isNotEmpty) {
        tinhThanh = 'Thành phố Hồ Chí Minh';
      }

      final parts = <String?>[
        p != null
            ? <String?>[p.subThoroughfare, p.thoroughfare]
                .where((s) => s != null && s.isNotEmpty)
                .join(' ')
            : null,
        p?.subLocality,
        quanHuyen.isNotEmpty ? quanHuyen : null,
        tinhThanh.isNotEmpty ? tinhThanh : null,
      ].where((s) => s != null && s.trim().isNotEmpty).cast<String>();

      final out = <String>[];
      for (final s in parts) {
        if (out.isEmpty || out.last != s) out.add(s);
      }

      return {
        'quanHuyen': quanHuyen,
        'tinhThanh': tinhThanh,
        'diaChi': out.join(', '),
      };
    } catch (_) {
      final q = doanQuanTheoToaDo(lat, lng) ?? '';
      return {
        'quanHuyen': q,
        'tinhThanh': q.isNotEmpty ? 'Thành phố Hồ Chí Minh' : '',
        'diaChi': q,
      };
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

  static Future<bool> _launchMapsUri(Uri uri) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (ok) return true;
    } catch (_) {}
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.platformDefault);
      if (ok) return true;
    } catch (_) {}
    try {
      return await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    } catch (_) {
      return false;
    }
  }

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
    return _launchMapsUri(uri);
  }

  /// Mở bản đồ tại một điểm (xem vị trí CTV).
  static Future<bool> openMap(double lat, double lng) {
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': '$lat,$lng',
    });
    return _launchMapsUri(uri);
  }

  static double? toDouble(dynamic v) =>
      v == null ? null : double.tryParse(v.toString());
}
