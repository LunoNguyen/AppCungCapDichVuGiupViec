import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_colors.dart';
import 'service_detail_screen.dart';
import 'customer_services_screen.dart';
import 'customer_notification_screen.dart';
import '../auth/login_screen.dart';
import '../../services/session_service.dart';
import '../../services/service_catalog_api_service.dart';

class CustomerHomeScreen extends StatefulWidget {
  final ValueChanged<int>? onSwitchTab;
  const CustomerHomeScreen({super.key, this.onSwitchTab});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _currentBannerIndex = 0;
  UserSession? _session;

  bool get _loggedIn => _session?.isCustomer == true;

  List<Map<String, dynamic>> _apiServices = [];

  @override
  void initState() {
    super.initState();
    SessionService.load().then((s) {
      if (mounted) setState(() => _session = s);
    });
    _fetchServicesFromApi();
  }

  Future<void> _fetchServicesFromApi() async {
    try {
      final res = await ServiceCatalogApiService().getServices();
      if (res.success && res.data != null && mounted) {
        setState(() {
          _apiServices = res.data!;
        });
      }
    } catch (_) {}
  }

  IconData _getServiceIcon(String name) {
    final title = name.toLowerCase();
    if (title.contains('dọn dẹp')) return Icons.cleaning_services_rounded;
    if (title.contains('máy lạnh') || title.contains('điều hoà'))
      return Icons.ac_unit_rounded;
    if (title.contains('giặt') || title.contains('ủi'))
      return Icons.local_laundry_service_rounded;
    if (title.contains('nấu ăn')) return Icons.restaurant_rounded;
    if (title.contains('tổng vệ sinh')) return Icons.home_work_rounded;
    if (title.contains('trông trẻ')) return Icons.child_care_rounded;
    if (title.contains('người già') || title.contains('người cao tuổi'))
      return Icons.elderly_rounded;
    if (title.contains('văn phòng')) return Icons.apartment_rounded;
    if (title.contains('sofa') || title.contains('rèm'))
      return Icons.weekend_rounded;
    if (title.contains('chuyển nhà')) return Icons.local_shipping_rounded;
    return Icons.cleaning_services_rounded;
  }

  final PageController _pageController = PageController(viewportFraction: 0.9);

  final List<Map<String, dynamic>> _promoBanners = [
    {
      'title': 'Giảm 50.000đ cho đơn đầu tiên',
      'subtitle': 'Thanh toán qua thẻ hoặc VNPAY',
      'badge': 'ƯU ĐÃI ĐỘC QUYỀN',
      'code': 'NEATIFY50',
      'colors': const [Color(0xFF13666D), Color(0xFF1D969F)],
      'icon': Icons.credit_card_rounded,
    },
    {
      'title': 'Thảnh thơi đón Tết • Tổng vệ sinh',
      'subtitle': 'Đặt trước 7 ngày nhận ưu đãi giảm 20%',
      'badge': 'HOT DEAL',
      'code': 'XUANMOI20',
      'colors': const [Color(0xFF1D969F), Color(0xFF28B5BF)],
      'icon': Icons.cleaning_services_rounded,
    },
    {
      'title': 'Gói tháng • Tiết kiệm đến 30%',
      'subtitle': 'Người làm cố định, linh hoạt đổi lịch',
      'badge': 'TIẾT KIỆM',
      'code': 'TIETKIEM30',
      'colors': const [Color(0xFF167E86), Color(0xFF38C5CF)],
      'icon': Icons.calendar_month_rounded,
    },
  ];

  List<Map<String, dynamic>> get _displayServices {
    if (_apiServices.isNotEmpty) {
      final List<Map<String, dynamic>> list = [];
      for (var s in _apiServices) {
        final String ten = (s['tenDichVu'] ?? '').toString();
        final double gia = double.tryParse(s['giaTien']?.toString() ?? '') ?? 0;
        final String priceStr = gia > 0
            ? 'Từ ${(gia / 1000).toStringAsFixed(0)}.000đ'
            : 'Báo giá';

        list.add({
          'id': s['id'],
          'title': ten,
          'subtitle': s['moTa'] ?? '',
          'icon': _getServiceIcon(ten),
          'price': priceStr,
          'description': s['moTa'] ?? '',
        });
      }
      list.add({
        'title': 'Khám phá',
        'subtitle': 'Xem tất cả',
        'icon': Icons.grid_view_rounded,
        'isExplore': true,
        'price': '',
        'description': 'Khám phá toàn bộ hệ sinh thái dịch vụ.',
      });
      return list;
    }
    return _fallbackServices;
  }

