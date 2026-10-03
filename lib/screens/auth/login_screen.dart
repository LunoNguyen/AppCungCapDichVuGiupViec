import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_colors.dart';
import '../../services/auth_api_service.dart';
import '../collaborator/collaborator_main_screen.dart';
import '../customer/customer_main_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final int initialRoleTab; // 0: Khách hàng (Màu chủ đạo), 1: Cộng tác viên (Màu vàng)
  const LoginScreen({super.key, this.initialRoleTab = 0});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthApiService _authApiService = AuthApiService();

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  late int _roleIndex; // 0: Khách hàng, 1: Cộng tác viên
  bool get isCustomer => _roleIndex == 0;
  bool _obscurePassword = true;
  bool _isLoading = false;

  // Selected language / country for CTV header (Image 4)
  String _selectedCountry = 'Việt Nam';
  String _selectedLanguage = 'Tiếng Việt';

  @override
  void initState() {
    super.initState();
    _roleIndex = widget.initialRoleTab;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onRoleChanged(int index) {
    if (_roleIndex == index) return;
    setState(() {
      _roleIndex = index;
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
        username: _phoneController.text.trim(),
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
        if (data['taiKhoanId'] != null) {
          await prefs.setInt('taiKhoanId', int.tryParse(data['taiKhoanId'].toString()) ?? userId);
        } else {
          await prefs.setInt('taiKhoanId', userId);
        }
        if (data['congTacVienId'] != null) {
          await prefs.setInt('congTacVienId', int.tryParse(data['congTacVienId'].toString()) ?? userId);
        }
        await prefs.setString('userRole', roleStr);

        if (data['token'] != null) {
          await prefs.setString('token', data['token']);
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isCustomer
                  ? 'Đăng nhập Khách hàng thành công!'
                  : 'Đăng nhập Cộng tác viên thành công!',
            ),
            backgroundColor: isCustomer ? AppColors.brand500 : AppColors.ctvYellowDark,
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
            content: Text(
              response.message ?? 'Đăng nhập thất bại. Vui lòng kiểm tra lại!',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi kết nối máy chủ: $e'),
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
    final emailPhoneCtrl = TextEditingController(text: _phoneController.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Quên mật khẩu?',
          style: TextStyle(
            color: isCustomer ? AppColors.brand500 : AppColors.ctvYellowDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nhập số điện thoại đã đăng ký để nhận mã khôi phục mật khẩu qua SMS.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailPhoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Số điện thoại',
                prefixIcon: const Icon(Icons.phone_outlined),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isCustomer ? AppColors.brand500 : AppColors.ctvYellow,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Mã khôi phục đã được gửi tới số điện thoại của bạn!'),
                  backgroundColor: isCustomer ? AppColors.brand500 : AppColors.ctvYellowDark,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isCustomer ? AppColors.brand500 : AppColors.ctvYellow,
              foregroundColor: isCustomer ? Colors.white : AppColors.neutral800,
            ),
            child: const Text('Gửi mã'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color roleColor = isCustomer ? AppColors.brand500 : AppColors.ctvYellow;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isCustomer ? 'Đăng nhập Khách hàng' : 'Đăng nhập Cộng tác viên',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment:
                  isCustomer ? CrossAxisAlignment.start : CrossAxisAlignment.center,
              children: [
                // 1. THANH CHUYỂN ĐỔI VAI TRÒ TO NGANG NÚT ĐĂNG NHẬP
                _buildRoleSelector(),
                const SizedBox(height: 18),

                // DỰA TRÊN ẢNH:
                // Nếu là Khách hàng -> Hiển thị layout Image 1 (Màu chủ đạo app)
                // Nếu là Cộng tác viên -> Hiển thị layout Image 4 (Màu vàng CTV)
                if (isCustomer) _buildCustomerHeader() else _buildCollaboratorHeader(),

                const SizedBox(height: 28),

                // Ô nhập SỐ ĐIỆN THOẠI (Dựa trên ảnh 1 và ảnh 4)
                _buildPhoneInput(),

                const SizedBox(height: 20),

                // Ô nhập MẬT KHẨU
                _buildPasswordInput(),

                const SizedBox(height: 12),

                // QUÊN MẬT KHẨU (Khách hàng ở dưới nút, CTV ở trên nút bên phải)
                if (!isCustomer)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _showForgotPasswordDialog,
                      child: const Text(
                        'Quên mật khẩu?',
                        style: TextStyle(
                          color: AppColors.ctvYellowDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // NÚT ĐĂNG NHẬP
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: roleColor,
                      foregroundColor: isCustomer ? Colors.white : AppColors.neutral800,
                      elevation: isCustomer ? 2 : 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: isCustomer ? Colors.white : AppColors.neutral800,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            'Đăng nhập',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: isCustomer ? Colors.white : AppColors.neutral800,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // HÀNG DƯỚI NÚT ĐĂNG NHẬP
                if (isCustomer) ...[
                  // Image 1: "Bạn chưa có tài khoản? Tạo tài khoản" và "Quên mật khẩu"
                  Center(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Bạn chưa có tài khoản? ',
                              style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterScreen(initialRoleTab: 0),
                                  ),
                                );
                              },
                              child: Text(
                                'Tạo tài khoản',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.brand500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: _showForgotPasswordDialog,
                          child: Text(
                            'Quên mật khẩu',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.brand500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),

                  // SOCIAL LOGIN (Image 1: Apple, Facebook, Google)
                  _buildSocialLoginRow(),
                ] else ...[
                  // Image 4: "Bạn chưa có tài khoản? Đăng ký" (Màu vàng CTV)
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Bạn chưa có tài khoản? ',
                          style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(initialRoleTab: 1),
                              ),
                            );
                          },
                          child: const Text(
                            'Đăng ký',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.ctvYellowDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Bộ chọn vai trò TO NGANG NÚT ĐĂNG NHẬP (Khách hàng vs Cộng tác viên)
  Widget _buildRoleSelector() {
    return Container(
      width: double.infinity,
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9), // Nền xám slate nhạt sạch sẽ
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Nút Khách hàng
          Expanded(
            child: InkWell(
              onTap: () => _onRoleChanged(0),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isCustomer ? AppColors.brand500 : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isCustomer
                      ? [
                          BoxShadow(
                            color: AppColors.brand500.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isCustomer ? Icons.person_rounded : Icons.person_outline_rounded,
                      size: 22,
                      color: isCustomer ? Colors.white : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Khách hàng',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: isCustomer ? FontWeight.bold : FontWeight.w600,
                        color: isCustomer ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 6),

          // Nút Cộng tác viên
          Expanded(
            child: InkWell(
              onTap: () => _onRoleChanged(1),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: !isCustomer ? AppColors.ctvYellow : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: !isCustomer
                      ? [
                          BoxShadow(
                            color: AppColors.ctvYellow.withValues(alpha: 0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      !isCustomer ? Icons.handyman_rounded : Icons.handyman_outlined,
                      size: 22,
                      color: !isCustomer ? AppColors.neutral800 : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Cộng tác viên',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: !isCustomer ? FontWeight.bold : FontWeight.w600,
                        color: !isCustomer ? AppColors.neutral800 : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Tiêu đề Khách hàng (Image 1: bTaskee / Neatify style với màu chủ đạo)
  Widget _buildCustomerHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 80,
            height: 80,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brand500.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                'assets/images/Logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        Text(
          'Chào mừng đến với Neatify',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.brand500,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Nhập số điện thoại để tiếp tục',
          style: TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// Tiêu đề Cộng tác viên (Image 4: Logo bTaskee / Neatify Dành cho Tasker với màu vàng chanh)
  Widget _buildCollaboratorHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Thanh chọn Quốc gia & Ngôn ngữ như Image 4
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _buildFlagIcon(),
                const SizedBox(width: 6),
                DropdownButton<String>(
                  value: _selectedCountry,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Việt Nam', child: Text('Việt Nam')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCountry = val);
                  },
                ),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.translate, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                DropdownButton<String>(
                  value: _selectedLanguage,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Tiếng Việt', child: Text('Tiếng Việt')),
                    DropdownMenuItem(value: 'English', child: Text('English')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedLanguage = val);
                  },
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Ảnh Logo Neatify của bạn (thay thế emoji / placeholder icon)
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.ctvYellowBorder, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.ctvYellow.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/images/Logo.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Neatify Tasker',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: AppColors.neutral800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.ctvYellowLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.ctvYellowBorder),
          ),
          child: const Text(
            'Dành cho Đối tác Cộng tác viên',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: AppColors.ctvYellowDark,
            ),
          ),
        ),
      ],
    );
  }

  /// Trường nhập Số điện thoại (+84 cờ Việt Nam)
  Widget _buildPhoneInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Số điện thoại',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCustomer ? AppColors.divider : AppColors.textPrimary.withValues(alpha: 0.7),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              // Prefix cờ Việt Nam và +84
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 8),
                child: Row(
                  children: [
                    _buildFlagIcon(),
                    const SizedBox(width: 6),
                    const Text(
                      '+84',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                  ],
                ),
              ),
              Container(width: 1, height: 28, color: AppColors.divider),
              // Input nhập số điện thoại
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Nhập số điện thoại',
                    hintStyle: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14.5,
                      fontWeight: FontWeight.normal,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Vui lòng nhập số điện thoại';
                    }
                    if (val.trim().length < 9) {
                      return 'Số điện thoại không hợp lệ';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Trường nhập Mật khẩu kèm nút ẩn/hiện
  Widget _buildPasswordInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mật khẩu',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCustomer ? AppColors.divider : AppColors.textPrimary.withValues(alpha: 0.7),
              width: 1.2,
            ),
          ),
          child: TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Nhập mật khẩu',
              hintStyle: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 14.5,
                fontWeight: FontWeight.normal,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: AppColors.textSecondary,
                  size: 20,
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
              if (val.length < 6) {
                return 'Mật khẩu phải từ 6 ký tự trở lên';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  /// Hàng đăng nhập mạng xã hội (Apple, Facebook, Google - Image 1)
  Widget _buildSocialLoginRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSocialCircleButton(
          icon: Icons.apple,
          color: Colors.black,
          onTap: () => _handleSocialLogin('APPLE'),
        ),
        const SizedBox(width: 20),
        _buildSocialCircleButton(
          icon: Icons.facebook,
          color: const Color(0xFF1877F2),
          onTap: () => _handleSocialLogin('FACEBOOK'),
        ),
        const SizedBox(width: 20),
        _buildSocialCircleButton(
          icon: Icons.g_mobiledata,
          color: const Color(0xFFEA4335),
          size: 30,
          onTap: () => _handleSocialLogin('GOOGLE'),
        ),
      ],
    );
  }

  Widget _buildSocialCircleButton({
    required IconData icon,
    required Color color,
    double size = 24,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.divider, width: 1.5),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Icon(icon, color: color, size: size),
        ),
      ),
    );
  }

  void _handleSocialLogin(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đang kết nối đăng nhập qua $provider...'),
        backgroundColor: AppColors.brand500,
      ),
    );
  }

  /// Icon cờ Việt Nam
  Widget _buildFlagIcon() {
    return Container(
      width: 24,
      height: 16,
      decoration: BoxDecoration(
        color: const Color(0xFFDA251D),
        borderRadius: BorderRadius.circular(2),
      ),
      child: const Center(
        child: Icon(Icons.star, color: Color(0xFFFFEB3B), size: 10),
      ),
    );
  }
}
