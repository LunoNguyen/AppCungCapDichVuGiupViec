import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../services/chinh_sach.dart';

/// Màn "Chính sách" ở tab Tài khoản (khách, khách chưa đăng nhập, cộng tác viên):
/// danh sách Điều khoản sử dụng / Quy trình khiếu nại / Chính sách bảo mật, bấm để đọc.
class ChinhSachScreen extends StatefulWidget {
  const ChinhSachScreen({super.key});

  @override
  State<ChinhSachScreen> createState() => _ChinhSachScreenState();
}

class _ChinhSachScreenState extends State<ChinhSachScreen> {
  List<TaiLieuChinhSach> _ds = [];
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
    final res = await ChinhSachApiService().danhSach();
    if (!mounted) return;
    setState(() {
      _dangTai = false;
      if (res.success && (res.data?.isNotEmpty ?? false)) {
        _ds = res.data!;
      } else {
        _loi = (res.message ?? '').startsWith('Lỗi kết nối') || res.message == null
            ? 'Không kết nối được máy chủ'
            : res.message;
      }
    });
  }

  static const _bieuTuong = {
    'dieu-khoan': Icons.gavel_rounded,
    'khieu-nai': Icons.support_agent_rounded,
    'bao-mat': Icons.privacy_tip_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(title: const Text('Chính sách')),
      body: _dangTai
          ? const Center(child: CircularProgressIndicator(color: AppColors.brand500))
          : _loi != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_rounded, size: 40, color: AppColors.textMuted),
                        const SizedBox(height: 10),
                        Text(_loi!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
                        TextButton(onPressed: _tai, child: const Text('Thử lại')),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _ds.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final t = _ds[i];
                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => TaiLieuChinhSachScreen(taiLieu: t)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: const BoxDecoration(color: AppColors.brandLight, shape: BoxShape.circle),
                                child: Icon(_bieuTuong[t.ma] ?? Icons.description_outlined, color: AppColors.brand500),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(t.ten,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
                                    if (t.moTa.isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Text(t.moTa,
                                          style: const TextStyle(
                                              fontSize: 12.5, color: AppColors.textSecondary, height: 1.35)),
                                    ],
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

/// Đọc một tài liệu chính sách. Bảng hiển thị thành từng thẻ (mỗi dòng một thẻ) để không phải cuộn ngang.
class TaiLieuChinhSachScreen extends StatelessWidget {
  final TaiLieuChinhSach taiLieu;

  const TaiLieuChinhSachScreen({super.key, required this.taiLieu});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text(taiLieu.ten, maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: SelectionArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Text(taiLieu.ten,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            for (final k in taiLieu.khoi) _khoi(k),
          ],
        ),
      ),
    );
  }

  static const _chu = TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.55);

  Widget _khoi(KhoiChinhSach k) {
    switch (k) {
      case KhoiTieuDe(:final noiDung):
        return Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 6),
          child: Text(noiDung,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        );
      case KhoiTieuDeNho(:final noiDung):
        return Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(noiDung,
              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        );
      case KhoiDoan(:final noiDung):
        // Mục con "(i)", "(ii)"… lùi vào một chút
        final con = RegExp(r'^\((i|ii|iii|iv|v|vi)\)').hasMatch(noiDung);
        return Padding(
          padding: EdgeInsets.only(top: 6, left: con ? 14 : 0),
          child: Text(noiDung, style: _chu),
        );
      case KhoiDanhSach(:final muc):
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final m in muc)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 8, right: 8, left: 2),
                        child: CircleAvatar(radius: 2.5, backgroundColor: AppColors.brand500),
                      ),
                      Expanded(child: Text(m, style: _chu)),
                    ],
                  ),
                ),
            ],
          ),
        );
      case KhoiBang(:final cot, :final dong):
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            children: [
              for (final d in dong)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.brandSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int i = 0; i < d.length; i++)
                        if (d[i].isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: i == 0 ? 0 : 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (i < cot.length)
                                  Text(cot[i],
                                      style: const TextStyle(
                                          fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                                Text(d[i],
                                    style: TextStyle(
                                        fontSize: 13.5,
                                        height: 1.45,
                                        fontWeight: i == 0 ? FontWeight.w700 : FontWeight.w400,
                                        color: AppColors.textPrimary)),
                              ],
                            ),
                          ),
                    ],
                  ),
                ),
            ],
          ),
        );
    }
  }
}
