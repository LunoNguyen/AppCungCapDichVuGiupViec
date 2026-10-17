import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Hiện thông báo lên thanh thông báo của điện thoại (khi app đang chạy hoặc chạy nền),
/// dùng cho sự kiện "thong-bao-moi" nhận qua realtime ([AppRealtime]).
class ThongBaoCucBo {
  ThongBaoCucBo._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _daKhoiTao = false;
  static int _soThuTu = 0;

  static AndroidNotificationDetails _kenh(String noiDung) => AndroidNotificationDetails(
        'thong_bao_btaskee',
        'Thông báo bTaskee',
        channelDescription: 'Đơn đặt, phân công, ưu đãi',
        importance: Importance.high,
        priority: Priority.high,
        ticker: 'Thông báo bTaskee',
        category: AndroidNotificationCategory.message,
        styleInformation: BigTextStyleInformation(noiDung), // nội dung dài hiện đủ khi kéo xuống
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

  /// [id]: mã thông báo trên máy chủ, mỗi thông báo một mục riêng trên thanh thông báo.
  static Future<void> hien(String tieuDe, String noiDung, {int? id}) async {
    if (!_daKhoiTao) await khoiTao();
    if (!_daKhoiTao) return;
    try {
      await _plugin.show(
        id: id ?? (_soThuTu++ & 0x7fffffff),
        title: tieuDe,
        body: noiDung,
        notificationDetails: NotificationDetails(
          android: _kenh(noiDung),
          iOS: const DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      debugPrint('Không hiện được thông báo: $e');
    }
  }
}
