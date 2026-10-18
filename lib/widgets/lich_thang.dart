import 'package:flutter/material.dart';

import '../core/app_colors.dart';

/// Lịch tháng chọn một ngày (cùng giao diện với lịch đặt dịch vụ trên web):
/// - chỉ chọn trong [ngayDau]..[ngayCuoi], ngày ngoài khoảng bị mờ và gạch;
/// - [ngayTo]: các ngày tô nhạt (vd các buổi của gói tháng);
/// - tuần bắt đầu thứ Hai, có chấm đánh dấu hôm nay.
class LichThang extends StatefulWidget {
  final DateTime? ngayChon;
  final DateTime ngayDau;
  final DateTime ngayCuoi;
  final Set<DateTime> ngayTo;
  final ValueChanged<DateTime> onChon;

  const LichThang({
    super.key,
    required this.ngayChon,
    required this.ngayDau,
    required this.ngayCuoi,
    required this.onChon,
    this.ngayTo = const {},
  });

  static DateTime chiNgay(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  State<LichThang> createState() => _LichThangState();
}

class _LichThangState extends State<LichThang> {
  static const _thu = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
  late DateTime _thang; // ngày 1 của tháng đang xem

  @override
  void initState() {
    super.initState();
    final goc = widget.ngayChon ?? widget.ngayDau;
    _thang = DateTime(goc.year, goc.month);
  }

  bool _cungNgay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  bool _trongKhoang(DateTime d) =>
      !d.isBefore(LichThang.chiNgay(widget.ngayDau)) && !d.isAfter(LichThang.chiNgay(widget.ngayCuoi));

  bool get _luiDuoc => _thang.isAfter(DateTime(widget.ngayDau.year, widget.ngayDau.month));
  bool get _toiDuoc => _thang.isBefore(DateTime(widget.ngayCuoi.year, widget.ngayCuoi.month));

  @override
  Widget build(BuildContext context) {
    final homNay = LichThang.chiNgay(DateTime.now());
    final to = widget.ngayTo.map(LichThang.chiNgay).toSet();
    // Ô đầu tiên: thứ Hai của tuần chứa ngày 1
    final dauLuoi = _thang.subtract(Duration(days: _thang.weekday - 1));
    final soNgayThang = DateTime(_thang.year, _thang.month + 1, 0).day;
    final soO = ((_thang.weekday - 1 + soNgayThang) / 7).ceil() * 7;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _nutThang(Icons.chevron_left_rounded, _luiDuoc,
                () => setState(() => _thang = DateTime(_thang.year, _thang.month - 1))),
            Expanded(
              child: Text('Tháng ${_thang.month}, ${_thang.year}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            ),
            _nutThang(Icons.chevron_right_rounded, _toiDuoc,
                () => setState(() => _thang = DateTime(_thang.year, _thang.month + 1))),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final t in _thu)
              Expanded(
                child: Center(
                  child: Text(t,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: soO,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7, mainAxisSpacing: 4, crossAxisSpacing: 4, childAspectRatio: 1.05),
          itemBuilder: (context, i) {
            final d = DateTime(dauLuoi.year, dauLuoi.month, dauLuoi.day + i);
            final trongThang = d.month == _thang.month;
            final chonDuoc = trongThang && _trongKhoang(d);
            final dangChon = widget.ngayChon != null && _cungNgay(d, widget.ngayChon!);
            final coBuoi = trongThang && to.contains(d);
            final laHomNay = _cungNgay(d, homNay);

            Color nen = Colors.transparent;
            Color chu = AppColors.textPrimary;
            if (!trongThang) {
              chu = AppColors.textMuted.withValues(alpha: 0.5);
            } else if (!chonDuoc) {
              chu = AppColors.textMuted;
            }
            if (coBuoi) {
              nen = AppColors.brandLight;
              chu = AppColors.brand600;
            }
            if (dangChon) {
              nen = AppColors.brand500;
              chu = Colors.white;
            }

            return Semantics(
              button: chonDuoc,
              selected: dangChon,
              label: '${d.day}/${d.month}/${d.year}',
              child: Material(
                color: nen,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: chonDuoc ? () => widget.onChon(d) : null,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '${d.day}',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: dangChon || coBuoi || laHomNay ? FontWeight.w800 : FontWeight.w500,
                          color: laHomNay && !dangChon && !coBuoi ? AppColors.brand500 : chu,
                          decoration: trongThang && !chonDuoc ? TextDecoration.lineThrough : null,
                          decorationColor: AppColors.textMuted,
                        ),
                      ),
                      if (laHomNay)
                        Positioned(
                          bottom: 5,
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: dangChon ? Colors.white : AppColors.brand500,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _nutThang(IconData icon, bool bat, VoidCallback onTap) {
    return IconButton(
      onPressed: bat ? onTap : null,
      icon: Icon(icon),
      color: AppColors.textSecondary,
      disabledColor: AppColors.divider,
      style: IconButton.styleFrom(
        backgroundColor: bat ? AppColors.brandSurface : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
