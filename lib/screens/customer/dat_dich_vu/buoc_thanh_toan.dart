import 'package:flutter/material.dart';
import '../../../core/app_colors.dart';

/// Bước 5: chọn phương thức thanh toán – "TienMat" | "ChuyenKhoan" (đúng chữ máy chủ đọc).
class BuocThanhToan extends StatelessWidget {
  final String? chon;
  final int phutThanhToan;
  final ValueChanged<String> onChon;

  const BuocThanhToan({super.key, required this.chon, required this.phutThanhToan, required this.onChon});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Phương thức thanh toán',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 12),
        _the(
          ma: 'TienMat',
          icon: Icons.payments_outlined,
          ten: 'Tiền mặt',
          moTa: 'Trả cho cộng tác viên sau buổi làm. bTaskee tìm người làm ngay.',
        ),
        _the(
          ma: 'ChuyenKhoan',
          icon: Icons.qr_code_2_rounded,
          ten: 'Chuyển khoản',
          moTa: 'Quét mã VietQR, cần thanh toán trong $phutThanhToan phút. Thanh toán xong bTaskee mới tìm người làm.',
        ),
      ],
    );
  }

  Widget _the({required String ma, required IconData icon, required String ten, required String moTa}) {
    final dangChon = chon == ma;
    return GestureDetector(
      onTap: () => onChon(ma),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: dangChon ? AppColors.brandSurface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: dangChon ? AppColors.brand500 : AppColors.divider, width: dangChon ? 1.5 : 1),
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
                  Text(moTa, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.35)),
                ],
              ),
            ),
            Icon(
              dangChon ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: dangChon ? AppColors.brand500 : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
