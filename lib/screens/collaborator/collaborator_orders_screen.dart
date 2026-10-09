import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_colors.dart';
import '../../services/collaborator_api_service.dart';
import '../../services/location_service.dart';

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
  // Pool: đơn đang tìm CTV (tất cả CTV thấy)
  List<Map<String, dynamic>> _poolOrders = [];
  // Assignments: đơn CTV đã nhận (DaXacNhan/DangThucHien/HoanThanh)
  List<Map<String, dynamic>> _allAssignments = [];
  // Các đơn CTV đã bấm bỏ qua/từ chối (lưu local)
  Set<int> _hiddenOrderIds = {};
  double? _myLat; // vị trí GPS hiện tại của CTV, để tính khoảng cách tới nơi làm
  double? _myLng;

  // Màu theo phong cách bTaskee Partner
  static const _primary = AppColors.partner500;
  static const _money = AppColors.ctvMoney;
  static const _ink = AppColors.textPrimary;

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
    final hiddenList = prefs.getStringList('hidden_orders_$_currentUserId') ?? [];
    _hiddenOrderIds = hiddenList.map((e) => int.tryParse(e) ?? 0).toSet();
    _layViTri();
    await _fetchAllData();
  }

  Future<void> _layViTri() async {
    final r = await LocationService.getCurrentPosition();
    if (!mounted || !r.ok) return;
    setState(() {
      _myLat = r.position!.latitude;
      _myLng = r.position!.longitude;
    });
  }

  /// Tải cả 2 nguồn dữ liệu:
  /// 1. Pool đơn chung (DangTimCTV) — tab "Việc mới"
  /// 2. Đơn CTV đã nhận (PhanCongCTV của CTV này) — tab "Đã nhận" và "Hoàn thành"
  Future<void> _fetchAllData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // Gọi song song
      final results = await Future.wait([
        _apiService.getAvailableOrders(congTacVienId: _currentUserId),
        _apiService.getAssignments(congTacVienId: _currentUserId),
      ]);

      final poolRes = results[0] as dynamic;
      final assignRes = results[1] as dynamic;

      setState(() {
        _poolOrders = poolRes.success && poolRes.data != null
            ? List<Map<String, dynamic>>.from(poolRes.data!)
            : [];
        _allAssignments = assignRes.success && assignRes.data != null
            ? List<Map<String, dynamic>>.from(assignRes.data!)
            : [];
      });


    } catch (e) {
      _showError('Lỗi kết nối: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Chỉ refresh pool (sau khi nhận/từ chối đơn)
  Future<void> _refreshPool() async {
    try {
      final res = await _apiService.getAvailableOrders(congTacVienId: _currentUserId);
      if (mounted && res.success && res.data != null) {
        setState(() => _poolOrders = List<Map<String, dynamic>>.from(res.data!));
      }
    } catch (_) {}
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  List<Map<String, dynamic>> _getFilteredList(String tabType) {
    if (tabType == 'new') {
      // Tab "Việc mới" = pool đơn DangTimCTV (lọc bỏ đơn CTV này đã ẩn local)
      return _poolOrders.where((item) {
        final donId = item['donDatId'] ?? item['id'] ?? 0;
        return !_hiddenOrderIds.contains(donId);
      }).toList();
    } else if (tabType == 'confirmed') {
      return _allAssignments.where((item) {
        final status = (item['trangThaiPhanCong']?.toString() ??
                item['trangThai']?.toString() ??
                '')
            .toLowerCase();
        return status == 'daxacnhan' ||
            status == 'da_xac_nhan' ||
            status == 'danhan' ||
            status == 'da_nhan' ||
            status == 'daphancong' ||
            status == 'da_phan_cong' ||
            status == 'choxacnhan' ||
            status == 'cho_xac_nhan' ||
            status == 'choduyet' ||
            status == 'cho_duyet' ||
            status == 'dang_thuc_hien' ||
            status == 'dangthuchien' ||
            status == 'confirmed' ||
            status == 'assigned' ||
            status == 'pending' ||
            status == 'active';
      }).toList();
    } else {
      return _allAssignments.where((item) {
        final status = (item['trangThaiPhanCong']?.toString() ??
                item['trangThai']?.toString() ??
                '')
            .toLowerCase();
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
                      child: CircularProgressIndicator(color: _primary))
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

  // Header xanh lá + tab gạch chân như bTaskee Partner
  Widget _buildHeader() {
    final newCount = _getFilteredList('new').length;
    return Container(
      color: _primary,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      child: Column(
        children: [
          SizedBox(
            height: 52,
            child: Row(
              children: [
                const SizedBox(width: 48),
                const Expanded(
                  child: Text(
                    'Công việc',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  onPressed: _fetchAllData,
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.75),
            labelStyle:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            unselectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            tabs: [
              Tab(text: newCount > 0 ? 'Việc mới ($newCount)' : 'Việc mới'),
              const Tab(text: 'Đã nhận'),
              const Tab(text: 'Hoàn thành'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList(String status) {
    final filtered = _getFilteredList(status);

    if (filtered.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchAllData,
        color: _primary,
        child: ListView(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.15),
            Center(
              child: Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: AppColors.partnerLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.work_off_outlined,
                    size: 44, color: _primary),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              status == 'new'
                  ? 'Hiện chưa có công việc mới'
                  : status == 'confirmed'
                      ? 'Bạn chưa nhận công việc nào'
                      : 'Chưa có công việc hoàn thành',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Kéo xuống để làm mới danh sách',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAllData,
      color: _primary,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 10, bottom: 20),
        itemCount: filtered.length,
        itemBuilder: (context, index) =>
            _buildOrderCard(filtered[index], status),
      ),
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

  // Màu theo trạng thái: Mới = cam, Đã nhận = xanh dương, Hoàn thành = xanh lá
  Color _statusColor(String tab) {
    switch (tab) {
      case 'new':
        return AppColors.partner500;
      case 'confirmed':
        return AppColors.info;
      default:
        return AppColors.success;
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

  // ===================== THẺ CÔNG VIỆC =====================

  /// Toạ độ nhà khách tra từ địa chỉ dạng chữ (CSDL không lưu toạ độ), theo địa chỉ.
  final Map<String, List<double>?> _toaDoDiaChi = {};

  Future<void> _traToaDo(String address) async {
    if (_toaDoDiaChi.containsKey(address)) return;
    _toaDoDiaChi[address] = null;
    final td = await LocationService.forwardGeocode(address);
    if (mounted && td != null) setState(() => _toaDoDiaChi[address] = td);
  }

  /// Khoảng cách tới nhà khách (khi tra được toạ độ) và nút mở Google Maps chỉ đường.
  Widget _directionsRow(Map<String, dynamic> o) {
    final address = o['diaChi']?.toString().trim() ?? '';
    if (address.isEmpty) return const SizedBox.shrink();
    String? khoangCach;
    if (_myLat != null && _myLng != null) {
      final td = _toaDoDiaChi[address];
      if (td == null) {
        _traToaDo(address);
      } else {
        khoangCach = 'Cách bạn khoảng ${LocationService.formatKm(LocationService.distanceKm(_myLat!, _myLng!, td[0], td[1]))}';
      }
    }
    return Padding(
      padding: const EdgeInsets.only(left: 26, bottom: 6),
      child: Row(
        children: [
          if (khoangCach != null)
            Expanded(
              child: Text(khoangCach,
                  style: const TextStyle(
                      fontSize: 12.5, color: AppColors.textSecondary)),
            )
          else
            const Spacer(),
          TextButton.icon(
            onPressed: () async {
              final ok = await LocationService.openDirections(address: address);
              if (!ok && mounted) _showError('Không mở được ứng dụng bản đồ');
            },
            icon: const Icon(Icons.directions, size: 18),
            label: const Text('Chỉ đường'),
            style: TextButton.styleFrom(
              foregroundColor: _primary,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

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
            ? 'Đã nhận'
            : 'Hoàn thành';

    final String? dayLbl = _dayLabel(rawDate);
    final avatar = _avatarPair(customerName);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tên dịch vụ + thu nhập
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serviceName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: sc.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: sc,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _money,
                      ),
                    ),
                    const Text(
                      'Thu nhập',
                      style: TextStyle(
                          fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Thông tin chi tiết
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: Column(
              children: [
                _infoRow(
                  Icons.calendar_today_outlined,
                  dayLbl != null ? '$dayLbl, $dateStr' : dateStr,
                ),
                _infoRow(Icons.access_time_rounded, timeStr),
                _infoRow(Icons.location_on_outlined, address, maxLines: 2),
                _directionsRow(o),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: avatar[0],
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          _initials(customerName),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: avatar[1],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          customerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Nút thao tác
          if (isNew)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () => _showRejectDialog(o),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text('Từ chối',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () => _handleAction(o, 'accept'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text('Nhận việc'),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (currentTab == 'confirmed')
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: () => _handleAction(o, 'complete'),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Hoàn thành công việc'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                color: _ink,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===================== HỘP THOẠI TỪ CHỐI ĐƠN =====================

  Future<void> _showRejectDialog(Map<String, dynamic> o) async {
    final TextEditingController reasonController = TextEditingController();
    String? errorMessage;
    String selectedChip = '';

    final List<String> reasonPresets = [
      'Bận việc cá nhân',
      'Trùng lịch làm',
      'Khoảng cách quá xa',
      'Lý do sức khỏe',
    ];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.assignment_return_outlined,
                            color: Color(0xFFDC2626),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Từ chối nhận việc',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _ink,
                                ),
                              ),
                              Text(
                                'Mã đơn: ${o['maDonDat'] ?? 'N/A'}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Lý do gợi ý nhanh:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: reasonPresets.map((preset) {
                        final isSelected = selectedChip == preset;
                        return ChoiceChip(
                          label: Text(preset),
                          selected: isSelected,
                          selectedColor: const Color(0xFFFEE2E2),
                          backgroundColor: const Color(0xFFF1F5F9),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? const Color(0xFFDC2626) : const Color(0xFF334155),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isSelected ? const Color(0xFFEF4444) : Colors.transparent,
                            ),
                          ),
                          onSelected: (selected) {
                            setModalState(() {
                              if (selected) {
                                selectedChip = preset;
                                reasonController.text = preset;
                                reasonController.selection = TextSelection.collapsed(offset: preset.length);
                                errorMessage = null;
                              } else {
                                selectedChip = '';
                                if (reasonController.text == preset) {
                                  reasonController.clear();
                                }
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Chi tiết lý do từ chối *',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: reasonController,
                      maxLines: 3,
                      maxLength: 150,
                      inputFormatters: [
                        _NoMultipleSpacesFormatter(),
                      ],
                      onChanged: (val) {
                        setModalState(() {
                          if (selectedChip.isNotEmpty && val != selectedChip) {
                            selectedChip = '';
                          }
                          if (errorMessage != null) {
                            errorMessage = null;
                          }
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Nhập lý do cụ thể gửi CSKH điều phối lại...',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        errorText: errorMessage,
                        contentPadding: const EdgeInsets.all(12),
                        suffixIcon: reasonController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18, color: Color(0xFF94A3B8)),
                                onPressed: () {
                                  setModalState(() {
                                    reasonController.clear();
                                    selectedChip = '';
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                            child: const Text(
                              'Bỏ qua',
                              style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              final raw = reasonController.text;
                              // Chuẩn hóa văn bản: xóa khoảng trắng đầu cuối và gộp các khoảng trắng liên tiếp
                              final cleanReason = raw.trim().replaceAll(RegExp(r'\s+'), ' ');

                              if (cleanReason.isEmpty) {
                                setModalState(() {
                                  errorMessage = 'Vui lòng nhập lý do từ chối (không được để trống)';
                                });
                                return;
                              }
                              if (cleanReason.length < 5) {
                                setModalState(() {
                                  errorMessage = 'Lý do từ chối phải có ít nhất 5 ký tự';
                                });
                                return;
                              }

                              Navigator.pop(context);
                              _handleAction(o, 'reject', lyDo: cleanReason);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDC2626),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Xác nhận từ chối',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ===================== THAO TÁC =====================

  Future<void> _handleAction(Map<String, dynamic> o, String action, {String? lyDo}) async {
    setState(() => _isLoading = true);
    try {
      dynamic res;

      if (action == 'accept') {
        // Pool: dùng donDatId (không phải phanCongId)
        final int donDatId = o['donDatId'] ?? 0;
        if (donDatId == 0) {
          _showError('Lỗi: Không tìm thấy ID đơn hàng');
          return;
        }
        res = await _apiService.acceptOrderFromPool(
          donDatId: donDatId,
          congTacVienId: _currentUserId,
        );
      } else if (action == 'reject') {
        // Pool: dùng donDatId (ẩn local trên máy CTV này)
        final int donDatId = o['donDatId'] ?? 0;
        if (donDatId == 0) {
          _showError('Lỗi: Không tìm thấy ID đơn hàng');
          return;
        }
        _hiddenOrderIds.add(donDatId);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('hidden_orders_$_currentUserId', _hiddenOrderIds.map((e) => e.toString()).toList());

        res = await _apiService.rejectOrderFromPool(
          donDatId: donDatId,
          congTacVienId: _currentUserId,
          lyDo: lyDo,
        );
      } else if (action == 'complete') {
        // Đơn đã nhận: dùng phanCongId như cũ
        final int phanCongId = o['phanCongId'] ?? 0;
        if (phanCongId == 0) {
          _showError('Lỗi: Không tìm thấy ID phân công');
          return;
        }
        res = await _apiService.completeAssignment(
            id: phanCongId, ghiChu: 'Hoàn thành qua ứng dụng');
      }

      if (res != null && res.success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(action == 'accept'
                ? 'Đã nhận việc thành công!'
                : (action == 'reject'
                    ? 'Đã bỏ qua. Đơn vẫn hiện cho CTV khác.'
                    : 'Đã hoàn thành công việc!')),
            backgroundColor:
                action == 'reject' ? AppColors.warning : AppColors.success,
          ),
        );

        if (action == 'accept') {
          // Tải lại cả 2 để pool bớt đơn, tab đã nhận thêm đơn mới
          await _fetchAllData();
          _tabController.animateTo(1);
        } else if (action == 'reject') {
          // Chỉ cần tải lại pool (đơn mới này biến mất, tab khác không đổi)
          await _refreshPool();
        } else if (action == 'complete') {
          await _fetchAllData();
          _tabController.animateTo(2);
        }
      } else {
        // 409: đơn đã có người nhận trước
        final msg = res?.message ?? 'Thao tác thất bại';
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Đơn đã có người nhận'),
            content: Text(msg),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _refreshPool(); // Tải lại để xóa đơn đã bị lấy khỏi list
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      _showError('Lỗi hệ thống: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

/// Formatter ngăn người dùng nhập nhiều dấu cách liên tiếp hoặc bắt đầu bằng dấu cách
class _NoMultipleSpacesFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Không cho phép khoảng trắng ở đầu dòng
    if (newValue.text.startsWith(' ') || newValue.text.startsWith('\n')) {
      final trimmed = newValue.text.trimLeft();
      return newValue.copyWith(
        text: trimmed,
        selection: TextSelection.collapsed(offset: trimmed.length),
      );
    }
    // Gộp 2 khoảng trắng liên tiếp trở lên thành 1
    final replaced = newValue.text.replaceAll(RegExp(r' {2,}'), ' ');
    if (replaced != newValue.text) {
      final diff = newValue.text.length - replaced.length;
      final newOffset = (newValue.selection.baseOffset - diff).clamp(0, replaced.length);
      return newValue.copyWith(
        text: replaced,
        selection: TextSelection.collapsed(offset: newOffset),
      );
    }
    return newValue;
  }
}