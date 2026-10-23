import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_colors.dart';

/// Hiển thị bộ chọn giờ dạng con lăn bánh cuộn (Cupertino Wheel) kết hợp các khung giờ gợi ý nhanh
/// Thay thế hoàn toàn cho đồng hồ tròn xoay kim Material mặc định vốn khó dùng và dễ bấm nhầm.
Future<TimeOfDay?> showAppTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
  String title = 'Chọn giờ bắt đầu ca làm',
  int minHour = 6,
  int maxHour = 22,
  int minuteStep = 5,
}) async {
  return showModalBottomSheet<TimeOfDay>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _AppTimePickerModal(
      initialTime: initialTime,
      title: title,
      minHour: minHour,
      maxHour: maxHour,
      minuteStep: minuteStep,
    ),
  );
}

class _AppTimePickerModal extends StatefulWidget {
  final TimeOfDay initialTime;
  final String title;
  final int minHour;
  final int maxHour;
  final int minuteStep;

  const _AppTimePickerModal({
    required this.initialTime,
    required this.title,
    required this.minHour,
    required this.maxHour,
    required this.minuteStep,
  });

  @override
  State<_AppTimePickerModal> createState() => _AppTimePickerModalState();
}

class _AppTimePickerModalState extends State<_AppTimePickerModal> {
  late int _selectedHour;
  late int _selectedMinute;

  late final List<int> _hours;
  late final List<int> _minutes;

  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

  static const Color _primary = Color(0xFF0D9488);
  static const Color _ink = Color(0xFF0F172A);

  @override
  void initState() {
    super.initState();
    _hours = List.generate(
      widget.maxHour - widget.minHour + 1,
      (i) => widget.minHour + i,
    );

    _minutes = [];
    for (int m = 0; m < 60; m += widget.minuteStep) {
      _minutes.add(m);
    }

    // Clamp initial hour
    int initH = widget.initialTime.hour;
    if (initH < widget.minHour) initH = widget.minHour;
    if (initH > widget.maxHour) initH = widget.maxHour;
    _selectedHour = initH;

    // Round initial minute to nearest step
    int initM = (widget.initialTime.minute / widget.minuteStep).round() * widget.minuteStep;
    if (initM >= 60) initM = 60 - widget.minuteStep;
    _selectedMinute = initM;

    final hourIndex = _hours.indexOf(_selectedHour);
    final minuteIndex = _minutes.indexOf(_selectedMinute);

    _hourController = FixedExtentScrollController(
      initialItem: hourIndex >= 0 ? hourIndex : 0,
    );
    _minuteController = FixedExtentScrollController(
      initialItem: minuteIndex >= 0 ? minuteIndex : 0,
    );
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _onQuickSelect(int h, int m) {
    if (h < widget.minHour || h > widget.maxHour) return;
    setState(() {
      _selectedHour = h;
      _selectedMinute = m;
    });

    final hIdx = _hours.indexOf(h);
    final mIdx = _minutes.indexOf(m);

    if (hIdx >= 0 && _hourController.hasClients) {
      _hourController.animateToItem(
        hIdx,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
    if (mIdx >= 0 && _minuteController.hasClients) {
      _minuteController.animateToItem(
        mIdx,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }

    HapticFeedback.lightImpact();
  }

  String _getPeriodLabel(int hour) {
    if (hour < 12) return '☀️ Buổi sáng';
    if (hour < 18) return '🌤️ Buổi chiều';
    return '🌙 Buổi tối';
  }

  Color _getPeriodColor(int hour) {
    if (hour < 12) return const Color(0xFFB45309);
    if (hour < 18) return const Color(0xFF2563EB);
    return const Color(0xFF7C3AED);
  }

  Color _getPeriodBg(int hour) {
    if (hour < 12) return const Color(0xFFFEF3C7);
    if (hour < 18) return const Color(0xFFEFF6FF);
    return const Color(0xFFF3E8FF);
  }

  @override
  Widget build(BuildContext context) {
    final hourStr = _selectedHour.toString().padLeft(2, '0');
    final minStr = _selectedMinute.toString().padLeft(2, '0');
    final periodLabel = _getPeriodLabel(_selectedHour);
    final periodColor = _getPeriodColor(_selectedHour);
    final periodBg = _getPeriodBg(_selectedHour);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 38,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCCFBF1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.access_time_filled, size: 20, color: _primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 1),
                      const Text(
                        'Cuộn con lăn hoặc chọn khung giờ nhanh',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 22, color: Color(0xFF64748B)),
                  splashRadius: 20,
                  tooltip: 'Đóng',
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Digital Display Badge
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF0FDFA), Color(0xFFF8FAFC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF99F6E4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        '$hourStr : $minStr',
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: _primary,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: periodBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      periodLabel,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: periodColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Quick Presets
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Khung giờ gợi ý nhanh:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildPresetChip('07:30', 7, 30),
                      _buildPresetChip('08:00', 8, 0),
                      _buildPresetChip('08:30', 8, 30),
                      _buildPresetChip('09:00', 9, 0),
                      _buildPresetChip('09:30', 9, 30),
                      _buildPresetChip('13:30', 13, 30),
                      _buildPresetChip('14:00', 14, 0),
                      _buildPresetChip('14:30', 14, 30),
                      _buildPresetChip('15:00', 15, 0),
                      _buildPresetChip('17:00', 17, 0),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Wheel Picker Container
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 160,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Stack(
              children: [
                // Highlight middle band
                Center(
                  child: Container(
                    height: 44,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _primary.withValues(alpha: 0.3)),
                    ),
                  ),
                ),

                // Wheels
                Row(
                  children: [
                    // Hour Wheel
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: _hourController,
                        itemExtent: 44,
                        squeeze: 1.15,
                        diameterRatio: 1.2,
                        selectionOverlay: const SizedBox.shrink(),
                        onSelectedItemChanged: (index) {
                          setState(() => _selectedHour = _hours[index]);
                          HapticFeedback.selectionClick();
                        },
                        children: _hours.map((h) {
                          final isSelected = h == _selectedHour;
                          return Center(
                            child: Text(
                              '${h.toString().padLeft(2, '0')} giờ',
                              style: TextStyle(
                                fontSize: isSelected ? 18.5 : 15,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                color: isSelected ? _primary : const Color(0xFF94A3B8),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // Colon separator
                    const Text(
                      ':',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: _primary,
                      ),
                    ),

                    // Minute Wheel
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: _minuteController,
                        itemExtent: 44,
                        squeeze: 1.15,
                        diameterRatio: 1.2,
                        selectionOverlay: const SizedBox.shrink(),
                        onSelectedItemChanged: (index) {
                          setState(() => _selectedMinute = _minutes[index]);
                          HapticFeedback.selectionClick();
                        },
                        children: _minutes.map((m) {
                          final isSelected = m == _selectedMinute;
                          return Center(
                            child: Text(
                              '${m.toString().padLeft(2, '0')} phút',
                              style: TextStyle(
                                fontSize: isSelected ? 18.5 : 15,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                color: isSelected ? _primary : const Color(0xFF94A3B8),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Confirm button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Navigator.of(context).pop(
                    TimeOfDay(hour: _selectedHour, minute: _selectedMinute),
                  );
                },
                icon: const Icon(Icons.check_circle_rounded, size: 20),
                label: Text(
                  'Xác nhận giờ: $hourStr:$minStr',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(String label, int h, int m) {
    final isSelected = _selectedHour == h && _selectedMinute == m;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _onQuickSelect(h, m),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? _primary : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? _primary : const Color(0xFFE2E8F0),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF334155),
            ),
          ),
        ),
      ),
    );
  }
}
