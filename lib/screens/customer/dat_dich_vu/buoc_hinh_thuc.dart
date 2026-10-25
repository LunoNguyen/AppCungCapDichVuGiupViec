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
  final List<Map<String, dynamic>> cacDichVuCombo;
  final Set<int> comboDichVuIds;
  final ValueChanged<int>? onToggleCombo;

  const BuocHinhThuc({
    super.key,
    required this.nhom,
    required this.loaiChon,
    required this.onChon,
    required this.dichVuId,
    required this.onChonBienThe,
    this.cacDichVuCombo = const [],
    this.comboDichVuIds = const {},
    this.onToggleCombo,
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
        if (bienThes.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            laGoi ? 'Chọn gói' : 'Chọn thời lượng',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 10),
          for (final b in bienThes) _bienThe(b),
        ],
        if (loaiChon == 'TheoLan' && cacDichVuCombo.isNotEmpty) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.brand500, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Thêm dịch vụ đi kèm (Combo tiện lợi)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
              ),
              if (comboDichVuIds.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.brand500,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Đã chọn ${comboDichVuIds.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Ghép thêm dịch vụ vào cùng ca làm để cộng tác viên thực hiện liền mạch.',
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.3),
          ),
          const SizedBox(height: 10),
          for (final cdv in cacDichVuCombo) _theCombo(cdv),
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

  Widget _theCombo(Map<String, dynamic> cdv) {
    final id = CatalogUi.toInt(cdv['id'] ?? cdv['dichVuId']);
    final chon = comboDichVuIds.contains(id);
    final phut = CatalogUi.toInt(cdv['thoiGianThucHienPhut']);
    final thoiLuong = phut > 0 ? (phut % 60 == 0 ? '${phut ~/ 60}h' : '$phut phút') : '60 phút';
    final gia = CatalogUi.money(cdv['donGiaThamKhao']);

    return GestureDetector(
      onTap: () => onToggleCombo?.call(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: chon ? AppColors.brandSurface : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: chon ? AppColors.brand500 : AppColors.divider,
            width: chon ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Checkbox(
              value: chon,
              onChanged: (_) => onToggleCombo?.call(id),
              activeColor: AppColors.brand500,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cdv['tenDichVu']?.toString() ?? 'Dịch vụ đi kèm',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.neutral100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '+$thoiLuong',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '+$gia',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: chon ? AppColors.brand600 : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
