import 'package:flutter/material.dart';
import 'core/app_colors.dart';
import 'core/app_theme.dart';
import 'screens/guest/guest_main_screen.dart';
import 'screens/customer/customer_main_screen.dart';
import 'screens/collaborator/collaborator_main_screen.dart';
import 'screens/auth/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HousekeepingApp());
}

class HousekeepingApp extends StatelessWidget {
  const HousekeepingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ứng dụng Cung cấp Dịch vụ Giúp việc',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const AppEntryScreen(),
    );
  }
}

/// An entry screen that allows seamless demonstration of all 3 user roles:
/// 1. Khách vãng lai (Guest)
/// 2. Khách hàng thành viên (Customer)
/// 3. Cộng tác viên giúp việc (Collaborator)
/// 4. Đăng nhập / Đăng ký (Auth)
class AppEntryScreen extends StatefulWidget {
  const AppEntryScreen({super.key});

  @override
  State<AppEntryScreen> createState() => _AppEntryScreenState();
}

class _AppEntryScreenState extends State<AppEntryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // App Brand Header
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.brand700, AppColors.brand500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brand500.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.home_repair_service,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'ỨNG DỤNG GIÚP VIỆC TIỆN ÍCH',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.brand700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Nền tảng kết nối dịch vụ giúp việc gia đình & văn phòng uy tín hàng đầu',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 36),

              // Role Selection Header
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Chọn vai trò để trải nghiệm ứng dụng:',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Role Card 1: Khách vãng lai (Guest)
              _buildRoleCard(
                title: 'Khách vãng lai (Guest)',
                subtitle:
                    'Xem danh mục dịch vụ, bảng giá công khai, tìm kiếm CTV tiêu biểu',
                icon: Icons.explore_outlined,
                badge: 'Xem thử',
                badgeColor: AppColors.brand300,
                color: AppColors.brand500,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const GuestMainScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Role Card 2: Khách hàng (Customer)
              _buildRoleCard(
                title: 'Khách hàng (Customer)',
                subtitle:
                    'Đặt lịch dịch vụ, chọn CTV, áp mã giảm giá, theo dõi tiến độ & đánh giá',
                icon: Icons.person_outline,
                badge: 'Người dùng',
                badgeColor: AppColors.brand500,
                color: AppColors.brand600,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CustomerMainScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Role Card 3: Cộng tác viên (Collaborator)
              _buildRoleCard(
                title: 'Cộng tác viên (Collaborator)',
                subtitle:
                    'Nhận đơn mới, xem lịch làm việc, báo cáo hoàn thành & theo dõi thu nhập ví',
                icon: Icons.badge_outlined,
                badge: 'Đối tác',
                badgeColor: AppColors.brand700,
                color: AppColors.brand700,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CollaboratorMainScreen()),
                  );
                },
              ),
              const SizedBox(height: 28),

              // Login / Auth Entry Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LoginScreen()),
                    );
                  },
                  icon: const Icon(Icons.login),
                  label: const Text(
                    'Đăng nhập / Đăng ký tài khoản',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brand500,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Footer Note
              const Text(
                'Đồ án Tốt nghiệp / Luận án Chuyên ngành Công nghệ Phần mềm',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String badge,
    required Color badgeColor,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            color: badgeColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
