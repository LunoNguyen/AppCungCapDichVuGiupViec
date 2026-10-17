import 'package:flutter/material.dart';
import '../../../core/app_colors.dart';
import '../../../services/catalog_ui.dart';
import '../../../services/nhom_dich_vu.dart';

/// Bước 2: Theo lần / Gói tháng. Hình thức dịch vụ không có thì mờ, không bấm được.
class BuocHinhThuc extends StatelessWidget {
  final NhomDichVu nhom;
  final String? loaiChon;
  final ValueChanged<String> onChon;

  const BuocHinhThuc({super.key, required this.nhom, required this.loaiChon, required this.onChon});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          nhom.ten,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 4),
        const Text('Chọn hình thức đặt', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 12),
        _the(
          loai: 'TheoLan',
          coDuoc: nhom.coTheoLan,
          icon: Icons.event_available_rounded,
          ten: 'Theo lần',
          moTa: 'Đặt một buổi, chọn ngày trong vòng 1 tháng tới.',
          khongCo: 'Dịch vụ này không đặt theo lần',
        ),
        _the(
          loai: 'GoiThang',
          coDuoc: nhom.coGoiThang,
          icon: Icons.date_range_rounded,
          ten: 'Gói tháng',
          moTa: 'Nhiều buổi trong 1 tháng theo các thứ bạn chọn, bắt đầu trong vòng 3 tháng tới.',
          khongCo: 'Dịch vụ này chưa có gói tháng',
        ),
      ],
    );
  }

  Widget _the({
    required String loai,
    required bool coDuoc,
    required IconData icon,
    required String ten,
    required String moTa,
    required String khongCo,
  }) {
    final chon = coDuoc && loai == loaiChon;
    final gia = nhom
        .bienTheTheoLoai(loai)
        .map((b) => (num.tryParse(b['donGiaThamKhao']?.toString() ?? '') ?? 0).round())
        .where((g) => g > 0);
    final giaTu = gia.isEmpty ? 0 : gia.reduce((a, b) => a < b ? a : b);
    return Opacity(
      opacity: coDuoc ? 1 : 0.45,
      child: GestureDetector(
        onTap: coDuoc ? () => onChon(loai) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: chon ? AppColors.brandSurface : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: chon ? AppColors.brand500 : AppColors.divider, width: chon ? 1.5 : 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(color: AppColors.brandLight, shape: BoxShape.circle),
                child: Icon(icon, color: AppColors.brand500),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ten,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(coDuoc ? moTa : khongCo,
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.35)),
                    if (coDuoc && giaTu > 0) ...[
                      const SizedBox(height: 6),
                      Text('Từ ${CatalogUi.money(giaTu)}',
                          style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.brand600)),
                    ],
                  ],
                ),
              ),
              Icon(
                chon ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: chon ? AppColors.brand500 : AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
