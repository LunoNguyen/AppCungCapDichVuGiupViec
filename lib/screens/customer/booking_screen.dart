import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
<<<<<<< Updated upstream
import '../../services/address_api_service.dart';
import '../../services/session_service.dart';
import 'address_book_screen.dart';
=======
import '../../services/session_service.dart';
import '../../services/booking_api_service.dart';
import '../../services/service_catalog_api_service.dart';
import '../../services/order_storage_service.dart';
import 'customer_main_screen.dart';
import '../auth/login_screen.dart';
>>>>>>> Stashed changes

class BookingScreen extends StatefulWidget {
  final Map<String, dynamic> service;

  const BookingScreen({super.key, required this.service});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int _step = 0;
<<<<<<< Updated upstream
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
  bool _promoApplied = false;

  static const _stepTitles = ['Chọn gói', 'Chọn thời gian', 'Xác nhận'];
=======
  static const _stepTitles = [
    'Chi tiết công việc',
    'Thời gian & Địa điểm',
    'Xác nhận & Thanh toán',
  ];
>>>>>>> Stashed changes
  static const _weekDays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  // Bước 1: Quy mô & Dịch vụ thêm
  int _selectedDurationIndex = 1; // Mặc định 3 giờ (phổ biến nhất)
  final List<Map<String, dynamic>> _durationOptions = [
    {
      'hours': 2,
      'title': '2 giờ làm việc',
      'area': 'Tối đa 55m² • 2 phòng',
      'price': 140000,
      'desc': 'Phù hợp căn hộ 1 phòng ngủ, phòng trọ, dọn dẹp nhanh',
    },
    {
      'hours': 3,
      'title': '3 giờ làm việc',
      'area': '55m² - 85m² • 3 phòng',
      'price': 200000,
      'desc': 'Phù hợp căn hộ 2 phòng ngủ, nhà phố nhỏ (Được chọn nhiều nhất)',
      'isPopular': true,
    },
    {
      'hours': 4,
      'title': '4 giờ làm việc',
      'area': '85m² - 105m² • 4 phòng',
      'price': 260000,
      'desc': 'Phù hợp nhà 2–3 tầng, căn hộ lớn, dọn dẹp kỹ',
    },
  ];

  // Tùy chọn dịch vụ thêm đặc trưng bTaskee
  bool _bringTools = false; // Mang theo dụng cụ & hoá chất (+30.000đ)
  bool _cooking = false; // Nấu ăn gia đình (+50.000đ)
  bool _ironing = false; // Ủi đồ (+40.000đ)
  bool _hasPets = false; // Nhà có thú cưng
  bool _preferFemale = false; // Ưu tiên người làm nữ

