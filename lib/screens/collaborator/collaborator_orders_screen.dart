import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import '../../services/collaborator_api_service.dart';
import '../../services/location_service.dart';

class CollaboratorOrdersScreen extends StatefulWidget {
  const CollaboratorOrdersScreen({super.key});

  @override
  State<CollaboratorOrdersScreen> createState() =>
      CollaboratorOrdersScreenState();
}

class CollaboratorOrdersScreenState extends State<CollaboratorOrdersScreen>
    with SingleTickerProviderStateMixin {
  void reload() => _fetchAllData();
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

  // Bộ lọc theo khoảng ngày cho tab "Đã xong"
  DateTimeRange? _completedDateRange;

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
    // 4 Tab: Mới (0), Chờ làm (1), Đang làm (2), Đã xong (3)
    _tabController = TabController(length: 4, vsync: this);
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
    await _fetchAllData();
  }

  /// Tải cả 2 nguồn dữ liệu:
  /// 1. Pool đơn chung (DangTimCTV) — tab "Mới"
  /// 2. Đơn CTV đã nhận (PhanCongCTV của CTV này) — tab "Chờ làm", "Đang làm", "Đã xong"
  Future<void> _fetchAllData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
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
      // Tab "Mới" = pool đơn DangTimCTV
      return _poolOrders.where((item) {
        final donId = item['donDatId'] ?? item['id'] ?? 0;
        return !_hiddenOrderIds.contains(donId);
      }).toList();
    } else if (tabType == 'waiting') {
      // Tab "Chờ làm": Đã nhận nhưng CHƯA bắt đầu làm
      return _allAssignments.where((item) {
        final donStatus = (item['trangThaiDon']?.toString() ??
                item['trangThai']?.toString() ??
                '')
            .toLowerCase();
        final pcStatus =
            (item['trangThaiPhanCong']?.toString() ?? '').toLowerCase();

        final isWorking = donStatus == 'dang_thuc_hien' ||
            donStatus == 'dangthuchien' ||
            pcStatus == 'dang_thuc_hien' ||
            pcStatus == 'dangthuchien';
        final isCompleted = donStatus == 'hoanthanh' ||
            donStatus == 'hoan_thanh' ||
            donStatus == 'completed' ||
            pcStatus == 'hoanthanh';
        final isCanceled = pcStatus == 'tuchoi' ||
            donStatus == 'dahuy' ||
            donStatus == 'tuchoi' ||
            donStatus == 'choduyet';

        return !isWorking && !isCompleted && !isCanceled;
      }).toList();
    } else if (tabType == 'in_progress') {
      // Tab "Đang làm": Đang thực hiện
      return _allAssignments.where((item) {
        final donStatus = (item['trangThaiDon']?.toString() ??
                item['trangThai']?.toString() ??
                '')
            .toLowerCase();
        final pcStatus =
            (item['trangThaiPhanCong']?.toString() ?? '').toLowerCase();

        return donStatus == 'dang_thuc_hien' ||
            donStatus == 'dangthuchien' ||
            pcStatus == 'dang_thuc_hien' ||
            pcStatus == 'dangthuchien';
      }).toList();
    } else {
      // Tab "Đã xong": Hoàn thành
      var list = _allAssignments.where((item) {
        final donStatus = (item['trangThaiDon']?.toString() ??
                item['trangThai']?.toString() ??
                '')
            .toLowerCase();
        final pcStatus =
            (item['trangThaiPhanCong']?.toString() ?? '').toLowerCase();

        return donStatus == 'hoanthanh' ||
            donStatus == 'hoan_thanh' ||
            donStatus == 'completed' ||
            pcStatus == 'hoanthanh';
      }).toList();

      // SẮP XẾP: Ngày mới nhất cho tới thấp nhất (giảm dần)
      list.sort((a, b) {
        final dateA = (a['ngayThucHien'] ?? a['ngayLam'] ?? a['ngayTao'] ?? '').toString();
        final dateB = (b['ngayThucHien'] ?? b['ngayLam'] ?? b['ngayTao'] ?? '').toString();
        final cmpDate = dateB.compareTo(dateA); // Mới nhất lên đầu
        if (cmpDate != 0) return cmpDate;
        final timeA = (a['gioBatDau'] ?? '').toString();
        final timeB = (b['gioBatDau'] ?? '').toString();
        return timeB.compareTo(timeA);
      });

      // LỌC THEO KHOẢNG NGÀY
      if (_completedDateRange == null) return list;

      final start = DateTime(
        _completedDateRange!.start.year,
        _completedDateRange!.start.month,
        _completedDateRange!.start.day,
      );
      final end = DateTime(
        _completedDateRange!.end.year,
        _completedDateRange!.end.month,
        _completedDateRange!.end.day,
        23, 59, 59,
      );

      return list.where((item) {
        final raw = (item['ngayThucHien'] ?? item['ngayLam'] ?? item['ngayTao'] ?? '').toString();
        if (raw.isEmpty) return true;
        final dt = DateTime.tryParse(raw.length >= 10 ? raw.substring(0, 10) : raw);
        if (dt == null) return false;
        return !dt.isBefore(start) && !dt.isAfter(end);
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
                        _buildOrderList('waiting'),
                        _buildOrderList('in_progress'),
                        _buildOrderList('completed'),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final newCount = _getFilteredList('new').length;
    final waitingCount = _getFilteredList('waiting').length;
    final inProgressCount = _getFilteredList('in_progress').length;

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
                    'Quản lý công việc',
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
            labelPadding: const EdgeInsets.symmetric(horizontal: 6),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.72),
            labelStyle:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
            unselectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.w500, fontSize: 12.5),
            tabs: [
              Tab(text: newCount > 0 ? 'Mới ($newCount)' : 'Mới'),
              Tab(text: waitingCount > 0 ? 'Chờ làm ($waitingCount)' : 'Chờ làm'),
              Tab(text: inProgressCount > 0 ? 'Đang làm ($inProgressCount)' : 'Đang làm'),
              const Tab(text: 'Đã xong'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList(String status) {
    final filtered = _getFilteredList(status);

    // Xử lý riêng cho tab "Đã xong" (Lịch sử: có bộ lọc ngày + tóm tắt thu nhập + xếp mới nhất -> cũ nhất)
    if (status == 'completed') {
      return _buildCompletedOrderTab(filtered);
    }

    if (filtered.isEmpty) {
      String emptyText;
      switch (status) {
        case 'new':
          emptyText = 'Hiện chưa có công việc mới';
          break;
        case 'waiting':
          emptyText = 'Không có công việc nào đang chờ làm';
          break;
        case 'in_progress':
          emptyText = 'Hiện không có ca làm nào đang diễn ra';
          break;
        default:
          emptyText = 'Chưa có công việc nào hoàn thành';
      }

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
              emptyText,
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

  Widget _buildCompletedOrderTab(List<Map<String, dynamic>> filtered) {
    num totalIncome = 0;
    for (final o in filtered) {
      final p = num.tryParse(o['thanhTien']?.toString() ?? o['tongTien']?.toString() ?? '') ?? 0;
      totalIncome += p;
    }

    String dateRangeText = 'Tất cả các ngày (Chọn khoảng ngày)';
    if (_completedDateRange != null) {
      final s = DateFormat('dd/MM/yyyy').format(_completedDateRange!.start);
      final e = DateFormat('dd/MM/yyyy').format(_completedDateRange!.end);
      dateRangeText = s == e ? s : '$s - $e';
    }

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Banner tóm tắt đưa lên trên
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.history_rounded, size: 20, color: Color(0xFF16A34A)),
                    const SizedBox(width: 8),
                    Text(
                      'Đã xong: ${filtered.length} đơn',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF166534),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Thu nhập: ${_formatPrice(totalIncome)}',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF15803D),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // 2. Cuốn lịch chọn khoảng ngày (đưa xuống bên dưới banner)
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          initialDateRange: _completedDateRange ??
                              DateTimeRange(
                                start: DateTime.now().subtract(const Duration(days: 30)),
                                end: DateTime.now(),
                              ),
                          firstDate: DateTime(2025),
                          lastDate: DateTime(2028),
                          saveText: 'Áp dụng',
                          helpText: 'Chọn khoảng ngày đơn hoàn thành',
                        );
                        if (picked != null) {
                          setState(() => _completedDateRange = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: _completedDateRange != null
                              ? const Color(0xFFEFF6FF)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _completedDateRange != null
                                ? const Color(0xFF3B82F6)
                                : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.date_range_rounded,
                              size: 19,
                              color: _completedDateRange != null
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                dateRangeText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: _completedDateRange != null
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: _completedDateRange != null
                                      ? const Color(0xFF1D4ED8)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_completedDateRange != null) ...[
                    const SizedBox(width: 6),
                    IconButton(
                      tooltip: 'Bỏ lọc',
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.cancel_rounded, size: 22, color: Color(0xFFEF4444)),
                      onPressed: () {
                        setState(() => _completedDateRange = null);
                      },
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              const Divider(height: 8, thickness: 0.8, color: AppColors.divider),
            ],
          ),
        ),

        // 3. Danh sách đơn đã xong (sắp xếp mới nhất -> thấp nhất)
        Expanded(
          child: filtered.isEmpty
              ? RefreshIndicator(
                  onRefresh: _fetchAllData,
                  color: _primary,
                  child: ListView(
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                      const Center(
                        child: Icon(Icons.history_toggle_off_rounded,
                            size: 54, color: Color(0xFFCBD5E1)),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Không có đơn hoàn thành nào trong khoảng thời gian này',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _completedDateRange = null;
                            });
                          },
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Xem tất cả lịch sử'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF16A34A),
                            side: const BorderSide(color: Color(0xFF16A34A)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchAllData,
                  color: _primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 6, bottom: 20),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final rawDate = (item['ngayThucHien'] ?? item['ngayLam'] ?? '').toString();
                      final bool showHeader = index == 0 ||
                          ((filtered[index - 1]['ngayThucHien'] ?? filtered[index - 1]['ngayLam'] ?? '').toString() != rawDate);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showHeader && rawDate.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
                              child: Row(
                                children: [
                                  const Icon(Icons.event_available_rounded, size: 14, color: Color(0xFF16A34A)),
                                  const SizedBox(width: 6),
                                  Text(
                                    _fmtDate(rawDate),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: _ink,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          _buildOrderCard(item, 'completed'),
                        ],
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  // ===================== HÀM HỖ TRỢ =====================

  String _formatPrice(dynamic v) {
    final n = num.tryParse(v?.toString() ?? '')?.round() ?? 0;
    final s = n
        .toString()
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');
    return '$sđ';
  }

  String _fmtTime(String? s) {
    if (s == null || s.isEmpty) return '';
    return s.length >= 5 ? s.substring(0, 5) : s;
  }

  String _fmtDate(String s) {
    if (s.length < 10) return s;
    final p = s.substring(0, 10).split('-');
    return p.length == 3 ? '${p[2]}/${p[1]}/${p[0]}' : s;
  }

  int? _daysDiff(String? rawDate) {
    if (rawDate == null || rawDate.length < 10) return null;
    final d = DateTime.tryParse(rawDate.substring(0, 10));
    if (d == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final workDay = DateTime(d.year, d.month, d.day);
    return workDay.difference(today).inDays;
  }

  bool _isGoiThang(Map<String, dynamic> o) {
    final loaiHinh = (o['loaiHinh'] ?? o['loaiHinhDat'] ?? '').toString().toLowerCase();
    final ten = (o['tenDichVu'] ?? '').toString().toLowerCase();
    final ma = (o['maDichVu'] ?? '').toString().toUpperCase();
    final soBuoi = num.tryParse(o['soBuoi']?.toString() ?? '') ?? 0;
    return loaiHinh.contains('goi') ||
        loaiHinh.contains('thang') ||
        ten.contains('gói') ||
        ten.contains('tháng') ||
        ma.endsWith('-T') ||
        soBuoi > 1;
  }

  String _getDuration(Map<String, dynamic> o) {
    if (o['thoiLuong'] != null) return '${o['thoiLuong']} phút';
    if (o['tg'] != null) return '${o['tg']} phút';
    final start = o['gioBatDau']?.toString();
    final end = o['gioKetThuc']?.toString();
    if (start != null && end != null && start.length >= 5 && end.length >= 5) {
      try {
        final sh = int.parse(start.substring(0, 2));
        final sm = int.parse(start.substring(3, 5));
        final eh = int.parse(end.substring(0, 2));
        final em = int.parse(end.substring(3, 5));
        final mins = (eh * 60 + em) - (sh * 60 + sm);
        if (mins > 0) return '$mins phút';
      } catch (_) {}
    }
    return '120 phút';
  }

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

  List<Color> _avatarPair(String name) {
    final sum = name.codeUnits.fold<int>(0, (a, b) => a + b);
    return _avatarColors[sum % _avatarColors.length];
  }

  Future<void> _handlePhoneCall(String? phone) async {
    if (phone == null || phone.trim().isEmpty) {
      _showError('Không có số điện thoại khách hàng');
      return;
    }
    final clean = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$clean');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showError('Không thể mở ứng dụng gọi điện');
      }
    } catch (e) {
      _showError('Lỗi cuộc gọi: $e');
    }
  }

  Future<void> _handleMapButton(String address, {double? lat, double? lng}) async {
    if ((lat == null || lng == null) && address.trim().isEmpty) {
      _showError('Chưa có thông tin địa chỉ để mở bản đồ');
      return;
    }
    final ok = await LocationService.openDirections(
      lat: lat,
      lng: lng,
      address: address.trim().isNotEmpty ? address.trim() : null,
    );
    if (!ok && mounted) {
      _showError('Không thể mở ứng dụng Google Maps');
    }
  }

  // ===================== THẺ CÔNG VIỆC =====================

  Widget _directionsRow(Map<String, dynamic> o) {
    final address = o['diaChi']?.toString().trim() ?? '';
    if (address.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: 26, bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
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

  Widget _buildServiceTypeBadge(Map<String, dynamic> o) {
    final isPackage = _isGoiThang(o);
    final soBuoi = o['soBuoi']?.toString() ?? '8';
    final buoiHienTai = o['buoiThu']?.toString() ?? o['buoiHienTai']?.toString();

    if (isPackage) {
      final label = buoiHienTai != null
          ? '🔄 Gói tháng - Buổi $buoiHienTai/$soBuoi'
          : '🔄 Gói tháng ($soBuoi buổi)';
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFFCD34D)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFFB45309),
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFC7D2FE)),
        ),
        child: const Text(
          '🏷️ Theo lần (1 buổi)',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF4338CA),
          ),
        ),
      );
    }
  }

  Widget _buildCountdownBadge(String? rawDate) {
    final diff = _daysDiff(rawDate);
    if (diff == null) return const SizedBox.shrink();

    String text;
    Color bg;
    Color fg;

    if (diff == 0) {
      text = '🟢 HÔM NAY';
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF15803D);
    } else if (diff == 1) {
      text = '⏳ NGÀY MAI';
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFFB45309);
    } else if (diff > 1) {
      text = '⏳ Còn $diff ngày';
      bg = const Color(0xFFF1F5F9);
      fg = const Color(0xFF475569);
    } else {
      text = '⚠️ Quá hạn';
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFFDC2626);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildReviewSection(Map<String, dynamic> o) {
    final dynamic dg = o['danhGia'];
    num? diem;
    String? nhanXet;

    if (dg is Map) {
      diem = dg['diemChatLuong'] ?? dg['diemThaiDo'] ?? dg['diem'];
      nhanXet = dg['nhanXet']?.toString();
    } else if (o['diemDanhGia'] != null) {
      diem = num.tryParse(o['diemDanhGia'].toString());
      nhanXet = o['nhanXetDanhGia']?.toString();
    }

    if (diem == null && (nhanXet == null || nhanXet.trim().isEmpty)) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.star_outline_rounded, size: 16, color: AppColors.textMuted),
            SizedBox(width: 6),
            Text(
              'Khách hàng chưa đánh giá ca làm này',
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    final score = (diem ?? 5.0).toDouble().toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star_rounded, size: 18, color: Color(0xFFF59E0B)),
              const SizedBox(width: 4),
              Text(
                'Đánh giá: $score / 5.0',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFB45309),
                ),
              ),
            ],
          ),
          if (nhanXet != null && nhanXet.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '💬 "$nhanXet"',
              style: const TextStyle(
                fontSize: 12.5,
                fontStyle: FontStyle.italic,
                color: Color(0xFF78350F),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> o, String currentTab) {
    final String serviceName = o['tenDichVu'] ?? 'Dịch vụ giúp việc';
    final String customerName = o['khachHangTen'] ?? 'Khách hàng';
    final String address = o['diaChi'] ?? 'Chưa cập nhật địa chỉ';
    final String price = _formatPrice(o['thanhTien']);
    final String rawDate = o['ngayThucHien']?.toString() ?? o['ngayLam']?.toString() ?? '';
    final String dateStr = _fmtDate(rawDate);
    final String timeStr =
        '${_fmtTime(o['gioBatDau']?.toString())} - ${_fmtTime(o['gioKetThuc']?.toString())}';
    final String durationStr = _getDuration(o);
    final String note = o['yeuCauDacBiet']?.toString() ?? o['ghiChu']?.toString() ?? '';
    final String phone = o['khachHangPhone']?.toString() ?? o['soDienThoai']?.toString() ?? '';
    final avatar = _avatarPair(customerName);
    final diff = _daysDiff(rawDate);
    final bool isToday = diff != null && diff == 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. HEADER CỦA CARD
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (currentTab == 'waiting')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.access_time_filled, size: 16, color: _primary),
                            const SizedBox(width: 4),
                            Text(
                              timeStr,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: _primary,
                              ),
                            ),
                          ],
                        ),
                        _buildCountdownBadge(rawDate),
                      ],
                    ),
                  )
                else if (currentTab == 'in_progress')
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_circle_fill_rounded, size: 16, color: Color(0xFF2563EB)),
                        SizedBox(width: 6),
                        Text(
                          'ĐANG THỰC HIỆN TẠI NHÀ KHÁCH',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (currentTab == 'completed')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Đã làm: $dateStr ($timeStr)',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Hoàn thành',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Tên dịch vụ
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
                const SizedBox(height: 6),
                _buildServiceTypeBadge(o),
              ],
            ),
          ),
          const Divider(height: 1),

          // 2. THÔNG TIN CHI TIẾT
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: Column(
              children: [
                if (currentTab == 'new') ...[
                  _infoRow(Icons.calendar_today_outlined, dateStr),
                  _infoRow(Icons.access_time_rounded, '$timeStr (Thời lượng: $durationStr)'),
                  _infoRow(Icons.location_on_outlined, address, maxLines: 2),
                  _directionsRow(o),
                ] else if (currentTab == 'waiting' || currentTab == 'in_progress') ...[
                  _infoRow(Icons.location_on_outlined, address, maxLines: 2),
                  _directionsRow(o),
                  // Thông tin khách hàng + nút gọi điện
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: avatar[0],
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            _initials(customerName),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: avatar[1],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customerName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _ink,
                                ),
                              ),
                              if (phone.isNotEmpty)
                                Text(
                                  phone,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _handlePhoneCall(phone),
                          icon: const Icon(Icons.phone, size: 14),
                          label: const Text('Gọi khách', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (note.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.notes_rounded, size: 16, color: Color(0xFF64748B)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Ghi chú: $note',
                                style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ] else ...[
                  // Tab completed
                  _infoRow(Icons.location_on_outlined, address, maxLines: 2),
                  const SizedBox(height: 4),
                  _buildReviewSection(o),
                  const SizedBox(height: 6),
                ],
              ],
            ),
          ),

          // 3. HÀNG TIỀN CÔNG NẰM Ở ĐÁY CARD (ĐỒNG BỘ 4 BODY)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentTab == 'completed'
                              ? 'Tiền công đã nhận:'
                              : 'Tiền công nhận được:',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          price,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: _money,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified, size: 14, color: Color(0xFF16A34A)),
                        const SizedBox(width: 4),
                        Text(
                          currentTab == 'completed'
                              ? 'Đã thanh toán'
                              : 'Đã trả trước 100%',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. CÁC NÚT THAO TÁC HÀNH ĐỘNG
          if (currentTab == 'new')
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
                          foregroundColor: const Color(0xFF64748B),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Bỏ qua',
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
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: const Text('Nhận việc ngay',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (currentTab == 'waiting')
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final double? lat = LocationService.toDouble(o['viDo'] ?? o['lat']);
                          final double? lng = LocationService.toDouble(o['kinhDo'] ?? o['lng']);
                          _handleMapButton(address, lat: lat, lng: lng);
                        },
                        icon: const Icon(Icons.map_outlined, size: 16),
                        label: const Text(
                          'Xem bản đồ',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primary,
                          side: const BorderSide(color: _primary),
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: () => _handleStartJob(o),
                        icon: Icon(
                          isToday ? Icons.play_arrow_rounded : Icons.lock_outline_rounded,
                          size: 18,
                        ),
                        label: const Text(
                          'Bắt đầu làm',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isToday ? _primary : const Color(0xFF94A3B8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (currentTab == 'in_progress')
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () => _handleAction(o, 'complete'),
                  icon: const Icon(Icons.check_circle_rounded, size: 20),
                  label: const Text(
                    'HOÀN THÀNH CA LÀM',
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13.5,
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

  Future<void> _handleStartJob(Map<String, dynamic> o) async {
    final rawDate = o['ngayThucHien']?.toString() ?? o['ngayLam']?.toString();
    final diff = _daysDiff(rawDate);
    final dateStr = _fmtDate(rawDate ?? '');

    if (diff != null && diff != 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '⚠️ Chưa đến ngày làm việc, bạn chưa thể bắt đầu ca này!\n(Lịch làm: $dateStr)',
          ),
          backgroundColor: AppColors.warning,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    final int phanCongId = o['phanCongId'] ?? o['id'] ?? 0;
    if (phanCongId == 0) {
      _showError('Không tìm thấy ID phân công');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await _apiService.startAssignment(phanCongId);
      if (res.success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('▶️ Đã bắt đầu ca làm việc! Chúc bạn làm việc tốt.'),
            backgroundColor: AppColors.success,
          ),
        );
        await _fetchAllData();
        _tabController.animateTo(2); // Nhảy sang Tab Đang làm
      } else {
        _showError(res.message ?? 'Không thể bắt đầu ca làm');
      }
    } catch (e) {
      _showError('Lỗi kết nối: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAction(Map<String, dynamic> o, String action, {String? lyDo}) async {
    setState(() => _isLoading = true);
    try {
      dynamic res;

      if (action == 'accept') {
        final int donDatId = o['donDatId'] ?? o['id'] ?? 0;
        if (donDatId == 0) {
          _showError('Lỗi: Không tìm thấy ID đơn hàng');
          return;
        }
        res = await _apiService.acceptOrderFromPool(
          donDatId: donDatId,
          congTacVienId: _currentUserId,
        );
      } else if (action == 'reject') {
        final int donDatId = o['donDatId'] ?? o['id'] ?? 0;
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
        final int phanCongId = o['phanCongId'] ?? o['id'] ?? 0;
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
                ? 'Đã nhận việc thành công! Ca làm đã được thêm vào lịch.'
                : (action == 'reject'
                    ? 'Đã bỏ qua. Đơn vẫn hiện cho CTV khác.'
                    : 'Đã hoàn thành công việc! Tiền công đã được cộng vào tài khoản.')),
            backgroundColor:
                action == 'reject' ? AppColors.warning : AppColors.success,
          ),
        );

        if (action == 'accept') {
          await _fetchAllData();
          _tabController.animateTo(1); // Chuyển sang Tab "Chờ làm"
        } else if (action == 'reject') {
          await _refreshPool();
        } else if (action == 'complete') {
          await _fetchAllData();
          _tabController.animateTo(3); // Chuyển sang Tab "Đã xong"
        }
      } else {
        final msg = res?.message ?? 'Thao tác thất bại';
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Thông báo'),
            content: Text(msg),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _refreshPool();
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
    if (newValue.text.startsWith(' ') || newValue.text.startsWith('\n')) {
      final trimmed = newValue.text.trimLeft();
      return newValue.copyWith(
        text: trimmed,
        selection: TextSelection.collapsed(offset: trimmed.length),
      );
    }
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