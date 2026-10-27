import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import 'customer_home_screen.dart';
import 'booking_history_screen.dart';
import 'customer_notification_screen.dart';
import 'customer_account_screen.dart';
import 'cart_screen.dart';
import '../../services/app_realtime.dart';
import '../../services/cart_service.dart';
import '../../services/session_service.dart';
import '../../widgets/chuong_thong_bao.dart';

/// Khung chính app Khách hàng - bố cục tab giống bTaskee:
/// Trang chủ / Hoạt động / Thông báo / Tài khoản
/// Có nút giỏ hàng lơ lửng phong cách Be ở góc dưới phải.
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
    // Tải số lượng giỏ hàng cache
    CartService.refreshCount();
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

  Widget _buildFloatingCart() {
    return Positioned(
      right: 16,
      bottom: 16,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: Colors.white,
            shape: const CircleBorder(),
            elevation: 6,
            shadowColor: Colors.black38,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                );
                CartService.refreshCount();
              },
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.brand300, width: 1.5),
                ),
                child: const Center(
                  child: Icon(
                    Icons.shopping_cart_rounded,
                    color: AppColors.brand500,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
          // Huy hiệu đỏ đếm số lượng giỏ hàng
          ValueListenableBuilder<int>(
            valueListenable: CartService.countNotifier,
            builder: (context, count, _) {
              if (count <= 0) return const SizedBox.shrink();
              return Positioned(
                top: -2,
                right: -2,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
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
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
          // Nút giỏ hàng lơ lửng phong cách Be (hiện ở tab Trang chủ)
          if (_currentIndex == 0) _buildFloatingCart(),
        ],
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
