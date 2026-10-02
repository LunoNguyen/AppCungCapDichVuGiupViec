import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_colors.dart';
import 'service_detail_screen.dart';
import 'customer_services_screen.dart';
import 'customer_notification_screen.dart';
import '../auth/login_screen.dart';
import '../../services/session_service.dart';

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

  @override
  void initState() {
    super.initState();
    SessionService.load().then((s) {
      if (mounted) setState(() => _session = s);
    });
  }
  final PageController _pageController = PageController(viewportFraction: 0.9);

  final List<Map<String, dynamic>> _promoBanners = [
    {
      'title': 'Giảm 50.000đ cho đơn đầu tiên',
      'subtitle': 'Thanh toán qua thẻ hoặc VNPAY',
      'badge': 'ƯU ĐÃI ĐỘC QUYỀN',
      'code': 'NEATIFY50',
      'colors': [Color(0xFF1BB55C), Color(0xFF4CCB80)],
      'icon': Icons.credit_card_rounded,
    },
    {
      'title': 'Thảnh thơi đón Tết • Tổng vệ sinh',
      'subtitle': 'Đặt trước 7 ngày nhận ưu đãi giảm 20%',
      'badge': 'HOT DEAL',
      'code': 'XUANMOI20',
      'colors': [Color(0xFFFF8228), Color(0xFFFFA25E)],
      'icon': Icons.cleaning_services_rounded,
    },
    {
      'title': 'Gói tháng • Tiết kiệm đến 30%',
      'subtitle': 'Người làm cố định, linh hoạt đổi lịch',
      'badge': 'TIẾT KIỆM',
      'code': 'TIETKIEM30',
      'colors': [Color(0xFF2F80ED), Color(0xFF5A9CF2)],
      'icon': Icons.calendar_month_rounded,
    },
  ];

  // Lưới dịch vụ 4 cột như bTaskee
  final List<Map<String, dynamic>> _bTaskeeServices = [
    {
      'title': 'Dọn dẹp nhà',
      'subtitle': 'Dọn dẹp theo giờ 2–4 tiếng',
      'icon': Icons.cleaning_services_rounded,
      'iconColor': Color(0xFFFF8228),
      'price': 'Chỉ từ 60.000đ/giờ',
      'description':
          'Dọn dẹp nhà theo giờ linh hoạt 2–4 tiếng. Phù hợp nhu cầu phát sinh đột xuất.',
    },
    {
      'title': 'Dọn dẹp\ngói tháng',
      'subtitle': 'Đặt lịch định kỳ 2–5 buổi/tuần',
      'icon': Icons.event_repeat_rounded,
      'iconColor': Color(0xFF1BB55C),
      'price': 'Từ 1.200.000đ/tháng',
      'description':
          'Đặt lịch định kỳ 2-5 buổi/tuần. Giữ người làm cố định, an tâm tuyệt đối.',
    },
    {
      'title': 'Tổng vệ sinh',
      'subtitle': 'Vệ sinh chuyên sâu toàn diện',
      'icon': Icons.home_work_rounded,
      'iconColor': Color(0xFF7C3AED),
      'price': 'Từ 500.000đ/nhà',
      'description':
          'Vệ sinh chuyên sâu toàn diện sau xây dựng, chuẩn bị tân gia hoặc dọn dẹp cuối năm.',
    },
    {
      'title': 'Vệ sinh\nmáy lạnh',
      'subtitle': 'Rửa lưới lọc, nạp ga, khử khuẩn',
      'icon': Icons.ac_unit_rounded,
      'iconColor': Color(0xFF2F80ED),
      'price': 'Từ 150.000đ/máy',
      'description':
          'Rửa lưới lọc, xịt dàn nóng lạnh, nạp ga và khử khuẩn chống nấm mốc.',
    },
    {
      'title': 'Nấu ăn\ngia đình',
      'subtitle': 'Đi chợ và nấu bữa cơm gia đình',
      'icon': Icons.restaurant_rounded,
      'iconColor': Color(0xFFEF4444),
      'price': 'Từ 180.000đ/buổi',
      'description':
          'Đầu bếp gia đình chuẩn bị bữa cơm ấm cúng theo đúng khẩu vị, hỗ trợ đi chợ.',
    },
    {
      'title': 'Giặt ủi',
      'subtitle': 'Giặt sấy, giao nhận tận nơi',
      'icon': Icons.local_laundry_service_rounded,
      'iconColor': Color(0xFF0EA5E9),
      'price': 'Từ 25.000đ/kg',
      'description':
          'Giặt sấy quần áo, giặt hấp đồ cao cấp. Giao nhận tận cửa trong 24 giờ.',
    },
    {
      'title': 'Vệ sinh\nSofa - Rèm',
      'subtitle': 'Giặt hơi nước nóng diệt khuẩn',
      'icon': Icons.weekend_rounded,
      'iconColor': Color(0xFFD97706),
      'price': 'Từ 350.000đ/bộ',
      'description':
          'Công nghệ giặt hơi nước nóng diệt khuẩn nệm, ghế sofa và giặt rèm cửa tận nhà.',
    },
    {
      'title': 'Chăm sóc\nngười già',
      'subtitle': 'Hỗ trợ sinh hoạt, nhắc uống thuốc',
      'badge': 'bCare',
      'icon': Icons.elderly_rounded,
      'iconColor': Color(0xFF16A34A),
      'price': 'Từ 120.000đ/giờ',
      'description':
          'Hỗ trợ sinh hoạt hàng ngày, trò chuyện tâm sự, nhắc uống thuốc và theo dõi sức khỏe cơ bản.',
    },
    {
      'title': 'Trông trẻ',
      'subtitle': 'Người giữ trẻ có kinh nghiệm',
      'badge': 'bCare',
      'icon': Icons.child_care_rounded,
      'iconColor': Color(0xFFDB2777),
      'price': 'Từ 80.000đ/giờ',
      'description':
          'Cộng tác viên giữ trẻ yêu trẻ, có nghiệp vụ chăm sóc dinh dưỡng và vui chơi an toàn.',
    },
    {
      'title': 'Dọn\nvăn phòng',
      'subtitle': 'Dọn dẹp văn phòng, phòng họp',
      'badge': 'MỚI',
      'icon': Icons.apartment_rounded,
      'iconColor': Color(0xFF475569),
      'price': 'Từ 80.000đ/giờ',
      'description':
          'Dọn dẹp môi trường làm việc văn phòng, phòng họp, lau kính và khử khuẩn thiết bị.',
    },
    {
      'title': 'Chuyển nhà',
      'subtitle': 'Đóng gói, bốc xếp, vận chuyển',
      'icon': Icons.local_shipping_rounded,
      'iconColor': Color(0xFF2563EB),
      'price': 'Báo giá khảo sát',
      'description':
          'Trọn gói đóng gói đồ đạc, bốc xếp và xe tải vận chuyển tận nhà mới an toàn.',
    },
    {
      'title': 'Tháo lắp\nmáy lạnh',
      'subtitle': 'Tháo dỡ, di dời, lắp đặt',
      'badge': 'MỚI',
      'icon': Icons.build_rounded,
      'iconColor': Color(0xFF0D9488),
      'price': 'Từ 200.000đ',
      'description':
          'Kỹ thuật viên chuyên nghiệp hỗ trợ tháo dỡ, di dời và lắp đặt máy lạnh dân dụng.',
    },
  ];

  final List<Map<String, dynamic>> _rewards = [
    {
      'title': 'Voucher giảm 50K',
      'subtitle': 'Áp dụng cho đơn từ 150K',
      'points': '200',
      'icon': Icons.confirmation_number_rounded,
      'color': Color(0xFFFF8228),
    },
    {
      'title': 'Giặt sấy giảm 30%',
      'subtitle': 'Giao nhận tận nơi',
      'points': '150',
      'icon': Icons.local_laundry_service_rounded,
      'color': Color(0xFF0EA5E9),
    },
    {
      'title': 'Bình nước Neatify',
      'subtitle': 'Quà tặng tri ân khách hàng',
      'points': '500',
      'icon': Icons.card_giftcard_rounded,
      'color': Color(0xFF1BB55C),
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
      color: AppColors.brand500,
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
                          const Icon(Icons.chevron_right_rounded,
                              color: Colors.white, size: 22),
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
                        builder: (_) => const CustomerNotificationScreen()),
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

  // Dải "điểm thưởng" nằm đè lên header như bTaskee (bPoints)
  Widget _buildRewardStrip() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.brandLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.stars_rounded,
                color: AppColors.brand500, size: 22),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '0 điểm thưởng',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Tích điểm mỗi đơn để đổi quà',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 30, color: AppColors.divider),
          const SizedBox(width: 12),
          InkWell(
            onTap: _openLogin,
            child: const Row(
              children: [
                Icon(Icons.workspace_premium_rounded,
                    color: Color(0xFFB0B0B0), size: 20),
                SizedBox(width: 4),
                Text(
                  'Thành viên',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
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
            itemCount: _bTaskeeServices.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.78,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, index) =>
                _buildGridServiceItem(_bTaskeeServices[index]),
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
    final Color c = item['iconColor'] as Color? ?? AppColors.brand500;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ServiceDetailScreen(service: item)),
        );
      },
      child: Column(
        children: [
          const SizedBox(height: 4),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(item['icon'] as IconData, color: c, size: 28),
              ),
              if (item['badge'] != null)
                Positioned(
                  top: -4,
                  right: -10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: item['badge'] == 'bCare'
                          ? AppColors.green500
                          : AppColors.error,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Text(
                      item['badge'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            item['title'] as String,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.25,
            ),
          ),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
              itemBuilder: (context, index) => _buildRewardCard(_rewards[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardCard(Map<String, dynamic> r) {
    final Color c = r['color'] as Color;
    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 72,
            width: double.infinity,
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.12),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Icon(r['icon'] as IconData, color: c, size: 34),
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
                    const Icon(Icons.stars_rounded,
                        color: AppColors.brand500, size: 16),
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
                    Icon(item['icon'] as IconData,
                        color: AppColors.green500, size: 28),
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
