import 'dart:async';

import 'package:geolocator/geolocator.dart';

import 'collaborator_api_service.dart';
import 'location_service.dart';

/// Gửi vị trí GPS của CTV lên máy chủ (lưu Redis) mỗi [interval] khi app đang mở.
/// Nghe luồng vị trí của Geolocator và gửi điểm mới nhất theo chu kỳ, không xin GPS mỗi lần.
class CtvLocationTracker {
  CtvLocationTracker._();
  static final CtvLocationTracker instance = CtvLocationTracker._();

  static const interval = Duration(seconds: 5);

  final CollaboratorApiService _api = CollaboratorApiService();
  StreamSubscription<Position>? _sub;
  Timer? _timer;
  Position? _latest;
  int _ctvId = 0;
  bool _sending = false;

  bool get isRunning => _timer != null;

  /// Bắt đầu theo dõi. Trả về null nếu chạy được, ngược lại là thông điệp lỗi (chưa cấp quyền...).
  Future<String?> start(int congTacVienId) async {
    if (congTacVienId == 0) return 'Chưa có hồ sơ cộng tác viên.';
    if (isRunning && _ctvId == congTacVienId) return null;
    stop();
    _ctvId = congTacVienId;

    // Xin quyền + lấy điểm đầu tiên
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
  }

  Future<void> _send() async {
    final p = _latest;
    if (p == null || _sending) return;
    _sending = true;
    try {
      await _api.updateLocation(_ctvId, p.latitude, p.longitude);
    } catch (_) {
      // Mất mạng: bỏ qua, lần sau gửi tiếp
    } finally {
      _sending = false;
    }
  }
}
