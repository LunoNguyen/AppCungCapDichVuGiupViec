import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../widgets/shared_widgets.dart';

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
      'subtitle': 'Đơn Dọn dẹp nhà cơ bản ngày 28/09 đã được xác nhận. CTV: Nguyễn Thị Lan.',
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
      'color': Color(0xFFFF5722),
      'title': 'Khuyến mãi đặc biệt!',
      'subtitle': 'Giảm 20% khi đặt gói tháng. Dùng mã GIAM20. Hết hạn 30/09/2026.',
      'time': 'Hôm qua',
      'read': false,
    },
    {
      'icon': Icons.assignment_turned_in_outlined,
      'color': AppColors.brand500,
      'title': 'Dịch vụ hoàn thành',
      'subtitle': 'Cộng tác viên Trần Thị Mai đã hoàn thành Dọn dẹp tổng thể vào 25/09.',
      'time': '2 ngày trước',
      'read': true,
    },
    {
      'icon': Icons.payment_outlined,
      'color': AppColors.brand600,
      'title': 'Xác nhận thanh toán',
      'subtitle': 'Thanh toán 500.000đ cho đơn Dọn dẹp tổng thể đã được xác nhận.',
      'time': '3 ngày trước',
      'read': true,
    },
    {
      'icon': Icons.info_outline,
      'color': AppColors.textSecondary,
      'title': 'Cập nhật ứng dụng',
      'subtitle': 'GiupViec đã cập nhật thêm tính năng theo dõi CTV theo thời gian thực.',
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
        automaticallyImplyLeading: false,
        actions: [
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
              style: TextStyle(color: AppColors.white, fontSize: 13),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (unread > 0)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.brand300.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.brand300.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active, color: AppColors.brand500, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Bạn có $unread thông báo chưa đọc',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.brand600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 20),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final n = _notifications[index];
                return GestureDetector(
                  onTap: () {
                    setState(() => n['read'] = true);
                  },
                  child: NotificationItem(
                    icon: n['icon'] as IconData,
                    iconColor: n['color'] as Color,
                    title: n['title'] as String,
                    subtitle: n['subtitle'] as String,
                    time: n['time'] as String,
                    isRead: n['read'] as bool,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
