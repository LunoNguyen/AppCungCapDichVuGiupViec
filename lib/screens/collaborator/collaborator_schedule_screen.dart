import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class CollaboratorScheduleScreen extends StatefulWidget {
  const CollaboratorScheduleScreen({super.key});

  @override
  State<CollaboratorScheduleScreen> createState() =>
      _CollaboratorScheduleScreenState();
}

class _CollaboratorScheduleScreenState
    extends State<CollaboratorScheduleScreen> {
  int _selectedView = 0; // 0 = week, 1 = list
  int _selectedDay = DateTime.now().weekday - 1;

  final List<String> _weekDays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
  final List<int> _dates = [29, 30, 1, 2, 3, 4, 5]; // Demo dates

  final List<Map<String, dynamic>> _allSchedules = [
    {
      'day': 0, // Monday
      'service': 'Dọn dẹp nhà cơ bản',
      'customer': 'Nguyễn Thị B',
      'time': '08:00 – 10:00',
      'address': '123 Nguyễn Trãi, Q.1',
      'price': '300.000đ',
      'status': 'upcoming',
      'color': AppColors.brand500,
    },
    {
      'day': 1, // Tuesday
      'service': 'Giặt ủi quần áo',
      'customer': 'Trần Văn C',
      'time': '09:00 – 11:00',
      'address': '456 Lê Văn Sỹ, Q.3',
      'price': '150.000đ',
      'status': 'upcoming',
      'color': Color(0xFF4CAF50),
    },
    {
      'day': 1, // Tuesday
      'service': 'Nấu ăn tại nhà',
      'customer': 'Lê Thị D',
      'time': '14:00 – 17:00',
      'address': '789 Đinh Tiên Hoàng, Q.BT',
      'price': '200.000đ',
      'status': 'upcoming',
      'color': Color(0xFFFF5722),
    },
    {
      'day': 3, // Thursday
      'service': 'Dọn dẹp tổng thể',
      'customer': 'Phạm Văn E',
      'time': '08:00 – 12:00',
      'address': '321 Pasteur, Q.1',
      'price': '500.000đ',
      'status': 'inProgress',
      'color': AppColors.brand600,
    },
    {
      'day': 5, // Saturday
      'service': 'Trông trẻ',
      'customer': 'Hoàng Thị F',
      'time': '14:00 – 18:00',
      'address': '99 Võ Thị Sáu, Q.1',
      'price': '320.000đ',
      'status': 'upcoming',
      'color': Color(0xFF9C27B0),
    },
  ];

  List<Map<String, dynamic>> get _schedulesForSelectedDay =>
      _allSchedules.where((s) => s['day'] == _selectedDay).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Lịch làm việc'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(
              _selectedView == 0 ? Icons.list : Icons.calendar_view_week,
              color: AppColors.white,
            ),
            onPressed: () => setState(() => _selectedView = 1 - _selectedView),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildWeekSelector(),
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

  Widget _buildWeekSelector() {
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
                const SizedBox(width: 6),
                const Text(
                  'Tuần 40 • Tháng 9/2026',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 20),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 20),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 62,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: 7,
              itemBuilder: (context, i) {
                final selected = i == _selectedDay;
                final hasOrder = _allSchedules.any((s) => s['day'] == i);
                return GestureDetector(
                  onTap: () => setState(() => _selectedDay = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.brand500 : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _weekDays[i],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: selected
                                ? Colors.white70
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_dates[i]}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: selected ? AppColors.white : AppColors.textPrimary,
                          ),
                        ),
                        if (hasOrder)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: selected ? Colors.white : AppColors.brand300,
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
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand500.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _statItem('5', 'Ca tuần này', Icons.work_outline),
          _divider(),
          _statItem('1.450.000đ', 'Thu nhập', Icons.account_balance_wallet_outlined),
          _divider(),
          _statItem('4.9★', 'Đánh giá', Icons.star_outline),
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
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: AppColors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 36, color: Colors.white24);
  }

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
              'Không có lịch vào ${_weekDays[_selectedDay]}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Hãy tận hưởng ngày nghỉ của bạn 🎉',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
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
    return ListView.builder(
      padding: const EdgeInsets.only(top: 12, bottom: 20),
      itemCount: _allSchedules.length,
      itemBuilder: (context, index) {
        final s = _allSchedules[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (index == 0 ||
                _allSchedules[index - 1]['day'] != s['day'])
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  '${_weekDays[s['day'] as int]}, ${_dates[s['day'] as int]}/09/2026',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.brand600,
                  ),
                ),
              ),
            _buildScheduleCard(s),
          ],
        );
      },
    );
  }

  Widget _buildScheduleCard(Map<String, dynamic> s) {
    final statusLabel = s['status'] == 'inProgress' ? 'Đang thực hiện' : 'Sắp tới';
    final statusColor = s['status'] == 'inProgress' ? AppColors.warning : AppColors.brand500;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: s['color'] as Color,
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(16)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            s['service'] as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.person_outline,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          s['customer'] as String,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const Spacer(),
                        Text(
                          s['price'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.brand600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          s['time'] as String,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            s['address'] as String,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
}
