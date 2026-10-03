import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

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
  final _addressController = TextEditingController(
      text: '123 Nguyễn Trãi, Q.1, TP.HCM');
  final _noteController = TextEditingController();
  final _promoController = TextEditingController();
  bool _promoApplied = false;

  static const _stepTitles = ['Chọn gói', 'Chọn thời gian', 'Xác nhận'];
  static const _weekDays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  final List<Map<String, dynamic>> _plans = [
    {'label': 'Theo buổi', 'price': 150000, 'display': '150.000đ/h', 'desc': '2–4 giờ'},
    {'label': 'Gói 8 buổi', 'price': 1100000, 'display': '1.100.000đ', 'desc': 'Tiết kiệm 8%'},
    {'label': 'Gói tháng', 'price': 3800000, 'display': '3.800.000đ', 'desc': 'Tiết kiệm 15%'},
  ];

  final List<Map<String, dynamic>> _payments = [
    {'icon': Icons.payments_outlined, 'label': 'Tiền mặt'},
    {'icon': Icons.qr_code_scanner_rounded, 'label': 'Chuyển khoản / QR'},
  ];

  // Khung giờ bắt đầu 07:00 → 17:00
  final List<TimeOfDay> _timeSlots = List.generate(
      11, (i) => TimeOfDay(hour: 7 + i, minute: 0));

  late final List<DateTime> _dateOptions = List.generate(14, (i) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + i + 1);
  });

  int get _total {
    final base = _plans[_selectedPlan]['price'] as int;
    return _promoApplied ? (base * 0.8).toInt() : base;
  }

  String _formatPrice(int p) =>
      '${p.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ';

  String _fmtDate(DateTime d) =>
      '${_weekDays[d.weekday - 1]}, ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String get _serviceTitle =>
      ((widget.service['title'] as String?) ?? 'Dịch vụ').replaceAll('\n', ' ');

  @override
  void dispose() {
    _addressController.dispose();
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
          Column(
            children: List.generate(_plans.length, (i) {
              final p = _plans[i];
              final selected = i == _selectedPlan;
              return GestureDetector(
                onTap: () => setState(() => _selectedPlan = i),
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
                    hintText: 'Nhập mã (VD: GIAM20)',
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
                  onPressed: _applyPromo,
                  child: Text(_promoApplied ? 'Đã áp dụng' : 'Áp dụng'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _applyPromo() {
    final ok = _promoController.text.trim().toUpperCase() == 'GIAM20';
    if (ok) setState(() => _promoApplied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Áp dụng mã thành công! Giảm 20%'
            : 'Mã không hợp lệ hoặc đã hết hạn'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
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
          TextField(
            controller: _addressController,
            decoration: const InputDecoration(
              prefixIcon:
                  Icon(Icons.location_on_outlined, color: AppColors.brand500),
              hintText: 'Địa chỉ thực hiện dịch vụ',
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
    final plan = _plans[_selectedPlan];
    final base = plan['price'] as int;
    final discount = _promoApplied ? (base * 0.2).toInt() : 0;

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
                  _addressController.text,
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
              _summaryRow('Tạm tính', _formatPrice(base)),
              if (_promoApplied)
                _summaryRow('Khuyến mãi (20%)', '-${_formatPrice(discount)}',
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
          onPressed: _onNext,
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
                _step < 2 ? 'Tiếp theo' : 'Đặt lịch',
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

  void _confirmBooking() {
    showDialog(
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
            const Text(
              'Đơn của bạn đã được ghi nhận. Chúng tôi sẽ tìm người làm phù hợp sớm nhất!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
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
        ),
      ),
    );
  }
}
