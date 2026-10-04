import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
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

  final List<Widget> _screens = const [
    CollaboratorOrdersScreen(),
    CollaboratorScheduleScreen(),
    CollaboratorNotificationsScreen(),
    CollaboratorAccountScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    WidgetsBinding.instance.addObserver(this);
    _batDauGuiViTri();
  }

  /// Gửi vị trí GPS lên máy chủ mỗi 5 giây khi app đang mở (CSKH theo dõi đơn đang thực hiện).
  Future<void> _batDauGuiViTri() async {
    final s = await SessionService.load();
    if (s == null || !s.isCollaborator) return;
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
    return Scaffold(
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
            setState(() {
              _currentIndex = index;
            });
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
              icon: Icon(Icons.notifications_none_rounded),
              activeIcon: Icon(Icons.notifications_rounded),
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
    );
  }
}
