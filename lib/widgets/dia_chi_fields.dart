import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../services/dia_gioi_api_service.dart';

/// Giá trị đang chọn của [DiaChiFields], khớp bảng DiaChiKhachHang (chuỗi địa chỉ + khu vực):
/// phường, xã mới → gửi maTinh + maPhuong; quận, huyện cũ → gửi maTinh (cũ) + maQuan.
class DiaChiDangChon {
  int? maTinh = DiaGioiApiService.maHcm;
  String? tenTinh = 'Thành phố Hồ Chí Minh';

  /// true = tỉnh chỉ còn ở danh mục trước sáp nhập (ô thứ hai chỉ có quận, huyện cũ).
  bool tinhCu = false;

  /// Dòng đang chọn ở ô thứ hai (phường, xã mới hoặc quận, huyện cũ).
  PhuongGop? duoi;
  int? khuVucId;

  /// Đang chọn quận, huyện cũ: địa chỉ theo địa giới trước sáp nhập.
  bool get isV1 => duoi?.cu ?? tinhCu;

  /// Mã tỉnh gửi lên: quận cũ của tỉnh cùng tên mang mã tỉnh cũ.
  int? get maTinhGui => duoi?.maTinh ?? maTinh;

  void chonTinh(TinhThanh t) {
    maTinh = t.ma;
    tenTinh = t.ten;
    tinhCu = t.cu;
    boPhuong();
  }

  void apDung(PhuongGop p) {
    khuVucId = null;
    duoi = p;
  }

  /// Bỏ dòng đang chọn ở ô thứ hai (khi đổi tỉnh).
  void boPhuong() {
    duoi = null;
    khuVucId = null;
  }

  bool laTinh(TinhThanh t) => t.ma == maTinh && t.cu == tinhCu;
  bool laPhuong(PhuongGop p) => duoi?.ma == p.ma && duoi?.cu == p.cu;

  int? get maPhuong => duoi == null || duoi!.cu ? null : duoi!.ma;
  int? get maQuan => duoi != null && duoi!.cu ? duoi!.ma : null;

  /// Đã chọn ô thứ hai.
  bool get daChonDuoi => duoi != null;

  /// Địa chỉ ngoài khu vực phục vụ.
  bool get ngoaiKhuVuc => duoi != null && duoi!.khuVuc.isEmpty;

  /// Phường mới thuộc nhiều quận cũ: người dùng chọn khu vực.
  bool get nhieuKhuVuc => (duoi?.khuVuc.length ?? 0) > 1;

  /// Khu vực đang áp dụng.
  KhuVucNho? get khuVuc {
    final ds = duoi?.khuVuc ?? const <KhuVucNho>[];
    if (ds.isEmpty) return null;
    return ds.firstWhere((k) => k.id == khuVucId, orElse: () => ds.first);
  }

  /// Tên phường mới đang chọn.
  String? get tenPhuongHienTai => maPhuong == null ? null : duoi?.ten;

  /// Tên quận cũ đang chọn.
  String? get tenQuanHienTai => maQuan == null ? null : duoi?.ten;
}

/// Các ô ĐỊA CHỈ dùng chung (sổ địa chỉ, đăng ký khách hàng, đăng ký CTV), giống form web:
/// Tỉnh, thành phố (tỉnh mới; tỉnh chỉ còn ở danh mục cũ ghi "(cũ)") → Phường, xã / quận, huyện (+ số nhà).
class DiaChiFields extends StatefulWidget {
  final DiaChiDangChon giaTri;
  final TextEditingController soNhaCtrl;
  final int? maPhuongBanDau;

  /// Có = địa chỉ đã lưu theo địa giới cũ: maTinh là mã tỉnh cũ, chọn sẵn quận, huyện này.
  final int? maQuanBanDau;

  /// true: báo lỗi khi địa chỉ ngoài khu vực phục vụ (dùng khi đặt dịch vụ).
  final bool batBuocTrongKhuVuc;

  /// Ghi chú dưới ô phường (VD đăng ký CTV: "khu vực gần nhà"); null = mặc định.
  final String Function(DiaChiDangChon)? ghiChuKhuVuc;
  final ValueChanged<DiaChiDangChon>? onChanged;

  const DiaChiFields({
    super.key,
    required this.giaTri,
    required this.soNhaCtrl,
    this.maPhuongBanDau,
    this.maQuanBanDau,
    this.batBuocTrongKhuVuc = false,
    this.ghiChuKhuVuc,
    this.onChanged,
  });

  @override
  State<DiaChiFields> createState() => DiaChiFieldsState();
}

class DiaChiFieldsState extends State<DiaChiFields> {
  final _api = DiaGioiApiService();

  List<TinhThanh> _tinh = [];
  List<PhuongGop> _duoi = [];
  bool _taiPhuong = false;
  String? _loi;

  DiaChiDangChon get _g => widget.giaTri;

  @override
  void initState() {
    super.initState();
    _napTinh();
  }

