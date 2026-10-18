import '../../widgets/gia_hien_thi.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_colors.dart';
import '../../services/catalog_ui.dart';
import '../../services/service_catalog_api_service.dart';
import 'service_detail_screen.dart';

/// Tìm dịch vụ (GET /v1/services) theo nhiều tiêu chí mở rộng:
/// - Từ khoá (khớp tên dịch vụ, nội dung mô tả chi tiết, mức giá 216k/216.000, thời lượng, số buổi...)
/// - Nhóm dịch vụ, Hình thức đặt (Theo lần / Gói tháng)
/// - Khoảng giá linh hoạt với 2 Textbox (Giá tối thiểu, Giá tối đa) đồng bộ 2 chiều với 1 Thanh trượt (RangeSlider)
/// - Thời lượng mỗi buổi, Đang có ưu đãi giảm giá, Sắp xếp đa tiêu chí.
class CustomerServicesScreen extends StatefulWidget {
  final ValueChanged<int>? onSwitchTab;
  final int? loaiDichVuId; // mở sẵn theo một loại (từ lưới dịch vụ ở trang chủ)
  final String? tenLoai;
  final bool autofocus; // mở từ thanh tìm kiếm ở trang chủ: bàn phím bật sẵn
  final String? loaiHinhDat; // mở sẵn theo hình thức (TheoLan | GoiThang)
  final int? giaTu; // mở sẵn theo giá tối thiểu
  final int? giaDen; // mở sẵn theo giá tối đa
  final String? tuKhoa;

  const CustomerServicesScreen({
    super.key,
    this.onSwitchTab,
    this.loaiDichVuId,
    this.tenLoai,
    this.autofocus = false,
    this.loaiHinhDat,
    this.giaTu,
    this.giaDen,
    this.tuKhoa,
  });

  @override
  State<CustomerServicesScreen> createState() => _CustomerServicesScreenState();
}

class _CustomerServicesScreenState extends State<CustomerServicesScreen> {
  static const double _kMaxSliderPrice = 10000000; // 10.000.000đ
  static const double _kStepPrice = 50000; // bước nhảy 50.000đ

  final ServiceCatalogApiService _api = ServiceCatalogApiService();
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  List<Map<String, dynamic>> _types = [];
  List<Map<String, dynamic>> _services = [];
  int? _loaiId;
  bool _loading = true;
  String? _error;

  // Các tiêu chí lọc linh hoạt
  String? _loaiHinh; // null = tất cả, 'TheoLan', 'GoiThang'
  double? _minPrice; // Giá tối thiểu (null = không giới hạn dưới)
  double? _maxPrice; // Giá tối đa (null = không giới hạn trên)
  String? _thoiLuong; // null | 'duoi-2h' | '2h-3h' | 'tren-3h'
  bool _chiGiamGia = false; // chỉ hiện dịch vụ đang có ưu đãi giảm giá
  String _sapXep = 'phu-hop'; // phu-hop | gia-tang | gia-giam | ten-az | thoi-luong-tang

  static const _goiYGia = <(String, double?, double?)>[
    ('Mọi mức giá', null, null),
    ('Dưới 300k', null, 300000),
    ('300k – 700k', 300000, 700000),
    ('700k – 2tr', 700000, 2000000),
    ('Trên 2tr', 2000000, null),
  ];

  bool get _coLocGia => (_minPrice != null && _minPrice! > 0) || _maxPrice != null;

  int get _soLocDangBat =>
      (_coLocGia ? 1 : 0) +
      (_thoiLuong != null ? 1 : 0) +
      (_chiGiamGia ? 1 : 0) +
      (_sapXep != 'phu-hop' ? 1 : 0);

