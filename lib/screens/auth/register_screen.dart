import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../services/auth_api_service.dart';
import '../../services/auth_flow.dart';
import '../../services/session_service.dart';
import '../customer/customer_main_screen.dart';
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

  String _fmtApiDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool _isAdult(DateTime dob) {
    final now = DateTime.now();
    final adultDay = DateTime(dob.year + 18, dob.month, dob.day);
    return !adultDay.isAfter(now);
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  Future<void> _submitRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreeTerms) {
      _showSnack('Vui lòng đồng ý với Điều khoản sử dụng và Chính sách bảo mật!',
          AppColors.error);
      return;
    }

    if (isCustomer) {
      if (_customerDob != null && !_isAdult(_customerDob!)) {
        _showSnack('Khách hàng phải từ đủ 18 tuổi trở lên.', AppColors.error);
        return;
      }
    } else {
      // Kiểm tra CTV: ngày sinh, khu vực và kỹ năng
      if (_ctvDob == null) {
        _showSnack('Vui lòng chọn ngày sinh!', AppColors.error);
        return;
      }
      if (!_isAdult(_ctvDob!)) {
        _showSnack('Cộng tác viên phải từ đủ 18 tuổi trở lên.', AppColors.error);
        return;
      }
      if (_selectedCtvArea == null) {
        _showSnack('Vui lòng chọn nơi cư trú / khu vực nhận việc!',
            AppColors.error);
        return;
      }
      final hasSkill = _selectedSkills.values.any((s) => s);
      if (!hasSkill) {
        _showSnack('Vui lòng chọn ít nhất 1 dịch vụ bạn mong muốn tham gia!',
            AppColors.error);
        return;
      }
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final phone = SessionService.normalizePhone(_phoneController.text);

    try {
      if (isCustomer) {
        // UC-KH01: Đăng ký Khách hàng -> backend tạo tài khoản chờ kích hoạt + mã OTP
        final address = [
          _addressController.text.trim(),
          if (_selectedCustomerArea != null) _selectedCustomerArea!,
        ].where((e) => e.isNotEmpty).join(', ');

        final response = await _authApiService.registerCustomer(
          hoTen: _fullNameController.text.trim(),
          soDienThoai: phone,
          email: _emailController.text.trim(),
          matKhau: _passwordController.text,
          ngaySinh: _customerDob != null ? _fmtApiDate(_customerDob!) : null,
          diaChiChiTiet: address,
        );
        if (!mounted) return;

        if (!response.success) {
          _showSnack(response.message ?? 'Đăng ký thất bại. Vui lòng thử lại!',
              AppColors.error);
          return;
        }

        // SĐT đã là cộng tác viên: dùng chung tài khoản (đã nhập đúng mật khẩu), không cần OTP
        if (response.data?['canXacThucOtp'] == false) {
          final login = await AuthFlow.login(
            phone: phone,
            password: _passwordController.text,
            asCustomer: true,
          );
          if (!mounted) return;
          _showSnack(
              response.message ?? 'Đã thêm vai trò khách hàng cho tài khoản của bạn.',
              AppColors.success);
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => login.success
                  ? const CustomerMainScreen()
                  : const LoginScreen(initialRoleTab: 0),
            ),
            (route) => false,
          );
          return;
        }

        _showSnack('Đăng ký thành công! Vui lòng nhập mã OTP để kích hoạt.',
            AppColors.success);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OtpVerificationScreen(
              destination: phone,
              password: _passwordController.text,
              demoOtp: response.data?['otpCode']?.toString(),
            ),
          ),
        );
      } else {
        // UC-KH02: Đăng ký Cộng tác viên -> hồ sơ chờ phòng HCNS duyệt
        final response = await _authApiService.registerCollaborator(
          hoTen: _fullNameController.text.trim(),
          soDienThoai: phone,
          matKhau: _passwordController.text,
          ngaySinh: _fmtApiDate(_ctvDob!),
          gioiTinh: _ctvGender == 'Nam' ? 'Nam' : 'Nu',
          noiCuTru: _selectedCtvArea!,
        );
        if (!mounted) return;

        if (!response.success) {
          _showSnack(response.message ?? 'Gửi hồ sơ thất bại. Vui lòng thử lại!',
              AppColors.error);
          return;
        }
        _showCtvSubmittedDialog(
          response.data?['maCongTacVien']?.toString(),
          response.data?['thoiGianXetDuyetDuKien']?.toString(),
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack('Lỗi: $e', AppColors.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCtvSubmittedDialog(String? maCtv, String? thoiGian) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.assignment_turned_in_outlined,
                color: AppColors.partner500, size: 60),
            const SizedBox(height: 14),
            const Text(
              'Đã gửi hồ sơ!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hồ sơ${maCtv != null ? ' $maCtv' : ''} đang chờ duyệt'
              '${thoiGian != null ? ' (dự kiến $thoiGian)' : ''}. '
              'Bạn có thể đăng nhập bằng số điện thoại và mật khẩu vừa tạo sau khi hồ sơ được duyệt.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13.5, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.partner500),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const LoginScreen(initialRoleTab: 1)),
                  );
                },
                child: const Text('Về trang đăng nhập'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color roleColor = isCustomer ? AppColors.brand500 : AppColors.ctvYellow;

    return Scaffold(
      backgroundColor: isCustomer ? Colors.white : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isCustomer ? 'Đăng ký Khách hàng' : 'Đăng ký Cộng tác viên',
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
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. THANH CHUYỂN ĐỔI VAI TRÒ TO NGANG NÚT ĐĂNG KÝ
                _buildRoleSelector(),
                const SizedBox(height: 20),

                // 2. NỘI DUNG FORM (KHÁCH HÀNG HOẶC CỘNG TÁC VIÊN)
                if (isCustomer)
                  _buildCustomerForm()
                else
                  _buildCollaboratorForm(),

                const SizedBox(height: 24),

                // 3. NÚT ĐĂNG KÝ (WIDTH DOUBLE.INFINITY, HEIGHT 52)
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
                            isCustomer ? 'Đăng ký tài khoản' : 'Gửi hồ sơ đăng ký CTV',
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

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Nút chuyển đổi vai trò TO NGANG NÚT ĐĂNG KÝ (Khách hàng vs Cộng tác viên)
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

  // ==========================================
  // 1. FORM ĐĂNG KÝ KHÁCH HÀNG (Image 2 + UC-KH01)
  // ==========================================
  Widget _buildCustomerForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 76,
            height: 76,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brand500.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/Logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
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
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Text(
            'Nếu số điện thoại đã đăng ký vai trò khác (khách hàng / cộng tác viên), hãy nhập đúng mật khẩu đó để dùng chung tài khoản.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ),

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
        // Banner chào mừng Cộng tác viên (Theme vàng chanh)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFEFCE8), // Vàng chanh pastel nhạt
                Color(0xFFFFFBEB),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.ctvYellowBorder, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: AppColors.ctvYellow.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.ctvYellow.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/Logo.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trở thành Đối tác Neatify',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Chủ động nhận việc, thu nhập hấp dẫn lên đến 15 - 20 triệu/tháng',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Thẻ chứa form đăng ký CTV bo góc đẹp mắt (Image 3)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
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
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.ctvYellowLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.ctvYellowBorder),
                    ),
                    child: const Icon(
                      Icons.assignment_ind_outlined,
                      color: AppColors.ctvYellowDark,
                      size: 20,
                    ),
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

              // Họ và tên *
              _buildFieldLabel('Họ và tên', isRequired: true),
              const SizedBox(height: 6),
              _buildCleanInputField(
                controller: _fullNameController,
                hintText: 'Ví dụ: Nguyễn Văn A',
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Vui lòng nhập họ và tên';
                  return null;
                },
              ),

              const SizedBox(height: 18),

              // Giới tính (Hai nút Nam / Nữ to rõ, bo tròn mềm mại)
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
                  // Nút Nam
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _ctvGender = 'Nam'),
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _ctvGender == 'Nam' ? AppColors.ctvYellowLight : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _ctvGender == 'Nam' ? AppColors.ctvYellowDark : AppColors.divider,
                            width: _ctvGender == 'Nam' ? 1.8 : 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.male_rounded,
                              size: 22,
                              color: _ctvGender == 'Nam' ? AppColors.ctvYellowDark : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Nam',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: _ctvGender == 'Nam' ? FontWeight.bold : FontWeight.w500,
                                color: _ctvGender == 'Nam' ? AppColors.neutral800 : AppColors.textPrimary,
                              ),
                            ),
                            if (_ctvGender == 'Nam') ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.check_circle, size: 16, color: AppColors.ctvYellowDark),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Nút Nữ
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _ctvGender = 'Nữ'),
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _ctvGender == 'Nữ' ? AppColors.ctvYellowLight : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _ctvGender == 'Nữ' ? AppColors.ctvYellowDark : AppColors.divider,
                            width: _ctvGender == 'Nữ' ? 1.8 : 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.female_rounded,
                              size: 22,
                              color: _ctvGender == 'Nữ' ? AppColors.ctvYellowDark : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Nữ',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: _ctvGender == 'Nữ' ? FontWeight.bold : FontWeight.w500,
                                color: _ctvGender == 'Nữ' ? AppColors.neutral800 : AppColors.textPrimary,
                              ),
                            ),
                            if (_ctvGender == 'Nữ') ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.check_circle, size: 16, color: AppColors.ctvYellowDark),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Số CMND/CCCD (Image 3)
              _buildFieldLabel('Số CMND/CCCD', isRequired: true),
              const SizedBox(height: 6),
              _buildCleanInputField(
                controller: _idCardController,
                hintText: '12 số CCCD gắn chip',
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

              // Ngày sinh (UC-KH02) - backend bắt buộc
              _buildFieldLabel('Ngày sinh', isRequired: true),
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
                      const Icon(Icons.cake_outlined, size: 20, color: AppColors.ctvYellowDark),
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
                  prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.ctvYellowDark),
                ),
                hint: const Text('Chọn khu vực bạn muốn nhận việc', style: TextStyle(fontSize: 13)),
                items: _districts.map((d) {
                  return DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 13.5)));
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedCtvArea = val);
                },
              ),

              const SizedBox(height: 20),

              // Dịch vụ mong muốn tham gia (UC-KH02)
              _buildFieldLabel('Dịch vụ / Kỹ năng đảm nhận', isRequired: true),
              const SizedBox(height: 8),
              _buildSkillItem(
                title: 'Dọn dẹp nhà cơ bản',
                icon: Icons.cleaning_services_outlined,
              ),
              _buildSkillItem(
                title: 'Dọn dẹp tổng thể',
                icon: Icons.home_work_outlined,
              ),
              _buildSkillItem(
                title: 'Giặt ủi quần áo',
                icon: Icons.local_laundry_service_outlined,
              ),
              _buildSkillItem(
                title: 'Nấu ăn gia đình',
                icon: Icons.restaurant_outlined,
              ),
              _buildSkillItem(
                title: 'Trông trẻ',
                icon: Icons.child_care_outlined,
              ),
              _buildSkillItem(
                title: 'Chăm sóc người cao tuổi',
                icon: Icons.elderly_outlined,
              ),

              const SizedBox(height: 18),

              // Kinh nghiệm làm việc (UC-KH02)
              _buildFieldLabel('Kinh nghiệm làm việc (năm)', isRequired: false),
              const SizedBox(height: 6),
              _buildCleanInputField(
                controller: _experienceController,
                hintText: 'Ví dụ: 2 năm dọn dẹp gia đình, biết nấu ăn...',
              ),

              const SizedBox(height: 20),

              // Khối HỒNG "Nhập mã giới thiệu để nhận quà" (Image 3)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2), // Light soft pink box from Image 3
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFECDD3), width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE4E6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.card_giftcard_rounded,
                            color: Color(0xFFE11D48),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Nhập mã giới thiệu để nhận quà.',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFBE123C),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Nhập mã giới thiệu từ Tasker để nhận được nhiều ưu đãi hấp dẫn từ hệ thống.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF4B5563),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        // Nút Không
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() => _hasReferralCode = false),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: !_hasReferralCode ? Colors.white : Colors.transparent,
                              side: BorderSide(
                                color: !_hasReferralCode ? const Color(0xFFE11D48) : const Color(0xFFCBD5E1),
                                width: !_hasReferralCode ? 1.8 : 1.0,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            ),
                            child: Text(
                              'Không',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: !_hasReferralCode ? FontWeight.bold : FontWeight.w500,
                                color: !_hasReferralCode ? const Color(0xFFE11D48) : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Nút Có
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => setState(() => _hasReferralCode = true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _hasReferralCode ? const Color(0xFFE11D48) : Colors.white,
                              foregroundColor: _hasReferralCode ? Colors.white : AppColors.textPrimary,
                              elevation: _hasReferralCode ? 2 : 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                                side: BorderSide(
                                  color: _hasReferralCode ? Colors.transparent : const Color(0xFFCBD5E1),
                                ),
                              ),
                            ),
                            child: Text(
                              'Có',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _hasReferralCode ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_hasReferralCode) ...[
                      const SizedBox(height: 14),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFECDD3)),
                        ),
                        child: TextFormField(
                          controller: _referralController,
                          decoration: const InputDecoration(
                            hintText: 'Nhập mã giới thiệu Tasker',
                            hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13.5),
                            prefixIcon: Icon(Icons.confirmation_number_outlined, color: Color(0xFFE11D48), size: 20),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 18),

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

  /// Widget hiển thị kỹ năng dạng thẻ có icon và highlight vàng chanh
  Widget _buildSkillItem({required String title, required IconData icon}) {
    final bool isSelected = _selectedSkills[title] ?? false;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedSkills[title] = !isSelected;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.ctvYellowLight : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.ctvYellowDark : AppColors.divider,
            width: isSelected ? 1.6 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.ctvYellow.withValues(alpha: 0.3) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? AppColors.neutral800 : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppColors.neutral800 : AppColors.textPrimary,
                ),
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
              size: 22,
              color: isSelected ? AppColors.ctvYellowDark : AppColors.textMuted,
            ),
          ],
        ),
      ),
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
                final p = SessionService.normalizePhone(val);
                if (!RegExp(r'^0\d{9}$').hasMatch(p)) return 'Số điện thoại không hợp lệ (10 số)';
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
      lastDate: DateTime(DateTime.now().year - 18, DateTime.now().month, DateTime.now().day),
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
      lastDate: DateTime(DateTime.now().year - 18, DateTime.now().month, DateTime.now().day),
    );
    if (picked != null) {
      setState(() => _ctvDob = picked);
    }
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
