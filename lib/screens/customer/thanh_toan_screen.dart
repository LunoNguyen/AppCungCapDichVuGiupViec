import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/app_colors.dart';
import '../../services/booking_api_service.dart';
import '../../services/catalog_ui.dart';
import '../../services/dong_ho.dart';
import '../../services/payment_api_service.dart';
import '../../services/session_service.dart';
import 'order_detail_screen.dart';

/// Màn thanh toán chuyển khoản của một đơn: mã VietQR, thông tin tài khoản, đồng hồ hạn thanh toán.
/// "Tôi đã chuyển khoản" ghi nhận thanh toán (cùng hàm với website); xong thì sang chi tiết đơn.
class ThanhToanScreen extends StatefulWidget {
  final int donDatId;

  /// Mở từ chi tiết đơn: xong thì quay về màn đó (pop) thay vì mở chồng thêm một chi tiết đơn.
  final bool moTuChiTiet;

  const ThanhToanScreen({super.key, required this.donDatId, this.moTuChiTiet = false});

  @override
  State<ThanhToanScreen> createState() => _ThanhToanScreenState();
}

class _ThanhToanScreenState extends State<ThanhToanScreen> with WidgetsBindingObserver {
  final _bookingApi = BookingApiService();

  Map<String, dynamic>? _hoaDon;
  bool _dangTai = true;
  String? _loi;
  int? _giayMayChu; // số giây còn lại máy chủ trả lúc tải; null = không có hạn
  final _daQua = Stopwatch(); // đồng hồ đơn điệu, vẫn chạy khi app ở nền
  Timer? _dongHo;
  Timer? _hen;
  int _demGiay = 0;
  bool _dangGui = false;
  bool _daRoi = false;

  int? get _giay => DongHo.conLai(_giayMayChu, _daQua.elapsed);

