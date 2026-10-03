import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import 'booking_screen.dart';
import '../auth/login_screen.dart';

class ServiceDetailScreen extends StatelessWidget {
  final Map<String, dynamic> service;

  const ServiceDetailScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final title = ((service['title'] as String?) ?? 'Dịch vụ giúp việc theo giờ')
        .replaceAll('\n', ' ');
    final desc = (service['description'] as String?) ??
        'Giải pháp hoàn hảo cho gia đình bận rộn. Cộng tác viên đã được đào tạo bài bản, lý lịch rõ ràng, tận tâm dọn dẹp.';
    final Color accent = service['iconColor'] as Color? ?? AppColors.brand500;

    final benefits = (service['benefits'] as List<dynamic>?) ??
        [
          'Bảo hiểm đổ vỡ tài sản lên tới 10 triệu đồng',
          'Cộng tác viên đã tiêm đủ vacxin, lý lịch sạch 100%',
          'Đổi người dọn miễn phí nếu không hài lòng',
        ];

    final pricing = (service['pricing'] as List<dynamic>?) ??
        [
          {'name': 'Ca 2 giờ (tối đa 55m² / 2 phòng)', 'price': '140.000đ'},
          {'name': 'Ca 3 giờ (tối đa 85m² / 3 phòng)', 'price': '190.000đ'},
          {'name': 'Ca 4 giờ (tối đa 105m² / 4 phòng)', 'price': '240.000đ'},
        ];

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: Text(title),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // Ảnh minh hoạ dịch vụ
          Container(
            height: 170,
            color: accent.withValues(alpha: 0.10),
            child: Stack(
              children: [
                Positioned(
                  right: -30,
                  top: -30,
                  child: CircleAvatar(
                    radius: 80,
                    backgroundColor: accent.withValues(alpha: 0.10),
                  ),
                ),
                Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      service['icon'] as IconData? ??
                          Icons.cleaning_services_rounded,
                      size: 48,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tên + mô tả
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (service['price'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    service['price'] as String,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brand500,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: const [
                    Icon(Icons.star_rounded, color: AppColors.star, size: 18),
                    SizedBox(width: 4),
                    Text(
                      '4.9',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '• Hơn 10.000 lượt đặt',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Quyền lợi
          _section(
            'Quyền lợi dành cho bạn',
            Column(
              children: benefits
                  .map((b) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: AppColors.green500, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                b.toString(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 10),

          // Bảng giá
          _section(
            'Bảng giá tham khảo',
            Column(
              children: [
                for (int i = 0; i < pricing.length; i++) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            (pricing[i] as Map<String, dynamic>)['name']
                                as String,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          (pricing[i] as Map<String, dynamic>)['price']
                              as String,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.brand600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i < pricing.length - 1) const Divider(height: 1),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
            16, 10, 16, 10 + MediaQuery.of(context).padding.bottom),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: () => _handleBooking(context),
            child: const Text('Đặt dịch vụ'),
          ),
        ),
      ),
    );
  }

  Widget _section(String title, Widget child) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  void _handleBooking(BuildContext context) {
    // Cho phép đặt tiếp với tư cách khách hoặc đăng nhập
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Bắt đầu đặt lịch',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bạn có thể tiếp tục đặt lịch ngay hoặc đăng nhập để lưu thông tin và nhận ưu đãi thành viên.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookingScreen(service: service),
                    ),
                  );
                },
                child: const Text('Tiếp tục đặt lịch'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: const Text(
                  'Đăng nhập để nhận ưu đãi',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
