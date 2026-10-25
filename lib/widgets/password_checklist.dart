import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/password_rules.dart';

/// Danh sách tiêu chí mật khẩu dưới ô nhập, tiêu chí đạt chuyển xanh.
class PasswordChecklist extends StatelessWidget {
  final String password;
  final String? phone;

  const PasswordChecklist({super.key, required this.password, this.phone});

  @override
  Widget build(BuildContext context) {
    final result = PasswordRules.evaluate(password, phone);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 14,
        runSpacing: 4,
        children: [
          for (final c in PasswordRules.criteria)
            _Item(label: c.label, ok: result[c.key] == true),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final String label;
  final bool ok;

  const _Item({required this.label, required this.ok});

  @override
  Widget build(BuildContext context) {
    final color = ok ? AppColors.success : AppColors.textSecondary;
    return Semantics(
      label: '$label: ${ok ? 'đã đạt' : 'chưa đạt'}',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ok ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 16, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12.5, color: color)),
        ],
      ),
    );
  }
}
