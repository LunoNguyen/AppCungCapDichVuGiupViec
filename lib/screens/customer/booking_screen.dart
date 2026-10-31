import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../services/address_api_service.dart';
import '../../services/booking_api_service.dart';
import '../../services/buoc_dat.dart';
import '../../services/catalog_ui.dart';
import '../../services/gio_hang.dart';
import '../../services/lich_goi_thang.dart';
import '../../services/nhom_dich_vu.dart';
import '../../services/rang_buoc_ngay_dat.dart';
import '../../services/session_service.dart';
import '../../widgets/lich_thang.dart';
import 'address_book_screen.dart';
import 'dat_dich_vu/bang_khuyen_mai.dart';
import 'dat_dich_vu/buoc_thanh_toan.dart';
import 'dat_dich_vu/buoc_thoi_gian.dart';
import 'dat_dich_vu/buoc_xac_nhan.dart';
import 'dat_dich_vu/dich_vu_da_chon.dart';
import 'dat_dich_vu/thanh_buoc.dart';
import 'order_detail_screen.dart';
import 'thanh_toan_screen.dart';

/// Màn đặt dịch vụ, giống website: Thời gian → Xác nhận → Thanh toán.
/// Mở từ trang chi tiết dịch vụ với biến thể (hình thức + thời lượng / gói) đã chọn ở đó;
/// muốn đổi dịch vụ thì bấm "Đổi" hoặc Quay lại ở bước đầu để về trang chi tiết.
/// Mở từ giỏ hàng với [dichVuNhieu] (≥ 2 dịch vụ theo lần): một lịch, một địa chỉ, một hóa đơn;
/// các dịch vụ làm song song từ cùng giờ bắt đầu, dịch vụ lâu nhất phải xong trước 20:00 (giống web).
class BookingScreen extends StatefulWidget {
  final Map<String, dynamic> service;
  final List<MonGio>? dichVuNhieu;

  const BookingScreen({super.key, required this.service, this.dichVuNhieu});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  late int _buoc;
  late int _daToi;

  // Dịch vụ, hình thức và biến thể (thời lượng / gói) đã chọn ở trang chi tiết
  NhomDichVu? _nhom;
  String _loai = 'TheoLan';
  int? _dichVuId;

  // Bước 3: thời gian, gói tháng, địa chỉ
  DateTime? _ngay;
  TimeOfDay? _gio;
  Set<int> _thuGoi = {2, 4, 6, 7}; // mặc định T3, T5, T7, CN
  UserSession? _session;
  DiaChi? _diaChi;
  bool _dangTaiDiaChi = true;
  final _ghiChu = TextEditingController();

  // Bước 4: giá do máy chủ tính (gồm khuyến mãi) và mã ưu đãi
  final _bookingApi = BookingApiService();
  Map<String, dynamic>? _gia;
  bool _dangTinhGia = false;
  bool _loiGia = false;
  final _maController = TextEditingController();
  String? _maApDung; // mã máy chủ đã chấp nhận (có giảm)
  bool _dangKiemMa = false;

  // Bước 5: phương thức thanh toán ("TienMat" | "ChuyenKhoan") và gửi đơn
  String? _hinhThucTT;
  bool _dangGui = false;
  static const _phutThanhToan = 15;

  // Khung giờ bắt đầu 07:00 → 17:00
  static final List<TimeOfDay> _khungGio = List.generate(11, (i) => TimeOfDay(hour: 7 + i, minute: 0));

  int get _dichVuIdGoc => CatalogUi.toInt(widget.service['dichVuId'] ?? widget.service['id']);

  // Đặt nhiều dịch vụ từ giỏ hàng
  bool get _nhieu => (widget.dichVuNhieu?.length ?? 0) >= 2;
  List<int>? get _idsNhieu => _nhieu ? [for (final m in widget.dichVuNhieu!) m.id] : null;
  int get _tongPhutNhieu => _nhieu
      ? GioHang.phutDaiNhat(widget.dichVuNhieu!)
      : 0;
  static const _phutXongMuonNhat = 20 * 60; // các dịch vụ phải xong trước 20:00 (DatNhieuDichVu)