  // Danh sách dự phòng khi offline
  final List<Map<String, dynamic>> _fallbackServices = [
    {
      'id': 1,
      'title': 'Dọn dẹp nhà',
      'subtitle': 'Dọn dẹp theo giờ 2–4 tiếng',
      'icon': Icons.cleaning_services_rounded,
      'price': 'Chỉ từ 60.000đ/giờ',
      'description': 'Dọn dẹp nhà theo giờ linh hoạt 2–4 tiếng.',
    },
    {
      'id': 8,
      'title': 'Tổng vệ sinh',
      'subtitle': 'Vệ sinh chuyên sâu toàn diện',
      'icon': Icons.home_work_rounded,
      'price': 'Từ 500.000đ/nhà',
      'description': 'Vệ sinh chuyên sâu toàn diện.',
    },
    {
      'id': 51,
      'title': 'Vệ sinh máy lạnh',
      'subtitle': 'Rửa lưới lọc, nạp ga, khử khuẩn',
      'icon': Icons.ac_unit_rounded,
      'price': 'Từ 150.000đ/máy',
      'description': 'Bảo dưỡng và vệ sinh máy lạnh.',
    },
    {
      'id': 123,
      'title': 'Nấu ăn gia đình',
      'subtitle': 'Đi chợ và nấu bữa cơm gia đình',
      'icon': Icons.restaurant_rounded,
      'price': 'Từ 180.000đ/buổi',
      'description': 'Đầu bếp gia đình chuẩn bị bữa cơm ấm cúng.',
    },
    {
      'id': 72,
      'title': 'Trông trẻ',
      'subtitle': 'Người giữ trẻ có kinh nghiệm',
      'icon': Icons.child_care_rounded,
      'price': 'Từ 80.000đ/giờ',
      'description': 'Cộng tác viên giữ trẻ yêu trẻ.',
    },
    {
      'title': 'Khám phá',
      'subtitle': 'Xem tất cả các dịch vụ khác',
      'icon': Icons.grid_view_rounded,
      'isExplore': true,
      'price': '',
      'description': 'Khám phá toàn bộ hệ sinh thái dịch vụ.',
    },
  ];

