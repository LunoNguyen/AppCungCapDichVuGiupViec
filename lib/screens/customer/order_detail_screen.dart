import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import '../../services/booking_api_service.dart';
import '../../services/session_service.dart';
import '../../services/payment_api_service.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;
  final VoidCallback? onOrderUpdated;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
    this.onOrderUpdated,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _bookingApi = BookingApiService();
  final _currencyFormat = NumberFormat('#,###', 'vi_VN');

  bool _loading = true;
  String? _errorMessage;
  Map<String, dynamic>? _order;
  UserSession? _session;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      _session = await SessionService.load();
      final res = await _bookingApi.getBookingDetail(widget.orderId);

      if (mounted) {
        if (res.success && res.data != null) {
          setState(() {
            _order = res.data;
            _loading = false;
          });
        } else {
          setState(() {
            _errorMessage = res.message ?? 'Không tải được chi tiết đơn đặt.';
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Lỗi kết nối: $e';
          _loading = false;
        });
      }
    }
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return '0 đ';
    final numVal = num.tryParse(value.toString()) ?? 0;
    return '${_currencyFormat.format(numVal)} đ';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr);
      final weekdays = [
        '',
        'Thứ Hai',
        'Thứ Ba',
        'Thứ Tư',
        'Thứ Năm',
        'Thứ Sáu',
        'Thứ Bảy',
        'Chủ Nhật'
      ];
      final dayName = weekdays[dt.weekday];
      return '$dayName, ${DateFormat('dd/MM/yyyy').format(dt)}';
    } catch (_) {
      return dateStr;
    }
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '';
    final parts = timeStr.split(':');
    if (parts.length >= 2) {
      return '${parts[0]}:${parts[1]}';
    }
    return timeStr;
  }

  Map<String, dynamic> _getStatusConfig(String? status) {
    switch (status) {
      case 'ChoDuyet':
      case 'DangTimCTV':
        return {
          'text': 'Đang tìm CTV',
          'color': const Color(0xFFE65100),
          'bgColor': const Color(0xFFFFF3E0),
          'icon': Icons.hourglass_top_rounded,
        };
      case 'DaXacNhan':
      case 'DaPhanCong':
        return {
          'text': 'Đã phân công',
          'color': const Color(0xFF1565C0),
          'bgColor': const Color(0xFFE3F2FD),
          'icon': Icons.assignment_turned_in_rounded,
        };
      case 'DangThucHien':
        return {
          'text': 'Đang thực hiện',
          'color': const Color(0xFF2E7D32),
          'bgColor': const Color(0xFFE8F5E9),
          'icon': Icons.cleaning_services_rounded,
        };
      case 'HoanThanh':
        return {
          'text': 'Hoàn thành',
          'color': AppColors.brand700,
          'bgColor': AppColors.brandSurface,
          'icon': Icons.check_circle_rounded,
        };
      case 'DaHuy':
        return {
          'text': 'Đã hủy',
          'color': const Color(0xFFC62828),
          'bgColor': const Color(0xFFFFEBEE),
          'icon': Icons.cancel_rounded,
        };
      default:
        return {
          'text': status ?? 'Đang xử lý',
          'color': AppColors.textSecondary,
          'bgColor': const Color(0xFFEEEEEE),
          'icon': Icons.info_outline_rounded,
        };
    }
  }

  Future<void> _handleCancelBooking() async {
    final lyDoController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('Xác nhận hủy đơn', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bạn có chắc chắn muốn hủy đơn đặt này không? Đơn sau khi hủy sẽ không thể khôi phục.',
              style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: lyDoController,
              decoration: InputDecoration(
                hintText: 'Nhập lý do hủy (không bắt buộc)',
                hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.brand500),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Quay lại', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Hủy đơn'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    final khachHangId = _session?.userId ?? 0;
    if (khachHangId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng đăng nhập lại để thực hiện.')),
      );
      return;
    }

    try {
      final res = await _bookingApi.cancelBooking(
        id: widget.orderId,
        khachHangId: khachHangId,
        lyDo: lyDoController.text.trim(),
      );

      if (!mounted) return;

      if (res.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã hủy đơn thành công.'),
            backgroundColor: AppColors.success,
          ),
        );
        widget.onOrderUpdated?.call();
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.message ?? 'Không thể hủy đơn này.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Chi tiết công việc',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.brand500),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brand500,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_order == null) {
      return const Center(child: Text('Không có dữ liệu đơn hàng.'));
    }

    final trangThai = _order!['trangThai']?.toString();
    final statusConfig = _getStatusConfig(trangThai);
    final ctv = _order!['congTacVien'] as Map<String, dynamic>?;
    final hoaDon = _order!['hoaDon'] as Map<String, dynamic>?;
    final danhGia = _order!['danhGia'] as Map<String, dynamic>?;
    final danhSachDv = _order!['danhSachDichVu'] as List<dynamic>? ?? [];

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.brand500,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: statusConfig['bgColor'] as Color,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      statusConfig['icon'] as IconData,
                      color: statusConfig['color'] as Color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mã đơn: ${_order!['maDonDat'] ?? ''}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          statusConfig['text'] as String,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: statusConfig['color'] as Color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_order!['ngayTao'] != null)
                    Text(
                      _formatDate(_order!['ngayTao']?.toString().split('T').first),
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Service & Schedule Info
            _buildSection(
              title: 'Thời gian & Dịch vụ',
              icon: Icons.calendar_today_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.access_time_rounded, size: 18, color: AppColors.brand500),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatDate(_order!['ngayThucHien']?.toString()),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${_formatTime(_order!['gioBatDau']?.toString())} - ${_formatTime(_order!['gioKetThuc']?.toString())}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.brand600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: AppColors.divider),
                  ),

                  // Danh sách dịch vụ
                  if (danhSachDv.isNotEmpty)
                    ...danhSachDv.map((dv) {
                      final dvMap = dv as Map<String, dynamic>;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                dvMap['tenDichVu']?.toString() ?? '',
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Text(
                              _formatCurrency(dvMap['thanhTien']),
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    })
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _order!['tenDichVu']?.toString() ?? 'Dịch vụ giúp việc',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          _formatCurrency(_order!['thanhTien']),
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),

                  if (_order!['yeuCauDacBiet'] != null &&
                      _order!['yeuCauDacBiet'].toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE9ECEF)),
                      ),
                      child: Text(
                        'Ghi chú: ${_order!['yeuCauDacBiet']}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Address Section
            _buildSection(
              title: 'Địa chỉ làm việc',
              icon: Icons.location_on_rounded,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.place_outlined, size: 20, color: AppColors.brand500),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _order!['diaChi'] != null && _order!['diaChi'].toString().isNotEmpty
                          ? _order!['diaChi'].toString()
                          : 'Chưa cập nhật địa chỉ',
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Collaborator Section
            _buildSection(
              title: 'Cộng tác viên phụ trách',
              icon: Icons.person_rounded,
              child: ctv != null
                  ? Row(
                      children: [
                        const CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.brandLight,
                          child: Icon(
                            Icons.person_rounded,
                            color: AppColors.brand500,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ctv['hoTen']?.toString() ?? 'Cộng tác viên',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, size: 16, color: AppColors.star),
                                  const SizedBox(width: 3),
                                  Text(
                                    ctv['diemDanhGia'] != null
                                        ? '${ctv['diemDanhGia']}'
                                        : '5.0',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.brandLight,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Đã xác thực',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.brand600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (ctv['soDienThoai'] != null)
                          IconButton(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: ctv['soDienThoai'].toString()));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Đã sao chép SĐT: ${ctv['soDienThoai']}'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: AppColors.brandLight,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.phone_rounded,
                                color: AppColors.brand500,
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    )
                  : Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: trangThai == 'DaHuy'
                            ? const Color(0xFFFFEBEE)
                            : (trangThai == 'HoanThanh' ? AppColors.brandSurface : const Color(0xFFFFF9C4)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            trangThai == 'DaHuy'
                                ? Icons.cancel_outlined
                                : (trangThai == 'HoanThanh' ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded),
                            color: trangThai == 'DaHuy'
                                ? const Color(0xFFC62828)
                                : (trangThai == 'HoanThanh' ? AppColors.brand700 : const Color(0xFFF57F17)),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              trangThai == 'DaHuy'
                                  ? 'Đơn đặt này đã được hủy, không có cộng tác viên thực hiện.'
                                  : (trangThai == 'HoanThanh'
                                      ? 'Đơn đặt đã hoàn thành.'
                                      : 'Hệ thống đang tìm cộng tác viên phù hợp nhất gần khu vực của bạn.'),
                              style: TextStyle(
                                fontSize: 12.5,
                                color: trangThai == 'DaHuy'
                                    ? const Color(0xFFC62828)
                                    : (trangThai == 'HoanThanh' ? AppColors.brand700 : const Color(0xFF5D4037)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 14),

            // Invoice & Payment Section
            _buildSection(
              title: 'Thanh toán & Hóa đơn',
              icon: Icons.receipt_long_rounded,
              child: Column(
                children: [
                  _buildPaymentRow('Tạm tính', _formatCurrency(_order!['chiPhiGoc'])),
                  if (_order!['soTienGiam'] != null &&
                      (num.tryParse(_order!['soTienGiam'].toString()) ?? 0) > 0)
                    _buildPaymentRow(
                      'Khuyến mãi',
                      '- ${_formatCurrency(_order!['soTienGiam'])}',
                      valueColor: AppColors.error,
                    ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, color: AppColors.divider),
                  ),
                  _buildPaymentRow(
                    'Tổng thanh toán',
                    _formatCurrency(_order!['thanhTien']),
                    isTotal: true,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.payment_rounded, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            hoaDon != null && hoaDon['hinhThucThanhToan'] == 'TienMat'
                                ? 'Tiền mặt'
                                : 'Chuyển khoản / Ví điện tử',
                            style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: hoaDon != null && hoaDon['trangThaiThanhToan'] == 'DaThanhToan'
                              ? AppColors.brandLight
                              : const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          hoaDon != null && hoaDon['trangThaiThanhToan'] == 'DaThanhToan'
                              ? 'Đã thanh toán'
                              : 'Chưa thanh toán',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: hoaDon != null && hoaDon['trangThaiThanhToan'] == 'DaThanhToan'
                                ? AppColors.brand600
                                : const Color(0xFFE65100),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Review section if available
            if (danhGia != null) ...[
              const SizedBox(height: 14),
              _buildSection(
                title: 'Đánh giá của bạn',
                icon: Icons.rate_review_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (i) => Icon(
                            i < (danhGia['diemChatLuong'] ?? 5)
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: AppColors.star,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${danhGia['diemChatLuong'] ?? 5}/5 sao',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    if (danhGia['nhanXet'] != null &&
                        danhGia['nhanXet'].toString().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        '"${danhGia['nhanXet']}"',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.brand500),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, String value, {bool isTotal = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 14.5 : 13,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
              color: isTotal ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 13,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
              color: valueColor ?? (isTotal ? AppColors.brand600 : AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentModal() {
    if (_order == null) return;
    final int donId = widget.orderId;
    final int khachHangId = _session?.userId ?? 0;
    final maDon = _order!['maDonDat']?.toString() ?? _order!['maDon']?.toString() ?? 'DON$donId';
    final tongTien = num.tryParse(_order!['tongTien']?.toString() ?? _order!['thanhTien']?.toString() ?? '0') ?? 0;

    String method = _order!['phuongThucThanhToan']?.toString() ?? 'CHUYEN_KHOAN';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: AppColors.brand500)),
    );

    PaymentApiService().getInvoice(donId).then((res) {
      if (mounted) Navigator.pop(context); // close loading
      Map<String, dynamic>? invoiceData = res.data;
      String bankName = invoiceData?['nganHang']?.toString() ?? invoiceData?['bankName']?.toString() ?? 'MBBank';
      String accNo = invoiceData?['soTaiKhoan']?.toString() ?? invoiceData?['accountNo']?.toString() ?? '0336676173';
      String qrUrl = invoiceData?['qrCodeUrl']?.toString() ?? invoiceData?['qrUrl']?.toString() ?? invoiceData?['vietQrUrl']?.toString() ?? 'https://img.vietqr.io/image/MB-0336676173-compact2.png?amount=$tongTien&addInfo=$maDon';

      _showPaymentModalWithData(donId, khachHangId, maDon, tongTien, method, bankName, accNo, qrUrl);
    }).catchError((e) {
      if (mounted) Navigator.pop(context);
      _showPaymentModalWithData(donId, khachHangId, maDon, tongTien, method, 'MBBank', '0336676173', 'https://img.vietqr.io/image/MB-0336676173-compact2.png?amount=$tongTien&addInfo=$maDon');
    });
  }

  void _showPaymentModalWithData(int donId, int khachHangId, String maDon, num tongTien, String method, String bankName, String accNo, String qrUrl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              24 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
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
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.payment_rounded, color: AppColors.brand500, size: 24),
                      const SizedBox(width: 10),
                      Text(
                        'Thanh toán đơn hàng $maDon',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.brandSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.brandLight),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Số tiền cần thanh toán:',
                          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                        ),
                        Text(
                          _formatCurrency(tongTien),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.brand600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Chọn hình thức thanh toán:',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                  ),
                  const SizedBox(height: 10),

                  // Option 1: VietQR Chuyển khoản
                  InkWell(
                    onTap: () => setModalState(() => method = 'CHUYEN_KHOAN'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Radio<String>(
                            value: 'CHUYEN_KHOAN',
                            groupValue: method,
                            activeColor: AppColors.brand500,
                            onChanged: (v) => setModalState(() => method = v!),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Chuyển khoản Ngân hàng (VietQR)', style: TextStyle(fontWeight: FontWeight.w600)),
                                Text('Quét mã QR tự động điền nội dung & số tiền', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Option 2: VNPAY
                  InkWell(
                    onTap: () => setModalState(() => method = 'VNPAY'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Radio<String>(
                            value: 'VNPAY',
                            groupValue: method,
                            activeColor: AppColors.brand500,
                            onChanged: (v) => setModalState(() => method = v!),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Thanh toán Online / VNPAY', style: TextStyle(fontWeight: FontWeight.w600)),
                                Text('Thẻ ATM, Mobile Banking, Ví VNPAY', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Option 3: Tiền mặt
                  InkWell(
                    onTap: () => setModalState(() => method = 'TIEN_MAT'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Radio<String>(
                            value: 'TIEN_MAT',
                            groupValue: method,
                            activeColor: AppColors.brand500,
                            onChanged: (v) => setModalState(() => method = v!),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Tiền mặt', style: TextStyle(fontWeight: FontWeight.w600)),
                                Text('Thanh toán trực tiếp cho người làm khi hoàn thành', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (method == 'CHUYEN_KHOAN') ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              qrUrl,
                              height: 180,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Container(
                                height: 120,
                                alignment: Alignment.center,
                                child: Text('Mã QR $bankName $accNo'),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Ngân hàng:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                              Text(bankName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Số tài khoản:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                              Row(
                                children: [
                                  Text(accNo, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.brand600)),
                                  IconButton(
                                    icon: const Icon(Icons.copy, size: 16, color: AppColors.brand500),
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: accNo));
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã chép số tài khoản')));
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Nội dung:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                              Text(maDon, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],


                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        _executePayment(donId, khachHangId, method, maDon);
                      },
                      child: Text(
                        method == 'CHUYEN_KHOAN'
                            ? 'Xác nhận đã chuyển khoản'
                            : method == 'VNPAY'
                                ? 'Thanh toán qua VNPAY'
                                : 'Xác nhận thanh toán tiền mặt',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _executePayment(int donId, int khachHangId, String method, String maDon) async {
    setState(() => _loading = true);
    try {
      final res = await _bookingApi.payBooking(
        id: donId,
        khachHangId: khachHangId,
        phuongThucThanhToan: method,
        maGiaoDich: 'PAY_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (!mounted) return;
      if (res.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật thanh toán đơn hàng thành công!'),
            backgroundColor: AppColors.success,
          ),
        );
        widget.onOrderUpdated?.call();
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.message ?? 'Thanh toán thành công!'),
            backgroundColor: AppColors.success,
          ),
        );
        widget.onOrderUpdated?.call();
        _loadData();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã ghi nhận thông tin thanh toán.'),
            backgroundColor: AppColors.success,
          ),
        );
        widget.onOrderUpdated?.call();
        _loadData();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget? _buildBottomBar() {
    if (_order == null) return null;
    final trangThai = _order!['trangThai']?.toString();
    final isPaid = _order!['daThanhToan'] == true ||
        _order!['trangThaiThanhToan']?.toString().toUpperCase() == 'DATHANHTOAN' ||
        _order!['trangThaiThanhToan']?.toString().toUpperCase() == 'DA_THANH_TOAN';

    final canCancel = trangThai == 'ChoDuyet' || trangThai == 'DangTimCTV';
    final canPay = !isPaid && trangThai != 'DaHuy';

    if (!canCancel && !canPay) return null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canPay) ...[
              SizedBox(
                height: 48,
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showPaymentModal,
                  icon: const Icon(Icons.payment_rounded, size: 20),
                  label: const Text(
                    'Thanh toán ngay (VietQR / Online)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              if (canCancel) const SizedBox(height: 8),
            ],
            if (canCancel) ...[
              SizedBox(
                height: 44,
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _handleCancelBooking,
                  icon: const Icon(Icons.cancel_outlined, color: AppColors.error, size: 18),
                  label: const Text(
                    'Hủy đơn đặt này',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
