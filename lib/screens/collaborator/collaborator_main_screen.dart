import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import 'collaborator_orders_screen.dart';
import 'collaborator_schedule_screen.dart';
import 'collaborator_account_screen.dart';

class CollaboratorMainScreen extends StatefulWidget {
  final int initialIndex;
  const CollaboratorMainScreen({super.key, this.initialIndex = 0});

  @override
  State<CollaboratorMainScreen> createState() => _CollaboratorMainScreenState();
}

class _CollaboratorMainScreenState extends State<CollaboratorMainScreen> {
  late int _currentIndex;

  final List<Widget> _screens = const [
    CollaboratorOrdersScreen(),
    CollaboratorScheduleScreen(),
    CollaboratorAccountScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          selectedItemColor: AppColors.ctvYellowDark,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 12,
          ),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment),
              label: 'Đơn hàng',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month),
              label: 'Lịch làm việc',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Hồ sơ & Ví',
            ),
          ],
        ),
      ),
    );
  }
}
