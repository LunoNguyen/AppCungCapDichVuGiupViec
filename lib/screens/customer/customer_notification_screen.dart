import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class CustomerNotificationScreen extends StatefulWidget {
  const CustomerNotificationScreen({super.key});

  @override
  State<CustomerNotificationScreen> createState() =>
      _CustomerNotificationScreenState();
}

class _CustomerNotificationScreenState
    extends State<CustomerNotificationScreen> {
  final List<Map<String, dynamic>> _notifications = [
    {
      'icon': Icons.check_circle_outline,
      'color': AppColors.success,
      'title': 'Đơn dịch vụ đã xác nhận',
      'subtitle': 'Đơn Dọn dẹp nhà ngày 28/09 đã được xác nhận. Người làm: Nguyễn Thị Lan.',
      'time': 'Vừa xong',
      'read': false,
    },
    {
      'icon': Icons.star_outline,
      'color': AppColors.star,
      'title': 'Mời đánh giá dịch vụ',
      'subtitle': 'Bạn vừa sử dụng Nấu ăn tại nhà. Hãy đánh giá để giúp chúng tôi cải thiện!',
      'time': '2 giờ trước',
      'read': false,
    },
    {
      'icon': Icons.local_offer_outlined,
      'color': AppColors.brand500,
      'title': 'Khuyến mãi đặc biệt!',
      'subtitle': 'Giảm 20% khi đặt gói tháng. Dùng mã GIAM20. Hết hạn 30/09/2026.',
      'time': 'Hôm qua',
      'read': false,
    },
    {
      'icon': Icons.assignment_turned_in_outlined,
      'color': AppColors.info,
      'title': 'Dịch vụ hoàn thành',
      'subtitle': 'Người làm Trần Thị Mai đã hoàn thành Tổng vệ sinh vào 25/09.',
      'time': '2 ngày trước',
      'read': true,
    },
    {
      'icon': Icons.payment_outlined,
      'color': AppColors.success,
      'title': 'Xác nhận thanh toán',
      'subtitle': 'Thanh toán 500.000đ cho đơn Tổng vệ sinh đã được xác nhận.',
      'time': '3 ngày trước',
      'read': true,
    },
    {
      'icon': Icons.campaign_outlined,
      'color': AppColors.textSecondary,
      'title': 'Cập nhật ứng dụng',
      'subtitle': 'Neatify đã cập nhật thêm tính năng theo dõi người làm theo thời gian thực.',
      'time': '1 tuần trước',
      'read': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final unread = _notifications.where((n) => !(n['read'] as bool)).length;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Thông báo'),
        automaticallyImplyLeading: Navigator.canPop(context),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: () {
                setState(() {
                  for (var n in _notifications) {
                    n['read'] = true;
                  }
                });
              },
              child: const Text(
                'Đọc tất cả',
                style: TextStyle(
                  color: AppColors.brand500,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.only(bottom: 20),
        itemCount: _notifications.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
        itemBuilder: (context, index) {
          final n = _notifications[index];
          final bool isRead = n['read'] as bool;
          final Color c = n['color'] as Color;
          return InkWell(
            onTap: () => setState(() => n['read'] = true),
            child: Container(
              color: isRead ? Colors.white : AppColors.brandSurface,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: c.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(n['icon'] as IconData, color: c, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                n['title'] as String,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: isRead
                                      ? FontWeight.w600
                                      : FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (!isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.brand500,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          n['subtitle'] as String,
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          n['time'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
