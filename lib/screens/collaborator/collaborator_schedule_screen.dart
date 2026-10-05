import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import '../../services/collaborator_api_service.dart';

class CollaboratorScheduleScreen extends StatefulWidget {
  const CollaboratorScheduleScreen({super.key});

  @override
  State<CollaboratorScheduleScreen> createState() =>
      _CollaboratorScheduleScreenState();
}

class _CollaboratorScheduleScreenState
    extends State<CollaboratorScheduleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _viewTabController;
  int _selectedDayIndex = 0;
  bool _isLoading = true;
  int _currentUserId = 0;

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
  static const _money = AppColors.brand500;
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
      final seenIds = <dynamic>{};

      if (res.success && res.data != null) {
        for (final item in res.data!) {
          final id = item['id'] ?? item['donDatId'];
          if (id != null) seenIds.add(id);
          combined.add({
            ...item,
            'ngayLam': item['ngayLam'] ?? item['ngayThucHien'] ?? item['ngayLamViec'],
          });
        }
      }

      if (ass.success && ass.data != null) {
        for (final a in ass.data!) {
          final id = a['id'] ?? a['donDatId'];
          if (!seenIds.contains(id)) {
            if (id != null) seenIds.add(id);
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
                      color: _primary))
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
            unselectedLabelColor: Colors.white.withValues(alpha: 0.75),
            labelStyle:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            unselectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            tabs: const [
              Tab(text: 'Theo ngày'),
              Tab(text: 'Tất cả ca'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayViewWithNavigator() {
    return Column(
      children: [
        _buildWeekNavigator(),
        Expanded(child: _buildDayView()),
      ],
    );
  }

  Widget _buildWeekNavigator() {
    String monthYear = DateFormat('MMMM yyyy', 'vi_VN').format(_focusedDate);
    if (monthYear.isNotEmpty) {
      monthYear = monthYear[0].toUpperCase() + monthYear.substring(1);
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.calendar_month, color: _primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    monthYear,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_left,
                      size: 28, color: _primary),
                  onPressed: () => _changeWeek(-1),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 20),
                IconButton(
                  icon: const Icon(Icons.chevron_right,
                      size: 28, color: _primary),
                  onPressed: () => _changeWeek(1),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 64,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 7,
              itemBuilder: (context, i) {
                final date = _weekDates[i];
                final isSelected = i == _selectedDayIndex;
                final isToday = DateFormat('yyyy-MM-dd').format(date) ==
                    DateFormat('yyyy-MM-dd').format(DateTime.now());
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
                              color: isSelected ? Colors.white : AppColors.partner500,
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
            const Icon(Icons.event_available, size: 60, color: AppColors.ctvYellowBorder),
            const SizedBox(height: 12),
            Text(
              'Không có lịch vào ${_weekDayLabels[_selectedDayIndex]}',
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary),
            ),
            const Text('Hãy tận hưởng ngày nghỉ của bạn 🎉',
                style:
                TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 12, bottom: 20),
      itemCount: schedules.length,
      itemBuilder: (context, index) => _buildScheduleCard(schedules[index]),
    );
  }

  Widget _buildListView() {
    if (_allSchedules.isEmpty) {
      return const Center(
          child: Text('Không có ca làm việc nào',
              style: TextStyle(color: AppColors.textSecondary)));
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 12, bottom: 20),
      itemCount: _allSchedules.length,
      itemBuilder: (context, index) {
        final s = _allSchedules[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (index == 0 ||
                _allSchedules[index - 1]['ngayLam'] != s['ngayLam'])
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  _fmtDate(s['ngayLam']?.toString() ?? ''),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppColors.textSecondary),
                ),
              ),
            _buildScheduleCard(s),
          ],
        );
      },
    );
  }

  // ===================== THẺ CA LÀM VIỆC =====================

  Widget _buildScheduleCard(Map<String, dynamic> s) {
    final String serviceName = s['tenDichVu'] ?? 'Dịch vụ giúp việc';
    final String customerName = s['khachHangTen'] ?? 'Khách hàng';
    final String address = s['diaChi'] ?? 'Chưa cập nhật địa chỉ';
    final String rawDate = s['ngayLam']?.toString() ?? '';
    final String dateStr = _fmtDate(rawDate);
    final String startStr = _fmtTime(s['gioBatDau']?.toString());
    final String endStr = _fmtTime(s['gioKetThuc']?.toString());
    final String status = s['trangThai'] ?? 'SapToi';

    final bool isCompleted = status == 'HoanThanh';
    final Color sc = isCompleted ? AppColors.success : AppColors.info;
    final String statusText = isCompleted ? 'Hoàn thành' : 'Sắp tới';

    final String? dayLbl = _dayLabel(rawDate);
    final avatar = _avatarPair(customerName);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cột giờ bên trái như timeline
            Container(
              width: 72,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: sc.withValues(alpha: 0.08),
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(12)),
              ),
              child: Column(
                children: [
                  Text(
                    startStr,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: sc,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(width: 1, height: 14, color: sc.withValues(alpha: 0.4)),
                  const SizedBox(height: 2),
                  Text(
                    endStr,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            serviceName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
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
                    const SizedBox(height: 8),
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
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: _ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
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
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 15, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            dayLbl != null ? '$dayLbl, $dateStr' : dateStr,
                            style: const TextStyle(
                              fontSize: 13,
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
    );
  }

  // ===================== HÀM HỖ TRỢ =====================

  String _formatPrice(dynamic v) {
    final n = num.tryParse(v?.toString() ?? '')?.round() ?? 0;
    final s = n
        .toString()
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');
    return '${s}đ';
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
}