import 'package:flutter/material.dart';

import '../core/app_colors.dart';

/// Giá đang áp dụng, kèm giá gốc gạch ngang bên dưới khi đang có đợt tăng / giảm giá tạm
/// (giống website). [giaGoc] null hoặc rỗng thì chỉ hiện giá.
class GiaHienThi extends StatelessWidget {
  final String gia;
  final String? giaGoc;
  final TextStyle style;
  final CrossAxisAlignment canh;

  const GiaHienThi({
    super.key,
    required this.gia,
    this.giaGoc,
    required this.style,
    this.canh = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final coGoc = giaGoc != null && giaGoc!.isNotEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: canh,
      children: [
        Text(gia, maxLines: 1, overflow: TextOverflow.ellipsis, style: style),
        if (coGoc)
          Text(
            giaGoc!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: (style.fontSize ?? 14) - 1.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
              decoration: TextDecoration.lineThrough,
              decorationColor: AppColors.textMuted,
            ),
          ),
      ],
    );
  }
}
