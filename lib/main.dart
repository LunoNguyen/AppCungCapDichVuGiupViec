import 'package:flutter/material.dart';
import 'core/app_theme.dart';
import 'screens/customer/customer_main_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HousekeepingApp());
}

class HousekeepingApp extends StatelessWidget {
  const HousekeepingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ứng dụng Dịch vụ Giúp việc Neatify',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const CustomerMainScreen(),
    );
  }
}
