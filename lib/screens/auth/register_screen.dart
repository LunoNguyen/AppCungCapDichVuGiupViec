import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import 'otp_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _referralController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  void _submitRegister() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      // Navigate to OTP verification screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            destination: _phoneController.text.trim(),
            isPhone: true,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.textPrimary,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title (bTaskee style, Teal brand color)
                const Text(
                  'Đăng ký',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.brand500,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tạo ngay tài khoản để trải nghiệm dịch vụ.',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 28),

                // 1. Họ và tên *
                _buildFieldLabel('Họ và tên', isRequired: true),
                TextFormField(
                  controller: _fullNameController,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Nhập họ và tên',
                    hintStyle: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14.5,
                      fontWeight: FontWeight.normal,
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                    isDense: true,
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: AppColors.brand500, width: 2),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Vui lòng nhập họ và tên';
                    }
                    if (val.trim().length < 2) {
                      return 'Họ tên quá ngắn';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // 2. Số điện thoại *
                _buildFieldLabel('Số điện thoại', isRequired: true),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Container(
                      padding: const EdgeInsets.only(right: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Vietnam Flag Badge
                          Container(
                            width: 24,
                            height: 16,
                            decoration: BoxDecoration(
                              color: const Color(0xFFDA251D),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.star,
                                color: Color(0xFFFFEB3B),
                                size: 10,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            '+84',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 1,
                            height: 18,
                            color: const Color(0xFFE5E7EB),
                          ),
                        ],
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 0,
                      minHeight: 0,
                    ),
                    hintText: 'Nhập số điện thoại',
                    hintStyle: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14.5,
                      fontWeight: FontWeight.normal,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    isDense: true,
                    border: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: AppColors.brand500, width: 2),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Vui lòng nhập số điện thoại';
                    }
                    final phoneRegex = RegExp(r'^(0[3|5|7|8|9])+([0-9]{8})$');
                    if (!phoneRegex.hasMatch(val.trim().replaceAll(' ', ''))) {
                      return 'Số điện thoại không hợp lệ (10 chữ số)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // 3. Email (Không bắt buộc)
                _buildFieldLabel('Email', isRequired: false),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Nhập địa chỉ email',
                    hintStyle: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14.5,
                      fontWeight: FontWeight.normal,
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                    isDense: true,
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: AppColors.brand500, width: 2),
                    ),
                  ),
                  validator: (val) {
                    if (val != null && val.trim().isNotEmpty) {
                      if (!val.contains('@') || !val.contains('.')) {
                        return 'Email không hợp lệ';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // 4. Mật khẩu *
                _buildFieldLabel('Mật khẩu', isRequired: true),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Nhập mật khẩu',
                    hintStyle: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14.5,
                      fontWeight: FontWeight.normal,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    isDense: true,
                    border: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: AppColors.brand500, width: 2),
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
                const SizedBox(height: 20),

                // 5. Mã giới thiệu (nếu có)
                _buildFieldLabel('Mã giới thiệu (nếu có)', isRequired: false),
                TextFormField(
                  controller: _referralController,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Nhập mã giới thiệu',
                    hintStyle: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14.5,
                      fontWeight: FontWeight.normal,
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                    isDense: true,
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: AppColors.brand500, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Điều khoản dịch vụ và chính sách bảo mật (Matching bTaskee)
                Text.rich(
                  TextSpan(
                    text: 'Bằng việc đăng ký, bạn đồng ý với các ',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                    children: [
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () => _showTermsDialog(context),
                          child: const Text(
                            'Điều khoản dịch vụ',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.brand500,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const TextSpan(text: ' và '),
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () => _showPrivacyDialog(context),
                          child: const Text(
                            'Chính sách bảo mật',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.brand500,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const TextSpan(text: ' của chúng tôi.'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Neatify Mascot / Helper illustration
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    child: _buildMascotBadge(),
                  ),
                ),
                const SizedBox(height: 20),

                // Nút Đăng ký (bTaskee layout)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brand500,
                      foregroundColor: Colors.white,
                      elevation: 0,
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
                        : const Text(
                            'Đăng ký',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 18),

                // Link Đăng nhập
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Đã có tài khoản? ',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Đăng nhập ngay',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brand500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, {required bool isRequired}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text.rich(
        TextSpan(
          text: label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6C7C86),
          ),
          children: isRequired
              ? const [
                  TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: Color(0xFFEF4444),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ]
              : const [],
        ),
      ),
    );
  }

  Widget _buildMascotBadge() {
    return SizedBox(
      width: 58,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Antennae
          Positioned(
            top: 2,
            left: 12,
            child: Container(
              width: 4,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.brand500,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Positioned(
            top: 2,
            right: 12,
            child: Container(
              width: 4,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.brand500,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 9,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFFF97316),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 9,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFFF97316),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Head / Body
          Positioned(
            bottom: 12,
            child: Container(
              width: 46,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.brand500,
                  width: 2.2,
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sentiment_satisfied_alt,
                      color: AppColors.brand500, size: 24),
                ],
              ),
            ),
          ),
          // Label Box "NEATIFY"
          Positioned(
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: AppColors.brand500,
                borderRadius: BorderRadius.circular(5),
              ),
              child: const Text(
                'NEAT',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Điều khoản dịch vụ'),
        content: const SingleChildScrollView(
          child: Text(
            '1. Khách hàng cam kết cung cấp thông tin trung thực khi đặt dịch vụ.\n\n'
            '2. Chúng tôi cam kết bảo vệ tài sản và chất lượng của từng buổi giúp việc.\n\n'
            '3. Mọi thắc mắc hoặc sự cố sẽ được giải quyết trong vòng 24 giờ qua tổng đài hỗ trợ.',
            style: TextStyle(fontSize: 13.5, height: 1.4),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brand500,
              foregroundColor: Colors.white,
            ),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Chính sách bảo mật'),
        content: const SingleChildScrollView(
          child: Text(
            '1. Dữ liệu cá nhân (số điện thoại, email) chỉ dùng để liên hệ đặt dịch vụ.\n\n'
            '2. Hệ thống mã hóa thông tin theo tiêu chuẩn quốc tế và không chia sẻ cho bên thứ ba.\n\n'
            '3. Bạn có quyền yêu cầu xóa hoặc cập nhật thông tin tài khoản bất kỳ lúc nào.',
            style: TextStyle(fontSize: 13.5, height: 1.4),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brand500,
              foregroundColor: Colors.white,
            ),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }
}
