import 'package:flutter/material.dart';

import '../core/app_colors.dart';

/// Phản hồi công khai mới nhất của bTaskee dưới một đánh giá (trang chi tiết dịch vụ).
class PhanHoiBTaskee extends StatelessWidget {
  final String noiDung;

  const PhanHoiBTaskee({super.key, required this.noiDung});

  /// Dựng từ trường `phanHoi` ({noiDung, thoiGian}) của API; null khi thiếu hoặc sai kiểu.
  static PhanHoiBTaskee? tuJson(Object? phanHoi) {
    if (phanHoi is! Map) return null;
    final noiDung = phanHoi['noiDung'];
    if (noiDung is! String || noiDung.trim().isEmpty) return null;
    return PhanHoiBTaskee(noiDung: noiDung.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 10, top: 2, bottom: 2),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: AppColors.brand500, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Phản hồi từ bTaskee',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(noiDung,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
        ],
      ),
    );
  }
}
