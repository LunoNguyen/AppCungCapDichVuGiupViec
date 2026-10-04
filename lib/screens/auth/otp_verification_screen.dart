import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../services/auth_api_service.dart';
import '../../services/auth_flow.dart';
import '../customer/customer_main_screen.dart';
import 'login_screen.dart';

/// Xác thực OTP kích hoạt tài khoản Khách hàng (UC-KH01).
/// Nếu có [password] thì sau khi xác thực sẽ tự đăng nhập luôn.
class OtpVerificationScreen extends StatefulWidget {
  final String destination; // SĐT (hoặc email) đã đăng ký
  final bool isPhone;
  final int targetRoleTab; // 0: Khách hàng, 1: Cộng tác viên
  final String? password;
  final String? demoOtp; // Chỉ có khi backend dùng SMS mô phỏng (app.sms.provider=mock)

  const OtpVerificationScreen({
    super.key,
    required this.destination,
    this.isPhone = true,
    this.targetRoleTab = 0,
    this.password,
    this.demoOtp,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final AuthApiService _authApiService = AuthApiService();
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _counter = 60;
  Timer? _timer;
  bool _isLoading = false;
  String? _demoOtp;

  @override
  void initState() {
    super.initState();
    _demoOtp = widget.demoOtp;
    _startTimer();
  }

  void _startTimer() {
    _counter = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_counter > 0) {
        setState(() => _counter--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  void _clearCode() {
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes.first.requestFocus();
  }

  Future<void> _verifyOtp() async {
    if (_isLoading) return;
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length < 6) {
      _showSnack('Vui lòng nhập đầy đủ mã OTP gồm 6 chữ số!', AppColors.error);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await _authApiService.verifyOtp(
        identifier: widget.destination,
        maCode: otp,
      );
      if (!mounted) return;
      if (!res.success) {
        _showSnack(res.message ?? 'Mã OTP không chính xác', AppColors.error);
        _clearCode();
        return;
      }

      // Đã kích hoạt -> tự đăng nhập nếu có mật khẩu
      if (widget.password != null) {
        final login = await AuthFlow.login(
          phone: widget.destination,
          password: widget.password!,
          asCustomer: true,
        );
        if (!mounted) return;
        if (login.success) {
          _showSnack('Kích hoạt tài khoản thành công. Chào mừng bạn!',
              AppColors.success);
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const CustomerMainScreen()),
            (route) => false,
          );
          return;
        }
      }
      _showActivatedDialog();
    } catch (e) {
      if (mounted) _showSnack('Lỗi kết nối: $e', AppColors.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    final res = await _authApiService.sendOtp(identifier: widget.destination);
    if (!mounted) return;
    if (res.success) {
      setState(() => _demoOtp = res.data?['otpCode']?.toString());
      _startTimer();
      _clearCode();
      _showSnack('Đã gửi lại mã OTP mới!', AppColors.success);
    } else {
      _showSnack(res.message ?? 'Không gửi được mã OTP', AppColors.error);
    }
  }

  void _showActivatedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Xác thực thành công!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tài khoản của bạn đã được kích hoạt. Vui lòng đăng nhập để bắt đầu!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CustomerMainScreen()),
                    (route) => false,
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          LoginScreen(initialRoleTab: widget.targetRoleTab),
                    ),
                  );
                },
                child: const Text('Đăng nhập ngay'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Xác thực OTP')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.brandLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.sms_outlined,
                  color: AppColors.brand500,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Nhập mã xác thực',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.isPhone
                    ? 'Mã gồm 6 chữ số đã được gửi qua tin nhắn SMS tới số điện thoại'
                    : 'Mã gồm 6 chữ số đã được gửi tới email',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                widget.destination,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brand600,
                ),
              ),
              if (_demoOtp != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.brandSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.brandLight),
                  ),
                  child: Text(
                    'Môi trường demo (SMS mô phỏng) – mã OTP: $_demoOtp',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.brand700,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 46,
                    height: 56,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        contentPadding: EdgeInsets.zero,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: _controllers[index].text.isNotEmpty
                                ? AppColors.brand500
                                : AppColors.divider,
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: AppColors.brand500, width: 2),
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {});
                        if (val.isNotEmpty && index < 5) {
                          _focusNodes[index + 1].requestFocus();
                        } else if (val.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                        if (index == 5 && val.isNotEmpty) {
                          _verifyOtp();
                        }
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Chưa nhận được mã? ',
                    style:
                        TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  _counter > 0
                      ? Text(
                          'Gửi lại sau ($_counter s)',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        )
                      : TextButton(
                          onPressed: _resendOtp,
                          child: const Text(
                            'Gửi lại mã',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text('Xác nhận'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