  final List<Map<String, dynamic>> _rewards = [
    {
      'title': 'Voucher giảm 50K',
      'subtitle': 'Áp dụng cho đơn từ 150K',
      'points': '200',
      'icon': Icons.confirmation_number_rounded,
      'color': const Color(0xFF1D969F),
    },
    {
      'title': 'Giặt sấy giảm 30%',
      'subtitle': 'Giao nhận tận nơi',
      'points': '150',
      'icon': Icons.local_laundry_service_rounded,
      'color': const Color(0xFF1D969F),
    },
    {
      'title': 'Bình nước Neatify',
      'subtitle': 'Quà tặng tri ân khách hàng',
      'points': '500',
      'icon': Icons.card_giftcard_rounded,
      'color': const Color(0xFF1D969F),
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openServices() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CustomerServicesScreen()),
    );
  }

  Future<void> _handleServiceClick(Map<String, dynamic> item) async {
    final isExplore = item['isExplore'] == true;
    if (isExplore) {
      _openServices();
      return;
    }

    final session = await SessionService.load();
    if (session == null || !session.isCustomer) {
      if (!mounted) return;
      _showRequireLoginDialog(item);
      return;
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ServiceDetailScreen(service: item)),
    );
  }

  void _showRequireLoginDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        contentPadding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                color: AppColors.brandLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_rounded,
                color: AppColors.brand500,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Yêu cầu đăng nhập',
              style: TextStyle(
                fontSize: 17.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vui lòng đăng nhập tài khoản khách hàng để đặt dịch vụ "${(item['title'] as String).replaceAll('\n', ' ')}" và đồng bộ đơn hàng với hệ thống.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(initialRoleTab: 0),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brand500,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Đăng nhập ngay',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Để sau',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openLogin() {
    if (_loggedIn) {
      widget.onSwitchTab?.call(3); // đã đăng nhập -> sang tab Tài khoản
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBg,
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header cam + thẻ dịch vụ nổi lên trên header (kiểu bTaskee)
              Stack(
                children: [
                  _buildTopHeader(),
                  Padding(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 118,
                    ),
                    child: _buildRewardStrip(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildServicesSection(),
              const SizedBox(height: 12),
              _buildPromoCarousel(),
              const SizedBox(height: 12),
              _buildRewardsSection(),
              const SizedBox(height: 12),
              _buildTrustBadges(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== HEADER =====================

  Widget _buildTopHeader() {
    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).padding.top + 160,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF13666D), Color(0xFF1D969F), Color(0xFF28B5BF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Xin chào 👋',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: _openLogin,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              _loggedIn
                                  ? (_session!.fullName.isNotEmpty
                                        ? _session!.fullName
                                        : 'Khách hàng')
                                  : 'Đăng nhập / Tạo tài khoản',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _headerIcon(Icons.headset_mic_outlined, _showSupportBottomSheet),
              _headerIcon(Icons.notifications_none_rounded, () {
                if (widget.onSwitchTab != null) {
                  widget.onSwitchTab!(2);
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CustomerNotificationScreen(),
                    ),
                  );
                }
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerIcon(IconData icon, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white, size: 24),
      splashRadius: 22,
    );
  }

  // Dải số dư và điểm thưởng kiểu 2 ô như bTaskee
  Widget _buildRewardStrip() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Ô 1: Số dư ví
            Expanded(
              child: InkWell(
                onTap: _openLogin,
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF3DC),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          'đ',
                          style: TextStyle(
                            color: Color(0xFFF59E0B),
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '0 đ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textMuted,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
            const VerticalDivider(
              width: 20,
              thickness: 1,
              color: AppColors.divider,
            ),
            // Ô 2: Điểm thưởng bPoints
            Expanded(
              child: InkWell(
                onTap: _openLogin,
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: AppColors.brandLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.military_tech_rounded,
                        color: AppColors.brand500,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '0 bPoints',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textMuted,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== DỊCH VỤ =====================

  Widget _buildServicesSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Dịch vụ', 'Xem tất cả', _openServices),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _displayServices.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.74,
              crossAxisSpacing: 8,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, index) =>
                _buildGridServiceItem(_displayServices[index]),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, String? action, VoidCallback? onTap) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (action != null)
          InkWell(
            onTap: onTap,
            child: Text(
              action,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.brand500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGridServiceItem(Map<String, dynamic> item) {
    final String title = item['title'] as String;
    final String? subTag = item['subTag'] as String?;
    final String? badge = item['badge'] as String?;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _handleServiceClick(item),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 2),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF0FAFA), Color(0xFFDFF3F5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brand500.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  border: Border.all(
                    color: AppColors.brand300.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF13666D), Color(0xFF1D969F)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ).createShader(bounds),
                    child: Icon(
                      item['icon'] as IconData,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
              if (badge != null)
                Positioned(
                  top: -5,
                  right: -8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      gradient: badge == 'bCare'
                          ? const LinearGradient(
                              colors: [Color(0xFFEA580C), Color(0xFFF97316)],
                            )
                          : const LinearGradient(
                              colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
                            ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.15,
            ),
          ),
          if (subTag != null) ...[
            const SizedBox(height: 2),
            Text(
              subTag,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: AppColors.brand500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===================== BANNER ƯU ĐÃI =====================

  Widget _buildPromoCarousel() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _sectionTitle('Ưu đãi dành cho bạn', null, null),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 132,
            child: PageView.builder(
              controller: _pageController,
              padEnds: false,
              itemCount: _promoBanners.length,
              onPageChanged: (index) =>
                  setState(() => _currentBannerIndex = index),
              itemBuilder: (context, index) =>
                  _buildBanner(_promoBanners[index]),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _promoBanners.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _currentBannerIndex == index ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _currentBannerIndex == index
                      ? AppColors.brand500
                      : AppColors.divider,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner(Map<String, dynamic> banner) {
    final colors = banner['colors'] as List<Color>;
    return Container(
      margin: const EdgeInsets.only(left: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  banner['badge'] as String,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  banner['title'] as String,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Mã: ${banner['code']}',
                    style: TextStyle(
                      color: colors.first,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            banner['icon'] as IconData,
            color: Colors.white.withValues(alpha: 0.9),
            size: 56,
          ),
        ],
      ),
    );
  }

  // ===================== ĐỔI QUÀ =====================

  Widget _buildRewardsSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _sectionTitle('Đổi quà', 'Xem thêm', _openLogin),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _rewards.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) =>
                  _buildRewardCard(_rewards[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardCard(Map<String, dynamic> r) {
    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 72,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF0FAFA), Color(0xFFDFF3F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Center(
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF13666D), Color(0xFF1D969F)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ).createShader(bounds),
                child: Icon(
                  r['icon'] as IconData,
                  color: Colors.white,
                  size: 34,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r['title'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.stars_rounded,
                      color: AppColors.brand500,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${r['points']} điểm',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brand500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===================== CAM KẾT =====================

  Widget _buildTrustBadges() {
    final trustItems = [
      {
        'icon': Icons.verified_user_outlined,
        'title': 'Bảo hiểm 10 triệu',
        'subtitle': 'An tâm về tài sản',
      },
      {
        'icon': Icons.badge_outlined,
        'title': '100% xác thực',
        'subtitle': 'Lý lịch rõ ràng',
      },
      {
        'icon': Icons.thumb_up_alt_outlined,
        'title': 'Đổi người miễn phí',
        'subtitle': 'Nếu chưa hài lòng',
      },
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Vì sao chọn Neatify?', null, null),
          const SizedBox(height: 14),
          Row(
            children: trustItems.map((item) {
              return Expanded(
                child: Column(
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      color: AppColors.brand500,
                      size: 28,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item['title'] as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item['subtitle'] as String,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showSupportBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Hỗ trợ khách hàng',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Chúng tôi luôn sẵn sàng hỗ trợ bạn từ 8:00 - 21:00 hàng ngày.',
              style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: AppColors.brandLight,
                child: Icon(Icons.phone_rounded, color: AppColors.brand500),
              ),
              title: const Text('Tổng đài hỗ trợ'),
              subtitle: const Text('1900 xxxx (Miễn phí cước gọi)'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: AppColors.brandLight,
                child: Icon(Icons.email_outlined, color: AppColors.brand500),
              ),
              title: const Text('Email phản hồi'),
              subtitle: const Text('hotro@neatify.vn'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }
}
