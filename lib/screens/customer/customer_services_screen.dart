import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../services/catalog_ui.dart';
import '../../services/service_catalog_api_service.dart';
import 'service_detail_screen.dart';

/// Tìm dịch vụ (GET /v1/services) theo nhiều tiêu chí: từ khoá (không dấu cũng được), nhóm dịch vụ,
/// hình thức (theo lần / gói tháng), khoảng giá, sắp xếp theo giá. Không cần đăng nhập để xem.
class CustomerServicesScreen extends StatefulWidget {
  final ValueChanged<int>? onSwitchTab;
  final int? loaiDichVuId; // mở sẵn theo một loại (từ lưới dịch vụ ở trang chủ)
  final String? tenLoai;
  final bool autofocus; // mở từ thanh tìm kiếm ở trang chủ: bàn phím bật sẵn
  final String? loaiHinhDat; // mở sẵn theo hình thức (TheoLan | GoiThang)
  final int? giaDen; // mở sẵn theo khoảng giá (đến bao nhiêu)
  final String? tuKhoa;

  const CustomerServicesScreen({
    super.key,
    this.onSwitchTab,
    this.loaiDichVuId,
    this.tenLoai,
    this.autofocus = false,
    this.loaiHinhDat,
    this.giaDen,
    this.tuKhoa,
  });

  @override
  State<CustomerServicesScreen> createState() => _CustomerServicesScreenState();
}

class _CustomerServicesScreenState extends State<CustomerServicesScreen> {
  final ServiceCatalogApiService _api = ServiceCatalogApiService();
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  List<Map<String, dynamic>> _types = [];
  List<Map<String, dynamic>> _services = [];
  int? _loaiId;
  bool _loading = true;
  String? _error;

  // Bộ lọc thêm
  String? _loaiHinh; // null = tất cả
  int _khoangGia = 0; // chỉ số trong _khoangGias
  String _sapXep = 'phu-hop';

  static const _khoangGias = <(String, double?, double?)>[
    ('Mọi mức giá', null, null),
    ('Dưới 300.000đ', null, 300000),
    ('300.000đ – 700.000đ', 300000, 700000),
    ('700.000đ – 2.000.000đ', 700000, 2000000),
    ('Trên 2.000.000đ', 2000000, null),
  ];

  int get _soLocDangBat =>
      (_khoangGia != 0 ? 1 : 0) + (_sapXep != 'phu-hop' ? 1 : 0);

