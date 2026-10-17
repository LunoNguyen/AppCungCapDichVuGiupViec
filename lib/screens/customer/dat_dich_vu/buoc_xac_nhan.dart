import 'package:flutter/material.dart';
import '../../../core/app_colors.dart';
import '../../../services/catalog_ui.dart';

/// Bước 4: tóm tắt đơn, ô mã ưu đãi (Áp dụng / Chọn khuyến mãi), tạm tính – ưu đãi – tổng.
class BuocXacNhan extends StatelessWidget {
  final List<(String, String)> tomTat;
  final int tamTinh;
  final int giam;
  final int tong;
  final bool dangTinhGia;
  final bool loiGia;
  final VoidCallback onTinhLai;

  final TextEditingController maController;
  final String? maApDung;
  final bool dangKiemMa;
  final VoidCallback onApDung;
  final VoidCallback onBoMa;
  final VoidCallback onChonKhuyenMai;

  const BuocXacNhan({
    super.key,
    required this.tomTat,
    required this.tamTinh,
    required this.giam,
    required this.tong,
    required this.dangTinhGia,
    required this.loiGia,
    required this.onTinhLai,
    required this.maController,
    required this.maApDung,
    required this.dangKiemMa,
    required this.onApDung,
    required this.onBoMa,
    required this.onChonKhuyenMai,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        _khoi('Thông tin đơn', Column(children: [for (final (nhan, giaTri) in tomTat) _dong(nhan, giaTri)])),
        const SizedBox(height: 10),
        _khoi('Mã ưu đãi', _oMa()),
        const SizedBox(height: 10),
        _khoi('Chi tiết thanh toán', _tien()),
      ],
    );
  }

  Widget _oMa() {
    final daApDung = maApDung != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: maController,
                enabled: !daApDung,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  hintText: 'Nhập mã ưu đãi',
                  prefixIcon: Icon(Icons.local_offer_outlined, color: AppColors.brand500),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 46,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16)),
                onPressed: dangKiemMa ? null : (daApDung ? onBoMa : onApDung),
                child: dangKiemMa
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(daApDung ? 'Bỏ mã' : 'Áp dụng'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextButton.icon(
          onPressed: dangKiemMa ? null : onChonKhuyenMai,
          icon: const Icon(Icons.confirmation_number_outlined, size: 18),
          label: const Text('Chọn khuyến mãi'),
        ),
      ],
    );
  }

  Widget _tien() {
    if (dangTinhGia) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator(color: AppColors.brand500)),
      );
    }
    return Column(
      children: [
        if (loiGia)
          Row(
            children: [
              const Expanded(
                child: Text('Chưa tính được giá, thử lại',
                    style: TextStyle(fontSize: 13, color: AppColors.orange600)),
              ),
              TextButton(onPressed: onTinhLai, child: const Text('Thử lại')),
            ],
          ),
        _dong('Tạm tính', CatalogUi.money(tamTinh)),
        if (giam > 0) _dong('Ưu đãi ($maApDung)', '-${CatalogUi.money(giam)}', mau: AppColors.green500),
        const Divider(height: 16),
        Row(
          children: [
            const Text('Tổng cộng',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary)),
            const Spacer(),
            Text(CatalogUi.money(tong),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.brand600)),
          ],
        ),
      ],
    );
  }

  static Widget _dong(String nhan, String giaTri, {Color? mau}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(nhan, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            ),
            Expanded(
              child: Text(
                giaTri,
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: mau ?? AppColors.textPrimary),
              ),
            ),
          ],
        ),
      );

  static Widget _khoi(String tieuDe, Widget con) => Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tieuDe,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            con,
          ],
        ),
      );
}