  bool get _hetGio => DongHo.hetGio(_giay);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tai();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dongHo?.cancel();
    _hen?.cancel();
    super.dispose();
  }

  /// Quay lại từ app ngân hàng: lấy lại số giây và trạng thái từ máy chủ.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_daRoi && !_dangGui) _tai();
  }

  Future<void> _tai() async {
    setState(() {
      _dangTai = true;
      _loi = null;
    });
    try {
      final kq = await Future.wait([
        PaymentApiService().getInvoice(widget.donDatId),
        _bookingApi.getBookingDetail(widget.donDatId),
      ]);
      if (!mounted) return;
      final hd = kq[0];
      final ct = kq[1];
      if (!hd.success || hd.data == null) {
        setState(() => _loi = hd.message ?? 'Không tải được hóa đơn');
        return;
      }
      // Đã trả hoặc đơn đã hủy: không còn gì để thanh toán
      if (hd.data!['trangThaiThanhToan'] == 'DaThanhToan' || ct.data?['trangThai'] == 'DaHuy') {
        _moChiTiet();
        return;
      }
      final giay = ct.data?['soGiayConLaiThanhToan'];
      setState(() {
        _hoaDon = hd.data;
        _giayMayChu = giay == null ? null : CatalogUi.toInt(giay);
        _daQua
          ..reset()
          ..start();
      });
      _batDongHo();
    } catch (_) {
      if (mounted) setState(() => _loi = 'Không kết nối được máy chủ');
    } finally {
      if (mounted) setState(() => _dangTai = false);
    }
  }

  void _batDongHo() {
    _dongHo?.cancel();
    if (_giay == null) return;
    if (_hetGio) {
      _henMoChiTiet();
      return;
    }
    _dongHo = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {});
      _demGiay++;
      if (_demGiay % 3 == 0) {
        _kiemTraThanhToanTuDong();
      }
      if (_hetGio) {
        t.cancel();
        _henMoChiTiet();
      }
    });
  }

  /// Tự động thăm dò trạng thái xem SePay webhook đã nhận được tiền chưa
  Future<void> _kiemTraThanhToanTuDong() async {
    if (_dangGui || _daRoi || !mounted) return;
    try {
      final res = await PaymentApiService().getInvoice(widget.donDatId);
      if (!mounted || _daRoi) return;
      if (res.success && res.data != null && res.data!['trangThaiThanhToan'] == 'DaThanhToan') {
        _bao('Thanh toán thành công! Hệ thống đang tìm người làm.', loi: false);
        _moChiTiet();
      }
    } catch (_) {}
  }


  /// Hết hạn: chờ máy chủ tự hủy đơn (cron mỗi phút) rồi mở chi tiết đơn.
  void _henMoChiTiet() {
    _hen ??= Timer(const Duration(seconds: 65), () {
      if (mounted) _moChiTiet();
    });
  }

  void _moChiTiet() {
    if (_daRoi || !mounted) return;
    _daRoi = true;
    if (widget.moTuChiTiet) {
      Navigator.pop(context);
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: widget.donDatId)),
    );
  }

  void _bao(String msg, {bool loi = true}) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg), backgroundColor: loi ? AppColors.error : AppColors.success));

  Future<void> _daChuyenKhoan() async {
    setState(() => _dangGui = true);
    try {
      final res = await _bookingApi.confirmTransfer(widget.donDatId);
      if (!mounted) return;
      if (res.success) {
        _bao(res.message ?? 'Đã ghi nhận thanh toán.', loi: false);
        _moChiTiet();
        return;
      }
      final msg = res.message ?? 'Không ghi nhận được thanh toán';
      _bao(msg.startsWith('Lỗi kết nối') ? 'Không kết nối được máy chủ' : msg);
      if (msg.contains('đã được thanh toán') || msg.contains('đã bị hủy')) _moChiTiet();
    } finally {
      if (mounted) setState(() => _dangGui = false);
    }
  }

  Future<void> _giaLapThanhToan() async {
    setState(() => _dangGui = true);
    try {
      final res = await PaymentApiService().mockPay(widget.donDatId);
      if (!mounted) return;
      if (res.success) {
        _bao('Giả lập thanh toán thành công!', loi: false);
        _moChiTiet();
      } else {
        _bao(res.message ?? 'Giả lập thanh toán không thành công');
      }
    } catch (_) {
      if (mounted) _bao('Không kết nối được máy chủ');
    } finally {
      if (mounted) setState(() => _dangGui = false);
    }
  }


  Future<void> _huyDon() async {
    final dongY = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy đơn?'),
        content: const Text('Đơn chưa thanh toán sẽ bị hủy.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Không')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hủy đơn')),
        ],
      ),
    );
    if (dongY != true || !mounted) return;
    final session = await SessionService.load();
    if (!mounted) return;
    if (session == null) {
      _bao('Vui lòng đăng nhập lại');
      return;
    }
    setState(() => _dangGui = true);
    try {
      final res = await _bookingApi.cancelBooking(
        id: widget.donDatId,
        khachHangId: session.userId,
        lyDo: 'Khách hủy khi chưa chuyển khoản',
      );
      if (!mounted) return;
      if (res.success) {
        _bao('Đã hủy đơn', loi: false);
        _moChiTiet();
      } else {
        _bao(res.message ?? 'Không hủy được đơn');
      }
    } finally {
      if (mounted) setState(() => _dangGui = false);
    }
  }

  void _saoChep(String nhan, String giaTri) {
    Clipboard.setData(ClipboardData(text: giaTri));
    _bao('Đã sao chép $nhan', loi: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Thanh toán'),
        actions: [
          TextButton(onPressed: _moChiTiet, child: const Text('Xem đơn')),
        ],
      ),
      body: _dangTai
          ? const Center(child: CircularProgressIndicator(color: AppColors.brand500))
          : _loi != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_loi!, style: const TextStyle(color: AppColors.error)),
                      TextButton(onPressed: _tai, child: const Text('Thử lại')),
                    ],
                  ),
                )
              : _noiDung(),
    );
  }

  Widget _noiDung() {
    final hd = _hoaDon!;
    final nh = Map<String, dynamic>.from((hd['thongTinNganHang'] as Map?) ?? const {});
    final qr = nh['qrCodeUrl']?.toString();
    final soTien = nh['soTien'] ?? hd['tongThanhToan'];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _hetGio && _giay != null ? AppColors.orangeLight : AppColors.brandSurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.timer_outlined, color: AppColors.brand600),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _giay == null
                      ? 'Đơn ${hd['maDonDat'] ?? ''}'
                      : _hetGio
                          ? 'Đã hết thời gian thanh toán'
                          : 'Còn ${DongHo.mmss(_giay)} để thanh toán',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.brand600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              if (qr != null && qr.isNotEmpty)
                Image.network(
                  qr,
                  width: 220,
                  height: 220,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const SizedBox(
                    height: 80,
                    child: Center(child: Text('Không tải được mã QR', style: TextStyle(color: AppColors.textSecondary))),
                  ),
                ),
              const SizedBox(height: 12),
              _dong('Số tiền', CatalogUi.money(soTien), dam: true),
              _dong('Ngân hàng', nh['nganHang']?.toString() ?? '—'),
              _dong('Số tài khoản', nh['soTaiKhoan']?.toString() ?? '—', saoChep: true),
              _dong('Chủ tài khoản', nh['chuTaiKhoan']?.toString() ?? '—'),
              _dong('Nội dung', nh['noiDungChuyenKhoan']?.toString() ?? '—', saoChep: true),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _dangGui || (_giay != null && _hetGio) ? null : _daChuyenKhoan,
            child: _dangGui
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Tôi đã chuyển khoản'),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 48,
          child: OutlinedButton(onPressed: _dangGui ? null : _huyDon, child: const Text('Hủy đơn')),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: _dangGui || (_giay != null && _hetGio) ? null : _giaLapThanhToan,
          icon: const Icon(Icons.science_outlined, size: 18, color: Color(0xFF16A34A)),
          label: const Text(
            'Giả lập thanh toán thành công (Test miễn phí)',
            style: TextStyle(color: Color(0xFF16A34A), fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );

  }

  Widget _dong(String nhan, String giaTri, {bool saoChep = false, bool dam = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 105,
              child: Text(nhan, style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary)),
            ),
            Expanded(
              child: Text(
                giaTri,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: dam ? 16 : 14,
                  fontWeight: dam ? FontWeight.w800 : FontWeight.w600,
                  color: dam ? AppColors.brand600 : AppColors.textPrimary,
                ),
              ),
            ),
            if (saoChep)
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Sao chép',
                onPressed: () => _saoChep(nhan.toLowerCase(), giaTri),
                icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.brand500),
              ),
          ],
        ),
      );
}
