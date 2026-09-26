import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../widgets/shared_widgets.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> _bookings = [
    {
      'service': 'Dọn dẹp nhà cơ bản',
      'collaborator': 'Nguyễn Thị Lan',
      'date': 'Thứ Hai, 28/09/2026',
      'time': '08:00 – 10:00',
      'address': '123 Nguyễn Trãi, Q.1, TP.HCM',
      'price': '300.000đ',
      'status': 'pending',
    },
    {
      'service': 'Dọn dẹp tổng thể',
      'collaborator': 'Trần Thị Mai',
      'date': 'Thứ Sáu, 25/09/2026',
      'time': '09:00 – 13:00',
      'address': '456 Lê Văn Sỹ, Q.3, TP.HCM',
      'price': '500.000đ',
      'status': 'confirmed',
    },
    {
      'service': 'Nấu ăn tại nhà',
      'collaborator': 'Lê Thị Hoa',
      'date': 'Thứ Tư, 24/09/2026',
      'time': '10:00 – 13:00',
      'address': '789 Đinh Tiên Hoàng, Q.BT, TP.HCM',
      'price': '200.000đ',
      'status': 'completed',
    },
    {
      'service': 'Giặt ủi quần áo',
      'collaborator': 'Phạm Thị Bình',
      'date': 'Thứ Ba, 20/09/2026',
      'time': '08:00 – 09:00',
      'address': '321 Pasteur, Q.1, TP.HCM',
      'price': '150.000đ',
      'status': 'completed',
    },
    {
      'service': 'Trông trẻ',
      'collaborator': 'Hoàng Thị Linh',
      'date': 'Chủ Nhật, 14/09/2026',
      'time': '14:00 – 18:00',
      'address': '99 Võ Thị Sáu, Q.1, TP.HCM',
      'price': '320.000đ',
      'status': 'cancelled',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Lịch sử đặt dịch vụ'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: AppColors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'Tất cả'),
            Tab(text: 'Chờ xác nhận'),
            Tab(text: 'Đã xác nhận'),
            Tab(text: 'Hoàn thành'),
            Tab(text: 'Đã hủy'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBookingList(null),
          _buildBookingList('pending'),
          _buildBookingList('confirmed'),
          _buildBookingList('completed'),
          _buildBookingList('cancelled'),
        ],
      ),
    );
  }

  Widget _buildBookingList(String? filterStatus) {
    final filtered = filterStatus == null
        ? _bookings
        : _bookings.where((b) => b['status'] == filterStatus).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 60, color: AppColors.brand300),
            const SizedBox(height: 12),
            const Text(
              'Chưa có đơn nào',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Đặt dịch vụ ngay để trải nghiệm!',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Đặt dịch vụ'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 12, bottom: 20),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final b = filtered[index];
        return BookingListItem(
          serviceName: b['service'],
          collaboratorName: b['collaborator'],
          dateTime: '${b['date']} • ${b['time']}',
          address: b['address'],
          price: b['price'],
          statusChip: _statusChip(b['status']),
          onTap: () => _showBookingDetail(context, b),
        );
      },
    );
  }

  Widget _statusChip(String status) {
    switch (status) {
      case 'pending':
        return StatusChip.pending();
      case 'confirmed':
        return StatusChip.confirmed();
      case 'inProgress':
        return StatusChip.inProgress();
      case 'completed':
        return StatusChip.completed();
      case 'cancelled':
        return StatusChip.cancelled();
      default:
        return const StatusChip(label: 'Không xác định', color: Colors.grey, bg: Color(0xFFF5F5F5));
    }
  }

  void _showBookingDetail(BuildContext context, Map<String, dynamic> b) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, ctrl) => SingleChildScrollView(
          controller: ctrl,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Chi tiết đơn dịch vụ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    _statusChip(b['status']),
                  ],
                ),
                const SizedBox(height: 20),
                _detailRow(Icons.home_repair_service, 'Dịch vụ', b['service']),
                _detailRow(Icons.person_outline, 'Cộng tác viên', b['collaborator']),
                _detailRow(Icons.calendar_today, 'Ngày', b['date']),
                _detailRow(Icons.access_time, 'Thời gian', b['time']),
                _detailRow(Icons.location_on_outlined, 'Địa điểm', b['address']),
                _detailRow(Icons.attach_money, 'Chi phí', b['price']),
                const SizedBox(height: 20),
                if (b['status'] == 'completed') ...[
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.star_outline),
                    label: const Text('Đánh giá dịch vụ'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.report_outlined, color: AppColors.error),
                    label: const Text(
                      'Gửi khiếu nại',
                      style: TextStyle(color: AppColors.error),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
                if (b['status'] == 'pending')
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.cancel_outlined, color: AppColors.error),
                    label: const Text(
                      'Hủy đơn',
                      style: TextStyle(color: AppColors.error),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.brand500),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
