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
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  String? _selectedArea;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeTerms = true;
  bool _isLoading = false;

  final List<String> _districts = [
    'Quận 1, TP. Hồ Chí Minh',
    'Quận 3, TP. Hồ Chí Minh',
    'Quận 4, TP. Hồ Chí Minh',
    'Quận 5, TP. Hồ Chí Minh',
    'Quận 7, TP. Hồ Chí Minh',
    'Quận 10, TP. Hồ Chí Minh',
    'Quận Bình Thạnh, TP. Hồ Chí Minh',
    'Quận Phú Nhuận, TP. Hồ Chí Minh',
    'Quận Tân Bình, TP. Hồ Chí Minh',
    'TP. Thủ Đức, TP. Hồ Chí Minh',
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1940),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 16)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.brand500,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  void _submitRegister() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedArea == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn khu vực cần phục vụ!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Vui lòng đồng ý với Điều khoản dịch vụ và Chính sách bảo mật!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      // Navigate to OTP verification as per UC-KH01
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
        title: const Text('Đăng ký tài khoản'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tạo tài khoản mới',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Điền đầy đủ thông tin để trở thành thành viên và đặt dịch vụ dễ dàng',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // Họ và tên
                _buildLabel('Họ và tên *'),
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    hintText: 'Ví dụ: Nguyễn Văn A',
                    prefixIcon: Icon(Icons.person_outline),
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
                const SizedBox(height: 16),

                // Số điện thoại
                _buildLabel('Số điện thoại *'),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: 'Ví dụ: 0901 234 567',
                    prefixIcon: Icon(Icons.phone_outlined),
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
                const SizedBox(height: 16),

                // Email
                _buildLabel('Email *'),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'Ví dụ: nguyenvana@gmail.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Vui lòng nhập địa chỉ email';
                    }
                    if (!val.contains('@') || !val.contains('.')) {
                      return 'Email không hợp lệ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Ngày sinh
                _buildLabel('Ngày sinh'),
                TextFormField(
                  controller: _dobController,
                  readOnly: true,
                  onTap: _selectDate,
                  decoration: const InputDecoration(
                    hintText: 'Chọn ngày sinh (DD/MM/YYYY)',
                    prefixIcon: Icon(Icons.cake_outlined),
                    suffixIcon: Icon(Icons.calendar_today_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 16),

                // Địa chỉ chi tiết
                _buildLabel('Địa chỉ nhà / Căn hộ *'),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    hintText: 'Số nhà, tên đường, tên toà nhà/chung cư...',
                    prefixIcon: Icon(Icons.home_outlined),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Vui lòng nhập địa chỉ cụ thể';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Khu vực cần phục vụ
                _buildLabel('Khu vực cần phục vụ *'),
                DropdownButtonFormField<String>(
                  value: _selectedArea,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.location_on_outlined),
                    hintText: 'Chọn Quận / Huyện phục vụ',
                  ),
                  items: _districts.map((d) {
                    return DropdownMenuItem(
                      value: d,
                      child: Text(d, style: const TextStyle(fontSize: 14)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedArea = val;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Mật khẩu
                _buildLabel('Mật khẩu *'),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Tối thiểu 6 ký tự',
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
                    if (val.length < 6) {
                      return 'Mật khẩu phải từ 6 ký tự trở lên';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Nhập lại mật khẩu
                _buildLabel('Xác nhận mật khẩu *'),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    hintText: 'Nhập lại mật khẩu của bạn',
                    prefixIcon: const Icon(Icons.lock_reset_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Vui lòng xác nhận mật khẩu';
                    }
                    if (val != _passwordController.text) {
                      return 'Mật khẩu xác nhận không khớp';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Checkbox điều khoản
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: _agreeTerms,
                        activeColor: AppColors.brand500,
                        onChanged: (val) {
                          setState(() {
                            _agreeTerms = val ?? false;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'Tôi đã đọc và đồng ý với ',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          children: [
                            TextSpan(
                              text: 'Điều khoản dịch vụ',
                              style: const TextStyle(
                                color: AppColors.brand600,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const TextSpan(text: ' & '),
                            TextSpan(
                              text: 'Chính sách bảo mật',
                              style: const TextStyle(
                                color: AppColors.brand600,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const TextSpan(text: ' của hệ thống.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Button Đăng ký
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitRegister,
                    style: ElevatedButton.styleFrom(
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
                        : const Text(
                            'Đăng ký tài khoản',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

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
                          fontWeight: FontWeight.bold,
                          color: AppColors.brand600,
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
