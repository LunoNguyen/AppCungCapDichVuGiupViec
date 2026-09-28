import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import 'otp_verification_screen.dart';

class CollaboratorRegisterScreen extends StatefulWidget {
  const CollaboratorRegisterScreen({super.key});

  @override
  State<CollaboratorRegisterScreen> createState() =>
      _CollaboratorRegisterScreenState();
}

class _CollaboratorRegisterScreenState
    extends State<CollaboratorRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _idCardController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _selectedGender = 'Nữ';
  String? _selectedArea;
  bool _obscurePassword = true;
  bool _agreeTerms = true;
  bool _isLoading = false;

  final Map<String, bool> _selectedSkills = {
    'Dọn dẹp nhà cơ bản': true,
    'Dọn dẹp tổng thể': false,
    'Giặt ủi quần áo': true,
    'Nấu ăn gia đình': false,
    'Trông trẻ': false,
    'Chăm sóc người cao tuổi': false,
  };

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
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _idCardController.dispose();
    _experienceController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitRegister() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedArea == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn khu vực bạn muốn nhận việc!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    final hasSkill = _selectedSkills.values.any((selected) => selected);
    if (!hasSkill) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất 1 kỹ năng/dịch vụ bạn đảm nhận!'),
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
        title: const Text('Đăng ký Cộng tác viên'),
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
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.brand500.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.brand500.withOpacity(0.2),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified_user_outlined,
                          color: AppColors.brand600, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Trở thành đối tác giúp việc uy tín, chủ động thời gian và tăng thu nhập ổn định.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.brand700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Họ và tên
                _buildLabel('Họ và tên *'),
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    hintText: 'Nhập đầy đủ theo CCCD/CMND',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Vui lòng nhập họ và tên'
                      : null,
                ),
                const SizedBox(height: 14),

                // Số điện thoại
                _buildLabel('Số điện thoại *'),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: 'Ví dụ: 0901 234 567',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Vui lòng nhập số điện thoại'
                      : null,
                ),
                const SizedBox(height: 14),

                // Số CCCD / CMND
                _buildLabel('Số CCCD / CMND *'),
                TextFormField(
                  controller: _idCardController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Mã số 12 số định danh',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Vui lòng nhập số CCCD/CMND';
                    }
                    if (val.trim().length < 9) {
                      return 'Số định danh không hợp lệ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Giới tính
                _buildLabel('Giới tính'),
                Row(
                  children: ['Nữ', 'Nam'].map((gender) {
                    final isSelected = _selectedGender == gender;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedGender = gender;
                          });
                        },
                        child: Container(
                          margin: EdgeInsets.only(
                              right: gender == 'Nữ' ? 8 : 0,
                              left: gender == 'Nam' ? 8 : 0),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.brand500.withOpacity(0.1)
                                : AppColors.neutral100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.brand500
                                  : AppColors.divider,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              gender,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? AppColors.brand600
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Địa chỉ cư trú
                _buildLabel('Địa chỉ thường trú *'),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    hintText: 'Số nhà, đường, phường, quận...',
                    prefixIcon: Icon(Icons.home_outlined),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'Vui lòng nhập địa chỉ'
                      : null,
                ),
                const SizedBox(height: 14),

                // Khu vực nhận việc
                _buildLabel('Khu vực mong muốn nhận việc *'),
                DropdownButtonFormField<String>(
                  value: _selectedArea,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.location_on_outlined),
                    hintText: 'Chọn Quận / Huyện làm việc',
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
                const SizedBox(height: 14),

                // Kỹ năng chuyên môn
                _buildLabel('Dịch vụ có thể đảm nhận *'),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.neutral100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    children: _selectedSkills.keys.map((skill) {
                      return CheckboxListTile(
                        value: _selectedSkills[skill],
                        title: Text(
                          skill,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        activeColor: AppColors.brand500,
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
                const SizedBox(height: 14),

                // Kinh nghiệm làm việc
                _buildLabel('Kinh nghiệm làm việc'),
                TextFormField(
                  controller: _experienceController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Ví dụ: 3 năm làm dọn dẹp gia đình, nấu ăn tốt...',
                  ),
                ),
                const SizedBox(height: 14),

                // Mật khẩu
                _buildLabel('Tạo mật khẩu *'),
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
                    const Expanded(
                      child: Text(
                        'Tôi cam kết thông tin khai báo là hoàn toàn chính xác và tuân thủ các quy tắc ứng xử của Cộng tác viên.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
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
                      backgroundColor: AppColors.brand600,
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
                            'Nộp hồ sơ Cộng tác viên',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
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
