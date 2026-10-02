import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import 'service_detail_screen.dart';

class CustomerServicesScreen extends StatelessWidget {
  final ValueChanged<int>? onSwitchTab;
  const CustomerServicesScreen({super.key, this.onSwitchTab});

  static final List<Map<String, dynamic>> popularServices = [
    {
      'id': 'hourly_cleaning',
      'title': 'Giúp việc định kỳ & Theo giờ',
      'subtitle': 'Dọn dẹp bụi bẩn phòng khách, phòng bếp, phòng ngủ',
      'price': 'Chỉ từ 60.000đ/giờ',
      'icon': Icons.auto_awesome,
      'iconBg': Color(0xFFE0F5F6),
      'iconColor': AppColors.brand500,
      'badge': 'HOT',
      'description':
          'Giải pháp hoàn hảo cho gia đình bận rộn. Cộng tác viên đã được đào tạo bài bản, lý lịch rõ ràng, tận tâm dọn dẹp.',
      'benefits': [
        'Bảo hiểm đổ vỡ tài sản lên tới 10 triệu đồng',
        'Cộng tác viên đã tiêm đủ vacxin, lý lịch sạch 100%',
        'Đổi người dọn miễn phí nếu không hài lòng',
      ],
      'pricing': [
        {'name': 'Ca 2 giờ dọn (nhà nhỏ)', 'price': '140.000đ'},
        {'name': 'Ca 3 giờ dọn (căn hộ 2PN)', 'price': '190.000đ'},
        {'name': 'Ca 4 giờ dọn (nhà phố / 3PN)', 'price': '240.000đ'},
      ],
    },
    {
      'id': 'ac_cleaning',
      'title': 'Vệ sinh Máy lạnh / Điều hoà',
      'subtitle': 'Rửa lưới lọc, nạp ga, khử khuẩn chuẩn kỹ thuật',
      'price': 'Từ 150.000đ/máy',
      'icon': Icons.ac_unit,
      'iconBg': Color(0xFFE4F7F2),
      'iconColor': Color(0xFF1EA884),
      'badge': 'NEW',
      'description':
          'Bảo dưỡng và vệ sinh máy lạnh gia đình, văn phòng. Kỹ thuật viên lành nghề, kiểm tra áp suất ga, khử mùi nấm mốc chuyên sâu.',
      'benefits': [
        'Bảo hành chảy nước 30 ngày sau khi vệ sinh',
        'Kiểm tra gas và dòng điện hoàn toàn miễn phí',
        'Sử dụng dung dịch tẩy rửa chuyên dụng an toàn',
      ],
      'pricing': [
        {'name': 'Máy lạnh treo tường (dưới 2HP)', 'price': '150.000đ/máy'},
        {'name': 'Máy lạnh treo tường (trên 2HP)', 'price': '200.000đ/máy'},
        {'name': 'Máy lạnh âm trần / tủ đứng', 'price': '350.000đ/máy'},
      ],
    },
    {
      'id': 'laundry_sofa',
      'title': 'Giặt ủi quần áo & Sofa',
      'subtitle': 'Giặt ủi sấy lấy ngay, giặt sofa hơi nước nóng',
      'price': 'Giá tính theo kg hoặc chiếc',
      'icon': Icons.local_laundry_service,
      'iconBg': Color(0xFFFFF4E6),
      'iconColor': Color(0xFFF59E0B),
      'description':
          'Công nghệ giặt sấy hiện đại, phân loại vải cẩn thận và giao nhận tận cửa. Vệ sinh ghế sofa, rèm cửa, nệm với công nghệ hơi nước nóng diệt khuẩn 99%.',
      'benefits': [
        'Giao nhận tận nơi trong vòng 24 giờ',
        'Diệt khuẩn khử mùi bằng công nghệ sinh học',
        'Đền bù 100% nếu có hư hao thất lạc đồ giặt',
      ],
      'pricing': [
        {'name': 'Giặt sấy quần áo thông thường', 'price': '25.000đ/kg'},
        {'name': 'Giặt hấp vest / áo dài', 'price': '80.000đ/bộ'},
        {'name': 'Vệ sinh Sofa vải nỉ / da (bộ 3)', 'price': '350.000đ/bộ'},
      ],
    },
    {
      'id': 'deep_cleaning',
      'title': 'Tổng vệ sinh nhà ở',
      'subtitle': 'Vệ sinh chuyên sâu sau xây dựng hoặc dọn nhà đón Tết',
      'price': 'Từ 500.000đ/nhà',
      'icon': Icons.cleaning_services,
      'iconBg': Color(0xFFEDE9FE),
      'iconColor': Color(0xFF7C3AED),
      'description':
          'Dịch vụ tổng vệ sinh chuyên nghiệp với máy chà sàn, máy hút bụi công nghiệp và đội ngũ từ 2-4 nhân sự lành nghề.',
      'benefits': [
        'Trang thiết bị máy móc hóa chất đạt chuẩn an toàn',
        'Nghiệm thu từng phòng trước khi bàn giao',
        'Hỗ trợ dọn dẹp phế thải và rác xây dựng nhẹ',
      ],
      'pricing': [
        {'name': 'Căn hộ chung cư dưới 70m²', 'price': '500.000đ/lần'},
        {'name': 'Căn hộ chung cư 70m² – 110m²', 'price': '800.000đ/lần'},
        {'name': 'Nhà phố / Biệt thự (khảo sát)', 'price': 'Từ 1.200.000đ'},
      ],
    },
    {
      'id': 'home_cooking',
      'title': 'Nấu ăn gia đình',
      'subtitle': 'Nấu ăn dinh dưỡng, hợp khẩu vị, vệ sinh an toàn',
      'price': 'Từ 180.000đ/buổi',
      'icon': Icons.restaurant,
      'iconBg': Color(0xFFFFECEB),
      'iconColor': Color(0xFFEF4444),
      'description':
          'Đầu bếp gia đình chuẩn bị bữa cơm ấm cúng theo đúng khẩu vị vùng miền. Hỗ trợ đi chợ chọn lựa thực phẩm tươi ngon, rõ nguồn gốc.',
      'benefits': [
        'Thực đơn phong phú thay đổi theo ngày',
        'Có chứng nhận khám sức khỏe định kỳ',
        'Dọn dẹp gian bếp sạch bóng sau khi nấu',
      ],
      'pricing': [
        {'name': 'Bữa cơm gia đình (2-3 món, 2-4 người)', 'price': '180.000đ/buổi'},
        {'name': 'Bữa cơm gia đình (4-5 món, 4-6 người)', 'price': '260.000đ/buổi'},
        {'name': 'Hỗ trợ đi chợ mua sắm thực phẩm', 'price': '+40.000đ/lần'},
      ],
    },
    {
      'id': 'child_care',
      'title': 'Trông trẻ & Chăm sóc bé',
      'subtitle': 'Cộng tác viên yêu trẻ, có chứng chỉ kỹ năng sư phạm',
      'price': 'Từ 80.000đ/giờ',
      'icon': Icons.child_care,
      'iconBg': Color(0xFFFDF2F8),
      'iconColor': Color(0xFFDB2777),
      'badge': 'Yêu thích',
      'description':
          'Người giữ trẻ có kinh nghiệm, tận tâm, được xác minh nhân thân kỹ càng. Chăm sóc bé ăn ngủ, cùng chơi và rèn luyện kỹ năng phát triển.',
      'benefits': [
        'Xác minh lý lịch tư pháp số 2 nghiêm ngặt',
        'Có chứng chỉ sơ cứu và kỹ năng chăm sóc trẻ',
        'Cập nhật tình hình bé liên tục cho phụ huynh',
      ],
      'pricing': [
        {'name': 'Trông trẻ theo giờ (ca 3-4 giờ)', 'price': '80.000đ/giờ'},
        {'name': 'Trông trẻ bán thời gian (ca 6-8 giờ)', 'price': '70.000đ/giờ'},
        {'name': 'Gói trông trẻ theo tháng (thứ 2 - thứ 6)', 'price': '6.500.000đ/tháng'},
      ],
    },
    {
      'id': 'elderly_care',
      'title': 'Chăm sóc người cao tuổi',
      'subtitle': 'Tận tâm chu đáo, đo huyết áp, nhắc thuốc đúng giờ',
      'price': 'Từ 120.000đ/giờ',
      'icon': Icons.elderly,
      'iconBg': Color(0xFFF0FDF4),
      'iconColor': Color(0xFF16A34A),
      'description':
          'Hỗ trợ sinh hoạt hàng ngày, trò chuyện tâm sự, theo dõi sức khỏe cơ bản và nhắc nhở uống thuốc đúng giờ cho ông bà cha mẹ.',
      'benefits': [
        'Điều dưỡng viên và hộ lý có kinh nghiệm chăm sóc',
        'Kiên nhẫn, thấu hiểu tâm lý người cao tuổi',
        'Hỗ trợ dìu đi dạo và tập vật lý trị liệu cơ bản',
      ],
      'pricing': [
        {'name': 'Chăm sóc theo ca (ca 4 giờ)', 'price': '120.000đ/giờ'},
        {'name': 'Chăm sóc tại bệnh viện / tại nhà cả ngày', 'price': '650.000đ/ngày'},
        {'name': 'Gói chăm sóc định kỳ theo tháng', 'price': 'Liên hệ'},
      ],
    },
    {
      'id': 'home_moving',
      'title': 'Dịch vụ chuyển nhà & Văn phòng',
      'subtitle': 'Đóng gói, khuân vác, xe tải vận chuyển chuyên nghiệp',
      'price': 'Báo giá theo khảo sát',
      'icon': Icons.local_shipping,
      'iconBg': Color(0xFFEFF6FF),
      'iconColor': Color(0xFF2563EB),
      'description':
          'Giải pháp dọn nhà trọn gói tiết kiệm thời gian và công sức. Đội ngũ bốc xếp cẩn thận, bao bọc màng PE chống xước cho đồ gỗ và đồ điện tử.',
      'benefits': [
        'Cung cấp miễn phí thùng carton và băng keo',
        'Cam kết đền bù 100% giá trị đồ vật nếu xảy ra rơi vỡ',
        'Hỗ trợ tháo lắp giường tủ và thiết bị điện lạnh',
      ],
      'pricing': [
        {'name': 'Xe tải chuyển đồ 1 tấn (dưới 10km)', 'price': '450.000đ/chuyến'},
        {'name': 'Nhân công bốc vác, khuân vác đồ', 'price': '150.000đ/người/h'},
        {'name': 'Trọn gói chuyển nhà chung cư 2PN', 'price': 'Khảo sát'},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Screen Header (Matching Image 2)
              const Text(
                'Tất cả dịch vụ',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 18),

              // Category section tag
              const Text(
                'DỊCH VỤ PHỔ THÔNG',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),

              // Services List matching layout in Image 2
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: popularServices.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = popularServices[index];
                  return _buildServiceCard(context, item);
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, Map<String, dynamic> item) {
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
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.cardBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon Box with rounded background
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: item['iconBg'] as Color,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  item['icon'] as IconData,
                  color: item['iconColor'] as Color,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),

              // Text info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item['title'] as String,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              height: 1.25,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item['badge'] != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: item['badge'] == 'HOT'
                                  ? const Color(0xFFEF4444)
                                  : (item['badge'] == 'NEW'
                                      ? AppColors.brand500
                                      : const Color(0xFFDB2777)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item['badge'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['subtitle'] as String,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item['price'] as String,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brand500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
