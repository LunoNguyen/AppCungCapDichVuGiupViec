import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../services/address_api_service.dart';
import '../../services/booking_api_service.dart';
import '../../services/catalog_ui.dart';
import '../../services/service_catalog_api_service.dart';
import '../../services/session_service.dart';
import 'address_book_screen.dart';
import 'order_detail_screen.dart';

class BookingScreen extends StatefulWidget {
  final Map<String, dynamic> service;

  const BookingScreen({super.key, required this.service});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int _step = 0;
  int _selectedPlan = 0;
  int _selectedPayment = 0;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  // Địa chỉ làm việc chọn từ sổ địa chỉ của khách (mặc định: địa chỉ mặc định)
  UserSession? _session;
  DiaChi? _diaChi;
  bool _loadingAddress = true;
  final _noteController = TextEditingController();
  final _promoController = TextEditingController();
  final BookingApiService _bookingApi = BookingApiService();

  // Gói giá lấy từ bảng giá đang áp dụng của dịch vụ (GET /v1/services/{id})
  List<Map<String, dynamic>> _plans = [];
  bool _loadingPlans = true;
  String? _planError;

  // Giá do máy chủ tính (POST /v1/bookings/calculate-price), gồm cả khuyến mãi
  Map<String, dynamic>? _price;
  bool _calculating = false;
  String? _appliedCode; // mã đã được máy chủ chấp nhận
  bool _checkingPromo = false;
  bool _submitting = false;

  bool get _promoApplied => _appliedCode != null;

  static const _stepTitles = ['Chọn gói', 'Chọn thời gian', 'Xác nhận'];
  static const _weekDays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  final List<Map<String, dynamic>> _payments = [
    {'icon': Icons.payments_outlined, 'label': 'Tiền mặt', 'code': 'TIEN_MAT'},
    {'icon': Icons.qr_code_scanner_rounded, 'label': 'Chuyển khoản / QR', 'code': 'CHUYEN_KHOAN'},
  ];

  // Khung giờ bắt đầu 07:00 → 17:00
  final List<TimeOfDay> _timeSlots = List.generate(
      11, (i) => TimeOfDay(hour: 7 + i, minute: 0));

