import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_colors.dart';
import '../auth/change_password_screen.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import '../../services/session_service.dart';
import 'address_book_screen.dart';
import 'customer_main_screen.dart';

class CustomerAccountScreen extends StatefulWidget {
  const CustomerAccountScreen({super.key});

  @override
  State<CustomerAccountScreen> createState() => _CustomerAccountScreenState();
}

class _CustomerAccountScreenState extends State<CustomerAccountScreen> {
  UserSession? _session;

  bool get _loggedIn => _session?.isCustomer == true;

  @override
  void initState() {
    super.initState();
    SessionService.load().then((s) {
      if (mounted) setState(() => _session = s);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBg,
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(context),
              const SizedBox(height: 10),

              // Tiện ích nhanh dạng lưới như bTaskee
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    _quickAction(Icons.local_offer_outlined, 'Ưu đãi\ncủa tôi',
                        const Color(0xFFFF8228),
                        () => _promptLogin(context, 'Ưu đãi của tôi')),
                    _quickAction(Icons.receipt_long_outlined,
                        'Lịch sử\ngiao dịch', const Color(0xFF2F80ED),
                        () => _promptLogin(context, 'Lịch sử giao dịch')),
                    _quickAction(Icons.favorite_border_rounded,
                        'Người làm\nyêu thích', const Color(0xFFEF4444),
                        () => _promptLogin(context, 'Người làm yêu thích')),
                    _quickAction(Icons.card_giftcard_rounded,
                        'Giới thiệu\nbạn bè', AppColors.brand500,
                        () => _showReferralDialog(context)),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              if (_loggedIn) ...[
                _buildMenuGroup([
                  _OptionItem(
                    icon: Icons.location_on_outlined,
                    title: 'Sổ địa chỉ',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AddressBookScreen(khachHangId: _session!.userId),
                      ),
                    ),
                  ),
                  _OptionItem(
                    icon: Icons.lock_outline_rounded,
                    title: 'Đổi mật khẩu',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ChangePasswordScreen()),
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
              ],
              _buildMenuGroup([
                _OptionItem(
                  icon: Icons.help_outline_rounded,
                  title: 'Trợ giúp',
                  onTap: () => _showHelpDialog(context),
                ),
                _OptionItem(
                  icon: Icons.settings_outlined,
                  title: 'Cài đặt',
                  onTap: () => _showSettingsDialog(context),
                ),
                _OptionItem(
                  icon: Icons.info_outline_rounded,
                  title: 'Giới thiệu bTaskee',
                  onTap: () => _showAboutDialog(context),
                ),
              ]),
              if (_loggedIn) ...[
                const SizedBox(height: 10),
                Container(
                  color: Colors.white,
                  child: ListTile(
                    onTap: _confirmLogout,
                    leading:
                        const Icon(Icons.logout_rounded, color: AppColors.error),
                    title: const Text(
                      'Đăng xuất',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                'Phiên bản 1.0.0',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    if (_loggedIn) return _buildUserHeader(context);
    return _buildGuestHeader(context);
  }

  Widget _buildUserHeader(BuildContext context) {
    final s = _session!;
    final name = s.fullName.isNotEmpty ? s.fullName : 'Khách hàng';
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppColors.brandGradient),
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 16, 16, 20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Text(
              name.characters.first.toUpperCase(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.brand600,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.soDienThoai,
                  style: const TextStyle(fontSize: 13.5, color: Colors.white),
                ),
                if (s.maNguoiDung != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Mã KH: ${s.maNguoiDung}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Đăng xuất?'),
        content: const Text('Bạn có chắc muốn đăng xuất khỏi tài khoản này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await SessionService.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const CustomerMainScreen()),
      (route) => false,
    );
  }

  Widget _buildGuestHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppColors.brandGradient),
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 16, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.6), width: 2),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppColors.brand300,
                  size: 36,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Khách',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Đăng nhập để đặt lịch và nhận ưu đãi',
                      style: TextStyle(fontSize: 13, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RegisterScreen()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 1.2),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      'Đăng ký',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.brand500,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text('Đăng nhập'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickAction(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuGroup(List<_OptionItem> items) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            ListTile(
              onTap: items[i].onTap,
              leading: Icon(items[i].icon, color: AppColors.textSecondary),
              title: Text(
                items[i].title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted),
            ),
            if (i < items.length - 1) const Divider(height: 1, indent: 56),
          ],
        ],
      ),
    );
  }

  void _promptLogin(BuildContext context, String featureName) {
    if (_loggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$featureName đang được cập nhật.')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.brandLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: AppColors.brand500,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Đăng nhập để xem $featureName',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Trải nghiệm tính năng tiện ích, lưu trữ ưu đãi và quản lý dịch vụ dễ dàng hơn.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brand500,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Đăng nhập ngay',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReferralDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.card_giftcard, color: AppColors.brand500),
            SizedBox(width: 8),
            Text('Giới thiệu bạn bè', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: const Text(
          'Chia sẻ mã giới thiệu cho bạn bè nhận ngay voucher giảm 50.000đ cho đơn hàng dịch vụ đầu tiên!',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _promptLogin(context, 'Mã giới thiệu của bạn');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brand500,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Nhận mã giới thiệu'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Trung tâm Trợ giúp'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Hotline hỗ trợ khách hàng: 1900 xxxx (8:00 - 21:00)'),
            SizedBox(height: 8),
            Text('• Email giải đáp: hotro@btaskee.vn'),
            SizedBox(height: 8),
            Text('• Đội ngũ kỹ thuật túc trực 24/7 giải quyết khiếu nại.'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brand500,
              foregroundColor: Colors.white,
            ),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Cài đặt ứng dụng'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Ngôn ngữ: Tiếng Việt (Mặc định)'),
            SizedBox(height: 8),
            Text('• Thông báo đẩy: Đang bật'),
            SizedBox(height: 8),
            Text('• Phiên bản ứng dụng: 1.0.0 (Bản thử nghiệm)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Giới thiệu bTaskee'),
        content: const Text(
          'bTaskee là nền tảng công nghệ kết nối các dịch vụ giúp việc gia đình, vệ sinh điện lạnh và chăm sóc nhà cửa chuyên nghiệp, mang đến không gian sống sạch sẽ, tiện nghi và hạnh phúc cho mọi nhà.',
          style: TextStyle(fontSize: 13.5, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brand500,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tuyệt vời'),
          ),
        ],
      ),
    );
  }
}

class _OptionItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  _OptionItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}
