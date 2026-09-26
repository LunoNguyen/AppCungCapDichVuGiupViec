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
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final _addressController = TextEditingController(
      text: '123 Nguyễn Trãi, Q.1, TP.HCM');
  final _noteController = TextEditingController();
  final _promoController = TextEditingController();
  bool _promoApplied = false;

  final List<Map<String, dynamic>> _plans = [
    {'label': 'Theo buổi', 'price': 150000, 'display': '150.000đ/h', 'desc': '2–4 giờ'},
    {'label': 'Gói 8 buổi', 'price': 1100000, 'display': '1.100.000đ', 'desc': 'Tiết kiệm 8%'},
    {'label': 'Gói tháng', 'price': 3800000, 'display': '3.800.000đ', 'desc': 'Tiết kiệm 15%'},
  ];

  int get _total {
    final base = _plans[_selectedPlan]['price'] as int;
    return _promoApplied ? (base * 0.8).toInt() : base;
  }

  String _formatPrice(int p) =>
      '${p.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Đặt dịch vụ'),
      ),
      body: Column(
        children: [
          _buildStepper(),
          Expanded(
            child: IndexedStack(
              index: _step,
              children: [
                _buildStep1(),
                _buildStep2(),
                _buildStep3(),
              ],
            ),
          ),
          _buildBottomButtons(),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    const steps = ['Chọn gói', 'Lịch & Địa chỉ', 'Xác nhận'];
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Row(
        children: steps.asMap().entries.map((e) {
          final i = e.key;
          final label = e.value;
          final done = i < _step;
          final active = i == _step;
          return Expanded(
            child: Row(
              children: [
                Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: done || active ? AppColors.brand500 : AppColors.divider,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: done
                            ? const Icon(Icons.check, color: AppColors.white, size: 16)
                            : Text(
                                '${i + 1}',
                                style: TextStyle(
                                  color: active ? AppColors.white : AppColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        color: active ? AppColors.brand500 : AppColors.textSecondary,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                if (i < steps.length - 1)
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 18),
                      height: 2,
                      color: done ? AppColors.brand500 : AppColors.divider,
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStep1() {
    final s = widget.service;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: (s['color'] as Color).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(s['icon'] as IconData, color: s['color'] as Color, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s['title'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        s['subtitle'] as String,
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
          const SizedBox(height: 16),
          const Text(
            'Chọn gói dịch vụ',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ...List.generate(_plans.length, (i) {
            final p = _plans[i];
            final selected = i == _selectedPlan;
            return GestureDetector(
              onTap: () => setState(() => _selectedPlan = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: selected ? AppColors.brand500 : AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? AppColors.brand500 : AppColors.divider,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: selected ? AppColors.white : AppColors.divider,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p['label'] as String,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: selected ? AppColors.white : AppColors.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            p['desc'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: selected ? Colors.white70 : AppColors.textSecondary,
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
                        color: selected ? AppColors.white : AppColors.brand600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_offer_outlined, color: AppColors.brand500),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _promoController,
                    decoration: const InputDecoration(
                      hintText: 'Nhập mã khuyến mãi',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    if (_promoController.text == 'GIAM20') {
                      setState(() => _promoApplied = true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Áp dụng mã thành công! Giảm 20%'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Mã không hợp lệ hoặc đã hết hạn'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                  child: const Text('Áp dụng'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chọn ngày & giờ',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              leading: const Icon(Icons.calendar_today, color: AppColors.brand500),
              title: Text(
                _selectedDate == null
                    ? 'Chọn ngày thực hiện'
                    : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                style: TextStyle(
                  color: _selectedDate == null
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                  builder: (context, child) => Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: AppColors.brand500,
                      ),
                    ),
                    child: child!,
                  ),
                );
                if (date != null) setState(() => _selectedDate = date);
              },
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              leading: const Icon(Icons.access_time, color: AppColors.brand500),
              title: Text(
                _selectedTime == null
                    ? 'Chọn giờ thực hiện'
                    : _selectedTime!.format(context),
                style: TextStyle(
                  color: _selectedTime == null
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: const TimeOfDay(hour: 8, minute: 0),
                  builder: (context, child) => Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: AppColors.brand500,
                      ),
                    ),
                    child: child!,
                  ),
                );
                if (time != null) setState(() => _selectedTime = time);
              },
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Địa điểm thực hiện',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _addressController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.brand500),
              hintText: 'Địa chỉ thực hiện dịch vụ',
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Yêu cầu đặc biệt',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Nhập yêu cầu đặc biệt (không bắt buộc)...',
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    final s = widget.service;
    final plan = _plans[_selectedPlan];
    final base = plan['price'] as int;
    final discount = _promoApplied ? (base * 0.2).toInt() : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tóm tắt đơn hàng',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Divider(height: 20),
                _summaryRow('Dịch vụ', s['title'] as String),
                _summaryRow('Gói', plan['label'] as String),
                if (_selectedDate != null)
                  _summaryRow('Ngày', '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'),
                if (_selectedTime != null)
                  _summaryRow('Giờ', _selectedTime!.format(context)),
                _summaryRow('Địa điểm', _addressController.text),
                const Divider(height: 20),
                _summaryRow('Chi phí gốc', _formatPrice(base)),
                if (_promoApplied)
                  _summaryRow('Giảm giá (20%)', '-${_formatPrice(discount)}',
                      valueColor: AppColors.success),
                const Divider(height: 12),
                Row(
                  children: [
                    const Text(
                      'Tổng cộng',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
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
          const SizedBox(height: 16),
          const Text(
            'Phương thức thanh toán',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          _paymentOption(Icons.qr_code_scanner, 'Chuyển khoản / QR', true),
          const SizedBox(height: 8),
          _paymentOption(Icons.money, 'Tiền mặt (thanh toán trực tiếp)', false),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.textPrimary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentOption(IconData icon, String label, bool selected) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected ? AppColors.brand300.withOpacity(0.1) : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? AppColors.brand500 : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: selected ? AppColors.brand500 : AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ),
          if (selected)
            const Icon(Icons.check_circle, color: AppColors.brand500),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      decoration: const BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2)),
        ],
      ),
      child: Row(
        children: [
          if (_step > 0)
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: () => setState(() => _step--),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brand500,
                  side: const BorderSide(color: AppColors.brand500),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Quay lại'),
              ),
            ),
          if (_step > 0) const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {
                if (_step < 2) {
                  setState(() => _step++);
                } else {
                  _confirmBooking();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brand500,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _step < 2 ? 'Tiếp theo' : 'Xác nhận đặt lịch',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmBooking() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: AppColors.success, size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'Đặt lịch thành công!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Đơn của bạn đã được ghi nhận. Chúng tôi sẽ phân công cộng tác viên sớm nhất!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
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
              child: const Text('Xem lịch sử đặt dịch vụ'),
            ),
          ],
        ),
      ),
    );
  }
}
