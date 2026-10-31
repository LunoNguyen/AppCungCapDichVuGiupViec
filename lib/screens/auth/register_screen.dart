import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/app_colors.dart';
import '../../core/password_rules.dart';
import '../../services/auth_api_service.dart';
import '../../services/auth_flow.dart';
import '../../services/session_service.dart';
import '../../services/storage_api_service.dart';
import '../../services/service_catalog_api_service.dart';
import '../../widgets/dia_chi_fields.dart';
import '../../widgets/password_checklist.dart';
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
  final StorageApiService _storageApiService = StorageApiService();
  final ServiceCatalogApiService _catalogApiService = ServiceCatalogApiService();
  final ImagePicker _imagePicker = ImagePicker();

  late int _roleIndex; // 0: Khách hàng, 1: Cộng tác viên
  bool get isCustomer => _roleIndex == 0;

  // Controllers dùng chung và riêng
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _referralController = TextEditingController();

  // Các trường bổ sung cho Khách hàng (UC-KH01)
  final TextEditingController _addressController = TextEditingController(); // số nhà, tên đường
  DateTime? _customerDob;
  final DiaChiDangChon _diaChiKhach = DiaChiDangChon(); // địa chỉ nơi ở (tỉnh, phường)

  // Các trường bổ sung cho Cộng tác viên (UC-KH02, Image 3)
  final TextEditingController _experienceController = TextEditingController(); // Kinh nghiệm
  String _ctvGender = 'Nữ'; // Giới tính: Nam / Nữ
  DateTime? _ctvDob;
  final DiaChiDangChon _diaChiCtv = DiaChiDangChon(); // ĐỊA CHỈ nơi ở hiện tại
  bool _hasReferralCode = false; // Nút [Không] / [Có] trong box mã giới thiệu

  // Hồ sơ bắt buộc CTV: AnhChanDung, CCCD_Mat_Truoc, CCCD_Mat_Sau
  final Map<String, String> _uploadedHoSo = {}; // loai -> objectName
  final Map<String, Uint8List> _previewHoSo = {}; // loai -> bytes
  final Map<String, bool> _uploadingHoSo = {}; // loai -> bool

  // Chứng chỉ tùy chọn CTV (nhiều file)
  final List<Map<String, dynamic>> _uploadedChungChi = []; // [{'ten': file.name, 'objectName': '...', 'bytes': Uint8List}]
  bool _isUploadingChungChi = false;

  // Danh mục dịch vụ động từ backend
  List<Map<String, dynamic>> _allServices = [];
  final Map<String, List<Map<String, dynamic>>> _servicesByCategory = {};
  final Map<String, Map<String, List<Map<String, dynamic>>>> _repServicesByCategory = {};
  final Set<int> _selectedServiceIds = {};
  final Set<String> _expandedCategories = {};
  bool _isLoadingServices = false;

  bool _obscurePassword = true;
  // SĐT đã có tài khoản vai trò khác: nhập mật khẩu hiện tại để dùng chung, không áp quy tắc mật khẩu mới
  bool _dungChungTaiKhoan = false;
  bool _agreeTerms = true;

  bool get _matKhauHopLe =>
      _dungChungTaiKhoan ||
      PasswordRules.isValid(_passwordController.text, _phoneController.text);
  bool _isLoading = false;

  final TextEditingController _ctvAddressController = TextEditingController(); // Số nhà, tên đường hiện tại

  // ==========================================
  // ĐIỀU KIỆN MỞ KHÓA TUẦN TỰ (TỪ TRÊN XUỐNG)
  // ==========================================

  // --- 1. Dành cho Khách hàng ---
  bool get _isCustHoTenOk => _fullNameController.text.trim().length >= 2;

  bool get _isCustPhoneOk =>
      _isCustHoTenOk &&
      RegExp(r'^0\d{9}$').hasMatch(SessionService.normalizePhone(_phoneController.text.trim()));

  bool get _isCustPasswordOk =>
      _isCustPhoneOk && _matKhauHopLe && _passwordController.text.isNotEmpty;

  bool get _isCustDiaChiOk {
    if (!_isCustPasswordOk) return false;
    final d = _diaChiKhach;
    final hasTinh = d.maTinh != null;
    final hasPhuongOrQuan = d.isV1
        ? (d.quanV1 != null && d.phuongV1 != null)
        : (d.phuong != null);
    final hasSoNha = _addressController.text.trim().length >= 3;
    return hasTinh && hasPhuongOrQuan && hasSoNha;
  }

  bool get _isCustomerFormComplete => _isCustDiaChiOk;

  // --- 2. Dành cho Cộng tác viên ---
  bool get _isCtvHoTenOk => _fullNameController.text.trim().length >= 2;

  bool get _isCtvPhoneOk =>
      _isCtvHoTenOk &&
      RegExp(r'^0\d{9}$').hasMatch(SessionService.normalizePhone(_phoneController.text.trim()));

  bool get _isCtvPasswordOk =>
      _isCtvPhoneOk && _matKhauHopLe && _passwordController.text.isNotEmpty;

  bool get _isCtvDobOk =>
      _isCtvPasswordOk && _ctvDob != null && _isAdult(_ctvDob!);

  bool get _isCtvDiaChiOk {
    if (!_isCtvDobOk) return false;
    final d = _diaChiCtv;
    final hasTinh = d.maTinh != null;
    final hasPhuongOrQuan = d.isV1
        ? (d.quanV1 != null && d.phuongV1 != null)
        : (d.phuong != null);
    final hasSoNha = _ctvAddressController.text.trim().length >= 3;
    return hasTinh && hasPhuongOrQuan && hasSoNha;
  }

  bool get _isCtvServicesOk =>
      _isCtvDiaChiOk && _selectedServiceIds.isNotEmpty;

  bool get _isCtvHoSoOk =>
      _isCtvServicesOk &&
      _uploadedHoSo.containsKey('AnhChanDung') &&
      _uploadedHoSo.containsKey('CCCD_Mat_Truoc') &&
      _uploadedHoSo.containsKey('CCCD_Mat_Sau');

  bool get _isCollaboratorFormComplete =>
      _isCtvHoSoOk && _agreeTerms;

  bool get _isCurrentFormComplete =>
      isCustomer ? _isCustomerFormComplete : _isCollaboratorFormComplete;

  @override
  void initState() {
    super.initState();
    _roleIndex = widget.initialRoleTab;
    _fullNameController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
    _emailController.addListener(_onFieldChanged);
    _passwordController.addListener(_onFieldChanged);
    _ctvAddressController.addListener(_onFieldChanged);
    _addressController.addListener(_onFieldChanged);
    _experienceController.addListener(_onFieldChanged);
    _referralController.addListener(_onFieldChanged);
    _fetchServices();
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _fetchServices() async {
    setState(() => _isLoadingServices = true);
    try {
      final res = await _catalogApiService.getServices();
      if (res.success && res.data != null) {
        _allServices = res.data!;
        _buildServiceGroupings();
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingServices = false);
  }

  void _buildServiceGroupings() {
    _servicesByCategory.clear();
    _repServicesByCategory.clear();
    for (final s in _allServices) {
      final cat = (s['tenLoaiDichVu'] ?? 'Dịch vụ khác').toString();
      _servicesByCategory.putIfAbsent(cat, () => []).add(s);

      final repName = _rutGonTenDichVu((s['tenDichVu'] ?? '').toString());
      _repServicesByCategory.putIfAbsent(cat, () => {});
      _repServicesByCategory[cat]!.putIfAbsent(repName, () => []).add(s);
    }
    if (_servicesByCategory.isNotEmpty) {
      _expandedCategories.add(_servicesByCategory.keys.first);
    }
  }

  String _rutGonTenDichVu(String ten) {
    if (ten.isEmpty) return '';
    return ten
        .replaceAll(RegExp(r'\s*\(.*?\)', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+(tối đa|dưới|trên|từ|nhỏ hơn|lớn hơn)\s.*$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+\d.*$'), '')
        .trim();
  }

  void _toggleRepService(String category, String repName) {
    final list = _repServicesByCategory[category]?[repName] ?? [];
    if (list.isEmpty) return;
    final ids = list.map((s) => s['id'] as int).toList();
    final allSelected = ids.every((id) => _selectedServiceIds.contains(id));
    setState(() {
      if (allSelected) {
        for (final id in ids) {
          _selectedServiceIds.remove(id);
        }
      } else {
        _selectedServiceIds.addAll(ids);
      }
    });
  }

  Future<void> _pickAndUploadHoSo(String loai) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.ctvYellowDark),
              title: const Text('Chụp ảnh từ Camera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.ctvYellowDark),
              title: const Text('Chọn ảnh từ Thư viện'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final XFile? file = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (file == null) return;

      setState(() => _uploadingHoSo[loai] = true);
      final bytes = await file.readAsBytes();

      final res = await _storageApiService.uploadCTVHoSo(
        bytes: bytes,
        fileName: file.name.isNotEmpty ? file.name : '$loai.jpg',
      );

      if (!mounted) return;

      if (res.success && res.data != null && res.data!['objectName'] != null) {
        setState(() {
          _uploadedHoSo[loai] = res.data!['objectName'].toString();
          _previewHoSo[loai] = bytes;
        });
        _showSnack('Tải ảnh thành công!', AppColors.success);
      } else {
        _showSnack(res.message ?? 'Tải ảnh thất bại', AppColors.error);
      }
    } catch (e) {
      if (mounted) _showSnack('Lỗi: $e', AppColors.error);
    } finally {
      if (mounted) setState(() => _uploadingHoSo[loai] = false);
    }
  }

  Future<void> _pickAndUploadChungChi() async {
    try {
      final List<XFile> files = await _imagePicker.pickMultiImage(
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (files.isEmpty) return;

      setState(() => _isUploadingChungChi = true);

      int addedCount = 0;
      for (final file in files) {
        final bytes = await file.readAsBytes();
        final res = await _storageApiService.uploadChungChi(
          bytes: bytes,
          fileName: file.name,
        );
        if (res.success && res.data != null && res.data!['objectName'] != null) {
          setState(() {
            _uploadedChungChi.add({
              'ten': file.name,
              'objectName': res.data!['objectName'].toString(),
              'bytes': bytes,
            });
          });
          addedCount++;
        }
      }
      if (mounted && addedCount > 0) {
        _showSnack('Đã thêm $addedCount chứng chỉ thành công!', AppColors.success);
      }
    } catch (e) {
      if (mounted) _showSnack('Lỗi tải chứng chỉ: $e', AppColors.error);
    } finally {
      if (mounted) setState(() => _isUploadingChungChi = false);
    }
  }

  void _openImageLightbox({Uint8List? bytes, String? networkUrl, required String title}) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(ctx),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              child: Container(
                color: Colors.black,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                child: InteractiveViewer(
                  child: bytes != null
                      ? Image.memory(bytes, fit: BoxFit.contain)
                      : (networkUrl != null
                          ? Image.network(StorageApiService.resolveImageUrl(networkUrl), fit: BoxFit.contain)
                          : const SizedBox()),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.removeListener(_onFieldChanged);
    _phoneController.removeListener(_onFieldChanged);
    _emailController.removeListener(_onFieldChanged);
    _passwordController.removeListener(_onFieldChanged);
    _ctvAddressController.removeListener(_onFieldChanged);
    _addressController.removeListener(_onFieldChanged);
    _experienceController.removeListener(_onFieldChanged);
    _referralController.removeListener(_onFieldChanged);

    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _referralController.dispose();
    _addressController.dispose();
    _ctvAddressController.dispose();
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
      // Kiểm tra CTV: ngày sinh, dịch vụ, và tài liệu bắt buộc
      if (_ctvDob == null) {
        _showSnack('Vui lòng chọn ngày sinh!', AppColors.error);
        return;
      }
      if (!_isAdult(_ctvDob!)) {
        _showSnack('Cộng tác viên phải từ đủ 18 tuổi trở lên.', AppColors.error);
        return;
      }
      if (_selectedServiceIds.isEmpty) {
        _showSnack('Vui lòng chọn ít nhất 1 dịch vụ bạn mong muốn tham gia!', AppColors.error);
        return;
      }
      if (_uploadedHoSo['AnhChanDung'] == null ||
          _uploadedHoSo['CCCD_Mat_Truoc'] == null ||
          _uploadedHoSo['CCCD_Mat_Sau'] == null) {
        _showSnack('Vui lòng tải đủ Ảnh chân dung và 2 mặt CCCD!', AppColors.error);
        return;
      }
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final phone = SessionService.normalizePhone(_phoneController.text);

    try {
      if (isCustomer) {
        // UC-KH01: Đăng ký Khách hàng -> backend tạo tài khoản chờ kích hoạt + mã OTP
        final maPhuongKhach = _diaChiKhach.isV1
            ? _diaChiKhach.phuongV1?.ma
            : _diaChiKhach.phuong?.ma;
        final maQuanKhach = _diaChiKhach.isV1
            ? _diaChiKhach.quanV1?.ma
            : null;
        final response = await _authApiService.registerCustomer(
          hoTen: _fullNameController.text.trim(),
          soDienThoai: phone,
          email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
          matKhau: _passwordController.text,
          ngaySinh: _customerDob != null ? _fmtApiDate(_customerDob!) : null,
          // Địa chỉ nơi ở thành địa chỉ mặc định; khu vực suy ra từ phường
          soNhaTenDuong: _addressController.text.trim(),
          maTinh: _diaChiKhach.maTinh,
          maQuan: maQuanKhach,
          maPhuong: maPhuongKhach,
          khuVucId: (!_diaChiKhach.isV1 && (_diaChiKhach.phuong?.khuVuc.length ?? 0) > 1) ? _diaChiKhach.khuVuc?.id : null,
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
        final List<Map<String, dynamic>> danhSachHoSo = [
          {'loaiTaiLieu': 'AnhChanDung', 'duongDanFile': _uploadedHoSo['AnhChanDung']},
          {'loaiTaiLieu': 'CCCD_Mat_Truoc', 'duongDanFile': _uploadedHoSo['CCCD_Mat_Truoc']},
          {'loaiTaiLieu': 'CCCD_Mat_Sau', 'duongDanFile': _uploadedHoSo['CCCD_Mat_Sau']},
        ];
        final List<Map<String, dynamic>> danhSachChungChi = _uploadedChungChi.map((cc) => {
          'loaiChungChi': 'ChungChi',
          'tenChungChi': cc['ten'] ?? 'Chứng chỉ',
          'noiCap': 'Tải lên từ ứng dụng',
          'duongDanFile': cc['objectName'],
        }).toList();

        final maPhuongCtv = _diaChiCtv.isV1
            ? _diaChiCtv.phuongV1?.ma
            : _diaChiCtv.phuong?.ma;
        final maQuanCtv = _diaChiCtv.isV1
            ? _diaChiCtv.quanV1?.ma
            : null;
        final phuongTen = _diaChiCtv.tenPhuongHienTai ?? '';
        final quanTen = _diaChiCtv.tenQuanHienTai != null ? ', ${_diaChiCtv.tenQuanHienTai}' : '';
        final tinhTen = _diaChiCtv.tenTinh ?? '';
        final soNhaCtv = _ctvAddressController.text.trim();
        final noiCuTruCtv = '$soNhaCtv, $phuongTen$quanTen, $tinhTen';

        final response = await _authApiService.registerCollaborator(
          hoTen: _fullNameController.text.trim(),
          soDienThoai: phone,
          email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
          matKhau: _passwordController.text,
          ngaySinh: _fmtApiDate(_ctvDob!),
          gioiTinh: _ctvGender == 'Nam' ? 'Nam' : 'Nu',
          noiCuTru: noiCuTruCtv,
          soNhaTenDuong: soNhaCtv,
          maTinh: _diaChiCtv.maTinh,
          maQuan: maQuanCtv,
          maPhuong: maPhuongCtv,
          tinhThanh: tinhTen,
          phuongXa: phuongTen,
          danhSachDichVuId: _selectedServiceIds.toList(),
          danhSachHoSo: danhSachHoSo,
          danhSachChungChi: danhSachChungChi.isNotEmpty ? danhSachChungChi : null,
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

  Widget _buildStepLockWrapper({
    required bool isUnlocked,
    required Widget child,
    required String lockMessage,
  }) {
    if (isUnlocked) {
      return child;
    }
    return IgnorePointer(
      ignoring: true,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: 0.42,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            child,
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_rounded, size: 13, color: AppColors.textMuted),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      lockMessage,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
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
                    onPressed: _isLoading || !_isCurrentFormComplete ? null : _submitRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isCurrentFormComplete ? roleColor : const Color(0xFFE2E8F0),
                      foregroundColor: _isCurrentFormComplete
                          ? (isCustomer ? Colors.white : AppColors.neutral800)
                          : const Color(0xFF94A3B8),
                      elevation: _isCurrentFormComplete ? (isCustomer ? 2 : 1) : 0,
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
                              color: _isCurrentFormComplete
                                  ? (isCustomer ? Colors.white : AppColors.neutral800)
                                  : const Color(0xFF94A3B8),
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
                'assets/images/icon_btaskee.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        // Title (Image 2: "Đăng ký" màu chủ đạo)
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
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),

        // 1. Họ và tên * (Luôn mở)
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

        // 2. Số điện thoại (Mở khóa khi có Họ và tên)
        _buildStepLockWrapper(
          isUnlocked: _isCustHoTenOk,
          lockMessage: 'Vui lòng nhập Họ và tên ở trên trước',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFieldLabel('Số điện thoại', isRequired: true),
              const SizedBox(height: 6),
              _buildPhoneField(controller: _phoneController),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // 3. Mật khẩu (Mở khóa khi có Số điện thoại hợp lệ)
        _buildStepLockWrapper(
          isUnlocked: _isCustPhoneOk,
          lockMessage: 'Vui lòng nhập Số điện thoại hợp lệ ở trên trước',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFieldLabel('Mật khẩu', isRequired: true),
              const SizedBox(height: 6),
              _buildPasswordField(),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // 4. Địa chỉ nơi ở hiện tại (Mở khóa khi có Mật khẩu hợp lệ)
        _buildStepLockWrapper(
          isUnlocked: _isCustPasswordOk,
          lockMessage: 'Vui lòng thiết lập Mật khẩu hợp lệ ở trên trước',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFieldLabel('Địa chỉ nơi ở hiện tại', isRequired: true),
              const SizedBox(height: 8),
              DiaChiFields(
                giaTri: _diaChiKhach,
                soNhaCtrl: _addressController,
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 5. Thông tin tùy chọn (Không bắt buộc: Email, Ngày sinh, Mã giới thiệu)
        _buildStepLockWrapper(
          isUnlocked: _isCustDiaChiOk,
          lockMessage: 'Vui lòng hoàn thành Địa chỉ nơi ở ở trên trước',
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 18, color: AppColors.brand500),
                    SizedBox(width: 8),
                    Text(
                      'Thông tin bổ sung (Không bắt buộc)',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Email (không bắt buộc)
                _buildFieldLabel('Email (không bắt buộc)', isRequired: false),
                const SizedBox(height: 6),
                _buildCleanInputField(
                  controller: _emailController,
                  hintText: 'johnlegend@gmail.com',
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) {
                    if (val != null && val.trim().isNotEmpty && !val.contains('@')) {
                      return 'Email không hợp lệ';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 14),

                // Ngày sinh (không bắt buộc)
                _buildFieldLabel('Ngày sinh (không bắt buộc)', isRequired: false),
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
                                : 'Chọn ngày sinh (tùy chọn)',
                            style: TextStyle(
                              fontSize: 13.5,
                              color: _customerDob != null ? AppColors.textPrimary : AppColors.textMuted,
                            ),
                          ),
                        ),
                        if (_customerDob != null)
                          GestureDetector(
                            onTap: () => setState(() => _customerDob = null),
                            child: const Icon(Icons.clear, size: 18, color: AppColors.textMuted),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Mã giới thiệu (nếu có)
                _buildFieldLabel('Mã giới thiệu (nếu có)', isRequired: false),
                const SizedBox(height: 6),
                _buildCleanInputField(
                  controller: _referralController,
                  hintText: '123456',
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Điều khoản & Chính sách (Image 2)
        RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
            children: [
              TextSpan(text: 'Bằng việc đăng ký, bạn đồng ý với các '),
              TextSpan(
                text: 'Điều khoản dịch vụ',
                style: TextStyle(
                  color: AppColors.brand500,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(text: ' và '),
              TextSpan(
                text: 'Chính sách bảo mật',
                style: TextStyle(
                  color: AppColors.brand500,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(text: ' của chúng tôi.'),
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
                  'assets/images/icon_partner.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trở thành Đối tác bTaskee',
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

              // Họ và tên * (Luôn mở)
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

              // Số điện thoại & Email (Mở khóa khi có Họ và tên)
              _buildStepLockWrapper(
                isUnlocked: _isCtvHoTenOk,
                lockMessage: 'Vui lòng nhập Họ và tên ở trên trước',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Số điện thoại', isRequired: true),
                    const SizedBox(height: 6),
                    _buildPhoneField(controller: _phoneController),
                    const SizedBox(height: 18),
                    _buildFieldLabel('Email (không bắt buộc)', isRequired: false),
                    const SizedBox(height: 6),
                    _buildCleanInputField(
                      controller: _emailController,
                      hintText: 'email@vi-du.com',
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) {
                        if (val != null && val.trim().isNotEmpty && !val.contains('@')) {
                          return 'Email không hợp lệ';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Mật khẩu (Mở khóa khi có Số điện thoại hợp lệ)
              _buildStepLockWrapper(
                isUnlocked: _isCtvPhoneOk,
                lockMessage: 'Vui lòng nhập Số điện thoại hợp lệ ở trên trước',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Mật khẩu (để đăng nhập lần sau)', isRequired: true),
                    const SizedBox(height: 6),
                    _buildPasswordField(),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Ngày sinh (Mở khóa khi Mật khẩu hợp lệ)
              _buildStepLockWrapper(
                isUnlocked: _isCtvPasswordOk,
                lockMessage: 'Vui lòng thiết lập Mật khẩu hợp lệ ở trên trước',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ĐỊA CHỈ nơi ở hiện tại (Mở khóa khi có Ngày sinh đủ 18 tuổi)
              _buildStepLockWrapper(
                isUnlocked: _isCtvDobOk,
                lockMessage: 'Vui lòng chọn Ngày sinh (từ đủ 18 tuổi) ở trên trước',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Địa chỉ nơi ở hiện tại', isRequired: true),
                    const SizedBox(height: 8),
                    DiaChiFields(
                      giaTri: _diaChiCtv,
                      soNhaCtrl: _ctvAddressController,
                      onChanged: (_) => setState(() {}),
                      ghiChuKhuVuc: (d) {
                        if (d.isV1) {
                          if (d.quanV1 == null) return '';
                          return d.quanV1!.khuVucId == null
                              ? 'Nơi ở ngoài khu vực bTaskee đang phục vụ'
                              : 'Thuộc khu vực: ${d.quanV1!.tenKhuVuc ?? d.quanV1!.ten}';
                        }
                        return d.phuong == null
                            ? ''
                            : d.phuong!.khuVuc.isEmpty
                                ? 'Nơi ở ngoài khu vực bTaskee đang phục vụ'
                                : 'Thuộc khu vực: ${d.phuong!.khuVuc.map((k) => k.ten).join(' / ')}';
                      },
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Khu vực nhận việc được xác định theo vị trí GPS khi bạn dùng ứng dụng; trước đó bTaskee dùng quận nơi bạn ở.',
                      style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Dịch vụ / Kỹ năng đảm nhận (Mở khóa khi hoàn thành Địa chỉ)
              _buildStepLockWrapper(
                isUnlocked: _isCtvDiaChiOk,
                lockMessage: 'Vui lòng hoàn thành Địa chỉ nơi ở ở trên trước',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Dịch vụ / Kỹ năng đảm nhận', isRequired: true),
                    const SizedBox(height: 8),
                    _buildServiceCatalogSection(),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Hồ sơ & Giấy tờ tùy thân (Mở khóa khi đã chọn ít nhất 1 dịch vụ)
              _buildStepLockWrapper(
                isUnlocked: _isCtvServicesOk,
                lockMessage: 'Vui lòng chọn ít nhất 1 dịch vụ đảm nhận ở trên trước',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Hồ sơ & Giấy tờ tùy thân', isRequired: true),
                    const SizedBox(height: 8),
                    _buildDocumentUploadCard(
                      type: 'AnhChanDung',
                      title: 'Ảnh chân dung',
                      hint: 'Chụp rõ khuôn mặt, nhìn thẳng, không đeo kính râm hay khẩu trang.',
                      icon: Icons.face_rounded,
                    ),
                    _buildDocumentUploadCard(
                      type: 'CCCD_Mat_Truoc',
                      title: 'Căn cước công dân - Mặt trước',
                      hint: 'Chụp rõ họ tên, số CCCD, không bị lóa hay mất góc.',
                      icon: Icons.badge_outlined,
                    ),
                    _buildDocumentUploadCard(
                      type: 'CCCD_Mat_Sau',
                      title: 'Căn cước công dân - Mặt sau',
                      hint: 'Chụp rõ vân tay và đặc điểm nhận dạng.',
                      icon: Icons.flip_to_back_outlined,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Chứng chỉ, Kinh nghiệm, Mã giới thiệu, Điều khoản (Mở khóa khi đã tải đủ 3 hồ sơ bắt buộc)
              _buildStepLockWrapper(
                isUnlocked: _isCtvHoSoOk,
                lockMessage: 'Vui lòng tải đủ 3 ảnh hồ sơ bắt buộc (Chân dung, CCCD 2 mặt) trước',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Chứng chỉ nghề nghiệp (Tùy chọn)', isRequired: false),
                    const SizedBox(height: 8),
                    _buildChungChiSection(),

                    const SizedBox(height: 18),

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
          ),
        ),
      ],
    );
  }

  // ==========================================
  // DỊCH VỤ & DANH MỤC CTV
  // ==========================================
  Widget _buildServiceCatalogSection() {
    if (_isLoadingServices) {
      return Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        child: const Column(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ctvYellowDark),
            ),
            SizedBox(height: 8),
            Text(
              'Đang tải danh mục dịch vụ...',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_servicesByCategory.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: AppColors.error, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Chưa có dữ liệu dịch vụ hoặc lỗi kết nối. Bấm để thử lại.',
                style: TextStyle(fontSize: 13, color: AppColors.error),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.error, size: 20),
              onPressed: _fetchServices,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Chọn các dịch vụ bạn có thể thực hiện:',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _selectedServiceIds.isNotEmpty ? AppColors.ctvYellow : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_selectedServiceIds.length} dịch vụ đã chọn',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: _selectedServiceIds.isNotEmpty ? AppColors.neutral800 : AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ..._servicesByCategory.keys.map((cat) {
          final isExpanded = _expandedCategories.contains(cat);
          final repMap = _repServicesByCategory[cat] ?? {};
          final catServiceIds = (_servicesByCategory[cat] ?? []).map((s) => s['id'] as int).toSet();
          final selectedInCat = catServiceIds.where((id) => _selectedServiceIds.contains(id)).length;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selectedInCat > 0 ? AppColors.ctvYellowDark : const Color(0xFFE2E8F0),
                width: selectedInCat > 0 ? 1.5 : 1.0,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // Header Danh mục lớn (Accordion)
                InkWell(
                  onTap: () {
                    setState(() {
                      if (isExpanded) {
                        _expandedCategories.remove(cat);
                      } else {
                        _expandedCategories.add(cat);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    color: selectedInCat > 0 ? AppColors.ctvYellowLight.withValues(alpha: 0.6) : const Color(0xFFF8FAFC),
                    child: Row(
                      children: [
                        Icon(
                          Icons.folder_outlined,
                          size: 20,
                          color: selectedInCat > 0 ? AppColors.ctvYellowDark : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            cat,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (selectedInCat > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: AppColors.ctvYellowDark,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$selectedInCat đã chọn',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        Icon(
                          isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
                // Body: Danh sách dịch vụ đại diện
                if (isExpanded)
                  Container(
                    padding: const EdgeInsets.all(10),
                    color: Colors.white,
                    child: Column(
                      children: repMap.keys.map((repName) {
                        final items = repMap[repName] ?? [];
                        final ids = items.map((s) => s['id'] as int).toList();
                        final isRepSelected = ids.isNotEmpty && ids.every((id) => _selectedServiceIds.contains(id));
                        final isPartiallySelected = !isRepSelected && ids.any((id) => _selectedServiceIds.contains(id));

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isRepSelected
                                ? AppColors.ctvYellowLight
                                : (isPartiallySelected ? const Color(0xFFFFFBEB) : const Color(0xFFF8FAFC)),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isRepSelected
                                  ? AppColors.ctvYellowDark
                                  : (isPartiallySelected ? AppColors.ctvYellowBorder : const Color(0xFFE2E8F0)),
                              width: isRepSelected ? 1.5 : 1.0,
                            ),
                          ),
                          child: InkWell(
                            onTap: () => _toggleRepService(cat, repName),
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: Row(
                                children: [
                                  Icon(
                                    isRepSelected
                                        ? Icons.check_box
                                        : (isPartiallySelected ? Icons.indeterminate_check_box : Icons.check_box_outline_blank),
                                    size: 22,
                                    color: (isRepSelected || isPartiallySelected)
                                        ? AppColors.ctvYellowDark
                                        : AppColors.textMuted,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          repName,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: isRepSelected ? FontWeight.bold : FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        if (items.length > 1)
                                          Text(
                                            'Gồm ${items.length} gói: ${items.map((i) => i['tenDichVu']).join(', ')}',
                                            style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ==========================================
  // TÀI LIỆU HỒ SƠ CTV (ẢNH CHÂN DUNG, CCCD 2 MẶT)
  // ==========================================
  Widget _buildDocumentUploadCard({
    required String type,
    required String title,
    required String hint,
    required IconData icon,
  }) {
    final isUploaded = _uploadedHoSo.containsKey(type);
    final isBusy = _uploadingHoSo[type] ?? false;
    final previewBytes = _previewHoSo[type];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isUploaded ? const Color(0xFFF0FDF4) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUploaded ? const Color(0xFF86EFAC) : AppColors.divider,
          width: isUploaded ? 1.6 : 1.2,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: isUploaded ? const Color(0xFF16A34A) : AppColors.ctvYellowDark),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ),
              if (isUploaded)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 14, color: Color(0xFF16A34A)),
                      SizedBox(width: 4),
                      Text(
                        'Đã tải lên',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(hint, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          if (isBusy)
            Container(
              height: 100,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ctvYellowDark),
                  ),
                  SizedBox(height: 8),
                  Text('Đang tải ảnh lên hệ thống...', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            )
          else if (isUploaded && previewBytes != null)
            Row(
              children: [
                // Thumbnail có thể chạm để xem to (Lightbox)
                InkWell(
                  onTap: () => _openImageLightbox(bytes: previewBytes, title: title),
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          previewBytes,
                          width: 100,
                          height: 70,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(Icons.zoom_in, color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Đổi ảnh khác', style: TextStyle(fontSize: 12.5)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.neutral800,
                          side: const BorderSide(color: AppColors.ctvYellowDark),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onPressed: () => _pickAndUploadHoSo(type),
                      ),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: () => _openImageLightbox(bytes: previewBytes, title: title),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('🔍 Chạm để xem phóng to', style: TextStyle(fontSize: 12, color: AppColors.brand500)),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            InkWell(
              onTap: () => _pickAndUploadHoSo(type),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.add_a_photo_outlined, color: AppColors.ctvYellowDark, size: 28),
                    SizedBox(height: 6),
                    Text(
                      'Chạm để chụp hoặc chọn ảnh từ máy',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    SizedBox(height: 2),
                    Text('Định dạng JPG, PNG (tối đa 20MB)', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // CHỨNG CHỈ / BẰNG CẤP NGHỀ (TÙY CHỌN)
  // ==========================================
  Widget _buildChungChiSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider, width: 1.2),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.military_tech_outlined, size: 20, color: AppColors.ctvYellowDark),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _uploadedChungChi.isEmpty
                            ? 'Chứng chỉ / Bằng cấp nghề'
                            : 'Chứng chỉ (${_uploadedChungChi.length})',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Thêm chứng chỉ', style: TextStyle(fontSize: 12.5)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.ctvYellow,
                  foregroundColor: AppColors.neutral800,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _isUploadingChungChi ? null : _pickAndUploadChungChi,
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Bằng cấp, chứng chỉ nghề, giấy chứng nhận sơ cứu, v.v. (tải nhiều file)',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          if (_isUploadingChungChi)
            Container(
              padding: const EdgeInsets.all(12),
              alignment: Alignment.center,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ctvYellowDark),
                  ),
                  SizedBox(width: 10),
                  Text('Đang tải chứng chỉ lên...', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                ],
              ),
            ),
          if (_uploadedChungChi.isNotEmpty)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _uploadedChungChi.asMap().entries.map((entry) {
                final idx = entry.key;
                final cc = entry.value;
                final bytes = cc['bytes'] as Uint8List?;
                final ten = (cc['ten'] ?? 'Chứng chỉ').toString();

                return Stack(
                  children: [
                    InkWell(
                      onTap: () => _openImageLightbox(bytes: bytes, title: ten),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 90,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: bytes != null
                                  ? Image.memory(bytes, width: 82, height: 60, fit: BoxFit.cover)
                                  : Container(
                                      width: 82,
                                      height: 60,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.description, color: Colors.grey),
                                    ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ten,
                              style: const TextStyle(fontSize: 10.5, color: AppColors.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _uploadedChungChi.removeAt(idx);
                          });
                        },
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(3),
                          child: const Icon(Icons.close, color: Colors.white, size: 12),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            )
          else
            InkWell(
              onTap: _pickAndUploadChungChi,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
                ),
                alignment: Alignment.center,
                child: const Text(
                  '+ Chạm để chọn chứng chỉ / bằng cấp',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                ),
              ),
            ),
        ],
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
                hintText: 'Số điện thoại',
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

  /// Ô mật khẩu + danh sách tiêu chí + ô đánh dấu dùng chung tài khoản đã có.
  Widget _buildPasswordField({String hintText = 'Ít nhất 8 ký tự, có chữ và số'}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPasswordInput(hintText),
        ListenableBuilder(
          listenable: Listenable.merge([_passwordController, _phoneController]),
          builder: (_, __) => _dungChungTaiKhoan
              ? const SizedBox.shrink()
              : PasswordChecklist(
                  password: _passwordController.text,
                  phone: _phoneController.text,
                ),
        ),
        CheckboxListTile(
          value: _dungChungTaiKhoan,
          onChanged: (v) => setState(() => _dungChungTaiKhoan = v ?? false),
          dense: true,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          visualDensity: VisualDensity.compact,
          title: Text(
            isCustomer
                ? 'Số này đã là cộng tác viên (nhập đúng mật khẩu đó để dùng chung tài khoản)'
                : 'Số này đã có tài khoản khách hàng (nhập đúng mật khẩu đó để dùng chung tài khoản)',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordInput(String hintText) {
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
          if (_dungChungTaiKhoan) return null;
          return PasswordRules.validate(val, _phoneController.text);
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
