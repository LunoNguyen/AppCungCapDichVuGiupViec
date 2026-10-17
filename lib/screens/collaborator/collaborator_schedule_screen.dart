import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import '../../services/collaborator_api_service.dart';
import '../../services/location_service.dart';

class CollaboratorScheduleScreen extends StatefulWidget {
  const CollaboratorScheduleScreen({super.key});

  @override
  State<CollaboratorScheduleScreen> createState() =>
      CollaboratorScheduleScreenState();
}

class CollaboratorScheduleScreenState
    extends State<CollaboratorScheduleScreen>
    with SingleTickerProviderStateMixin {
  void reload() => _fetchSchedules();
  late TabController _viewTabController;
  int _selectedDayIndex = 0;
  bool _isLoading = true;
  int _currentUserId = 0;

  // Bộ lọc cho tab "Tất cả lịch"
  String _allScheduleStatusFilter = 'all'; // 'all', 'saptoi', 'dangthuchien', 'hoanthanh'
  DateTimeRange? _allScheduleDateRange;

  final CollaboratorApiService _apiService = CollaboratorApiService();
  final List<String> _weekDayLabels = [
    'T2',
    'T3',
    'T4',
    'T5',
    'T6',
    'T7',
    'CN'
  ];

  DateTime _focusedDate = DateTime.now();
  List<DateTime> _weekDates = [];
  List<Map<String, dynamic>> _allSchedules = [];

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
    _viewTabController = TabController(length: 2, vsync: this);
    _generateWeek(_focusedDate);
    _loadUserAndFetchSchedules();

    _viewTabController.addListener(() {
      if (!_viewTabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _viewTabController.dispose();
    super.dispose();
  }

  // ===================== LỊCH TUẦN =====================

  void _generateWeek(DateTime date) {
    int currentWeekday = date.weekday;
    DateTime monday = DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: currentWeekday - 1));

    List<DateTime> dates = [];
    for (int i = 0; i < 7; i++) {
      dates.add(monday.add(Duration(days: i)));
    }

    setState(() {
      _weekDates = dates;

      final now = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(now);

      int foundToday = -1;
      for (int i = 0; i < dates.length; i++) {
        if (DateFormat('yyyy-MM-dd').format(dates[i]) == todayStr) {
          foundToday = i;
          break;
        }
      }
      _selectedDayIndex = foundToday != -1 ? foundToday : 0;
    });
  }

  void _changeWeek(int step) {
    setState(() {
      _focusedDate = _focusedDate.add(Duration(days: step * 7));
      _generateWeek(_focusedDate);
    });
  }

  // ===================== DỮ LIỆU =====================

  Future<void> _loadUserAndFetchSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getInt('userId') ?? 0;
    if (_currentUserId == 0) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    await _fetchSchedules();
  }

  Future<void> _fetchSchedules() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final res =
          await _apiService.getSchedules(congTacVienId: _currentUserId);
      final ass =
          await _apiService.getAssignments(congTacVienId: _currentUserId);

      final combined = <Map<String, dynamic>>[];
      final seenDonIds = <dynamic>{};
      final seenMaDons = <String>{};

      if (res.success && res.data != null) {
        for (final item in res.data!) {
          final st = (item['trangThai'] ?? '').toString().toLowerCase();
          final donSt = (item['trangThaiDon'] ?? '').toString().toLowerCase();
          final pcSt = (item['trangThaiPhanCong'] ?? '').toString().toLowerCase();
          if (st == 'huy' || st == 'dahuy' || donSt == 'dahuy' || pcSt == 'tuchoi') {
            continue;
          }
          final donId = item['donDatId'];
          final maDon = item['maDonDat']?.toString();
          if (donId != null) seenDonIds.add(donId);
          if (maDon != null && maDon.isNotEmpty) seenMaDons.add(maDon);

          combined.add({
            ...item,
            'ngayLam': item['ngayLam'] ?? item['ngayThucHien'] ?? item['ngayLamViec'],
          });
        }
      }

      if (ass.success && ass.data != null) {
        for (final a in ass.data!) {
          final donId = a['donDatId'];
          final maDon = a['maDonDat']?.toString();
          // Bỏ qua đơn đã có trong lịch làm việc để không bị nhân đôi
          if (donId != null && seenDonIds.contains(donId)) continue;
          if (maDon != null && maDon.isNotEmpty && seenMaDons.contains(maDon)) continue;

          // Bỏ qua đơn bị từ chối hoặc hủy
          final pcSt = (a['trangThaiPhanCong']?.toString() ?? '').toLowerCase();
          final donSt = (a['trangThaiDon']?.toString() ?? a['trangThai']?.toString() ?? '').toLowerCase();
          if (pcSt == 'tuchoi' || donSt == 'dahuy' || donSt == 'huy' || donSt == 'choduyet' || donSt == 'dangtimctv') continue;

          if (donId != null) seenDonIds.add(donId);
          if (maDon != null && maDon.isNotEmpty) seenMaDons.add(maDon);

          combined.add({
            ...a,
            'ngayLam': a['ngayLam'] ?? a['ngayThucHien'] ?? a['ngayLamViec'],
            'gioBatDau': a['gioBatDau'],
            'gioKetThuc': a['gioKetThuc'],
            'tenDichVu': a['tenDichVu'] ?? a['dichVuTitle'],
            'diaChiChiTiet': a['diaChiChiTiet'] ?? a['diaChi'],
            'thanhTien': a['thanhTien'] ?? a['tongTien'],
          });
        }
      }

      setState(() {
        _allSchedules = combined;
      });
    } catch (e) {
      debugPrint('Lỗi tải lịch làm việc: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _schedulesForSelectedDay {
    if (_weekDates.isEmpty || _selectedDayIndex >= _weekDates.length) return [];
    final selectedDateStr =
        DateFormat('yyyy-MM-dd').format(_weekDates[_selectedDayIndex]);

    return _allSchedules.where((s) {
      final ngayLam = s['ngayLam']?.toString() ??
          s['ngayThucHien']?.toString() ??
          s['ngayLamViec']?.toString() ??
          '';
      return ngayLam.startsWith(selectedDateStr);
    }).toList();
  }

  bool _hasOrderOnDay(int index) {
    if (_weekDates.isEmpty || index >= _weekDates.length) return false;
    final dateStr = DateFormat('yyyy-MM-dd').format(_weekDates[index]);
    return _allSchedules.any((s) {
      final ngayLam = s['ngayLam']?.toString() ??
          s['ngayThucHien']?.toString() ??
          s['ngayLamViec']?.toString() ??
          '';
      return ngayLam.startsWith(dateStr);
    });
  }

  bool _isGoiThang(Map<String, dynamic> s) {
    if (s['isGoiThang'] == false) return false;
    final loaiHinh = (s['loaiHinh'] ?? s['loaiHinhDat'] ?? '').toString().trim().toLowerCase();
    if (loaiHinh == 'theolan' || loaiHinh == 'theolen' || loaiHinh == 'single') return false;
    if (s['isGoiThang'] == true) return true;
    if (loaiHinh == 'goithang') return true;
    final ten = (s['tenDichVu'] ?? s['dichVuTitle'] ?? '').toString().toLowerCase();
    return ten.contains('gói') && ten.contains('tháng');
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
                      controller: _viewTabController,
                      children: [
                        _buildDayViewWithNavigator(),
                        _buildListView(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
                    'Lịch làm việc',
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
                  onPressed: _fetchSchedules,
                ),
              ],
            ),
          ),
          TabBar(
            controller: _viewTabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.72),
            labelStyle:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
            unselectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.w500, fontSize: 13.5),
            tabs: const [
              Tab(text: 'Theo ngày'),
              Tab(text: 'Tất cả lịch'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayViewWithNavigator() {
    return Column(
      children: [
        _buildWeekStrip(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchSchedules,
            color: _primary,
            child: _buildDayView(),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekStrip() {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final rawMonth = DateFormat('MMMM yyyy', 'vi').format(_focusedDate);
    final monthYear = rawMonth.isNotEmpty ? (rawMonth[0].toUpperCase() + rawMonth.substring(1)) : rawMonth;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        children: [
          // Điều hướng tuần
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: _primary),
                visualDensity: VisualDensity.compact,
                onPressed: () => _changeWeek(-1),
              ),
              Row(
                children: [
                  const Icon(Icons.calendar_month_outlined,
                      size: 16, color: _primary),
                  const SizedBox(width: 6),
                  Text(
                    monthYear,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: _primary),
                visualDensity: VisualDensity.compact,
                onPressed: () => _changeWeek(1),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Dãy 7 ngày trong tuần
          SizedBox(
            height: 62,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 7,
              itemBuilder: (context, i) {
                if (i >= _weekDates.length) return const SizedBox.shrink();
                final date = _weekDates[i];
                final dateStr = DateFormat('yyyy-MM-dd').format(date);
                final isSelected = i == _selectedDayIndex;
                final isToday = dateStr == todayStr;
                final hasOrder = _hasOrderOnDay(i);

                return GestureDetector(
                  onTap: () => setState(() => _selectedDayIndex = i),
                  child: Container(
                    width: (MediaQuery.of(context).size.width - 24) / 7,
                    decoration: BoxDecoration(
                      color: isSelected ? _primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: isToday && !isSelected
                          ? Border.all(color: _primary, width: 1.5)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _weekDayLabels[i],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                        if (hasOrder)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : const Color(0xFFF59E0B),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayView() {
    final schedules = _schedulesForSelectedDay;
    if (schedules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_available_rounded, size: 64, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text(
              'Không có ca làm vào ${_weekDayLabels[_selectedDayIndex]}',
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text('Hãy tận hưởng ngày nghỉ hoặc nhận thêm việc mới 🎉',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      itemCount: schedules.length,
      itemBuilder: (context, index) => _buildScheduleCard(schedules[index]),
    );
  }

  List<Map<String, dynamic>> get _sortedAndFilteredAllSchedules {
    final list = List<Map<String, dynamic>>.from(_allSchedules);

    // 1. Sắp xếp: ngày mới nhất cho tới thấp nhất (giảm dần)
    list.sort((a, b) {
      final dateA = (a['ngayLam'] ?? a['ngayThucHien'] ?? '').toString();
      final dateB = (b['ngayLam'] ?? b['ngayThucHien'] ?? '').toString();
      final cmpDate = dateB.compareTo(dateA); // Mới nhất lên đầu
      if (cmpDate != 0) return cmpDate;
      final timeA = (a['gioBatDau'] ?? '').toString();
      final timeB = (b['gioBatDau'] ?? '').toString();
      return timeB.compareTo(timeA);
    });

    // 2. Lọc theo trạng thái
    final filteredByStatus = list.where((item) {
      if (_allScheduleStatusFilter == 'all') return true;
      final st = (item['trangThai'] ?? item['trangThaiPhanCong'] ?? '').toString().toLowerCase();
      if (_allScheduleStatusFilter == 'saptoi') {
        return st == 'saptoi' || st == 'daxacnhan' || st == 'choxacnhan';
      } else if (_allScheduleStatusFilter == 'dangthuchien') {
        return st == 'dangthuchien' || st == 'dang_thuc_hien' || st == 'danglam';
      } else if (_allScheduleStatusFilter == 'hoanthanh') {
        return st == 'hoanthanh' || st == 'completed';
      }
      return true;
    }).toList();

    // 3. Lọc theo khoảng ngày (DateRange)
    if (_allScheduleDateRange == null) return filteredByStatus;

    final start = DateTime(
      _allScheduleDateRange!.start.year,
      _allScheduleDateRange!.start.month,
      _allScheduleDateRange!.start.day,
    );
    final end = DateTime(
      _allScheduleDateRange!.end.year,
      _allScheduleDateRange!.end.month,
      _allScheduleDateRange!.end.day,
      23, 59, 59,
    );

    return filteredByStatus.where((item) {
      final raw = (item['ngayLam'] ?? item['ngayThucHien'] ?? '').toString();
      if (raw.isEmpty) return true;
      final dt = DateTime.tryParse(raw.length >= 10 ? raw.substring(0, 10) : raw);
      if (dt == null) return false;
      return !dt.isBefore(start) && !dt.isAfter(end);
    }).toList();
  }

  Widget _buildAllScheduleFilters() {
    final bool hasFilter =
        _allScheduleStatusFilter != 'all' || _allScheduleDateRange != null;

    String dateRangeText = 'Chọn khoảng ngày';
    if (_allScheduleDateRange != null) {
      final s = DateFormat('dd/MM/yy').format(_allScheduleDateRange!.start);
      final e = DateFormat('dd/MM/yy').format(_allScheduleDateRange!.end);
      dateRangeText = s == e ? s : '$s - $e';
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: Column(
        children: [
          Row(
            children: [
              // 1. ComboBox chọn trạng thái (đổ menu xuống khi ấn)
              Expanded(
                flex: 5,
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _allScheduleStatusFilter != 'all'
                          ? _primary
                          : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _allScheduleStatusFilter,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down_rounded,
                          color: _primary),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      items: const [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text('Tất cả trạng thái'),
                        ),
                        DropdownMenuItem(
                          value: 'saptoi',
                          child: Text('Sắp tới'),
                        ),
                        DropdownMenuItem(
                          value: 'dangthuchien',
                          child: Text('Đang làm'),
                        ),
                        DropdownMenuItem(
                          value: 'hoanthanh',
                          child: Text('Hoàn thành'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _allScheduleStatusFilter = val);
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 2. Cuốn lịch chọn khoảng ngày (Từ ngày ... Đến ngày ...)
              Expanded(
                flex: 6,
                child: InkWell(
                  onTap: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      initialDateRange: _allScheduleDateRange ??
                          DateTimeRange(
                            start:
                                DateTime.now().subtract(const Duration(days: 7)),
                            end: DateTime.now().add(const Duration(days: 14)),
                          ),
                      firstDate: DateTime(2025),
                      lastDate: DateTime(2028),
                      saveText: 'Áp dụng',
                      helpText: 'Chọn khoảng ngày lọc lịch',
                    );
                    if (picked != null) {
                      setState(() => _allScheduleDateRange = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: _allScheduleDateRange != null
                          ? const Color(0xFFEFF6FF)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _allScheduleDateRange != null
                            ? const Color(0xFF3B82F6)
                            : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.date_range_rounded,
                          size: 17,
                          color: _allScheduleDateRange != null
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            dateRangeText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: _allScheduleDateRange != null
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: _allScheduleDateRange != null
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

              // 3. Nút xóa lọc
              if (hasFilter) ...[
                const SizedBox(width: 6),
                IconButton(
                  tooltip: 'Bỏ lọc',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: const Icon(Icons.cancel_rounded,
                      size: 20, color: Color(0xFFEF4444)),
                  onPressed: () {
                    setState(() {
                      _allScheduleStatusFilter = 'all';
                      _allScheduleDateRange = null;
                    });
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          const Divider(height: 8, thickness: 0.8, color: AppColors.divider),
        ],
      ),
    );
  }

  Widget _buildListView() {
    final displayList = _sortedAndFilteredAllSchedules;

    return Column(
      children: [
        _buildAllScheduleFilters(),
        Expanded(
          child: displayList.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.filter_list_off_rounded,
                            size: 54, color: Color(0xFFCBD5E1)),
                        const SizedBox(height: 12),
                        const Text(
                          'Không có ca làm việc nào khớp bộ lọc',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Thử thay đổi trạng thái hoặc khoảng thời gian lọc xem sao nhé!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _allScheduleStatusFilter = 'all';
                              _allScheduleDateRange = null;
                            });
                          },
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Đặt lại bộ lọc'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _primary,
                            side: const BorderSide(color: _primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 4, bottom: 20),
                  itemCount: displayList.length,
                  itemBuilder: (context, index) {
                    final s = displayList[index];
                    final rawDate = s['ngayLam']?.toString() ?? s['ngayThucHien']?.toString() ?? '';
                    final bool showDateHeader = index == 0 ||
                        (displayList[index - 1]['ngayLam']?.toString() ??
                                displayList[index - 1]['ngayThucHien']?.toString() ?? '') !=
                            rawDate;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showDateHeader)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded,
                                    size: 14, color: _primary),
                                const SizedBox(width: 6),
                                Text(
                                  _fmtDate(rawDate),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13.5,
                                    color: _ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        _buildScheduleCard(s),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ===================== THẺ CA LÀM VIỆC =====================

  Widget _buildScheduleCard(Map<String, dynamic> s) {
    final String serviceName = s['tenDichVu'] ?? s['dichVuTitle'] ?? 'Dịch vụ giúp việc';
    final String customerName = s['khachHangTen'] ?? 'Khách hàng';
    final String address = s['diaChiChiTiet'] ?? s['diaChi'] ?? 'Chưa cập nhật địa chỉ';
    final String rawDate = s['ngayLam']?.toString() ?? s['ngayThucHien']?.toString() ?? '';
    final String dateStr = _fmtDate(rawDate);
    final String startStr = _fmtTime(s['gioBatDau']?.toString());
    final String endStr = _fmtTime(s['gioKetThuc']?.toString());
    final String status = (s['trangThai'] ?? s['trangThaiPhanCong'] ?? 'SapToi').toString();

    final bool isCompleted = status.toLowerCase() == 'hoanthanh' || status.toLowerCase() == 'completed';
    final bool isWorking = status.toLowerCase() == 'dangthuchien' || status.toLowerCase() == 'dang_thuc_hien' || status.toLowerCase() == 'danglam';

    final bool isPackage = _isGoiThang(s);
    final int soBuoi = int.tryParse(s['soBuoi']?.toString() ?? '') ?? (isPackage ? 8 : 1);
    final int buoiThu = int.tryParse(s['buoiThu']?.toString() ?? s['buoiHienTai']?.toString() ?? '') ?? 1;

    // Màu theo loại hình: Gói tháng = Cam/Hổ phách, Theo lần = Tím chàm
    final Color typeColor = isPackage ? const Color(0xFFD97706) : AppColors.partner500;
    final Color typeBg = isPackage ? const Color(0xFFFEF3C7) : const Color(0xFFEEF2FF);

    final String? dayLbl = _dayLabel(rawDate);
    final avatar = _avatarPair(customerName);
    final int? diff = _daysDiff(rawDate);
    final String timingStatus = _getShiftTimingStatus(s);
    final bool isOverdue = !isCompleted && !isWorking && timingStatus == 'OVERDUE';
    final bool isReady = !isCompleted && !isWorking && timingStatus == 'READY';
    final bool isTooEarly = !isCompleted && !isWorking && timingStatus == 'TOO_EARLY';

    // Màu trạng thái
    Color sc;
    String statusText;
    if (isCompleted) {
      sc = const Color(0xFF16A34A);
      statusText = 'Hoàn thành';
    } else if (isWorking) {
      sc = const Color(0xFF2563EB);
      statusText = 'Đang làm';
    } else if (isOverdue) {
      sc = const Color(0xFFDC2626);
      statusText = '⚠️ Quá hạn';
    } else if (isReady) {
      sc = const Color(0xFF16A34A);
      statusText = '🟢 Đến giờ làm';
    } else {
      sc = isPackage ? const Color(0xFFD97706) : AppColors.partner500;
      statusText = isTooEarly ? 'Chưa đến giờ' : 'Sắp tới';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPackage ? const Color(0xFFFDE68A) : AppColors.cardBorder,
          width: isPackage ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cột giờ bên trái như timeline (Gói tháng có màu cam, Theo lần có màu tím)
                Container(
                  width: 76,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: typeBg,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(13),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        startStr,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: typeColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(width: 1.5, height: 14, color: typeColor.withValues(alpha: 0.35)),
                      const SizedBox(height: 2),
                      Text(
                        endStr,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      // Icon nhận diện loại hình
                      Icon(
                        isPackage ? Icons.autorenew_rounded : Icons.label_outline_rounded,
                        size: 16,
                        color: typeColor,
                      ),
                    ],
                  ),
                ),

                // Nội dung ca làm bên phải
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hàng tên dịch vụ + trạng thái
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                serviceName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: _ink,
                                  height: 1.25,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: sc.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: sc,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Badge phân biệt Ca Lẻ vs Gói Tháng (Đổi màu chuẩn)
                        if (isPackage) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFFCD34D)),
                            ),
                            child: Text(
                              (s['isBuoiLamBu'] == true)
                                  ? '🔄 Gói tháng (Buổi $buoiThu/$soBuoi - Làm bù)'
                                  : '🔄 Gói tháng (Buổi $buoiThu/$soBuoi)',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFB45309),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Thanh tiến độ buổi trong tháng
                          Text(
                            s['soBuoiConLai'] != null
                                ? '📊 Còn ${s['soBuoiConLai']} buổi chưa hoàn thành'
                                : '📊 Còn ${soBuoi - buoiThu} buổi trong tháng',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF92400E),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFC7D2FE)),
                            ),
                            child: const Text(
                              '🏷️ Ca lẻ (1 buổi)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF4338CA),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),

                        // Khách hàng
                        Row(
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
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                customerName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Địa chỉ
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 16, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                address,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Ngày làm + Tiền công
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined,
                                size: 15, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                dayLbl != null ? '$dayLbl, $dateStr' : dateStr,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            if (s['thanhTien'] != null)
                              Text(
                                _formatPrice(s['thanhTien']),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: _money,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // HÀNG NÚT HÀNH ĐỘNG DƯỚI ĐÁY
          if (!isCompleted)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final double? lat = LocationService.toDouble(s['viDo'] ?? s['lat']);
                        final double? lng = LocationService.toDouble(s['kinhDo'] ?? s['lng']);
                        _handleMapButton(address, lat: lat, lng: lng);
                      },
                      icon: const Icon(Icons.map_outlined, size: 15),
                      label: const Text('Xem bản đồ', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primary,
                        side: const BorderSide(color: _primary),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: isWorking
                        ? ElevatedButton.icon(
                            onPressed: () => _handleCompleteJob(s),
                            icon: const Icon(Icons.check_circle_outline, size: 15),
                            label: const Text('Hoàn thành', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: () => _handleStartJob(s, diff, dateStr),
                            icon: Icon(
                              isOverdue
                                  ? Icons.warning_amber_rounded
                                  : (isReady
                                      ? Icons.play_arrow_rounded
                                      : Icons.lock_outline_rounded),
                              size: 15,
                            ),
                            label: Text(
                              isOverdue
                                  ? 'Xử lý quá hạn'
                                  : (isReady
                                      ? 'Bắt đầu làm'
                                      : (diff != null && diff > 0 ? 'Chưa đến ngày' : 'Chưa đến giờ')),
                              style: const TextStyle(fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isOverdue
                                  ? const Color(0xFFEA580C)
                                  : (isReady
                                      ? _primary
                                      : const Color(0xFF94A3B8)),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                          ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleMapButton(String address, {double? lat, double? lng}) async {
    if ((lat == null || lng == null) &&
        (address.trim().isEmpty || address == 'Chưa cập nhật địa chỉ')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Chưa có thông tin địa chỉ để mở bản đồ'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    final ok = await LocationService.openDirections(
      lat: lat,
      lng: lng,
      address: address == 'Chưa cập nhật địa chỉ' ? null : address,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Không thể mở ứng dụng Google Maps'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handlePhoneCall(String? phone) async {
    final cleaned = (phone ?? '').trim();
    if (cleaned.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Không có số điện thoại của khách hàng'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    final uri = Uri(scheme: 'tel', path: cleaned);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📞 Số điện thoại khách hàng: $cleaned'),
          backgroundColor: AppColors.info,
        ),
      );
    }
  }

  Future<void> _handleStartJob(Map<String, dynamic> s, int? diff, String dateStr) async {
    final String timingStatus = _getShiftTimingStatus(s);

    // 1. Trường hợp CHƯA ĐẾN NGÀY / CHƯA ĐẾN GIỜ (TOO_EARLY)
    if (timingStatus == 'TOO_EARLY') {
      final String startStr = _fmtTime(s['gioBatDau']?.toString());
      String earlyMsg = '';
      if (startStr.isNotEmpty) {
        final parts = startStr.split(':');
        if (parts.length >= 2) {
          final int sM = (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
          final int eM = (sM - 30).clamp(0, 23 * 60 + 59);
          final h = (eM ~/ 60).toString().padLeft(2, '0');
          final m = (eM % 60).toString().padLeft(2, '0');
          earlyMsg = ' (bạn chỉ có thể bắt đầu từ $h:$m trở đi)';
        }
      }
      final String msg = (diff != null && diff > 0)
          ? '⚠️ Chưa đến ngày làm việc, bạn chưa thể bắt đầu ca này!\n(Lịch làm: $dateStr)'
          : '⏳ Chưa đến giờ làm việc!\nCa làm bắt đầu lúc $startStr$earlyMsg.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.warning,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // 2. Trường hợp CA LÀM ĐÃ QUÁ HẠN (OVERDUE)
    if (timingStatus == 'OVERDUE') {
      final int overdueDays = (diff != null && diff < 0) ? diff.abs() : 0;
      await _showOverdueResolutionModal(s, dateStr, overdueDays);
      return;
    }

    // 3. Trường hợp ĐÚNG KHUNG GIỜ HỢP LỆ (READY)
    final int phanCongId = s['phanCongId'] ?? s['id'] ?? 0;
    if (phanCongId == 0) return;

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
        await _fetchSchedules();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${res.message}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showOverdueResolutionModal(
    Map<String, dynamic> s,
    String oldDateStr,
    int daysLate,
  ) async {
    final int phanCongId = s['phanCongId'] ?? s['id'] ?? 0;
    if (phanCongId == 0) return;

    final int? targetLlvId = int.tryParse((s['lichLamViecId'] ?? s['id'])?.toString() ?? '');
    final bool isGoiThang = _isGoiThang(s);
    final int soBuoi = int.tryParse(s['soBuoi']?.toString() ?? '') ?? (isGoiThang ? 8 : 1);
    final int buoiThu = int.tryParse(s['buoiThu']?.toString() ?? s['buoiHienTai']?.toString() ?? '') ?? 1;

    final String customerName = (s['khachHangTen'] ?? 'Khách hàng').toString();
    final String customerPhone = (s['khachHangPhone'] ?? s['soDienThoai'] ?? '').toString();
    final String serviceName = (s['tenDichVu'] ?? s['dichVuTitle'] ?? 'Dịch vụ').toString();
    final String startTimeStr = _fmtTime(s['gioBatDau']?.toString()).isNotEmpty
        ? _fmtTime(s['gioBatDau']?.toString())
        : '08:00';
    final String endTimeStr = _fmtTime(s['gioKetThuc']?.toString()).isNotEmpty
        ? _fmtTime(s['gioKetThuc']?.toString())
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

    final int origStartMins = parseMinutes(startTimeStr);
    final int origEndMins = parseMinutes(endTimeStr);
    final int durationMins = (origEndMins > origStartMins) ? (origEndMins - origStartMins) : 120;
    int selectedStartMins = origStartMins;

    final now = DateTime.now();
    final DateTime todayDate = DateTime(now.year, now.month, now.day);

    String fmtLocalDate(DateTime d) {
      final dd = d.day.toString().padLeft(2, '0');
      final mm = d.month.toString().padLeft(2, '0');
      return '$dd/$mm/${d.year}';
    }

    String toIsoDate(DateTime d) {
      final dd = d.day.toString().padLeft(2, '0');
      final mm = d.month.toString().padLeft(2, '0');
      return '${d.year}-$mm-$dd';
    }

    // Thu thập các buổi khác trong cùng đơn gói tháng để kiểm tra trùng ngày và tìm buổi cuối cùng
    final Map<String, Map<String, dynamic>> packageSessionDates = {};
    DateTime? lastSessionDate;
    if (isGoiThang) {
      for (final item in _allSchedules) {
        final bool isSameOrder = (item['donDatId'] != null && s['donDatId'] != null && item['donDatId'].toString() == s['donDatId'].toString());
        if (isSameOrder) {
          final int? sId = int.tryParse((item['lichLamViecId'] ?? item['id'])?.toString() ?? '');
          if (targetLlvId != null && sId == targetLlvId) continue;
          final String st = (item['trangThai'] ?? '').toString().toLowerCase();
          if (st == 'dahuy' || st == 'huy') continue;
          final String rawDate = (item['ngayLam'] ?? item['ngayThucHien'] ?? '').toString();
          if (rawDate.length >= 10) {
            final String iso = rawDate.substring(0, 10);
            packageSessionDates[iso] = item;
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

    // Ngày gợi ý làm bù sau buổi cuối cùng của gói
    final DateTime? suggestedEndOfPackageDate = lastSessionDate?.add(const Duration(days: 3));
    final String? endOfPackageFmt = suggestedEndOfPackageDate != null
        ? fmtLocalDate(suggestedEndOfPackageDate)
        : null;

    // Lịch cho chọn từ hôm nay đến +90 ngày (không cho dời về ngày đã qua)
    final DateTime pickerFirstDate = todayDate;
    final DateTime pickerLastDate = todayDate.add(const Duration(days: 90));

    // Mặc định chọn ngày làm bù: gợi ý sau buổi cuối cùng của gói (nếu có), hoặc ngày mai
    DateTime selectedNewDate = suggestedEndOfPackageDate ?? todayDate.add(const Duration(days: 1));
    if (selectedNewDate.isBefore(pickerFirstDate)) {
      selectedNewDate = pickerFirstDate;
    }

    final int nowMins = now.hour * 60 + now.minute;
    final bool isLateNight = now.hour >= 21 || (nowMins + durationMins > 24 * 60);

    bool hasCustomerConsent = false;
    String selectedAction = isLateNight ? 'RESCHEDULE_KEEP' : 'START_TODAY';
    if (!isLateNight && selectedAction == 'START_TODAY' && selectedStartMins < nowMins) {
      selectedStartMins = ((nowMins + 15) ~/ 15) * 15;
      if (selectedStartMins + durationMins > 24 * 60) {
        selectedAction = 'RESCHEDULE_KEEP';
      }
    }
    final TextEditingController noteController = TextEditingController();
    bool isSubmitting = false;
    String? modalError;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final bool needsDatePicker =
                selectedAction == 'RESCHEDULE_KEEP' || selectedAction == 'RESCHEDULE_RELEASE';
            final bool usesTargetSlot =
                selectedAction == 'START_TODAY' ||
                selectedAction == 'RESCHEDULE_KEEP';

            final DateTime activeTargetDate =
                selectedAction == 'START_TODAY' ? todayDate : selectedNewDate;
            final String activeTargetIso = toIsoDate(activeTargetDate);
            final String activeTargetFmt = fmtLocalDate(activeTargetDate);
            final String todayIso = toIsoDate(todayDate);

            final int selectedEndMins = selectedStartMins + durationMins;
            final String selectedStartStr = formatMinutes(selectedStartMins);
            final String selectedEndStr = formatMinutes(selectedEndMins);

            List<Map<String, dynamic>> getShiftsForIsoDate(String isoDate) {
              return _allSchedules.where((item) {
                final int? itemId = int.tryParse((item['lichLamViecId'] ?? item['id'])?.toString() ?? '');
                if (targetLlvId != null && itemId == targetLlvId) return false;
                final String st = (item['trangThai'] ?? '').toString().toLowerCase();
                if (st == 'dahuy' || st == 'huy' || st == 'tuchoi') return false;
                final String sDate = (item['ngayLam'] ?? item['ngayThucHien'] ?? '').toString();
                return sDate.startsWith(isoDate);
              }).toList();
            }

            // Các ca làm khác của CTV trong ngày activeTargetDate và ngày hôm nay (START_TODAY)
            final List<Map<String, dynamic>> shiftsOnTargetDate = getShiftsForIsoDate(activeTargetIso);
            final List<Map<String, dynamic>> shiftsOnToday = getShiftsForIsoDate(todayIso);

            Map<String, dynamic>? conflictingShiftToday;
            for (final item in shiftsOnToday) {
              final int exStart = parseMinutes(_fmtTime(item['gioBatDau']?.toString()));
              final int exEnd = parseMinutes(_fmtTime(item['gioKetThuc']?.toString()));
              if (selectedStartMins < exEnd && exStart < selectedEndMins) {
                conflictingShiftToday = item;
                break;
              }
            }

            Map<String, dynamic>? conflictingShift;
            for (final item in shiftsOnTargetDate) {
              final int exStart = parseMinutes(_fmtTime(item['gioBatDau']?.toString()));
              final int exEnd = parseMinutes(_fmtTime(item['gioKetThuc']?.toString()));
              final bool isSameOrder = (item['donDatId'] != null && s['donDatId'] != null && item['donDatId'].toString() == s['donDatId'].toString());
              if (selectedAction == 'START_TODAY' || selectedAction == 'RESCHEDULE_KEEP' || isSameOrder) {
                if (selectedStartMins < exEnd && exStart < selectedEndMins) {
                  conflictingShift = item;
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
              required Color iconColor,
              required String title,
              required String subtitle,
              required String badgeText,
              bool enabled = true,
              String? disabledReason,
            }) {
              final bool isSelected = selectedAction == value;
              return GestureDetector(
                onTap: enabled
                    ? () => setModalState(() {
                        selectedAction = value;
                        modalError = null;
                      })
                    : () {
                        if (disabledReason != null) {
                          setModalState(() {
                            modalError = disabledReason;
                          });
                        }
                      },
                child: Opacity(
                  opacity: enabled ? 1.0 : 0.6,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? iconColor.withValues(alpha: 0.07)
                          : (enabled ? const Color(0xFFF8FAFC) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? iconColor : const Color(0xFFE2E8F0),
                        width: isSelected ? 1.6 : 1.0,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: iconColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(icon, color: iconColor, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected ? iconColor : (enabled ? _ink : AppColors.textSecondary),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: iconColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      badgeText,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: iconColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked_rounded
                              : (enabled ? Icons.radio_button_off_rounded : Icons.block_rounded),
                          color: isSelected ? iconColor : const Color(0xFF94A3B8),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.90,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.warning_amber_rounded,
                              color: Color(0xFFD97706),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  daysLate > 0
                                      ? (isGoiThang
                                          ? 'Ca quá hạn $daysLate ngày (Buổi $buoiThu/$soBuoi)'
                                          : 'Ca làm đã quá hạn $daysLate ngày')
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
                                  daysLate > 0
                                      ? 'Lịch cũ: $oldDateStr (trễ $daysLate ngày) • $startTimeStr - $endTimeStr'
                                      : 'Lịch ca làm: $oldDateStr • $startTimeStr - $endTimeStr (đã quá giờ làm hôm nay)',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFDC2626),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(sheetCtx),
                            icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.divider),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                            ? '🔄 Gói tháng (Buổi $buoiThu/$soBuoi): Khách có thể dời bù vào ngày trống giữa các buổi, hoặc chọn làm bù sau buổi cuối cùng của gói (sau ngày ${fmtLocalDate(lastSessionDate)}).'
                                            : '🔄 Gói tháng (Buổi $buoiThu/$soBuoi): Vui lòng chọn ngày chưa có lịch của các buổi khác trong gói.',
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

                            // Bước 1: Gọi khách hàng
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFBFDBFE)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.support_agent_rounded,
                                      color: Color(0xFF2563EB), size: 24),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Bước 1: Liên hệ KH $customerName',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF1E40AF),
                                          ),
                                        ),
                                        Text(
                                          customerPhone.isNotEmpty
                                              ? 'SĐT: $customerPhone • $serviceName'
                                              : serviceName,
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            color: Color(0xFF3B82F6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (customerPhone.isNotEmpty)
                                    ElevatedButton.icon(
                                      onPressed: () => _handlePhoneCall(customerPhone),
                                      icon: const Icon(Icons.phone_in_talk_rounded, size: 15),
                                      label: const Text('Gọi ngay', style: TextStyle(fontSize: 12)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF2563EB),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        elevation: 0,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Checkbox xác nhận đã hỏi ý kiến khách hàng
                            InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () => setModalState(() {
                                hasCustomerConsent = !hasCustomerConsent;
                                modalError = null;
                              }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: hasCustomerConsent
                                      ? const Color(0xFFF0FDF4)
                                      : const Color(0xFFFFFBEB),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: hasCustomerConsent
                                        ? const Color(0xFF86EFAC)
                                        : const Color(0xFFFDE68A),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: hasCustomerConsent,
                                      activeColor: const Color(0xFF16A34A),
                                      visualDensity: VisualDensity.compact,
                                      onChanged: (val) => setModalState(() {
                                        hasCustomerConsent = val ?? false;
                                        modalError = null;
                                      }),
                                    ),
                                    const Expanded(
                                      child: Text(
                                        'Tôi xác nhận đã liên hệ và được Khách hàng đồng ý với phương án bên dưới',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: _ink,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            const Text(
                              'Bước 2: Chọn phương án thống nhất với khách hàng',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _ink,
                              ),
                            ),
                            const SizedBox(height: 8),

                            buildOptionTile(
                              value: 'START_TODAY',
                              icon: Icons.play_circle_fill_rounded,
                              iconColor: isLateNight
                                  ? const Color(0xFFDC2626)
                                  : (conflictingShiftToday != null
                                      ? const Color(0xFFDC2626)
                                      : const Color(0xFF16A34A)),
                              title: '1. Làm bù NGAY HÔM NAY (${fmtLocalDate(todayDate)})',
                              enabled: !isLateNight,
                              disabledReason:
                                  '⚠️ Đã quá muộn trong ngày (${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}), không còn khung giờ phù hợp để dọn dẹp hôm nay! Vui lòng chọn Phương án 2 để dời sang ngày làm bù.',
                              subtitle: isLateNight
                                  ? '⚠️ Đã quá muộn trong ngày (${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}). Hệ thống tự động chuyển sang Phương án 2 (Dời sang ngày làm bù) để đảm bảo chất lượng dịch vụ!'
                                  : (conflictingShiftToday != null
                                      ? '⚠️ Lịch hôm nay của bạn bị trùng giờ ($selectedStartStr-$selectedEndStr)! Dù khách rảnh, hãy đổi sang ca Sáng/Chiều trống bên dưới hoặc chọn Phương án 2 (Dời sang ngày mới).'
                                      : 'Khách đồng ý cho làm bù ngay hôm nay ($selectedStartStr-$selectedEndStr). Chuyển ca sang Đang làm.'),
                              badgeText: isLateNight ? 'Quá muộn' : (conflictingShiftToday != null ? 'Trùng lịch hôm nay' : 'Làm ngay'),
                            ),
                            buildOptionTile(
                              value: 'RESCHEDULE_KEEP',
                              icon: Icons.event_available_rounded,
                              iconColor: _primary,
                              title: isGoiThang
                                  ? '2. Dời sang ngày làm bù (Tôi vẫn nhận làm trọn gói)'
                                  : '2. Dời sang ngày mới (Tôi vẫn phụ trách)',
                              subtitle: isGoiThang
                                  ? (endOfPackageFmt != null
                                      ? 'Làm bù sau buổi cuối cùng của gói (Gợi ý: $endOfPackageFmt). Đảm bảo hoàn thành trọn vẹn toàn bộ gói.'
                                      : 'Khách hẹn ngày khác (trước buổi kế tiếp nếu là gói tháng). Có thể chèn vào buổi Sáng/Chiều còn trống.')
                                  : 'Khách hẹn ngày khác. Có thể chèn vào buổi Sáng/Chiều còn trống.',
                              badgeText: 'Giữ đơn',
                            ),
                            if (!isGoiThang) ...[
                              buildOptionTile(
                                value: 'RESCHEDULE_RELEASE',
                                icon: Icons.person_search_rounded,
                                iconColor: const Color(0xFFD97706),
                                title: '3. Dời sang ngày mới (Tôi bận — Tìm CTV khác)',
                                subtitle:
                                    'Cập nhật ngày mới khách chọn và trả đơn về trạng thái Đang tìm CTV để người khác nhận.',
                                badgeText: 'Trả về Tìm CTV',
                              ),
                              buildOptionTile(
                                value: 'CANCEL_ORDER',
                                icon: Icons.cancel_outlined,
                                iconColor: const Color(0xFFDC2626),
                                title: '4. Khách không còn nhu cầu (Hủy đơn)',
                                subtitle:
                                    'Khách báo không cần dọn nữa. Hủy ca quá hạn để không bị treo đơn.',
                                badgeText: 'Hủy đơn',
                              ),
                            ],

                            if (needsDatePicker) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_month_rounded,
                                        color: _primary, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            isGoiThang
                                                ? 'Ngày làm bù khách chọn:'
                                                : 'Ngày làm mới khách hàng chọn:',
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          Text(
                                            fmtLocalDate(selectedNewDate),
                                            style: const TextStyle(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w800,
                                              color: _primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: () async {
                                        final DateTime safeInit = selectedNewDate.isAfter(pickerLastDate)
                                            ? pickerLastDate
                                            : (selectedNewDate.isBefore(pickerFirstDate) ? pickerFirstDate : selectedNewDate);
                                        final picked = await showDatePicker(
                                          context: ctx,
                                          initialDate: safeInit,
                                          firstDate: pickerFirstDate,
                                          lastDate: pickerLastDate,
                                        );
                                        if (picked != null) {
                                          setModalState(() {
                                            selectedNewDate = picked;
                                            modalError = null;
                                          });
                                        }
                                      },
                                      icon: const Icon(Icons.edit_calendar_rounded, size: 15),
                                      label: const Text('Chọn ngày', style: TextStyle(fontSize: 12)),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: _primary,
                                        side: const BorderSide(color: _primary),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isGoiThang && suggestedEndOfPackageDate != null) ...[
                                const SizedBox(height: 6),
                                ActionChip(
                                  avatar: const Icon(Icons.event_repeat_rounded,
                                      size: 15, color: _primary),
                                  backgroundColor: selectedNewDate.isAtSameMomentAs(suggestedEndOfPackageDate)
                                      ? const Color(0xFFDBEAFE)
                                      : const Color(0xFFEFF6FF),
                                  side: const BorderSide(color: Color(0xFF93C5FD)),
                                  label: Text(
                                    '📅 Bù sau buổi cuối ($endOfPackageFmt)',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: _primary,
                                    ),
                                  ),
                                  onPressed: () {
                                    setModalState(() {
                                      selectedNewDate = suggestedEndOfPackageDate;
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
                              const SizedBox(height: 8),
                            ],

                            // Bộ chọn Khung giờ làm bù (Sáng / Chiều) & Kiểm tra trùng lịch trực tiếp
                            if (usesTargetSlot) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 10),
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
                                            'Khung giờ ngày $activeTargetFmt: $selectedStartStr - $selectedEndStr',
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
                                              'Giờ gốc ($startTimeStr)',
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
                                            final pickedTime = await showTimePicker(
                                              context: ctx,
                                              initialTime: TimeOfDay(
                                                hour: selectedStartMins ~/ 60,
                                                minute: selectedStartMins % 60,
                                              ),
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
                                        '📅 Các ca đã có trong ngày $activeTargetFmt: ${shiftsOnTargetDate.map((item) => '${_fmtTime(item['gioBatDau']?.toString())}-${_fmtTime(item['gioKetThuc']?.toString())} (${item['maDonDat'] ?? 'Ca làm'})').join(', ')}',
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
                                            ? '⚠️ Trùng lịch hôm nay với ca ${_fmtTime(conflictingShift['gioBatDau']?.toString())} - ${_fmtTime(conflictingShift['gioKetThuc']?.toString())} (${conflictingShift['maDonDat'] ?? ''})! '
                                                'Dù khách hàng rảnh nhưng lịch của bạn bị trùng: vui lòng chọn Phương án 2 (Dời sang ngày mới) hoặc đổi sang khung giờ Sáng/Chiều còn trống.'
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

                            TextField(
                              controller: noteController,
                              maxLines: 2,
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                labelText: 'Ghi chú thỏa thuận với khách (tùy chọn)',
                                hintText: 'VD: Đã gọi khách lúc 9h, khách đồng ý làm bù...',
                                hintStyle: const TextStyle(fontSize: 12),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),

                            if (modalError != null) ...[
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFFCA5A5)),
                                ),
                                child: Text(
                                  '⚠️ $modalError',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFDC2626),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 14),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: isSubmitting
                                    ? null
                                    : () async {
                                        if (!hasCustomerConsent) {
                                          setModalState(() {
                                            modalError =
                                                'Vui lòng gọi điện cho khách hàng và tích chọn xác nhận khách đã đồng ý phương án!';
                                          });
                                          return;
                                        }
                                        if (selectedAction == 'START_TODAY' && isLateNight) {
                                          setModalState(() {
                                            modalError =
                                                '⚠️ Đã quá muộn trong ngày (${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}), không thể làm bù hôm nay! Vui lòng chọn Phương án 2 (Dời sang ngày mới).';
                                          });
                                          return;
                                        }
                                        if (selectedAction == 'START_TODAY' && selectedStartMins < nowMins) {
                                          setModalState(() {
                                            modalError =
                                                '⚠️ Giờ làm bù hôm nay (${formatMinutes(selectedStartMins)}) không được ở trong quá khứ so với hiện tại (${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')})!';
                                          });
                                          return;
                                        }
                                        if (packageOrderWarning != null) {
                                          setModalState(() {
                                            modalError = packageOrderWarning;
                                          });
                                          return;
                                        }
                                        if (usesTargetSlot && conflictingShift != null) {
                                          setModalState(() {
                                            if (selectedAction == 'START_TODAY') {
                                              modalError =
                                                  'Không thể xác nhận "Làm bù ngay hôm nay" vì lịch hôm nay ($activeTargetFmt) của bạn bị trùng giờ ($selectedStartStr - $selectedEndStr) với ca ${conflictingShift!['maDonDat'] ?? ''}! Dù khách hàng rảnh nhưng lịch của bạn bị trùng, vui lòng chọn Phương án 2 (Dời sang ngày mới) hoặc đổi sang khung giờ Sáng/Chiều còn trống.';
                                            } else {
                                              modalError =
                                                  'Khung giờ $selectedStartStr - $selectedEndStr ngày $activeTargetFmt đang bị trùng với ca ${conflictingShift!['maDonDat'] ?? ''}. Vui lòng chọn Ca sáng/Ca chiều còn trống hoặc đổi ngày khác!';
                                            }
                                          });
                                          return;
                                        }
                                        setModalState(() {
                                          isSubmitting = true;
                                          modalError = null;
                                        });
                                        try {
                                          final res = await _apiService.resolveOverdueAssignment(
                                            phanCongId: phanCongId,
                                            action: selectedAction,
                                            lichLamViecId: targetLlvId,
                                            ngayMoi: needsDatePicker
                                                ? toIsoDate(selectedNewDate)
                                                : null,
                                            gioBatDauMoi: usesTargetSlot
                                                ? selectedStartStr
                                                : null,
                                            ghiChu: noteController.text.trim(),
                                          );
                                          if (!mounted) return;
                                          if (res.success) {
                                            if (sheetCtx.mounted) {
                                              Navigator.pop(sheetCtx);
                                            }
                                            final msg = res.data?['message']?.toString() ??
                                                'Đã xử lý ca làm quá hạn thành công!';
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('✅ $msg'),
                                                backgroundColor: AppColors.success,
                                                duration: const Duration(seconds: 3),
                                              ),
                                            );
                                            await _fetchSchedules();
                                          } else {
                                            setModalState(() {
                                              isSubmitting = false;
                                              modalError = res.message;
                                            });
                                          }
                                        } catch (e) {
                                          setModalState(() {
                                            isSubmitting = false;
                                            modalError = 'Lỗi kết nối: $e';
                                          });
                                        }
                                      },
                                icon: isSubmitting
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.check_circle_rounded, size: 18),
                                label: Text(
                                  isSubmitting
                                      ? 'Đang cập nhật...'
                                      : 'Xác nhận thực hiện phương án',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primary,
                                  disabledBackgroundColor: const Color(0xFFCBD5E1),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Future<void> _handleCompleteJob(Map<String, dynamic> s) async {
    final int phanCongId = s['phanCongId'] ?? s['id'] ?? 0;
    if (phanCongId == 0) return;

    setState(() => _isLoading = true);
    try {
      final res = await _apiService.completeAssignment(id: phanCongId);
      if (res.success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã hoàn thành ca làm việc!'),
            backgroundColor: AppColors.success,
          ),
        );
        await _fetchSchedules();
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
  String _getShiftTimingStatus(Map<String, dynamic> s) {
    final rawDate = s['ngayLam']?.toString() ?? s['ngayThucHien']?.toString();
    final diff = _daysDiff(rawDate);
    if (diff == null) return 'READY';

    if (diff < 0) return 'OVERDUE';
    if (diff > 0) return 'TOO_EARLY';

    // diff == 0: Đúng ngày hôm nay -> xét giờ (LocalTime)
    final String startStr = _fmtTime(s['gioBatDau']?.toString());
    final String endStr = _fmtTime(s['gioKetThuc']?.toString());
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

  int? _daysDiff(String? raw) {
    if (raw == null || raw.length < 10) return null;
    final d = DateTime.tryParse(raw.substring(0, 10));
    if (d == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return DateTime(d.year, d.month, d.day).difference(today).inDays;
  }

  String? _dayLabel(String raw) {
    final diff = _daysDiff(raw);
    if (diff == null) return null;
    if (diff == 0) return 'Hôm nay';
    if (diff == 1) return 'Ngày mai';
    if (diff == -1) return 'Hôm qua';
    return null;
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
}