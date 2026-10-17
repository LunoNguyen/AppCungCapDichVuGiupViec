import 'package:flutter/material.dart';
import '../../../core/app_colors.dart';
import '../../../services/catalog_ui.dart';
import '../../../services/nhom_dich_vu.dart';

/// Bước 1: các dịch vụ cùng danh mục, mỗi mã dịch vụ một thẻ (ảnh, tên, "Từ …đ").
class BuocDichVu extends StatelessWidget {
  final List<NhomDichVu> nhoms;
  final String? maChon;
  final ValueChanged<NhomDichVu> onChon;
  final bool dangTai;
  final String? loi;
  final VoidCallback? onThuLai;

  const BuocDichVu({
    super.key,
    required this.nhoms,
    required this.maChon,
    required this.onChon,
    required this.dangTai,
    this.loi,
    this.onThuLai,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Chọn dịch vụ',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        if (loi != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.orangeLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.wifi_off_rounded, color: AppColors.orange600, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(loi!, style: const TextStyle(fontSize: 13, color: AppColors.orange600)),
                ),
                if (onThuLai != null) TextButton(onPressed: onThuLai, child: const Text('Thử lại')),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        for (final g in nhoms) _the(g),
        if (dangTai)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(color: AppColors.brand500)),
          ),
      ],
    );
  }

  Widget _the(NhomDichVu g) {
    final chon = g.ma == maChon;
    final anh = CatalogUi.fileUrl(g.anh);
    final hinhThuc = [if (g.coTheoLan) 'Theo lần', if (g.coGoiThang) 'Gói tháng'].join(' · ');
    return GestureDetector(
      onTap: () => onChon(g),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: chon ? AppColors.brandSurface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: chon ? AppColors.brand500 : AppColors.divider, width: chon ? 1.5 : 1),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 64,
                height: 64,
                child: anh == null
                    ? _anhThay(g)
                    : Image.network(anh, fit: BoxFit.cover, errorBuilder: (_, _, _) => _anhThay(g)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    g.ten,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    g.giaTu > 0 ? 'Từ ${CatalogUi.money(g.giaTu)}' : 'Liên hệ báo giá',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.brand600),
                  ),
                  if (hinhThuc.isNotEmpty)
                    Text(hinhThuc, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
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
    );
  }

  Widget _anhThay(NhomDichVu g) => Container(
        color: AppColors.brandLight,
        child: Icon(CatalogUi.iconFor(g.ten), color: AppColors.brand500, size: 30),
      );
}
