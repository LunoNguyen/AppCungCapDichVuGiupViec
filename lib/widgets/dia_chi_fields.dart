import 'package:flutter/material.dart';

import '../core/app_colors.dart';
import '../services/dia_gioi_api_service.dart';

/// Giá trị đang chọn của [DiaChiFields].
class DiaChiDangChon {
  /// true = Địa chỉ cũ (3 cấp: Tỉnh → Quận/Huyện → Phường/Xã)
  /// false = Địa chỉ mới (2 cấp: Tỉnh → Phường/Xã sau sáp nhập)
  bool isV1 = true;

  int? maTinh = DiaGioiApiService.maHcm;
  String? tenTinh = 'Thành phố Hồ Chí Minh';

  // Chế độ V1 (3 cấp)
  QuanHuyenV1? quanV1;
  PhuongXaV1? phuongV1;

  // Chế độ V2 (2 cấp)
  PhuongXa? phuong;
  int? khuVucId;

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

/// Các ô ĐỊA CHỈ dùng chung (sổ địa chỉ, đăng ký khách hàng, đăng ký CTV):
/// Hỗ trợ chuyển đổi linh hoạt:
/// - "Địa chỉ cũ (Quận / Huyện)": Tỉnh → Quận/Huyện → Phường/Xã + Số nhà.
/// - "Địa chỉ mới (Sau sáp nhập)": Tỉnh → Phường/Xã mới + Số nhà.
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

  // Dữ liệu V1
  List<TinhThanh> _tinhV1 = [];
  List<QuanHuyenV1> _quanV1 = [];
  List<PhuongXaV1> _phuongV1 = [];
  bool _taiQuanV1 = false;
  bool _taiPhuongV1 = false;

  // Dữ liệu V2
  List<TinhThanh> _tinhV2 = [];
  List<PhuongXa> _phuongV2 = [];
  bool _taiPhuongV2 = false;

  String? _loi;

  DiaChiDangChon get _g => widget.giaTri;

  @override
  void initState() {
    super.initState();
    _napDuLieuBanDau();
  }

  Future<void> _napDuLieuBanDau() async {
    if (_g.isV1) {
      await _napTinhV1();
    } else {
      await _napTinhV2();
    }
  }

  // ===================== XỬ LÝ V1 (3 CẤP) =====================
  Future<void> _napTinhV1() async {
    final res = await _api.tinhThanhV1();
    if (!mounted) return;
    setState(() {
      _tinhV1 = res.data ?? [];
      _loi = res.success ? null : (res.message ?? 'Không tải được danh sách tỉnh.');
      if (_g.maTinh != null && _tinhV1.isNotEmpty) {
        _g.tenTinh = _tinhV1.firstWhere((t) => t.ma == _g.maTinh, orElse: () => _tinhV1.first).ten;
      }
    });
    if (_g.maTinh != null) {
      await _napQuanV1(_g.maTinh!);
    }
  }

  Future<void> _napQuanV1(int maTinh) async {
    setState(() {
      _taiQuanV1 = true;
      _quanV1 = [];
      _phuongV1 = [];
    });
    final res = await _api.quanHuyenV1(maTinh);
    if (!mounted) return;
    setState(() {
      _taiQuanV1 = false;
      _quanV1 = res.data ?? [];
      _loi = res.success ? null : (res.message ?? 'Không tải được danh sách quận, huyện.');
    });
    widget.onChanged?.call(_g);
  }

  Future<void> _napPhuongV1(int maQuan) async {
    setState(() {
      _taiPhuongV1 = true;
      _phuongV1 = [];
    });
    final res = await _api.phuongXaV1(maQuan);
    if (!mounted) return;
    setState(() {
      _taiPhuongV1 = false;
      _phuongV1 = res.data ?? [];
      _loi = res.success ? null : (res.message ?? 'Không tải được danh sách phường, xã.');
    });
    widget.onChanged?.call(_g);
  }

  // ===================== XỬ LÝ V2 (2 CẤP) =====================
  Future<void> _napTinhV2() async {
    final res = await _api.tinhThanh();
    if (!mounted) return;
    setState(() {
      _tinhV2 = res.data ?? [];
      _loi = res.success ? null : (res.message ?? 'Không tải được danh sách tỉnh.');
      if (_g.maTinh != null && _tinhV2.isNotEmpty) {
        _g.tenTinh = _tinhV2.firstWhere((t) => t.ma == _g.maTinh, orElse: () => _tinhV2.first).ten;
      }
    });
    if (_g.maTinh != null) {
      await _napPhuongV2(_g.maTinh!, chonMa: widget.maPhuongBanDau);
    }
  }

