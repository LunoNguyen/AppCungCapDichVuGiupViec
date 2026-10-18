import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Hiện thông báo lên thanh thông báo của điện thoại (khi app đang chạy hoặc chạy nền),
/// dùng cho sự kiện "thong-bao-moi" nhận qua realtime ([AppRealtime]).
class ThongBaoCucBo {
  ThongBaoCucBo._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _daKhoiTao = false;
  static int _soThuTu = 0;

  static const _kenh = AndroidNotificationDetails(
    'thong_bao_btaskee',
    'Thông báo bTaskee',
    channelDescription: 'Đơn đặt, phân công, ưu đãi',
    importance: Importance.high,
    priority: Priority.high,
  );

  static Future<void> khoiTao() async {
    if (_daKhoiTao || kIsWeb) return;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );
      // Android 13+: hỏi quyền hiện thông báo
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      _daKhoiTao = true;
    } catch (e) {
      debugPrint('Không khởi tạo được thông báo cục bộ: $e');
    }
  }

  static Future<void> hien(String tieuDe, String noiDung) async {
    if (!_daKhoiTao) await khoiTao();
    if (!_daKhoiTao) return;
    try {
      await _plugin.show(
        id: _soThuTu++ & 0x7fffffff,
        title: tieuDe,
        body: noiDung,
        notificationDetails: const NotificationDetails(
          android: _kenh,
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      debugPrint('Không hiện được thông báo: $e');
    }
  }
}
