import 'package:flutter/material.dart';

import '../services/app_realtime.dart';

/// Biểu tượng chuông kèm số thông báo chưa đọc (tự cập nhật theo realtime).
class ChuongThongBao extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final double? size;

  const ChuongThongBao({super.key, this.icon = Icons.notifications_none_rounded, this.color, this.size});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: AppRealtime.instance.soChuaDoc,
      builder: (_, n, __) => Badge.count(
        count: n,
        isLabelVisible: n > 0,
        backgroundColor: Colors.red,
        child: Icon(icon, color: color, size: size),
      ),
    );
  }
}
