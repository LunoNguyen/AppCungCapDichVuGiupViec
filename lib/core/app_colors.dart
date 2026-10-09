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

  // Brand colors - Cam bTaskee (app Khách hàng), cùng màu với website
  static const Color brand700 = Color(0xFFE8650C); // cam đậm (đầu gradient, pressed)
  static const Color brand600 = Color(0xFFF2721A); // cam đậm vừa (text giá)
  static const Color brand500 = Color(0xFFFF8228); // màu chủ đạo bTaskee
  static const Color brand400 = Color(0xFFFF9A4D); // cam sáng
  static const Color brand300 = Color(0xFFFFC291); // cam nhạt
  static const Color brandLight = Color(0xFFFFEBDC); // nền icon / badge
  static const Color brandSurface = Color(0xFFFFF6EF); // nền rất nhạt

  /// Gradient header / thẻ nổi bật phía khách hàng: cam đậm → cam bTaskee
  static const LinearGradient brandGradient = LinearGradient(
    colors: [brand700, brand500],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Partner colors - Tím chàm (app Cộng tác viên, theo bTaskee Partner)
  static const Color partner800 = Color(0xFF2A3166); // tím đậm (đáy header)
  static const Color partner600 = Color(0xFF343E78); // tím chàm (pressed, chữ đậm)
  static const Color partner500 = Color(0xFF3E4989); // màu chủ đạo CTV, đúng màu logo bTaskee Partner
  static const Color partner400 = Color(0xFF6670B0); // tím sáng
  static const Color partnerLight = Color(0xFFECEDF8); // nền icon / badge / tab chọn
  static const Color ctvMoney = Color(0xFFE5584F); // giá / thu nhập: đỏ san hô như bTaskee Partner

  /// Gradient header app CTV: tím chàm → tím đậm
  static const LinearGradient partnerGradient = LinearGradient(
    colors: [partner500, partner800],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Giữ tên cũ để màn Đăng nhập / Đăng ký không phải đổi, giá trị trỏ sang màu Partner
  static const Color ctvYellow = partner500;
  static const Color ctvYellowDark = partner600;
  static const Color ctvYellowLight = partnerLight;
  static const Color ctvYellowBorder = Color(0xFFC5C8EA);
  static const Color ctvHeaderBg = partner800; // Deep header
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
