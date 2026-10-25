import 'package:flutter/material.dart';
import '../../../core/app_colors.dart';
import '../../../services/catalog_ui.dart';
import '../../../services/nhom_dich_vu.dart';
import '../../../widgets/anh_khong_cat.dart';

/// Thẻ "Dịch vụ đã chọn" ở đầu bước Thời gian (giống website): dịch vụ, hình thức, thời lượng / gói, giá.
/// "Đổi" quay về trang chi tiết dịch vụ để chọn lại.
class DichVuDaChon extends StatelessWidget {
  final NhomDichVu nhom;
  final Map<String, dynamic>? bienThe;
  final String loai;
  final VoidCallback onDoi;

  const DichVuDaChon({
    super.key,
    required this.nhom,
    required this.bienThe,
    required this.loai,
    required this.onDoi,
  });

  @override
  Widget build(BuildContext context) {
    final anh = CatalogUi.fileUrl(nhom.anh);
    final bt = bienThe;
    final gia = (num.tryParse(bt?['donGiaThamKhao']?.toString() ?? '') ?? 0).round();
    final chiTiet = [CatalogUi.loaiHinhLabel(loai), if (bt != null) NhomDichVu.nhanBienThe(bt)].join(' · ');
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Dịch vụ đã chọn',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const Spacer(),
              TextButton(
                onPressed: onDoi,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text('Đổi'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: anh == null
                    ? _anhThay()
                    : AnhKhongCat(url: anh, thayThe: _anhThay(), borderRadius: BorderRadius.circular(10)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nhom.ten,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(chiTiet, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    if (gia > 0) ...[
                      const SizedBox(height: 2),
                      Text(CatalogUi.money(gia),
                          style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.brand600)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _anhThay() => Container(
        decoration: BoxDecoration(color: AppColors.brandLight, borderRadius: BorderRadius.circular(10)),
        child: Icon(CatalogUi.iconFor(nhom.ten), color: AppColors.brand500, size: 30),
      );
}
