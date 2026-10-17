import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../services/address_api_service.dart';
import '../../services/booking_api_service.dart';
import '../../services/buoc_dat.dart';
import '../../services/catalog_ui.dart';
import '../../services/lich_goi_thang.dart';
import '../../services/nhom_dich_vu.dart';
import '../../services/rang_buoc_ngay_dat.dart';
import '../../services/service_catalog_api_service.dart';
import '../../services/session_service.dart';
import '../../widgets/lich_thang.dart';
import 'address_book_screen.dart';
import 'dat_dich_vu/bang_khuyen_mai.dart';
import 'dat_dich_vu/buoc_dich_vu.dart';
import 'dat_dich_vu/buoc_hinh_thuc.dart';
import 'dat_dich_vu/buoc_thoi_gian.dart';
import 'dat_dich_vu/buoc_xac_nhan.dart';
import 'dat_dich_vu/thanh_buoc.dart';

/// Màn đặt dịch vụ 5 bước, giống website:
/// 1 Dịch vụ → 2 Hình thức → 3 Thời gian → 4 Xác nhận → 5 Thanh toán.
/// Mở từ trang chi tiết dịch vụ nên dịch vụ đã chọn sẵn, bắt đầu ở bước 2 (bước 3 nếu chỉ có một hình thức).
class BookingScreen extends StatefulWidget {
  final Map<String, dynamic> service;

  const BookingScreen({super.key, required this.service});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  late int _buoc;
  late int _daToi;

  // Bước 1: dịch vụ cùng danh mục, gom theo mã dịch vụ
  List<NhomDichVu> _nhoms = [];
  NhomDichVu? _nhom;
  bool _dangTaiDv = true;
  bool _daTaiDv = false; // đã có danh sách đầy đủ: mới biết nhóm có bỏ qua bước 2 hay không
  String? _loiDv;

  // Bước 2–3: hình thức và biến thể (thời lượng / gói)
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

  // Khung giờ bắt đầu 07:00 → 17:00
  static final List<TimeOfDay> _khungGio = List.generate(11, (i) => TimeOfDay(hour: 7 + i, minute: 0));

  int get _dichVuIdGoc => CatalogUi.toInt(widget.service['dichVuId'] ?? widget.service['id']);

  /// Trong lúc chưa tải xong danh sách, nhóm tạm chỉ có một biến thể nên chưa kết luận được việc bỏ bước 2.
  bool get _boQua2 => _daTaiDv && _nhom != null && BuocDat.boQuaBuoc2(_nhom!);