  Future<void> _napTinh() async {
    final res = await _api.tinhGop();
    if (!mounted) return;
    setState(() {
      _tinh = res.data ?? [];
      _loi = res.success ? null : (res.message ?? 'Không tải được danh sách tỉnh.');
      // Địa chỉ đã lưu theo địa giới cũ (có quận): maTinh là mã tỉnh cũ → tỉnh mới cùng tên hoặc tỉnh "(cũ)"
      if (widget.maQuanBanDau != null && !_g.daChonDuoi) {
        final maCu = _g.maTinh;
        final tc = _tinh.where((x) => x.cu ? x.ma == maCu : x.maCu == maCu).firstOrNull;
        if (tc != null) {
          final kv = _g.khuVucId;
          _g.chonTinh(tc);
          _g.khuVucId = kv;
        }
      }
      final t = _tinh.where(_g.laTinh).firstOrNull;
      if (t != null) _g.tenTinh = t.ten;
    });
    if (_g.maTinh != null) {
      final quan = widget.maQuanBanDau;
      await _napPhuong(chonMa: quan ?? widget.maPhuongBanDau, chonCu: quan != null);
    }
  }

  Future<void> _napPhuong({int? chonMa, bool chonCu = false}) async {
    final maTinh = _g.maTinh!, cu = _g.tinhCu;
    setState(() {
      _taiPhuong = true;
      _duoi = [];
    });
    final res = await _api.duoiTinh(maTinh, cu: cu);
    if (!mounted || _g.maTinh != maTinh || _g.tinhCu != cu) return;
    setState(() {
      _taiPhuong = false;
      _duoi = res.data ?? [];
      _loi = res.success ? null : (res.message ?? 'Không tải được danh sách phường, xã / quận, huyện.');
      if (chonMa != null) {
        final p = _duoi.where((x) => x.ma == chonMa && x.cu == chonCu).firstOrNull;
        if (p != null) {
          final kv = _g.khuVucId; // giữ khu vực đã lưu (phường thuộc nhiều quận cũ)
          _g.apDung(p);
          _g.khuVucId = kv;
        }
      }
    });
    widget.onChanged?.call(_g);
  }

  /// Chọn sẵn phường, xã / quận, huyện có tên xuất hiện trong chuỗi địa chỉ (GPS). Trả về true nếu tìm được.
  bool doanPhuong(String diaChi) {
    final t = diaChi.toLowerCase();
    PhuongGop? thay;
    for (final p in _duoi) {
      final ten = p.ten.toLowerCase();
      final rutGon = ten.replaceFirst(RegExp(r'^(phường|xã|thị trấn|đặc khu|quận|huyện|thị xã|thành phố)\s+'), '').trim();
      final khop = t.contains(ten) || (!RegExp(r'^\d+$').hasMatch(rutGon) && rutGon.length > 3 && t.contains(rutGon));
      if (!khop) continue;
      thay = p;
      break;
    }
    if (thay == null) return false;
    setState(() => _g.apDung(thay!));
    widget.onChanged?.call(_g);
    return true;
  }

