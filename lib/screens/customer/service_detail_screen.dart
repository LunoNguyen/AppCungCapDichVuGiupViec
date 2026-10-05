import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../services/catalog_ui.dart';
import '../../services/service_catalog_api_service.dart';
import '../../services/session_service.dart';
import 'booking_screen.dart';
import '../auth/login_screen.dart';

/// Chi tiết dịch vụ lấy từ API: GET /v1/services/{id}
/// (bảng giá đang áp dụng, đánh giá, số lượt đặt, thông số dịch vụ).
class ServiceDetailScreen extends StatefulWidget {
  /// Dịch vụ đã có ở màn trước (map từ CatalogUi.fromService), cần có 'dichVuId'.
  final Map<String, dynamic> service;

  const ServiceDetailScreen({super.key, required this.service});

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  final ServiceCatalogApiService _api = ServiceCatalogApiService();
  late Map<String, dynamic> _service = widget.service;
  bool _loading = true;
  String? _error;

  int get _dichVuId => CatalogUi.toInt(_service['dichVuId'] ?? _service['id']);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_dichVuId == 0) {
      setState(() {
        _loading = false;
        _error = 'Dịch vụ không hợp lệ';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.getServiceDetail(_dichVuId);
      if (!mounted) return;
      setState(() {
        if (res.success && res.data != null) {
          // Giữ icon/màu của màn trước, cập nhật dữ liệu mới nhất từ API
          _service = {
            ...widget.service,
            ...CatalogUi.fromService(res.data!),
            'iconColor': widget.service['iconColor'] ??
                CatalogUi.colorFor(CatalogUi.toInt(res.data!['loaiDichVuId'])),
          };
        } else {
          _error = res.message ?? 'Không tải được chi tiết dịch vụ';
        }
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Lỗi kết nối máy chủ');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _bangGias =>
      ((_service['bangGias'] as List?) ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

  List<Map<String, dynamic>> get _danhGias =>
      ((_service['danhGias'] as List?) ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

  @override
  Widget build(BuildContext context) {
    final title = (_service['title'] as String? ?? 'Dịch vụ').replaceAll('\n', ' ');
    final desc = _service['description'] as String? ?? '';
    final Color accent = _service['iconColor'] as Color? ?? AppColors.brand500;
    final soDanhGia = CatalogUi.toInt(_service['soLuongDanhGia']);
    final soLuotDat = CatalogUi.toInt(_service['soLuotDat']);
    final diem = num.tryParse(_service['diemDanhGiaTrungBinh']?.toString() ?? '');

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.brand500,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            // Ảnh minh hoạ dịch vụ
            Container(
              height: 150,
              color: accent.withValues(alpha: 0.10),
              child: Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _service['icon'] as IconData? ?? Icons.cleaning_services_rounded,
                    size: 44,
                    color: accent,
                  ),
                ),
              ),
            ),

            // Tên + giá + mô tả + đánh giá
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (_service['price'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _service['price'] as String,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brand500,
                      ),
                    ),
                  ],
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      desc,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],
                  if (!_loading && _error == null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: AppColors.star, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          soDanhGia > 0 && diem != null
                              ? diem.toStringAsFixed(1)
                              : 'Chưa có đánh giá',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            [
                              if (soDanhGia > 0) '$soDanhGia đánh giá',
                              '$soLuotDat lượt đặt',
                            ].join(' • '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),

            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                    child: CircularProgressIndicator(color: AppColors.brand500)),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(_error!,
                        style: const TextStyle(color: AppColors.textSecondary)),
                    TextButton(onPressed: _load, child: const Text('Thử lại')),
                  ],
                ),
              )
            else ...[
              _section('Thông tin dịch vụ', _buildThongTin()),
              const SizedBox(height: 10),
              _section('Bảng giá', _buildBangGia()),
              if (_danhGias.isNotEmpty) ...[
                const SizedBox(height: 10),
                _section('Đánh giá của khách hàng', _buildDanhGia()),
              ],
            ],
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
            16, 10, 16, 10 + MediaQuery.of(context).padding.bottom),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _loading || _error != null ? null : _handleBooking,
            child: const Text('Đặt dịch vụ'),
          ),
        ),
      ),
    );
  }

  Widget _buildThongTin() {
    final phut = CatalogUi.toInt(_service['thoiGianThucHienPhut']);
    final soNguoi = CatalogUi.toInt(_service['soNguoiThucHien']);
    final soBuoi = CatalogUi.toInt(_service['soBuoi']);
    final rows = <List<dynamic>>[
      [Icons.category_outlined, 'Loại dịch vụ', _service['tenLoaiDichVu'] ?? '—'],
      [Icons.event_note_outlined, 'Hình thức', CatalogUi.loaiHinhLabel(_service['loaiHinhDat']?.toString())],
      if (phut > 0)
        [Icons.timer_outlined, 'Thời gian', phut % 60 == 0 ? '${phut ~/ 60} giờ' : '$phut phút'],
      if (soNguoi > 0) [Icons.groups_outlined, 'Số người làm', '$soNguoi người'],
      if (soBuoi > 0) [Icons.repeat_rounded, 'Số buổi', '$soBuoi buổi'],
      if ((_service['donViTinh']?.toString() ?? '').isNotEmpty)
        [Icons.straighten_rounded, 'Đơn vị tính', _service['donViTinh']],
    ];
    return Column(
      children: rows
          .map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(r[0] as IconData, size: 20, color: AppColors.brand500),
                    const SizedBox(width: 10),
                    Text(r[1] as String,
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.textSecondary)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        r[2].toString(),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _buildBangGia() {
    final list = _bangGias;
    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          _service['price'] as String? ?? 'Liên hệ để được báo giá',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return Column(
      children: [
        for (int i = 0; i < list.length; i++) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    [
                      CatalogUi.loaiHinhLabel(list[i]['loaiHinhDat']?.toString()),
                      list[i]['khuVuc'] ?? 'Toàn quốc',
                    ].join(' • '),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${CatalogUi.money(list[i]['donGia'])}'
                  '${(list[i]['donViTinh']?.toString() ?? '').isNotEmpty ? '/${list[i]['donViTinh'].toString().toLowerCase()}' : ''}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.brand600,
                  ),
                ),
              ],
            ),
          ),
          if (i < list.length - 1) const Divider(height: 1),
        ],
      ],
    );
  }

  Widget _buildDanhGia() {
    return Column(
      children: _danhGias.take(3).map((d) {
        final diem = num.tryParse(d['diem']?.toString() ?? '') ?? 0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      d['khachHang']?.toString() ?? 'Khách hàng',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                    ),
                  ),
                  const Icon(Icons.star_rounded,
                      color: AppColors.star, size: 16),
                  const SizedBox(width: 2),
                  Text(diem.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
              if ((d['nhanXet']?.toString() ?? '').isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  d['nhanXet'].toString(),
                  style: const TextStyle(
                      fontSize: 13.5, color: AppColors.textSecondary, height: 1.4),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _section(String title, Widget child) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  /// Đã đăng nhập khách hàng: vào thẳng màn đặt lịch; chưa đăng nhập: mời đăng nhập
  /// (đặt đơn cần tài khoản để lưu địa chỉ và theo dõi đơn).
  Future<void> _handleBooking() async {
    final session = await SessionService.load();
    if (!mounted) return;
    if (session != null && session.isCustomer) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BookingScreen(service: _service)),
      );
      return;
    }
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
            const SizedBox(height: 18),
            const Text(
              'Đăng nhập để đặt lịch',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bạn cần đăng nhập tài khoản khách hàng để chọn địa chỉ, đặt lịch và theo dõi đơn.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: const Text('Đăng nhập'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
