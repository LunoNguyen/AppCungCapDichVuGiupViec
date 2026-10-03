import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_colors.dart';
import '../../services/notification_api_service.dart';
import 'collaborator_main_screen.dart';

class CollaboratorNotificationsScreen extends StatefulWidget {
  const CollaboratorNotificationsScreen({super.key});

  @override
  State<CollaboratorNotificationsScreen> createState() =>
      _CollaboratorNotificationsScreenState();
}

class _CollaboratorNotificationsScreenState
    extends State<CollaboratorNotificationsScreen> {
  final NotificationApiService _apiService = NotificationApiService();
  bool _isLoading = true;
  bool _notifEnabled = true;
  bool _onlyUnread = false;
  int _currentUserId = 0;
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
    _currentUserId = prefs.getInt('taiKhoanId') ?? prefs.getInt('userId') ?? 9;
    await _fetchNotifications();
  }

  // ===================== DỮ LIỆU TỪ API =====================

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final response =
          await _apiService.getCollaboratorNotifications(_currentUserId);
      if (response.success && response.data != null) {
        final List<Map<String, dynamic>> loaded = [];
        for (final raw in response.data!) {
          DateTime thoiGian = DateTime.now();
          if (raw['thoiGianGui'] != null) {
            thoiGian =
                DateTime.tryParse(raw['thoiGianGui'].toString()) ?? DateTime.now();
          }
          loaded.add({
            'id': raw['id'],
            'thongBaoId': raw['thongBaoId'],
            'loai': raw['loai']?.toString() ?? 'heThong',
            'tieuDe': raw['tieuDe']?.toString() ?? '',
            'noiDung': raw['noiDung']?.toString() ?? '',
            'nguoiGui': raw['nguoiGui']?.toString() ?? 'Hệ thống',
            'thoiGian': thoiGian,
            'daDoc': raw['daDoc'] == true,
          });
        }
        if (mounted) setState(() => _items = loaded);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  List<Map<String, dynamic>> get _visibleItems =>
      _onlyUnread ? _items.where((e) => e['daDoc'] == false).toList() : _items;

  int get _unreadCount => _items.where((e) => e['daDoc'] == false).length;

  Future<void> _markAllRead() async {
    setState(() {
      for (final e in _items) {
        e['daDoc'] = true;
      }
    });
    try {
      await _apiService.markAllCollaboratorNotificationsRead(_currentUserId);
    } catch (_) {}
  }

  Future<void> _markRead(Map<String, dynamic> item) async {
    if (item['daDoc'] == true) return;
    setState(() => item['daDoc'] = true);
    final id = item['id'];
    if (id is int) {
      try {
        await _apiService.markCollaboratorNotificationRead(
          id: id,
          taiKhoanId: _currentUserId,
        );
      } catch (_) {}
    }
  }

  void _showNotificationDetail(Map<String, dynamic> n) {
    _markRead(n);
    final String tieuDe = n['tieuDe']?.toString() ?? '';
    final String noiDung = n['noiDung']?.toString() ?? '';
    final style = _typeStyle(n['loai']?.toString() ?? '', tieuDe);
    final DateTime thoiGian = n['thoiGian'] as DateTime? ?? DateTime.now();
    final String formattedTime =
        '${thoiGian.hour.toString().padLeft(2, '0')}:${thoiGian.minute.toString().padLeft(2, '0')} • ${thoiGian.day.toString().padLeft(2, '0')}/${thoiGian.month.toString().padLeft(2, '0')}/${thoiGian.year}';

    // Parse thông minh thông tin đơn
    final fullText = '$tieuDe $noiDung';
    final orderMatch =
        RegExp(r'(DON-[A-Za-z0-9\-]+|PC-[A-Za-z0-9\-]+)').firstMatch(fullText);
    final String? orderCode = orderMatch?.group(0);

    final moneyMatch = RegExp(
            r'([0-9]{1,3}(?:\.[0-9]{3})+đ|[0-9]{1,3}(?:,[0-9]{3})+đ|[0-9]+(?:\.[0-9]+)?\s*đ)')
        .firstMatch(noiDung);
    final String? moneyStr = moneyMatch?.group(0);

    String? reasonStr;
    if (noiDung.toLowerCase().contains('lý do:')) {
      final parts = noiDung.split(RegExp(r'[Ll]ý do:'));
      if (parts.length > 1) {
        reasonStr = parts[1].split('.')[0].trim().replaceAll('"', '');
      }
    }

    final String nguoiGui = n['nguoiGui']?.toString() ?? 'Hệ thống Neatify';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 14),

            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Hero Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            style.lightBg,
                            Colors.white,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: style.border, width: 1.2),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  style.color,
                                  style.color.withValues(alpha: 0.8),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: style.color.withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(style.icon,
                                size: 26, color: Colors.white),
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
                                    color: style.color.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    style.label.toUpperCase(),
                                    style: TextStyle(
                                      color: style.color,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.schedule,
                                        size: 13, color: Colors.grey.shade500),
                                    const SizedBox(width: 4),
                                    Text(
                                      formattedTime,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () => Navigator.pop(ctx),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey.shade100,
                              ),
                              child: const Icon(Icons.close,
                                  size: 18, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Tiêu đề thông báo
                    Text(
                      tieuDe,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                        height: 1.35,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Thẻ thông tin nổi bật: Mã đơn & Số tiền (nếu có)
                    if (orderCode != null ||
                        moneyStr != null ||
                        reasonStr != null) ...[
                      Row(
                        children: [
                          if (orderCode != null)
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: const Color(0xFFE2E8F0)),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'MÃ ĐƠN HÀNG',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.grey.shade500,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      orderCode,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: _headerTop,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (orderCode != null && moneyStr != null)
                            const SizedBox(width: 10),
                          if (moneyStr != null)
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: const Color(0xFFA7F3D0)),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'TIỀN NHẬN ĐƯỢC',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF059669),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '+$moneyStr',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF047857),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Thẻ Lý do từ chối (nếu có)
                    if (reasonStr != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: const Color(0xFFFECACA)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline,
                                size: 18, color: Color(0xFFDC2626)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'LÝ DO TỪ CHỐI ĐƠN',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFDC2626),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    reasonStr,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF991B1B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Khung nội dung chi tiết
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.notes_rounded,
                                  size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 6),
                              Text(
                                'Nội dung chi tiết',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            noiDung,
                            style: const TextStyle(
                              fontSize: 14.5,
                              height: 1.55,
                              color: Color(0xFF334155),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Người gửi / Nguồn thông báo
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _headerTop.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.verified_user_rounded,
                              size: 14, color: _headerTop),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Nguồn: $nguoiGui',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Nút bấm hành động ở đáy
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: (orderCode != null || n['loai'] == 'donMoi')
                  ? Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(46),
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text(
                              'Đóng',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.arrow_forward_rounded,
                                size: 18),
                            label: const Text(
                              'Xem danh sách đơn',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(46),
                              backgroundColor: _headerTop,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () {
                              Navigator.pop(ctx);
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const CollaboratorMainScreen(initialIndex: 0),
                                ),
                                (route) => false,
                              );
                            },
                          ),
                        ),
                      ],
                    )
                  : SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: const Text(
                          'Đã hiểu & Đóng',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _headerTop,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
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
        onTap: () => _showNotificationDetail(n),
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

  _TypeStyle _typeStyle(String loai, [String tieuDe = '']) {
    final lower = tieuDe.toLowerCase();
    if (lower.contains('từ chối') || loai == 'huy') {
      return const _TypeStyle(
        icon: Icons.cancel_rounded,
        color: Color(0xFFDC2626),
        lightBg: Color(0xFFFEF2F2),
        border: Color(0xFFFECACA),
        label: 'Đã từ chối',
      );
    }
    switch (loai) {
      case 'donMoi':
        return const _TypeStyle(
          icon: Icons.assignment_rounded,
          color: Color(0xFFD97706),
          lightBg: Color(0xFFFFFBEB),
          border: Color(0xFFFDE68A),
          label: 'Đơn mới',
        );
      case 'nhacLich':
        return const _TypeStyle(
          icon: Icons.schedule_rounded,
          color: Color(0xFF2563EB),
          lightBg: Color(0xFFEFF6FF),
          border: Color(0xFFBFDBFE),
          label: 'Nhắc lịch ca làm',
        );
      case 'hoanThanh':
        return const _TypeStyle(
          icon: Icons.check_circle_rounded,
          color: Color(0xFF059669),
          lightBg: Color(0xFFECFDF5),
          border: Color(0xFFA7F3D0),
          label: 'Hoàn thành',
        );
      default:
        return const _TypeStyle(
          icon: Icons.campaign_rounded,
          color: Color(0xFF4F46E5),
          lightBg: Color(0xFFEEF2FF),
          border: Color(0xFFC7D2FE),
          label: 'Thông báo',
        );
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
  final Color lightBg;
  final Color border;
  final String label;

  const _TypeStyle({
    required this.icon,
    required this.color,
    required this.lightBg,
    required this.border,
    required this.label,
  });
}