  @override
  void initState() {
    super.initState();
    _loaiId = widget.loaiDichVuId;
    _loaiHinh = widget.loaiHinhDat;
    if (widget.tuKhoa != null) _searchCtrl.text = widget.tuKhoa!;
    if (widget.giaDen != null) {
      final i = _khoangGias.indexWhere((k) => k.$3 == widget.giaDen);
      if (i > 0) _khoangGia = i;
    }
    _loadTypes();
    _loadServices();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTypes() async {
    try {
      final res = await _api.getServiceTypes();
      if (!mounted || !res.success) return;
      setState(() {
        _types = (res.data ?? [])
            .where((t) => t['trangThai'] == null || t['trangThai'] == 'HienThi')
            .map(CatalogUi.fromServiceType)
            .toList();
      });
    } catch (_) {}
  }

  Future<void> _loadServices() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.getServices(
        loaiDichVuId: _loaiId,
        tuKhoa: _searchCtrl.text.trim(),
        loaiHinhDat: _loaiHinh,
        minPrice: _khoangGias[_khoangGia].$2,
        maxPrice: _khoangGias[_khoangGia].$3,
      );
      if (!mounted) return;
      setState(() {
        if (res.success) {
          _services = (res.data ?? []).map(CatalogUi.fromService).toList();
          if (_sapXep == 'gia-tang') {
            _services.sort((a, b) => (a['donGia'] as num).compareTo(b['donGia'] as num));
          } else if (_sapXep == 'gia-giam') {
            _services.sort((a, b) => (b['donGia'] as num).compareTo(a['donGia'] as num));
          }
        } else {
          _error = res.message ?? 'Không tải được danh sách dịch vụ';
        }
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Lỗi kết nối máy chủ');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _loadServices);
  }

  void _chonLoai(int? id) {
    if (_loaiId == id) return;
    setState(() => _loaiId = id);
    _loadServices();
  }

  String get _tieuDe {
    if (_loaiId == null) return 'Tất cả dịch vụ';
    final t = _types.where((e) => e['id'] == _loaiId);
    return t.isNotEmpty ? t.first['title'] as String : (widget.tenLoai ?? 'Dịch vụ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: Text(_tieuDe),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              autofocus: widget.autofocus,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _loadServices(),
              decoration: InputDecoration(
                hintText: 'Bạn cần gì? Ví dụ: dọn nhà, máy lạnh, sofa',
                prefixIcon: const Icon(Icons.search_rounded),
                isDense: true,
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          _loadServices();
                        },
                      ),
              ),
            ),
          ),
          if (_types.isNotEmpty)
            Container(
              color: Colors.white,
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                children: [
                  _chip('Tất cả', _loaiId == null, () => _chonLoai(null)),
                  for (final t in _types)
                    _chip(t['title'] as String, _loaiId == t['id'],
                        () => _chonLoai(t['id'] as int)),
                ],
              ),
            ),
          // Hàng lọc: hình thức + nút bộ lọc (giá, sắp xếp) + số kết quả
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      _chip('Mọi hình thức', _loaiHinh == null, () => _chonLoaiHinh(null)),
                      _chip('Theo lần', _loaiHinh == 'TheoLan', () => _chonLoaiHinh('TheoLan')),
                      _chip('Gói tháng', _loaiHinh == 'GoiThang', () => _chonLoaiHinh('GoiThang')),
                    ]),
                  ),
                ),
                TextButton.icon(
                  onPressed: _moBoLoc,
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: Text(_soLocDangBat > 0 ? 'Lọc ($_soLocDangBat)' : 'Lọc'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (!_loading && _error == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('${_services.length} dịch vụ',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              ),
            ),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  void _chonLoaiHinh(String? loai) {
    if (_loaiHinh == loai) return;
    setState(() => _loaiHinh = loai);
    _loadServices();
  }

  /// Bảng lọc: khoảng giá và sắp xếp.
  Future<void> _moBoLoc() async {
    int gia = _khoangGia;
    String sapXep = _sapXep;
    final apDung = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Khoảng giá', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (int i = 0; i < _khoangGias.length; i++)
                    _chip(_khoangGias[i].$1, gia == i, () => setSheet(() => gia = i)),
                ]),
                const SizedBox(height: 16),
                const Text('Sắp xếp', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _chip('Phù hợp nhất', sapXep == 'phu-hop', () => setSheet(() => sapXep = 'phu-hop')),
                  _chip('Giá thấp đến cao', sapXep == 'gia-tang', () => setSheet(() => sapXep = 'gia-tang')),
                  _chip('Giá cao đến thấp', sapXep == 'gia-giam', () => setSheet(() => sapXep = 'gia-giam')),
                ]),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setSheet(() {
                        gia = 0;
                        sapXep = 'phu-hop';
                      }),
                      child: const Text('Đặt lại'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Áp dụng'),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
    if (apDung == true && mounted) {
      setState(() {
        _khoangGia = gia;
        _sapXep = sapXep;
      });
      _loadServices();
    }
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.brandLight,
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? AppColors.brand700 : AppColors.textPrimary,
        ),
        side: BorderSide(
            color: selected ? AppColors.brand500 : AppColors.divider),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildList() {
    if (_loading && _services.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.brand500));
    }
    if (_error != null && _services.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: AppColors.textSecondary)),
            TextButton(onPressed: _loadServices, child: const Text('Thử lại')),
          ],
        ),
      );
    }
    if (_services.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off_rounded, size: 40, color: AppColors.textMuted),
              const SizedBox(height: 8),
              const Text('Không có dịch vụ khớp',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              const Text('Thử từ khoá ngắn hơn hoặc bỏ bớt bộ lọc.',
                  textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
              TextButton(
                onPressed: () {
                  _searchCtrl.clear();
                  setState(() {
                    _loaiId = null;
                    _loaiHinh = null;
                    _khoangGia = 0;
                    _sapXep = 'phu-hop';
                  });
                  _loadServices();
                },
                child: const Text('Xoá bộ lọc'),
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.brand500,
      onRefresh: _loadServices,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: _services.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 84),
        itemBuilder: (context, i) => _buildServiceRow(context, _services[i]),
      ),
    );
  }

  Widget _buildServiceRow(BuildContext context, Map<String, dynamic> item) {
    final Color c = item['iconColor'] as Color;
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ServiceDetailScreen(service: item),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(item['icon'] as IconData, color: c, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'] as String,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item['subtitle'] as String,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['price'] as String,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brand600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
