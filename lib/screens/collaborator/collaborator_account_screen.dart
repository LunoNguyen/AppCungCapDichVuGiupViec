import 'dart:async';
import 'package:flutter/material.dart';
import '../chinh_sach_screen.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_colors.dart';
import '../../models/cong_tac_vien.dart';
import '../../services/collaborator_api_service.dart';
import '../../services/ctv_location_tracker.dart';
import '../auth/change_password_screen.dart';
import '../auth/login_screen.dart';
import '../customer/customer_main_screen.dart';
import '../../services/session_service.dart';
import '../collaborator/collaborator_notifications_screen.dart';
import 'collaborator_location_screen.dart';

class CollaboratorAccountScreen extends StatefulWidget {
  const CollaboratorAccountScreen({super.key});

  @override
  State<CollaboratorAccountScreen> createState() =>
      CollaboratorAccountScreenState();
}

class CollaboratorAccountScreenState extends State<CollaboratorAccountScreen> {
  String get _currentKhuVuc {
    final live = CtvLocationTracker.instance.currentDistrict?.trim() ?? '';
    if (live.isNotEmpty) return live;
    return _profile?.khuVucNhanViec.trim() ?? '';
  }

  void _onLocationChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  /// Tải ngầm lại hồ sơ & thống kê thu nhập khi mở tab Tài khoản, không hiện vòng xoay.
  Future<void> reload() async {
    if (_currentUserId == 0) return;
    try {
      if (CtvLocationTracker.instance.isRunning) {
        unawaited(CtvLocationTracker.instance.forceSend());
      }
      final response = await _apiService.getProfile(_currentUserId);
      if (response.success && response.data != null) {
        _profile = response.data;
      }
      await _fetchStats();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Lỗi tải lại hồ sơ: $e');
    }
  }

  bool _isLoading = true;
  int _currentUserId = 0;
  CongTacVien? _profile;
  final CollaboratorApiService _apiService = CollaboratorApiService();

  // Số liệu tính từ danh sách đơn hoàn thành (theo công thức 80% CTV - 20% nền tảng)
  int _completedCount = 0;
  num _totalIncome = 0;
  num _totalGrossIncome = 0;
  num _totalPlatformFee = 0;
  List<Map<String, dynamic>> _completedOrders = [];

  num get _effectiveWalletBalance {
    final profileWallet = _profile?.soDuVi ?? 0;
    return _totalIncome > profileWallet ? _totalIncome : profileWallet;
  }

  final NumberFormat _currencyFormat =
  NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

  // Màu theo phong cách bTaskee Partner (xanh lá chủ đạo, cam cho tiền)
  static const _headerTop = AppColors.partner500;
  static const _headerBottom = AppColors.partner800;
  static const _coral = AppColors.ctvMoney;
  static const _ink = AppColors.textPrimary;

  @override
  void initState() {
    super.initState();
    CtvLocationTracker.instance.addListener(_onLocationChanged);
    _loadProfile();
  }

  @override
  void dispose() {
    CtvLocationTracker.instance.removeListener(_onLocationChanged);
    super.dispose();
  }

  bool _dangGuiViTri = false;

