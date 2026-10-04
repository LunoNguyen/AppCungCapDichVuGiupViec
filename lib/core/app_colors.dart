import 'package:flutter/material.dart';

class AppColors {
  // Bảng màu gốc bTaskee
  static const Color orange600 = Color(0xFFE86F14);
  static const Color orange500 = Color(0xFFFF8228);
  static const Color orange400 = Color(0xFFFF9A4D);
  static const Color orangeLight = Color(0xFFFFEBDC);

  static const Color green500 = Color(0xFF1BB55C);
  static const Color green600 = Color(0xFF149A4C);
  static const Color greenLight = Color(0xFFE6F7EE);

  // Brand colors - Xanh ngọc #1D969F (app Khách hàng)
  static const Color brand700 = Color(0xFF13616B); // ngọc sẫm (đầu gradient)
  static const Color brand600 = Color(0xFF187F87); // ngọc đậm (text giá, pressed)
  static const Color brand500 = Color(0xFF1D969F); // màu chủ đạo
  static const Color brand400 = Color(0xFF4FB2B9); // ngọc sáng
  static const Color brand300 = Color(0xFF97D3D7); // ngọc nhạt
  static const Color brandLight = Color(0xFFE0F2F3); // nền icon / badge
  static const Color brandSurface = Color(0xFFF0F9FA); // nền rất nhạt

  /// Gradient chủ đạo cho header / thẻ nổi bật phía khách hàng: ngọc sẫm → #1D969F
  static const LinearGradient brandGradient = LinearGradient(
    colors: [brand700, brand500],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Partner colors - Cam (app Cộng tác viên, thu nhập hiển thị bằng màu brand xanh lá)
  static const Color partner500 = orange500;
  static const Color partner600 = orange600;
  static const Color partnerLight = orangeLight;

  // Giữ tên cũ để màn Đăng nhập / Đăng ký không phải đổi, giá trị trỏ sang màu Partner
  static const Color ctvYellow = partner500;
  static const Color ctvYellowDark = partner600;
  static const Color ctvYellowLight = partnerLight;
  static const Color ctvYellowBorder = Color(0xFFFFC08F);
  static const Color ctvHeaderBg = Color(0xFF2E384D); // Deep header
  static const Color ctvCardBg = Color(0xFFFFFFFF);

  // Neutral colors
  static const Color neutral100 = Color(0xFFF5F5F5); // light background
  static const Color neutral800 = Color(0xFF1F1F1F); // dark text / button
  static const Color darkButton = Color(0xFF1F1F1F); // [Đăng ký] button dark color

  // Utility colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color error = Color(0xFFE53935);
  static const Color success = green500;
  static const Color warning = Color(0xFFFB8C00);
  static const Color star = Color(0xFFFFB300);
  static const Color info = Color(0xFF2F80ED);

  static const Color textPrimary = Color(0xFF1F1F1F);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textMuted = Color(0xFFA6A6A6);
  static const Color divider = Color(0xFFEEEEEE);
  static const Color cardBorder = Color(0xFFEEEEEE);
  static const Color cardBg = white;
  static const Color scaffoldBg = Color(0xFFF5F5F5);
}
