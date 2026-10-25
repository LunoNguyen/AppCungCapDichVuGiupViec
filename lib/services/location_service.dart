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

      // Thu lay vi tri gan nhat truoc de khong phai doi GPS ve tinh qua lau
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) {
          final diff = DateTime.now().difference(last.timestamp);
          if (diff.inMinutes < 15) {
            return LocationResult._(last, null);
          }
        }
      } catch (_) {}

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        ),
      );
      return LocationResult._(pos, null);
    } catch (e) {
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) return LocationResult._(last, null);
      } catch (_) {}
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

  static const List<({String ten, double viDo, double kinhDo})> _tamQuanHcm = [
    (ten: 'Quận 1', viDo: 10.7769, kinhDo: 106.7009),
    (ten: 'Quận 3', viDo: 10.7843, kinhDo: 106.6844),
    (ten: 'Quận 4', viDo: 10.7578, kinhDo: 106.7013),
    (ten: 'Quận 5', viDo: 10.7540, kinhDo: 106.6634),
    (ten: 'Quận 6', viDo: 10.7480, kinhDo: 106.6352),
    (ten: 'Quận 7', viDo: 10.7340, kinhDo: 106.7215),
    (ten: 'Quận 8', viDo: 10.7240, kinhDo: 106.6286),
    (ten: 'Quận 10', viDo: 10.7746, kinhDo: 106.6670),
    (ten: 'Quận 11', viDo: 10.7629, kinhDo: 106.6505),
    (ten: 'Quận 12', viDo: 10.8672, kinhDo: 106.6413),
    (ten: 'Quận Bình Thạnh', viDo: 10.8106, kinhDo: 106.7091),
    (ten: 'Quận Bình Tân', viDo: 10.7653, kinhDo: 106.6036),
    (ten: 'Quận Gò Vấp', viDo: 10.8387, kinhDo: 106.6653),
    (ten: 'Quận Phú Nhuận', viDo: 10.7991, kinhDo: 106.6803),
    (ten: 'Quận Tân Bình', viDo: 10.8015, kinhDo: 106.6527),
    (ten: 'Quận Tân Phú', viDo: 10.7901, kinhDo: 106.6281),
    (ten: 'Thành phố Thủ Đức', viDo: 10.8231, kinhDo: 106.7710),
    (ten: 'Huyện Bình Chánh', viDo: 10.6874, kinhDo: 106.5939),
    (ten: 'Huyện Cần Giờ', viDo: 10.4113, kinhDo: 106.9547),
    (ten: 'Huyện Củ Chi', viDo: 11.0067, kinhDo: 106.5135),
    (ten: 'Huyện Hóc Môn', viDo: 10.8862, kinhDo: 106.5923),
    (ten: 'Huyện Nhà Bè', viDo: 10.6950, kinhDo: 106.7400),
  ];

  /// Đoán quận/huyện TP.HCM từ toạ độ (chọn tâm gần nhất trong bán kính 30km).
  static String? doanQuanTheoToaDo(double lat, double lng) {
    ({String ten, double viDo, double kinhDo})? gan;
    double min = double.infinity;
    for (int i = 0; i < _tamQuanHcm.length; i++) {
      final t = _tamQuanHcm[i];
      final d = distanceKm(lat, lng, t.viDo, t.kinhDo);
      if (d < min) {
        min = d;
        gan = t;
      }
    }
    return (gan != null && min <= 30) ? gan.ten : null;
  }

  /// Tìm tên quận từ danh sách các trường địa chỉ của Geocoder.
  static String? _timTenQuan(Iterable<String?> texts) {
    for (final raw in texts) {
      if (raw == null || raw.trim().isEmpty) continue;
      final t = raw.trim().toLowerCase();
      if (t == 'thành phố hồ chí minh' ||
          t == 'thành phố hcm' ||
          t == 'tp. hcm' ||
          t == 'tp.hcm' ||
          t == 'ho chi minh city' ||
          t == 'hồ chí minh') {
        continue;
      }
      for (final q in _tamQuanHcm) {
        final qTen = q.ten.toLowerCase();
        final qRutGon = qTen.replaceFirst(RegExp(r'^(quận|huyện|thành phố)\s+'), '');
        if (t == qTen || t.contains(qTen) || t.contains(qRutGon)) {
          return q.ten;
        }
      }
    }
    return null;
  }

  /// Lấy chi tiết thông tin hành chính (quận huyện, tỉnh thành, địa chỉ) từ toạ độ GPS.
  static Future<Map<String, String>> getAddressDetails(double lat, double lng) async {
    try {
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
      // Mac dinh ve Quan 1 neu toa do o xa ngoai TP.HCM (may ao o My hoac ngoai tinh)
      quanHuyen ??= 'Quận 1';

      String tinhThanh = p?.administrativeArea ?? '';
      if (tinhThanh.isEmpty || !tinhThanh.toLowerCase().contains('hồ chí minh')) {
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