  @override
  void initState() {
    super.initState();
    _loaiId = widget.loaiDichVuId;
    _loaiHinh = widget.loaiHinhDat;
    if (widget.tuKhoa != null) _searchCtrl.text = widget.tuKhoa!;
    if (widget.giaTu != null && widget.giaTu! > 0) {
      _minPrice = widget.giaTu!.toDouble();
    }
    if (widget.giaDen != null && widget.giaDen! > 0) {
      _maxPrice = widget.giaDen!.toDouble();
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

  static String _formatNumberVN(num? value) {
    if (value == null || value <= 0) return '';
    final n = value.round();
    return n.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }

  static double? _parseNumberVN(String text) {
    final digits = text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return null;
    final val = double.tryParse(digits);
    return (val != null && val > 0) ? val : null;
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
      double? minP = (_minPrice != null && _minPrice! > 0) ? _minPrice : null;
      double? maxP = (_maxPrice != null && _maxPrice! > 0) ? _maxPrice : null;
      if (minP != null && maxP != null && minP > maxP) {
        final tmp = minP;
        minP = maxP;
        maxP = tmp;
      }

      final res = await _api.getServices(
        loaiDichVuId: _loaiId,
        tuKhoa: _searchCtrl.text.trim(),
        loaiHinhDat: _loaiHinh,
        minPrice: minP,
        maxPrice: maxP,
      );
      if (!mounted) return;
      setState(() {
        if (res.success) {
          var list = (res.data ?? []).map(CatalogUi.fromService).toList();

          // Lọc theo thời lượng thực hiện
          if (_thoiLuong != null) {
            list = list.where((m) {
              final phut = CatalogUi.toInt(m['thoiGianThucHienPhut']);
              if (phut <= 0) return false;
              switch (_thoiLuong) {
                case 'duoi-2h':
                  return phut <= 120;
                case '2h-3h':
                  return phut > 120 && phut <= 180;
                case 'tren-3h':
                  return phut > 180;
                default:
                  return true;
              }
            }).toList();
          }

          // Lọc chỉ lấy dịch vụ đang có ưu đãi giảm giá
          if (_chiGiamGia) {
            list = list.where((m) => m['priceGoc'] != null).toList();
          }

          // Sắp xếp linh hoạt
          switch (_sapXep) {
            case 'gia-tang':
              list.sort((a, b) => (a['donGia'] as num).compareTo(b['donGia'] as num));
              break;
            case 'gia-giam':
              list.sort((a, b) => (b['donGia'] as num).compareTo(a['donGia'] as num));
              break;
            case 'ten-az':
              list.sort((a, b) => (a['title'] as String)
                  .toLowerCase()
                  .compareTo((b['title'] as String).toLowerCase()));
              break;
            case 'thoi-luong-tang':
              list.sort((a, b) {
                final pa = CatalogUi.toInt(a['thoiGianThucHienPhut']);
                final pb = CatalogUi.toInt(b['thoiGianThucHienPhut']);
                if (pa <= 0 && pb <= 0) return 0;
                if (pa <= 0) return 1;
                if (pb <= 0) return -1;
                return pa.compareTo(pb);
              });
              break;
          }

          _services = list;
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
    setState(() {}); // cập nhật nút xoá trên thanh tìm kiếm
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _loadServices);
  }

  void _chonLoai(int? id) {
    if (_loaiId == id) return;
    setState(() => _loaiId = id);
    _loadServices();
  }

  String get _tieuDe {
    if (_loaiId == null) return 'Tìm & Lọc dịch vụ';
    final t = _types.where((e) => e['id'] == _loaiId);
    return t.isNotEmpty ? t.first['title'] as String : (widget.tenLoai ?? 'Dịch vụ');
  }

  String get _nhanKhoangGia {
    if (_minPrice != null && _minPrice! > 0 && _maxPrice != null) {
      return 'Giá: ${CatalogUi.money(_minPrice)} – ${CatalogUi.money(_maxPrice)}';
    }
    if (_minPrice != null && _minPrice! > 0) {
      return 'Giá từ ${CatalogUi.money(_minPrice)}';
    }
    if (_maxPrice != null) {
      return 'Giá đến ${CatalogUi.money(_maxPrice)}';
    }
    return '';
  }

  String get _nhanThoiLuong {
    switch (_thoiLuong) {
      case 'duoi-2h':
        return 'Thời lượng: ≤ 2 giờ';
      case '2h-3h':
        return 'Thời lượng: 2 – 3 giờ';
      case 'tren-3h':
        return 'Thời lượng: > 3 giờ';
      default:
        return '';
    }
  }

  String get _nhanSapXep {
    switch (_sapXep) {
      case 'gia-tang':
        return 'Giá thấp → cao';
      case 'gia-giam':
        return 'Giá cao → thấp';
      case 'ten-az':
        return 'Tên A → Z';
      case 'thoi-luong-tang':
        return 'Thời lượng ngắn → dài';
      default:
        return '';
    }
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
                hintText: 'Tìm theo tên, mô tả, giá tiền (vd: 216k, 55m², sofa)...',
                prefixIcon: const Icon(Icons.search_rounded),
                isDense: true,
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {});
                          _loadServices();
                        },
                      ),
              ),
            ),
          ),
          // Hàng lọc ngang gọn gàng bằng ComboBox (Nhóm dịch vụ + Hình thức + Nút Bộ lọc nâng cao)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
            child: Row(
              children: [
                // ComboBox 1: Nhóm dịch vụ
                Expanded(
                  flex: 5,
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: _loaiId != null ? AppColors.brandLight : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _loaiId != null ? AppColors.brand500 : AppColors.divider,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int?>(
                        value: _types.any((t) => t['id'] == _loaiId) ? _loaiId : null,
                        isExpanded: true,
                        isDense: true,
                        menuWidth: 280,
                        menuMaxHeight: 380,
                        borderRadius: BorderRadius.circular(12),
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: _loaiId != null ? AppColors.brand700 : AppColors.textSecondary,
                        ),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: _loaiId != null ? FontWeight.w700 : FontWeight.w600,
                          color: _loaiId != null ? AppColors.brand700 : AppColors.textPrimary,
                        ),
                        selectedItemBuilder: (context) {
                          return [
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Tất cả nhóm',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            for (final t in _types)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  t['title']?.toString() ?? '',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                          ];
                        },
                        items: [
                          DropdownMenuItem<int?>(
                            value: null,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.apps_rounded,
                                    size: 18,
                                    color: _loaiId == null ? AppColors.brand500 : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Tất cả nhóm dịch vụ',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: _loaiId == null ? FontWeight.w700 : FontWeight.w500,
                                        color: _loaiId == null ? AppColors.brand700 : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  if (_loaiId == null)
                                    const Icon(Icons.check_rounded, size: 18, color: AppColors.brand500),
                                ],
                              ),
                            ),
                          ),
                          for (final t in _types)
                            DropdownMenuItem<int?>(
                              value: t['id'] as int,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  children: [
                                    Icon(
                                      CatalogUi.iconFor(t['title']?.toString() ?? ''),
                                      size: 18,
                                      color: _loaiId == t['id'] ? AppColors.brand500 : AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        t['title']?.toString() ?? '',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: _loaiId == t['id'] ? FontWeight.w700 : FontWeight.w500,
                                          color: _loaiId == t['id'] ? AppColors.brand700 : AppColors.textPrimary,
                                        ),
                                        softWrap: true,
                                        maxLines: 2,
                                      ),
                                    ),
                                    if (_loaiId == t['id'])
                                      const Icon(Icons.check_rounded, size: 18, color: AppColors.brand500),
                                  ],
                                ),
                              ),
                            ),
                        ],
                        onChanged: (val) => _chonLoai(val),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // ComboBox 2: Hình thức đặt (Theo lần / Gói tháng)
                Expanded(
                  flex: 4,
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: _loaiHinh != null ? AppColors.brandLight : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _loaiHinh != null ? AppColors.brand500 : AppColors.divider,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: _loaiHinh,
                        isExpanded: true,
                        isDense: true,
                        menuWidth: 190,
                        borderRadius: BorderRadius.circular(12),
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: _loaiHinh != null ? AppColors.brand700 : AppColors.textSecondary,
                        ),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: _loaiHinh != null ? FontWeight.w700 : FontWeight.w600,
                          color: _loaiHinh != null ? AppColors.brand700 : AppColors.textPrimary,
                        ),
                        selectedItemBuilder: (context) {
                          return const [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Mọi hình thức', overflow: TextOverflow.ellipsis, maxLines: 1),
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Theo lần', overflow: TextOverflow.ellipsis, maxLines: 1),
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Gói tháng', overflow: TextOverflow.ellipsis, maxLines: 1),
                            ),
                          ];
                        },
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Text('Mọi hình thức', style: TextStyle(fontSize: 13)),
                                ),
                                if (_loaiHinh == null)
                                  const Icon(Icons.check_rounded, size: 18, color: AppColors.brand500),
                              ],
                            ),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'TheoLan',
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Text('Đặt theo lần', style: TextStyle(fontSize: 13)),
                                ),
                                if (_loaiHinh == 'TheoLan')
                                  const Icon(Icons.check_rounded, size: 18, color: AppColors.brand500),
                              ],
                            ),
                          ),
                          DropdownMenuItem<String?>(
                            value: 'GoiThang',
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Text('Định kỳ gói tháng', style: TextStyle(fontSize: 13)),
                                ),
                                if (_loaiHinh == 'GoiThang')
                                  const Icon(Icons.check_rounded, size: 18, color: AppColors.brand500),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (val) => _chonLoaiHinh(val),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Nút mở Bộ lọc nâng cao
                SizedBox(
                  height: 38,
                  child: TextButton.icon(
                    onPressed: _moBoLoc,
                    style: TextButton.styleFrom(
                      backgroundColor: _soLocDangBat > 0 ? AppColors.brandLight : const Color(0xFFF8FAFC),
                      foregroundColor: _soLocDangBat > 0 ? AppColors.brand700 : AppColors.textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: _soLocDangBat > 0 ? AppColors.brand500 : AppColors.divider,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    icon: const Icon(Icons.tune_rounded, size: 17),
                    label: Text(
                      _soLocDangBat > 0 ? 'Lọc ($_soLocDangBat)' : 'Bộ lọc',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Hàng hiển thị các tag bộ lọc đang áp dụng (Active Filter Chips) để tắt lẻ từng tiêu chí
          if (_soLocDangBat > 0)
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (_coLocGia)
                      _activeFilterChip(_nhanKhoangGia, () {
                        setState(() {
                          _minPrice = null;
                          _maxPrice = null;
                        });
                        _loadServices();
                      }),
                    if (_thoiLuong != null)
                      _activeFilterChip(_nhanThoiLuong, () {
                        setState(() => _thoiLuong = null);
                        _loadServices();
                      }),
                    if (_chiGiamGia)
                      _activeFilterChip('Đang giảm giá', () {
                        setState(() => _chiGiamGia = false);
                        _loadServices();
                      }),
                    if (_sapXep != 'phu-hop')
                      _activeFilterChip(_nhanSapXep, () {
                        setState(() => _sapXep = 'phu-hop');
                        _loadServices();
                      }),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _minPrice = null;
                          _maxPrice = null;
                          _thoiLuong = null;
                          _chiGiamGia = false;
                          _sapXep = 'phu-hop';
                        });
                        _loadServices();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 30),
                      ),
                      child: const Text('Xoá lọc', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ),
          const Divider(height: 1),
          if (!_loading && _error == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('${_services.length} dịch vụ phù hợp',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              ),
            ),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _activeFilterChip(String label, VoidCallback onRemove) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InputChip(
        label: Text(label),
        onDeleted: onRemove,
        deleteIconColor: AppColors.brand700,
        backgroundColor: AppColors.brandLight,
        labelStyle: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: AppColors.brand700,
        ),
        side: const BorderSide(color: AppColors.brand500),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  void _chonLoaiHinh(String? loai) {
    if (_loaiHinh == loai) return;
    setState(() => _loaiHinh = loai);
    _loadServices();
  }

  /// Bảng lọc linh hoạt:
  /// - Lọc theo giá tiền bằng 2 Textbox (Giá tối thiểu, Giá tối đa) + 1 Thanh trượt giá (RangeSlider) đồng bộ 2 chiều
  /// - Lọc theo thời lượng mỗi buổi
  /// - Lọc dịch vụ đang giảm giá
  /// - Sắp xếp đa tiêu chí
  Future<void> _moBoLoc() async {
    double? tempMin = _minPrice;
    double? tempMax = _maxPrice;
    String? tempThoiLuong = _thoiLuong;
    bool tempGiamGia = _chiGiamGia;
    String tempSapXep = _sapXep;

    final minCtrl = TextEditingController(text: _formatNumberVN(tempMin));
    final maxCtrl = TextEditingController(text: _formatNumberVN(tempMax));

    RangeValues currentRangeValues() {
      final start = (tempMin ?? 0).clamp(0.0, _kMaxSliderPrice);
      final end = (tempMax ?? _kMaxSliderPrice).clamp(0.0, _kMaxSliderPrice);
      return start <= end ? RangeValues(start, end) : RangeValues(end, start);
    }

    final apDung = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final rangeVals = currentRangeValues();

          void applyPreset(double? mn, double? mx) {
            setSheet(() {
              tempMin = mn;
              tempMax = mx;
              minCtrl.text = _formatNumberVN(mn);
              maxCtrl.text = _formatNumberVN(mx);
            });
          }

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Bộ lọc tìm kiếm',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                        ),
                        TextButton(
                          onPressed: () {
                            setSheet(() {
                              tempMin = null;
                              tempMax = null;
                              tempThoiLuong = null;
                              tempGiamGia = false;
                              tempSapXep = 'phu-hop';
                              minCtrl.clear();
                              maxCtrl.clear();
                            });
                          },
                          child: const Text('Đặt lại tất cả'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // 1. PHẦN LỌC THEO GIÁ TIỀN: 2 TEXTBOX + 1 THANH TRƯỢT GIÁ TIỀN
                    const Text(
                      'Khoảng giá (VNĐ)',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: minCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(
                              labelText: 'Giá tối thiểu',
                              hintText: '0',
                              suffixText: 'đ',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (val) {
                              final parsed = _parseNumberVN(val);
                              final formatted = _formatNumberVN(parsed);
                              if (formatted != val) {
                                minCtrl.value = TextEditingValue(
                                  text: formatted,
                                  selection: TextSelection.collapsed(offset: formatted.length),
                                );
                              }
                              setSheet(() => tempMin = parsed);
                            },
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text('–', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                        ),
                        Expanded(
                          child: TextField(
                            controller: maxCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: const InputDecoration(
                              labelText: 'Giá tối đa',
                              hintText: '10.000.000',
                              suffixText: 'đ',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (val) {
                              final parsed = _parseNumberVN(val);
                              final formatted = _formatNumberVN(parsed);
                              if (formatted != val) {
                                maxCtrl.value = TextEditingValue(
                                  text: formatted,
                                  selection: TextSelection.collapsed(offset: formatted.length),
                                );
                              }
                              setSheet(() => tempMax = parsed);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Thanh trượt giá tiền 2 đầu kéo (RangeSlider)
                    SliderTheme(
                      data: SliderTheme.of(ctx).copyWith(
                        activeTrackColor: AppColors.brand500,
                        inactiveTrackColor: AppColors.divider,
                        thumbColor: AppColors.brand500,
                        overlayColor: AppColors.brand500.withValues(alpha: 0.15),
                        rangeValueIndicatorShape: const PaddleRangeSliderValueIndicatorShape(),
                      ),
                      child: RangeSlider(
                        values: rangeVals,
                        min: 0,
                        max: _kMaxSliderPrice,
                        divisions: (_kMaxSliderPrice ~/ _kStepPrice),
                        labels: RangeLabels(
                          CatalogUi.money(rangeVals.start),
                          rangeVals.end >= _kMaxSliderPrice
                              ? '10.000.000đ+'
                              : CatalogUi.money(rangeVals.end),
                        ),
                        onChanged: (RangeValues values) {
                          final newMin = (values.start / _kStepPrice).round() * _kStepPrice;
                          final newMax = (values.end / _kStepPrice).round() * _kStepPrice;
                          setSheet(() {
                            tempMin = newMin > 0 ? newMin : null;
                            tempMax = newMax < _kMaxSliderPrice ? newMax : null;
                            minCtrl.text = _formatNumberVN(tempMin);
                            maxCtrl.text = _formatNumberVN(tempMax);
                          });
                        },
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('0đ', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                          Text('5.000.000đ', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                          Text('10.000.000đ+', style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final g in _goiYGia)
                          _chip(
                            g.$1,
                            tempMin == g.$2 && tempMax == g.$3,
                            () => applyPreset(g.$2, g.$3),
                          ),
                      ],
                    ),

                    const SizedBox(height: 18),
                    // 2. THỜI LƯỢNG MỖI BUỔI & SẮP XẾP THEO (2 COMBOBOX NẰM NGANG CẠNH NHAU)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cột trái: ComboBox Thời lượng mỗi buổi
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Thời lượng mỗi buổi',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                height: 42,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: tempThoiLuong != null
                                      ? AppColors.brandLight
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: tempThoiLuong != null
                                        ? AppColors.brand500
                                        : AppColors.divider,
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String?>(
                                    value: tempThoiLuong,
                                    isExpanded: true,
                                    isDense: true,
                                    menuWidth: 200,
                                    borderRadius: BorderRadius.circular(12),
                                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: tempThoiLuong != null
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: tempThoiLuong != null
                                          ? AppColors.brand700
                                          : AppColors.textPrimary,
                                    ),
                                    selectedItemBuilder: (context) {
                                      return const [
                                        Align(alignment: Alignment.centerLeft, child: Text('Mọi thời lượng', overflow: TextOverflow.ellipsis, maxLines: 1)),
                                        Align(alignment: Alignment.centerLeft, child: Text('≤ 2 giờ', overflow: TextOverflow.ellipsis, maxLines: 1)),
                                        Align(alignment: Alignment.centerLeft, child: Text('2 – 3 giờ', overflow: TextOverflow.ellipsis, maxLines: 1)),
                                        Align(alignment: Alignment.centerLeft, child: Text('> 3 giờ', overflow: TextOverflow.ellipsis, maxLines: 1)),
                                      ];
                                    },
                                    items: [
                                      DropdownMenuItem<String?>(
                                        value: null,
                                        child: Row(
                                          children: [
                                            const Expanded(child: Text('Mọi thời lượng', style: TextStyle(fontSize: 13))),
                                            if (tempThoiLuong == null) const Icon(Icons.check_rounded, size: 18, color: AppColors.brand500),
                                          ],
                                        ),
                                      ),
                                      DropdownMenuItem<String?>(
                                        value: 'duoi-2h',
                                        child: Row(
                                          children: [
                                            const Expanded(child: Text('≤ 2 giờ (Nhanh gọn)', style: TextStyle(fontSize: 13))),
                                            if (tempThoiLuong == 'duoi-2h') const Icon(Icons.check_rounded, size: 18, color: AppColors.brand500),
                                          ],
                                        ),
                                      ),
                                      DropdownMenuItem<String?>(
                                        value: '2h-3h',
                                        child: Row(
                                          children: [
                                            const Expanded(child: Text('2 – 3 giờ (Phổ biến)', style: TextStyle(fontSize: 13))),
                                            if (tempThoiLuong == '2h-3h') const Icon(Icons.check_rounded, size: 18, color: AppColors.brand500),
                                          ],
                                        ),
                                      ),
                                      DropdownMenuItem<String?>(
                                        value: 'tren-3h',
                                        child: Row(
                                          children: [
                                            const Expanded(child: Text('> 3 giờ (Chuyên sâu)', style: TextStyle(fontSize: 13))),
                                            if (tempThoiLuong == 'tren-3h') const Icon(Icons.check_rounded, size: 18, color: AppColors.brand500),
                                          ],
                                        ),
                                      ),
                                    ],
                                    onChanged: (val) => setSheet(() => tempThoiLuong = val),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Cột phải: ComboBox Sắp xếp theo
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Sắp xếp theo',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                height: 42,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: tempSapXep != 'phu-hop'
                                      ? AppColors.brandLight
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: tempSapXep != 'phu-hop'
                                        ? AppColors.brand500
                                        : AppColors.divider,
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: tempSapXep,
                                    isExpanded: true,
                                    isDense: true,
                                    menuWidth: 230,
                                    borderRadius: BorderRadius.circular(12),
                                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: tempSapXep != 'phu-hop'
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: tempSapXep != 'phu-hop'
                                          ? AppColors.brand700
                                          : AppColors.textPrimary,
                                    ),
                                    selectedItemBuilder: (context) {
                                      return const [
                                        Align(alignment: Alignment.centerLeft, child: Text('Phù hợp nhất', overflow: TextOverflow.ellipsis, maxLines: 1)),
                                        Align(alignment: Alignment.centerLeft, child: Text('Giá thấp → cao', overflow: TextOverflow.ellipsis, maxLines: 1)),
                                        Align(alignment: Alignment.centerLeft, child: Text('Giá cao → thấp', overflow: TextOverflow.ellipsis, maxLines: 1)),
                                        Align(alignment: Alignment.centerLeft, child: Text('Tên A → Z', overflow: TextOverflow.ellipsis, maxLines: 1)),
                                        Align(alignment: Alignment.centerLeft, child: Text('Thời lượng ngắn → dài', overflow: TextOverflow.ellipsis, maxLines: 1)),
                                      ];
                                    },
                                    items: [
                                      DropdownMenuItem<String>(
                                        value: 'phu-hop',
                                        child: Row(
                                          children: [
                                            const Expanded(child: Text('Phù hợp nhất', style: TextStyle(fontSize: 13))),
                                            if (tempSapXep == 'phu-hop') const Icon(Icons.check_rounded, size: 18, color: AppColors.brand500),
                                          ],
                                        ),
                                      ),
                                      DropdownMenuItem<String>(
                                        value: 'gia-tang',
                                        child: Row(
                                          children: [
                                            const Expanded(child: Text('Giá thấp → cao', style: TextStyle(fontSize: 13))),
                                            if (tempSapXep == 'gia-tang') const Icon(Icons.check_rounded, size: 18, color: AppColors.brand500),
                                          ],
                                        ),
                                      ),
                                      DropdownMenuItem<String>(
                                        value: 'gia-giam',
                                        child: Row(
                                          children: [
                                            const Expanded(child: Text('Giá cao → thấp', style: TextStyle(fontSize: 13))),
                                            if (tempSapXep == 'gia-giam') const Icon(Icons.check_rounded, size: 18, color: AppColors.brand500),
                                          ],
                                        ),
                                      ),
                                      DropdownMenuItem<String>(
                                        value: 'ten-az',
                                        child: Row(
                                          children: [
                                            const Expanded(child: Text('Tên A → Z', style: TextStyle(fontSize: 13))),
                                            if (tempSapXep == 'ten-az') const Icon(Icons.check_rounded, size: 18, color: AppColors.brand500),
                                          ],
                                        ),
                                      ),
                                      DropdownMenuItem<String>(
                                        value: 'thoi-luong-tang',
                                        child: Row(
                                          children: [
                                            const Expanded(child: Text('Thời lượng ngắn → dài', style: TextStyle(fontSize: 13), softWrap: true)),
                                            if (tempSapXep == 'thoi-luong-tang') const Icon(Icons.check_rounded, size: 18, color: AppColors.brand500),
                                          ],
                                        ),
                                      ),
                                    ],
                                    onChanged: (val) {
                                      if (val != null) {
                                        setSheet(() => tempSapXep = val);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    // 3. ƯU ĐÃI GIẢM GIÁ
                    const Text(
                      'Ưu đãi',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                    ),
                    const SizedBox(height: 6),
                    FilterChip(
                      label: const Text('Đang có ưu đãi giảm giá'),
                      selected: tempGiamGia,
                      onSelected: (v) => setSheet(() => tempGiamGia = v),
                      selectedColor: AppColors.brandLight,
                      checkmarkColor: AppColors.brand700,
                      labelStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: tempGiamGia ? FontWeight.w700 : FontWeight.w500,
                        color: tempGiamGia ? AppColors.brand700 : AppColors.textPrimary,
                      ),
                      side: BorderSide(
                        color: tempGiamGia ? AppColors.brand500 : AppColors.divider,
                      ),
                    ),

                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Đóng'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Áp dụng bộ lọc'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    minCtrl.dispose();
    maxCtrl.dispose();

    if (apDung == true && mounted) {
      setState(() {
        _minPrice = tempMin;
        _maxPrice = tempMax;
        _thoiLuong = tempThoiLuong;
        _chiGiamGia = tempGiamGia;
        _sapXep = tempSapXep;
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, style: const TextStyle(color: AppColors.textSecondary)),
              TextButton(onPressed: _loadServices, child: const Text('Thử lại')),
            ],
          ),
        ),
      );
    }
    if (_services.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off_rounded, size: 36, color: AppColors.textMuted),
              const SizedBox(height: 6),
              const Text('Không có dịch vụ khớp',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              const Text(
                  'Thử từ khoá khác (tên, mô tả, mức giá như "216k", "55m²") hoặc điều chỉnh khoảng giá trên thanh trượt.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              TextButton(
                onPressed: () {
                  _searchCtrl.clear();
                  setState(() {
                    _loaiId = null;
                    _loaiHinh = null;
                    _minPrice = null;
                    _maxPrice = null;
                    _thoiLuong = null;
                    _chiGiamGia = false;
                    _sapXep = 'phu-hop';
                  });
                  _loadServices();
                },
                child: const Text('Xoá tất cả bộ lọc'),
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
    final String moTa = (item['moTaChiTiet']?.toString() ?? '').trim();
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (moTa.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        moTa,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          height: 1.35,
                        ),
                      ),
                    ],
                    const SizedBox(height: 5),
                    GiaHienThi(
                      gia: item['price'] as String,
                      giaGoc: item['priceGoc'] as String?,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brand600,
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 14),
                child: Icon(Icons.chevron_right_rounded,
                    color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
