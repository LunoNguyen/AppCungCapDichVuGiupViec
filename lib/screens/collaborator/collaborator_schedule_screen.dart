import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
          final status = (a['trangThaiPhanCong']?.toString() ?? a['trangThai']?.toString() ?? '').toLowerCase();
          if (status == 'tuchoi' || status == 'dahuy' || status == 'choduyet') continue;

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

    // Màu trạng thái
    Color sc;
    String statusText;
    if (isCompleted) {
      sc = const Color(0xFF16A34A);
      statusText = 'Hoàn thành';
    } else if (isWorking) {
      sc = const Color(0xFF2563EB);
      statusText = 'Đang làm';
    } else {
      sc = isPackage ? const Color(0xFFD97706) : AppColors.partner500;
      statusText = 'Sắp tới';
    }

    final String? dayLbl = _dayLabel(rawDate);
    final avatar = _avatarPair(customerName);
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final bool isToday = rawDate.startsWith(todayStr);

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
                              '🔄 Gói tháng (Buổi $buoiThu/$soBuoi)',
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
                            '📊 Còn ${soBuoi - buoiThu} buổi trong tháng',
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
                            onPressed: () => _handleStartJob(s, isToday, dateStr),
                            icon: Icon(
                              isToday ? Icons.play_arrow_rounded : Icons.lock_outline_rounded,
                              size: 15,
                            ),
                            label: const Text('Bắt đầu làm', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isToday ? _primary : const Color(0xFF94A3B8),
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

  Future<void> _handleStartJob(Map<String, dynamic> s, bool isToday, String dateStr) async {
    if (!isToday) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Chưa đến ngày làm việc, bạn chưa thể bắt đầu ca này!\n(Lịch làm: $dateStr)'),
          backgroundColor: AppColors.warning,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

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
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoading = false);
    }
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