  // Bước 2: Thời gian & Địa điểm
  late final List<DateTime> _dateOptions = List.generate(14, (i) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + i);
  });
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  final List<TimeOfDay> _morningSlots = [
    const TimeOfDay(hour: 7, minute: 0),
    const TimeOfDay(hour: 8, minute: 0),
    const TimeOfDay(hour: 9, minute: 0),
    const TimeOfDay(hour: 10, minute: 0),
  ];
  final List<TimeOfDay> _afternoonSlots = [
    const TimeOfDay(hour: 13, minute: 0),
    const TimeOfDay(hour: 14, minute: 0),
    const TimeOfDay(hour: 15, minute: 0),
    const TimeOfDay(hour: 16, minute: 0),
  ];
  final List<TimeOfDay> _eveningSlots = [
    const TimeOfDay(hour: 17, minute: 0),
    const TimeOfDay(hour: 18, minute: 0),
  ];

  String _houseType = 'Căn hộ chung cư';
  final List<String> _houseTypes = [
    'Căn hộ chung cư',
    'Nhà phố',
    'Biệt thự',
    'Phòng trọ',
  ];

  final _addressController = TextEditingController(text: '123 Nguyễn Trãi, Phường Bến Thành, Quận 1, TP.HCM');
  final _customerNameController = TextEditingController(text: 'Khách hàng');
  final _customerPhoneController = TextEditingController(text: '0901234567');
  final _noteController = TextEditingController();

  // Bước 3: Xác nhận & Thanh toán
  int _selectedPayment = 0;
  final List<Map<String, dynamic>> _payments = [
    {
      'id': 'TIEN_MAT',
      'label': 'Tiền mặt',
      'sub': 'Thanh toán trực tiếp cho người làm khi hoàn tất',
      'icon': Icons.payments_rounded,
    },
    {
      'id': 'VIETQR',
      'label': 'Chuyển khoản VietQR',
      'sub': 'Quét mã QR qua mọi ứng dụng ngân hàng',
      'icon': Icons.qr_code_scanner_rounded,
    },
    {
      'id': 'MOMO',
      'label': 'Ví MoMo / ZaloPay',
      'sub': 'Thanh toán qua ví điện tử liên kết',
      'icon': Icons.account_balance_wallet_rounded,
    },
  ];

  final _promoController = TextEditingController();
  bool _promoApplied = false;
  String? _appliedPromoCode;
  int _discountAmount = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = _dateOptions.first;
    _selectedTime = const TimeOfDay(hour: 8, minute: 0);

    SessionService.load().then((s) {
      if (s != null && mounted) {
        setState(() {
          if (s.fullName.trim().isNotEmpty) {
            _customerNameController.text = s.fullName;
          }
          if (s.soDienThoai.trim().isNotEmpty) {
            _customerPhoneController.text = s.soDienThoai;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _noteController.dispose();
    _promoController.dispose();
    super.dispose();
  }

  String get _serviceTitle =>
      ((widget.service['title'] as String?) ?? 'Dọn dẹp nhà').replaceAll('\n', ' ');

  int get _selectedHours => _durationOptions[_selectedDurationIndex]['hours'] as int;

  int get _basePrice {
    final optPrice = _durationOptions[_selectedDurationIndex]['price'] as int;
    final svcPrice = widget.service['basePrice'] ?? widget.service['price'];
    if (svcPrice is int && svcPrice > 0 && _selectedHours == 2) {
      return svcPrice;
    }
    return optPrice;
  }

  int get _extraPrice {
    int total = 0;
    if (_bringTools) total += 30000;
    if (_cooking) total += 50000;
    if (_ironing) total += 40000;
    return total;
  }

  int get _subtotal => _basePrice + _extraPrice;

  int get _total => (_subtotal - _discountAmount).clamp(0, 999999999);

  String _formatPrice(int p) =>
      '${p.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ';

  String _fmtDate(DateTime d) =>
      '${_weekDays[d.weekday - 1]}, ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

<<<<<<< Updated upstream
  String get _serviceTitle =>
      ((widget.service['title'] as String?) ?? 'Dịch vụ').replaceAll('\n', ' ');

  @override
  void initState() {
    super.initState();
    _loadDefaultAddress();
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
=======
  String _calcEndTime(TimeOfDay start, int hours) {
    final totalMinutes = start.hour * 60 + start.minute + hours * 60;
    final endHour = (totalMinutes ~/ 60) % 24;
    final endMinute = totalMinutes % 60;
    return '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';
>>>>>>> Stashed changes
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _stepTitles[_step],
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            if (_step > 0) {
              setState(() => _step--);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_step + 1) / _stepTitles.length,
            minHeight: 4,
            backgroundColor: const Color(0xFFE2E8F0),
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

  // ===========================================================================
  // BƯỚC 1: CHI TIẾT CÔNG VIỆC & QUY MÔ
  // ===========================================================================

  Widget _buildStep1() {
    final s = widget.service;

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // Thẻ tóm tắt dịch vụ
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brand500.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  s['icon'] as IconData? ?? Icons.cleaning_services_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _serviceTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      s['subtitle']?.toString() ?? 'Tiện ích chuyên nghiệp, đảm bảo sạch sẽ',
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

        // Chọn thời lượng / quy mô
        _section(
          title: 'Chọn thời lượng & quy mô',
          subtitle: 'Lựa chọn thời gian phù hợp với diện tích nhà bạn',
          child: Column(
            children: List.generate(_durationOptions.length, (i) {
              final opt = _durationOptions[i];
              final isSelected = i == _selectedDurationIndex;
              final isPopular = opt['isPopular'] == true;

              return GestureDetector(
                onTap: () => setState(() => _selectedDurationIndex = i),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFF0FDF4).withValues(alpha: 0.5) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? AppColors.brand500 : const Color(0xFFE2E8F0),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.brand500.withValues(alpha: 0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Text(
                                  opt['title'] as String,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15.5,
                                    color: isSelected ? AppColors.brand700 : AppColors.textPrimary,
                                  ),
                                ),
                                if (isPopular) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Phổ biến',
                                      style: TextStyle(
                                        color: Color(0xFFB45309),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 10.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Text(
                            _formatPrice(opt['price'] as int),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: isSelected ? AppColors.brand600 : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                            color: isSelected ? AppColors.brand500 : const Color(0xFFCBD5E1),
                            size: 22,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.home_work_outlined, size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 5),
                          Text(
                            opt['area'] as String,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        opt['desc'] as String,
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 10),

        // Dịch vụ thêm đặc trưng bTaskee
        _section(
          title: 'Dịch vụ thêm',
          subtitle: 'Tùy chọn bổ sung để công việc hoàn hảo hơn',
          child: Column(
            children: [
              _buildAddonSwitch(
                icon: Icons.cleaning_services_rounded,
                title: 'Mang dụng cụ & chất tẩy rửa',
                subtitle: 'Người làm tự chuẩn bị đầy đủ cây lau, chổi, khăn và hóa chất',
                price: '+30.000đ',
                value: _bringTools,
                onChanged: (v) => setState(() => _bringTools = v),
              ),
              const Divider(height: 1),
              _buildAddonSwitch(
                icon: Icons.restaurant_rounded,
                title: 'Nấu ăn gia đình',
                subtitle: 'Nấu 2–3 món ăn gia đình đơn giản theo yêu cầu',
                price: '+50.000đ',
                value: _cooking,
                onChanged: (v) => setState(() => _cooking = v),
              ),
              const Divider(height: 1),
              _buildAddonSwitch(
                icon: Icons.iron_rounded,
                title: 'Ủi quần áo',
                subtitle: 'Ủi thẳng quần áo công sở, đồ gia đình (tối đa 10 bộ)',
                price: '+40.000đ',
                value: _ironing,
                onChanged: (v) => setState(() => _ironing = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Yêu cầu đặc biệt
        _section(
          title: 'Yêu cầu đặc biệt',
          subtitle: 'Ghi chú thêm về nhà của bạn',
          child: Column(
            children: [
              _buildAddonSwitch(
                icon: Icons.pets_rounded,
                title: 'Nhà có thú cưng (chó/mèo)',
                subtitle: 'Để người làm chuẩn bị và tránh trường hợp bị dị ứng',
                value: _hasPets,
                onChanged: (v) => setState(() => _hasPets = v),
              ),
              const Divider(height: 1),
              _buildAddonSwitch(
                icon: Icons.woman_rounded,
                title: 'Ưu tiên người làm Nữ',
                subtitle: 'Hệ thống sẽ ưu tiên gửi việc cho các đối tác nữ',
                value: _preferFemale,
                onChanged: (v) => setState(() => _preferFemale = v),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddonSwitch({
    required IconData icon,
    required String title,
    required String subtitle,
    String? price,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: value ? AppColors.brandLight : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 22,
              color: value ? AppColors.brand500 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (price != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        price,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          color: AppColors.brand600,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: AppColors.brand500.withValues(alpha: 0.5),
            activeThumbColor: AppColors.brand500,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // BƯỚC 2: THỜI GIAN & ĐỊA ĐIỂM
  // ===========================================================================

  Widget _buildStep2() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // Chọn ngày làm việc
        _section(
          title: 'Ngày làm việc',
          subtitle: 'Chọn ngày thực hiện dịch vụ',
          child: SizedBox(
            height: 78,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _dateOptions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final d = _dateOptions[i];
                final isSelected = _selectedDate != null &&
                    _selectedDate!.year == d.year &&
                    _selectedDate!.month == d.month &&
                    _selectedDate!.day == d.day;
                final isToday = i == 0;

                return GestureDetector(
                  onTap: () => setState(() => _selectedDate = d),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 62,
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppColors.brandGradient : null,
                      color: isSelected ? null : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppColors.brand500 : const Color(0xFFE2E8F0),
                        width: isSelected ? 1.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.brand500.withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isToday ? 'Hôm nay' : _weekDays[d.weekday - 1],
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${d.day}',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Th${d.month}',
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected ? Colors.white.withValues(alpha: 0.85) : AppColors.textMuted,
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

        // Giờ bắt đầu
        _section(
          title: 'Giờ bắt đầu làm việc',
          subtitle: _selectedTime == null
              ? 'Chọn thời gian bắt đầu'
              : 'Dự kiến: ${_fmtTime(_selectedTime!)} → ${_calcEndTime(_selectedTime!, _selectedHours)} ($_selectedHours giờ)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTimeSlotGroup('Buổi sáng', _morningSlots),
              const SizedBox(height: 12),
              _buildTimeSlotGroup('Buổi chiều', _afternoonSlots),
              const SizedBox(height: 12),
              _buildTimeSlotGroup('Buổi tối', _eveningSlots),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Địa điểm & loại nhà
        _section(
          title: 'Địa điểm làm việc',
          subtitle: 'Địa chỉ cụ thể để người làm tìm đến đúng nơi',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Loại nhà
              const Text(
                'Loại hình nhà ở',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _houseTypes.map((ht) {
                  final isSel = _houseType == ht;
                  return ChoiceChip(
                    label: Text(ht),
                    selected: isSel,
                    selectedColor: AppColors.brandLight,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSel ? AppColors.brand700 : AppColors.textPrimary,
                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13,
                    ),
                    side: BorderSide(color: isSel ? AppColors.brand500 : const Color(0xFFE2E8F0)),
                    onSelected: (v) {
                      if (v) setState(() => _houseType = ht);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Địa chỉ chi tiết
              TextField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Địa chỉ chi tiết',
                  prefixIcon: const Icon(Icons.location_on_rounded, color: AppColors.brand500),
                  hintText: 'Số nhà, tên đường, phường, quận...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
<<<<<<< Updated upstream
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
=======

        // Thông tin liên hệ
        _section(
          title: 'Thông tin liên hệ',
          subtitle: 'Để người làm liên hệ xác nhận trước khi đến',
          child: Column(
            children: [
              TextField(
                controller: _customerNameController,
                decoration: InputDecoration(
                  labelText: 'Tên người liên hệ',
                  prefixIcon: const Icon(Icons.person_rounded, color: AppColors.brand500),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _customerPhoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Số điện thoại',
                  prefixIcon: const Icon(Icons.phone_rounded, color: AppColors.brand500),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ],
>>>>>>> Stashed changes
          ),
        ),
        const SizedBox(height: 10),

        // Ghi chú cho người làm
        _section(
          title: 'Ghi chú cho người làm',
          subtitle: 'Chỉ dẫn thêm đường đi, đồ đạc hoặc lưu ý cần tránh',
          child: TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'VD: Nhà hẻm nhỏ, bấm chuông lầu 1, vui lòng để xe trước cửa...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSlotGroup(String groupTitle, List<TimeOfDay> slots) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
<<<<<<< Updated upstream
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
=======
        Text(
          groupTitle,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: slots.map((t) {
            final isSelected = _selectedTime != null &&
                _selectedTime!.hour == t.hour &&
                _selectedTime!.minute == t.minute;

            return GestureDetector(
              onTap: () => setState(() => _selectedTime = t),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 76,
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.brandGradient : null,
                  color: isSelected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppColors.brand500 : const Color(0xFFE2E8F0),
                    width: isSelected ? 1.5 : 1,
>>>>>>> Stashed changes
                  ),
                ),
                child: Text(
                  _fmtTime(t),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ===========================================================================
  // BƯỚC 3: XÁC NHẬN & THANH TOÁN
  // ===========================================================================

  Widget _buildStep3() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // Tóm tắt công việc
        _section(
          title: 'Thông tin công việc',
          child: Column(
            children: [
              _summaryItem(
                icon: Icons.cleaning_services_rounded,
                label: 'Dịch vụ',
                value: _serviceTitle,
              ),
              _summaryItem(
                icon: Icons.timer_outlined,
                label: 'Quy mô / Gói',
                value: '$_selectedHours giờ (${_durationOptions[_selectedDurationIndex]['area']})',
              ),
              _summaryItem(
                icon: Icons.calendar_month_rounded,
                label: 'Thời gian',
                value: '${_selectedDate == null ? '' : _fmtDate(_selectedDate!)}\n${_selectedTime == null ? '' : '${_fmtTime(_selectedTime!)} → ${_calcEndTime(_selectedTime!, _selectedHours)}'}',
              ),
              _summaryItem(
                icon: Icons.location_on_rounded,
                label: 'Địa điểm',
                value: '${_addressController.text.trim()} ($_houseType)',
              ),
              _summaryItem(
                icon: Icons.person_rounded,
                label: 'Khách hàng',
                value: '${_customerNameController.text.trim()} • ${_customerPhoneController.text.trim()}',
              ),
              if (_bringTools || _cooking || _ironing || _hasPets || _preferFemale)
                _summaryItem(
                  icon: Icons.add_task_rounded,
                  label: 'Yêu cầu thêm',
                  value: [
                    if (_bringTools) 'Mang dụng cụ (+30k)',
                    if (_cooking) 'Nấu ăn (+50k)',
                    if (_ironing) 'Ủi đồ (+40k)',
                    if (_hasPets) 'Nhà có thú cưng',
                    if (_preferFemale) 'Ưu tiên người làm Nữ',
                  ].join('\n'),
                ),
              if (_noteController.text.trim().isNotEmpty)
                _summaryItem(
                  icon: Icons.edit_note_rounded,
                  label: 'Ghi chú',
                  value: _noteController.text.trim(),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Khuyến mãi / Voucher
        _section(
          title: 'Khuyến mãi & Ưu đãi',
          subtitle: 'Nhập mã để nhận giảm giá từ hệ thống',
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _promoController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: 'Nhập mã (VD: BTASKEE, GIAM20)',
                        prefixIcon: const Icon(Icons.local_offer_rounded, color: AppColors.brand500),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _applyPromo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _promoApplied ? AppColors.green500 : AppColors.brand500,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(_promoApplied ? 'Đã áp dụng' : 'Áp dụng'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Gợi ý voucher
              Wrap(
                spacing: 8,
                children: [
                  _promoChip('BTASKEE', 'Giảm 25.000đ'),
                  _promoChip('GIAM20', 'Giảm 20%'),
                  _promoChip('NEATIFY50', 'Giảm 50.000đ'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Phương thức thanh toán
        _section(
          title: 'Phương thức thanh toán',
          child: Column(
            children: List.generate(_payments.length, (i) {
              final p = _payments[i];
              final isSel = i == _selectedPayment;
              return InkWell(
                onTap: () => setState(() => _selectedPayment = i),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSel ? AppColors.brandLight.withValues(alpha: 0.5) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSel ? AppColors.brand500 : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.brandLight : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(p['icon'] as IconData, color: isSel ? AppColors.brand500 : const Color(0xFF64748B)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p['label'] as String,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              p['sub'] as String,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isSel ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        color: isSel ? AppColors.brand500 : const Color(0xFFCBD5E1),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 10),

        // Chi tiết giá
        _section(
          title: 'Chi tiết thanh toán',
          child: Column(
            children: [
              _costRow('Tiền công ($_selectedHours giờ)', _formatPrice(_basePrice)),
              if (_extraPrice > 0)
                _costRow('Phí dịch vụ & dụng cụ thêm', '+${_formatPrice(_extraPrice)}'),
              if (_discountAmount > 0)
                _costRow(
                  'Khuyến mãi (${_appliedPromoCode ?? 'VOUCHER'})',
                  '-${_formatPrice(_discountAmount)}',
                  color: AppColors.green600,
                ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tổng thanh toán',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary),
                  ),
                  Text(
                    _formatPrice(_total),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: AppColors.brand700,
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

  Widget _promoChip(String code, String label) {
    return ActionChip(
      avatar: const Icon(Icons.confirmation_number_outlined, size: 14, color: AppColors.brand600),
      label: Text('$code: $label', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
      backgroundColor: const Color(0xFFF1F5F9),
      side: const BorderSide(color: Color(0xFFE2E8F0)),
      onPressed: () {
        _promoController.text = code;
        _applyPromo();
      },
    );
  }

  void _applyPromo() {
    final code = _promoController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    int discount = 0;
    if (code == 'BTASKEE') {
      discount = 25000;
    } else if (code == 'GIAM20') {
      discount = (_subtotal * 0.2).toInt();
    } else if (code == 'NEATIFY50') {
      discount = 50000;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mã khuyến mãi không hợp lệ hoặc đã hết lượt sử dụng'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _promoApplied = true;
      _appliedPromoCode = code;
      _discountAmount = discount;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Áp dụng mã $code thành công! Đã giảm ${_formatPrice(discount)}'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Widget _section({required String title, String? subtitle, required Widget child}) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _summaryItem({required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.brand500),
          const SizedBox(width: 10),
          SizedBox(
            width: 95,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _costRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

<<<<<<< Updated upstream
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
=======
  // ===========================================================================
  // BOTTOM BAR & SUBMISSION
  // ===========================================================================

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tổng ước tính',
                  style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                ),
                Text(
                  _formatPrice(_total),
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppColors.brand700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 48,
            width: 170,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _handleNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brand500,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      _step < 2 ? 'Tiếp theo' : 'Đăng đơn đặt',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNext() {
    if (_step == 1) {
      if (_addressController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng nhập địa chỉ làm việc'), backgroundColor: AppColors.error),
        );
        return;
      }
      if (_customerPhoneController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng nhập số điện thoại liên hệ'), backgroundColor: AppColors.error),
        );
        return;
      }
>>>>>>> Stashed changes
    }

    if (_step < 2) {
      setState(() => _step++);
    } else {
      _executeBooking();
    }
  }

  Future<void> _executeBooking() async {
    setState(() => _isSubmitting = true);

    final orderId = 'BTK-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final dateStr = _selectedDate == null
        ? DateTime.now().toIso8601String().substring(0, 10)
        : '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
    final timeStr = _selectedTime == null ? '08:00' : _fmtTime(_selectedTime!);

    final order = CustomerOrder(
      id: orderId,
      dichVuId: (widget.service['id'] is int) ? widget.service['id'] as int : 1,
      dichVuTitle: _serviceTitle,
      dichVuSubtitle: widget.service['subtitle']?.toString(),
      planLabel: '$_selectedHours giờ (${_durationOptions[_selectedDurationIndex]['area']})',
      soGio: _selectedHours,
      ngayLamViec: dateStr,
      gioBatDau: timeStr,
      diaChi: '${_addressController.text.trim()} ($_houseType)',
      tenKhachHang: _customerNameController.text.trim(),
      soDienThoai: _customerPhoneController.text.trim(),
      ghiChu: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
      bringTools: _bringTools,
      hasPets: _hasPets,
      preferFemale: _preferFemale,
      cooking: _cooking,
      ironing: _ironing,
      phuongThucThanhToan: _payments[_selectedPayment]['id'] as String,
      maKhuyenMai: _appliedPromoCode,
      basePrice: _basePrice,
      extraPrice: _extraPrice,
      discount: _discountAmount,
      tongTien: _total,
      trangThai: 'DANG_TIM_NGUOI',
      createdAt: DateTime.now().toIso8601String(),
    );

    final session = await SessionService.load();
    if (session == null || !session.isCustomer) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      return;
    }

    // 1. Xác định ID dịch vụ chính xác bằng cách tìm trong danh sách dịch vụ của backend
    int targetDichVuId = (widget.service['id'] is int) ? widget.service['id'] as int : 1;
    final title = _serviceTitle.toLowerCase().trim();

    try {
      final catalogApi = ServiceCatalogApiService();
      final resCatalog = await catalogApi.getServices();
      if (resCatalog.success && resCatalog.data != null) {
        final allServices = resCatalog.data!;
        
        int? matchedTimeId;
        int? matchedNullTimeId;
        int? matchedAnyId;
        int? closestTimeId;
        int minTimeDiff = 999999;

        for (var s in allServices) {
          final tenDb = (s['tenDichVu'] ?? '').toString().toLowerCase();
          final timeDb = s['thoiGianThucHienPhut'];
          
          bool matchTitle = false;
          if (title.contains('dọn dẹp nhà')) {
            matchTitle = tenDb.contains('dọn dẹp nhà') && !tenDb.contains('gói');
          } else if (title.contains('trông trẻ') || title.contains('bảo mẫu')) {
            matchTitle = tenDb.contains('trông trẻ') && !tenDb.contains('gói');
          } else if (title.contains('người già') || title.contains('người cao tuổi')) {
            matchTitle = tenDb.contains('chăm sóc người cao tuổi') && !tenDb.contains('gói');
          } else if (title.contains('người bệnh')) {
            matchTitle = tenDb.contains('chăm sóc người bệnh') && !tenDb.contains('gói');
          } else if (title.contains('dọn văn phòng') || title.contains('vệ sinh văn phòng')) {
            matchTitle = tenDb.contains('vệ sinh văn phòng') && !tenDb.contains('thảm') && !tenDb.contains('gói');
          } else if (title.contains('máy lạnh') || title.contains('điều hoà')) {
            matchTitle = tenDb.contains('máy lạnh') && !tenDb.contains('gói');
          } else if (title.contains('nấu ăn')) {
            matchTitle = tenDb.contains('nấu ăn') && !tenDb.contains('gói');
          } else if (title.contains('giặt') || title.contains('ủi')) {
            matchTitle = (tenDb.contains('giặt sấy') || tenDb.contains('giặt')) && !tenDb.contains('gói');
          } else if (title.contains('tổng vệ sinh')) {
            matchTitle = tenDb.contains('tổng vệ sinh') && !tenDb.contains('gói');
          } else if (title.contains('sofa') || title.contains('rèm')) {
            matchTitle = (tenDb.contains('sofa') || tenDb.contains('rèm')) && !tenDb.contains('gói');
          } else if (title.contains('chuyển nhà')) {
            matchTitle = tenDb.contains('chuyển nhà') && !tenDb.contains('gói');
          } else {
            matchTitle = (tenDb.contains(title) || title.contains(tenDb)) && !tenDb.contains('gói');
          }

          if (matchTitle) {
            if (matchedAnyId == null) matchedAnyId = s['id'];
            if (timeDb == _selectedHours * 60) {
              matchedTimeId = s['id'];
              break;
            } else if (timeDb != null) {
              int diff = (timeDb - (_selectedHours * 60)).abs();
              if (diff < minTimeDiff) {
                minTimeDiff = diff;
                closestTimeId = s['id'];
              }
            } else if (timeDb == null && matchedNullTimeId == null) {
              matchedNullTimeId = s['id'];
            }
          }
        }

        if (matchedTimeId != null) {
          targetDichVuId = matchedTimeId;
        } else if (closestTimeId != null) {
          targetDichVuId = closestTimeId;
        } else if (matchedAnyId != null) {
          targetDichVuId = matchedAnyId;
        } else if (matchedNullTimeId != null) {
          targetDichVuId = matchedNullTimeId;
        }
      }
    } catch (_) {
      // Fallback
    }

    final specialReqs = [
      if (_bringTools) 'Mang dụng cụ & hóa chất',
      if (_cooking) 'Nấu ăn gia đình',
      if (_ironing) 'Ủi đồ',
      if (_hasPets) 'Nhà có thú cưng',
      if (_preferFemale) 'Ưu tiên CTV Nữ',
    ].join(', ');

    String finalOrderId = orderId;

    // 2. Gửi backend API để lưu vào CSDL hệ thống
    try {
      final api = BookingApiService();
      final res = await api.createBooking(
        khachHangId: session.userId,
        dichVuId: targetDichVuId,
        ngayLamViec: dateStr,
        gioBatDau: timeStr,
        soGio: _selectedHours,
        diaChi: '${_addressController.text.trim()} ($_houseType)',
        ghiChu: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
        maKhuyenMai: _appliedPromoCode,
        phuongThucThanhToan: _payments[_selectedPayment]['id'] as String,
        yeuCauDacBiet: specialReqs.isNotEmpty ? specialReqs : null,
      );

      if (res.success && res.data != null) {
        final serverCode = res.data?['maDonDat'] ?? res.data?['maDonHang'] ?? (res.data?['donDatId'] != null ? 'DD-${res.data!['donDatId']}' : null);
        if (serverCode != null) {
          finalOrderId = serverCode.toString();
        }
      } else if (!res.success && res.message != null && res.message!.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lưu ý từ hệ thống: ${res.message}'), backgroundColor: AppColors.warning),
          );
        }
      }
    } catch (_) {
      // Backend offline hoặc đang khởi động
    }

    final finalOrder = CustomerOrder(
      id: finalOrderId,
      dichVuId: targetDichVuId,
      dichVuTitle: order.dichVuTitle,
      dichVuSubtitle: order.dichVuSubtitle,
      planLabel: order.planLabel,
      soGio: order.soGio,
      ngayLamViec: order.ngayLamViec,
      gioBatDau: order.gioBatDau,
      diaChi: order.diaChi,
      tenKhachHang: order.tenKhachHang,
      soDienThoai: order.soDienThoai,
      ghiChu: order.ghiChu,
      bringTools: order.bringTools,
      hasPets: order.hasPets,
      preferFemale: order.preferFemale,
      cooking: order.cooking,
      ironing: order.ironing,
      phuongThucThanhToan: order.phuongThucThanhToan,
      maKhuyenMai: order.maKhuyenMai,
      basePrice: order.basePrice,
      extraPrice: order.extraPrice,
      discount: order.discount,
      tongTien: order.tongTien,
      trangThai: order.trangThai,
      createdAt: order.createdAt,
    );

    // 2. Lưu local để hiển thị ngay trong Tab Hoạt động
    await OrderStorageService.saveOrder(finalOrder);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    _showSuccessDialog(finalOrder);
  }

  void _showSuccessDialog(CustomerOrder order) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFE4F6F7),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.brand500.withValues(alpha: 0.3), width: 3),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.brand500,
                size: 46,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Đăng việc thành công!',
              style: TextStyle(
                fontSize: 18.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Mã đơn: ${order.id}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  color: AppColors.brand700,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Hệ thống đang phát việc cho các Cộng tác viên gần bạn nhất. Người làm phù hợp sẽ nhận việc và liên hệ trước khi đến.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const CustomerMainScreen(initialIndex: 1),
                    ),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brand500,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Xem đơn trong Hoạt động',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const CustomerMainScreen(initialIndex: 0),
                  ),
                  (route) => false,
                );
              },
              child: const Text(
                'Về trang chủ',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
