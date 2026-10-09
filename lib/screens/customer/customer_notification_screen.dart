import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_colors.dart';
import '../../services/notification_api_service.dart';
import '../../services/session_service.dart';
import '../auth/login_screen.dart';

class CustomerNotificationScreen extends StatefulWidget {
  const CustomerNotificationScreen({super.key});

  @override
  State<CustomerNotificationScreen> createState() =>
      _CustomerNotificationScreenState();
}

class _CustomerNotificationScreenState
    extends State<CustomerNotificationScreen> {
  final NotificationApiService _apiService = NotificationApiService();
  bool _isLoading = true;
  bool _isLoggedIn = false;
  int _currentTaiKhoanId = 0;
  bool _onlyUnread = false;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final session = await SessionService.load();
    if (session != null && session.taiKhoanId > 0) {
      if (mounted) {
        setState(() {
          _isLoggedIn = true;
          _currentTaiKhoanId = session.taiKhoanId;
        });
      }
      await _fetchNotifications();
    } else {
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchNotifications() async {
    if (_currentTaiKhoanId <= 0) return;
    setState(() => _isLoading = true);
    try {
      final response =
          await _apiService.getCustomerNotifications(_currentTaiKhoanId);
      if (response.success && response.data != null) {
        final List<Map<String, dynamic>> loaded = [];
        for (final raw in response.data!) {
          DateTime thoiGian = DateTime.now();
          if (raw['thoiGianGui'] != null) {
            thoiGian = DateTime.tryParse(raw['thoiGianGui'].toString()) ??
                DateTime.now();
          }
          loaded.add({
            'id': raw['id'],
            'thongBaoId': raw['thongBaoId'],
            'loai': raw['loai']?.toString() ?? 'heThong',
            'tieuDe': raw['tieuDe']?.toString() ?? '',
            'noiDung': raw['noiDung']?.toString() ?? '',
            'nguoiGui': raw['nguoiGui']?.toString() ?? 'Hệ thống bTaskee',
            'thoiGian': thoiGian,
            'daDoc': raw['daDoc'] == true,
          });
        }
        if (mounted) {
          setState(() {
            _items = loaded;
          });
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  List<Map<String, dynamic>> get _visibleItems => _onlyUnread
      ? _items.where((e) => e['daDoc'] == false).toList()
      : _items;

  int get _unreadCount => _items.where((e) => e['daDoc'] == false).length;

  Future<void> _markAllRead() async {
    if (_unreadCount == 0) return;
    setState(() {
      for (final e in _items) {
        e['daDoc'] = true;
      }
    });
    try {
      await _apiService.markAllCustomerNotificationsRead(_currentTaiKhoanId);
    } catch (_) {}
  }

  Future<void> _markRead(Map<String, dynamic> item) async {
    if (item['daDoc'] == true) return;
    setState(() => item['daDoc'] = true);
    final id = item['id'];
    if (id is int) {
      try {
        await _apiService.markCustomerNotificationRead(
          id: id,
          taiKhoanId: _currentTaiKhoanId,
        );
      } catch (_) {}
    }
  }

  // Phân loại kiểu thông báo (màu sắc, icon, nhãn)
  _TypeStyle _typeStyle(String loai, String tieuDe) {
    switch (loai) {
      case 'khuyenMai':
        return _TypeStyle(
          icon: Icons.local_offer_rounded,
          color: AppColors.brand500,
          bg: AppColors.brandSurface,
          label: 'Khuyến mãi',
        );
      case 'hoanThanh':
        return _TypeStyle(
          icon: Icons.task_alt_rounded,
          color: const Color(0xFF16A34A),
          bg: const Color(0xFFF0FDF4),
          label: 'Hoàn thành',
        );
      case 'tiepNhan':
      case 'donHang':
        return _TypeStyle(
          icon: Icons.person_pin_circle_rounded,
          color: const Color(0xFF2563EB),
          bg: const Color(0xFFEFF6FF),
          label: 'Đơn hàng',
        );
      case 'nhacLich':
        return _TypeStyle(
          icon: Icons.alarm_rounded,
          color: const Color(0xFF7C3AED),
          bg: const Color(0xFFF5F3FF),
          label: 'Lịch hẹn',
        );
      default:
        return _TypeStyle(
          icon: Icons.campaign_rounded,
          color: const Color(0xFF475569),
          bg: const Color(0xFFF1F5F9),
          label: 'Thông báo',
        );
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays == 1) return 'Hôm qua lúc ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return '${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}/${time.year}';
  }

  void _showNotificationDetail(Map<String, dynamic> n) {
    _markRead(n);
    final String tieuDe = n['tieuDe']?.toString() ?? '';
    final String noiDung = n['noiDung']?.toString() ?? '';
    final String nguoiGui = n['nguoiGui']?.toString() ?? 'Hệ thống bTaskee';
    final style = _typeStyle(n['loai']?.toString() ?? '', tieuDe);
    final DateTime thoiGian = n['thoiGian'] as DateTime? ?? DateTime.now();
    final String formattedFullTime =
        '${thoiGian.hour.toString().padLeft(2, '0')}:${thoiGian.minute.toString().padLeft(2, '0')} • ${thoiGian.day.toString().padLeft(2, '0')}/${thoiGian.month.toString().padLeft(2, '0')}/${thoiGian.year}';

    // Parse mã đơn hoặc mã khuyến mãi
    final fullText = '$tieuDe $noiDung';
    final orderMatch =
        RegExp(r'(DON-[A-Za-z0-9\-]+)').firstMatch(fullText);
    final String? orderCode = orderMatch?.group(0);

    final couponMatch =
        RegExp(r'(mã ưu đãi|mã giảm giá|mã|mã coupon)\s+([A-Za-z0-9\-]+)', caseSensitive: false)
            .firstMatch(fullText);
    final String? couponCode = couponMatch != null && couponMatch.groupCount >= 2
        ? couponMatch.group(2)
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
              20, 14, 20, MediaQuery.of(ctx).padding.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: style.bg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(style.icon, color: style.color, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: style.bg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            style.label,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: style.color,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formattedFullTime,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                tieuDe,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.send_rounded,
                      size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 5),
                  Text(
                    'Người gửi: $nguoiGui',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: SelectableText(
                  noiDung,
                  style: const TextStyle(
                    fontSize: 14.5,
                    color: AppColors.textSecondary,
                    height: 1.55,
                  ),
                ),
              ),
              if (orderCode != null || couponCode != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.brandSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.brand500.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        couponCode != null
                            ? Icons.confirmation_number_rounded
                            : Icons.receipt_long_rounded,
                        color: AppColors.brand500,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          couponCode != null
                              ? 'Mã ưu đãi: $couponCode'
                              : 'Mã đơn: $orderCode',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          final code = couponCode ?? orderCode!;
                          Clipboard.setData(ClipboardData(text: code));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Đã sao chép: $code'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text('Sao chép'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.brand500,
                          textStyle: const TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brand500,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Đã hiểu',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      return Scaffold(
        backgroundColor: AppColors.scaffoldBg,
        appBar: AppBar(
          title: const Text('Thông báo'),
          automaticallyImplyLeading: Navigator.canPop(context),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: AppColors.brandSurface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_off_outlined,
                    size: 40,
                    color: AppColors.brand500,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Bạn chưa đăng nhập',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Đăng nhập để nhận thông báo về tiến độ đơn hàng, mã giảm giá và ưu đãi mới nhất từ bTaskee.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                    _init();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brand500,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Đăng nhập ngay',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Thông báo'),
        automaticallyImplyLeading: Navigator.canPop(context),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text(
                'Đọc tất cả',
                style: TextStyle(
                  color: AppColors.brand500,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                _filterChip(
                  label: 'Tất cả (${_items.length})',
                  selected: !_onlyUnread,
                  onTap: () => setState(() => _onlyUnread = false),
                ),
                const SizedBox(width: 8),
                _filterChip(
                  label: 'Chưa đọc ($_unreadCount)',
                  selected: _onlyUnread,
                  onTap: () => setState(() => _onlyUnread = true),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.brand500),
              ),
            )
          : RefreshIndicator(
              color: AppColors.brand500,
              onRefresh: _fetchNotifications,
              child: _visibleItems.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _onlyUnread
                                      ? Icons.done_all_rounded
                                      : Icons.notifications_none_rounded,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  _onlyUnread
                                      ? 'Không có thông báo chưa đọc'
                                      : 'Chưa có thông báo nào',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _onlyUnread
                                      ? 'Bạn đã đọc hết tất cả các thông báo.'
                                      : 'Các thông báo mới về đơn hàng và ưu đãi sẽ xuất hiện ở đây.',
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: _visibleItems.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 72),
                      itemBuilder: (context, index) {
                        final n = _visibleItems[index];
                        final bool isRead = n['daDoc'] as bool;
                        final style = _typeStyle(
                            n['loai']?.toString() ?? '', n['tieuDe']?.toString() ?? '');
                        final DateTime time =
                            n['thoiGian'] as DateTime? ?? DateTime.now();

                        return InkWell(
                          onTap: () => _showNotificationDetail(n),
                          child: Container(
                            color: isRead
                                ? Colors.white
                                : AppColors.brandSurface.withValues(alpha: 0.5),
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: style.bg,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(style.icon,
                                      color: style.color, size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              n['tieuDe'] as String,
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
                                              margin: const EdgeInsets.only(
                                                  left: 6),
                                              decoration: const BoxDecoration(
                                                color: AppColors.brand500,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        n['noiDung'] as String,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          color: AppColors.textSecondary,
                                          height: 1.35,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Text(
                                            _formatTime(time),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            width: 3,
                                            height: 3,
                                            decoration: const BoxDecoration(
                                              color: AppColors.textMuted,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            n['nguoiGui'] as String? ?? 'Hệ thống',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ],
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
            ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.brand500 : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _TypeStyle {
  final IconData icon;
  final Color color;
  final Color bg;
  final String label;

  _TypeStyle({
    required this.icon,
    required this.color,
    required this.bg,
    required this.label,
  });
}
