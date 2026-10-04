import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_colors.dart';
import '../../services/auth_api_service.dart';
import '../../services/session_service.dart';

/// Quên mật khẩu: nhập SĐT -> nhận mã OTP qua tin nhắn SMS -> nhập OTP + mật khẩu mới.
/// Dùng chung cho Khách hàng và Cộng tác viên (cùng bảng tài khoản).
class ForgotPasswordScreen extends StatefulWidget {
  final String initialPhone;
  final Color roleColor;

  const ForgotPasswordScreen({
    super.key,
    this.initialPhone = '',
    this.roleColor = AppColors.brand500,
  });

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static const _mucDich = 'DatLaiMatKhau';

  final AuthApiService _authApiService = AuthApiService();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _phoneCtrl;
  final _otpCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _otpSent = false; // đã sang bước nhập OTP
  bool _isLoading = false;
  bool _obscure = true;
  int _counter = 0;
  Timer? _timer;
  String? _demoOtp; // chỉ có khi backend chạy SMS mô phỏng

  @override
  void initState() {
    super.initState();
    _phoneCtrl = TextEditingController(text: widget.initialPhone);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String get _phone => SessionService.normalizePhone(_phoneCtrl.text);

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  void _startTimer() {
    _counter = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_counter > 0) {
        setState(() => _counter--);
      } else {
        t.cancel();
      }
    });
  }

  Future<void> _sendOtp() async {
    if (_phoneCtrl.text.trim().isEmpty) {
      _showSnack('Vui lòng nhập số điện thoại đã đăng ký', AppColors.error);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    try {
      final res =
          await _authApiService.sendOtp(identifier: _phone, mucDich: _mucDich);
      if (!mounted) return;
      if (!res.success) {
        _showSnack(res.message ?? 'Không gửi được mã OTP', AppColors.error);
        return;
      }
      setState(() {
        _otpSent = true;
        _demoOtp = res.data?['otpCode']?.toString();
      });
      _startTimer();
      _showSnack('Mã OTP đã được gửi qua tin nhắn tới số $_phone',
          AppColors.success);
    } catch (e) {
      if (mounted) _showSnack('Lỗi kết nối: $e', AppColors.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    try {
      final res = await _authApiService.resetPassword(
        identifier: _phone,
        maCode: _otpCtrl.text.trim(),
        matKhauMoi: _passCtrl.text,
      );
      if (!mounted) return;
      if (!res.success) {
        _showSnack(res.message ?? 'Không đặt lại được mật khẩu', AppColors.error);
        return;
      }
      _showSnack(res.message ?? 'Đặt lại mật khẩu thành công',
          AppColors.success);
      Navigator.pop(context, _phone);
    } catch (e) {
      if (mounted) _showSnack('Lỗi kết nối: $e', AppColors.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _decoration(String label, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: widget.roleColor, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Quên mật khẩu')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _otpSent
                      ? 'Nhập mã OTP gồm 6 chữ số trong tin nhắn đã gửi tới $_phone và đặt mật khẩu mới.'
                      : 'Nhập số điện thoại đã đăng ký. Chúng tôi sẽ gửi mã OTP qua tin nhắn SMS.',
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _phoneCtrl,
                  enabled: !_otpSent,
                  keyboardType: TextInputType.phone,
                  decoration:
                      _decoration('Số điện thoại', Icons.phone_outlined),
                ),
                if (!_otpSent) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _sendOtp,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: widget.roleColor),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Text('Gửi mã OTP'),
                    ),
                  ),
                ] else ...[
                  if (_demoOtp != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Môi trường demo (SMS mô phỏng) – mã OTP: $_demoOtp',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.brand700),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _otpCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: _decoration('Mã OTP', Icons.sms_outlined),
                    validator: (v) => (v == null || v.trim().length != 6)
                        ? 'Mã OTP gồm 6 chữ số'
                        : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: _obscure,
                    decoration: _decoration(
                      'Mật khẩu mới',
                      Icons.lock_outline,
                      suffix: IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) => (v == null || v.trim().length < 6)
                        ? 'Mật khẩu cần ít nhất 6 ký tự'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmCtrl,
                    obscureText: _obscure,
                    decoration:
                        _decoration('Nhập lại mật khẩu mới', Icons.lock_outline),
                    validator: (v) =>
                        v != _passCtrl.text ? 'Mật khẩu nhập lại không khớp' : null,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Chưa nhận được tin nhắn? ',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.textSecondary)),
                      _counter > 0
                          ? Text('Gửi lại sau ($_counter s)',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary))
                          : TextButton(
                              onPressed: _isLoading ? null : _sendOtp,
                              child: const Text('Gửi lại mã',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                    ],
                  ),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => setState(() {
                              _otpSent = false;
                              _otpCtrl.clear();
                            }),
                    child: const Text('Đổi số điện thoại'),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _resetPassword,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: widget.roleColor),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Text('Đặt lại mật khẩu'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
