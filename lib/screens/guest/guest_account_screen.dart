import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';

class GuestAccountScreen extends StatelessWidget {
  const GuestAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Tài khoản'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildAuthButtons(context),
            const SizedBox(height: 16),
            _buildGuestOptions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.brand700, AppColors.brand500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 40),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white38, width: 2),
            ),
            child: const Icon(
              Icons.person_outline,
              color: AppColors.white,
              size: 44,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Khách chưa đăng nhập',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Đăng nhập để trải nghiệm đầy đủ tính năng',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              icon: const Icon(Icons.login),
              label: const Text('Đăng nhập'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brand500,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                );
              },
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Đăng ký tài khoản'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.brand500,
                side: const BorderSide(color: AppColors.brand500, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestOptions() {
    final options = [
      {'icon': Icons.help_outline, 'label': 'Trợ giúp & Hỗ trợ'},
      {'icon': Icons.info_outline, 'label': 'Về chúng tôi'},
      {'icon': Icons.phone_outlined, 'label': 'Liên hệ: 1800 xxxx'},
      {'icon': Icons.privacy_tip_outlined, 'label': 'Chính sách bảo mật'},
      {'icon': Icons.description_outlined, 'label': 'Điều khoản dịch vụ'},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
      child: Column(
        children: options.asMap().entries.map((e) {
          final idx = e.key;
          final opt = e.value;
          return Column(
            children: [
              ListTile(
                leading: Icon(opt['icon'] as IconData, color: AppColors.brand500),
                title: Text(
                  opt['label'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right,
                    color: AppColors.textSecondary),
                onTap: () {},
              ),
              if (idx < options.length - 1)
                const Divider(height: 1, indent: 56, color: AppColors.divider),
            ],
          );
        }).toList(),
      ),
    );
  }
}
