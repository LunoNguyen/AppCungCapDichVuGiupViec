import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_colors.dart';

class CollaboratorNotificationsScreen extends StatefulWidget {
  const CollaboratorNotificationsScreen({super.key});

  @override
  State<CollaboratorNotificationsScreen> createState() =>
      _CollaboratorNotificationsScreenState();
}

class _CollaboratorNotificationsScreenState
    extends State<CollaboratorNotificationsScreen> {
  bool _isLoading = true;
  bool _notifEnabled = true;
  bool _onlyUnread = false;
  List<Map<String, dynamic>> _items = [];

  // Màu đồng bộ với các trang khác
  static const _headerTop = Color(0xFF3F4A8A);
  static const _headerBottom = Color(0xFF5B62B3);
  static const _coral = Color(0xFFE8646A);
  static const _ink = Color(0xFF1F2544);

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _notifEnabled = prefs.getBool('notifEnabled') ?? true;
    await _fetchNotifications();
  }

  // ===================== DỮ LIỆU =====================

  // TODO: sau này thay bằng gọi API backend.
  // Mỗi item cần: id, loai (donMoi | nhacLich | hoanThanh | huy | heThong),
  // tieuDe, noiDung, thoiGian (DateTime), daDoc (bool)
  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 400));
    final now = DateTime.now();
    _items = [
      {
        'id': 1,
        'loai': 'donMoi',
        'tieuDe': 'Bạn có đơn mới',
        'noiDung':
        'Dọn dẹp nhà cửa • 123 Lê Lợi, Quận 1 • 09:00 - 12:00. Nhận đơn ngay!',
        'thoiGian': now.subtract(const Duration(minutes: 5)),
        'daDoc': false,
      },
      {
        'id': 2,
        'loai': 'nhacLich',
        'tieuDe': 'Sắp đến giờ làm việc',
        'noiDung': 'Ca của bạn với khách Nguyễn Văn A bắt đầu lúc 09:00 ngày mai.',
        'thoiGian': now.subtract(const Duration(hours: 2)),
        'daDoc': false,
      },
      {
        'id': 3,
        'loai': 'hoanThanh',
        'tieuDe': 'Đơn đã hoàn thành',
        'noiDung': 'Bạn nhận được 216.000đ từ đơn DON-2026-004.',
        'thoiGian': now.subtract(const Duration(days: 1, hours: 3)),
        'daDoc': true,
      },
      {
        'id': 4,
        'loai': 'huy',
        'tieuDe': 'Đơn bị hủy',
        'noiDung': 'Khách đã hủy đơn DON-2026-002. Rất tiếc về sự bất tiện này.',
        'thoiGian': now.subtract(const Duration(days: 2)),
        'daDoc': true,
      },
      {
        'id': 5,
        'loai': 'heThong',
        'tieuDe': 'Chào mừng đến Neatify',
        'noiDung': 'Hoàn thiện hồ sơ để nhận được nhiều đơn hơn.',
        'thoiGian': now.subtract(const Duration(days: 5)),
        'daDoc': true,
      },
    ];
    if (mounted) setState(() => _isLoading = false);
  }

  List<Map<String, dynamic>> get _visibleItems =>
      _onlyUnread ? _items.where((e) => e['daDoc'] == false).toList() : _items;

  int get _unreadCount => _items.where((e) => e['daDoc'] == false).length;

  void _markAllRead() {
    // TODO: gọi API đánh dấu tất cả đã đọc
    setState(() {
      for (final e in _items) {
        e['daDoc'] = true;
      }
    });
  }

  void _markRead(Map<String, dynamic> item) {
    if (item['daDoc'] == true) return;
    // TODO: gọi API đánh dấu đã đọc
    setState(() => item['daDoc'] = true);
  }

  Future<void> _toggleNotif(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifEnabled', val);
    setState(() => _notifEnabled = val);
    // TODO: bật -> lấy FCM token gửi backend; tắt -> báo backend ngừng gửi
  }

  // ===================== GIAO DIỆN CHÍNH =====================

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBg,
        body: Column(
          children: [
            _buildHeader(),
            _buildSettingRow(),
            Expanded(
              child: _isLoading
                  ? const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.brand500))
                  : RefreshIndicator(
                onRefresh: _fetchNotifications,
                color: _headerTop,
                child: _buildList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 8, 16, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_headerTop, _headerBottom],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.maybePop(context),
              ),
              const Expanded(
                child: Text(
                  'Thông báo',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Đánh dấu tất cả đã đọc',
                icon: const Icon(Icons.done_all, color: Colors.white),
                onPressed: _unreadCount == 0 ? null : _markAllRead,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Segmented: Tất cả / Chưa đọc
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                _segment('TẤT CẢ', !_onlyUnread,
                        () => setState(() => _onlyUnread = false)),
                _segment('CHƯA ĐỌC${_unreadCount > 0 ? ' ($_unreadCount)' : ''}',
                    _onlyUnread, () => setState(() => _onlyUnread = true)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _segment(String text, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? _headerTop : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: selected ? Colors.white : _headerTop,
            ),
          ),
        ),
      ),
    );
  }

  // Dòng bật/tắt nhận thông báo
  Widget _buildSettingRow() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Icon(
            _notifEnabled
                ? Icons.notifications_active_outlined
                : Icons.notifications_off_outlined,
            color: _notifEnabled ? _headerTop : Colors.grey,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _notifEnabled ? 'Đang nhận thông báo' : 'Đã tắt thông báo',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 14, color: _ink),
            ),
          ),
          Switch(
            value: _notifEnabled,
            activeTrackColor: const Color(0xFF2E9E6B),
            onChanged: _toggleNotif,
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    final list = _visibleItems;

    if (list.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.15),
          const Icon(Icons.notifications_none,
              size: 60, color: AppColors.brand300),
          const SizedBox(height: 12),
          Center(
            child: Text(
              _onlyUnread ? 'Bạn đã đọc hết thông báo' : 'Chưa có thông báo nào',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 8, bottom: 20),
      itemCount: list.length,
      itemBuilder: (context, i) => _buildItem(list[i]),
    );
  }

  // ===================== THẺ THÔNG BÁO =====================

  Widget _buildItem(Map<String, dynamic> n) {
    final style = _typeStyle(n['loai']?.toString() ?? '');
    final bool unread = n['daDoc'] == false;

    return Dismissible(
      key: ValueKey(n['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.only(right: 24),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) {
        // TODO: gọi API xóa thông báo
        setState(() => _items.removeWhere((e) => e['id'] == n['id']));
      },
      child: GestureDetector(
        onTap: () => _markRead(n),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: unread ? const Color(0xFFF1F2FB) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: unread
                ? Border.all(color: _headerTop.withValues(alpha: 0.25))
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: style.color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(style.icon, color: style.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            n['tieuDe']?.toString() ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight:
                              unread ? FontWeight.w800 : FontWeight.w600,
                              color: _ink,
                            ),
                          ),
                        ),
                        if (unread)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 6),
                            decoration: const BoxDecoration(
                              color: _coral,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      n['noiDung']?.toString() ?? '',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.3,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _timeAgo(n['thoiGian'] as DateTime),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== HÀM HỖ TRỢ =====================

  _TypeStyle _typeStyle(String loai) {
    switch (loai) {
      case 'donMoi':
        return const _TypeStyle(Icons.assignment_outlined, Color(0xFFC77700));
      case 'nhacLich':
        return const _TypeStyle(Icons.access_time, Color(0xFF2F80ED));
      case 'hoanThanh':
        return const _TypeStyle(
            Icons.check_circle_outline, Color(0xFF2E9E6B));
      case 'huy':
        return const _TypeStyle(Icons.cancel_outlined, _coral);
      default:
        return const _TypeStyle(Icons.campaign_outlined, _headerTop);
    }
  }

  String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays == 1) return 'Hôm qua';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return '${t.day.toString().padLeft(2, '0')}/${t.month.toString().padLeft(2, '0')}/${t.year}';
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 12,
        offset: const Offset(0, 3),
      ),
    ],
  );
}

class _TypeStyle {
  final IconData icon;
  final Color color;
  const _TypeStyle(this.icon, this.color);
}