  Future<T?> _bangChon<T>(String tieuDe, List<T> ds, String Function(T) nhan, bool Function(T) dangChon) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (_) => _BangChon<T>(tieuDe: tieuDe, ds: ds, nhan: nhan, dangChon: dangChon),
    );
  }

  Future<void> _chonTinh() async {
    if (_tinh.isEmpty) return _napTinh();
    final t = await _bangChon<TinhThanh>('Tìm tỉnh, thành', _tinh, (x) => x.nhan, _g.laTinh);
    if (t == null || _g.laTinh(t)) return;
    setState(() => _g.chonTinh(t));
    widget.onChanged?.call(_g);
    await _napPhuong();
  }

  Future<void> _chonPhuong() async {
    if (_g.maTinh == null) return;
    if (_duoi.isEmpty) return _napPhuong();
    final p = await _bangChon<PhuongGop>('Tìm phường, xã / quận, huyện', _duoi, (x) => x.nhan, _g.laPhuong);
    if (p == null) return;
    setState(() => _g.apDung(p));
    widget.onChanged?.call(_g);
  }

  Widget _o({
    required String nhan,
    required IconData icon,
    required String? giaTri,
    required VoidCallback onTap,
    String? loi,
    String? goiY,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: nhan,
          prefixIcon: Icon(icon),
          suffixIcon: const Icon(Icons.expand_more),
          errorText: loi,
          helperText: goiY,
          helperMaxLines: 3,
          errorMaxLines: 3,
        ),
        isEmpty: giaTri == null,
        child: Text(giaTri ?? '', overflow: TextOverflow.ellipsis),
      ),
    );
  }

  String? _ghiChu() {
    if (widget.ghiChuKhuVuc != null) return widget.ghiChuKhuVuc!(_g);
    if (!_g.daChonDuoi) return null;
    if (_g.ngoaiKhuVuc) {
      return widget.batBuocTrongKhuVuc ? null : 'Ngoài khu vực phục vụ: vẫn lưu được, chưa đặt dịch vụ tại đây được.';
    }
    if (!_g.nhieuKhuVuc) return 'Khu vực: ${_g.khuVuc?.ten}';
    return null;
  }

  String? get _nhanPhuong {
    if (_taiPhuong) return 'Đang tải…';
    return _g.duoi?.nhan;
  }

  @override
  Widget build(BuildContext context) {
    final tenTinh = _tinh.where(_g.laTinh).map((t) => t.nhan).firstOrNull ?? _g.tenTinh;
    final nhieuKv = _g.nhieuKhuVuc;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Ô 1: Tỉnh / Thành phố
        FormField<int>(
          validator: (_) => _g.maTinh == null ? 'Vui lòng chọn tỉnh, thành phố' : null,
          builder: (f) => _o(
            nhan: 'Tỉnh, thành phố *',
            icon: Icons.location_city_outlined,
            giaTri: tenTinh,
            onTap: () async {
              await _chonTinh();
              f.didChange(_g.maTinh);
            },
            loi: f.errorText ?? (_tinh.isEmpty ? _loi : null),
          ),
        ),
        const SizedBox(height: 12),

        // Ô 2: cấp ngay dưới tỉnh – phường, xã (tỉnh mới) hoặc quận, huyện (tỉnh cũ)
        FormField<int>(
          validator: (_) {
            if (!_g.daChonDuoi) return 'Vui lòng chọn phường, xã / quận, huyện';
            if (widget.batBuocTrongKhuVuc && _g.ngoaiKhuVuc) {
              return 'Địa chỉ này ngoài khu vực phục vụ.';
            }
            return null;
          },
          builder: (f) => _o(
            nhan: 'Phường, xã / quận, huyện *',
            icon: Icons.map_outlined,
            giaTri: _nhanPhuong,
            onTap: () async {
              await _chonPhuong();
              f.didChange(_g.duoi?.ma);
            },
            loi: f.errorText ?? (_duoi.isEmpty && !_taiPhuong ? _loi : null),
            goiY: _ghiChu(),
          ),
        ),
        if (nhieuKv) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _g.khuVuc?.id,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Khu vực *',
              prefixIcon: Icon(Icons.share_location_outlined),
              helperText: 'Phường này thuộc nhiều quận cũ, chọn quận đúng với địa chỉ',
              helperMaxLines: 2,
            ),
            items: _g.duoi!.khuVuc
                .map((k) => DropdownMenuItem(value: k.id, child: Text(k.ten, overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: (v) {
              setState(() => _g.khuVucId = v);
              widget.onChanged?.call(_g);
            },
          ),
        ],

        // Ô cuối: Số nhà, tên đường
        const SizedBox(height: 12),
        TextFormField(
          controller: widget.soNhaCtrl,
          maxLength: 200,
          decoration: const InputDecoration(
            labelText: 'Số nhà, tên đường *',
            hintText: 'VD: 45 Đường số 7',
            prefixIcon: Icon(Icons.home_outlined),
          ),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập số nhà, tên đường' : null,
        ),
      ],
    );
  }
}

/// Bảng chọn có ô tìm kiếm (so khớp không dấu).
class _BangChon<T> extends StatefulWidget {
  final String tieuDe;
  final List<T> ds;
  final String Function(T) nhan;
  final bool Function(T) dangChon;

  const _BangChon({required this.tieuDe, required this.ds, required this.nhan, required this.dangChon});

  @override
  State<_BangChon<T>> createState() => _BangChonState<T>();
}

class _BangChonState<T> extends State<_BangChon<T>> {
  String _tuKhoa = '';

  static const _coDau =
      'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
  static const _khongDau =
      'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';

  static String _boDau(String s) {
    final buf = StringBuffer();
    for (final ch in s.toLowerCase().split('')) {
      final i = _coDau.indexOf(ch);
      buf.write(i >= 0 ? _khongDau[i] : ch);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final tk = _boDau(_tuKhoa.trim());
    final ds = widget.ds.where((x) => tk.isEmpty || _boDau(widget.nhan(x)).contains(tk)).toList();
    final double chieuCaoKhaDung = media.size.height - media.viewInsets.bottom;
    final double chieuCao = (chieuCaoKhaDung * 0.85).clamp(240.0, media.size.height * 0.85);

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SafeArea(
        child: SizedBox(
          height: chieuCao,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  autofocus: true,
                  decoration: InputDecoration(hintText: widget.tieuDe, prefixIcon: const Icon(Icons.search)),
                  onChanged: (v) => setState(() => _tuKhoa = v),
                ),
              ),
              Expanded(
                child: ds.isEmpty
                    ? const Center(child: Text('Không có kết quả khớp'))
                    : ListView.builder(
                        itemCount: ds.length,
                        itemBuilder: (_, i) {
                          final chon = widget.dangChon(ds[i]);
                          return ListTile(
                            title: Text(widget.nhan(ds[i])),
                            trailing: chon ? const Icon(Icons.check, color: AppColors.brand500) : null,
                            selected: chon,
                            onTap: () => Navigator.pop(context, ds[i]),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
