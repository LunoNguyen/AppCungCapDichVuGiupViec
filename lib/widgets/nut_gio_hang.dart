import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../screens/customer/gio_hang_screen.dart';
import '../services/gio_hang.dart';

/// Nút giỏ hàng nổi (góc dưới phải) kèm số dịch vụ; ẩn khi giỏ trống – giống nút giỏ nổi trên web.
class NutGioHang extends StatelessWidget {
  const NutGioHang({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: GioHang.instance,
      builder: (context, _) {
        final so = GioHang.instance.soLuong;
        if (so == 0) return const SizedBox.shrink();
        return Badge(
          label: Text(so > 99 ? '99+' : '$so'),
          backgroundColor: AppColors.error,
          offset: const Offset(-2, 2),
          child: FloatingActionButton(
            heroTag: 'nut-gio-hang',
            tooltip: 'Giỏ hàng',
            backgroundColor: Colors.white,
            foregroundColor: AppColors.brand500,
            // phẳng 2D: không đổ bóng, vuông bo góc
            elevation: 0,
            focusElevation: 0,
            hoverElevation: 0,
            highlightElevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.brand500, width: 1.5),
            ),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GioHangScreen())),
            child: const Icon(Icons.shopping_cart_outlined),
          ),
        );
      },
    );
  }
}
