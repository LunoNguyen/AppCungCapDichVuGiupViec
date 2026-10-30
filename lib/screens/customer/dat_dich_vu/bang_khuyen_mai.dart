import 'package:flutter/material.dart';
import '../../../core/app_colors.dart';
import '../../../services/booking_api_service.dart';
import '../../../services/catalog_ui.dart';

/// Bảng trượt "Chọn khuyến mãi": mã dùng được kèm số tiền giảm, mã chưa đủ điều kiện kèm lý do.
/// Trả về code được chọn, null nếu đóng.
Future<String?> moBangKhuyenMai(
  BuildContext context, {
  required int dichVuId,
  required String loaiHinhDat,
  String? ngayThucHien,
  String? gioBatDau,
  String? maDangDung,
  List<int>? dichVuIds,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (_) => _BangKhuyenMai(
      dichVuId: dichVuId,
      loaiHinhDat: loaiHinhDat,
      ngayThucHien: ngayThucHien,
      gioBatDau: gioBatDau,
      maDangDung: maDangDung,
      dichVuIds: dichVuIds,
    ),
  );
}

class _BangKhuyenMai extends StatefulWidget {
  final int dichVuId;
  final String loaiHinhDat;
  final String? ngayThucHien;
  final String? gioBatDau;
  final String? maDangDung;
  final List<int>? dichVuIds;

  const _BangKhuyenMai({
    this.dichVuIds,
    required this.dichVuId,
    required this.loaiHinhDat,
    this.ngayThucHien,
    this.gioBatDau,
    this.maDangDung,
  });

  @override
  State<_BangKhuyenMai> createState() => _BangKhuyenMaiState();
}

class _BangKhuyenMaiState extends State<_BangKhuyenMai> {
  List<Map<String, dynamic>> _ds = [];
  bool _dangTai = true;
  String? _loi;

  @override
  void initState() {
    super.initState();
    _tai();
  }

  Future<void> _tai() async {
    setState(() {
      _dangTai = true;
      _loi = null;
    });
    try {
      final res = await BookingApiService().getAvailablePromotions(
        dichVuId: widget.dichVuId,
        loaiHinhDat: widget.loaiHinhDat,
        ngayThucHien: widget.ngayThucHien,
        gioBatDau: widget.gioBatDau,
        dichVuIds: widget.dichVuIds,
      );
      if (!mounted) return;
      setState(() {
        if (res.success) {
          // Mã dùng được lên trước
          _ds = [...?res.data]..sort((a, b) => (b['dungDuoc'] == true ? 1 : 0) - (a['dungDuoc'] == true ? 1 : 0));
        } else {
          _loi = res.message ?? 'Không tải được khuyến mãi';
        }
      });
    } catch (_) {
      if (mounted) setState(() => _loi = 'Không kết nối được máy chủ');
    } finally {
      if (mounted) setState(() => _dangTai = false);
    }
  }

  static String _hsd(dynamic v) {
    final s = v?.toString() ?? '';
    final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(s);
    return m == null ? '' : 'HSD ${m[3]}/${m[2]}/${m[1]}';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Chọn khuyến mãi',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(child: _noiDung()),
          ],
        ),
      ),
    );
  }

  Widget _noiDung() {
    if (_dangTai) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator(color: AppColors.brand500)),
      );
    }
    if (_loi != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_loi!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error)),
            TextButton(onPressed: _tai, child: const Text('Thử lại')),
          ],
        ),
      );
    }
    if (_ds.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Text('Hiện chưa có khuyến mãi cho dịch vụ này.',
            textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.all(16),
      itemCount: _ds.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _dong(_ds[i]),
    );
  }

  Widget _dong(Map<String, dynamic> km) {
    final code = km['codeKhuyenMai']?.toString() ?? '';
    final dungDuoc = km['dungDuoc'] == true;
    final dangDung = code.isNotEmpty && code.toUpperCase() == widget.maDangDung?.toUpperCase();
    final moTa = km['moTa']?.toString() ?? '';
    final hsd = _hsd(km['ngayKetThuc']);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: dungDuoc ? Colors.white : AppColors.scaffoldBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dangDung ? AppColors.brand500 : AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(km['tenChuongTrinh']?.toString() ?? code,
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(code, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.brand600, fontSize: 13)),
                if (moTa.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(moTa, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.35)),
                ],
                if (hsd.isNotEmpty)
                  Text(hsd, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 4),
                dungDuoc
                    ? Text('-${CatalogUi.money(km['soTienGiam'])}',
                        style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.green600))
                    : Text(km['lyDo']?.toString() ?? 'Chưa đủ điều kiện',
                        style: const TextStyle(fontSize: 12.5, color: AppColors.orange600)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: dungDuoc && !dangDung ? () => Navigator.pop(context, code) : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              minimumSize: const Size(0, 38),
            ),
            child: Text(dangDung ? 'Đang dùng' : 'Áp dụng'),
          ),
        ],
      ),
    );
  }
}
