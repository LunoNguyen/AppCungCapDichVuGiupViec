import 'package:flutter/material.dart';
import '../../../core/app_colors.dart';
import '../../../services/buoc_dat.dart';

/// Thanh bước ở đầu màn đặt (giống website): Thời gian → Xác nhận → Thanh toán, đánh số 1–3.
/// Bước đã tới thì bấm được để quay lại sửa; bước sau [daToi] bị khoá.
class ThanhBuoc extends StatelessWidget {
  static const nhan = {3: 'Thời gian', 4: 'Xác nhận', 5: 'Thanh toán'};

  final int buoc;
  final int daToi;
  final ValueChanged<int> onChon;

  const ThanhBuoc({
    super.key,
    required this.buoc,
    required this.daToi,
    required this.onChon,
  });

  @override
  Widget build(BuildContext context) {
    const cacBuoc = BuocDat.cacBuoc;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      child: Row(
        children: [
          for (int i = 0; i < cacBuoc.length; i++)
            Expanded(child: _oBuoc(cacBuoc[i], i + 1)),
        ],
      ),
    );
  }

  Widget _oBuoc(int b, int soThuTu) {
    final dangO = b == buoc;
    final xong = b < buoc;
    final moDuoc = b <= daToi && !dangO;
    final mau = dangO || xong ? AppColors.brand500 : AppColors.textMuted;
    return InkWell(
      onTap: moDuoc ? () => onChon(b) : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: dangO ? AppColors.brand500 : (xong ? AppColors.brandLight : Colors.white),
                shape: BoxShape.circle,
                border: Border.all(color: dangO || xong ? AppColors.brand500 : AppColors.divider),
              ),
              child: xong
                  ? const Icon(Icons.check_rounded, size: 16, color: AppColors.brand600)
                  : Text(
                      '$soThuTu',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: dangO ? Colors.white : AppColors.textMuted,
                      ),
                    ),
            ),
            const SizedBox(height: 4),
            Text(
              nhan[b]!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: dangO ? FontWeight.w800 : FontWeight.w600,
                color: dangO ? AppColors.textPrimary : mau,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
