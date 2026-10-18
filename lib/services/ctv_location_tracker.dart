import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'collaborator_api_service.dart';
import 'location_service.dart';

/// Tra lại quận từ toạ độ khi đã đi xa hơn 200 m hoặc sau 60 giây (geocoder tốn mạng, không tra mỗi 5 giây).
bool canTraLaiDiaChi(double? viDoCu, double? kinhDoCu, DateTime? luc, double viDo, double kinhDo, DateTime bayGio) {
  if (viDoCu == null || kinhDoCu == null || luc == null) return true;
  if (bayGio.difference(luc) >= const Duration(seconds: 60)) return true;
  return Geolocator.distanceBetween(viDoCu, kinhDoCu, viDo, kinhDo) > 200;
}

/// Gửi vị trí GPS của CTV lên máy chủ (lưu Redis) mỗi [interval] khi app đang mở, kèm quận đang đứng.
/// Máy chủ chỉ ghi CSDL khi CTV sang quận khác: khu vực nhận việc được thay bằng quận đó.
/// Nghe luồng vị trí của Geolocator và gửi điểm mới nhất theo chu kỳ, không xin GPS mỗi lần.
class CtvLocationTracker {
  CtvLocationTracker._();
  static final CtvLocationTracker instance = CtvLocationTracker._();

  static const interval = Duration(seconds: 10);

  final CollaboratorApiService _api = CollaboratorApiService();
  StreamSubscription<Position>? _sub;
  Timer? _timer;
  Position? _latest;
  int _ctvId = 0;
  bool _sending = false;
  String? _currentDistrict;

  // Quận đã tra gần nhất và toạ độ / thời điểm tra
  ({String? quanHuyen, String? tinhThanh, String? diaChi})? _quan;
  double? _viDoTra;
  double? _kinhDoTra;
  DateTime? _lucTra;

  bool get isRunning => _timer != null;
  String? get currentDistrict => _currentDistrict;

  /// Bắt đầu theo dõi. Trả về null nếu chạy được, ngược lại là thông điệp lỗi (chưa cấp quyền...).
  Future<String?> start(int congTacVienId) async {
    if (congTacVienId == 0) return 'Chưa có hồ sơ cộng tác viên.';
    if (isRunning && _ctvId == congTacVienId) return null;
    stop();
    _ctvId = congTacVienId;

    try {
      final prefs = await SharedPreferences.getInstance();
      _currentDistrict ??= prefs.getString('ctv_last_district_$_ctvId');
    } catch (_) {}

    // Xin quyền + lấy điểm đầu tiên với độ chính xác cao
    final first = await LocationService.getCurrentPosition();
    if (!first.ok) return first.error;
    _latest = first.position;

    _sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      ),
    ).listen((p) => _latest = p, onError: (_) {});

    _timer = Timer.periodic(interval, (_) => _send());
    _send();
    return null;
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _sub?.cancel();
    _sub = null;
    _quan = null;
    _viDoTra = null;
    _kinhDoTra = null;
    _lucTra = null;
  }

  Future<void> _send() async {
    final p = _latest;
    if (p == null || _sending) return;
    _sending = true;
    try {
      // Phân giải địa giới hành chính (Quận/Huyện, Tỉnh/Thành)
      final geo = await LocationService.getAddressDetails(p.latitude, p.longitude);
      final quanHuyen = geo['quanHuyen'];
      final tinhThanh = geo['tinhThanh'];
      final diaChi = geo['diaChi'];

      final res = await _api.updateLocation(
        _ctvId,
        p.latitude,
        p.longitude,
        quanHuyen: quanHuyen,
        tinhThanh: tinhThanh,
        diaChi: diaChi,
      );

      if (res.success && res.data != null) {
        final kv = res.data!['khuVucHienTai']?.toString();
        final finalDistrict = (kv != null && kv.isNotEmpty) ? kv : quanHuyen;
        if (finalDistrict != null && finalDistrict.isNotEmpty) {
          _currentDistrict = finalDistrict;
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('ctv_last_district_$_ctvId', finalDistrict);
          } catch (_) {}
        }
      }
    } catch (_) {
      // Mất mạng: bỏ qua, lần sau gửi tiếp
    } finally {
      _sending = false;
    }
  }
}
