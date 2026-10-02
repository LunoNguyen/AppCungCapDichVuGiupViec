import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_colors.dart';
import '../../services/collaborator_api_service.dart';

class CollaboratorOrdersScreen extends StatefulWidget {
  const CollaboratorOrdersScreen({super.key});

  @override
  State<CollaboratorOrdersScreen> createState() =>
      _CollaboratorOrdersScreenState();
}

class _CollaboratorOrdersScreenState extends State<CollaboratorOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CollaboratorApiService _apiService = CollaboratorApiService();

  bool _isLoading = true;
  int _currentUserId = 0;
  List<Map<String, dynamic>> _allAssignments = [];

  // Màu riêng của màn hình
  static const _headerTop = Color(0xFF3F4A8A);
  static const _headerBottom = Color(0xFF5B62B3);
  static const _coral = Color(0xFFE8646A);
  static const _chipBg = Color(0xFFE6E7F2);
  static const _tileBg = Color(0xFFF4F5FA);
  static const _ink = Color(0xFF1F2544);

  // Cặp màu avatar: [nền, chữ]
  static const _avatarColors = [
    [Color(0xFFCECBF6), Color(0xFF3C3489)],
    [Color(0xFF9FE1CB), Color(0xFF085041)],
    [Color(0xFFF5C4B3), Color(0xFF712B13)],
    [Color(0xFFB5D4F4), Color(0xFF0C447C)],
    [Color(0xFFF4C0D1), Color(0xFF72243E)],
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserAndFetchData();

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ===================== DỮ LIỆU =====================

  Future<void> _loadUserAndFetchData() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getInt('userId') ?? 0;
    if (_currentUserId == 0) {
      setState(() => _isLoading = false);
      return;
    }
    await _fetchAssignments();
  }

  Future<void> _fetchAssignments() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response =
      await _apiService.getAssignments(congTacVienId: _currentUserId);
      if (response.success && response.data != null) {
        setState(() {
          _allAssignments = List<Map<String, dynamic>>.from(response.data!);
        });
      } else {
        _showError(response.message ?? 'Không thể tải danh sách đơn');
      }
    } catch (e) {
      _showError('Lỗi kết nối: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  List<Map<String, dynamic>> _getFilteredList(String tabType) {
    if (tabType == 'new') {
      return _allAssignments.where((item) {
        final status =
        (item['trangThaiPhanCong']?.toString() ?? '').toLowerCase();
        return status == 'chophancong' ||
            status == 'cho_xac_nhan' ||
            status == 'new';
      }).toList();
    } else if (tabType == 'confirmed') {
      return _allAssignments.where((item) {
        final status =
        (item['trangThaiPhanCong']?.toString() ?? '').toLowerCase();
        return status == 'daxacnhan' ||
            status == 'da_xac_nhan' ||
            status == 'danhan' ||
            status == 'dang_thuc_hien' ||
            status == 'confirmed';
      }).toList();
    } else {
      return _allAssignments.where((item) {
        final status =
        (item['trangThaiPhanCong']?.toString() ?? '').toLowerCase();
        return status == 'hoanthanh' ||
            status == 'hoan_thanh' ||
            status == 'completed';
      }).toList();
    }
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
            Expanded(
              child: _isLoading
                  ? const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.brand500))
                  : TabBarView(
                controller: _tabController,
                children: [
                  _buildOrderList('new'),
                  _buildOrderList('confirmed'),
                  _buildOrderList('completed'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Header gradient + tab dạng segmented
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
              const SizedBox(width: 48),
              const Expanded(
                child: Text(
                  'Đơn của tôi',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _fetchAssignments,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              indicator: BoxDecoration(
                color: _headerTop,
                borderRadius: BorderRadius.circular(10),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: _headerTop,
              labelStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              tabs: const [
                Tab(
                    height: 38,
                    child: FittedBox(
                        fit: BoxFit.scaleDown, child: Text('MỚI'))),
                Tab(
                    height: 38,
                    child: FittedBox(
                        fit: BoxFit.scaleDown, child: Text('ĐÃ XÁC NHẬN'))),
                Tab(
                    height: 38,
                    child: FittedBox(
                        fit: BoxFit.scaleDown, child: Text('HOÀN THÀNH'))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList(String status) {
    final filtered = _getFilteredList(status);

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined,
                size: 60, color: AppColors.brand300),
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
        return _buildOrderCard(o, status);
      },
    );
  }

  // ===================== HÀM HỖ TRỢ =====================

  // 338000 -> 338.000đ
  String _formatPrice(dynamic v) {
    final n = num.tryParse(v?.toString() ?? '')?.round() ?? 0;
    final s = n
        .toString()
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');
    return '${s}đ';
  }

  // Màu theo trạng thái: Mới = cam, Đã xác nhận = xanh dương, Hoàn thành = xanh lá
  Color _statusColor(String tab) {
    switch (tab) {
      case 'new':
        return const Color(0xFFC77700);
      case 'confirmed':
        return const Color(0xFF2F80ED);
      default:
        return const Color(0xFF2E9E6B);
    }
  }

  // "09:00:00" -> "09:00"
  String _fmtTime(String? s) {
    if (s == null || s.isEmpty) return '';
    return s.length >= 5 ? s.substring(0, 5) : s;
  }

  // "2026-09-30" -> "30/09/2026"
  String _fmtDate(String s) {
    if (s.length < 10) return s;
    final p = s.substring(0, 10).split('-');
    return p.length == 3 ? '${p[2]}/${p[1]}/${p[0]}' : s;
  }

  // Hôm nay / Ngày mai / Hôm qua (ngày khác thì trả về null)
  String? _dayLabel(String raw) {
    if (raw.length < 10) return null;
    final d = DateTime.tryParse(raw.substring(0, 10));
    if (d == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = DateTime(d.year, d.month, d.day).difference(today).inDays;
    if (diff == 0) return 'Hôm nay';
    if (diff == 1) return 'Ngày mai';
    if (diff == -1) return 'Hôm qua';
    return null;
  }

  // "Nguyễn Thị Thu Lan" -> "TL", "Nguyễn Văn A" -> "VA"
  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[parts.length - 2][0] + parts.last[0]).toUpperCase();
  }

  // Mỗi tên khách ra một màu avatar cố định
  List<Color> _avatarPair(String name) {
    final sum = name.codeUnits.fold<int>(0, (a, b) => a + b);
    return _avatarColors[sum % _avatarColors.length];
  }

  // ===================== THẺ ĐƠN =====================

  Widget _buildOrderCard(Map<String, dynamic> o, String currentTab) {
    final String serviceName = o['tenDichVu'] ?? 'Dịch vụ giúp việc';
    final String customerName = o['khachHangTen'] ?? 'Khách hàng';
    final String address = o['diaChi'] ?? 'Chưa cập nhật địa chỉ';
    final String price = _formatPrice(o['thanhTien']);
    final String rawDate = o['ngayThucHien']?.toString() ?? '';
    final String dateStr = _fmtDate(rawDate);
    final String timeStr =
        '${_fmtTime(o['gioBatDau']?.toString())} - ${_fmtTime(o['gioKetThuc']?.toString())}';
    final bool isNew = currentTab == 'new';
    final Color sc = _statusColor(currentTab);

    final String statusText = isNew
        ? 'Chờ nhận'
        : currentTab == 'confirmed'
        ? 'Đã xác nhận'
        : 'Hoàn thành';

    final String? dayLbl = _dayLabel(rawDate);
    final avatar = _avatarPair(customerName);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isNew ? null : AppColors.white,
        gradient: isNew
            ? const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFE9A8), Color(0xFFFFF8E1)],
        )
            : null,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hàng 1: chip dịch vụ (trái) + nhãn trạng thái (phải)
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _chipBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      serviceName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _headerTop,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: sc.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: sc,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Hàng 2: avatar + tên khách (tối đa 2 dòng) + nhãn ngày
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: avatar[0],
                  shape: BoxShape.circle,
                ),
                child: Text(
                  _initials(customerName),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: avatar[1],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                        height: 1.25,
                      ),
                    ),
                    if (dayLbl != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        dayLbl,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Hàng 3: ô ngày + ô giờ (icon màu theo trạng thái)
          Row(
            children: [
              Expanded(
                  child: _infoTile(
                      Icons.calendar_today_outlined, dateStr, sc, isNew)),
              const SizedBox(width: 8),
              Expanded(
                  child: _infoTile(Icons.access_time, timeStr, sc, isNew)),
            ],
          ),
          const SizedBox(height: 10),

          // Hàng 4: địa chỉ
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: Icon(Icons.location_on_outlined,
                    size: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: Colors.black.withOpacity(0.08)),
          const SizedBox(height: 12),

          // Hàng 5: giá tiền
          Row(
            children: [
              const Text(
                'Thành tiền',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                price,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _coral,
                ),
              ),
            ],
          ),

          // Nút thao tác theo tab
          if (isNew) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleAction(o, 'reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Từ chối'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleAction(o, 'accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _headerTop,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Nhận đơn'),
                  ),
                ),
              ],
            ),
          ] else if (currentTab == 'confirmed') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _handleAction(o, 'complete'),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Đánh dấu hoàn thành'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Ô thông tin nền nhạt (ngày / giờ), icon màu theo trạng thái
  Widget _infoTile(IconData icon, String text, Color color, bool onYellow) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: onYellow ? Colors.white.withOpacity(0.7) : _tileBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                text,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===================== THAO TÁC =====================

  Future<void> _handleAction(Map<String, dynamic> o, String action) async {
    final int phanCongId = o['phanCongId'] ?? 0;
    if (phanCongId == 0) {
      _showError('Lỗi: Không tìm thấy ID phân công');
      return;
    }

    setState(() => _isLoading = true);
    try {
      dynamic res;
      if (action == 'accept') {
        res = await _apiService.acceptAssignment(phanCongId);
      } else if (action == 'reject') {
        res = await _apiService.rejectAssignment(id: phanCongId);
      } else if (action == 'complete') {
        res = await _apiService.completeAssignment(
            id: phanCongId, ghiChu: "Hoàn thành qua ứng dụng");
      }

      if (res != null && res.success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(action == 'accept'
                ? 'Đã nhận việc thành công!'
                : 'Thao tác thành công!'),
            backgroundColor: AppColors.success,
          ),
        );
        // Tải lại danh sách để cập nhật trạng thái mới nhất
        await _fetchAssignments();

        // Chuyển tab tương ứng
        if (action == 'accept') _tabController.animateTo(1);
        if (action == 'complete') _tabController.animateTo(2);
      } else {
        _showError(res?.message ?? 'Thao tác thất bại');
      }
    } catch (e) {
      _showError('Lỗi hệ thống: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}