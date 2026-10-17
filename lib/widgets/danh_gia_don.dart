import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_colors.dart';
import '../services/review_api_service.dart';

/// Nhãn trạng thái duyệt của đánh giá cho khách; null khi trạng thái lạ.
String? nhanTrangThaiDanhGia(Object? trangThai) => switch (trangThai) {
      'ChoDuyet' => 'Đang chờ bTaskee duyệt',
      'HienThi' => 'Đang hiển thị công khai',
      'An' => 'Không hiển thị công khai',
      _ => null,
    };

/// Đánh giá của một đơn đã hoàn thành (giống trang chi tiết đơn trên website):
/// - chưa đánh giá: chấm chất lượng, thái độ, nhận xét;
/// - đã đánh giá: xem lại, sửa trong 7 ngày, trao đổi (bình luận) với CSKH bTaskee.
///
/// [danhGia] là map `danhGia` của chi tiết đơn (null = chưa đánh giá).
/// [onChanged] được gọi sau khi gửi / sửa / bình luận để tải lại đơn.
class DanhGiaDon extends StatefulWidget {
  final int donDatId;
  final int khachHangId;
  final Map<String, dynamic>? danhGia;
  final Future<void> Function() onChanged;

  const DanhGiaDon({
    super.key,
    required this.donDatId,
    required this.khachHangId,
    required this.danhGia,
    required this.onChanged,
  });

  @override
  State<DanhGiaDon> createState() => _DanhGiaDonState();
}

class _DanhGiaDonState extends State<DanhGiaDon> {
  final _api = ReviewApiService();
  final _nhanXetCtrl = TextEditingController();
  final _binhLuanCtrl = TextEditingController();
  int _chatLuong = 0;
  int _thaiDo = 0;
  bool _dangSua = false;
  bool _dangGui = false;

  Map<String, dynamic>? get _dg => widget.danhGia;

  @override
  void dispose() {
    _nhanXetCtrl.dispose();
    _binhLuanCtrl.dispose();
    super.dispose();
  }

