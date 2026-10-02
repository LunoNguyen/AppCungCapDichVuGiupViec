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

  // Màu theo phong cách bTaskee Partner
  static const _primary = AppColors.partner500;
  static const _ink = AppColors.textPrimary;

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
                      child: CircularProgressIndicator(color: _primary))
                  : RefreshIndicator(
                      onRefresh: _fetchNotifications,
                      color: _primary,
                      child: _buildList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final canPop = Navigator.canPop(context);
    return Container(
      color: _primary,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: Column(
        children: [
          SizedBox(
            height: 52,
            child: Row(
              children: [
                canPop
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.maybePop(context),
                      )
                    : const SizedBox(width: 48),
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
                  icon: Icon(Icons.done_all,
                      color: _unreadCount == 0
                          ? Colors.white.withValues(alpha: 0.5)
                          : Colors.white),
                  onPressed: _unreadCount == 0 ? null : _markAllRead,
                ),
              ],
            ),
          ),
          Row(
            children: [
              _segment('Tất cả', !_onlyUnread,
                  () => setState(() => _onlyUnread = false)),
              _segment(
                  'Chưa đọc${_unreadCount > 0 ? ' ($_unreadCount)' : ''}',
                  _onlyUnread,
                  () => setState(() => _onlyUnread = true)),
            ],
          ),
        ],
      ),
    );
  }

  // Tab gạch chân trắng như bTaskee Partner
  Widget _segment(String text, bool selected, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? Colors.white : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 14,
              color: selected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.75),
            ),
          ),
        ),
      ),
    );
  }

  // Dòng bật/tắt nhận thông báo
  Widget _buildSettingRow() {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(
            _notifEnabled
                ? Icons.notifications_active_outlined
                : Icons.notifications_off_outlined,
            color: _notifEnabled ? _primary : AppColors.textMuted,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _notifEnabled ? 'Đang nhận thông báo' : 'Đã tắt thông báo',
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14, color: _ink),
            ),
          ),
          Switch(
            value: _notifEnabled,
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
              size: 60, color: AppColors.ctvYellowBorder),
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

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: list.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, i) => _buildItem(list[i]),
    );
  }

  // ===================== DÒNG THÔNG BÁO =====================

  Widget _buildItem(Map<String, dynamic> n) {
    final style = _typeStyle(n['loai']?.toString() ?? '');
    final bool unread = n['daDoc'] == false;

    return Dismissible(
      key: ValueKey(n['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        padding: const EdgeInsets.only(right: 24),
        alignment: Alignment.centerRight,
        color: AppColors.error,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) {
        // TODO: gọi API xóa thông báo
        setState(() => _items.removeWhere((e) => e['id'] == n['id']));
      },
      child: InkWell(
        onTap: () => _markRead(n),
        child: Container(
          color: unread ? AppColors.partnerLight : Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: style.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(style.icon, color: style.color, size: 22),
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
                            n['tieuDe']?.toString() ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14.5,
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
                              color: AppColors.partner500,
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
                        fontSize: 13.5,
                        height: 1.35,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _timeAgo(n['thoiGian'] as DateTime),
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
      ),
    );
  }

  // ===================== HÀM HỖ TRỢ =====================

  _TypeStyle _typeStyle(String loai) {
    switch (loai) {
      case 'donMoi':
        return const _TypeStyle(Icons.work_outline_rounded, AppColors.partner500);
      case 'nhacLich':
        return const _TypeStyle(Icons.access_time, AppColors.info);
      case 'hoanThanh':
        return const _TypeStyle(
            Icons.check_circle_outline, AppColors.success);
      case 'huy':
        return const _TypeStyle(Icons.cancel_outlined, AppColors.error);
      default:
        return const _TypeStyle(Icons.campaign_outlined, AppColors.textSecondary);
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
}

class _TypeStyle {
  final IconData icon;
  final Color color;
  const _TypeStyle(this.icon, this.color);
}