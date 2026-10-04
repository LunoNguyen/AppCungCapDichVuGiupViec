import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../services/auth_api_service.dart';
import '../../services/session_service.dart';
import 'forgot_password_screen.dart';

/// Đổi mật khẩu khi đã đăng nhập: nhập mật khẩu hiện tại + mật khẩu mới.
/// Dùng chung cho Khách hàng và Cộng tác viên.
class ChangePasswordScreen extends StatefulWidget {
  final Color roleColor;
  const ChangePasswordScreen({super.key, this.roleColor = AppColors.brand500});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final AuthApiService _authApiService = AuthApiService();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    try {
      final session = await SessionService.load();
      if (session == null || session.taiKhoanId == 0) {
        _showSnack('Phiên đăng nhập đã hết. Vui lòng đăng nhập lại.', AppColors.error);
        return;
      }
      final res = await _authApiService.changePassword(
        taiKhoanId: session.taiKhoanId,
        matKhauHienTai: _oldCtrl.text,
        matKhauMoi: _newCtrl.text,
      );
      if (!mounted) return;
      if (!res.success) {
        _showSnack(res.message ?? 'Không đổi được mật khẩu', AppColors.error);
        return;
      }
      _showSnack('Đổi mật khẩu thành công!', AppColors.success);
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) _showSnack('Lỗi kết nối: $e', AppColors.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(obscure
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined),
          onPressed: onToggle,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: widget.roleColor, width: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Đổi mật khẩu')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _passwordField(
                  controller: _oldCtrl,
                  label: 'Mật khẩu hiện tại',
                  obscure: _obscureOld,
                  onToggle: () => setState(() => _obscureOld = !_obscureOld),
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Vui lòng nhập mật khẩu hiện tại'
                      : null,
                ),
                const SizedBox(height: 16),
                _passwordField(
                  controller: _newCtrl,
                  label: 'Mật khẩu mới',
                  obscure: _obscureNew,
                  onToggle: () => setState(() => _obscureNew = !_obscureNew),
                  validator: (v) {
                    if (v == null || v.trim().length < 6) {
                      return 'Mật khẩu mới cần ít nhất 6 ký tự';
                    }
                    if (v == _oldCtrl.text) {
                      return 'Mật khẩu mới phải khác mật khẩu hiện tại';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _passwordField(
                  controller: _confirmCtrl,
                  label: 'Nhập lại mật khẩu mới',
                  obscure: _obscureNew,
                  onToggle: () => setState(() => _obscureNew = !_obscureNew),
                  validator: (v) =>
                      v != _newCtrl.text ? 'Mật khẩu nhập lại không khớp' : null,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () async {
                      final s = await SessionService.load();
                      if (!context.mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ForgotPasswordScreen(
                            initialPhone: s?.soDienThoai ?? '',
                            roleColor: widget.roleColor,
                          ),
                        ),
                      );
                    },
                    child: const Text('Quên mật khẩu hiện tại?'),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: widget.roleColor),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text('Đổi mật khẩu'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