  void _bao(String msg, {bool loi = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: loi ? AppColors.error : AppColors.success,
    ));
  }

  void _batDauSua() {
    setState(() {
      _dangSua = true;
      _chatLuong = int.tryParse('${_dg!['diemChatLuong']}') ?? 5;
      _thaiDo = int.tryParse('${_dg!['diemThaiDo']}') ?? 5;
      _nhanXetCtrl.text = _dg!['nhanXet']?.toString() ?? '';
    });
  }

  Future<void> _guiDanhGia() async {
    if (_chatLuong == 0 || _thaiDo == 0) {
      _bao('Vui lòng chấm đủ hai mục: chất lượng và thái độ.', loi: true);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _dangGui = true);
    final nhanXet = _nhanXetCtrl.text.trim();
    final res = _dg == null
        ? await _api.createReview(
            donDatId: widget.donDatId,
            khachHangId: widget.khachHangId,
            diemChatLuong: _chatLuong,
            diemThaiDo: _thaiDo,
            nhanXet: nhanXet.isEmpty ? null : nhanXet,
          )
        : await _api.updateReview(
            donDatId: widget.donDatId,
            khachHangId: widget.khachHangId,
            diemChatLuong: _chatLuong,
            diemThaiDo: _thaiDo,
            nhanXet: nhanXet,
          );
    if (!mounted) return;
    setState(() => _dangGui = false);
    if (!res.success) {
      _bao(res.message ?? 'Không gửi được đánh giá.', loi: true);
      return;
    }
    _bao(_dg == null ? 'Cảm ơn bạn đã đánh giá.' : 'Đã cập nhật đánh giá.');
    setState(() => _dangSua = false);
    await widget.onChanged();
  }

  Future<void> _guiBinhLuan() async {
    final noiDung = _binhLuanCtrl.text.trim();
    if (noiDung.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _dangGui = true);
    final res = await _api.comment(
        donDatId: widget.donDatId, khachHangId: widget.khachHangId, noiDung: noiDung);
    if (!mounted) return;
    setState(() => _dangGui = false);
    if (!res.success) {
      _bao(res.message ?? 'Không gửi được bình luận.', loi: true);
      return;
    }
    _binhLuanCtrl.clear();
    _bao('Đã gửi bình luận. bTaskee sẽ phản hồi sớm.');
    await widget.onChanged();
  }

  static String _gio(dynamic v) {
    final d = DateTime.tryParse(v?.toString() ?? '');
    return d == null ? '' : DateFormat('HH:mm dd/MM/yyyy').format(d);
  }

  Widget _chamSao(String nhan, int diem, ValueChanged<int> chon) {
    return Row(
      children: [
        SizedBox(
            width: 92,
            child: Text(nhan,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
        for (var i = 1; i <= 5; i++)
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            tooltip: '$i sao',
            icon: Icon(i <= diem ? Icons.star_rounded : Icons.star_border_rounded,
                color: AppColors.star, size: 30),
            onPressed: _dangGui ? null : () => setState(() => chon(i)),
          ),
      ],
    );
  }

  Widget _saoTinh(String nhan, dynamic diem) {
    final d = int.tryParse('$diem') ?? 0;
    return Row(children: [
      SizedBox(
          width: 92,
          child: Text(nhan,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
      ...List.generate(
          5,
          (i) => Icon(i < d ? Icons.star_rounded : Icons.star_border_rounded,
              color: AppColors.star, size: 20)),
    ]);
  }

  Widget _formDanhGia() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _chamSao('Chất lượng', _chatLuong, (v) => _chatLuong = v),
        _chamSao('Thái độ', _thaiDo, (v) => _thaiDo = v),
        if (_dg?['trangThai'] == 'HienThi')
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text('Sau khi sửa, đánh giá sẽ chờ duyệt lại trước khi hiển thị công khai.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ),
        const SizedBox(height: 8),
        TextField(
          controller: _nhanXetCtrl,
          maxLines: 3,
          maxLength: 1000,
          decoration: const InputDecoration(
            labelText: 'Nhận xét (không bắt buộc)',
            hintText: 'Cộng tác viên làm kỹ, đúng giờ…',
          ),
        ),
        Row(
          children: [
            if (_dg != null)
              TextButton(
                onPressed: _dangGui ? null : () => setState(() => _dangSua = false),
                child: const Text('Hủy'),
              ),
            const Spacer(),
            ElevatedButton(
              onPressed: _dangGui ? null : _guiDanhGia,
              child: Text(_dg == null ? 'Gửi đánh giá' : 'Lưu đánh giá'),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_dg == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Đánh giá giúp bTaskee giữ chất lượng cộng tác viên. Bạn sửa được trong 7 ngày sau khi gửi.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          _formDanhGia(),
        ],
      );
    }

    final coTheSua = _dg!['coTheSua'] == true;
    final traoDoi = (_dg!['traoDoi'] as List?)?.cast<Map>() ?? const [];
    final nhanXet = _dg!['nhanXet']?.toString();
    final nhanTrangThai = nhanTrangThaiDanhGia(_dg!['trangThai']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_dangSua)
          _formDanhGia()
        else ...[
          _saoTinh('Chất lượng', _dg!['diemChatLuong']),
          const SizedBox(height: 4),
          _saoTinh('Thái độ', _dg!['diemThaiDo']),
          if (nhanXet != null && nhanXet.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('"$nhanXet"',
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text('Gửi lúc ${_gio(_dg!['ngayDanhGia'])}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ),
              if (coTheSua)
                TextButton.icon(
                  onPressed: _batDauSua,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Sửa'),
                ),
            ],
          ),
          if (nhanTrangThai != null)
            Text(nhanTrangThai, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ],
        const Divider(height: 24),
        const Text('Trao đổi với bTaskee',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        if (traoDoi.isEmpty)
          const Text('Có góp ý thêm, cần hỗ trợ hay muốn khen cộng tác viên? Gửi bình luận bên dưới.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        for (final p in traoDoi) _tinNhan(Map<String, dynamic>.from(p)),
        const SizedBox(height: 8),
        TextField(
          controller: _binhLuanCtrl,
          minLines: 1,
          maxLines: 4,
          maxLength: 1000,
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(
            hintText: 'Viết bình luận hoặc phản hồi…',
            suffixIcon: IconButton(
              tooltip: 'Gửi bình luận',
              icon: const Icon(Icons.send_rounded, color: AppColors.brand500),
              onPressed: _dangGui ? null : _guiBinhLuan,
            ),
          ),
        ),
      ],
    );
  }

  Widget _tinNhan(Map<String, dynamic> p) {
    final laNhanVien = p['laNhanVien'] == true;
    return Align(
      alignment: laNhanVien ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: laNhanVien ? AppColors.brandSurface : const Color(0xFFF4F4F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(laNhanVien ? (p['nguoiGui']?.toString() ?? 'bTaskee') : 'Bạn',
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(p['noiDung']?.toString() ?? '',
                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(_gio(p['thoiGian']),
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