  late final List<DateTime> _dateOptions = List.generate(14, (i) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + i);
  });

  int get _dichVuId =>
      CatalogUi.toInt(widget.service['dichVuId'] ?? widget.service['id']);

  Map<String, dynamic>? get _plan =>
      _plans.isEmpty ? null : _plans[_selectedPlan.clamp(0, _plans.length - 1)];

  int _toMoney(dynamic v) => (num.tryParse(v?.toString() ?? '') ?? 0).round();

  /// Tạm tính / giảm / tổng: ưu tiên số máy chủ tính, chưa có thì lấy đơn giá của gói.
  int get _base => _price != null
      ? _toMoney(_price!['chiPhiGoc'] ?? _price!['tongTienGoc'] ?? _price!['donGia'] ?? _price!['price'])
      : _toMoney(_plan?['price']);

  int get _discount => _price != null
      ? _toMoney(_price!['soTienGiam'] ?? _price!['giaGiam'] ?? _price!['chietKhau'])
      : 0;

  int get _total => _price != null
      ? _toMoney(_price!['thanhTien'] ?? _price!['tongTien'] ?? _price!['tongTienThanhToan'])
      : (_base - _discount > 0 ? _base - _discount : _base);

  String _formatPrice(int p) =>
      '${p.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ';

  String _fmtDate(DateTime d) =>
      '${_weekDays[d.weekday - 1]}, ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String get _serviceTitle =>
      ((widget.service['title'] as String?) ?? 'Dịch vụ').replaceAll('\n', ' ');

  @override
  void initState() {
    super.initState();
    _selectedDate = _dateOptions.first;
    _selectedTime = _timeSlots.first;
    _loadDefaultAddress();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() {
      _loadingPlans = true;
      _planError = null;
    });
    try {
      List<dynamic>? bangGias = widget.service['bangGias'] as List<dynamic>?;
      Map<String, dynamic> dv = widget.service;
      if (bangGias == null || bangGias.isEmpty) {
        final res = await ServiceCatalogApiService().getServiceDetail(_dichVuId);
        if (res.success && res.data != null) {
          dv = res.data!;
          bangGias = dv['bangGias'] as List<dynamic>? ?? [];
        }
      }
      final plans = <Map<String, dynamic>>[
        for (final raw in (bangGias ?? []))
          () {
            final bg = Map<String, dynamic>.from(raw as Map);
            final donVi = bg['donViTinh']?.toString() ?? dv['donViTinh']?.toString() ?? '';
            final bgId = CatalogUi.toInt(bg['id'] ?? bg['bangGiaId']);
            return {
              'bangGiaId': bgId > 0 ? bgId : null,
              'loaiHinhDat': bg['loaiHinhDat']?.toString() ?? dv['loaiHinhDat']?.toString() ?? 'TheoLan',
              'label': CatalogUi.loaiHinhLabel(bg['loaiHinhDat']?.toString() ?? dv['loaiHinhDat']?.toString()),
              'desc': bg['khuVuc']?.toString() ?? 'Áp dụng toàn quốc',
              'price': bg['donGia'] ?? dv['giaHienTai'] ?? dv['donGia'],
              'display':
                  '${CatalogUi.money(bg['donGia'] ?? dv['giaHienTai'] ?? dv['donGia'])}${donVi.isNotEmpty ? '/${donVi.toLowerCase()}' : ''}',
            };
          }(),
      ];
      // Dịch vụ chưa có bảng giá: dùng giá hiện tại của dịch vụ
      if (plans.isEmpty) {
        final gia = dv['giaHienTai'] ?? dv['donGia'] ?? dv['donGiaThamKhao'];
        plans.add({
          'bangGiaId': null,
          'loaiHinhDat': dv['loaiHinhDat']?.toString() ?? 'TheoLan',
          'label': CatalogUi.loaiHinhLabel(dv['loaiHinhDat']?.toString()),
          'desc': 'Giá tham khảo',
          'price': gia,
          'display': CatalogUi.money(gia),
        });
      }
      if (!mounted) return;
      setState(() {
        _plans = plans;
        _selectedPlan = 0;
      });
      _recalc();
    } catch (e) {
      if (mounted) setState(() => _planError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loadingPlans = false);
    }
  }

  /// Máy chủ tính giá theo gói đã chọn và mã khuyến mãi đã áp dụng.
  Future<void> _recalc() async {
    final plan = _plan;
    if (plan == null) return;
    setState(() => _calculating = true);
    try {
      final res = await _bookingApi.calculatePrice(
        dichVuId: _dichVuId,
        bangGiaId: plan['bangGiaId'] as int?,
        loaiHinhDat: plan['loaiHinhDat'] as String,
        codeKhuyenMai: _appliedCode,
      );
      if (!mounted) return;
      setState(() => _price = res.success ? res.data : null);
    } catch (_) {
      if (mounted) setState(() => _price = null);
    } finally {
      if (mounted) setState(() => _calculating = false);
    }
  }

  void _selectPlan(int i) {
    if (i == _selectedPlan) return;
    setState(() => _selectedPlan = i);
    _recalc();
  }

  Future<void> _loadDefaultAddress() async {
    final session = await SessionService.load();
    DiaChi? macDinh;
    if (session != null && session.isCustomer) {
      try {
        final res = await AddressApiService().getAddresses(session.userId);
        final list = res.data ?? const <DiaChi>[];
        if (list.isNotEmpty) {
          macDinh = list.firstWhere((d) => d.laMacDinh, orElse: () => list.first);
        }
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _session = session;
      _diaChi = macDinh;
      _loadingAddress = false;
    });
  }

  Future<void> _pickAddress() async {
    if (_session == null || !_session!.isCustomer) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Vui lòng đăng nhập để chọn địa chỉ làm việc'),
        backgroundColor: AppColors.error,
      ));
      return;
    }
    final picked = await Navigator.push<DiaChi>(
      context,
      MaterialPageRoute(
        builder: (_) => AddressBookScreen(
          khachHangId: _session!.userId,
          selectMode: true,
          selectedId: _diaChi?.id,
        ),
      ),
    );
    if (picked != null && mounted) setState(() => _diaChi = picked);
  }

  @override
  void dispose() {
    _noteController.dispose();
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: Text(_stepTitles[_step]),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_step > 0) {
              setState(() => _step--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: LinearProgressIndicator(
            value: (_step + 1) / _stepTitles.length,
            minHeight: 3,
            backgroundColor: AppColors.divider,
            color: AppColors.brand500,
          ),
        ),
      ),
      body: IndexedStack(
        index: _step,
        children: [
          _buildStep1(),
          _buildStep2(),
          _buildStep3(),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ===================== BƯỚC 1: CHỌN GÓI =====================

  Widget _buildStep1() {
    final s = widget.service;
    final Color accent =
        s['iconColor'] as Color? ?? s['color'] as Color? ?? AppColors.brand500;

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(s['icon'] as IconData? ?? Icons.cleaning_services,
                    color: accent, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _serviceTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      (s['subtitle'] ?? s['price'] ?? '') as String,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _block(
          'Gói dịch vụ',
          _loadingPlans
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                      child: CircularProgressIndicator(color: AppColors.brand500)),
                )
              : _planError != null
                  ? Column(
                      children: [
                        Text(_planError!,
                            style: const TextStyle(color: AppColors.error)),
                        TextButton(
                            onPressed: _loadPlans, child: const Text('Thử lại')),
                      ],
                    )
                  : Column(
            children: List.generate(_plans.length, (i) {
              final p = _plans[i];
              final selected = i == _selectedPlan;
              return GestureDetector(
                onTap: () => _selectPlan(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.brandSurface : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? AppColors.brand500 : AppColors.divider,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p['label'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              p['desc'] as String,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        p['display'] as String,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: selected
                              ? AppColors.brand600
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color:
                            selected ? AppColors.brand500 : AppColors.textMuted,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 10),
        _block(
          'Mã khuyến mãi',
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _promoController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    hintText: 'Nhập mã khuyến mãi',
                    prefixIcon: Icon(Icons.local_offer_outlined,
                        color: AppColors.brand500),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 46,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onPressed: _checkingPromo ? null : _applyPromo,
                  child: _checkingPromo
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_promoApplied ? 'Bỏ mã' : 'Áp dụng'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Kiểm tra mã với máy chủ (POST /v1/promotions/validate) rồi tính lại giá.
  /// Bấm lại khi đã áp dụng = bỏ mã.
  Future<void> _applyPromo() async {
    if (_promoApplied) {
      setState(() => _appliedCode = null);
      _promoController.clear();
      _recalc();
      return;
    }
    final code = _promoController.text.trim();
    if (code.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _checkingPromo = true);
    try {
      final res = await _bookingApi.validatePromotion(
        codeKhuyenMai: code,
        tongTienDonHang: _base.toDouble(),
      );
      if (!mounted) return;
      if (res.success) {
        setState(() => _appliedCode = code);
        await _recalc();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.success
              ? 'Đã áp dụng mã ${res.data?['tenChuongTrinh'] ?? code}'
              : (res.message ?? 'Mã không hợp lệ hoặc đã hết hạn')),
          backgroundColor: res.success ? AppColors.success : AppColors.error,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Lỗi kết nối máy chủ'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _checkingPromo = false);
    }
  }

  // ===================== BƯỚC 2: THỜI GIAN & ĐỊA ĐIỂM =====================

  Widget _buildStep2() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        _block(
          'Ngày làm việc',
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _dateOptions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final d = _dateOptions[i];
                final selected = _selectedDate != null &&
                    _selectedDate!.year == d.year &&
                    _selectedDate!.month == d.month &&
                    _selectedDate!.day == d.day;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDate = d),
                  child: Container(
                    width: 56,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.brand500 : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            selected ? AppColors.brand500 : AppColors.divider,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _weekDays[d.weekday - 1],
                          style: TextStyle(
                            fontSize: 12,
                            color: selected
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${d.day}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: selected
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        _block(
          'Giờ bắt đầu',
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _timeSlots.map((t) {
              final selected = _selectedTime == t;
              return GestureDetector(
                onTap: () => setState(() => _selectedTime = t),
                child: Container(
                  width: 72,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.brand500 : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected ? AppColors.brand500 : AppColors.divider,
                    ),
                  ),
                  child: Text(
                    _fmtTime(t),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 10),
        _block(
          'Địa điểm làm việc',
          InkWell(
            onTap: _pickAddress,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      color: AppColors.brand500),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _loadingAddress
                        ? const Text('Đang tải địa chỉ...',
                            style: TextStyle(color: AppColors.textSecondary))
                        : _diaChi == null
                            ? const Text('Chọn hoặc thêm địa chỉ làm việc',
                                style: TextStyle(color: AppColors.textSecondary))
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_diaChi!.tieuDe,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700)),
                                  Text(_diaChi!.diaChiChiTiet,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary)),
                                ],
                              ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textMuted),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _block(
          'Ghi chú cho người làm',
          TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'VD: Nhà có thú cưng, cần lau kính kỹ...',
            ),
          ),
        ),
      ],
    );
  }

  // ===================== BƯỚC 3: XÁC NHẬN =====================

  Widget _buildStep3() {
    final plan = _plan ?? const {'label': '—'};

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        _block(
          'Vị trí làm việc',
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_rounded,
                  color: AppColors.brand500, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _diaChi?.diaChiChiTiet ?? '—',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _block(
          'Thông tin công việc',
          Column(
            children: [
              _summaryRow('Dịch vụ', _serviceTitle),
              _summaryRow('Gói', plan['label'] as String),
              _summaryRow('Ngày làm',
                  _selectedDate == null ? '—' : _fmtDate(_selectedDate!)),
              _summaryRow('Giờ bắt đầu',
                  _selectedTime == null ? '—' : _fmtTime(_selectedTime!)),
              if (_noteController.text.trim().isNotEmpty)
                _summaryRow('Ghi chú', _noteController.text.trim()),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _block(
          'Phương thức thanh toán',
          Column(
            children: List.generate(_payments.length, (i) {
              final p = _payments[i];
              final selected = i == _selectedPayment;
              return InkWell(
                onTap: () => setState(() => _selectedPayment = i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(p['icon'] as IconData,
                          color: AppColors.textSecondary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          p['label'] as String,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Icon(
                        selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color:
                            selected ? AppColors.brand500 : AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 10),
        _block(
          'Chi tiết thanh toán',
          Column(
            children: [
              _summaryRow('Tạm tính', _formatPrice(_base)),
              if (_discount > 0)
                _summaryRow('Khuyến mãi ($_appliedCode)', '-${_formatPrice(_discount)}',
                    valueColor: AppColors.green500),
              const Divider(height: 16),
              Row(
                children: [
                  const Text(
                    'Tổng cộng',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatPrice(_total),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: AppColors.brand600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===================== THÀNH PHẦN CHUNG =====================

  Widget _block(String title, Widget child) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
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

  Widget _summaryRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style:
                  const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Nút dưới cùng kiểu bTaskee: giá bên trái, hành động bên phải
  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, 10 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SizedBox(
        height: 50,
        child: ElevatedButton(
          onPressed: _submitting || _calculating || _plan == null ? null : _onNext,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 18),
          ),
          child: Row(
            children: [
              Text(
                _formatPrice(_total),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                _submitting
                    ? 'Đang đặt...'
                    : _step < 2
                        ? 'Tiếp theo'
                        : 'Đặt lịch',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onNext() {
    if (_step == 1 && _diaChi == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn địa chỉ làm việc'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (_step == 1 && (_selectedDate == null || _selectedTime == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ngày và giờ làm việc'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (_step < 2) {
      setState(() => _step++);
    } else {
      _confirmBooking();
    }
  }

  /// Tạo đơn: POST /v1/bookings (giá và khuyến mãi được máy chủ tính lại khi lưu).
  Future<void> _confirmBooking() async {
    final plan = _plan;
    if (plan == null || _session == null || !_session!.isCustomer) return;
    setState(() => _submitting = true);
    try {
      final d = _selectedDate!;
      final startTime = _selectedTime!;
      final durationMinutes = CatalogUi.toInt(widget.service['thoiGianThucHienPhut'] ?? widget.service['thoiGianThucHien'] ?? 120);
      final durationHours = (durationMinutes / 60).ceil();
      
      final totalStartMinutes = startTime.hour * 60 + startTime.minute;
      final totalEndMinutes = totalStartMinutes + (durationMinutes > 0 ? durationMinutes : 120);
      final endTime = TimeOfDay(
        hour: (totalEndMinutes ~/ 60) % 24,
        minute: totalEndMinutes % 60,
      );

      final dateStr = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final paymentCode = _payments[_selectedPayment]['code'] as String? ?? (_selectedPayment == 0 ? 'TIEN_MAT' : 'CHUYEN_KHOAN');

      final res = await _bookingApi.createBooking(
        khachHangId: _session!.userId,
        dichVuId: _dichVuId,
        bangGiaId: plan['bangGiaId'] as int?,
        ngayThucHien: dateStr,
        ngayLamViec: dateStr,
        gioBatDau: _fmtTime(startTime),
        gioKetThuc: _fmtTime(endTime),
        soGio: durationHours > 0 ? durationHours : 2,
        diaChiId: _diaChi?.id,
        diaChiChiTiet: _diaChi?.diaChiChiTiet,
        diaChi: _diaChi?.diaChiChiTiet,
        khuVucId: _diaChi?.khuVucId,
        loaiHinhDat: plan['loaiHinhDat'] as String? ?? 'TheoLan',
        yeuCauDacBiet: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        ghiChu: 'Thanh toán: ${_payments[_selectedPayment]['label']}',
        maKhuyenMai: _appliedCode,
        phuongThucThanhToan: paymentCode,
      );

      if (!mounted) return;
      if (!res.success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res.message ?? 'Không đặt được lịch, vui lòng thử lại'),
          backgroundColor: AppColors.error,
        ));
        return;
      }
      _showBookedDialog(res.data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Lỗi kết nối máy chủ'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showBookedDialog(Map<String, dynamic>? data) {
    final maDon = data?['maDonDat']?.toString() ?? data?['maDon']?.toString();
    final orderId = CatalogUi.toInt(data?['id'] ?? data?['donDatId']);

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                color: AppColors.greenLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded,
                  color: AppColors.green500, size: 42),
            ),
            const SizedBox(height: 16),
            const Text(
              'Đặt lịch thành công!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${maDon != null ? 'Mã đơn $maDon. ' : ''}Đơn của bạn đã được ghi nhận hệ thống backend & database. Bạn có thể theo dõi tiến độ trên web hoặc ứng dụng!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            if (orderId > 0) ...[
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderDetailScreen(orderId: orderId),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('Xem chi tiết đơn hàng'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('Về trang dịch vụ'),
              ),
            ] else ...[
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('Về trang dịch vụ'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
