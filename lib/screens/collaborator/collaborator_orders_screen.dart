import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import '../../services/collaborator_api_service.dart';
import '../../services/app_realtime.dart';
import '../../services/location_service.dart';
import '../../services/ctv_location_tracker.dart';
import '../../widgets/app_time_picker.dart';
import '../../widgets/tai_san_capture_sheet.dart';

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
    CtvLocationTracker.instance.addListener(_onTrackerLocationChanged);
    _loadUserAndFetchData();
    // Được phân công / đơn bị hủy / đơn mới... → tải lại danh sách đơn
    _realtime = AppRealtime.instance.suKien.listen((_) {
      if (mounted) _fetchAllData();
    });

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  void _onTrackerLocationChanged() {
    if (mounted) {
      setState(() {});
      _refreshPoolOnly();
    }
  }

  StreamSubscription<String>? _realtime;

  @override
  void dispose() {
    CtvLocationTracker.instance.removeListener(_onTrackerLocationChanged);
    _realtime?.cancel();
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
      // Quét lại GPS chạy ngầm song song để không làm chậm việc hiển thị danh sách đơn
      unawaited(_syncLocationAndRefreshPool());

      final results = await Future.wait([
        _apiService.getAvailableOrders(congTacVienId: _currentUserId),
        _apiService.getAssignments(congTacVienId: _currentUserId),
      ]);

      final poolRes = results[0] as dynamic;
      final assignRes = results[1] as dynamic;

      if (!mounted) return;
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

  Future<void> _syncLocationAndRefreshPool() async {
    try {
      await CtvLocationTracker.instance.forceSend();
      await _refreshPoolOnly();
    } catch (_) {}
  }

  Future<void> _refreshPoolOnly() async {
    if (_currentUserId == 0 || !mounted) return;
    try {
      final res = await _apiService.getAvailableOrders(congTacVienId: _currentUserId);
      if (mounted && res.success && res.data != null) {
        setState(() => _poolOrders = List<Map<String, dynamic>>.from(res.data!));
      }
    } catch (_) {}
  }

  Future<void> _refreshPool() async {
    await _syncLocationAndRefreshPool();
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

    Widget? locationHeader;
    if (status == 'new') {
      final district = CtvLocationTracker.instance.currentDistrict;
      final bool hasDistrict = district != null && district.trim().isNotEmpty;

      locationHeader = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đang định vị lại khu vực theo GPS...'),
                duration: Duration(milliseconds: 1200),
              ),
            );
            await _syncLocationAndRefreshPool();
            if (!mounted) return;
            final newDist = CtvLocationTracker.instance.currentDistrict;
            if (newDist != null && newDist.isNotEmpty) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Đã cập nhật khu vực nhận việc: $newDist'),
                  backgroundColor: AppColors.green500,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            margin: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _primary.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: hasDistrict
                      ? const Icon(Icons.my_location_rounded, size: 18, color: _primary)
                      : const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: _primary),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(
                              text: 'Khu vực hiện tại: ',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            TextSpan(
                              text: hasDistrict ? district : 'Đang lấy vị trí GPS...',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: hasDistrict ? _primary : const Color(0xFFD97706),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        hasDistrict
                            ? 'Đang tự động lọc các đơn việc mới quanh khu vực này (Chạm để quét lại)'
                            : 'Hệ thống sẽ tự động cập nhật đơn quanh vị trí của bạn',
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
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

    if (filtered.isEmpty) {
      String emptyText;
      switch (status) {
        case 'new':
          emptyText = 'Hiện chưa có công việc mới quanh khu vực của bạn';
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
            if (locationHeader != null) locationHeader,
            SizedBox(height: MediaQuery.of(context).size.height * 0.12),
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
        padding: const EdgeInsets.only(top: 6, bottom: 20),
        itemCount: locationHeader != null ? filtered.length + 1 : filtered.length,
        itemBuilder: (context, index) {
          if (locationHeader != null) {
            if (index == 0) return locationHeader;
            return _buildOrderCard(filtered[index - 1], status);
          }
          return _buildOrderCard(filtered[index], status);
        },
      ),
    );
  }

  Widget _buildCompletedOrderTab(List<Map<String, dynamic>> filtered) {
    num totalIncome = 0;
    for (final o in filtered) {
      totalIncome += _getNetIncome(o);
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
              // 1. Banner tóm tắt đưa lên trên (tính theo 80% thực nhận của CTV)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.history_rounded, size: 19, color: Color(0xFF16A34A)),
                    const SizedBox(width: 6),
                    Text(
                      'Đã xong: ${filtered.length} đơn',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF166534),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Thực nhận (80%): ${_formatPrice(totalIncome)}',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ),
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

  /// Tổng giá trị đơn dịch vụ (100%)
  num _getGrossPrice(Map<String, dynamic> o) {
    return num.tryParse(o['thanhTien']?.toString() ??
            o['tongTienDon']?.toString() ??
            o['tongTien']?.toString() ??
            '') ??
        0;
  }

  /// Chiết khấu chi phí nền tảng (20%)
  num _getPlatformFee(Map<String, dynamic> o) {
    final fromApi = num.tryParse(o['phiNenTang']?.toString() ?? '');
    if (fromApi != null && fromApi > 0) return fromApi.round();
    final gross = _getGrossPrice(o);
    final net = (gross * 0.80).round();
    return gross.round() - net;
  }

  /// Tiền công CTV thực nhận (80% sau khi trừ 20% phí nền tảng)
  num _getNetIncome(Map<String, dynamic> o) {
    final fromApi = num.tryParse(o['tienThucNhan']?.toString() ?? '');
    if (fromApi != null && fromApi > 0) return fromApi.round();
    final gross = _getGrossPrice(o);
    return (gross * 0.80).round();
  }

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

  /// "2026-10-13" → "Thứ 3, 13/10/2026" (ngày thực hiện đơn).
  String _ngayCoThu(String s) {
    final d = DateTime.tryParse(s.length >= 10 ? s.substring(0, 10) : s);
    if (d == null) return _fmtDate(s);
    final thu = d.weekday == DateTime.sunday ? 'Chủ nhật' : 'Thứ ${d.weekday + 1}';
    return '$thu, ${_fmtDate(s)}';
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

  int _parseTimeToMinutes(String? s) {
    if (s == null || s.isEmpty) return 0;
    final parts = s.split(':');
    if (parts.length < 2) return 0;
    return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
  }

  /// Trả về trạng thái thời gian của ca làm:
  /// - 'TOO_EARLY': Chưa đến ngày hoặc cùng ngày nhưng trước giờ hẹn > 30 phút
  /// - 'READY': Trong khung giờ hợp lệ (trước giờ hẹn 30 phút đến hết ca)
  /// - 'OVERDUE': Đã qua ngày hoặc cùng ngày nhưng đã quá giờ kết thúc ca làm
  String _getShiftTimingStatus(Map<String, dynamic> o) {
    final rawDate = o['ngayThucHien']?.toString() ?? o['ngayLam']?.toString();
    final diff = _daysDiff(rawDate);
    if (diff == null) return 'READY';

    if (diff < 0) return 'OVERDUE';
    if (diff > 0) return 'TOO_EARLY';

    // diff == 0: Đúng ngày hôm nay -> xét giờ (LocalTime)
    final String startStr = _fmtTime(o['gioBatDau']?.toString());
    final String endStr = _fmtTime(o['gioKetThuc']?.toString());
    if (startStr.isEmpty) return 'READY';

    final now = DateTime.now();
    final int nowMins = now.hour * 60 + now.minute;
    final int startMins = _parseTimeToMinutes(startStr);
    int endMins = _parseTimeToMinutes(endStr);
    if (endMins <= startMins) {
      endMins = startMins + 120; // Mặc định 2 tiếng nếu không có giờ kết thúc
    }

    final int earlyStartMins = startMins - 30; // Mở nút sớm tối đa 30 phút
    if (nowMins < earlyStartMins) {
      return 'TOO_EARLY';
    } else if (nowMins > endMins) {
      return 'OVERDUE';
    } else {
      return 'READY';
    }
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
    final isBuoiLamBu = o['isBuoiLamBu'] == true;

    if (isPackage) {
      final label = buoiHienTai != null
          ? (isBuoiLamBu
              ? '🔄 Gói tháng - Buổi $buoiHienTai/$soBuoi (Làm bù)'
              : '🔄 Gói tháng - Buổi $buoiHienTai/$soBuoi')
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

  Widget _buildCountdownBadge(Map<String, dynamic> o) {
    final rawDate = o['ngayThucHien']?.toString() ?? o['ngayLam']?.toString();
    final diff = _daysDiff(rawDate);
    if (diff == null) return const SizedBox.shrink();

    final status = _getShiftTimingStatus(o);

    String text;
    Color bg;
    Color fg;

    if (status == 'OVERDUE') {
      text = (diff < 0) ? '⚠️ Quá hạn (${diff.abs()} ngày)' : '⚠️ Quá hạn';
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFFDC2626);
    } else if (status == 'TOO_EARLY') {
      if (diff == 0) {
        text = '⏳ Chưa đến giờ';
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
      } else if (diff == 1) {
        text = '⏳ Ngày mai';
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFB45309);
      } else {
        text = '⏳ Còn $diff ngày';
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF475569);
      }
    } else {
      // READY
      text = '🟢 Đến giờ làm';
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF15803D);
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
    final String price = _formatPrice(_getNetIncome(o));
    final String grossPrice = _formatPrice(_getGrossPrice(o));
    final String feePrice = _formatPrice(_getPlatformFee(o));
    final String rawDate = o['ngayThucHien']?.toString() ?? o['ngayLam']?.toString() ?? '';
    final String dateStr = _fmtDate(rawDate);
    final String timeStr =
        '${_fmtTime(o['gioBatDau']?.toString())} - ${_fmtTime(o['gioKetThuc']?.toString())}';
    final String durationStr = _getDuration(o);
    final String note = o['yeuCauDacBiet']?.toString() ?? o['ghiChu']?.toString() ?? '';
    final String phone = o['khachHangPhone']?.toString() ?? o['soDienThoai']?.toString() ?? '';
    final avatar = _avatarPair(customerName);
    final diff = _daysDiff(rawDate);
    final String timingStatus = _getShiftTimingStatus(o);
    final bool isReady = timingStatus == 'READY';
    final bool isOverdue = timingStatus == 'OVERDUE';

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
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time_filled, size: 16, color: _primary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  // Ngày + giờ thực hiện
                                  dateStr.isNotEmpty ? '$dateStr · $timeStr' : timeStr,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: _primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildCountdownBadge(o),
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
                        Expanded(
                          child: Text(
                            'Đã làm: $dateStr ($timeStr)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
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
                  _infoRow(Icons.calendar_today_outlined, rawDate.isNotEmpty ? _ngayCoThu(rawDate) : dateStr),
                  if (o['maDonDat'] != null && o['maDonDat'].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.tag_rounded, size: 16, color: _primary),
                          const SizedBox(width: 6),
                          Text(
                            'Mã đơn: ${o['maDonDat']}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: _primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  _infoRow(Icons.calendar_today_outlined, dateStr),
                  _infoRow(Icons.access_time_rounded, '$timeStr (Thời lượng: $durationStr)'),
                  if (o['khuVuc'] != null && o['khuVuc'].toString().isNotEmpty)
                    _infoRow(Icons.my_location_rounded, 'Khu vực: ${o['khuVuc']}'),
                  _infoRow(Icons.location_on_outlined, address, maxLines: 4),
                  _directionsRow(o),
                  if (note.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
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
                                'Yêu cầu: $note',
                                style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ] else if (currentTab == 'waiting' || currentTab == 'in_progress') ...[
                  if (rawDate.isNotEmpty)
                    _infoRow(Icons.calendar_today_outlined, 'Ngày làm: ${_ngayCoThu(rawDate)}'),
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
                  TaiSanBeforeAfterSection(orderData: o, compact: true),
                ] else ...[
                  // Tab completed
                  _infoRow(Icons.location_on_outlined, address, maxLines: 2),
                  const SizedBox(height: 4),
                  TaiSanBeforeAfterSection(orderData: o, compact: true),
                  const SizedBox(height: 4),
                  _buildReviewSection(o),
                  const SizedBox(height: 6),
                ],
              ],
            ),
          ),

          // 3. HÀNG TIỀN CÔNG NẰM Ở ĐÁY CARD (ĐỒNG BỘ 4 BODY - TÍNH THEO 80% THỰC NHẬN)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentTab == 'completed'
                                  ? 'Tiền công thực nhận (80%):'
                                  : 'Tiền công bạn nhận (80%):',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                currentTab == 'completed' ? '+$price' : price,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: currentTab == 'completed'
                                      ? const Color(0xFF15803D)
                                      : _money,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
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
                                  ? 'Đã cộng vào ví'
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
                  const SizedBox(height: 4),
                  Text(
                    'Tổng đơn: $grossPrice • Chiết khấu nền tảng (20%): -$feePrice',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
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
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Xem bản đồ',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                          ),
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
                          isReady
                              ? Icons.play_arrow_rounded
                              : (isOverdue
                                  ? Icons.warning_amber_rounded
                                  : Icons.lock_outline_rounded),
                          size: 18,
                        ),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            isReady
                                ? 'Bắt đầu làm'
                                : (isOverdue
                                    ? 'Xử lý quá hạn'
                                    : (diff != null && diff > 0 ? 'Chưa đến ngày' : 'Chưa đến giờ')),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isReady
                              ? _primary
                              : (isOverdue
                                  ? const Color(0xFFEA580C)
                                  : const Color(0xFF94A3B8)),
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
                  onPressed: () => _showCompleteConfirmModal(o),
                  icon: const Icon(Icons.check_circle_rounded, size: 20),
                  label: const Text(
                    'XÁC NHẬN HOÀN THÀNH',
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
    final startStr = _fmtTime(o['gioBatDau']?.toString());
    final status = _getShiftTimingStatus(o);

    // TH1: Chưa đến ngày làm hoặc chưa đến giờ (TOO_EARLY)
    if (status == 'TOO_EARLY') {
      if (diff != null && diff > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '⚠️ Chưa đến ngày làm việc, bạn chưa thể bắt đầu ca này!\n(Lịch hẹn: $dateStr — còn $diff ngày nữa)',
            ),
            backgroundColor: AppColors.warning,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        String earlyStr = '';
        if (startStr.isNotEmpty) {
          final parts = startStr.split(':');
          if (parts.length >= 2) {
            final int sM = (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
            final int eM = (sM - 30).clamp(0, 23 * 60 + 59);
            final h = (eM ~/ 60).toString().padLeft(2, '0');
            final m = (eM % 60).toString().padLeft(2, '0');
            earlyStr = ' (bạn chỉ có thể bắt đầu từ $h:$m trở đi)';
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '⚠️ Chưa đến giờ làm việc! Ca làm bắt đầu lúc $startStr$earlyStr.',
            ),
            backgroundColor: AppColors.warning,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // TH2: Đã quá hạn (OVERDUE) -> Mở hộp thoại xử lý ca quá hạn
    if (status == 'OVERDUE') {
      final int overdueDays = (diff != null && diff < 0) ? diff.abs() : 0;
      await _showOverdueResolutionModal(o, overdueDays);
      return;
    }

    // TH3: Đúng khung giờ làm việc (READY) -> Yêu cầu chụp ảnh tài sản trước khi thực hiện dịch vụ
    final int phanCongId = o['phanCongId'] ?? o['id'] ?? 0;
    if (phanCongId == 0) {
      _showError('Không tìm thấy ID phân công');
      return;
    }

    final TaiSanCaptureResult? captureBefore = await TaiSanCaptureSheet.show(
      context,
      isBeforeService: true,
      maDon: (o['maDonDat'] ?? 'N/A').toString(),
      tenDichVu: (o['tenDichVu'] ?? 'Dịch vụ giúp việc').toString(),
      diaChi: (o['diaChi'] ?? '').toString(),
    );

    if (!mounted) return;
    if (captureBefore == null || captureBefore.danhSachHinhAnh.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '⚠️ Bạn cần chụp và gửi ảnh hiện trạng tài sản khu vực thực hiện trước khi bắt đầu dịch vụ!',
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await _apiService.startAssignment(
        phanCongId,
        danhSachHinhAnh: captureBefore.danhSachHinhAnh,
        khuVucVatDung: captureBefore.khuVucVatDung,
        moTaHienTrang: captureBefore.moTaHienTrang,
        ghiChuTaiSan: captureBefore.ghiChuTaiSan,
      );
      if (res.success) {
        o['anhTruocDichVu'] = captureBefore.danhSachHinhAnh;
        o['daChupTruocDichVu'] = true;
        o['thoiGianChupTruoc'] =
            DateFormat('HH:mm dd/MM/yyyy').format(DateTime.now());
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '▶️ Đã gửi ảnh tài sản trước khi làm và bắt đầu thực hiện dịch vụ!',
            ),
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

  Future<void> _showOverdueResolutionModal(
    Map<String, dynamic> o,
    int overdueDays,
  ) async {
    final int phanCongId = o['phanCongId'] ?? o['id'] ?? 0;
    if (phanCongId == 0) {
      _showError('Không tìm thấy ID phân công');
      return;
    }

    // Lấy danh sách lịch làm việc hiện tại của CTV để kiểm tra trùng ca Sáng/Chiều trực tiếp
    List<Map<String, dynamic>> ctvSchedules = [];
    try {
      final schedRes = await _apiService.getSchedules(congTacVienId: _currentUserId);
      if (schedRes.success && schedRes.data != null) {
        ctvSchedules = List<Map<String, dynamic>>.from(schedRes.data!);
      }
    } catch (_) {}
    if (!mounted) return;

    final int? targetLlvId = int.tryParse(o['lichLamViecId']?.toString() ?? '');
    final bool isGoiThang = _isGoiThang(o);
    final int soBuoi = int.tryParse(o['soBuoi']?.toString() ?? '') ?? (isGoiThang ? 8 : 1);
    final int buoiThu = int.tryParse(o['buoiThu']?.toString() ?? '') ?? 1;

    final String serviceName = o['tenDichVu'] ?? 'Dịch vụ giúp việc';
    final String customerName = o['khachHangTen'] ?? 'Khách hàng';
    final String phone =
        o['khachHangPhone']?.toString() ?? o['soDienThoai']?.toString() ?? '';
    final String rawDate =
        o['ngayThucHien']?.toString() ?? o['ngayLam']?.toString() ?? '';
    final String oldDateStr = _fmtDate(rawDate);

    final String origStartStr = _fmtTime(o['gioBatDau']?.toString()).isNotEmpty
        ? _fmtTime(o['gioBatDau']?.toString())
        : '08:00';
    final String origEndStr = _fmtTime(o['gioKetThuc']?.toString()).isNotEmpty
        ? _fmtTime(o['gioKetThuc']?.toString())
        : '10:00';

    int parseMinutes(String hhmm) {
      final parts = hhmm.split(':');
      if (parts.length < 2) return 480;
      return (int.tryParse(parts[0]) ?? 8) * 60 + (int.tryParse(parts[1]) ?? 0);
    }

    String formatMinutes(int totalMins) {
      final clamped = totalMins.clamp(0, 23 * 60 + 59);
      final h = (clamped ~/ 60).toString().padLeft(2, '0');
      final m = (clamped % 60).toString().padLeft(2, '0');
      return '$h:$m';
    }

    final int origStartMins = parseMinutes(origStartStr);
    final int origEndMins = parseMinutes(origEndStr);
    final int durationMins = (origEndMins > origStartMins) ? (origEndMins - origStartMins) : 120;

    int selectedStartMins = origStartMins;
    final String timeStr = '$origStartStr - $origEndStr';
    final now = DateTime.now();
    final DateTime todayDate = DateTime(now.year, now.month, now.day);
    final String todayStr = DateFormat('dd/MM/yyyy').format(todayDate);

    // Thu thập các buổi khác trong cùng đơn gói tháng để kiểm tra trùng ngày và tìm buổi cuối cùng
    final Map<String, Map<String, dynamic>> packageSessionDates = {};
    DateTime? lastSessionDate;
    if (isGoiThang) {
      for (final s in ctvSchedules) {
        final bool isSameOrder = (s['donDatId'] != null && o['donDatId'] != null && s['donDatId'].toString() == o['donDatId'].toString());
        if (isSameOrder) {
          final int? sId = int.tryParse((s['lichLamViecId'] ?? s['id'])?.toString() ?? '');
          if (targetLlvId != null && sId == targetLlvId) continue;
          final String st = (s['trangThai'] ?? '').toString().toLowerCase();
          if (st == 'dahuy' || st == 'huy') continue;
          final String rawDate = (s['ngayLam'] ?? s['ngayThucHien'] ?? '').toString();
          if (rawDate.length >= 10) {
            final String iso = rawDate.substring(0, 10);
            packageSessionDates[iso] = s;
            final DateTime? parsedD = DateTime.tryParse(iso);
            if (parsedD != null) {
              if (lastSessionDate == null || parsedD.isAfter(lastSessionDate)) {
                lastSessionDate = parsedD;
              }
            }
          }
        }
      }
    }

    // Ngày gợi ý làm bù sau buổi cuối cùng của gói: tìm ngày theo chu kỳ tuần kế tiếp sau buổi cuối
    DateTime? suggestedEndOfPackageDate;
    if (isGoiThang && lastSessionDate != null) {
      final packageWeekdays = <int>{};
      for (final iso in packageSessionDates.keys) {
        final d = DateTime.tryParse(iso);
        if (d != null) packageWeekdays.add(d.weekday);
      }
      if (packageWeekdays.isNotEmpty) {
        DateTime cur = lastSessionDate.add(const Duration(days: 1));
        for (int i = 0; i < 14; i++) {
          if (packageWeekdays.contains(cur.weekday)) {
            suggestedEndOfPackageDate = cur;
            break;
          }
          cur = cur.add(const Duration(days: 1));
        }
      }
      suggestedEndOfPackageDate ??= lastSessionDate.add(const Duration(days: 3));
    }
    final String? endOfPackageFmt = suggestedEndOfPackageDate != null
        ? DateFormat('dd/MM/yyyy').format(suggestedEndOfPackageDate)
        : null;

    // Lịch cho chọn từ hôm nay đến +90 ngày (không cho dời về ngày đã qua)
    final DateTime pickerFirstDate = todayDate;
    final DateTime pickerLastDate = todayDate.add(const Duration(days: 90));

    // Mặc định chọn ngày làm bù: gợi ý sau buổi cuối cùng của gói (nếu có), hoặc ngày mai
    DateTime pickedNewDate = suggestedEndOfPackageDate ?? todayDate.add(const Duration(days: 1));
    if (pickedNewDate.isBefore(pickerFirstDate)) {
      pickedNewDate = pickerFirstDate;
    }

    // Hàm lấy danh sách ca làm trong ngày bất kỳ để kiểm tra trùng lịch
    List<Map<String, dynamic>> getShiftsForIsoDate(String isoDate) {
      final List<Map<String, dynamic>> list = [];
      final Set<String> seenKeys = {};
      for (final s in ctvSchedules) {
        final int? sId = int.tryParse((s['lichLamViecId'] ?? s['id'])?.toString() ?? '');
        if (targetLlvId != null && sId == targetLlvId) continue;
        if (targetLlvId == null &&
            (s['phanCongId']?.toString() == phanCongId.toString())) {
          continue;
        }
        final String st = (s['trangThai'] ?? '').toString().toLowerCase();
        if (st == 'dahuy' || st == 'huy') continue;
        final String pcSt = (s['trangThaiPhanCong'] ?? '').toString().toLowerCase();
        if (pcSt == 'tuchoi') continue;
        final String sDate = (s['ngayLam'] ?? s['ngayThucHien'] ?? '').toString();
        if (sDate.startsWith(isoDate)) {
          final key = '${s['donDatId'] ?? sId}_${_fmtTime(s['gioBatDau']?.toString())}';
          seenKeys.add(key);
          list.add(s);
        }
      }
      for (final a in _allAssignments) {
        final int aPcId = a['phanCongId'] ?? a['id'] ?? 0;
        if (aPcId == phanCongId) continue;
        final String pcSt = (a['trangThaiPhanCong'] ?? '').toString().toLowerCase();
        final String donSt = (a['trangThaiDon'] ?? a['trangThai'] ?? '').toString().toLowerCase();
        if (pcSt == 'tuchoi' || donSt == 'dahuy' || donSt == 'huy') continue;
        final String aDate = (a['ngayThucHien'] ?? a['ngayLam'] ?? '').toString();
        if (aDate.startsWith(isoDate)) {
          final key = '${a['donDatId'] ?? aPcId}_${_fmtTime(a['gioBatDau']?.toString())}';
          if (!seenKeys.contains(key)) {
            seenKeys.add(key);
            list.add(a);
          }
        }
      }
      return list;
    }

    bool checkSlotConflict(List<Map<String, dynamic>> shifts, int startMins, int durMins) {
      final endMins = startMins + durMins;
      for (final s in shifts) {
        final int exStart = parseMinutes(_fmtTime(s['gioBatDau']?.toString()));
        final int exEnd = parseMinutes(_fmtTime(s['gioKetThuc']?.toString()));
        if (startMins < exEnd && exStart < endMins) {
          return true;
        }
      }
      return false;
    }

    final String todayIso = DateFormat('yyyy-MM-dd').format(todayDate);
    final List<Map<String, dynamic>> shiftsOnToday = getShiftsForIsoDate(todayIso);

    final bool origBusyToday = checkSlotConflict(shiftsOnToday, origStartMins, durationMins);
    final bool morningBusyToday = checkSlotConflict(shiftsOnToday, 8 * 60, durationMins) ||
        (origStartMins < 12 * 60 && origBusyToday);
    final bool afternoonBusyToday = checkSlotConflict(shiftsOnToday, 14 * 60, durationMins);
    final bool bothSlotsBusyToday = morningBusyToday && afternoonBusyToday;

    final int nowMins = now.hour * 60 + now.minute;
    final bool isLateNight = now.hour >= 21 || (nowMins + durationMins > 24 * 60);

    // Thiết lập hành động mặc định và khung giờ phù hợp
    String selectedAction = 'START_TODAY';
    if (isLateNight) {
      selectedAction = 'RESCHEDULE_KEEP';
    } else if (isGoiThang) {
      if (bothSlotsBusyToday) {
        // Cả sáng và chiều hôm nay đều bận -> tự động chuyển sang Phương án 2 (Dời sang buổi cuối)
        selectedAction = 'RESCHEDULE_KEEP';
      } else if (morningBusyToday && !afternoonBusyToday) {
        // Sáng trùng lịch nhưng chiều rảnh -> tự động chuyển sang ca chiều (14:00)
        selectedStartMins = 14 * 60;
        selectedAction = 'START_TODAY';
      } else if (!morningBusyToday && afternoonBusyToday && origStartMins >= 12 * 60) {
        selectedStartMins = 8 * 60;
        selectedAction = 'START_TODAY';
      }
    }
    // Nếu chọn làm bù hôm nay mà giờ bắt đầu đang nhỏ hơn giờ hiện tại -> tự động tăng lên mốc 15 phút kế tiếp
    if (!isLateNight && selectedAction == 'START_TODAY' && selectedStartMins < nowMins) {
      selectedStartMins = ((nowMins + 15) ~/ 15) * 15;
      if (selectedStartMins + durationMins > 24 * 60) {
        selectedAction = 'RESCHEDULE_KEEP';
      }
    }

    bool customerAgreed = false;
    final TextEditingController noteCtrl = TextEditingController();
    String? modalError;
    bool isSubmitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final bool needsDatePicker =
                selectedAction == 'RESCHEDULE_KEEP' ||
                selectedAction == 'RESCHEDULE_RELEASE';
            final bool usesTargetSlot =
                selectedAction == 'START_TODAY' ||
                selectedAction == 'RESCHEDULE_KEEP';

            final DateTime activeTargetDate =
                selectedAction == 'START_TODAY' ? todayDate : pickedNewDate;
            final String activeTargetIso =
                DateFormat('yyyy-MM-dd').format(activeTargetDate);
            final String activeTargetFmt =
                DateFormat('dd/MM/yyyy').format(activeTargetDate);
            final String newDateFmt = DateFormat('dd/MM/yyyy').format(pickedNewDate);
            final String newDateIso = DateFormat('yyyy-MM-dd').format(pickedNewDate);

            final int selectedEndMins = selectedStartMins + durationMins;
            final String selectedStartStr = formatMinutes(selectedStartMins);
            final String selectedEndStr = formatMinutes(selectedEndMins);

            final List<Map<String, dynamic>> shiftsOnTargetDate =
                getShiftsForIsoDate(activeTargetIso);
            final List<Map<String, dynamic>> shiftsOnToday =
                getShiftsForIsoDate(todayIso);

            Map<String, dynamic>? conflictingShiftToday;
            for (final s in shiftsOnToday) {
              final int exStart = parseMinutes(_fmtTime(s['gioBatDau']?.toString()));
              final int exEnd = parseMinutes(_fmtTime(s['gioKetThuc']?.toString()));
              if (selectedStartMins < exEnd && exStart < selectedEndMins) {
                conflictingShiftToday = s;
                break;
              }
            }

            // Kiểm tra trùng khung giờ [selectedStartMins, selectedEndMins] trên ngày đang chọn
            Map<String, dynamic>? conflictingShift;
            for (final s in shiftsOnTargetDate) {
              final int exStart = parseMinutes(_fmtTime(s['gioBatDau']?.toString()));
              final int exEnd = parseMinutes(_fmtTime(s['gioKetThuc']?.toString()));
              final bool isSameOrder = (s['donDatId'] != null && o['donDatId'] != null && s['donDatId'].toString() == o['donDatId'].toString());
              if (selectedAction == 'START_TODAY' || selectedAction == 'RESCHEDULE_KEEP' || isSameOrder) {
                if (selectedStartMins < exEnd && exStart < selectedEndMins) {
                  conflictingShift = s;
                  break;
                }
              }
            }

            // Kiểm tra trùng ngày với bất kỳ buổi nào khác trong cùng đơn gói tháng
            String? packageOrderWarning;
            if (isGoiThang && packageSessionDates.containsKey(activeTargetIso)) {
              final sConf = packageSessionDates[activeTargetIso]!;
              final String sStart = _fmtTime(sConf['gioBatDau']?.toString());
              final String sEnd = _fmtTime(sConf['gioKetThuc']?.toString());
              final String bCode = (sConf['maLichLamViec'] != null && sConf['maLichLamViec'].toString().isNotEmpty)
                  ? ' (${sConf['maLichLamViec']})'
                  : '';
              packageOrderWarning =
                  'Ngày $activeTargetFmt đã có ca$bCode từ $sStart - $sEnd trong gói này! Vui lòng chọn ngày khác chưa có lịch hoặc bấm "Bù sau buổi cuối".';
            }

            Widget buildOptionTile({
              required String value,
              required IconData icon,
              required Color color,
              required String title,
              required String subtitle,
              bool enabled = true,
              String? disabledReason,
            }) {
              final bool selected = selectedAction == value;
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: enabled
                    ? () {
                        setModalState(() {
                          selectedAction = value;
                          modalError = null;
                        });
                      }
                    : () {
                        if (disabledReason != null) {
                          setModalState(() {
                            modalError = disabledReason;
                          });
                        }
                      },
                child: Opacity(
                  opacity: enabled ? 1.0 : 0.6,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: selected
                          ? color.withValues(alpha: 0.08)
                          : (enabled ? const Color(0xFFF8FAFC) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? color : const Color(0xFFE2E8F0),
                        width: selected ? 1.6 : 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          selected
                              ? Icons.radio_button_checked_rounded
                              : (enabled ? Icons.radio_button_off_rounded : Icons.block_rounded),
                          color: selected ? color : const Color(0xFF94A3B8),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(icon, size: 16, color: color),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        color: selected ? color : (enabled ? _ink : AppColors.textSecondary),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                subtitle,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  height: 1.3,
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

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.90,
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 14,
                bottom: MediaQuery.of(context).viewInsets.bottom + 18,
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
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFDC2626),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                overdueDays > 0
                                    ? (isGoiThang
                                        ? 'Ca quá hạn $overdueDays ngày (Buổi $buoiThu/$soBuoi)'
                                        : 'Ca làm đã quá hạn $overdueDays ngày')
                                    : (isGoiThang
                                        ? 'Ca làm quá hạn hôm nay (Buổi $buoiThu/$soBuoi)'
                                        : 'Ca làm đã quá hạn hôm nay'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: _ink,
                                ),
                              ),
                              Text(
                                'Lịch cũ: $oldDateStr ($timeStr) • Hôm nay: $todayStr',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFDC2626),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Thông báo hướng dẫn dời lịch cho Đơn Gói Tháng
                    if (isGoiThang) ...[
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFF59E0B)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.event_repeat_rounded,
                                size: 18, color: Color(0xFFB45309)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                lastSessionDate != null
                                    ? '🔄 Gói tháng (Buổi $buoiThu/$soBuoi): Khách có thể dời bù vào ngày trống giữa các buổi, hoặc chọn làm bù sau buổi cuối cùng của gói (sau ngày ${DateFormat('dd/MM/yyyy').format(lastSessionDate)}).'
                                    : '🔄 Gói tháng (Buổi $buoiThu/$soBuoi): Vui lòng chọn ngày chưa vướng lịch của các buổi khác trong gói.',
                                style: const TextStyle(
                                  fontSize: 11.8,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF92400E),
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '📌 Dịch vụ: $serviceName',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF92400E),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Ca làm này đã qua ngày hẹn ban đầu. Vui lòng gọi điện trao đổi với Khách hàng trước khi cập nhật lịch hoặc trả đơn:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF78350F),
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _handlePhoneCall(phone),
                              icon: const Icon(Icons.phone_in_talk_rounded, size: 16),
                              label: Text(
                                phone.isNotEmpty
                                    ? 'Gọi khách hàng: $customerName ($phone)'
                                    : 'Gọi khách hàng: $customerName',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Checkbox xác nhận đã gọi khách
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        setModalState(() {
                          customerAgreed = !customerAgreed;
                          modalError = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: customerAgreed
                              ? const Color(0xFFECFDF5)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: customerAgreed
                                ? const Color(0xFF10B981)
                                : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: customerAgreed,
                              activeColor: const Color(0xFF10B981),
                              visualDensity: VisualDensity.compact,
                              onChanged: (val) {
                                setModalState(() {
                                  customerAgreed = val ?? false;
                                  modalError = null;
                                });
                              },
                            ),
                            const Expanded(
                              child: Text(
                                'Tôi xác nhận đã liên hệ và được Khách hàng đồng ý với phương án bên dưới',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: _ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isGoiThang) ...[
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF93C5FD)),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.shield_rounded, size: 18, color: Color(0xFF1D4ED8)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '🛡️ Quy định Đơn Gói: 1 CTV đồng hành trọn vẹn toàn bộ các buổi trong gói để kiểm soát chất lượng dịch vụ. Chỉ áp dụng Làm bù hôm nay hoặc Dời ngày làm bù (không tách lẻ ca cho người khác hoặc hủy ngang).',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E40AF),
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const Text(
                      'Chọn hướng xử lý theo ý kiến Khách hàng:',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    buildOptionTile(
                      value: 'START_TODAY',
                      icon: Icons.play_circle_fill_rounded,
                      color: isLateNight
                          ? const Color(0xFFDC2626)
                          : ((isGoiThang && bothSlotsBusyToday)
                              ? const Color(0xFFDC2626)
                              : (conflictingShiftToday != null
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF16A34A))),
                      title: '1. Làm bù NGAY HÔM NAY ($todayStr)',
                      enabled: !isLateNight && !(isGoiThang && bothSlotsBusyToday),
                      disabledReason: isLateNight
                          ? '⚠️ Đã quá muộn trong ngày (${DateFormat('HH:mm').format(now)}), không còn khung giờ phù hợp để dọn dẹp hôm nay! Vui lòng chọn Phương án 2 để dời sang ngày làm bù.'
                          : '⚠️ Hôm nay ($todayStr) bạn đã kín cả ca sáng lẫn ca chiều! Vui lòng chọn Phương án 2 để dời sang ngày làm bù sau buổi cuối.',
                      subtitle: isLateNight
                          ? '⚠️ Đã quá muộn trong ngày (${DateFormat('HH:mm').format(now)}). Hệ thống tự động chuyển sang Phương án 2 (Dời sang ngày làm bù) để đảm bảo chất lượng dịch vụ!'
                          : ((isGoiThang && bothSlotsBusyToday)
                              ? '⚠️ Hôm nay ($todayStr) bạn đã kín cả ca sáng và ca chiều. Hệ thống đã tự động chuyển sang Phương án 2 (Dời ngày làm bù sau buổi cuối)!'
                              : (isGoiThang && (morningBusyToday || origBusyToday) && !afternoonBusyToday)
                                  ? '💡 Ca sáng hôm nay của bạn trùng lịch đơn khác ➔ Hệ thống đã tự động chuyển sang làm bù vào Ca chiều (14:00 - ${formatMinutes(14 * 60 + durationMins)}) hôm nay!'
                                  : (conflictingShiftToday != null
                                      ? '⚠️ Lịch hôm nay ($todayStr) của bạn đang trùng ca ${_fmtTime(conflictingShiftToday['gioBatDau']?.toString())}-${_fmtTime(conflictingShiftToday['gioKetThuc']?.toString())} (${conflictingShiftToday['maDonDat'] ?? 'Đơn khác'})! Dù khách rảnh nhưng lịch bạn trùng → Vui lòng chọn Phương án 2 (Dời ngày) hoặc đổi sang ca Sáng/Chiều trống.'
                                      : 'Khách đồng ý làm hôm nay → Hệ thống kiểm tra khung giờ trống hôm nay ($todayStr) và bắt đầu tính giờ làm ngay.')),
                    ),
                    buildOptionTile(
                      value: 'RESCHEDULE_KEEP',
                      icon: Icons.edit_calendar_rounded,
                      color: _primary,
                      title: isGoiThang
                          ? '2. Dời sang ngày làm bù (Tôi vẫn nhận làm trọn gói)'
                          : '2. Dời sang ngày mới (Tôi vẫn nhận làm)',
                      subtitle: isGoiThang
                          ? (endOfPackageFmt != null
                              ? 'Làm bù sau buổi cuối cùng của gói (Gợi ý: $endOfPackageFmt). Đảm bảo hoàn thành trọn vẹn toàn bộ gói.'
                              : 'Khách hẹn dời sang ngày khác chưa có lịch của gói. Có thể chèn vào buổi Sáng hoặc Chiều.')
                          : 'Khách hẹn sang ngày khác (trước buổi kế tiếp nếu là gói tháng). Có thể chèn vào buổi Sáng hoặc Chiều còn trống.',
                    ),
                    if (!isGoiThang) ...[
                      buildOptionTile(
                        value: 'RESCHEDULE_RELEASE',
                        icon: Icons.person_search_rounded,
                        color: const Color(0xFFEA580C),
                        title: '3. Dời sang ngày mới (Tôi bận — Tìm CTV khác)',
                        subtitle:
                            'Cập nhật ngày thực hiện mới theo ý khách và trả đơn về trạng thái "Đang tìm CTV" để người khác nhận.',
                      ),
                      buildOptionTile(
                        value: 'CANCEL_ORDER',
                        icon: Icons.cancel_outlined,
                        color: const Color(0xFFDC2626),
                        title: '4. Khách không còn nhu cầu (Hủy đơn này)',
                        subtitle:
                            'Khách xác nhận hủy vì đã qua ngày hẹn → Kiểm tra trạng thái ca và chuyển đơn sang Đã hủy.',
                      ),
                    ],

                    if (needsDatePicker) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_month_rounded,
                              color: Color(0xFF2563EB),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isGoiThang
                                        ? 'Ngày làm bù khách chọn:'
                                        : 'Ngày thực hiện mới khách chọn:',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF1E40AF),
                                    ),
                                  ),
                                  Text(
                                    newDateFmt,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1D4ED8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () async {
                                final DateTime safeInit = pickedNewDate.isAfter(pickerLastDate)
                                    ? pickerLastDate
                                    : (pickedNewDate.isBefore(pickerFirstDate) ? pickerFirstDate : pickedNewDate);
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: safeInit,
                                  firstDate: pickerFirstDate,
                                  lastDate: pickerLastDate,
                                );
                                if (picked != null) {
                                  setModalState(() {
                                    pickedNewDate = picked;
                                    modalError = null;
                                  });
                                }
                              },
                              icon: const Icon(Icons.edit_rounded, size: 15),
                              label: const Text('Đổi ngày'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF1D4ED8),
                                side: const BorderSide(color: Color(0xFF93C5FD)),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isGoiThang && suggestedEndOfPackageDate != null) ...[
                        const SizedBox(height: 6),
                        ActionChip(
                          avatar: const Icon(Icons.event_repeat_rounded,
                              size: 15, color: Color(0xFF1D4ED8)),
                          backgroundColor: pickedNewDate.isAtSameMomentAs(suggestedEndOfPackageDate)
                              ? const Color(0xFFDBEAFE)
                              : const Color(0xFFEFF6FF),
                          side: const BorderSide(color: Color(0xFF93C5FD)),
                          label: Text(
                            '📅 Bù sau buổi cuối ($endOfPackageFmt)',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1D4ED8),
                            ),
                          ),
                          onPressed: () {
                            setModalState(() {
                              pickedNewDate = suggestedEndOfPackageDate!;
                              modalError = null;
                            });
                          },
                        ),
                      ],
                      if (packageOrderWarning != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFCA5A5)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  size: 16, color: Color(0xFFDC2626)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  packageOrderWarning,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFDC2626),
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],

                    // Bộ chọn Khung giờ làm bù (Sáng / Chiều) & Kiểm tra trùng lịch trực tiếp
                    if (usesTargetSlot) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (conflictingShift != null || packageOrderWarning != null)
                              ? const Color(0xFFFEF2F2)
                              : const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: (conflictingShift != null || packageOrderWarning != null)
                                ? const Color(0xFFFCA5A5)
                                : const Color(0xFF86EFAC),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time_filled_rounded,
                                  size: 18,
                                  color: (conflictingShift != null || packageOrderWarning != null)
                                      ? const Color(0xFFDC2626)
                                      : const Color(0xFF15803D),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Khung giờ làm ngày $activeTargetFmt: $selectedStartStr - $selectedEndStr',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: (conflictingShift != null || packageOrderWarning != null)
                                          ? const Color(0xFFB91C1C)
                                          : const Color(0xFF166534),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Nút đổi nhanh ca Sáng / ca Chiều hoặc chọn giờ bất kỳ
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                if (selectedAction != 'START_TODAY' || origStartMins >= nowMins)
                                  ActionChip(
                                    visualDensity: VisualDensity.compact,
                                    backgroundColor: selectedStartMins == origStartMins
                                        ? const Color(0xFFDBEAFE)
                                        : Colors.white,
                                    label: Text(
                                      'Giờ gốc ($origStartStr)',
                                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                                    ),
                                    onPressed: () => setModalState(() {
                                      selectedStartMins = origStartMins;
                                      modalError = null;
                                    }),
                                  ),
                                if (selectedAction != 'START_TODAY' || 8 * 60 >= nowMins)
                                  ActionChip(
                                    visualDensity: VisualDensity.compact,
                                    backgroundColor: selectedStartMins == 8 * 60
                                        ? const Color(0xFFDBEAFE)
                                        : Colors.white,
                                    label: const Text(
                                      '☀️ Ca sáng (08:00)',
                                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                                    ),
                                    onPressed: () => setModalState(() {
                                      selectedStartMins = 8 * 60;
                                      modalError = null;
                                    }),
                                  ),
                                if (selectedAction != 'START_TODAY' || 14 * 60 >= nowMins)
                                  ActionChip(
                                    visualDensity: VisualDensity.compact,
                                    backgroundColor: selectedStartMins == 14 * 60
                                        ? const Color(0xFFDBEAFE)
                                        : Colors.white,
                                    label: const Text(
                                      '🌤️ Ca chiều (14:00)',
                                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                                    ),
                                    onPressed: () => setModalState(() {
                                      selectedStartMins = 14 * 60;
                                      modalError = null;
                                    }),
                                  ),
                                ActionChip(
                                  visualDensity: VisualDensity.compact,
                                  avatar: const Icon(Icons.schedule_rounded, size: 14),
                                  label: const Text(
                                    'Chọn giờ khác',
                                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                                  ),
                                  onPressed: () async {
                                    final pickedTime = await showAppTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay(
                                        hour: selectedStartMins ~/ 60,
                                        minute: selectedStartMins % 60,
                                      ),
                                      title: 'Chọn giờ bắt đầu ca làm',
                                    );
                                    if (pickedTime != null) {
                                      setModalState(() {
                                        selectedStartMins = pickedTime.hour * 60 + pickedTime.minute;
                                        modalError = null;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            if (shiftsOnTargetDate.isNotEmpty) ...[
                              Text(
                                '📅 Các ca đã có trong ngày $activeTargetFmt: ${shiftsOnTargetDate.map((s) => '${_fmtTime(s['gioBatDau']?.toString())}-${_fmtTime(s['gioKetThuc']?.toString())} (${s['maDonDat'] ?? 'Ca làm'})').join(', ')}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF475569),
                                ),
                              ),
                              const SizedBox(height: 4),
                            ],
                            if (packageOrderWarning != null)
                              Text(
                                '⚠️ $packageOrderWarning',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFDC2626),
                                ),
                              )
                            else if (conflictingShift != null)
                              Text(
                                selectedAction == 'START_TODAY'
                                    ? '⚠️ Lịch hôm nay ($todayStr) của bạn bị trùng với ca ${_fmtTime(conflictingShift['gioBatDau']?.toString())} - ${_fmtTime(conflictingShift['gioKetThuc']?.toString())} (${conflictingShift['maDonDat'] ?? ''})! '
                                      'Dù khách rảnh nhưng lịch bạn trùng → Vui lòng chọn Phương án 2 (Dời sang ngày mới) hoặc đổi sang "Ca sáng (08:00)" / "Ca chiều (14:00)" còn trống.'
                                    : '⚠️ Trùng giờ với ca ${_fmtTime(conflictingShift['gioBatDau']?.toString())} - ${_fmtTime(conflictingShift['gioKetThuc']?.toString())} (${conflictingShift['maDonDat'] ?? ''})! '
                                      'Hãy bấm chọn "Ca sáng (08:00)" hoặc "Ca chiều (14:00)" còn trống, hoặc đổi sang ngày khác.',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFDC2626),
                                ),
                              )
                            else
                              Text(
                                shiftsOnTargetDate.isEmpty
                                    ? '✅ Ngày $activeTargetFmt chưa vướng lịch nào, có thể xếp ca $selectedStartStr - $selectedEndStr.'
                                    : '✅ Khung giờ $selectedStartStr - $selectedEndStr không trùng với các ca khác trong ngày $activeTargetFmt (có thể chèn ca Sáng/Chiều)!',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),
                    TextField(
                      controller: noteCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Ghi chú / lý do trao đổi với khách (tùy chọn)...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12.5,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.all(10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),

                    if (modalError != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Text(
                          modalError!,
                          style: const TextStyle(
                            color: Color(0xFFDC2626),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: OutlinedButton(
                              onPressed: isSubmitting
                                  ? null
                                  : () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textSecondary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('Đóng'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 44,
                            child: ElevatedButton(
                              onPressed: isSubmitting
                                  ? null
                                  : () async {
                                      if (!customerAgreed) {
                                        setModalState(() {
                                          modalError =
                                              '⚠️ Vui lòng gọi điện và tích xác nhận đã được Khách hàng đồng ý trước!';
                                        });
                                        return;
                                      }
                                      if (selectedAction == 'START_TODAY' && isLateNight) {
                                        setModalState(() {
                                          modalError =
                                              '⚠️ Đã quá muộn trong ngày (${DateFormat('HH:mm').format(now)}), không thể làm bù hôm nay! Vui lòng chọn Phương án 2 (Dời sang ngày mới).';
                                        });
                                        return;
                                      }
                                      if (selectedAction == 'START_TODAY' && selectedStartMins < nowMins) {
                                        setModalState(() {
                                          modalError =
                                              '⚠️ Giờ làm bù hôm nay (${formatMinutes(selectedStartMins)}) không được ở trong quá khứ so với hiện tại (${DateFormat('HH:mm').format(now)})!';
                                        });
                                        return;
                                      }
                                      if (isGoiThang && selectedAction == 'START_TODAY' && bothSlotsBusyToday) {
                                        setModalState(() {
                                          modalError =
                                              '⚠️ Hôm nay ($todayStr) bạn đã kín cả ca sáng lẫn ca chiều! Vui lòng chọn Phương án 2 để dời sang ngày làm bù sau buổi cuối.';
                                        });
                                        return;
                                      }
                                      if (packageOrderWarning != null) {
                                        setModalState(() {
                                          modalError = '⚠️ $packageOrderWarning';
                                        });
                                        return;
                                      }
                                      if (usesTargetSlot && conflictingShift != null) {
                                        final cStart = _fmtTime(conflictingShift['gioBatDau']?.toString());
                                        final cEnd = _fmtTime(conflictingShift['gioKetThuc']?.toString());
                                        final cCode = (conflictingShift['maDonDat'] ?? '').toString();
                                        setModalState(() {
                                          modalError = selectedAction == 'START_TODAY'
                                              ? '⚠️ Không thể xác nhận Làm bù ngay hôm nay ($todayStr)! Khách rảnh nhưng lịch hôm nay của bạn đang trùng ca $cStart - $cEnd (Đơn $cCode). Vui lòng chọn Phương án 2 (Dời sang ngày mới) hoặc đổi sang ca Sáng/Chiều còn trống!'
                                              : '⚠️ Khung giờ $selectedStartStr - $selectedEndStr ngày $activeTargetFmt đang bị trùng ca $cStart - $cEnd ($cCode)! Vui lòng đổi sang buổi Sáng/Chiều còn trống hoặc chọn ngày khác.';
                                        });
                                        return;
                                      }
                                      setModalState(() {
                                        isSubmitting = true;
                                        modalError = null;
                                      });
                                      try {
                                        final res = await _apiService
                                            .resolveOverdueAssignment(
                                          phanCongId: phanCongId,
                                          action: selectedAction,
                                          lichLamViecId: targetLlvId,
                                          ngayMoi: needsDatePicker
                                              ? newDateIso
                                              : null,
                                          gioBatDauMoi: usesTargetSlot
                                              ? selectedStartStr
                                              : null,
                                          ghiChu: noteCtrl.text,
                                        );
                                        if (res.success) {
                                          if (!ctx.mounted) return;
                                          Navigator.pop(ctx);
                                          if (!mounted) return;
                                          ScaffoldMessenger.of(this.context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                res.data?['message']?.toString() ??
                                                    res.message ??
                                                    'Đã xử lý ca quá hạn thành công!',
                                              ),
                                              backgroundColor:
                                                  AppColors.success,
                                            ),
                                          );
                                          await _fetchAllData();
                                          if (!mounted) return;
                                          if (selectedAction == 'START_TODAY') {
                                            _tabController.animateTo(2);
                                          } else if (selectedAction ==
                                              'RESCHEDULE_RELEASE') {
                                            _tabController.animateTo(0);
                                          }
                                        } else {
                                          setModalState(() {
                                            isSubmitting = false;
                                            modalError = res.message ??
                                                'Không thể xử lý ca quá hạn';
                                          });
                                        }
                                      } catch (e) {
                                        setModalState(() {
                                          isSubmitting = false;
                                          modalError = 'Lỗi kết nối: $e';
                                        });
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: isSubmitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Xác nhận xử lý',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                      ),
                                    ),
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

  // ===================== HỘP THOẠI XÁC NHẬN HOÀN THÀNH & NHẬN TIỀN (80%) =====================

  Future<void> _showCompleteConfirmModal(Map<String, dynamic> o) async {
    final String serviceName = (o['tenDichVu'] ?? 'Dịch vụ giúp việc').toString();
    final String maDon = (o['maDonDat'] ?? 'N/A').toString();
    final String customerName = (o['khachHangTen'] ?? 'Khách hàng').toString();
    final String rawDate = (o['ngayThucHien'] ?? o['ngayLam'] ?? '').toString();
    final String dateStr = _fmtDate(rawDate);
    final String timeStr =
        '${_fmtTime(o['gioBatDau']?.toString())} - ${_fmtTime(o['gioKetThuc']?.toString())}';

    // BƯỚC 1 (BẮT BUỘC): Yêu cầu CTV chụp lại tài sản ở khu vực thực hiện SAU KHI LÀM XONG
    final TaiSanCaptureResult? captureAfter = await TaiSanCaptureSheet.show(
      context,
      isBeforeService: false,
      maDon: maDon,
      tenDichVu: serviceName,
      diaChi: (o['diaChi'] ?? '').toString(),
    );

    if (!mounted) return;
    if (captureAfter == null || captureAfter.danhSachHinhAnh.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '⚠️ Chưa chụp ảnh tài sản sau khi thực hiện! Đơn chưa được chuyển sang trạng thái Hoàn thành.',
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final num gross = _getGrossPrice(o);
    final num fee = _getPlatformFee(o);
    final num net = _getNetIncome(o);

    final String grossStr = _formatPrice(gross);
    final String feeStr = _formatPrice(fee);
    final String netStr = _formatPrice(net);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
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

                // Header
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.payments_rounded,
                        color: Color(0xFF16A34A),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Xác nhận hoàn thành ca làm',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Mã đơn: $maDon • KH: $customerName',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Thông tin dịch vụ tóm tắt + Xác nhận đã chụp ảnh nghiệm thu
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serviceName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                      if (dateStr.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.schedule_rounded,
                                size: 15, color: Color(0xFF64748B)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Ca làm: $dateStr ($timeStr)',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF475569),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.verified_rounded,
                              size: 15, color: Color(0xFF16A34A)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Đã chụp ${captureAfter.danhSachHinhAnh.length} ảnh tài sản sau dịch vụ (${captureAfter.khuVucVatDung})',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF15803D),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Bảng kê chi tiết dòng tiền 100% - 20% = 80%
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF86EFAC), width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.receipt_long_rounded,
                              size: 17, color: Color(0xFF15803D)),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'CHI TIẾT DÒNG TIỀN THU NHẬP CA LÀM',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF166534),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Dòng 1: 100%
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'Tổng giá trị đơn dịch vụ (100%)',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF334155),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            grossStr,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _ink,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Dòng 2: -20%
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'Chiết khấu chi phí nền tảng (20%)',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '-$feeStr',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(height: 1, color: Color(0xFFBBF7D0)),
                      ),

                      // Dòng 3: 80% thực nhận
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Số tiền bạn thực nhận (80%)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF14532D),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Cộng trực tiếp vào Ví thu nhập & Tài khoản',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF15803D),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF16A34A),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '+$netStr',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Câu hỏi xác nhận
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 18, color: Color(0xFFD97706)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Bạn có xác nhận đã hoàn thành công việc và đồng ý nhận $netStr (sau khi trừ 20% phí nền tảng) vào Ví thu nhập không?',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF92400E),
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Hàng 2 nút: Từ chối / Xác nhận
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF475569),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Từ chối / Quay lại',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _handleAction(
                              o,
                              'complete',
                              taiSanResult: captureAfter,
                            );
                          },
                          icon: const Icon(Icons.check_circle_rounded, size: 19),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Xác nhận (+$netStr)',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
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
  }

  Future<void> _handleAction(
    Map<String, dynamic> o,
    String action, {
    String? lyDo,
    TaiSanCaptureResult? taiSanResult,
  }) async {
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
        if (taiSanResult == null || taiSanResult.danhSachHinhAnh.isEmpty) {
          _showError(
            'Bắt buộc chụp ảnh tài sản sau khi thực hiện thì đơn mới được chuyển sang Hoàn thành!',
          );
          return;
        }
        res = await _apiService.completeAssignment(
          id: phanCongId,
          ghiChu: taiSanResult.ghiChuTaiSan.isNotEmpty
              ? taiSanResult.ghiChuTaiSan
              : 'Hoàn thành qua ứng dụng',
          danhSachHinhAnh: taiSanResult.danhSachHinhAnh,
          khuVucVatDung: taiSanResult.khuVucVatDung,
          moTaHienTrang: taiSanResult.moTaHienTrang,
          ghiChuTaiSan: taiSanResult.ghiChuTaiSan,
        );
        if (res != null && res.success) {
          o['anhSauDichVu'] = taiSanResult.danhSachHinhAnh;
          o['daChupSauDichVu'] = true;
          o['thoiGianChupSau'] =
              DateFormat('HH:mm dd/MM/yyyy').format(DateTime.now());
        }
      }

      if (res != null && res.success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(action == 'accept'
                ? 'Đã nhận việc thành công! Ca làm đã được thêm vào lịch.'
                : (action == 'reject'
                    ? 'Đã bỏ qua. Đơn vẫn hiện cho CTV khác.'
                    : '✅ Đã hoàn thành công việc! +${_formatPrice(_getNetIncome(o))} (80% tiền công) đã được cộng vào Ví thu nhập.')),
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