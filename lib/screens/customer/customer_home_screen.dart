import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../widgets/shared_widgets.dart';
import 'booking_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  String _selectedCategory = 'Tất cả';

  final List<String> _categories = [
    'Tất cả', 'Theo giờ', 'Theo gói', 'Nhà cửa', 'Văn phòng',
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
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildSearch()),
          SliverToBoxAdapter(child: _buildQuickStats()),
          SliverToBoxAdapter(child: _buildCategories()),
          SliverToBoxAdapter(child: _buildPromoBanner()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: SectionHeader(
                title: 'Dịch vụ phổ biến',
                actionLabel: 'Tất cả',
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
                          builder: (_) => BookingScreen(service: s),
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
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 130,
      floating: true,
      pinned: true,
      backgroundColor: AppColors.brand500,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.brand700, AppColors.brand500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 52, 16, 12),
          child: Row(
            children: [
              Image.asset(
                'assets/images/Logo.png',
                height: 38,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.home_repair_service,
                  color: AppColors.white,
                  size: 34,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Xin chào, Nguyễn Thị A! 👋',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Hôm nay bạn cần dịch vụ gì?',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined,
                        color: AppColors.white),
                    onPressed: () {},
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Tìm kiếm dịch vụ...',
          hintStyle: const TextStyle(color: AppColors.textSecondary),
          prefixIcon: const Icon(Icons.search, color: AppColors.brand500),
          suffixIcon: const Icon(Icons.tune, color: AppColors.brand500),
          filled: true,
          fillColor: AppColors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

  Widget _buildQuickStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _statCard('3', 'Đơn đang dùng', Icons.pending_actions, AppColors.brand500),
          const SizedBox(width: 10),
          _statCard('12', 'Tổng đơn', Icons.receipt_long, AppColors.brand600),
          const SizedBox(width: 10),
          _statCard('20%', 'Ưu đãi', Icons.local_offer, Color(0xFFFF5722)),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
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
        itemBuilder: (context, i) {
          final cat = _categories[i];
          final selected = cat == _selectedCategory;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? AppColors.brand500 : AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? AppColors.brand500 : AppColors.divider,
                ),
                boxShadow: selected
                    ? [BoxShadow(color: AppColors.brand500.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
                    : [],
              ),
              child: Text(
                cat,
                style: TextStyle(
                  color: selected ? AppColors.white : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      height: 120,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.brand700, AppColors.brand300],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand500.withOpacity(0.3),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -15,
            top: -15,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '🎉 Gói tháng ưu đãi!',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Đặt gói 8 buổi – Giảm ngay 15%',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Text(
                          'Đặt ngay',
                          style: TextStyle(
                            color: AppColors.brand600,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.local_offer_outlined,
                  color: Colors.white38,
                  size: 60,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
