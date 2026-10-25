import 'package:flutter/material.dart';
import '../../../core/app_colors.dart';
import '../../../services/catalog_ui.dart';
import '../../../services/nhom_dich_vu.dart';

/// Bước 2: Theo lần / Gói tháng, rồi thời lượng / gói của hình thức đó (2 giờ, 3 giờ… hoặc gói 8 buổi…).
/// Hình thức dịch vụ không có thì mờ, không bấm được.
class BuocHinhThuc extends StatelessWidget {
  final NhomDichVu nhom;
  final String? loaiChon;
  final ValueChanged<String> onChon;
  final int? dichVuId;
  final ValueChanged<int> onChonBienThe;

  const BuocHinhThuc({
    super.key,
    required this.nhom,
    required this.loaiChon,
    required this.onChon,
    required this.dichVuId,
    required this.onChonBienThe,
  });

  @override
  Widget build(BuildContext context) {
    final laGoi = loaiChon == 'GoiThang';
    final bienThes = loaiChon == null ? const <Map<String, dynamic>>[] : nhom.bienTheTheoLoai(loaiChon!);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          nhom.ten,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 4),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(color: AppColors.divider.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              _nutLoai('TheoLan', 'Theo lần', nhom.coTheoLan),
              _nutLoai('GoiThang', 'Gói tháng', nhom.coGoiThang),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          laGoi
              ? 'Nhiều buổi trong 1 tháng theo các thứ bạn chọn, bắt đầu trong vòng 3 tháng tới.'
              : 'Một buổi làm, chọn ngày trong vòng 1 tháng tới.',
          style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.35),
        ),
        if (bienThes.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            laGoi ? 'Chọn gói' : 'Chọn thời lượng',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          for (final b in bienThes) _bienThe(b),
        ],
      ],
    );
  }

  /// Một dòng thời lượng / gói: nhãn ngắn + giá, chọn bằng nút tròn.
  Widget _bienThe(Map<String, dynamic> b) {
    final id = CatalogUi.toInt(b['id']);
    final chon = id == dichVuId;
    return GestureDetector(
      onTap: () => onChonBienThe(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: chon ? AppColors.brandSurface : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: chon ? AppColors.brand500 : AppColors.divider, width: chon ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                NhomDichVu.nhanBienThe(b),
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              CatalogUi.money(b['donGiaThamKhao']),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: chon ? AppColors.brand600 : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              chon ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: chon ? AppColors.brand500 : AppColors.textMuted,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  /// Một nút hình thức trong thanh chọn; hình thức dịch vụ không có thì mờ, không bấm được.
  Widget _nutLoai(String loai, String nhan, bool coDuoc) {
    final chon = coDuoc && loai == loaiChon;
    return Expanded(
      child: Opacity(
        opacity: coDuoc ? 1 : 0.4,
        child: GestureDetector(
          onTap: coDuoc ? () => onChon(loai) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: chon ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
              boxShadow: chon ? const [BoxShadow(color: Color(0x14000000), blurRadius: 2, offset: Offset(0, 1))] : null,
            ),
            child: Text(
              nhan,
              style: TextStyle(
                fontWeight: chon ? FontWeight.w800 : FontWeight.w600,
                color: chon ? AppColors.brand600 : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
