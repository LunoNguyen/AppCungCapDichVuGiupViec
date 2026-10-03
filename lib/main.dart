import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/app_theme.dart';
import 'services/session_service.dart';
import 'screens/customer/customer_main_screen.dart';
import 'screens/collaborator/collaborator_main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Khởi tạo ngôn ngữ Tiếng Việt cho toàn bộ ứng dụng
  await initializeDateFormatting('vi_VN', null);
  // Đọc phiên đăng nhập đã lưu để vào thẳng app, không cần đăng nhập lại
  final session = await SessionService.load();
  runApp(HousekeepingApp(session: session));
}

class HousekeepingApp extends StatelessWidget {
  final UserSession? session;
  const HousekeepingApp({super.key, this.session});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ứng dụng Dịch vụ Giúp việc Neatify',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      // CTV đã đăng nhập -> app CTV; còn lại vào Trang chủ Khách hàng (như bTaskee)
      home: session?.isCollaborator == true
          ? const CollaboratorMainScreen()
          : const CustomerMainScreen(),
    );
  }
}
