import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../services/dia_gioi_api_service.dart';

/// Giá trị đang chọn của [DiaChiFields].
class DiaChiDangChon {
  /// true = khách chọn phường cũ (trước sáp nhập, kèm quận cũ); false = phường mới (sau sáp nhập).
  bool isV1 = false;

  int? maTinh = DiaGioiApiService.maHcm;
  String? tenTinh = 'Thành phố Hồ Chí Minh';

  // Phường cũ (v1) và quận cũ của nó
  QuanHuyenV1? quanV1;
  PhuongXaV1? phuongV1;

  // Phường mới (v2)
  PhuongXa? phuong;
  int? khuVucId;

  /// Áp lựa chọn từ danh sách phường gộp (giống web: chọn phường cũ thì gửi kèm maQuan).
  void apDung(PhuongGop p) {
    khuVucId = null;
    if (p.laCu) {
      isV1 = true;
      quanV1 = QuanHuyenV1(
        ma: p.maQuan ?? 0,
        ten: p.tenQuan ?? '',
        maTinh: maTinh ?? DiaGioiApiService.maHcm,
        khuVucId: p.khuVucIdQuan,
        tenKhuVuc: p.tenKhuVucQuan,
      );
      phuongV1 = PhuongXaV1(ma: p.ma, ten: p.ten, maQuan: p.maQuan ?? 0);
      phuong = null;
    } else {
      isV1 = false;
      phuong = PhuongXa(p.ma, p.ten, p.khuVuc);
      quanV1 = null;
      phuongV1 = null;
    }
  }

  /// Bỏ phường đang chọn (khi đổi tỉnh).
  void boPhuong() {
    quanV1 = null;
    phuongV1 = null;
    phuong = null;
    khuVucId = null;
  }

  /// [p] có phải phường đang chọn không (mã phường mới và cũ có thể trùng nhau).
  bool laPhuong(PhuongGop p) => p.laCu
      ? isV1 && phuongV1?.ma == p.ma && quanV1?.ma == p.maQuan
      : !isV1 && phuong?.ma == p.ma;

  int? get maPhuong => isV1 ? phuongV1?.ma : phuong?.ma;
  int? get maQuan => isV1 ? quanV1?.ma : null;

  /// Địa chỉ ngoài khu vực phục vụ
  bool get ngoaiKhuVuc {
    if (isV1) {
      return quanV1 != null && quanV1!.khuVucId == null;
    }
    return phuong != null && phuong!.khuVuc.isEmpty;
  }

  /// Khu vực đang áp dụng
  KhuVucNho? get khuVuc {
    if (isV1) {
      if (quanV1 != null && quanV1!.khuVucId != null) {
        return KhuVucNho(quanV1!.khuVucId!, quanV1!.tenKhuVuc ?? quanV1!.ten);
      }
      return null;
    }
    final ds = phuong?.khuVuc ?? const <KhuVucNho>[];
    if (ds.isEmpty) return null;
    return ds.firstWhere((k) => k.id == khuVucId, orElse: () => ds.first);
  }

  /// Tên phường đang chọn (dùng hiển thị hoặc lưu trữ)
  String? get tenPhuongHienTai => isV1 ? phuongV1?.ten : phuong?.ten;

  /// Tên quận đang chọn (nếu có)
  String? get tenQuanHienTai => isV1 ? quanV1?.ten : null;
}

/// Các ô ĐỊA CHỈ dùng chung (sổ địa chỉ, đăng ký khách hàng, đăng ký CTV), giống form web:
/// chỉ 2 ô Tỉnh, thành phố → Phường, xã (+ số nhà). Tỉnh gộp trước và sau sáp nhập theo mã; tỉnh có ở
/// cả hai thì ô phường tìm được cả phường mới lẫn phường cũ (kèm quận cũ).
class DiaChiFields extends StatefulWidget {
  final DiaChiDangChon giaTri;
  final TextEditingController soNhaCtrl;
  final int? maPhuongBanDau;

