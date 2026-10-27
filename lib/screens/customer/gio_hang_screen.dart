import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../services/catalog_ui.dart';
import '../../services/gio_hang.dart';
import '../../services/session_service.dart';
import '../../widgets/anh_khong_cat.dart';
import '../auth/login_screen.dart';
import 'booking_screen.dart';

/// Giỏ hàng (giống trang /gio-hang trên web): tick các dịch vụ để đặt chung một lịch, một hóa đơn,
/// làm song song từ cùng giờ bắt đầu. Tối đa 5 dịch vụ; gói tháng chỉ đặt một mình.
class GioHangScreen extends StatelessWidget {
  const GioHangScreen({super.key});

  Future<void> _dat(BuildContext context) async {
    final gio = GioHang.instance;
    final chon = gio.daChon;
    if (chon.isEmpty) return;
    final session = await SessionService.load();
    if (!context.mounted) return;
    if (session == null || !session.isCustomer) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => chon.length == 1
            ? BookingScreen(service: _dichVuChoMan(chon.first))
            : BookingScreen(
                service: _dichVuChoMan(chon.first),
                dichVuNhieu: chon,
              ),
      ),
    );
  }

  /// Dữ liệu dịch vụ tối thiểu để mở màn đặt (giống map từ /v1/services).
  static Map<String, dynamic> _dichVuChoMan(MonGio m) => {
    'id': m.id,
    'dichVuId': m.id,
    'tenDichVu': m.ten,
    'title': m.ten,
    'loaiHinhDat': m.loaiHinhDat,
    'loaiDichVuId': m.danhMucId,
    'donGiaThamKhao': m.gia,
    'thoiGianThucHienPhut': m.phut,
    'hinhAnhUrl': m.anh,
  };

  @override
  Widget build(BuildContext context) {
    final gio = GioHang.instance;
    return ListenableBuilder(
      listenable: gio,
      builder: (context, _) {
        final ds = gio.mon;
        final chon = gio.daChon;
        final loi = GioHang.loiDatChung(chon);
        return Scaffold(
          backgroundColor: AppColors.scaffoldBg,
          appBar: AppBar(
            title: Text('Giỏ hàng (${ds.length})'),
            actions: [
              if (ds.isNotEmpty)
                TextButton(
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('Xóa tất cả?'),
                        content: const Text('Bỏ mọi dịch vụ khỏi giỏ hàng.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c, false),
                            child: const Text('Không'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(c, true),
                            child: const Text('Xóa'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) gio.xoaTatCa();
                  },
                  child: const Text(
                    'Xóa tất cả',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
            ],
          ),
          body: ds.isEmpty
              ? _trong(context)
              : ListView(
                  padding: const EdgeInsets.only(bottom: 16),
                  children: [
                    CheckboxListTile(
                      tileColor: Colors.white,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: chon.length == ds.length,
                      onChanged: (v) => gio.chonTatCa(v == true),
                      title: Text(
                        'Chọn tất cả (${ds.length})',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final m in ds) _dong(context, m),
                  ],
                ),
          bottomNavigationBar: ds.isEmpty
              ? null
              : _thanhDay(context, chon, loi),
        );
      },
    );
  }

  Widget _trong(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.shopping_cart_outlined,
            size: 56,
            color: AppColors.brand500,
          ),
          const SizedBox(height: 12),
          const Text(
            'Giỏ hàng của bạn đang trống',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Thêm dịch vụ ở trang chi tiết để đặt nhiều dịch vụ trong một lần.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Khám phá dịch vụ'),
          ),
        ],
      ),
    ),
  );

  Widget _dong(BuildContext context, MonGio m) {
    final anh = CatalogUi.fileUrl(m.anh);
    final thayThe = Container(
      color: AppColors.brandLight,
      child: Icon(CatalogUi.iconFor(m.ten), color: AppColors.brand500),
    );
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.fromLTRB(4, 10, 8, 10),
      child: Row(
        children: [
          Checkbox(
            value: m.chon,
            onChanged: (_) => GioHang.instance.doiChon(m.id),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 52,
              height: 52,
              child: anh == null
                  ? thayThe
                  : AnhKhongCat(url: anh, thayThe: thayThe),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.ten,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    CatalogUi.loaiHinhLabel(m.loaiHinhDat),
                    if (m.phut > 0) GioHang.thoiLuong(m.phut),
                  ].join(' · '),
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  CatalogUi.money(m.gia),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.brand600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Xóa khỏi giỏ',
            onPressed: () => GioHang.instance.xoa(m.id),
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _thanhDay(BuildContext context, List<MonGio> chon, String? loi) {
    final gio = GioHang.instance;
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        10 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                '${chon.length} dịch vụ · xong sau ${GioHang.thoiLuong(gio.phutXong)}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const Spacer(),
              Text(
                CatalogUi.money(gio.tongGia),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.brand600,
                ),
              ),
            ],
          ),
          if (loi != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                loi,
                style: const TextStyle(fontSize: 12.5, color: AppColors.error),
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: chon.isEmpty || loi != null
                  ? null
                  : () => _dat(context),
              child: Text('Đặt dịch vụ (${chon.length})'),
            ),
          ),
        ],
      ),
    );
  }
}