  DuLieuDat get _duLieu => DuLieuDat(
        nhom: _nhom,
        loaiHinhDat: _loai,
        dichVuId: _dichVuId,
        daChonGio: _gio != null && _gioHopLe(_gio!),
        goiDuBuoi: _loiLichGoi == null,
        coDiaChiNao: _diaChi != null,
        coDiaChiTrongKhuVuc: _diaChi?.coKhuVuc ?? false,
        hinhThucThanhToan: _hinhThucTT,
        loiNgayGio: _gio == null
            ? null
            : RangBuocNgayDat.loiNgayDat(_loai, _ngayBuoiDau, _gio!.hour, _gio!.minute, DateTime.now()),
      );

  bool get _laGoi => _loai == 'GoiThang';

  DateTime get _homNay => LichThang.chiNgay(DateTime.now());

  int get _soBuoiGoi => LichGoiThang.soBuoi(_bienThe?['soBuoiGoi'], _bienThe?['tenDichVu']?.toString());

  List<DateTime> get _lichGoi => LichGoiThang.tinhLich(_ngay ?? _homNay, _thuGoi, _soBuoiGoi);

  String? get _loiLichGoi => _laGoi ? LichGoiThang.loiThieu(_lichGoi, _soBuoiGoi, _thuGoi) : null;

  /// Ngày của buổi đầu tiên: gói tháng là ngày đầu khớp thứ đã chọn, theo lần là ngày đã chọn.
  DateTime? get _ngayBuoiDau => _laGoi && _lichGoi.isNotEmpty ? _lichGoi.first : _ngay;

  /// Giờ bắt đầu phải sau hiện tại ít nhất 1 giờ (cùng quy tắc với website và máy chủ).
  bool _gioHopLe(TimeOfDay t) {
    final ngay = _ngayBuoiDau;
    if (ngay == null) return false;
    final luc = DateTime(ngay.year, ngay.month, ngay.day, t.hour, t.minute);
    if (_nhieu && t.hour * 60 + t.minute + _tongPhutNhieu > _phutXongMuonNhat) return false;
    return !luc.isBefore(DateTime.now().add(const Duration(hours: 1)));
  }

  /// Giờ đang chọn không còn hợp lệ (đổi ngày, đổi thứ) thì chuyển sang giờ hợp lệ đầu tiên.
  void _chinhGio() {
    if (_gio != null && _gioHopLe(_gio!)) return;
    final hop = _khungGio.where(_gioHopLe);
    _gio = hop.isEmpty ? null : hop.first;
  }

  static String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _ddmmyyyy(DateTime d) =>
      '${LichGoiThang.nhanThu[d.weekday - 1]}, ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  static int _tien(dynamic v) => (num.tryParse(v?.toString() ?? '') ?? 0).round();

  Map<String, dynamic>? get _bienThe {
    final n = _nhom;
    if (n == null || _dichVuId == null) return null;
    for (final b in n.bienThe) {
      if (CatalogUi.toInt(b['id']) == _dichVuId) return b;
    }
    return null;
  }

  int get _donGiaThamKhao => _nhieu
      ? widget.dichVuNhieu!.fold(0, (s, m) => s + m.gia)
      : _tien(_bienThe?['donGiaThamKhao']);

  int get _tamTinh => _gia != null ? _tien(_gia!['chiPhiGoc']) : _donGiaThamKhao;

  int get _giam => _gia != null ? _tien(_gia!['soTienGiam']) : 0;

  /// Tổng tiền ở thanh đáy: số máy chủ tính, chưa có thì đơn giá tham khảo của biến thể đang chọn.
  int get _tongTien => _gia != null ? _tien(_gia!['thanhTien']) : _donGiaThamKhao;

  @override
  void initState() {
    super.initState();
    final nhom = NhomDichVu.gom([widget.service]).first;
    _nhom = nhom;
    _loai = BuocDat.loaiMacDinh(nhom, uuTien: widget.service['loaiHinhDat']?.toString());
    _dichVuId = _dichVuIdGoc > 0 ? _dichVuIdGoc : null;
    _buoc = BuocDat.buocDau;
    _daToi = BuocDat.buocDau;
    // Hôm nay nếu còn khung giờ hợp lệ, không thì ngày mai
    _ngay = _homNay;
    if (!_khungGio.any(_gioHopLe)) _ngay = _homNay.add(const Duration(days: 1));
    _chinhGio();
    _taiDiaChi();
  }

  @override
  void dispose() {
    _ghiChu.dispose();
    _maController.dispose();
    super.dispose();
  }