  Future<void> _napPhuongV2(int maTinh, {int? chonMa}) async {
    setState(() {
      _taiPhuongV2 = true;
      _phuongV2 = [];
    });
    final res = await _api.phuongXa(maTinh);
    if (!mounted) return;
    setState(() {
      _taiPhuongV2 = false;
      _phuongV2 = res.data ?? [];
      _loi = res.success ? null : (res.message ?? 'Không tải được danh sách phường, xã.');
      if (chonMa != null) {
        final p = _phuongV2.where((x) => x.ma == chonMa);
        if (p.isNotEmpty) _g.phuong = p.first;
      }
    });
    widget.onChanged?.call(_g);
  }

  /// Chọn sẵn quận/phường có tên xuất hiện trong chuỗi địa chỉ (GPS). Trả về true nếu tìm được.
  bool doanPhuong(String diaChi) {
    final t = diaChi.toLowerCase();
    if (_g.isV1) {
      for (final q in _quanV1) {
        if (t.contains(q.ten.toLowerCase())) {
          setState(() {
            _g.quanV1 = q;
            _g.phuongV1 = null;
          });
          _napPhuongV1(q.ma);
          widget.onChanged?.call(_g);
          return true;
        }
      }
    } else {
      for (final p in _phuongV2) {
        if (RegExp('(?![0-9])').hasMatch(t)) {
          setState(() {
            _g.phuong = p;
            _g.khuVucId = null;
          });
          widget.onChanged?.call(_g);
          return true;
        }
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

  // Chọn Tỉnh
  Future<void> _chonTinh() async {
    final ds = _g.isV1 ? _tinhV1 : _tinhV2;
    if (ds.isEmpty) {
      if (_g.isV1) {
        await _napTinhV1();
      } else {
        await _napTinhV2();
      }
      return;
    }
    final t = await _bangChon<TinhThanh>('Tìm tỉnh, thành', ds, (x) => x.ten, (x) => x.ma == _g.maTinh);
    if (t == null || t.ma == _g.maTinh) return;

    setState(() {
      _g.maTinh = t.ma;
      _g.tenTinh = t.ten;
      _g.quanV1 = null;
      _g.phuongV1 = null;
      _g.phuong = null;
      _g.khuVucId = null;
    });
    widget.onChanged?.call(_g);

    if (_g.isV1) {
      await _napQuanV1(t.ma);
    } else {
      await _napPhuongV2(t.ma);
    }
  }

  // Chọn Quận (V1)
  Future<void> _chonQuanV1() async {
    if (_g.maTinh == null) return;
    if (_quanV1.isEmpty) return _napQuanV1(_g.maTinh!);
    final q = await _bangChon<QuanHuyenV1>('Tìm quận, huyện', _quanV1, (x) => x.ten, (x) => x.ma == _g.quanV1?.ma);
    if (q == null) return;

    setState(() {
      _g.quanV1 = q;
      _g.phuongV1 = null;
    });
    widget.onChanged?.call(_g);
    await _napPhuongV1(q.ma);
  }

  // Chọn Phường V1
  Future<void> _chonPhuongV1() async {
    if (_g.quanV1 == null) return;
    if (_phuongV1.isEmpty) return _napPhuongV1(_g.quanV1!.ma);
    final p = await _bangChon<PhuongXaV1>('Tìm phường, xã', _phuongV1, (x) => x.nhan, (x) => x.ma == _g.phuongV1?.ma);
    if (p == null) return;

    setState(() {
      _g.phuongV1 = p;
    });
    widget.onChanged?.call(_g);
  }

  // Chọn Phường V2
  Future<void> _chonPhuongV2() async {
    if (_g.maTinh == null) return;
    if (_phuongV2.isEmpty) return _napPhuongV2(_g.maTinh!);
    final p = await _bangChon<PhuongXa>('Tìm phường, xã', _phuongV2, (x) => x.nhan, (x) => x.ma == _g.phuong?.ma);
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
    if (_g.isV1) {
      if (_g.quanV1 != null) {
        if (_g.quanV1!.khuVucId != null) {
          return 'Khu vực phục vụ: ${_g.quanV1!.tenKhuVuc ?? _g.quanV1!.ten}';
        } else if (_g.quanV1!.maTinh == DiaGioiApiService.maHcm) {
          return 'Khu vực: ${_g.quanV1!.ten}';
        } else {
          return widget.batBuocTrongKhuVuc ? null : 'Nằm ngoài khu vực phục vụ.';
        }
      }
      return null;
    } else {
      final p = _g.phuong;
      if (p == null) return null;
      if (p.khuVuc.isEmpty) {
        return widget.batBuocTrongKhuVuc ? null : 'Ngoài khu vực phục vụ: vẫn lưu được, chưa đặt dịch vụ tại đây được.';
      }
      if (p.khuVuc.length == 1) return 'Khu vực: ${p.khuVuc.first.ten}';
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dsTinh = _g.isV1 ? _tinhV1 : _tinhV2;
    final tenTinh = dsTinh.where((t) => t.ma == _g.maTinh).map((t) => t.ten).firstOrNull ?? _g.tenTinh;
    final nhieuKv = !_g.isV1 && (_g.phuong?.khuVuc.length ?? 0) > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ================= Thanh Toggle Chuyển Đổi V1 / V2 =================
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (_g.isV1) return;
                    setState(() {
                      _g.isV1 = true;
                    });
                    _napTinhV1();
                    widget.onChanged?.call(_g);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _g.isV1 ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: _g.isV1
                          ? [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 4, offset: const Offset(0, 1))]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '📍 Địa chỉ cũ (Quận/Huyện)',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: _g.isV1 ? FontWeight.bold : FontWeight.w500,
                          color: _g.isV1 ? AppColors.brand500 : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (!_g.isV1) return;
                    setState(() {
                      _g.isV1 = false;
                    });
                    _napTinhV2();
                    widget.onChanged?.call(_g);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: !_g.isV1 ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: !_g.isV1
                          ? [BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 4, offset: const Offset(0, 1))]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '🏛️ Địa chỉ mới (Sáp nhập)',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: !_g.isV1 ? FontWeight.bold : FontWeight.w500,
                          color: !_g.isV1 ? AppColors.brand500 : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

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
            loi: f.errorText ?? (dsTinh.isEmpty ? _loi : null),
          ),
        ),
        const SizedBox(height: 12),

        // ================= GIAO DIỆN KIỂU CŨ V1 (3 CẤP) =================
        if (_g.isV1) ...[
          // Ô 2: Quận / Huyện
          FormField<int>(
            validator: (_) => _g.quanV1 == null ? 'Vui lòng chọn quận, huyện' : null,
            builder: (f) => _o(
              nhan: 'Quận, huyện *',
              icon: Icons.share_location_outlined,
              giaTri: _taiQuanV1 ? 'Đang tải…' : _g.quanV1?.ten,
              onTap: () async {
                await _chonQuanV1();
                f.didChange(_g.quanV1?.ma);
              },
              loi: f.errorText ?? (_quanV1.isEmpty && !_taiQuanV1 ? _loi : null),
            ),
          ),
          const SizedBox(height: 12),

          // Ô 3: Phường / Xã V1
          FormField<int>(
            validator: (_) => _g.phuongV1 == null ? 'Vui lòng chọn phường, xã' : null,
            builder: (f) => _o(
              nhan: 'Phường, xã *',
              icon: Icons.map_outlined,
              giaTri: _taiPhuongV1 ? 'Đang tải…' : _g.phuongV1?.nhan,
              onTap: () async {
                await _chonPhuongV1();
                f.didChange(_g.phuongV1?.ma);
              },
              loi: f.errorText ?? (_phuongV1.isEmpty && !_taiPhuongV1 ? _loi : null),
              goiY: _ghiChu(),
            ),
          ),
        ],

        // ================= GIAO DIỆN KIỂU MỚI V2 (2 CẤP) =================
        if (!_g.isV1) ...[
          FormField<int>(
            validator: (_) {
              if (_g.phuong == null) return 'Vui lòng chọn phường, xã';
              if (widget.batBuocTrongKhuVuc && _g.ngoaiKhuVuc) {
                return 'Phường, xã này ngoài khu vực phục vụ.';
              }
              return null;
            },
            builder: (f) => _o(
              nhan: 'Phường, xã *',
              icon: Icons.map_outlined,
              giaTri: _taiPhuongV2 ? 'Đang tải…' : _g.phuong?.nhan,
              onTap: () async {
                await _chonPhuongV2();
                f.didChange(_g.phuong?.ma);
              },
              loi: f.errorText ?? (_phuongV2.isEmpty && !_taiPhuongV2 ? _loi : null),
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