  DuLieuDat get _duLieu => DuLieuDat(
        nhom: _nhom,
        loaiHinhDat: _loai,
        dichVuId: _dichVuId,
        daChonGio: _gio != null && _gioHopLe(_gio!),
        goiDuBuoi: _loiLichGoi == null,
        coDiaChiNao: _diaChi != null,
        coDiaChiTrongKhuVuc: _diaChi?.coKhuVuc ?? false,
        hinhThucThanhToan: null,
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

  int get _donGiaThamKhao => _tien(_bienThe?['donGiaThamKhao']);

  int get _tamTinh => _gia != null ? _tien(_gia!['chiPhiGoc']) : _donGiaThamKhao;

  int get _giam => _gia != null ? _tien(_gia!['soTienGiam']) : 0;

  /// Tổng tiền ở thanh đáy: số máy chủ tính, chưa có thì đơn giá tham khảo của biến thể đang chọn.
  int get _tongTien => _gia != null ? _tien(_gia!['thanhTien']) : _donGiaThamKhao;

  @override
  void initState() {
    super.initState();
    // Dựng tạm nhóm từ dịch vụ đang xem để mở ngay, không chờ mạng
    final tam = NhomDichVu.gom([widget.service]).first;
    _nhoms = [tam];
    _nhom = tam;
    _loai = BuocDat.loaiMacDinh(tam, uuTien: widget.service['loaiHinhDat']?.toString());
    _dichVuId = _dichVuIdGoc > 0 ? _dichVuIdGoc : null;
    _buoc = 2;
    _daToi = 2;
    // Hôm nay nếu còn khung giờ hợp lệ, không thì ngày mai
    _ngay = _homNay;
    if (!_khungGio.any(_gioHopLe)) _ngay = _homNay.add(const Duration(days: 1));
    _chinhGio();
    _taiDichVu();
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
  }

  Future<void> _taiDichVu() async {
    setState(() {
      _dangTaiDv = true;
      _loiDv = null;
    });
    try {
      final loaiId = CatalogUi.toInt(widget.service['loaiDichVuId']);
      final res = await ServiceCatalogApiService().getServices(loaiDichVuId: loaiId > 0 ? loaiId : null);
      if (!mounted) return;
      if (!res.success || res.data == null) {
        setState(() => _loiDv = res.message ?? 'Không tải được danh sách dịch vụ');
        return;
      }
      var nhoms = NhomDichVu.gom(res.data!);
      var dangChon = _nhom == null ? null : _timNhom(nhoms, _nhom!);
      if (dangChon == null && _nhom != null) {
        // Dịch vụ đang chọn không có trong danh sách (đã ngừng / khác danh mục): vẫn giữ để đặt tiếp
        nhoms = [_nhom!, ...nhoms];
        dangChon = _nhom;
      }
      setState(() {
        _nhoms = nhoms;
        _daTaiDv = true;
        if (dangChon != null) _datNhom(dangChon, giuBienThe: true);
        if (_buoc == 2 && _boQua2) {
          _buoc = 3;
          if (_daToi < 3) _daToi = 3;
        }
      });
    } catch (_) {
      if (mounted) setState(() => _loiDv = 'Không kết nối được máy chủ');
    } finally {
      if (mounted) setState(() => _dangTaiDv = false);
    }
  }

  /// Nhóm trong danh sách mới tương ứng nhóm đang chọn: theo biến thể đang chọn, rồi theo mã.
  NhomDichVu? _timNhom(List<NhomDichVu> nhoms, NhomDichVu cu) {
    final theoId = _dichVuId == null ? null : NhomDichVu.timTheoDichVuId(nhoms, _dichVuId!);
    if (theoId != null) return theoId;
    for (final g in nhoms) {
      if (g.ma == cu.ma) return g;
    }
    return null;
  }

  /// Chọn nhóm: giữ hình thức nếu nhóm có, chọn biến thể đầu tiên của hình thức đó
  /// (hoặc giữ biến thể đang chọn khi chỉ thay bằng bản đầy đủ của cùng nhóm).
  void _datNhom(NhomDichVu g, {bool giuBienThe = false}) {
    _nhom = g;
    _loai = BuocDat.loaiMacDinh(g, uuTien: _loai);
    final ds = g.bienTheTheoLoai(_loai);
    final conBienThe = giuBienThe && ds.any((b) => CatalogUi.toInt(b['id']) == _dichVuId);
    if (!conBienThe) _dichVuId = ds.isEmpty ? null : CatalogUi.toInt(ds.first['id']);
  }

  void _chonNhom(NhomDichVu g) {
    if (g.ma == _nhom?.ma) return;
    setState(() {
      _datNhom(g);
      _daToi = _buoc; // đổi dịch vụ: các bước sau phải đi lại
      _maApDung = null;
      _maController.clear();
      _huyGia();
      _chinhGio();
    });
  }

  void _chonLoai(String loai) {
    if (loai == _loai) return;
    String? thongBao;
    setState(() {
      _loai = loai;
      final ds = _nhom?.bienTheTheoLoai(loai) ?? const [];
      _dichVuId = ds.isEmpty ? null : CatalogUi.toInt(ds.first['id']);
      _daToi = _buoc;
      _huyGia();
      final cu = _ngay;
      if (cu != null) {
        final moi = BuocDat.keoNgay(cu, loai, _homNay);
        if (moi != cu) {
          _ngay = moi;
          final dm = '${moi.day.toString().padLeft(2, '0')}/${moi.month.toString().padLeft(2, '0')}';
          thongBao = loai == 'GoiThang'
              ? 'Đã đổi ngày về $dm vì gói tháng chỉ bắt đầu trong 3 tháng.'
              : 'Đã đổi ngày về $dm vì đặt theo lần chỉ trong 1 tháng.';
        }
      }
      _chinhGio();
    });
    if (thongBao != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(thongBao!)));
    }
  }

  void _chonBienThe(int id) => setState(() {
        _dichVuId = id;
        _huyGia();
        _chinhGio();
      });

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
    setState(() => _dangTinhGia = true);
    try {
      final res = await _bookingApi.calculatePrice(
        dichVuId: id,
        loaiHinhDat: _loai,
        codeKhuyenMai: _maApDung,
        khachHangId: _session?.userId,
        ngayThucHien: _ngayBuoiDau == null ? null : _ymd(_ngayBuoiDau!),
        gioBatDau: _gio == null ? null : BuocThoiGian.hhmm(_gio!),
      );
      if (!mounted) return;
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
      if (mounted) {
        setState(() {
          _gia = null;
          _loiGia = true;
        });
      }
    } finally {
      if (mounted) setState(() => _dangTinhGia = false);
    }
  }

  /// Áp mã: máy chủ tính giá kèm mã; có giảm thì nhận mã, không thì báo câu của máy chủ.
  Future<void> _apDungMa(String code) async {
    final id = _dichVuId;
    code = code.trim().toUpperCase();
    if (id == null || code.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _dangKiemMa = true);
    try {
      final res = await _bookingApi.calculatePrice(
        dichVuId: id,
        loaiHinhDat: _loai,
        codeKhuyenMai: code,
        khachHangId: _session?.userId,
        ngayThucHien: _ngayBuoiDau == null ? null : _ymd(_ngayBuoiDau!),
        gioBatDau: _gio == null ? null : BuocThoiGian.hhmm(_gio!),
      );
      if (!mounted) return;
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
    );
    if (code != null && mounted) _apDungMa(code);
  }

  /// Sang một bước: tới bước 4 thì tính giá.
  void _denBuoc(int b) {
    setState(() {
      _buoc = b;
      if (_buoc > _daToi) _daToi = _buoc;
    });
    if (b == 4 && _gia == null && !_dangTinhGia) _tinhGia();
  }

  void _tiep() {
    final loi = BuocDat.loiBuoc(_buoc, _duLieu) ??
        (_buoc == 3
            ? RangBuocNgayDat.loiNgayDat(_loai, _ngayBuoiDau, _gio?.hour, _gio?.minute, DateTime.now())
            : null);
    if (loi != null) {
      _baoLoi(loi);
      return;
    }
    if (_buoc >= BuocDat.soBuoc) return;
    _denBuoc(_daTaiDv ? BuocDat.buocKe(_buoc, _nhom!) : _buoc + 1);
  }

  void _lui() {
    if (_buoc <= 1) {
      Navigator.pop(context);
      return;
    }
    setState(() => _buoc = _daTaiDv ? BuocDat.buocLui(_buoc, _nhom!) : _buoc - 1);
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
            boQuaBuoc2: _boQua2,
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
      case 1:
        return BuocDichVu(
          nhoms: _nhoms,
          maChon: _nhom?.ma,
          onChon: _chonNhom,
          dangTai: _dangTaiDv,
          loi: _loiDv,
          onThuLai: _taiDichVu,
        );
      case 2:
        return BuocHinhThuc(nhom: _nhom!, loaiChon: _loai, onChon: _chonLoai);
      case 3:
        return BuocThoiGian(
          loai: _loai,
          bienThes: _nhom?.bienTheTheoLoai(_loai) ?? const [],
          dichVuId: _dichVuId,
          onChonBienThe: _chonBienThe,
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
      default:
        return const SizedBox.shrink();
    }
  }

  List<(String, String)> _tomTat() {
    final bt = _bienThe;
    final lich = _lichGoi;
    final ghiChu = _ghiChu.text.trim();
    return [
      ('Dịch vụ', _nhom?.ten ?? '—'),
      ('Hình thức', CatalogUi.loaiHinhLabel(_loai)),
      (_laGoi ? 'Gói' : 'Thời lượng', bt == null ? '—' : BuocThoiGian.nhanBienThe(bt)),
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
      5 => 'Xác nhận đặt',
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
                  child: OutlinedButton(onPressed: _lui, child: const Text('Quay lại')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(onPressed: _tiep, child: Text(nhanTiep)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
