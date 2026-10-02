import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import 'service_detail_screen.dart';
import 'customer_services_screen.dart';
import 'customer_notification_screen.dart';
import '../auth/login_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  final ValueChanged<int>? onSwitchTab;
  const CustomerHomeScreen({super.key, this.onSwitchTab});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _currentBannerIndex = 0;
  final PageController _pageController = PageController();

  final List<Map<String, dynamic>> _promoBanners = [
    {
      'title': 'Connect to pay • Giảm 50.000đ',
      'subtitle': 'Thanh toán thẻ Sacombank hoặc VNPAY',
      'badge': 'ƯU ĐÃI ĐỘC QUYỀN',
      'code': 'NEATIFY50',
      'colors': [Color(0xFF0F4C5C), Color(0xFF197A8D)],
      'icon': Icons.credit_card_rounded,
    },
    {
      'title': 'Thảnh thơi đón Tết • Dọn dẹp nhà',
      'subtitle': 'Đặt trước 7 ngày nhận ưu đãi giảm 20%',
      'badge': 'HOT DEAL',
      'code': 'XUANMOI20',
      'colors': [Color(0xFFE36414), Color(0xFFFB8B24)],
      'icon': Icons.cleaning_services_rounded,
    },
    {
      'title': 'Gói định kỳ tháng • Tiết kiệm 30%',
      'subtitle': 'Cộng tác viên cố định, linh hoạt đổi lịch',
      'badge': 'TIẾT KIỆM',
      'code': 'TIETKIEM30',
      'colors': [Color(0xFF2E7D32), Color(0xFF4CAF50)],
      'icon': Icons.calendar_month_rounded,
    },
  ];

  // Grid services following bTaskee 4-column layout
  final List<Map<String, dynamic>> _bTaskeeServices = [
    {
      'title': 'Tháo - lắp máy lạnh',
      'badge': 'NEW',
      'badgeColor': Color(0xFFE53935),
      'icon': Icons.build_circle_outlined,
      'color': Color(0xFFFFECEB),
      'iconColor': Color(0xFFE53935),
      'price': 'Từ 200.000đ',
      'description':
          'Kỹ thuật viên chuyên nghiệp hỗ trợ tháo dỡ, di dời và lắp đặt máy lạnh dân dụng, công nghiệp.',
    },
    {
      'title': 'Dọn văn phòng',
      'badge': 'NEW',
      'badgeColor': Color(0xFFE53935),
      'icon': Icons.apartment_rounded,
      'color': Color(0xFFFFECEB),
      'iconColor': Color(0xFFE53935),
      'price': 'Từ 80.000đ/giờ',
      'description':
          'Dọn dẹp môi trường làm việc văn phòng, phòng họp, lau kính và khử khuẩn máy tính thiết bị.',
    },
    {
      'title': 'Làm đẹp tại nhà',
      'badge': 'NEW',
      'badgeColor': Color(0xFFE53935),
      'icon': Icons.face_retouching_natural_rounded,
      'color': Color(0xFFFFECEB),
      'iconColor': Color(0xFFE53935),
      'price': 'Theo gói',
      'description':
          'Dịch vụ chăm sóc sắc đẹp, gội đầu dưỡng sinh, massage thư giãn tại gia.',
    },
    {
      'title': 'Chăm sóc cao tuổi',
      'badge': 'bCare',
      'badgeColor': Color(0xFFE53935),
      'icon': Icons.elderly_rounded,
      'color': Color(0xFFFFF0EB),
      'iconColor': Color(0xFFE36414),
      'price': 'Từ 120.000đ/giờ',
      'description':
          'Hỗ trợ sinh hoạt hàng ngày, trò chuyện tâm sự, nhắc uống thuốc và theo dõi sức khỏe cơ bản.',
    },
    {
      'title': 'Dọn dẹp nhà\nca lẻ',
      'highlight': 'ca lẻ',
      'icon': Icons.cleaning_services_rounded,
      'color': Color(0xFFFFF4EB),
      'iconColor': Color(0xFFE36414),
      'price': 'Chỉ từ 60.000đ/giờ',
      'description':
          'Dọn dẹp nhà theo giờ linh hoạt 2–4 tiếng. Phù hợp nhu cầu phát sinh đột xuất.',
    },
    {
      'title': 'Dọn dẹp nhà\ngói tháng',
      'highlight': 'gói tháng',
      'icon': Icons.event_repeat_rounded,
      'color': Color(0xFFFFF4EB),
      'iconColor': Color(0xFFE36414),
      'price': 'Từ 1.200.000đ/tháng',
      'description':
          'Đặt lịch định kỳ 2-5 buổi/tuần. Giữ người làm cố định, an tâm tuyệt đối.',
    },
    {
      'title': 'Tổng vệ sinh',
      'icon': Icons.home_work_rounded,
      'color': Color(0xFFFFF4EB),
      'iconColor': Color(0xFFE36414),
      'price': 'Từ 500.000đ/nhà',
      'description':
          'Vệ sinh chuyên sâu toàn diện sau xây dựng, chuẩn bị tân gia hoặc dọn dẹp cuối năm.',
    },
    {
      'title': 'Vệ sinh máy lạnh',
      'icon': Icons.ac_unit_rounded,
      'color': Color(0xFFFFF4EB),
      'iconColor': Color(0xFFE36414),
      'price': 'Từ 150.000đ/máy',
      'description':
          'Rửa lưới lọc, xịt dàn nóng lạnh, nạp ga và khử khuẩn chống nấm mốc.',
    },
    {
      'title': 'Dịch vụ\nchuyển nhà',
      'icon': Icons.local_shipping_rounded,
      'color': Color(0xFFFFF4EB),
      'iconColor': Color(0xFFE36414),
      'price': 'Báo giá khảo sát',
      'description':
          'Trọn gói đóng gói đồ đạc, bốc xếp và xe tải vận chuyển tận nhà mới an toàn.',
    },
    {
      'title': 'Vệ sinh công nghiệp',
      'icon': Icons.factory_rounded,
      'color': Color(0xFFFFF4EB),
      'iconColor': Color(0xFFE36414),
      'price': 'Báo giá dự án',
      'description':
          'Vệ sinh nhà xưởng, tòa nhà, showroom, trường học với máy móc công suất lớn.',
    },
    {
      'title': 'Vệ sinh Sofa - Rèm cửa',
      'icon': Icons.weekend_rounded,
      'color': Color(0xFFFFF4EB),
      'iconColor': Color(0xFFE36414),
      'price': 'Từ 350.000đ/bộ',
      'description':
          'Công nghệ giặt hơi nước nóng diệt khuẩn nệm, ghế sofa và giặt rèm cửa tận nhà.',
    },
    {
      'title': 'Trông Trẻ',
      'badge': 'bCare',
      'badgeColor': Color(0xFFE53935),
      'icon': Icons.child_care_rounded,
      'color': Color(0xFFFFECEB),
      'iconColor': Color(0xFFE53935),
      'price': 'Từ 80.000đ/giờ',
      'description':
          'Cộng tác viên giữ trẻ yêu trẻ, có nghiệp vụ chăm sóc dinh dưỡng và vui chơi an toàn.',
    },
  ];

  final List<Map<String, dynamic>> _rewards = [
    {
      'title': 'Thẻ quà tặng VNPAY 50K',
      'subtitle': 'Áp dụng cho mọi dịch vụ trên 150K',
      'points': 'Đổi 200 điểm',
      'color': Color(0xFF0F4C5C),
    },
    {
      'title': 'Voucher Giặt sấy 30%',
      'subtitle': 'Giặt đồ gia đình giao nhận tận nơi',
      'points': 'Đổi 150 điểm',
      'color': Color(0xFF197A8D),
    },
    {
      'title': 'Bình nước thể thao Neatify',
      'subtitle': 'Quà tặng thương hiệu tri ân khách hàng',
      'points': 'Đổi 500 điểm',
      'color': Color(0xFFE36414),
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header (bTaskee layout with our Teal Palette & Unauthenticated State)
            _buildTopHeader(),

            const SizedBox(height: 16),

            // Promotional Carousel Banner
            _buildPromoCarousel(),

            const SizedBox(height: 20),

            // Services Grid Section (bTaskee 4-column layout)
            _buildServicesSection(),

            const SizedBox(height: 22),

            // Neatify Rewards Section (bRewards style)
            _buildRewardsSection(),

            const SizedBox(height: 20),

            // Trust & Commitment Badges
            _buildTrustBadges(),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.brand700, AppColors.brand500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting Row with Support / Chat & Notification Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Xin chào',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Row(
                    children: [
                      // Chat / Support icon button
                      InkWell(
                        onTap: () {
                          _showSupportBottomSheet();
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Notification icon button
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const CustomerNotificationScreen(),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.notifications_none_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Unauthenticated Capsule Button: [ Đăng nhập / Tạo tài khoản ]
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Đăng nhập / Tạo tài khoản',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.brand500,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: AppColors.brand500,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromoCarousel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        children: [
          SizedBox(
            height: 140,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _promoBanners.length,
              onPageChanged: (index) {
                setState(() {
                  _currentBannerIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final banner = _promoBanners[index];
                final colors = banner['colors'] as List<Color>;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: colors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: colors.first.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                banner['badge'] as String,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              banner['title'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              banner['subtitle'] as String,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          banner['icon'] as IconData,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // Carousel Dot Indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _promoBanners.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _currentBannerIndex == index ? 20 : 6,
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

  Widget _buildServicesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title Row: "Dịch vụ" and "Xem tất cả"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Dịch vụ',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              InkWell(
                onTap: () {
                  if (widget.onSwitchTab != null) {
                    widget.onSwitchTab!(1); // Switch to Tab 2: Dịch vụ
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CustomerServicesScreen(),
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        'Xem tất cả',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brand500,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: AppColors.brand500,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 4-Column Grid (bTaskee layout)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _bTaskeeServices.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.72,
              crossAxisSpacing: 10,
              mainAxisSpacing: 14,
            ),
            itemBuilder: (context, index) {
              final s = _bTaskeeServices[index];
              return _buildGridServiceItem(s);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGridServiceItem(Map<String, dynamic> item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ServiceDetailScreen(service: item),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon container with optional top badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: item['color'] as Color? ?? AppColors.brandLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.cardBorder,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    item['icon'] as IconData,
                    color: item['iconColor'] as Color? ?? AppColors.brand500,
                    size: 28,
                  ),
                ),
                // Badge: "NEW", "bCare", etc.
                if (item['badge'] != null)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: item['badgeColor'] as Color? ??
                            const Color(0xFFE53935),
                        borderRadius: BorderRadius.circular(8),
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

            // Service Title
            Text(
              item['title'] as String,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text(
                    'Ưu đãi Neatify',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.brand500,
                    size: 20,
                  ),
                ],
              ),
              Text(
                'Tích điểm đổi quà',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18),
            itemCount: _rewards.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final r = _rewards[index];
              return Container(
                width: 240,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: (r['color'] as Color).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.card_giftcard_rounded,
                            size: 18,
                            color: r['color'] as Color,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            r['title'] as String,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      r['subtitle'] as String,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      r['points'] as String,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: r['color'] as Color,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTrustBadges() {
    final trustItems = [
      {
        'icon': Icons.security_rounded,
        'title': 'Bảo hiểm 10 triệu',
        'subtitle': 'An tâm tuyệt đối về tài sản',
      },
      {
        'icon': Icons.verified_user_rounded,
        'title': '100% Xác thực',
        'subtitle': 'Lý lịch nhân thân rõ ràng',
      },
      {
        'icon': Icons.thumb_up_alt_rounded,
        'title': 'Đổi người miễn phí',
        'subtitle': 'Nếu bạn chưa hài lòng',
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.brandSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.brandLight),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: trustItems.map((item) {
            return Expanded(
              child: Column(
                children: [
                  Icon(
                    item['icon'] as IconData,
                    color: AppColors.brand500,
                    size: 26,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['title'] as String,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item['subtitle'] as String,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showSupportBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Hỗ trợ khách hàng Neatify',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Đội ngũ chăm sóc khách hàng luôn sẵn sàng hỗ trợ bạn từ 8:00 - 21:00 hàng ngày.',
              style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppColors.brandLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.phone, color: AppColors.brand500),
              ),
              title: const Text('Tổng đài hỗ trợ'),
              subtitle: const Text('1900 xxxx (Miễn phí cước gọi)'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppColors.brandLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.email, color: AppColors.brand500),
              ),
              title: const Text('Email phản hồi'),
              subtitle: const Text('hotro@neatify.vn'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }
}
