import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../services/dia_gioi_api_service.dart';

/// Giá trị đang chọn của [DiaChiFields].
class DiaChiDangChon {
  int? maTinh = DiaGioiApiService.maHcm;
  PhuongXa? phuong;
  int? khuVucId;

  /// Địa chỉ ngoài khu vực bTaskee đang phục vụ (phường không thuộc quận, huyện nào trong danh sách).
  bool get ngoaiKhuVuc => phuong != null && phuong!.khuVuc.isEmpty;

  /// Khu vực đang áp dụng: chọn tay khi phường thuộc nhiều khu vực, không thì khu vực duy nhất.
  KhuVucNho? get khuVuc {
    final ds = phuong?.khuVuc ?? const <KhuVucNho>[];
    if (ds.isEmpty) return null;
    return ds.firstWhere((k) => k.id == khuVucId, orElse: () => ds.first);
  }
}

/// Các ô ĐỊA CHỈ dùng chung (sổ địa chỉ, đăng ký khách hàng, đăng ký CTV):
/// Tỉnh, thành → Phường, xã (provinces.open-api.vn v2) + số nhà, tên đường.
/// KHU VỰC (quận, huyện) tự suy ra từ phường; phường thuộc nhiều khu vực thì cho chọn.
class DiaChiFields extends StatefulWidget {
  final DiaChiDangChon giaTri;
  final TextEditingController soNhaCtrl;
  final int? maPhuongBanDau;

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
  List<PhuongXa> _phuong = [];
  bool _taiPhuong = false;
  String? _loi;

  DiaChiDangChon get _g => widget.giaTri;

  @override
  void initState() {
    super.initState();
    _napTinh();
  }

  Future<void> _napTinh() async {
    final res = await _api.tinhThanh();
    if (!mounted) return;
    setState(() {
      _tinh = res.data ?? [];
      _loi = res.success ? null : (res.message ?? 'Không tải được danh sách tỉnh, thành.');
    });
    if (_g.maTinh != null) await _napPhuong(_g.maTinh!, chonMa: widget.maPhuongBanDau);
  }

  Future<void> _napPhuong(int maTinh, {int? chonMa}) async {
    setState(() {
      _taiPhuong = true;
      _phuong = [];
    });
    final res = await _api.phuongXa(maTinh);
    if (!mounted) return;
    setState(() {
      _taiPhuong = false;
      _phuong = res.data ?? [];
      _loi = res.success ? null : (res.message ?? 'Không tải được danh sách phường, xã.');
      if (chonMa != null) {
        final p = _phuong.where((x) => x.ma == chonMa);
        if (p.isNotEmpty) _g.phuong = p.first;
      }
    });
    widget.onChanged?.call(_g);
  }

  /// Chọn sẵn phường có tên xuất hiện trong chuỗi địa chỉ (GPS). Trả về true nếu tìm được.
  bool doanPhuong(String diaChi) {
    final t = diaChi.toLowerCase();
    for (final p in _phuong) {
      if (RegExp('${RegExp.escape(p.ten.toLowerCase())}(?![0-9])').hasMatch(t)) {
        setState(() {
          _g.phuong = p;
          _g.khuVucId = null;
        });
        widget.onChanged?.call(_g);
        return true;
      }
    }
    return false;
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
    final t = await _bangChon<TinhThanh>('Tìm tỉnh, thành', _tinh, (x) => x.ten, (x) => x.ma == _g.maTinh);
    if (t == null || t.ma == _g.maTinh) return;
    setState(() {
      _g.maTinh = t.ma;
      _g.phuong = null;
      _g.khuVucId = null;
    });
    widget.onChanged?.call(_g);
    await _napPhuong(t.ma);
  }

  Future<void> _chonPhuong() async {
    if (_g.maTinh == null) return;
    if (_phuong.isEmpty) return _napPhuong(_g.maTinh!);
    final p = await _bangChon<PhuongXa>('Tìm phường, xã', _phuong, (x) => x.nhan, (x) => x.ma == _g.phuong?.ma);
    if (p == null) return;
    setState(() {
      _g.phuong = p;
      _g.khuVucId = null;
    });
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
    final p = _g.phuong;
    if (p == null) return null;
    if (p.khuVuc.isEmpty) {
      return widget.batBuocTrongKhuVuc ? null : 'Ngoài khu vực phục vụ: vẫn lưu được, chưa đặt dịch vụ tại đây được.';
    }
    if (p.khuVuc.length == 1) return 'Khu vực: ${p.khuVuc.first.ten}';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final tenTinh = _tinh.where((t) => t.ma == _g.maTinh).map((t) => t.ten).firstOrNull;
    final nhieuKv = (_g.phuong?.khuVuc.length ?? 0) > 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
        FormField<int>(
          validator: (_) {
            if (_g.phuong == null) return 'Vui lòng chọn phường, xã';
            if (widget.batBuocTrongKhuVuc && _g.ngoaiKhuVuc) {
              return 'Phường, xã này ngoài khu vực bTaskee đang phục vụ (các quận, huyện TP. Hồ Chí Minh).';
            }
            return null;
          },
          builder: (f) => _o(
            nhan: 'Phường, xã *',
            icon: Icons.map_outlined,
            giaTri: _taiPhuong ? 'Đang tải…' : _g.phuong?.nhan,
            onTap: () async {
              await _chonPhuong();
              f.didChange(_g.phuong?.ma);
            },
            loi: f.errorText ?? (_tinh.isNotEmpty && _phuong.isEmpty && !_taiPhuong ? _loi : null),
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
              helperText: 'Phường, xã này thuộc nhiều quận cũ, chọn quận đúng với địa chỉ',
              helperMaxLines: 2,
            ),
            items: _g.phuong!.khuVuc
                .map((k) => DropdownMenuItem(value: k.id, child: Text(k.ten)))
                .toList(),
            onChanged: (v) {
              setState(() => _g.khuVucId = v);
              widget.onChanged?.call(_g);
            },
          ),
        ],
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
    final tk = _boDau(_tuKhoa.trim());
    final ds = widget.ds.where((x) => tk.isEmpty || _boDau(widget.nhan(x)).contains(tk)).toList();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
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
