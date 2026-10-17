import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/app_colors.dart';
import '../../services/app_realtime.dart';
import '../../services/booking_api_service.dart';
import '../../services/dong_ho.dart';
import '../../services/session_service.dart';
import '../../widgets/danh_gia_don.dart';
import 'thanh_toan_screen.dart';

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

class _OrderDetailScreenState extends State<OrderDetailScreen> with WidgetsBindingObserver {
  final _bookingApi = BookingApiService();
  final _currencyFormat = NumberFormat('#,###', 'vi_VN');

  bool _loading = true;
  String? _errorMessage;
  Map<String, dynamic>? _order;
  UserSession? _session;

  // Đồng hồ đếm lùi từ số giây máy chủ trả: hạn chuyển khoản, hạn có người nhận
  int? _giayThanhToanGoc;
  int? _giayNhanGoc;
  final _daQua = Stopwatch(); // đồng hồ đơn điệu từ lúc tải đơn, vẫn chạy khi app ở nền
  int? get _giayThanhToan => DongHo.conLai(_giayThanhToanGoc, _daQua.elapsed);
  int? get _giayNhan => DongHo.conLai(_giayNhanGoc, _daQua.elapsed);
  Timer? _dongHo;
  Timer? _henTaiLai;
  StreamSubscription<String>? _realtime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
    // Có cộng tác viên nhận, đơn tự hủy, thanh toán xong... thì tải lại
    _realtime = AppRealtime.instance.suKien.listen((_) => _taiLaiDon());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dongHo?.cancel();
    _henTaiLai?.cancel();
    _realtime?.cancel();
    super.dispose();
  }

  /// Quay lại app (vd. từ app ngân hàng): tải lại đơn để đồng hồ và trạng thái khớp máy chủ.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _order != null) _taiLaiDon();
  }

  static int? _giay(dynamic v) => v == null ? null : int.tryParse(v.toString());

  /// Đọc số giây còn lại từ đơn vừa tải và chạy đồng hồ; về 0 thì 65 giây sau tải lại
  /// (máy chủ tự hủy đơn quá hạn mỗi phút).
  void _capNhatDongHo() {
    _dongHo?.cancel();
    _giayThanhToanGoc = _giay(_order?['soGiayConLaiThanhToan']);
    _giayNhanGoc = _giay(_order?['soGiayConLaiNhan']);
    _daQua
      ..reset()
      ..start();
    if (_giayThanhToan == null && _giayNhan == null) return;
    if (DongHo.hetGio(_giayThanhToan) && DongHo.hetGio(_giayNhan)) {
      _henTai();
      return;
    }
    _dongHo = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {});
      if (DongHo.hetGio(_giayThanhToan) && DongHo.hetGio(_giayNhan)) {
        t.cancel();
        _henTai();
      }
    });
  }

  void _henTai() {
    _henTaiLai?.cancel();
    _henTaiLai = Timer(const Duration(seconds: 65), () {
      if (mounted) _taiLaiDon();
    });
  }

  Future<void> _moThanhToan() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ThanhToanScreen(donDatId: widget.orderId, moTuChiTiet: true)),
    );
    if (mounted) _taiLaiDon();
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
            _capNhatDongHo();
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

  /// Tải lại đơn mà không hiện màn chờ (sau khi đánh giá / bình luận), giữ nguyên vị trí cuộn.
  Future<void> _taiLaiDon() async {
    final res = await _bookingApi.getBookingDetail(widget.orderId);
    if (mounted && res.success && res.data != null) {
      setState(() {
        _order = res.data;
        _capNhatDongHo();
      });
      widget.onOrderUpdated?.call();
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
    final statusConfig = _giayThanhToan != null
        ? {
            'text': 'Chờ thanh toán',
            'color': const Color(0xFFE65100),
            'bgColor': const Color(0xFFFFF3E0),
            'icon': Icons.qr_code_2_rounded,
          }
        : _getStatusConfig(trangThai);
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
            if (_giayThanhToan != null) ...[
              const SizedBox(height: 10),
              _bannerCho(
                'Chờ thanh toán · còn ${DongHo.mmss(_giayThanhToan)}',
                'Đơn chuyển khoản cần thanh toán trong ${_order!['soPhutThanhToan'] ?? 15} phút, quá hạn đơn sẽ tự hủy.',
              ),
            ] else if (_giayNhan != null) ...[
              const SizedBox(height: 10),
              _bannerCho(
                'Đang tìm cộng tác viên · còn ${DongHo.mmss(_giayNhan)}',
                'Nếu sau ${_order!['soPhutNhanDon'] ?? 15} phút chưa có ai nhận, đơn sẽ tự hủy và bạn không mất phí.',
              ),
            ],
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
                            // Gói tháng: các thứ đã chọn và lịch các buổi (máy chủ tính, xem LichGoiThang)
                            if (_order!['lichBuoi'] is List && (_order!['lichBuoi'] as List).isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Gói ${(_order!['lichBuoi'] as List).length} buổi · ${_order!['thuTrongTuanText'] ?? ''}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                (_order!['lichBuoi'] as List).map((n) {
                                  final d = DateTime.tryParse(n.toString());
                                  return d == null ? n.toString() : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
                                }).join(' · '),
                                style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
                              ),
                            ],
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
                                      : (_giayThanhToan != null
                                          ? 'Đơn đang chờ bạn chuyển khoản. Hệ thống sẽ tìm cộng tác viên ngay sau khi nhận được thanh toán.'
                                          : 'Hệ thống đang tìm cộng tác viên phù hợp nhất gần khu vực của bạn.')),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.payment_rounded, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _dongThanhToan(hoaDon),
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                  if (trangThai == 'DaHuy' && hoaDon?['trangThaiThanhToan'] == 'DaThanhToan')
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        'bTaskee sẽ liên hệ hoàn tiền trong 1–3 ngày làm việc.',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFFE65100)),
                      ),
                    ),
                ],
              ),
            ),

            // Đánh giá + trao đổi với CSKH sau khi đơn hoàn thành
            if (trangThai == 'HoanThanh' && _session != null) ...[
              const SizedBox(height: 14),
              _buildSection(
                title: danhGia == null ? 'Đánh giá buổi làm' : 'Đánh giá của bạn',
                icon: Icons.rate_review_rounded,
                child: DanhGiaDon(
                  donDatId: widget.orderId,
                  khachHangId: _session!.userId,
                  danhGia: danhGia,
                  onChanged: _taiLaiDon,
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

  /// Dòng phương thức thanh toán của đơn.
  String _dongThanhToan(Map<String, dynamic>? hoaDon) {
    if (hoaDon == null) return 'Chưa có hóa đơn';
    if (hoaDon['hinhThucThanhToan'] == 'TienMat') return 'Tiền mặt – trả cho cộng tác viên sau buổi làm';
    final tt = hoaDon['trangThaiThanhToan']?.toString();
    return 'Chuyển khoản – ${tt == 'DaThanhToan' ? 'Đã thanh toán' : tt == 'DaHoanTien' ? 'Đã hoàn tiền' : 'Chưa thanh toán'}';
  }

  Widget _bannerCho(String tieuDe, String moTa) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.timer_outlined, color: Color(0xFFE65100)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tieuDe,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: Color(0xFFE65100))),
                  const SizedBox(height: 4),
                  Text(moTa, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.35)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget? _buildBottomBar() {
    if (_order == null) return null;
    final trangThai = _order!['trangThai']?.toString();

    // Hủy được khi chưa bắt đầu làm (kể cả đã có cộng tác viên nhận); máy chủ kiểm tra giờ bắt đầu
    final canCancel = trangThai == 'ChoDuyet' || trangThai == 'DangTimCTV' || trangThai == 'DaXacNhan';
    final canPay = _giayThanhToan != null && !DongHo.hetGio(_giayThanhToan) && trangThai != 'DaHuy';

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
                  onPressed: _moThanhToan,
                  icon: const Icon(Icons.qr_code_2_rounded, size: 20),
                  label: const Text(
                    'Thanh toán ngay',
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
