import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../customer/customer_main_screen.dart';
import '../collaborator/collaborator_main_screen.dart';
import '../guest/guest_main_screen.dart';
import 'register_screen.dart';
import 'collaborator_register_screen.dart';

class LoginScreen extends StatefulWidget {
  final int initialRoleTab; // 0: Khách hàng, 1: Cộng tác viên
  const LoginScreen({super.key, this.initialRoleTab = 0});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _accountController =
      TextEditingController(text: '0901234567');
  final TextEditingController _passwordController =
      TextEditingController(text: '123456');

  late int _roleIndex; // 0: Khách hàng, 1: Cộng tác viên
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _roleIndex = widget.initialRoleTab;
  }

  @override
  void dispose() {
    _accountController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onRoleChanged(int index) {
    setState(() {
      _roleIndex = index;
      if (index == 0) {
        _accountController.text = '0901234567';
        _passwordController.text = '123456';
      } else {
        _accountController.text = '0909888999';
        _passwordController.text = '123456';
      }
    });
  }

  void _handleLogin() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      if (_roleIndex == 0) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CustomerMainScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CollaboratorMainScreen()),
        );
      }
    });
  }

  void _showForgotPasswordDialog() {
    final emailPhoneCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Quên mật khẩu?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhập số điện thoại hoặc email đã đăng ký. Hệ thống sẽ gửi mã đặt lại mật khẩu cho bạn.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailPhoneCtrl,
              decoration: const InputDecoration(
                labelText: 'Số điện thoại hoặc Email',
                prefixIcon: Icon(Icons.contact_mail_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Mã khôi phục đã được gửi tới thông tin của bạn!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Gửi mã'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCustomer = _roleIndex == 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                // App Logo and Brand
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.brand700, AppColors.brand500],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.home_repair_service,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'GIÚP VIỆC TIỆN ÍCH',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.brand700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              'Uy tín • Chu đáo • Chuyên nghiệp',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const GuestMainScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Khách xem',
                        style: TextStyle(
                          color: AppColors.brand500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 36),

                const Text(
                  'Chào mừng trở lại!',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Vui lòng đăng nhập để tiếp tục quản lý và sử dụng dịch vụ.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // Role selector toggle
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.neutral100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _onRoleChanged(0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isCustomer
                                  ? AppColors.brand500
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: isCustomer
                                  ? [
                                      BoxShadow(
                                        color: AppColors.brand500
                                            .withOpacity(0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person,
                                  size: 18,
                                  color: isCustomer
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Khách hàng',
                                  style: TextStyle(
                                    fontWeight: isCustomer
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isCustomer
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _onRoleChanged(1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !isCustomer
                                  ? AppColors.brand700
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: !isCustomer
                                  ? [
                                      BoxShadow(
                                        color: AppColors.brand700
                                            .withOpacity(0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.badge,
                                  size: 18,
                                  color: !isCustomer
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Cộng tác viên',
                                  style: TextStyle(
                                    fontWeight: !isCustomer
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: !isCustomer
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Account input
                Text(
                  isCustomer
                      ? 'Số điện thoại hoặc Email'
                      : 'Số điện thoại đăng ký CTV',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _accountController,
                  decoration: InputDecoration(
                    hintText: isCustomer
                        ? 'Nhập SĐT hoặc email'
                        : 'Nhập SĐT đã được kích hoạt',
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Vui lòng nhập số điện thoại hoặc email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password input
                const Text(
                  'Mật khẩu',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Nhập mật khẩu',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Vui lòng nhập mật khẩu';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showForgotPasswordDialog,
                    child: const Text(
                      'Quên mật khẩu?',
                      style: TextStyle(
                        color: AppColors.brand600,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isCustomer ? AppColors.brand500 : AppColors.brand700,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            isCustomer
                                ? 'Đăng nhập Khách hàng'
                                : 'Đăng nhập Cộng tác viên',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // Quick Demo Fill buttons
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.neutral100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tài khoản thử nghiệm nhanh:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _onRoleChanged(0),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                side: BorderSide(
                                  color: isCustomer
                                      ? AppColors.brand500
                                      : AppColors.divider,
                                ),
                              ),
                              child: const Text(
                                'Khách hàng',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _onRoleChanged(1),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                side: BorderSide(
                                  color: !isCustomer
                                      ? AppColors.brand700
                                      : AppColors.divider,
                                ),
                              ),
                              child: const Text(
                                'Cộng tác viên',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Register options
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Chưa có tài khoản? ',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        if (isCustomer) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const CollaboratorRegisterScreen(),
                            ),
                          );
                        }
                      },
                      child: Text(
                        isCustomer
                            ? 'Đăng ký ngay'
                            : 'Đăng ký làm CTV',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isCustomer
                              ? AppColors.brand500
                              : AppColors.brand700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CollaboratorRegisterScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.work_outline, size: 16),
                    label: const Text(
                      'Ứng tuyển trở thành Cộng tác viên',
                      style: TextStyle(
                        color: AppColors.brand700,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
