import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../services/buoc_dat.dart';
import '../../services/catalog_ui.dart';
import '../../services/nhom_dich_vu.dart';
import '../../services/service_catalog_api_service.dart';
import 'dat_dich_vu/buoc_dich_vu.dart';
import 'dat_dich_vu/buoc_hinh_thuc.dart';
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

  int get _dichVuIdGoc => CatalogUi.toInt(widget.service['dichVuId'] ?? widget.service['id']);

  /// Trong lúc chưa tải xong danh sách, nhóm tạm chỉ có một biến thể nên chưa kết luận được việc bỏ bước 2.
  bool get _boQua2 => _daTaiDv && _nhom != null && BuocDat.boQuaBuoc2(_nhom!);

  DuLieuDat get _duLieu => DuLieuDat(
        nhom: _nhom,
        loaiHinhDat: _loai,
        dichVuId: _dichVuId,
      );

  Map<String, dynamic>? get _bienThe {
    final n = _nhom;
    if (n == null || _dichVuId == null) return null;
    for (final b in n.bienThe) {
      if (CatalogUi.toInt(b['id']) == _dichVuId) return b;
    }
    return null;
  }

  /// Tổng tiền ở thanh đáy: đơn giá tham khảo của biến thể đang chọn.
  int get _tongTien =>
      (num.tryParse(_bienThe?['donGiaThamKhao']?.toString() ?? '') ?? 0).round();

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
    _taiDichVu();
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
    });
  }

  void _chonLoai(String loai) {
    if (loai == _loai) return;
    setState(() {
      _loai = loai;
      final ds = _nhom?.bienTheTheoLoai(loai) ?? const [];
      _dichVuId = ds.isEmpty ? null : CatalogUi.toInt(ds.first['id']);
      _daToi = _buoc;
    });
  }

  void _tiep() {
    final loi = BuocDat.loiBuoc(_buoc, _duLieu);
    if (loi != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(loi), backgroundColor: AppColors.error));
      return;
    }
    if (_buoc >= BuocDat.soBuoc) return;
    setState(() {
      _buoc = _daTaiDv ? BuocDat.buocKe(_buoc, _nhom!) : _buoc + 1;
      if (_buoc > _daToi) _daToi = _buoc;
    });
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
            onChon: (b) => setState(() => _buoc = b),
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
      default:
        return const SizedBox.shrink();
    }
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
