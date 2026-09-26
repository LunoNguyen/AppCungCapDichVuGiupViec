import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../widgets/shared_widgets.dart';
import '../auth/login_screen.dart';

class CollaboratorAccountScreen extends StatefulWidget {
  const CollaboratorAccountScreen({super.key});

  @override
  State<CollaboratorAccountScreen> createState() =>
      _CollaboratorAccountScreenState();
}

class _CollaboratorAccountScreenState extends State<CollaboratorAccountScreen> {
  bool _isAvailable = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Hồ sơ & Thu nhập'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cài đặt hệ thống')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 12),
            _buildAvailabilityToggle(),
            const SizedBox(height: 12),
            _buildEarningsCard(),
            const SizedBox(height: 12),
            _buildPerformanceStats(),
            const SizedBox(height: 16),
            _buildMenuSection('Công việc & Dịch vụ', [
              _CollaboratorMenuItem(
                Icons.handyman_outlined,
                'Dịch vụ đăng ký phụ trách',
                AppColors.brand500,
                '5 dịch vụ',
                () {},
              ),
              _CollaboratorMenuItem(
                Icons.map_outlined,
                'Khu vực nhận việc',
                AppColors.brand600,
                'Q.1, Q.3, Q.Bình Thạnh',
                () {},
              ),
              _CollaboratorMenuItem(
                Icons.work_history_outlined,
                'Lịch sử công việc hoàn thành',
                const Color(0xFF4CAF50),
                '148 ca',
                () {},
              ),
            ]),
            const SizedBox(height: 12),
            _buildMenuSection('Tài chính & Ví', [
              _CollaboratorMenuItem(
                Icons.account_balance_wallet_outlined,
                'Ví thu nhập',
                AppColors.brand500,
                '4.850.000đ',
                () {},
              ),
              _CollaboratorMenuItem(
                Icons.credit_card_outlined,
                'Tài khoản ngân hàng liên kết',
                const Color(0xFF9C27B0),
                'Vietcombank •••• 8868',
                () {},
              ),
              _CollaboratorMenuItem(
                Icons.receipt_long_outlined,
                'Lịch sử rút tiền',
                const Color(0xFFFF9800),
                '',
                () {},
              ),
            ]),
            const SizedBox(height: 12),
            _buildMenuSection('Tài khoản & Hỗ trợ', [
              _CollaboratorMenuItem(
                Icons.badge_outlined,
                'Thông tin cá nhân & CCCD',
                AppColors.brand500,
                'Đã xác thực',
                () {},
              ),
              _CollaboratorMenuItem(
                Icons.star_outline,
                'Đánh giá từ khách hàng',
                AppColors.star,
                '4.9 (126 đánh giá)',
                () {},
              ),
              _CollaboratorMenuItem(
                Icons.support_agent_outlined,
                'Liên hệ hỗ trợ quản trị viên',
                AppColors.brand700,
                '1900 xxxx',
                () {},
              ),
            ]),
            const SizedBox(height: 16),
            _buildLogoutButton(context),
            const SizedBox(height: 32),
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
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'L',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brand600,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _isAvailable ? AppColors.success : Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Flexible(
                      child: Text(
                        'Lê Thị Mai',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade700,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.workspace_premium,
                              size: 12, color: Colors.white),
                          SizedBox(width: 2),
                          Text(
                            'VIP',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Mã CTV: CTV-2026-089',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: AppColors.star, size: 14),
                    const SizedBox(width: 4),
                    const Text(
                      '4.9',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      ' • 148 ca làm việc thành công',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isAvailable
              ? AppColors.success.withOpacity(0.3)
              : AppColors.divider,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isAvailable
                  ? AppColors.success.withOpacity(0.12)
                  : Colors.grey.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isAvailable ? Icons.notifications_active : Icons.notifications_off,
              color: _isAvailable ? AppColors.success : Colors.grey,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isAvailable ? 'Sẵn sàng nhận việc' : 'Tạm dừng nhận việc',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  _isAvailable
                      ? 'Hệ thống sẽ ghép đơn mới khi có khách đặt'
                      : 'Bạn sẽ không nhận được thông báo đơn mới',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isAvailable,
            activeColor: AppColors.success,
            onChanged: (val) {
              setState(() {
                _isAvailable = val;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(val
                      ? 'Đã bật chế độ nhận việc!'
                      : 'Đã tạm dừng nhận việc!'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F3B46), Color(0xFF1B5E6E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand700.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.wallet, color: AppColors.brand300, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Số dư ví thu nhập',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Tháng này',
                  style: TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '4.850.000 đ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showWithdrawModal(context);
                  },
                  icon: const Icon(Icons.arrow_downward, size: 16),
                  label: const Text('Rút về ngân hàng'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brand500,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sao kê thu nhập')),
                  );
                },
                icon: const Icon(Icons.receipt, size: 16),
                label: const Text('Sao kê'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white38),
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showWithdrawModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Rút tiền về tài khoản',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.neutral100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.account_balance, color: AppColors.brand500),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vietcombank - CN Tân Định',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '0071001234567 • LE THI MAI',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const TextField(
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Số tiền muốn rút (VNĐ)',
                  prefixIcon: Icon(Icons.attach_money),
                  hintText: 'Tối thiểu 100.000đ',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Yêu cầu rút tiền đã được tạo thành công! Tiền sẽ về trong 2-4 giờ làm việc.'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  child: const Text('Xác nhận rút tiền'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPerformanceStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hiệu suất làm việc tháng này',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatItem('32', 'Ca đã hoàn thành', Icons.check_circle_outline,
                  AppColors.success),
              _buildDivider(),
              _buildStatItem('98%', 'Tỷ lệ nhận đơn', Icons.trending_up,
                  AppColors.brand500),
              _buildDivider(),
              _buildStatItem('4.9/5', 'Điểm trung bình', Icons.star_outline,
                  AppColors.star),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 36,
      width: 1,
      color: AppColors.divider,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildMenuSection(
      String title, List<_CollaboratorMenuItem> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          ...items.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            return Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: item.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(item.icon, color: item.color, size: 20),
                  ),
                  title: Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (item.subtext.isNotEmpty)
                        Text(
                          item.subtext,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right,
                          color: AppColors.textSecondary, size: 18),
                    ],
                  ),
                  onTap: item.onTap,
                ),
                if (idx < items.length - 1)
                  const Divider(
                      height: 1, indent: 56, color: AppColors.divider),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Đăng xuất'),
              content: const Text(
                  'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản Cộng tác viên?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(initialRoleTab: 1),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error),
                  child: const Text('Đăng xuất'),
                ),
              ],
            ),
          );
        },
        icon: const Icon(Icons.logout, color: AppColors.error),
        label: const Text(
          'Đăng xuất tài khoản CTV',
          style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.error),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _CollaboratorMenuItem {
  final IconData icon;
  final String title;
  final Color color;
  final String subtext;
  final VoidCallback onTap;

  _CollaboratorMenuItem(
      this.icon, this.title, this.color, this.subtext, this.onTap);
}
