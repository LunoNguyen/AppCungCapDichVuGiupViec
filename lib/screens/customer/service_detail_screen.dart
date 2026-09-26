import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../widgets/shared_widgets.dart';

class ServiceDetailScreen extends StatefulWidget {
  final Map<String, dynamic> service;

  const ServiceDetailScreen({super.key, required this.service});

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  int _selectedPlan = 0;

  final List<Map<String, dynamic>> _plans = [
    {'label': 'Theo buổi', 'price': '150.000đ/h', 'desc': '2–4 giờ'},
    {'label': 'Gói 8 buổi', 'price': '1.100.000đ', 'desc': 'Tiết kiệm 8%'},
    {'label': 'Gói tháng', 'price': '3.800.000đ', 'desc': 'Tiết kiệm 15%'},
  ];

  final List<Map<String, dynamic>> _reviews = [
    {
      'name': 'Chị Hương',
      'rating': 5.0,
      'comment': 'Cộng tác viên rất chuyên nghiệp và tận tâm. Nhà sạch bóng sau khi làm!',
      'date': '20/09/2026',
    },
    {
      'name': 'Anh Minh',
      'rating': 4.5,
      'comment': 'Dịch vụ tốt, đúng giờ. Sẽ đặt lại lần sau.',
      'date': '18/09/2026',
    },
    {
      'name': 'Chị Phương',
      'rating': 4.8,
      'comment': 'Giá cả hợp lý, chất lượng tốt. Rất hài lòng!',
      'date': '15/09/2026',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final s = widget.service;
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: s['color'] as Color,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      (s['color'] as Color).withOpacity(0.85),
                      s['color'] as Color,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Icon(
                    s['icon'] as IconData,
                    size: 90,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(s),
                _buildPlans(),
                _buildDetails(),
                _buildReviews(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(s),
    );
  }

  Widget _buildHeader(Map<String, dynamic> s) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s['title'] as String,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              StarRating(rating: (s['rating'] as double)),
              const SizedBox(width: 8),
              Text(
                '${s['rating']} (${s['reviews']} đánh giá)',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _infoChip(Icons.access_time, s['subtitle'] as String),
              const SizedBox(width: 8),
              _infoChip(Icons.attach_money, s['price'] as String),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.brand300.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.brand600),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.brand600),
          ),
        ],
      ),
    );
  }

  Widget _buildPlans() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      color: AppColors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chọn gói dịch vụ',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(_plans.length, (i) {
              final p = _plans[i];
              final selected = i == _selectedPlan;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedPlan = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(right: i < _plans.length - 1 ? 8 : 0),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.brand500
                          : AppColors.scaffoldBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? AppColors.brand500
                            : AppColors.divider,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          p['label'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? AppColors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          p['price'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: selected ? AppColors.white : AppColors.brand600,
                          ),
                        ),
                        Text(
                          p['desc'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            color: selected
                                ? Colors.white70
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDetails() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      color: AppColors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mô tả dịch vụ',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Dịch vụ dọn dẹp nhà chuyên nghiệp với đội ngũ cộng tác viên được đào tạo bài bản. Chúng tôi cam kết mang đến không gian sống sạch sẽ, thoáng mát và an toàn cho gia đình bạn.\n\n'
            'Dịch vụ bao gồm: lau chùi sàn nhà, vệ sinh phòng tắm, sắp xếp đồ đạc, lau kính cửa và các bề mặt nội thất.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Lưu ý',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          _noteItem('Vui lòng đặt trước ít nhất 2 giờ'),
          _noteItem('Cung cấp dụng cụ vệ sinh cơ bản'),
          _noteItem('Giá có thể thay đổi theo diện tích'),
        ],
      ),
    );
  }

  Widget _noteItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: AppColors.brand500),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviews() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      color: AppColors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Đánh giá từ khách hàng',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              const Icon(Icons.star, color: AppColors.star, size: 16),
              const SizedBox(width: 4),
              const Text(
                '4.8 • 234 đánh giá',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ..._reviews.map((r) => _reviewCard(r)),
        ],
      ),
    );
  }

  Widget _reviewCard(Map<String, dynamic> r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.scaffoldBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.brand300.withOpacity(0.3),
                child: Text(
                  (r['name'] as String).substring(0, 1),
                  style: const TextStyle(
                    color: AppColors.brand600,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  r['name'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              StarRating(rating: r['rating'] as double, size: 14),
              const SizedBox(width: 8),
              Text(
                r['date'] as String,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            r['comment'] as String,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(Map<String, dynamic> s) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      decoration: const BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tổng tiền',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              Text(
                _plans[_selectedPlan]['price'] as String,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.brand600,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _showLoginPrompt(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brand500,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Đặt dịch vụ ngay',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLoginPrompt() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Icon(Icons.lock_outline, size: 48, color: AppColors.brand500),
            const SizedBox(height: 12),
            const Text(
              'Đăng nhập để đặt dịch vụ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bạn cần có tài khoản để sử dụng chức năng này.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đăng nhập'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brand500,
                  side: const BorderSide(color: AppColors.brand500),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Đăng ký tài khoản'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
