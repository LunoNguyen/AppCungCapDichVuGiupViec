import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../widgets/shared_widgets.dart';

class CollaboratorOrdersScreen extends StatefulWidget {
  const CollaboratorOrdersScreen({super.key});

  @override
  State<CollaboratorOrdersScreen> createState() =>
      _CollaboratorOrdersScreenState();
}

class _CollaboratorOrdersScreenState extends State<CollaboratorOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> _orders = [
    {
      'service': 'Dọn dẹp nhà cơ bản',
      'customer': 'Nguyễn Thị B',
      'phone': '0901 111 222',
      'date': 'Thứ Hai, 28/09/2026',
      'time': '08:00 – 10:00',
      'address': '123 Nguyễn Trãi, Q.1, TP.HCM',
      'price': '300.000đ',
      'status': 'new',
      'note': 'Dọn phòng khách và phòng ngủ chính. Ưu tiên vệ sinh cửa kính.',
    },
    {
      'service': 'Giặt ủi quần áo',
      'customer': 'Trần Văn C',
      'phone': '0902 333 444',
      'date': 'Thứ Ba, 29/09/2026',
      'time': '09:00 – 11:00',
      'address': '456 Lê Văn Sỹ, Q.3, TP.HCM',
      'price': '150.000đ',
      'status': 'confirmed',
      'note': '',
    },
    {
      'service': 'Nấu ăn tại nhà',
      'customer': 'Lê Thị D',
      'phone': '0903 555 666',
      'date': 'Thứ Tư, 24/09/2026',
      'time': '10:00 – 13:00',
      'address': '789 Đinh Tiên Hoàng, Q.BT, TP.HCM',
      'price': '200.000đ',
      'status': 'completed',
      'note': 'Nấu 4 món cơm gia đình. Có trẻ nhỏ.',
    },
    {
      'service': 'Dọn dẹp tổng thể',
      'customer': 'Phạm Văn E',
      'phone': '0904 777 888',
      'date': 'Thứ Năm, 25/09/2026',
      'time': '08:00 – 12:00',
      'address': '321 Pasteur, Q.1, TP.HCM',
      'price': '500.000đ',
      'status': 'completed',
      'note': '',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Đơn của tôi'),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: AppColors.white,
          indicatorWeight: 3,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'Mới'),
            Tab(text: 'Đã xác nhận'),
            Tab(text: 'Hoàn thành'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrderList('new'),
          _buildOrderList('confirmed'),
          _buildOrderList('completed'),
        ],
      ),
    );
  }

  Widget _buildOrderList(String status) {
    final filtered = _orders.where((o) => o['status'] == status).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 60, color: AppColors.brand300),
            const SizedBox(height: 12),
            const Text(
              'Chưa có đơn nào',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 12, bottom: 20),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final o = filtered[index];
        return _buildOrderCard(o);
      },
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> o) {
    return GestureDetector(
      onTap: () => _showOrderDetail(o),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: o['status'] == 'new'
                    ? AppColors.brand300.withOpacity(0.1)
                    : AppColors.white,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.brand500.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.cleaning_services,
                        color: AppColors.brand500, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          o['service'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'KH: ${o['customer']}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  if (o['status'] == 'new')
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.brand500,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Mới',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _infoRow(Icons.calendar_today, o['date'] as String),
                  const SizedBox(height: 6),
                  _infoRow(Icons.access_time, o['time'] as String),
                  const SizedBox(height: 6),
                  _infoRow(Icons.location_on_outlined, o['address'] as String),
                  const SizedBox(height: 12),
                  if (o['status'] == 'new') ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _confirmAction(o, 'reject'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Từ chối'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _confirmAction(o, 'accept'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.brand500,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Nhận đơn'),
                          ),
                        ),
                      ],
                    ),
                  ] else if (o['status'] == 'confirmed') ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _markComplete(o),
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Đánh dấu hoàn thành'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: AppColors.success, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Hoàn thành • ${o['price']}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _confirmAction(Map<String, dynamic> o, String action) {
    final isAccept = action == 'accept';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isAccept ? 'Nhận đơn?' : 'Từ chối đơn?'),
        content: Text(isAccept
            ? 'Bạn xác nhận nhận đơn dịch vụ "${o['service']}"?'
            : 'Vui lòng cho biết lý do từ chối đơn này.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                o['status'] = isAccept ? 'confirmed' : 'rejected';
              });
              _tabController.animateTo(isAccept ? 1 : 0);
            },
            child: Text(
              isAccept ? 'Xác nhận' : 'Từ chối',
              style: TextStyle(
                  color: isAccept ? AppColors.brand500 : AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _markComplete(Map<String, dynamic> o) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hoàn thành dịch vụ'),
        content: const Text('Xác nhận bạn đã hoàn thành dịch vụ này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => o['status'] = 'completed');
              _tabController.animateTo(2);
            },
            child: const Text('Hoàn thành',
                style: TextStyle(color: AppColors.success)),
          ),
        ],
      ),
    );
  }

  void _showOrderDetail(Map<String, dynamic> o) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, ctrl) => SingleChildScrollView(
          controller: ctrl,
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
              const Text(
                'Chi tiết đơn',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              _detailRow(Icons.home_repair_service, 'Dịch vụ', o['service']),
              _detailRow(Icons.person_outline, 'Khách hàng', o['customer']),
              _detailRow(Icons.phone_outlined, 'Điện thoại', o['phone']),
              _detailRow(Icons.calendar_today, 'Ngày', o['date']),
              _detailRow(Icons.access_time, 'Giờ', o['time']),
              _detailRow(Icons.location_on_outlined, 'Địa chỉ', o['address']),
              _detailRow(Icons.attach_money, 'Thu nhập', o['price']),
              if ((o['note'] as String).isNotEmpty)
                _detailRow(Icons.notes, 'Ghi chú', o['note']),
            ],
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
                Text(label,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
