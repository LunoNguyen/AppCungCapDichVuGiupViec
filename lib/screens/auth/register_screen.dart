import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../services/auth_api_service.dart';
import 'login_screen.dart';
import 'otp_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  final int initialRoleTab; // 0: Khách hàng (Màu chủ đạo), 1: Cộng tác viên (Màu vàng)
  const RegisterScreen({super.key, this.initialRoleTab = 0});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthApiService _authApiService = AuthApiService();

  late int _roleIndex; // 0: Khách hàng, 1: Cộng tác viên
  bool get isCustomer => _roleIndex == 0;

  // Controllers dùng chung và riêng
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _referralController = TextEditingController();

  // Các trường bổ sung cho Khách hàng (UC-KH01)
  final TextEditingController _addressController = TextEditingController();
  DateTime? _customerDob;
  String? _selectedCustomerArea;

  // Các trường bổ sung cho Cộng tác viên (UC-KH02, Image 3)
  final TextEditingController _idCardController = TextEditingController(); // CMND/CCCD
  final TextEditingController _experienceController = TextEditingController(); // Kinh nghiệm
  String _ctvGender = 'Nữ'; // Giới tính: Nam / Nữ
  DateTime? _ctvDob;
  String? _selectedCtvArea;
  bool _hasReferralCode = false; // Nút [Không] / [Có] trong box mã giới thiệu

  final Map<String, bool> _selectedSkills = {
    'Dọn dẹp nhà cơ bản': true,
    'Dọn dẹp tổng thể': false,
    'Giặt ủi quần áo': true,
    'Nấu ăn gia đình': false,
    'Trông trẻ': false,
    'Chăm sóc người cao tuổi': false,
  };

  bool _obscurePassword = true;
  bool _agreeTerms = true;
  bool _isLoading = false;

  final List<String> _districts = [
    'Quận 1, TP. Hồ Chí Minh',
    'Quận 3, TP. Hồ Chí Minh',
    'Quận 5, TP. Hồ Chí Minh',
    'Quận 7, TP. Hồ Chí Minh',
    'Quận 10, TP. Hồ Chí Minh',
    'Quận Bình Thạnh, TP. Hồ Chí Minh',
    'Quận Tân Bình, TP. Hồ Chí Minh',
    'TP. Thủ Đức, TP. Hồ Chí Minh',
  ];

  @override
  void initState() {
    super.initState();
    _roleIndex = widget.initialRoleTab;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _referralController.dispose();
    _addressController.dispose();
    _idCardController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  void _onRoleChanged(int index) {
    if (_roleIndex == index) return;
    setState(() {
      _roleIndex = index;
    });
  }

  Future<void> _submitRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng đồng ý với Điều khoản sử dụng và Chính sách bảo mật!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Kiểm tra CTV: khu vực và kỹ năng
    if (!isCustomer) {
      if (_selectedCtvArea == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng chọn nơi cư trú / khu vực nhận việc!'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      final hasSkill = _selectedSkills.values.any((s) => s);
      if (!hasSkill) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng chọn ít nhất 1 dịch vụ bạn mong muốn tham gia!'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (isCustomer) {
        // UC-KH01: Đăng ký Khách hàng qua API
        final response = await _authApiService.registerCustomer(
          hoTen: _fullNameController.text.trim(),
          soDienThoai: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          matKhau: _passwordController.text,
          ngaySinh: _customerDob?.toIso8601String().split('T')[0],
          diaChi: _addressController.text.trim(),
          khuVucPhucVu: _selectedCustomerArea,
        );

        if (!mounted) return;

        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đăng ký thành công! Vui lòng xác thực mã OTP.'),
              backgroundColor: AppColors.success,
            ),
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OtpVerificationScreen(
                destination: _phoneController.text.trim(),
                isPhone: true,
                targetRoleTab: 0,
              ),
            ),
          );
        } else {
          // Nếu backend chưa chạy hoặc số điện thoại demo -> vẫn hỗ trợ chuyển sang xác thực OTP để test UI
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? 'Đang chuyển sang bước xác thực OTP...'),
              backgroundColor: AppColors.brand500,
            ),
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OtpVerificationScreen(
                destination: _phoneController.text.trim(),
                isPhone: true,
                targetRoleTab: 0,
              ),
            ),
          );
        }
      } else {
        // UC-KH02: Đăng ký Cộng tác viên (Ứng viên)
        await Future.delayed(const Duration(milliseconds: 700));
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hồ sơ đã được tiếp nhận! Vui lòng xác thực số điện thoại.'),
            backgroundColor: AppColors.ctvYellowDark,
          ),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpVerificationScreen(
              destination: _phoneController.text.trim(),
              isPhone: true,
              targetRoleTab: 1,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
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

  @override
  Widget build(BuildContext context) {
    final Color roleColor = isCustomer ? AppColors.brand500 : AppColors.ctvYellow;

    return Scaffold(
      backgroundColor: isCustomer ? Colors.white : const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: isCustomer ? Colors.white : AppColors.ctvHeaderBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isCustomer ? AppColors.textPrimary : Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: _buildRoleSelector(),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isCustomer)
                  _buildCustomerForm()
                else
                  _buildCollaboratorForm(),

                const SizedBox(height: 24),

                // NÚT ĐĂNG KÝ
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitRegister,
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
                            isCustomer ? 'Đăng ký' : 'Gửi hồ sơ đăng ký CTV',
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.bold,
                              color: isCustomer ? Colors.white : AppColors.neutral800,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                // LIÊN KẾT ĐĂNG NHẬP
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Đã có tài khoản? ',
                        style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LoginScreen(initialRoleTab: _roleIndex),
                            ),
                          );
                        },
                        child: Text(
                          'Đăng nhập ngay',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isCustomer ? AppColors.brand500 : AppColors.ctvYellowDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (isCustomer) ...[
                  const SizedBox(height: 24),
                  _buildKaiMascotBadge(),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Bộ chọn vai trò ở AppBar (Khách hàng vs Cộng tác viên)
  Widget _buildRoleSelector() {
    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isCustomer ? AppColors.neutral100 : Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isCustomer ? AppColors.divider : Colors.white24,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Nút Khách hàng (Teal)
          GestureDetector(
            onTap: () => _onRoleChanged(0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isCustomer ? AppColors.brand500 : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isCustomer
                    ? [
                        BoxShadow(
                          color: AppColors.brand500.withValues(alpha: 0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 16,
                    color: isCustomer ? Colors.white : (isCustomer ? AppColors.textSecondary : Colors.white70),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Khách hàng',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isCustomer ? FontWeight.bold : FontWeight.w500,
                      color: isCustomer ? Colors.white : (isCustomer ? AppColors.textSecondary : Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Nút Cộng tác viên (Vàng)
          GestureDetector(
            onTap: () => _onRoleChanged(1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: !isCustomer ? AppColors.ctvYellow : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                boxShadow: !isCustomer
                    ? [
                        BoxShadow(
                          color: AppColors.ctvYellow.withValues(alpha: 0.45),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.badge,
                    size: 16,
                    color: !isCustomer ? AppColors.neutral800 : (isCustomer ? AppColors.textSecondary : Colors.white70),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Cộng tác viên',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: !isCustomer ? FontWeight.bold : FontWeight.w500,
                      color: !isCustomer ? AppColors.neutral800 : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 1. FORM ĐĂNG KÝ KHÁCH HÀNG (Image 2 + UC-KH01)
  // ==========================================
  Widget _buildCustomerForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title (Image 2: "Đăng ký" màu chủ đạo)
        Text(
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
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),

        // Họ và tên *
        _buildFieldLabel('Họ và tên', isRequired: true),
        const SizedBox(height: 6),
        _buildCleanInputField(
          controller: _fullNameController,
          hintText: 'John Legend',
          validator: (val) {
            if (val == null || val.trim().isEmpty) return 'Vui lòng nhập họ và tên';
            return null;
          },
        ),

        const SizedBox(height: 18),

        // Số điện thoại *
        _buildFieldLabel('Số điện thoại', isRequired: true),
        const SizedBox(height: 6),
        _buildPhoneField(controller: _phoneController),

        const SizedBox(height: 18),

        // Email (UC-KH01)
        _buildFieldLabel('Email', isRequired: false),
        const SizedBox(height: 6),
        _buildCleanInputField(
          controller: _emailController,
          hintText: 'johnlegend@gmail.com',
          keyboardType: TextInputType.emailAddress,
          validator: (val) {
            if (val != null && val.isNotEmpty && !val.contains('@')) {
              return 'Email không hợp lệ';
            }
            return null;
          },
        ),

        const SizedBox(height: 18),

        // Mật khẩu *
        _buildFieldLabel('Mật khẩu', isRequired: true),
        const SizedBox(height: 6),
        _buildPasswordField(),

        const SizedBox(height: 18),

        // Ngày sinh & Khu vực phục vụ (Đặc tả UC-KH01)
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('Ngày sinh', isRequired: false),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: _pickCustomerDob,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _customerDob != null
                                  ? '${_customerDob!.day}/${_customerDob!.month}/${_customerDob!.year}'
                                  : 'Chọn ngày',
                              style: TextStyle(
                                fontSize: 13.5,
                                color: _customerDob != null ? AppColors.textPrimary : AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('Khu vực phục vụ', isRequired: false),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _selectedCustomerArea,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.divider),
                      ),
                    ),
                    hint: const Text('Chọn khu vực', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                    isExpanded: true,
                    items: _districts.map((d) {
                      return DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 13)));
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _selectedCustomerArea = val);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // Địa chỉ (UC-KH01)
        _buildFieldLabel('Địa chỉ', isRequired: false),
        const SizedBox(height: 6),
        _buildCleanInputField(
          controller: _addressController,
          hintText: 'Số nhà, tên đường, phường...',
        ),

        const SizedBox(height: 18),

        // Mã giới thiệu (nếu có) - Image 2
        _buildFieldLabel('Mã giới thiệu (nếu có)', isRequired: false),
        const SizedBox(height: 6),
        _buildCleanInputField(
          controller: _referralController,
          hintText: '123456',
        ),

        const SizedBox(height: 20),

        // Điều khoản & Chính sách (Image 2)
        RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
            children: [
              const TextSpan(text: 'Bằng việc đăng ký, bạn đồng ý với các '),
              TextSpan(
                text: 'Điều khoản dịch vụ',
                style: TextStyle(
                  color: AppColors.brand500,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const TextSpan(text: ' và '),
              TextSpan(
                text: 'Chính sách bảo mật',
                style: TextStyle(
                  color: AppColors.brand500,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const TextSpan(text: ' của chúng tôi.'),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 2. FORM ĐĂNG KÝ CỘNG TÁC VIÊN (Image 3 + UC-KH02)
  // ==========================================
  Widget _buildCollaboratorForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thẻ chứa toàn bộ form đăng ký CTV bo góc đẹp mắt (Image 3)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tiêu đề card
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.ctvYellowLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.badge, color: AppColors.ctvYellowDark, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Thông tin Cộng tác viên',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Họ và tên
              _buildFieldLabel('Họ và tên', isRequired: true),
              const SizedBox(height: 6),
              _buildCleanInputField(
                controller: _fullNameController,
                hintText: 'Nguyễn Văn A',
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Vui lòng nhập họ và tên';
                  return null;
                },
              ),

              const SizedBox(height: 18),

              // Giới tính (Nam / Nữ radio buttons - Image 3)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildFieldLabel('Giới tính', isRequired: true),
                  const Text(
                    'Thông tin bắt buộc',
                    style: TextStyle(fontSize: 11, color: AppColors.error),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _ctvGender = 'Nam'),
                      child: Row(
                        children: [
                          Radio<String>(
                            value: 'Nam',
                            groupValue: _ctvGender,
                            activeColor: AppColors.ctvYellowDark,
                            onChanged: (val) => setState(() => _ctvGender = val!),
                          ),
                          const Text('Nam', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _ctvGender = 'Nữ'),
                      child: Row(
                        children: [
                          Radio<String>(
                            value: 'Nữ',
                            groupValue: _ctvGender,
                            activeColor: AppColors.ctvYellowDark,
                            onChanged: (val) => setState(() => _ctvGender = val!),
                          ),
                          const Text('Nữ', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Ngày sinh (UC-KH02)
              _buildFieldLabel('Ngày sinh', isRequired: false),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickCtvDob,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider, width: 1.2),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cake_outlined, size: 18, color: AppColors.ctvYellowDark),
                      const SizedBox(width: 10),
                      Text(
                        _ctvDob != null
                            ? '${_ctvDob!.day}/${_ctvDob!.month}/${_ctvDob!.year}'
                            : 'Chọn ngày sinh',
                        style: TextStyle(
                          fontSize: 14,
                          color: _ctvDob != null ? AppColors.textPrimary : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Số CMND/CCCD (Image 3)
              _buildFieldLabel('Số CMND/CCCD', isRequired: true),
              const SizedBox(height: 6),
              _buildCleanInputField(
                controller: _idCardController,
                hintText: '123456789',
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Vui lòng nhập CCCD/CMND';
                  if (val.trim().length < 9) return 'CCCD phải từ 9-12 số';
                  return null;
                },
              ),

              const SizedBox(height: 18),

              // Số điện thoại (Image 3)
              _buildFieldLabel('Số điện thoại', isRequired: true),
              const SizedBox(height: 6),
              _buildPhoneField(controller: _phoneController),

              const SizedBox(height: 18),

              // Mật khẩu (để đăng nhập lần sau) - Image 3
              _buildFieldLabel('Mật khẩu (để đăng nhập lần sau)', isRequired: true),
              const SizedBox(height: 3),
              const Text(
                'Mật khẩu phải chứa 6-12 ký tự và không có khoảng cách',
                style: TextStyle(
                  fontSize: 11.5,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              _buildPasswordField(hintText: 'Ít nhất 6 ký tự'),

              const SizedBox(height: 18),

              // Nơi cư trú / Khu vực mong muốn nhận việc (UC-KH02)
              _buildFieldLabel('Nơi cư trú / Khu vực nhận việc', isRequired: true),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedCtvArea,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                ),
                hint: const Text('Chọn khu vực bạn muốn nhận việc', style: TextStyle(fontSize: 13)),
                items: _districts.map((d) {
                  return DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 13.5)));
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedCtvArea = val);
                },
              ),

              const SizedBox(height: 18),

              // Dịch vụ mong muốn tham gia (UC-KH02)
              _buildFieldLabel('Dịch vụ / Kỹ năng đảm nhận', isRequired: true),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.neutral100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: _selectedSkills.keys.map((skill) {
                    return CheckboxListTile(
                      title: Text(skill, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500)),
                      value: _selectedSkills[skill],
                      activeColor: AppColors.ctvYellowDark,
                      dense: true,
                      onChanged: (val) {
                        setState(() {
                          _selectedSkills[skill] = val ?? false;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 18),

              // Kinh nghiệm làm việc (UC-KH02)
              _buildFieldLabel('Kinh nghiệm làm việc (năm)', isRequired: false),
              const SizedBox(height: 6),
              _buildCleanInputField(
                controller: _experienceController,
                hintText: 'Ví dụ: 2 năm dọn dẹp gia đình...',
              ),

              const SizedBox(height: 20),

              // Khối HỒNG "Nhập mã giới thiệu để nhận quà" (Image 3)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE), // Light pink box from Image 3
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFFCDD2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.share, color: Color(0xFFE53935), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Nhập mã giới thiệu để nhận quà.',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFC62828),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Nhập mã giới thiệu từ Tasker để nhận được nhiều ưu đãi hấp dẫn từ hệ thống.',
                      style: TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.3),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Nút Không
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() => _hasReferralCode = false),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: !_hasReferralCode ? Colors.white : Colors.transparent,
                              side: BorderSide(
                                color: !_hasReferralCode ? const Color(0xFFE53935) : AppColors.divider,
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: const Text('Không', style: TextStyle(color: AppColors.textPrimary)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Nút Có
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => setState(() => _hasReferralCode = true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _hasReferralCode ? const Color(0xFFFF5252) : Colors.white,
                              foregroundColor: _hasReferralCode ? Colors.white : AppColors.textPrimary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: _hasReferralCode ? Colors.transparent : AppColors.divider,
                                ),
                              ),
                            ),
                            child: const Text('Có', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                    if (_hasReferralCode) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _referralController,
                        decoration: InputDecoration(
                          hintText: 'Nhập mã giới thiệu Tasker',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Checkbox đồng ý điều khoản (Image 3)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _agreeTerms,
                    activeColor: AppColors.ctvYellowDark,
                    onChanged: (val) => setState(() => _agreeTerms = val ?? false),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.3),
                          children: [
                            TextSpan(text: 'Tôi đồng ý với '),
                            TextSpan(
                              text: 'Điều khoản sử dụng',
                              style: TextStyle(color: AppColors.ctvYellowDark, fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: ' và '),
                            TextSpan(
                              text: 'Chính sách bảo mật',
                              style: TextStyle(color: AppColors.ctvYellowDark, fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: ' của hệ thống.'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // HELPER WIDGETS
  // ==========================================
  Widget _buildFieldLabel(String label, {required bool isRequired}) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        if (isRequired)
          const Text(
            ' *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.error,
            ),
          ),
      ],
    );
  }

  Widget _buildCleanInputField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 1.2),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildPhoneField({required TextEditingController controller}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 1.2),
      ),
      child: Row(
        children: [
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
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.phone,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Nhập số điện thoại',
                hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Vui lòng nhập số điện thoại';
                if (val.trim().length < 9) return 'Số điện thoại không hợp lệ';
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({String hintText = 'Nhập mật khẩu'}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 1.2),
      ),
      child: TextFormField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
          border: InputBorder.none,
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
          if (val == null || val.isEmpty) return 'Vui lòng nhập mật khẩu';
          if (val.length < 6) return 'Mật khẩu phải từ 6 ký tự trở lên';
          return null;
        },
      ),
    );
  }

  Future<void> _pickCustomerDob() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _customerDob ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _customerDob = picked);
    }
  }

  Future<void> _pickCtvDob() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _ctvDob ?? DateTime(1995, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _ctvDob = picked);
    }
  }

  Widget _buildKaiMascotBadge() {
    return Align(
      alignment: Alignment.bottomRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Color(0xFFFF9800),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.smart_toy_outlined, color: Colors.white, size: 16),
              ),
            ),
            const SizedBox(width: 6),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'KAI AI',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF9800),
                  ),
                ),
                Text(
                  'Trợ lý hỗ trợ',
                  style: TextStyle(fontSize: 9, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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
