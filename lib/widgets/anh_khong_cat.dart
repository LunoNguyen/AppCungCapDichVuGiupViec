import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// Ảnh hiện trọn (không cắt): ảnh vừa khung theo kiểu contain, phần thừa là chính ảnh đó phóng to và làm mờ phía sau.
/// Dùng cho ảnh dịch vụ (ảnh HCNS tải lên có đủ tỉ lệ khác nhau). Lỗi tải ảnh thì hiện [thayThe].
class AnhKhongCat extends StatelessWidget {
  final String url;
  final Widget thayThe;
  final BorderRadius borderRadius;

  const AnhKhongCat({
    super.key,
    required this.url,
    required this.thayThe,
    this.borderRadius = BorderRadius.zero,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Opacity(
              opacity: 0.55,
              child: Image.network(url, fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox.shrink()),
            ),
          ),
          Image.network(url, fit: BoxFit.contain, errorBuilder: (_, _, _) => thayThe),
        ],
      ),
    );
  }
}
