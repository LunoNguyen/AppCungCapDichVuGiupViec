import 'dart:async';

import 'package:flutter/foundation.dart';
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
class CtvLocationTracker extends ChangeNotifier {
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

  bool get isRunning => _timer != null;
  String? get currentDistrict => _currentDistrict;

  void _setDistrict(String? d) {
    if (d == null || d.trim().isEmpty) return;
    final trimmed = d.trim();
    if (_currentDistrict != trimmed) {
      _currentDistrict = trimmed;
      notifyListeners();
    }
  }

  /// Bắt đầu theo dõi. Trả về null nếu chạy được, ngược lại là thông điệp lỗi (chưa cấp quyền...).
  Future<String?> start(int congTacVienId) async {
    if (congTacVienId == 0) return 'Chưa có hồ sơ cộng tác viên.';
    if (isRunning && _ctvId == congTacVienId) return null;
    stop();
    _ctvId = congTacVienId;

    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('ctv_last_district_$_ctvId');
      if (cached != null && cached.isNotEmpty) {
        _setDistrict(cached);
      }
    } catch (_) {}

    // Lấy vị trí ban đầu (nhanh, có cache last known)
    final first = await LocationService.getCurrentPosition();
    if (first.ok && first.position != null) {
      _latest = first.position;
    }

    try {
      _sub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          distanceFilter: 10,
        ),
      ).listen((p) {
        _latest = p;
      }, onError: (_) {});
    } catch (_) {}

    _timer = Timer.periodic(interval, (_) => _send());
    _send();
    return null;
  }

  /// Gửi ngay lập tức vị trí GPS hiện tại lên server.
  Future<void> forceSend() async {
    final pos = await LocationService.getCurrentPosition();
    if (pos.ok && pos.position != null) {
      _latest = pos.position;
      await _send();
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _sub?.cancel();
    _sub = null;
  }

  Future<void> _send() async {
    final p = _latest;
    if (p == null || _sending) return;
    _sending = true;
    try {
      // Phân giải địa giới hành chính (Quận/Huyện, Tỉnh/Thành)
      final geo = await LocationService.getAddressDetails(p.latitude, p.longitude);
      final quanHuyen = geo['quanHuyen'] ?? '';
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
        final finalDistrict = (kv != null && kv.isNotEmpty)
            ? kv
            : (quanHuyen.isNotEmpty ? quanHuyen : 'Quận 1');
        _setDistrict(finalDistrict);
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('ctv_last_district_$_ctvId', finalDistrict);
        } catch (_) {}
      } else if (quanHuyen.isNotEmpty) {
        _setDistrict(quanHuyen);
      }
    } catch (_) {
      // Mất mạng: nếu chưa có quận thì tạm dùng fallback
      if (_currentDistrict == null || _currentDistrict!.isEmpty) {
        _setDistrict('Quận 1');
      }
    } finally {
      _sending = false;
    }
  }
}
