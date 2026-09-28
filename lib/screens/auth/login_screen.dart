import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_colors.dart';
import '../../services/auth_api_service.dart';
import '../collaborator/collaborator_main_screen.dart';
import '../customer/customer_main_screen.dart';
import 'collaborator_register_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final int initialRoleTab; // 0: Khách hàng, 1: Cộng tác viên
  const LoginScreen({super.key, this.initialRoleTab = 0});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthApiService _authApiService = AuthApiService();

  late final TextEditingController _accountController;
  final TextEditingController _passwordController =
      TextEditingController(text: '123456');

  late int _roleIndex;
  bool get isCustomer => _roleIndex == 0;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _roleIndex = widget.initialRoleTab;
    _accountController = TextEditingController(
      text: _roleIndex == 0 ? '0901234567' : '0909888999',
    );
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

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final String roleStr = isCustomer ? 'KHACH_HANG' : 'CONG_TAC_VIEN';

      final response = await _authApiService.login(
        username: _accountController.text.trim(),
        matKhau: _passwordController.text,
        vaiTro: roleStr,
      );

      if (response.success && response.data != null) {
        final prefs = await SharedPreferences.getInstance();
        final data = response.data!;

        dynamic rawId = data['id'] ??
            data['userId'] ??
            data['collaboratorId'] ??
            data['taiKhoanId'];
        int userId = 0;
        if (rawId != null) {
          userId = int.tryParse(rawId.toString()) ?? 0;
        }

        await prefs.setInt('userId', userId);
        await prefs.setString('userRole', roleStr);

        if (data['token'] != null) {
          await prefs.setString('token', data['token']);
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng nhập thành công!'),
            backgroundColor: AppColors.success,
          ),
        );

        if (isCustomer) {
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
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ??
                'Đăng nhập thất bại. Vui lòng kiểm tra lại!'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi kết nối: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brand500,
              foregroundColor: Colors.white,
            ),
            child: const Text('Gửi mã'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isCustomer
                                    ? [AppColors.brand500, AppColors.brand300]
                                    : [AppColors.brand700, AppColors.brand500],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isCustomer
                                  ? Icons.cleaning_services_rounded
                                  : Icons.home_repair_service,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isCustomer
                                      ? 'NEATIFY - GIÚP VIỆC'
                                      : 'GIÚP VIỆC TIỆN ÍCH',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isCustomer
                                        ? AppColors.brand500
                                        : AppColors.brand700,
                                    letterSpacing: 0.5,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  isCustomer
                                      ? 'Dành cho Khách hàng'
                                      : 'Dành cho Đối tác CTV',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 36),
                Text(
                  isCustomer ? 'Chào mừng bạn trở lại!' : 'Chào mừng Đối tác!',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isCustomer
                      ? 'Vui lòng đăng nhập để trải nghiệm dịch vụ tiện ích.'
                      : 'Vui lòng đăng nhập để tiếp tục quản lý công việc.',
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
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
                                            .withValues(alpha: 0.3),
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
                                            .withValues(alpha: 0.3),
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
                        ? 'Nhập SĐT hoặc email đã đăng ký'
                        : 'Nhập SĐT đã được kích hoạt',
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Vui lòng nhập tài khoản';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
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
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showForgotPasswordDialog,
                    child: Text(
                      'Quên mật khẩu?',
                      style: TextStyle(
                        color: isCustomer
                            ? AppColors.brand500
                            : AppColors.brand700,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCustomer
                          ? AppColors.brand500
                          : AppColors.brand700,
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
                const SizedBox(height: 28),
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
                        isCustomer ? 'Đăng ký ngay' : 'Đăng ký làm CTV',
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
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
