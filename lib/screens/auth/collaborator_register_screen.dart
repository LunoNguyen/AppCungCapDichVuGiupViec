import 'package:flutter/material.dart';
import 'register_screen.dart';

/// Màn hình đăng ký Cộng tác viên (sử dụng giao diện thống nhất RegisterScreen với tab CTV)
class CollaboratorRegisterScreen extends StatelessWidget {
  const CollaboratorRegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RegisterScreen(initialRoleTab: 1);
  }
}
