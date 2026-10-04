import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import '../auth/login_screen.dart';
import '../../services/session_service.dart';
import '../../services/booking_api_service.dart';
import 'order_detail_screen.dart';

class BookingHistoryScreen extends StatefulWidget {
  final ValueChanged<int>? onSwitchTab;
  const BookingHistoryScreen({super.key, this.onSwitchTab});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _bookingApi = BookingApiService();
  final _currencyFormat = NumberFormat('#,###', 'vi_VN');

  bool _loggedIn = false;
  bool _loading = false;
  int? _khachHangId;

  List<Map<String, dynamic>> _pendingOrders = [];
  List<Map<String, dynamic>> _historyOrders = [];
  List<Map<String, dynamic>> _recurringOrders = [];
  List<Map<String, dynamic>> _packageOrders = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkSessionAndLoad();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkSessionAndLoad() async {
    final session = await SessionService.load();
    if (!mounted) return;

    final isCust = session?.isCustomer == true;
    setState(() {
      _loggedIn = isCust;
      _khachHangId = session?.userId;
    });

    if (isCust && _khachHangId != null && _khachHangId! > 0) {
      await _loadBookings();
    }
  }

  Future<void> _loadBookings() async {
    if (_khachHangId == null || _khachHangId! <= 0) return;

    setState(() => _loading = true);
    try {
      final res = await _bookingApi.getCustomerBookings(khachHangId: _khachHangId!);
      if (mounted) {
        if (res.success && res.data != null) {
          final list = res.data!;
          setState(() {
            _pendingOrders = list.where((o) {
              final st = o['trangThai']?.toString();
              return st != 'HoanThanh' && st != 'DaHuy';
            }).toList();

            _historyOrders = list.where((o) {
              final st = o['trangThai']?.toString();
              return st == 'HoanThanh' || st == 'DaHuy';
            }).toList();

            _recurringOrders = list.where((o) {
              final lh = o['loaiHinhDat']?.toString();
              return lh == 'DinhKy' || lh == 'LapLai';
            }).toList();

            _packageOrders = list.where((o) {
              final lh = o['loaiHinhDat']?.toString();
              return lh == 'GoiThang';
            }).toList();

            _loading = false;
          });
        } else {
          setState(() => _loading = false);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return '0 đ';
    final numVal = num.tryParse(value.toString()) ?? 0;
    return '${_currencyFormat.format(numVal)} đ';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr);
      final weekdays = [
        '',
        'Thứ Hai',
        'Thứ Ba',
        'Thứ Tư',
        'Thứ Năm',
        'Thứ Sáu',
        'Thứ Bảy',
        'Chủ Nhật'
      ];
      final dayName = weekdays[dt.weekday];
      return '$dayName, ${DateFormat('dd/MM/yyyy').format(dt)}';
    } catch (_) {
      return dateStr;
    }
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '';
    final parts = timeStr.split(':');
    if (parts.length >= 2) {
      return '${parts[0]}:${parts[1]}';
    }
    return timeStr;
  }

  Map<String, dynamic> _getStatusBadge(String? status) {
    switch (status) {
      case 'ChoDuyet':
      case 'DangTimCTV':
        return {
          'text': 'Đang tìm CTV',
          'color': const Color(0xFFE65100),
          'bgColor': const Color(0xFFFFF3E0),
        };
      case 'DaXacNhan':
      case 'DaPhanCong':
        return {
          'text': 'Đã phân công',
          'color': const Color(0xFF1565C0),
          'bgColor': const Color(0xFFE3F2FD),
        };
      case 'DangThucHien':
        return {
          'text': 'Đang thực hiện',
          'color': const Color(0xFF2E7D32),
          'bgColor': const Color(0xFFE8F5E9),
        };
      case 'HoanThanh':
        return {
          'text': 'Hoàn thành',
          'color': AppColors.brand700,
          'bgColor': AppColors.brandSurface,
        };
      case 'DaHuy':
        return {
          'text': 'Đã hủy',
          'color': const Color(0xFFC62828),
          'bgColor': const Color(0xFFFFEBEE),
        };
      default:
        return {
          'text': status ?? 'Đang xử lý',
          'color': AppColors.textSecondary,
          'bgColor': const Color(0xFFEEEEEE),
        };
    }
  }

  void _openHistoryScreen() {
    if (!_loggedIn) {
      _promptLogin(context);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Lịch sử đơn hoàn thành',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            centerTitle: true,
          ),
          body: _historyOrders.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history_rounded, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 14),
                        const Text(
                          'Chưa có đơn nào hoàn thành',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Các đơn dịch vụ bạn đã hoàn thành sẽ xuất hiện tại đây.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  itemCount: _historyOrders.length,
                  itemBuilder: (ctx, i) => _buildOrderCard(_historyOrders[i]),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Hoạt động',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _openHistoryScreen,
            icon: const Icon(Icons.history_rounded, color: AppColors.brand500, size: 18),
            label: const Text(
              'Lịch sử',
              style: TextStyle(
                color: AppColors.brand500,
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.brand500,
          indicatorWeight: 2.5,
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: AppColors.brand500,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14.5,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14.5,
          ),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Chờ làm'),
                  if (_pendingOrders.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: const BoxDecoration(
                        color: AppColors.brand500,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${_pendingOrders.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Lặp lại'),
            const Tab(text: 'Gói tháng'),
          ],
        ),
      ),
      body: !_loggedIn
          ? TabBarView(
              controller: _tabController,
              children: [
                _buildEmptyGuestView(context),
                _buildEmptyGuestView(context),
                _buildEmptyGuestView(context),
              ],
            )
          : _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.brand500))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOrderListView(_pendingOrders, 'Bạn chưa có công việc nào đang chờ làm.'),
                    _buildOrderListView(_recurringOrders, 'Bạn chưa có công việc nào lặp lại định kỳ.'),
                    _buildOrderListView(_packageOrders, 'Bạn chưa có gói dịch vụ tháng nào.'),
                  ],
                ),
    );
  }

  Widget _buildOrderListView(List<Map<String, dynamic>> orders, String emptyMsg) {
    return RefreshIndicator(
      onRefresh: _loadBookings,
      color: AppColors.brand500,
      child: orders.isEmpty
          ? SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.65,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildActivityIllustration(),
                        const SizedBox(height: 24),
                        Text(
                          emptyMsg,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: 160,
                          height: 44,
                          child: ElevatedButton(
                            onPressed: () => widget.onSwitchTab?.call(0),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.brand500,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Đặt dịch vụ', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: orders.length,
              itemBuilder: (ctx, i) => _buildOrderCard(orders[i]),
            ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['trangThai']?.toString();
    final badge = _getStatusBadge(status);
    final ctvTen = order['congTacVienTen']?.toString();
    final ctvDiem = order['congTacVienDiem'];
    final tenDichVu = order['tenDichVu']?.toString() ?? 'Dịch vụ giúp việc';
    final ngayThucHien = order['ngayThucHien']?.toString();
    final gioBatDau = order['gioBatDau']?.toString();
    final gioKetThuc = order['gioKetThuc']?.toString();
    final thanhTien = order['thanhTien'];
    final diaChi = order['diaChi']?.toString() ?? '';
    final orderId = order['id'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9ECEF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OrderDetailScreen(
                  orderId: orderId,
                  onOrderUpdated: _loadBookings,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Mã đơn + Trạng thái
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.brandLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.cleaning_services_rounded, color: AppColors.brand500, size: 16),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${order['maDonDat'] ?? ''}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: badge['bgColor'] as Color,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge['text'] as String,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: badge['color'] as Color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Tên dịch vụ
                Text(
                  tenDichVu.isNotEmpty ? tenDichVu : 'Dịch vụ giúp việc',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                // Ngày & Giờ làm việc
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 15, color: AppColors.brand500),
                    const SizedBox(width: 6),
                    Text(
                      '${_formatTime(gioBatDau)} - ${_formatTime(gioKetThuc)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.brand600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(width: 3, height: 3, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _formatDate(ngayThucHien),
                        style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // Địa chỉ nếu có
                if (diaChi.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 15, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          diaChi,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1, color: AppColors.divider),
                ),

                // Footer: CTV & Giá tiền
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Thông tin CTV
                    if (ctvTen != null && ctvTen.isNotEmpty)
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 12,
                            backgroundColor: AppColors.brandLight,
                            child: Icon(Icons.person, size: 14, color: AppColors.brand500),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            ctvTen,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (ctvDiem != null) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.star_rounded, size: 14, color: AppColors.star),
                            Text(
                              ' $ctvDiem',
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ],
                      )
                    else if (status == 'ChoDuyet' || status == 'DangTimCTV')
                      const Row(
                        children: [
                          Icon(Icons.person_search_rounded, size: 16, color: Color(0xFFE65100)),
                          SizedBox(width: 5),
                          Text(
                            'Đang tìm người làm...',
                            style: TextStyle(fontSize: 12, color: Color(0xFFE65100), fontWeight: FontWeight.w500),
                          ),
                        ],
                      )
                    else
                      const Row(
                        children: [
                          Icon(Icons.person_outline_rounded, size: 16, color: AppColors.textMuted),
                          SizedBox(width: 5),
                          Text(
                            'Chưa gán CTV',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),

                    // Giá tiền
                    Row(
                      children: [
                        Text(
                          _formatCurrency(thanhTien),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.brand600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyGuestView(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          _buildActivityIllustration(),
          const SizedBox(height: 32),
          const Text(
            'Công việc bạn đăng lên sẽ được hiển thị ở đây để bạn dễ dàng thao tác và quản lý. Bạn có thể xem lại lịch sử những công việc đã được hoàn thành ở mục Lịch sử nằm ở góc trên bên phải.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              color: AppColors.textSecondary,
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: 170,
            height: 46,
            child: ElevatedButton(
              onPressed: () {
                if (_loggedIn) {
                  widget.onSwitchTab?.call(0);
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ).then((_) => _checkSessionAndLoad());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brand500,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                _loggedIn ? 'Đặt dịch vụ' : 'Đăng nhập ngay',
                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildActivityIllustration() {
    return SizedBox(
      width: 250,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: 25,
            top: 30,
            child: Container(
              width: 150,
              height: 130,
              decoration: BoxDecoration(
                color: AppColors.brandSurface,
                borderRadius: BorderRadius.circular(50),
              ),
            ),
          ),
          Positioned(
            left: 20,
            bottom: 60,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFFED7AA),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 40,
            top: 45,
            child: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Color(0xFFFDBA74),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: 35,
            top: 10,
            bottom: 10,
            child: Container(
              width: 105,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.brand500, width: 3.2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brand500.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 24,
                    height: 3,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDBA74),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppColors.brandSurface,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      color: AppColors.brand500,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      5,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFDBA74),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFED7AA),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFED7AA),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFED7AA),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 42,
            bottom: 24,
            child: SizedBox(
              width: 80,
              height: 90,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    bottom: 0,
                    child: Container(
                      width: 48,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E293B),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    child: Container(
                      width: 16,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.brand500,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0F172A),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 24,
                          height: 22,
                          margin: const EdgeInsets.only(top: 8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFED7AA),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _promptLogin(BuildContext context) {
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
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: AppColors.brandLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history_rounded,
                color: AppColors.brand500,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Lịch sử hoạt động',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vui lòng đăng nhập để xem lại các công việc và dịch vụ đã hoàn thành.',
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
                  ).then((_) => _checkSessionAndLoad());
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
}