  void _baoLoi(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.error));

  /// Địa chỉ mặc định: ưu đãi địa chỉ mặc định trong khu vực phục vụ, rồi địa chỉ đầu tiên trong khu vực.
  Future<void> _taiDiaChi({int? chonId}) async {
    final session = await SessionService.load();
    DiaChi? chon;
    if (session != null && session.isCustomer) {
      try {
        final res = await AddressApiService().getAddresses(session.userId);
        final ds = res.data ?? const <DiaChi>[];
        final trongKv = ds.where((d) => d.coKhuVuc).toList();
        chon = ds.where((d) => d.id == chonId).firstOrNull ??
            trongKv.where((d) => d.laMacDinh).firstOrNull ??
            trongKv.firstOrNull ??
            ds.where((d) => d.laMacDinh).firstOrNull ??
            ds.firstOrNull;
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _session = session;
      _diaChi = chon;
      _dangTaiDiaChi = false;
    });
  }

  Future<void> _chonDiaChi() async {
    if (_session == null || !_session!.isCustomer) {
      _baoLoi('Vui lòng đăng nhập để chọn địa chỉ làm việc');
      return;
    }
    final chon = await Navigator.push<DiaChi>(
      context,
      MaterialPageRoute(
        builder: (_) => AddressBookScreen(khachHangId: _session!.userId, selectMode: true, selectedId: _diaChi?.id),
      ),
    );
    if (!mounted) return;
    if (chon != null) {
      setState(() => _diaChi = chon);
    } else {
      // Có thể vừa thêm / sửa địa chỉ trong sổ: tải lại, giữ địa chỉ đang chọn
      _taiDiaChi(chonId: _diaChi?.id);
    }
  }

  /// Lựa chọn thay đổi: giá cũ không còn đúng, tính lại khi tới bước 4.
  void _huyGia() {
    _gia = null;
    _loiGia = false;
    _phienGia++;
  }

  /// Tăng mỗi khi lựa chọn đổi: phản hồi giá của lựa chọn cũ về muộn thì bỏ qua.
  int _phienGia = 0;
  int _lanTinh = 0; // lần gọi _tinhGia mới nhất: chỉ lần này được tắt vòng xoay

  void _chonNgay(DateTime d) => setState(() {
        _ngay = d;
        _huyGia();
        _chinhGio();
      });

  void _doiThu(Set<int> thu) => setState(() {
        _thuGoi = thu;
        _huyGia();
        _chinhGio();
      });

  /// Máy chủ tính giá theo biến thể, ngày giờ và mã đang dùng. Mã không còn dùng được thì bỏ và báo lý do.
  Future<void> _tinhGia() async {
    final id = _dichVuId;
    if (id == null) return;
    final phien = ++_phienGia;
    final lan = ++_lanTinh;
    setState(() => _dangTinhGia = true);
    try {
      final res = await _bookingApi.calculatePrice(
        dichVuId: id,
        loaiHinhDat: _loai,
        codeKhuyenMai: _maApDung,
        khachHangId: _session?.userId,
        ngayThucHien: _ngayBuoiDau == null ? null : _ymd(_ngayBuoiDau!),
        gioBatDau: _gio == null ? null : BuocThoiGian.hhmm(_gio!),
        dichVuIds: _idsNhieu,
      );
      if (!mounted || phien != _phienGia) return;
      if (!res.success || res.data == null) {
        setState(() {
          _gia = null;
          _loiGia = true;
        });
        return;
      }
      final data = res.data!;
      String? boMa;
      setState(() {
        _gia = data;
        _loiGia = false;
        if (_maApDung != null && _tien(data['soTienGiam']) <= 0) {
          boMa = data['thongDiepKMDuocApDung']?.toString() ?? 'Mã $_maApDung không còn dùng được cho đơn này.';
          _maApDung = null;
          _maController.clear();
        }
      });
      if (boMa != null) _baoLoi(boMa!);
    } catch (_) {
      if (mounted && phien == _phienGia) {
        setState(() {
          _gia = null;
          _loiGia = true;
        });
      }
    } finally {
      if (mounted && lan == _lanTinh) setState(() => _dangTinhGia = false);
    }
  }

  /// Áp mã: máy chủ tính giá kèm mã; có giảm thì nhận mã, không thì báo câu của máy chủ.
  Future<void> _apDungMa(String code) async {
    final id = _dichVuId;
    code = code.trim().toUpperCase();
    if (id == null || code.isEmpty) return;
    FocusScope.of(context).unfocus();
    final phien = ++_phienGia;
    setState(() => _dangKiemMa = true);
    try {
      final res = await _bookingApi.calculatePrice(
        dichVuId: id,
        loaiHinhDat: _loai,
        codeKhuyenMai: code,
        khachHangId: _session?.userId,
        ngayThucHien: _ngayBuoiDau == null ? null : _ymd(_ngayBuoiDau!),
        gioBatDau: _gio == null ? null : BuocThoiGian.hhmm(_gio!),
        dichVuIds: _idsNhieu,
      );
      if (!mounted) return;
      if (phien != _phienGia) return; // lựa chọn đã đổi trong lúc chờ
      final data = res.data;
      final thongDiep = data?['thongDiepKMDuocApDung']?.toString();
      if (res.success && data != null && _tien(data['soTienGiam']) > 0) {
        setState(() {
          _maApDung = code;
          _maController.text = code;
          _gia = data;
          _loiGia = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(thongDiep ?? 'Đã áp dụng mã $code'),
          backgroundColor: AppColors.success,
        ));
      } else {
        _baoLoi(thongDiep ?? res.message ?? 'Mã không hợp lệ hoặc đã hết hạn');
      }
    } catch (_) {
      if (mounted) _baoLoi('Không kết nối được máy chủ');
    } finally {
      if (mounted) setState(() => _dangKiemMa = false);
    }
  }

  void _boMa() {
    setState(() {
      _maApDung = null;
      _maController.clear();
    });
    _tinhGia();
  }

  Future<void> _moBangKhuyenMai() async {
    final id = _dichVuId;
    if (id == null) return;
    final code = await moBangKhuyenMai(
      context,
      dichVuId: id,
      loaiHinhDat: _loai,
      ngayThucHien: _ngayBuoiDau == null ? null : _ymd(_ngayBuoiDau!),
      gioBatDau: _gio == null ? null : BuocThoiGian.hhmm(_gio!),
      maDangDung: _maApDung,
      dichVuIds: _idsNhieu,
    );
    if (code != null && mounted) _apDungMa(code);
  }

  /// Sang một bước: tới bước 4 thì tính giá.
  void _denBuoc(int b) {
    if (b > _buoc) {
      final chan = BuocDat.buocChan(b, _duLieu);
      if (chan != null) {
        // Thanh bước nhảy qua một bước vừa bị sửa thành chưa hợp lệ: dừng ở bước đó
        _baoLoi(BuocDat.loiBuoc(chan, _duLieu)!);
        setState(() => _buoc = math.max(chan, BuocDat.buocDau));
        return;
      }
    }
    setState(() {
      _buoc = b;
      if (_buoc > _daToi) _daToi = _buoc;
    });
    if (b == 4 && _gia == null) _tinhGia();
  }

  void _tiep() {
    final loi = BuocDat.loiBuoc(_buoc, _duLieu);
    if (loi != null) {
      _baoLoi(loi);
      return;
    }
    if (_buoc >= BuocDat.soBuoc) {
      _guiDon();
      return;
    }
    _denBuoc(BuocDat.buocKe(_buoc));
  }

  /// Gửi đơn (POST /v1/bookings): chuyển khoản → màn QR, tiền mặt → chi tiết đơn.
  /// Máy chủ báo lỗi ngày giờ thì về bước 3, lỗi mã ưu đãi thì về bước 4.
  Future<void> _guiDon() async {
    final session = _session;
    final id = _dichVuId;
    final ngay = _ngayBuoiDau;
    final gio = _gio;
    final hinhThuc = _hinhThucTT;
    if (session == null || !session.isCustomer) {
      _baoLoi('Vui lòng đăng nhập để đặt dịch vụ');
      return;
    }
    final chan = BuocDat.buocChan(BuocDat.soBuoc + 1, _duLieu);
    if (chan != null) {
      _baoLoi(BuocDat.loiBuoc(chan, _duLieu)!);
      setState(() => _buoc = math.max(chan, BuocDat.buocDau));
      return;
    }
    if (id == null || ngay == null || gio == null || hinhThuc == null) return;
    final phut = _nhieu ? _tongPhutNhieu : CatalogUi.toInt(_bienThe?['thoiGianThucHienPhut']);
    final ketThuc = gio.hour * 60 + gio.minute + (phut > 0 ? phut : 120);
    final ghiChu = _ghiChu.text.trim();
    setState(() => _dangGui = true);
    try {
      final res = await _bookingApi.createBooking(
        khachHangId: session.userId,
        dichVuId: id,
        ngayThucHien: _ymd(ngay),
        gioBatDau: BuocThoiGian.hhmm(gio),
        gioKetThuc: BuocThoiGian.hhmm(TimeOfDay(hour: (ketThuc ~/ 60) % 24, minute: ketThuc % 60)),
        diaChiId: _diaChi?.id,
        diaChiChiTiet: _diaChi?.diaChiChiTiet,
        khuVucId: _diaChi?.khuVucId,
        loaiHinhDat: _loai,
        ngayThucHienTrongTuan: _laGoi ? LichGoiThang.maThu(_thuGoi) : null,
        yeuCauDacBiet: ghiChu.isEmpty ? null : ghiChu,
        maKhuyenMai: _maApDung,
        hinhThucThanhToan: hinhThuc,
        dichVuIds: _idsNhieu,
      );
      if (!mounted) return;
      if (!res.success) {
        final msg = res.message ?? 'Không đặt được dịch vụ, vui lòng thử lại';
        if (msg.startsWith('Lỗi kết nối')) {
          // Có thể máy chủ đã tạo đơn nhưng phản hồi về muộn: tránh khách bấm lại tạo đơn trùng
          _baoLoi('Không nhận được phản hồi từ máy chủ. Vui lòng xem "Đơn của tôi" trước khi đặt lại.');
          return;
        }
        _baoLoi(msg);
        final thuong = msg.toLowerCase();
        if (thuong.contains('ngày') || thuong.contains('giờ')) {
          setState(() => _buoc = 3);
        } else if (thuong.contains('mã') || thuong.contains('khuyến mãi')) {
          setState(() => _buoc = 4);
          _tinhGia();
        }
        return;
      }
      // Đặt từ giỏ hàng: bỏ các dịch vụ vừa đặt khỏi giỏ
      final daDat = _idsNhieu ?? (widget.dichVuNhieu != null ? [id] : null);
      if (daDat != null) GioHang.instance.xoaNhieu(daDat);
      final donId = CatalogUi.toInt(res.data?['donDatId'] ?? res.data?['id']);
      if (donId <= 0) {
        _baoLoi('Đã đặt nhưng không đọc được mã đơn, vui lòng xem trong Đơn của tôi');
        return;
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => hinhThuc == 'ChuyenKhoan'
              ? ThanhToanScreen(donDatId: donId)
              : OrderDetailScreen(orderId: donId),
        ),
      );
    } catch (_) {
      if (mounted) _baoLoi('Không kết nối được máy chủ');
    } finally {
      if (mounted) setState(() => _dangGui = false);
    }
  }

  void _lui() {
    if (_buoc <= BuocDat.buocDau) {
      Navigator.pop(context);
      return;
    }
    setState(() => _buoc = BuocDat.buocLui(_buoc));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(title: const Text('Đặt dịch vụ')),
      body: Column(
        children: [
          ThanhBuoc(
            buoc: _buoc,
            daToi: _daToi,
            onChon: _denBuoc,
          ),
          const Divider(height: 1),
          Expanded(child: _noiDungBuoc()),
        ],
      ),
      bottomNavigationBar: _thanhDay(),
    );
  }

  Widget _noiDungBuoc() {
    switch (_buoc) {
      case 3:
        return BuocThoiGian(
          dau: _nhieu
              ? _theNhieuDichVu()
              : _nhom == null
                  ? null
                  : DichVuDaChon(nhom: _nhom!, bienThe: _bienThe, loai: _loai, onDoi: () => Navigator.pop(context)),
          loai: _loai,
          ngay: _ngay,
          ngayDau: _homNay,
          ngayCuoi: RangBuocNgayDat.ngayToiDa(_loai, _homNay),
          onChonNgay: _chonNgay,
          khungGio: _khungGio,
          gio: _gio,
          gioHopLe: _gioHopLe,
          onChonGio: (t) => setState(() {
            _gio = t;
            _huyGia();
          }),
          thuGoi: _thuGoi,
          soBuoiGoi: _soBuoiGoi,
          lichGoi: _lichGoi,
          loiLichGoi: _loiLichGoi,
          onDoiThu: _doiThu,
          diaChi: _diaChi,
          dangTaiDiaChi: _dangTaiDiaChi,
          onChonDiaChi: _chonDiaChi,
          ghiChu: _ghiChu,
        );
      case 4:
        return BuocXacNhan(
          tomTat: _tomTat(),
          tamTinh: _tamTinh,
          giam: _giam,
          tong: _tongTien,
          dangTinhGia: _dangTinhGia,
          loiGia: _loiGia,
          onTinhLai: _tinhGia,
          maController: _maController,
          maApDung: _maApDung,
          dangKiemMa: _dangKiemMa,
          onApDung: () => _apDungMa(_maController.text),
          onBoMa: _boMa,
          onChonKhuyenMai: _moBangKhuyenMai,
        );
      case 5:
        return BuocThanhToan(
          chon: _hinhThucTT,
          phutThanhToan: _phutThanhToan,
          onChon: (ma) => setState(() => _hinhThucTT = ma),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  /// Thẻ "Các dịch vụ đã chọn" ở bước Thời gian khi đặt từ giỏ hàng.
  Widget _theNhieuDichVu() {
    final ds = widget.dichVuNhieu!;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('${ds.length} dịch vụ đã chọn · bắt đầu cùng lúc, làm song song',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              ),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Sửa')),
            ],
          ),
          for (final m in ds)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(child: Text(m.ten, style: const TextStyle(fontWeight: FontWeight.w600))),
                  Text(GioHang.thoiLuong(m.phut > 0 ? m.phut : GioHang.phutMacDinh),
                      style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(width: 10),
                  Text(CatalogUi.money(m.gia), style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          const Divider(),
          Row(
            children: [
              Text('Xong sau ${GioHang.thoiLuong(_tongPhutNhieu)}'),
              const Spacer(),
              Text(CatalogUi.money(_donGiaThamKhao),
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.brand600)),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Các dịch vụ phải xong trước 20:00, khung giờ quá muộn sẽ bị khóa.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  List<(String, String)> _tomTat() {
    final bt = _bienThe;
    final lich = _lichGoi;
    final ghiChu = _ghiChu.text.trim();
    return [
      if (_nhieu) ...[
        for (final m in widget.dichVuNhieu!) ('Dịch vụ', '${m.ten} · ${CatalogUi.money(m.gia)}'),
        ('Hình thức', 'Theo lần'),
        ('Xong sau', GioHang.thoiLuong(_tongPhutNhieu)),
      ] else ...[
        ('Dịch vụ', _nhom?.ten ?? '—'),
        ('Hình thức', CatalogUi.loaiHinhLabel(_loai)),
        (_laGoi ? 'Gói' : 'Thời lượng', bt == null ? '—' : NhomDichVu.nhanBienThe(bt)),
      ],
      if (_laGoi && _loiLichGoi == null) ...[
        ('Thứ trong tuần', LichGoiThang.nhan(_thuGoi)),
        ('Lịch', '$_soBuoiGoi buổi, ${_ddmmyyyy(lich.first)} → ${_ddmmyyyy(lich.last)}'),
      ] else
        ('Ngày làm', _ngay == null ? '—' : _ddmmyyyy(_ngay!)),
      ('Giờ bắt đầu', _gio == null ? '—' : BuocThoiGian.hhmm(_gio!)),
      ('Địa chỉ', _diaChi?.diaChiChiTiet ?? '—'),
      if (ghiChu.isNotEmpty) ('Ghi chú', ghiChu),
    ];
  }

  // Thanh đáy cố định: tổng tiền + Quay lại / Tiếp tục
  Widget _thanhDay() {
    final nhanTiep = switch (_buoc) {
      4 => 'Đặt dịch vụ',
      5 => _hinhThucTT == 'ChuyenKhoan' ? 'Thanh toán' : 'Xác nhận đặt',
      _ => 'Tiếp tục',
    };
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text('Tổng tiền', style: TextStyle(color: AppColors.textSecondary)),
              const Spacer(),
              Text(
                _tongTien > 0 ? CatalogUi.money(_tongTien) : '—',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.brand600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(onPressed: _dangGui ? null : _lui, child: const Text('Quay lại')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _dangGui ? null : _tiep,
                    child: _dangGui
                        ? const SizedBox(
                            width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(nhanTiep),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
