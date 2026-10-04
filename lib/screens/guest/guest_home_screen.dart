import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../widgets/shared_widgets.dart';
import '../customer/service_detail_screen.dart';

class GuestHomeScreen extends StatefulWidget {
  const GuestHomeScreen({super.key});

  @override
  State<GuestHomeScreen> createState() => _GuestHomeScreenState();
}

class _GuestHomeScreenState extends State<GuestHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Tất cả';

  final List<String> _categories = [
    'Tất cả',
    'Theo giờ',
    'Theo gói',
    'Nhà cửa',
    'Văn phòng',
  ];

  final List<Map<String, dynamic>> _services = [
    {
      'title': 'Dọn dẹp nhà cơ bản',
      'subtitle': 'Theo giờ • 2–4 giờ',
      'price': 'Từ 150.000đ/h',
      'icon': Icons.cleaning_services,
      'color': AppColors.brand500,
      'rating': 4.8,
      'reviews': 234,
    },
    {
      'title': 'Dọn dẹp tổng thể',
      'subtitle': 'Theo buổi • Toàn bộ nhà',
      'price': 'Từ 500.000đ',
      'icon': Icons.home_work,
      'color': AppColors.brand600,
      'rating': 4.9,
      'reviews': 187,
    },
    {
      'title': 'Giặt ủi quần áo',
      'subtitle': 'Theo kg • Giao nhận tận nơi',
      'price': 'Từ 30.000đ/kg',
      'icon': Icons.local_laundry_service,
      'color': Color(0xFF4CAF50),
      'rating': 4.7,
      'reviews': 156,
    },
    {
      'title': 'Nấu ăn tại nhà',
      'subtitle': 'Theo buổi • 3–5 món',
      'price': 'Từ 200.000đ/buổi',
      'icon': Icons.restaurant,
      'color': Color(0xFFFF5722),
      'rating': 4.6,
      'reviews': 98,
    },
    {
      'title': 'Trông trẻ',
      'subtitle': 'Theo giờ • Có kinh nghiệm',
      'price': 'Từ 80.000đ/h',
      'icon': Icons.child_care,
      'color': Color(0xFF9C27B0),
      'rating': 4.9,
      'reviews': 312,
    },
    {
      'title': 'Chăm sóc người cao tuổi',
      'subtitle': 'Theo ca • Tận tâm chu đáo',
      'price': 'Từ 120.000đ/h',
      'icon': Icons.elderly,
      'color': Color(0xFF795548),
      'rating': 4.8,
      'reviews': 143,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: _buildSearchBar(),
          ),
          SliverToBoxAdapter(
            child: _buildCategories(),
          ),
          SliverToBoxAdapter(
            child: _buildBanner(),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: SectionHeader(
                title: 'Dịch vụ nổi bật',
                actionLabel: 'Xem tất cả',
                onAction: () {},
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final s = _services[index];
                  return ServiceCard(
                    title: s['title'],
                    subtitle: s['subtitle'],
                    price: s['price'],
                    icon: s['icon'],
                    iconBg: s['color'],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ServiceDetailScreen(service: s),
                        ),
                      );
                    },
                  );
                },
                childCount: _services.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.78,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildTopCollaborators(),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      backgroundColor: AppColors.brand500,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: AppColors.brandGradient),
          padding: const EdgeInsets.fromLTRB(16, 55, 16, 12),
          child: Row(
            children: [
              Image.asset(
                'assets/images/Logo.png',
                height: 40,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.home_repair_service,
                  color: AppColors.white,
                  size: 36,
                ),
              ),
              const SizedBox(width: 10),
              const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GiupViec.vn',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Dịch vụ giúp việc tin cậy',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: AppColors.white),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Tìm kiếm dịch vụ...',
          hintStyle: const TextStyle(color: AppColors.textSecondary),
          prefixIcon:
              const Icon(Icons.search, color: AppColors.brand500),
          suffixIcon: IconButton(
            icon: const Icon(Icons.tune, color: AppColors.brand500),
            onPressed: () {},
          ),
          filled: true,
          fillColor: AppColors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = cat == _selectedCategory;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.brand500 : AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.brand500 : AppColors.divider,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.brand500.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              child: Text(
                cat,
                style: TextStyle(
                  color: isSelected ? AppColors.white : AppColors.textSecondary,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      height: 130,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.brand600, AppColors.brand300],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand500.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 20,
            top: 10,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Đặt lịch ngay hôm nay!',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Giảm 20% cho lần đặt đầu tiên',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Đăng ký ngay',
                    style: TextStyle(
                      color: AppColors.brand600,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCollaborators() {
    final collaborators = [
      {'name': 'Nguyễn Thị Lan', 'job': 'Dọn dẹp nhà', 'rating': 4.9, 'jobs': 127},
      {'name': 'Trần Thị Mai', 'job': 'Nấu ăn', 'rating': 4.8, 'jobs': 94},
      {'name': 'Lê Thị Hoa', 'job': 'Trông trẻ', 'rating': 5.0, 'jobs': 58},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: SectionHeader(
            title: 'Cộng tác viên nổi bật',
            actionLabel: 'Xem thêm',
            onAction: () {},
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: collaborators.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final c = collaborators[index];
              return Container(
                width: 160,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.brand300.withOpacity(0.3),
                      child: Text(
                        (c['name'] as String).substring(0, 1),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brand600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      (c['name'] as String).split(' ').last,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      c['job'] as String,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, color: AppColors.star, size: 14),
                        const SizedBox(width: 2),
                        Text(
                          '${c['rating']}  •  ${c['jobs']} việc',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary),
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
    );
  }
}
