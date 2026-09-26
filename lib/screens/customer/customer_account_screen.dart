import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../auth/login_screen.dart';

class CustomerAccountScreen extends StatelessWidget {
  const CustomerAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Tài khoản'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 12),
            _buildStatsRow(),
            const SizedBox(height: 16),
            _buildMenuSection('Dịch vụ', [
              _MenuItem(Icons.home_repair_service_outlined, 'Đặt dịch vụ mới', AppColors.brand500),
              _MenuItem(Icons.history, 'Lịch sử đặt dịch vụ', AppColors.brand600),
              _MenuItem(Icons.favorite_outline, 'Dịch vụ yêu thích', Color(0xFFE91E63)),
              _MenuItem(Icons.local_offer_outlined, 'Mã khuyến mãi', Color(0xFFFF5722)),
            ]),
            const SizedBox(height: 12),
            _buildMenuSection('Tài khoản', [
              _MenuItem(Icons.person_outline, 'Thông tin cá nhân', AppColors.brand500),
              _MenuItem(Icons.lock_outline, 'Đổi mật khẩu', AppColors.brand600),
              _MenuItem(Icons.location_on_outlined, 'Địa chỉ đã lưu', Color(0xFF4CAF50)),
              _MenuItem(Icons.payment_outlined, 'Lịch sử thanh toán', Color(0xFF9C27B0)),
            ]),
            const SizedBox(height: 12),
            _buildMenuSection('Hỗ trợ', [
              _MenuItem(Icons.headset_mic_outlined, 'Liên hệ hỗ trợ', AppColors.brand500),
              _MenuItem(Icons.chat_bubble_outline, 'Gửi khiếu nại', AppColors.error),
              _MenuItem(Icons.help_outline, 'Trung tâm trợ giúp', AppColors.textSecondary),
            ]),
            const SizedBox(height: 12),
            _buildLogoutButton(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.brand700, AppColors.brand500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: const Icon(Icons.person, color: AppColors.white, size: 50),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit, size: 16, color: AppColors.brand500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Nguyễn Thị A',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '0901 234 567  •  nguyenthia@email.com',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white38),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, color: AppColors.white, size: 14),
                SizedBox(width: 4),
                Text(
                  'Thành viên từ 09/2025',
                  style: TextStyle(color: AppColors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            _statItem('12', 'Tổng đơn'),
            _divider(),
            _statItem('10', 'Hoàn thành'),
            _divider(),
            _statItem('4.8★', 'Đánh giá TB'),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: AppColors.brand600,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 32, color: AppColors.divider);
  }

  Widget _buildMenuSection(String title, List<_MenuItem> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
              ],
            ),
            child: Column(
              children: items.asMap().entries.map((e) {
                final idx = e.key;
                final item = e.value;
                return Column(
                  children: [
                    ListTile(
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: item.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(item.icon, color: item.color, size: 20),
                      ),
                      title: Text(
                        item.label,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right,
                          color: AppColors.textSecondary),
                      onTap: () {},
                    ),
                    if (idx < items.length - 1)
                      const Divider(height: 1, indent: 56, color: AppColors.divider),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: OutlinedButton.icon(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text('Đăng xuất'),
              content: const Text('Bạn có chắc muốn đăng xuất không?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  child: const Text('Đăng xuất',
                      style: TextStyle(color: AppColors.error)),
                ),
              ],
            ),
          );
        },
        icon: const Icon(Icons.logout, color: AppColors.error),
        label: const Text(
          'Đăng xuất',
          style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.error),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final Color color;
  const _MenuItem(this.icon, this.label, this.color);
}