  /// Bật lại việc gửi vị trí GPS mỗi 5 giây (vd. sau khi vừa cấp quyền vị trí).
  Future<void> _guiViTri() async {
    if (_dangGuiViTri) return;
    setState(() => _dangGuiViTri = true);
    CtvLocationTracker.instance.stop();
    final loi = await CtvLocationTracker.instance.start(_currentUserId);
    if (!mounted) return;
    // Chờ 1.2s để toạ độ GPS gửi lên server và đồng bộ CSDL, sau đó tải lại hồ sơ ngay lập tức
    await Future.delayed(const Duration(milliseconds: 1200));
    await reload();
    if (!mounted) return;
    setState(() => _dangGuiViTri = false);
    final quan = _profile?.khuVucNhanViec;
    final msg = loi ?? (quan != null && quan.isNotEmpty
        ? 'Đã cập nhật vị trí GPS: '
        : 'Đang chia sẻ vị trí của bạn (cập nhật mỗi 5 giây).');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: loi == null ? AppColors.success : AppColors.error,
    ));
  }

  // ===================== DỮ LIỆU =====================

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getInt('userId') ?? 0;

    if (_currentUserId == 0) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    await _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.getProfile(_currentUserId);
      if (response.success && response.data != null) {
        _profile = response.data;
      }
      await _fetchStats();
    } catch (e) {
      debugPrint('Lỗi tải hồ sơ: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  num _getGrossPrice(Map<String, dynamic> a) {
    return num.tryParse(a['thanhTien']?.toString() ??
            a['tongTienDon']?.toString() ??
            a['tongTien']?.toString() ??
            '') ??
        0;
  }

  num _getPlatformFee(Map<String, dynamic> a) {
    final fromApi = num.tryParse(a['phiNenTang']?.toString() ?? '');
    if (fromApi != null && fromApi > 0) return fromApi.round();
    final gross = _getGrossPrice(a);
    final net = (gross * 0.80).round();
    return gross.round() - net;
  }

  num _getNetIncome(Map<String, dynamic> a) {
    final fromApi = num.tryParse(a['tienThucNhan']?.toString() ?? '');
    if (fromApi != null && fromApi > 0) return fromApi.round();
    final gross = _getGrossPrice(a);
    return (gross * 0.80).round();
  }

  // Đếm đơn hoàn thành + tổng thu nhập thực nhận (80%) từ API đơn
  Future<void> _fetchStats() async {
    try {
      final res =
          await _apiService.getAssignments(congTacVienId: _currentUserId);
      if (res.success && res.data != null) {
        int count = 0;
        num netSum = 0;
        num grossSum = 0;
        num feeSum = 0;
        final List<Map<String, dynamic>> doneList = [];
        for (final a in res.data!) {
          final s1 = (a['trangThaiDon'] ?? '').toString().toLowerCase();
          final s2 = (a['trangThaiPhanCong'] ?? '').toString().toLowerCase();
          final s3 = (a['trangThai'] ?? '').toString().toLowerCase();
          final isDone = s1 == 'hoanthanh' ||
              s1 == 'hoan_thanh' ||
              s1 == 'completed' ||
              s2 == 'hoanthanh' ||
              s2 == 'hoan_thanh' ||
              s2 == 'completed' ||
              s3 == 'hoanthanh' ||
              s3 == 'hoan_thanh' ||
              s3 == 'completed';
          if (isDone) {
            count++;
            grossSum += _getGrossPrice(a);
            feeSum += _getPlatformFee(a);
            netSum += _getNetIncome(a);
            doneList.add(Map<String, dynamic>.from(a));
          }
        }
        _completedCount = count;
        _totalGrossIncome = grossSum;
        _totalPlatformFee = feeSum;
        _totalIncome = netSum;
        _completedOrders = doneList;
      }
    } catch (e) {
      debugPrint('Lỗi tải thống kê: $e');
    }
  }

  // ===================== GIAO DIỆN CHÍNH =====================

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _profile == null) {
      return const Scaffold(
        backgroundColor: AppColors.scaffoldBg,
        body: Center(
            child: CircularProgressIndicator(color: _headerTop)),
      );
    }

    if (_profile == null) {
      return Scaffold(
        backgroundColor: AppColors.scaffoldBg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_outlined,
                  size: 60, color: AppColors.ctvYellowBorder),
              const SizedBox(height: 12),
              const Text('Không thể tải thông tin tài khoản',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchProfileData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _headerTop,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBg,
        body: RefreshIndicator(
          onRefresh: _fetchProfileData,
          color: _headerTop,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildHeader(),
                // Thẻ số liệu đè lên header
                Transform.translate(
                  offset: const Offset(0, -28),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildStatsCard(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Column(
                    children: [
                      if (_isProfileIncomplete) ...[
                        _buildIncompleteBanner(),
                        const SizedBox(height: 16),
                      ],
                      _buildWalletCard(),
                      const SizedBox(height: 16),
                      _buildAvailabilityCard(),
                      const SizedBox(height: 20),
                      _buildMenuSection('CÔNG VIỆC & DỊCH VỤ', [
                        _MenuItem(Icons.handyman_outlined, 'Dịch vụ đã đăng ký',
                            '5 dịch vụ', AppColors.partner500, () {}),
                        // Khu vực nhận việc tự cập nhật theo quận CTV đang đứng (GPS), không chọn tay
                        _MenuItem(Icons.map_outlined, 'Khu vực nhận việc',
                            _currentKhuVuc.isNotEmpty
                                ? '$_currentKhuVuc · theo GPS'
                                : 'Đang chờ vị trí GPS',
                            const Color(0xFF2F80ED), () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CollaboratorLocationScreen()),
                            ).then((_) => reload())),
                      ]),
                      const SizedBox(height: 16),
                      _buildMenuSection('TÀI CHÍNH', [
                        _MenuItem(
                            Icons.credit_card_outlined,
                            'Tài khoản ngân hàng',
                            'Vietcombank',
                            AppColors.partner500,
                                () {}),
                        _MenuItem(
                            Icons.receipt_long_outlined,
                            'Lịch sử thu nhập',
                            '$_completedCount đơn (80%)',
                            const Color(0xFFC77700),
                            _showIncomeHistorySheet),
                      ]),
                      const SizedBox(height: 16),
                      _buildMenuSection('TÀI KHOẢN', [
                        _MenuItem(
                            Icons.notifications_outlined,
                            'Thông báo',
                            '',
                            const Color(0xFFC77700),
                                () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                  const CollaboratorNotificationsScreen()),
                            )),
                        _MenuItem(
                            Icons.badge_outlined,
                            'Thông tin cá nhân & CCCD',
                            _profile!.trangThai == TrangThaiCTV.ChoDuyet
                                ? 'Chờ duyệt'
                                : 'Đã xác thực',
                            _headerTop,
                                () {}),
                        _MenuItem(
                            Icons.star_outline,
                            'Đánh giá từ khách hàng',
                            '${_profile!.diemDanhGia.toStringAsFixed(1)} ★',
                            const Color(0xFFF2A100),
                                () {}),
                        _MenuItem(Icons.my_location, 'Cập nhật vị trí (GPS)',
                            _currentKhuVuc.isNotEmpty ? _currentKhuVuc : 'Chạm để định vị', _coral,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CollaboratorLocationScreen()),
                            ).then((_) => reload())),
                        _MenuItem(Icons.lock_outline, 'Đổi mật khẩu', '',
                            _coral, () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ChangePasswordScreen(
                                      roleColor: AppColors.partner500)),
                            )),
                      ]),
                      const SizedBox(height: 16),
                      _buildMenuSection('HỖ TRỢ', [
                        _MenuItem(Icons.headset_mic_outlined,
                            'Trung tâm trợ giúp', '', const Color(0xFF2F80ED), () {}),
                        _MenuItem(Icons.description_outlined,
                            'Điều khoản & chính sách', '', Colors.grey,
                            () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const ChinhSachScreen()),
                                )),
                      ]),
                      const SizedBox(height: 24),
                      _buildLogoutButton(),
                      const SizedBox(height: 12),
                      const Text(
                        'bTaskee • Phiên bản 1.0.0',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Hồ sơ rỗng (tạo tự động khi CTV đăng nhập lần đầu mà chưa có hồ sơ)
  bool get _isProfileIncomplete =>
      _profile!.hoTen.trim().isEmpty || _profile!.noiCuTru.trim().isEmpty;

  Widget _buildIncompleteBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.partnerLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.ctvYellowBorder),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.partner600),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Hồ sơ của bạn chưa hoàn thiện. Vui lòng bổ sung họ tên, ngày sinh, '
              'nơi cư trú và giấy tờ để được duyệt và nhận việc.',
              style: TextStyle(
                  fontSize: 13, color: AppColors.textPrimary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // ===================== HEADER =====================

  Widget _buildHeader() {
    final name = _profile!.hoTen.trim().isNotEmpty
        ? _profile!.hoTen
        : 'Cộng tác viên mới';
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 4, 16, 52),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_headerTop, _headerBottom],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 48),
              const Expanded(
                child: Text(
                  'Tài khoản',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                icon:
                const Icon(Icons.settings_outlined, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Avatar có viền
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
            ),
            child: CircleAvatar(
              radius: 38,
              backgroundColor: Colors.white,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'C',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AppColors.partner600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Mã CTV: ${_profile!.maCongTacVien}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _headerChip(Icons.star_rounded,
                  _profile!.diemDanhGia.toStringAsFixed(1), const Color(0xFFFFD166)),
              const SizedBox(width: 8),
              _profile!.trangThai == TrangThaiCTV.ChoDuyet
                  ? _headerChip(Icons.hourglass_top_rounded, 'Chờ duyệt',
                      Colors.white)
                  : _headerChip(Icons.verified_outlined, 'Đã xác thực',
                      const Color(0xFF9FE1CB)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerChip(IconData icon, String text, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ===================== SỐ LIỆU =====================

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: _statItem('$_completedCount', 'Đơn hoàn thành',
                Icons.done_all_rounded, AppColors.success),
          ),
          Container(width: 1, height: 36, color: Colors.black.withValues(alpha: 0.08)),
          Expanded(
            child: _statItem(_profile!.diemDanhGia.toStringAsFixed(1),
                'Đánh giá', Icons.star_rounded, const Color(0xFFF2A100)),
          ),
          Container(width: 1, height: 36, color: Colors.black.withValues(alpha: 0.08)),
          Expanded(
            child: InkWell(
              onTap: _showIncomeHistorySheet,
              child: _statItem(_compactMoney(_effectiveWalletBalance), 'Tổng thu nhập',
                  Icons.trending_up_rounded, _coral),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800, color: _ink)),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  // 1.250.000 -> 1,25tr | 340.000 -> 340k
  String _compactMoney(num v) {
    if (v >= 1000000) {
      final m = (v / 1000000).toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
      return '${m.replaceAll('.', ',')}tr';
    }
    if (v >= 1000) return '${(v / 1000).round()}k';
    return '${v.round()}đ';
  }

  // ===================== VÍ =====================

  Widget _buildWalletCard() {
    final num balance = _effectiveWalletBalance;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _showIncomeHistorySheet,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.partner500, AppColors.partner400],
          ),
          boxShadow: [
            BoxShadow(
              color: _coral.withValues(alpha: 0.3),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.account_balance_wallet_outlined,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ví thu nhập (Thực nhận 80%)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _currencyFormat.format(balance),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Đã trừ 20% phí nền tảng • $_completedCount đơn hoàn thành',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _showIncomeHistorySheet,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _coral,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('Chi tiết',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showIncomeHistorySheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.82,
          ),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded,
                        color: Color(0xFF16A34A), size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chi tiết Ví & Lịch sử thu nhập',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                          ),
                        ),
                        Text(
                          'Tỷ lệ phân chia: CTV nhận 80% • Phí nền tảng 20%',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Bảng tổng hợp
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Tổng giá trị đơn hoàn thành (100%)',
                            style: TextStyle(
                                fontSize: 12.5, color: Color(0xFF334155)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _currencyFormat.format(_totalGrossIncome),
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: _ink,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Tổng chiết khấu nền tảng (20%)',
                            style: TextStyle(
                                fontSize: 12.5, color: Color(0xFF64748B)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '-${_currencyFormat.format(_totalPlatformFee)}',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1, color: Color(0xFFBBF7D0)),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Số dư thực nhận trong Ví (80%)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF14532D),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '+${_currencyFormat.format(_effectiveWalletBalance)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF15803D),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'DANH SÁCH ĐƠN ĐÃ CỘNG TIỀN ($_completedCount ĐƠN)',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _completedOrders.isEmpty
                    ? const Center(
                        child: Text(
                          'Chưa có đơn hoàn thành nào',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13.5,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _completedOrders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = _completedOrders[index];
                          final String maDon =
                              (item['maDonDat'] ?? 'N/A').toString();
                          final String tenDv =
                              (item['tenDichVu'] ?? 'Dịch vụ').toString();
                          final String ngay =
                              (item['ngayThucHien'] ?? item['ngayLam'] ?? '')
                                  .toString();
                          final num gross = _getGrossPrice(item);
                          final num fee = _getPlatformFee(item);
                          final num net = _getNetIncome(item);

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        tenDv,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: _ink,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '+${_currencyFormat.format(net)}',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF15803D),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Mã: $maDon${ngay.isNotEmpty ? ' • $ngay' : ''}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          'Gốc: ${_currencyFormat.format(gross)} (-20%: ${_currencyFormat.format(fee)})',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF64748B),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===================== NHẬN VIỆC =====================

  Widget _buildAvailabilityCard() {
    final bool isAvailable = _profile!.trangThai == TrangThaiCTV.HoatDong;
    final Color c = isAvailable ? AppColors.success : Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isAvailable
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_off_outlined,
              color: c,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAvailable ? 'Đang bật nhận việc' : 'Đang tắt nhận việc',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14, color: _ink),
                ),
                const SizedBox(height: 2),
                Text(
                  isAvailable
                      ? 'Bạn sẽ nhận được đơn mới'
                      : 'Bạn sẽ không nhận đơn mới',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Switch(
            value: isAvailable,
            onChanged: (val) async {
              final status = val ? 'HoatDong' : 'TamDung';
              final res =
              await _apiService.updateStatus(_currentUserId, status);
              if (!mounted) return;
              if (res.success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        val ? 'Đã bật nhận việc' : 'Đã tạm dừng nhận việc'),
                    backgroundColor: AppColors.success,
                  ),
                );
                _fetchProfileData();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Không thể đổi trạng thái'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // ===================== MENU =====================

  Widget _buildMenuSection(String title, List<_MenuItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: _cardDecoration(),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                _menuRow(items[i]),
                if (i != items.length - 1)
                  Divider(
                    height: 1,
                    indent: 64,
                    color: Colors.black.withValues(alpha: 0.06),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _menuRow(_MenuItem item) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, size: 20, color: item.color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                item.title,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600, color: _ink),
              ),
            ),
            if (item.subtext.isNotEmpty)
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    item.subtext,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
              ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right,
                size: 20, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  // ===================== ĐĂNG XUẤT =====================

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _confirmLogout,
        icon: const Icon(Icons.logout, size: 18),
        label: const Text('Đăng xuất',
            style: TextStyle(fontWeight: FontWeight.w700)),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          backgroundColor: Colors.white,
          side: const BorderSide(color: AppColors.error),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Đăng xuất?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Bạn có chắc muốn đăng xuất khỏi tài khoản này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    await SessionService.clear();
    if (!mounted) return;
    // Về Trang chủ (gốc của app) rồi mở màn đăng nhập CTV
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const CustomerMainScreen()),
      (route) => false,
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen(initialRoleTab: 1)),
    );
  }

  // ===================== HÀM HỖ TRỢ =====================

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 12,
        offset: const Offset(0, 3),
      ),
    ],
  );
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String subtext;
  final Color color;
  final VoidCallback onTap;

  _MenuItem(this.icon, this.title, this.subtext, this.color, this.onTap);
}
