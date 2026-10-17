import 'package:flutter/material.dart';
import '../../services/app_realtime.dart';
import '../../widgets/chuong_thong_bao.dart';
import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../services/ctv_location_tracker.dart';
import '../../services/session_service.dart';
import 'collaborator_orders_screen.dart';
import 'collaborator_schedule_screen.dart';
import 'collaborator_notifications_screen.dart';
import 'collaborator_account_screen.dart';

/// Khung chính app Cộng tác viên - bố cục tab giống bTaskee Partner:
/// Công việc / Lịch làm / Thông báo / Tài khoản
class CollaboratorMainScreen extends StatefulWidget {
  final int initialIndex;
  const CollaboratorMainScreen({super.key, this.initialIndex = 0});

  @override
  State<CollaboratorMainScreen> createState() => _CollaboratorMainScreenState();
}

class _CollaboratorMainScreenState extends State<CollaboratorMainScreen>
    with WidgetsBindingObserver {
  late int _currentIndex;
  final GlobalKey<CollaboratorOrdersScreenState> _ordersKey = GlobalKey<CollaboratorOrdersScreenState>();
  final GlobalKey<CollaboratorScheduleScreenState> _scheduleKey = GlobalKey<CollaboratorScheduleScreenState>();
  final GlobalKey<CollaboratorNotificationsScreenState> _notifKey = GlobalKey<CollaboratorNotificationsScreenState>();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _screens = [
      CollaboratorOrdersScreen(key: _ordersKey),
      CollaboratorScheduleScreen(key: _scheduleKey),
      // Gắn key để bấm vào tab Thông báo là tải lại danh sách
      CollaboratorNotificationsScreen(key: _notifKey),
      const CollaboratorAccountScreen(),
    ];
    WidgetsBinding.instance.addObserver(this);
    // Đợi khung hình đầu tiên hiện xong rồi mới bật chia sẻ vị trí: service vị trí của Geolocator
    // khởi động trên luồng chính Android, chạy ngay lúc mở app thì máy chậm dễ bị ANR, màn hình đen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _batDauGuiViTri();
    });
  }

  /// Gửi vị trí GPS lên máy chủ mỗi 5 giây khi app đang mở (CSKH theo dõi đơn đang thực hiện).
  Future<void> _batDauGuiViTri() async {
    final s = await SessionService.load();
    if (s == null || !s.isCollaborator) return;
    // Realtime: thông báo mới (được phân công, đơn mới trong khu vực, khách hủy) + số chưa đọc
    if (s.taiKhoanId > 0) {
      AppRealtime.instance.batDau(taiKhoanId: s.taiKhoanId, laCongTacVien: true);
      AppRealtime.instance.capNhatSoChuaDoc();
    }
    final loi = await CtvLocationTracker.instance.start(s.userId);
    if (loi != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Chưa chia sẻ được vị trí: $loi'),
        backgroundColor: AppColors.warning,
      ));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _batDauGuiViTri();
      // Quay lại app: cập nhật thông báo (có thể đã có thông báo mới khi app ở nền)
      _notifKey.currentState?.refresh();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      CtvLocationTracker.instance.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    CtvLocationTracker.instance.stop(); // đăng xuất / rời màn CTV
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // App CTV dùng tông tím chàm (bTaskee Partner), khác tông cam của app khách
    return Theme(
      data: AppTheme.partnerTheme,
      child: Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (index == 2) {
              _notifKey.currentState?.refresh();
            }
            setState(() {
              _currentIndex = index;
            });
            if (index == 0) {
              _ordersKey.currentState?.reload();
            } else if (index == 1) {
              _scheduleKey.currentState?.reload();
            }
          },
          selectedItemColor: AppColors.partner500,
          unselectedItemColor: AppColors.textMuted,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 11.5,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 11.5,
          ),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.work_outline_rounded),
              activeIcon: Icon(Icons.work_rounded),
              label: 'Công việc',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month_rounded),
              label: 'Lịch làm',
            ),
            BottomNavigationBarItem(
              // Số thông báo chưa đọc, cập nhật theo realtime
              icon: ChuongThongBao(),
              activeIcon: ChuongThongBao(icon: Icons.notifications_rounded),
              label: 'Thông báo',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Tài khoản',
            ),
          ],
        ),
      ),
    ),
    );
  }
}