  /// Có = địa chỉ đã lưu là phường cũ của quận này.
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
  List<PhuongGop> _phuong = [];
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
      final t = _tinh.where((t) => t.ma == _g.maTinh).firstOrNull;
      if (t != null) _g.tenTinh = t.ten;
    });
    if (_g.maTinh != null) {
      await _napPhuong(_g.maTinh!, chonMa: widget.maPhuongBanDau, chonQuan: widget.maQuanBanDau);
    }
  }

  Future<void> _napPhuong(int maTinh, {int? chonMa, int? chonQuan}) async {
    setState(() {
      _taiPhuong = true;
      _phuong = [];
    });
    final res = await _api.phuongXaGop(maTinh);
    if (!mounted || _g.maTinh != maTinh) return;
    setState(() {
      _taiPhuong = false;
      _phuong = res.data ?? [];
      _loi = res.success ? null : (res.message ?? 'Không tải được danh sách phường, xã.');
      if (chonMa != null) {
        final p = _phuong
            .where((x) => x.ma == chonMa && (chonQuan != null ? x.laCu && x.maQuan == chonQuan : !x.laCu))
            .firstOrNull;
        if (p != null) _g.apDung(p);
      }
    });
    widget.onChanged?.call(_g);
  }

  /// Chọn sẵn phường có tên xuất hiện trong chuỗi địa chỉ (GPS). Trả về true nếu tìm được.
  bool doanPhuong(String diaChi) {
    final t = diaChi.toLowerCase();
    PhuongGop? thay;
    for (final p in _phuong) {
      final ten = p.ten.toLowerCase();
      final rutGon = ten.replaceFirst(RegExp(r'^(phường|xã|thị trấn|đặc khu)\s+'), '').trim();
      final khop = t.contains(ten) || (!RegExp(r'^\d+$').hasMatch(rutGon) && rutGon.length > 3 && t.contains(rutGon));
      if (!khop) continue;
      if (p.laCu && (p.tenQuan == null || !t.contains(p.tenQuan!.toLowerCase()))) continue;
      thay = p;
      if (!p.laCu) break; // ưu tiên phường mới
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
    final t = await _bangChon<TinhThanh>('Tìm tỉnh, thành', _tinh, (x) => x.nhan, (x) => x.ma == _g.maTinh);
    if (t == null || t.ma == _g.maTinh) return;
    setState(() {
      _g.maTinh = t.ma;
      _g.tenTinh = t.ten;
      _g.boPhuong();
    });
    widget.onChanged?.call(_g);
    await _napPhuong(t.ma);
  }

  Future<void> _chonPhuong() async {
    if (_g.maTinh == null) return;
    if (_phuong.isEmpty) return _napPhuong(_g.maTinh!);
    final p = await _bangChon<PhuongGop>('Gõ tên phường, xã (mới hoặc cũ)', _phuong, (x) => x.nhan, _g.laPhuong);
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
    if (_g.maPhuong == null) return null;
    if (_g.ngoaiKhuVuc) {
      return widget.batBuocTrongKhuVuc ? null : 'Ngoài khu vực phục vụ: vẫn lưu được, chưa đặt dịch vụ tại đây được.';
    }
    if (_g.isV1) return 'Khu vực: ${_g.khuVuc?.ten}';
    if (_g.phuong!.khuVuc.length == 1) return 'Khu vực: ${_g.phuong!.khuVuc.first.ten}';
    return null;
  }

  String? get _nhanPhuong {
    if (_taiPhuong) return 'Đang tải…';
    final p = _phuong.where(_g.laPhuong).firstOrNull;
    return p?.nhan ?? (_g.isV1 ? _g.phuongV1?.nhan : _g.phuong?.nhan);
  }

  @override
  Widget build(BuildContext context) {
    final tenTinh = _tinh.where((t) => t.ma == _g.maTinh).map((t) => t.nhan).firstOrNull ?? _g.tenTinh;
    final nhieuKv = !_g.isV1 && (_g.phuong?.khuVuc.length ?? 0) > 1;

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

        // Ô 2: Phường / Xã (mới hoặc cũ)
        FormField<int>(
          validator: (_) {
            if (_g.maPhuong == null) return 'Vui lòng chọn phường, xã';
            if (widget.batBuocTrongKhuVuc && _g.ngoaiKhuVuc) {
              return 'Phường, xã này ngoài khu vực phục vụ.';
            }
            return null;
          },
          builder: (f) => _o(
            nhan: 'Phường, xã *',
            icon: Icons.map_outlined,
            giaTri: _nhanPhuong,
            onTap: () async {
              await _chonPhuong();
              f.didChange(_g.maPhuong);
            },
            loi: f.errorText ?? (_phuong.isEmpty && !_taiPhuong ? _loi : null),
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
            items: _g.phuong!.khuVuc
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
