import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import 'customer_home_screen.dart';
import 'booking_history_screen.dart';
import 'customer_notification_screen.dart';
import 'customer_account_screen.dart';
import '../../services/app_realtime.dart';
import '../../services/session_service.dart';
import '../../widgets/chuong_thong_bao.dart';
import '../../services/gio_hang.dart';
import '../../widgets/nut_gio_hang.dart';

/// Khung chính app Khách hàng - bố cục tab giống bTaskee:
/// Trang chủ / Hoạt động / Thông báo / Tài khoản
class CustomerMainScreen extends StatefulWidget {
  final int initialIndex;
  const CustomerMainScreen({super.key, this.initialIndex = 0});

  @override
  State<CustomerMainScreen> createState() => _CustomerMainScreenState();
}

class _CustomerMainScreenState extends State<CustomerMainScreen> {
  late int _currentIndex;
  final GlobalKey<CustomerNotificationScreenState> _notifKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    GioHang.instance.tai(); // giỏ hàng lưu trên máy: hiện nút giỏ nổi khi còn dịch vụ
    // Realtime: thông báo mới hiện lên điện thoại + số chưa đọc trên chuông
    SessionService.load().then((s) {
      if (s != null && s.taiKhoanId > 0) {
        AppRealtime.instance.batDau(taiKhoanId: s.taiKhoanId, laCongTacVien: false);
      }
    });
  }

  void _switchTab(int index) {
    if (index == 2) {
      _notifKey.currentState?.refresh();
    }
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      CustomerHomeScreen(onSwitchTab: _switchTab),
      BookingHistoryScreen(onSwitchTab: _switchTab),
      CustomerNotificationScreen(key: _notifKey),
      const CustomerAccountScreen(),
    ];

    return Scaffold(
      floatingActionButton: _currentIndex == 0 ? const NutGioHang() : null,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _switchTab,
          selectedItemColor: AppColors.brand500,
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
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Trang chủ',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.event_note_outlined),
              activeIcon: Icon(Icons.event_note_rounded),
              label: 'Hoạt động',
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
    );
  }
}
