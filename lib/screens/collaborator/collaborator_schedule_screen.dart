import 'package:flutter/material.dart';
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
    extends State<CollaboratorScheduleScreen> {
  int _selectedView = 0; // 0 = week, 1 = list
  int _selectedDayIndex = 0; 
  bool _isLoading = true;
  int _currentUserId = 0;

  final CollaboratorApiService _apiService = CollaboratorApiService();
  final List<String> _weekDayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
  
  DateTime _focusedDate = DateTime.now(); // Ngày mốc để xác định tuần đang xem
  List<DateTime> _weekDates = [];
  List<Map<String, dynamic>> _allSchedules = [];

  @override
  void initState() {
    super.initState();
    _generateWeek(_focusedDate);
    _loadUserAndFetchSchedules();
  }

  // Hàm tạo ra 7 ngày trong tuần dựa trên một ngày bất kỳ
  void _generateWeek(DateTime date) {
    // weekday: 1 (T2) -> 7 (CN)
    int currentWeekday = date.weekday; 
    // Tìm ngày Thứ 2 của tuần đó
    DateTime monday = DateTime(date.year, date.month, date.day).subtract(Duration(days: currentWeekday - 1));
    
    List<DateTime> dates = [];
    for (int i = 0; i < 7; i++) {
      dates.add(monday.add(Duration(days: i)));
    }

    setState(() {
      _weekDates = dates;
      
      // Nếu tuần này là tuần hiện tại, tự động chọn ngày hôm nay
      final now = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(now);
      
      int foundToday = -1;
      for(int i=0; i<dates.length; i++) {
        if(DateFormat('yyyy-MM-dd').format(dates[i]) == todayStr) {
          foundToday = i;
          break;
        }
      }
      
      if (foundToday != -1) {
        _selectedDayIndex = foundToday;
      } else {
        _selectedDayIndex = 0; // Mặc định chọn Thứ 2 nếu xem tuần khác
      }
    });
  }

  // Hàm chuyển tuần (step = 1: tới, step = -1: lùi)
  void _changeWeek(int step) {
    setState(() {
      _focusedDate = _focusedDate.add(Duration(days: step * 7));
      _generateWeek(_focusedDate);
    });
  }

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
      final response = await _apiService.getSchedules(congTacVienId: _currentUserId);
      if (response.success && response.data != null) {
        setState(() {
          _allSchedules = List<Map<String, dynamic>>.from(response.data!);
        });
      }
    } catch (e) {
      debugPrint('Lỗi tải lịch làm việc: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Lọc danh sách ca làm việc của ngày đang được chọn trên thanh lịch
  List<Map<String, dynamic>> get _schedulesForSelectedDay {
    if (_weekDates.isEmpty || _selectedDayIndex >= _weekDates.length) return [];
    final selectedDateStr = DateFormat('yyyy-MM-dd').format(_weekDates[_selectedDayIndex]);
    
    return _allSchedules.where((s) {
      final ngayLam = s['ngayLam']?.toString() ?? '';
      return ngayLam.startsWith(selectedDateStr);
    }).toList();
  }

  // Kiểm tra ngày có đơn hay không để hiện dấu chấm
  bool _hasOrderOnDay(int index) {
    if (_weekDates.isEmpty || index >= _weekDates.length) return false;
    final dateStr = DateFormat('yyyy-MM-dd').format(_weekDates[index]);
    return _allSchedules.any((s) => (s['ngayLam']?.toString() ?? '').startsWith(dateStr));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Lịch làm việc'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchSchedules,
          ),
          IconButton(
            icon: Icon(
              _selectedView == 0 ? Icons.list : Icons.calendar_view_week,
              color: AppColors.white,
            ),
            onPressed: () => setState(() => _selectedView = 1 - _selectedView),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.brand500))
          : Column(
              children: [
                _buildWeekNavigator(),
                _buildStats(),
                Expanded(
                  child: _selectedView == 0
                      ? _buildDayView()
                      : _buildListView(),
                ),
              ],
            ),
    );
  }

  // UI Thanh điều hướng tuần (Có mũi tên sang trái/phải)
  Widget _buildWeekNavigator() {
    String monthYear = DateFormat('MMMM yyyy', 'vi_VN').format(_focusedDate);
    if (monthYear.isNotEmpty) {
      monthYear = monthYear[0].toUpperCase() + monthYear.substring(1);
    }

    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.calendar_month, color: AppColors.brand500, size: 18),
                const SizedBox(width: 8),
                Text(
                  monthYear,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                // Nút chuyển về tuần trước
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 28, color: AppColors.brand600),
                  onPressed: () => _changeWeek(-1),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 20),
                // Nút chuyển sang tuần sau
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 28, color: AppColors.brand600),
                  onPressed: () => _changeWeek(1),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Danh sách 7 ngày trong tuần
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
                final isToday = DateFormat('yyyy-MM-dd').format(date) == DateFormat('yyyy-MM-dd').format(DateTime.now());
                final hasOrder = _hasOrderOnDay(i);

                return GestureDetector(
                  onTap: () => setState(() => _selectedDayIndex = i),
                  child: Container(
                    width: (MediaQuery.of(context).size.width - 24) / 7,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.brand500 : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: isToday && !isSelected ? Border.all(color: AppColors.brand500, width: 1.5) : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _weekDayLabels[i],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: isSelected ? AppColors.white : AppColors.textPrimary,
                          ),
                        ),
                        if (hasOrder)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : AppColors.brand500,
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

  Widget _buildStats() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.brand700, AppColors.brand500],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _statItem('${_allSchedules.length}', 'Tổng ca phân', Icons.work_outline),
          _divider(),
          _statItem('Hoạt động', 'Trạng thái', Icons.check_circle_outline),
          _divider(),
          _statItem('5.0★', 'Đánh giá', Icons.star_outline),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.white)),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 36, color: Colors.white24);

  Widget _buildDayView() {
    final schedules = _schedulesForSelectedDay;
    if (schedules.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available, size: 60, color: AppColors.brand300),
            const SizedBox(height: 12),
            Text(
              'Không có lịch vào ${_weekDayLabels[_selectedDayIndex]}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
            const Text('Hãy tận hưởng ngày nghỉ của bạn 🎉', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
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
      return const Center(child: Text('Không có ca làm việc nào', style: TextStyle(color: AppColors.textSecondary)));
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 12, bottom: 20),
      itemCount: _allSchedules.length,
      itemBuilder: (context, index) {
        final s = _allSchedules[index];
        final dateStr = s['ngayLam']?.toString() ?? '';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (index == 0 || _allSchedules[index - 1]['ngayLam'] != s['ngayLam'])
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(dateStr, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.brand600)),
              ),
            _buildScheduleCard(s),
          ],
        );
      },
    );
  }

  Widget _buildScheduleCard(Map<String, dynamic> s) {
    final String serviceName = s['tenDichVu'] ?? 'Dịch vụ giúp việc';
    final String customerName = s['khachHangTen'] ?? 'Khách hàng';
    final String address = s['diaChi'] ?? 'Chưa cập nhật địa chỉ';
    final String timeStr = '${s['gioBatDau'] ?? ''} - ${s['gioKetThuc'] ?? ''}';
    final String status = s['trangThai'] ?? 'SapToi';
    
    final statusLabel = status == 'HoanThanh' ? 'Hoàn thành' : 'Sắp tới';
    final statusColor = status == 'HoanThanh' ? AppColors.success : AppColors.brand500;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(width: 6, decoration: BoxDecoration(color: statusColor, borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)))),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(serviceName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: Text(statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _infoRow(Icons.person_outline, customerName),
                    const SizedBox(height: 4),
                    _infoRow(Icons.access_time, timeStr),
                    const SizedBox(height: 4),
                    _infoRow(Icons.location_on_outlined, address),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
