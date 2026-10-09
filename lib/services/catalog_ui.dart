import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import 'api_config.dart';

/// Chuyển dữ liệu danh mục từ API (/v1/services, /v1/service-types, /v1/promotions)
/// sang dữ liệu hiển thị: icon, màu, giá đã định dạng. Các màn khách hàng dùng chung.
class CatalogUi {
  CatalogUi._();

  static const List<Color> _palette = [
    AppColors.brand500,
    Color(0xFFFF8228),
    Color(0xFF7C3AED),
    Color(0xFF2F80ED),
    Color(0xFFEF4444),
    Color(0xFF0EA5E9),
    Color(0xFFD97706),
    Color(0xFF16A34A),
    Color(0xFFDB2777),
    Color(0xFF475569),
  ];

  /// Màu ổn định theo id (cùng loại dịch vụ luôn cùng màu).
  static Color colorFor(int seed) => _palette[seed.abs() % _palette.length];

  /// Icon theo từ khoá trong tên dịch vụ / loại dịch vụ.
  static IconData iconFor(String text) {
    final t = text.toLowerCase();
    bool has(List<String> keys) => keys.any(t.contains);
    if (has(['máy lạnh', 'điều hòa', 'điều hoà', 'điện máy'])) return Icons.ac_unit_rounded;
    if (has(['máy giặt', 'giặt', 'ủi', 'là '])) return Icons.local_laundry_service_rounded;
    if (has(['sofa', 'rèm', 'nệm', 'thảm'])) return Icons.weekend_rounded;
    if (has(['nấu', 'ăn', 'bếp'])) return Icons.restaurant_rounded;
    if (has(['người già', 'cao tuổi', 'người bệnh'])) return Icons.elderly_rounded;
    if (has(['trẻ', 'em bé'])) return Icons.child_care_rounded;
    if (has(['văn phòng', 'công ty'])) return Icons.apartment_rounded;
    if (has(['chuyển nhà', 'vận chuyển'])) return Icons.local_shipping_rounded;
    if (has(['kính', 'cửa sổ'])) return Icons.window_rounded;
    if (has(['khử khuẩn', 'diệt'])) return Icons.sanitizer_rounded;
    if (has(['tháng', 'định kỳ'])) return Icons.event_repeat_rounded;
    if (has(['tổng vệ sinh', 'tổng'])) return Icons.home_work_rounded;
    return Icons.cleaning_services_rounded;
  }

  static num _num(dynamic v) => num.tryParse(v?.toString() ?? '') ?? 0;

  static int toInt(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;

  /// 216000 -> "216.000đ"
  static String money(dynamic v) {
    final n = _num(v).round();
    final s = n.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return '$sđ';
  }

  static String loaiHinhLabel(String? loai) =>
      loai == 'GoiThang' ? 'Gói tháng' : 'Theo lần';

  /// URL ảnh MinIO (object key) qua backend: /files/{key}
  static String? fileUrl(String? key) {
    if (key == null || key.trim().isEmpty) return null;
    if (key.startsWith('http')) return key;
    final k = key.startsWith('/') ? key.substring(1) : key;
    return '${ApiConfig.baseUrl}/files/$k';
  }

  /// Dịch vụ từ /v1/services hoặc /v1/services/{id} -> map hiển thị.
  static Map<String, dynamic> fromService(Map<String, dynamic> j) {
    final ten = j['tenDichVu']?.toString() ?? 'Dịch vụ';
    final tenLoai = j['tenLoaiDichVu']?.toString() ?? '';
    final phut = toInt(j['thoiGianThucHienPhut']);
    dynamic gia = j['donGiaThamKhao'] ?? j['giaHienTai'];
    // Chi tiết dịch vụ: giaHienTai có thể = 0, khi đó lấy giá thấp nhất trong bảng giá
    final bangGias = j['bangGias'];
    if (_num(gia) <= 0 && bangGias is List && bangGias.isNotEmpty) {
      gia = bangGias
          .map((b) => _num((b as Map)['donGia']))
          .where((v) => v > 0)
          .fold<num>(0, (m, v) => m == 0 || v < m ? v : m);
    }
    final donVi = j['donViTinh']?.toString();
    final loaiId = toInt(j['loaiDichVuId']);
    return {
      ...j,
      'id': toInt(j['id']),
      'dichVuId': toInt(j['id']),
      'title': ten,
      'subtitle': [
        if (tenLoai.isNotEmpty) tenLoai,
        if (j['loaiHinhDat'] == 'GoiThang')
          'Gói tháng${j['soBuoiGoi'] != null ? ' ${j['soBuoiGoi']} buổi' : ''}',
        if (phut > 0) phut % 60 == 0 ? '${phut ~/ 60} giờ' : '$phut phút',
      ].join(' • '),
      'price': _num(gia) > 0
          ? 'Từ ${money(gia)}${donVi != null && donVi.isNotEmpty ? '/${donVi.toLowerCase()}' : ''}'
          : 'Liên hệ báo giá',
      'donGia': _num(gia),
      'description': j['moTaChiTiet']?.toString() ?? '',
      'icon': iconFor('$ten $tenLoai'),
      'iconColor': colorFor(loaiId),
    };
  }

  /// Loại dịch vụ từ /v1/service-types -> map hiển thị.
  static Map<String, dynamic> fromServiceType(Map<String, dynamic> j) {
    final ten = j['tenLoaiDichVu']?.toString() ?? 'Dịch vụ';
    final id = toInt(j['id']);
    return {
      ...j,
      'id': id,
      'title': ten,
      'description': j['moTa']?.toString() ?? '',
      'imageUrl': fileUrl(j['hinhAnh']?.toString()),
      'icon': iconFor(ten),
      'iconColor': colorFor(id),
    };
  }

  /// Khuyến mãi từ /v1/promotions -> nội dung banner.
  static Map<String, dynamic> fromPromotion(Map<String, dynamic> j, int index) {
    final phanTram = j['loaiGiam'] == 'PhanTram';
    final giaTri = _num(j['giaTriGiam']);
    final giam = phanTram ? 'Giảm ${giaTri.round()}%' : 'Giảm ${money(giaTri)}';
    final dk = _num(j['dieuKienToiThieu']);
    final toiDa = _num(j['soTienGiamToiDa']);
    const gradients = [
      [AppColors.brand700, AppColors.brand400],
      [Color(0xFFFF8228), Color(0xFFFFA25E)],
      [Color(0xFF2F80ED), Color(0xFF5A9CF2)],
    ];
    return {
      ...j,
      'title': j['tenChuongTrinh']?.toString() ?? giam,
      'badge': giam.toUpperCase(),
      'subtitle': [
        if (dk > 0) 'Đơn từ ${money(dk)}',
        if (phanTram && toiDa > 0) 'tối đa ${money(toiDa)}',
      ].join(', '),
      'code': j['codeKhuyenMai']?.toString() ?? '',
      'colors': gradients[index % gradients.length],
      'icon': phanTram ? Icons.percent_rounded : Icons.local_offer_rounded,
    };
  }
}
