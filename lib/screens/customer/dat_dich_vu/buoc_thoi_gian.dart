import 'package:flutter/material.dart';
import '../../../core/app_colors.dart';
import '../../../services/address_api_service.dart';
import '../../../services/catalog_ui.dart';
import '../../../services/lich_goi_thang.dart';
import '../../../widgets/lich_thang.dart';

/// Bước 3: thời lượng / gói, ngày, giờ bắt đầu, các thứ của gói tháng, địa chỉ, ghi chú.
/// Trạng thái nằm ở BookingScreen; widget này chỉ hiển thị và báo lựa chọn lên.
class BuocThoiGian extends StatelessWidget {
  final String loai;
  final List<Map<String, dynamic>> bienThes;
  final int? dichVuId;
  final ValueChanged<int> onChonBienThe;

  final DateTime? ngay;
  final DateTime ngayDau;
  final DateTime ngayCuoi;
  final ValueChanged<DateTime> onChonNgay;

  final List<TimeOfDay> khungGio;
  final TimeOfDay? gio;
  final bool Function(TimeOfDay) gioHopLe;
  final ValueChanged<TimeOfDay> onChonGio;

  final Set<int> thuGoi;
  final int soBuoiGoi;
  final List<DateTime> lichGoi;
  final String? loiLichGoi;
  final ValueChanged<Set<int>> onDoiThu;

  final DiaChi? diaChi;
  final bool dangTaiDiaChi;
  final VoidCallback onChonDiaChi;

  final TextEditingController ghiChu;

  const BuocThoiGian({
    super.key,
    required this.loai,
    required this.bienThes,
    required this.dichVuId,
    required this.onChonBienThe,
    required this.ngay,
    required this.ngayDau,
    required this.ngayCuoi,
    required this.onChonNgay,
    required this.khungGio,
    required this.gio,
    required this.gioHopLe,
    required this.onChonGio,
    required this.thuGoi,
    required this.soBuoiGoi,
    required this.lichGoi,
    required this.loiLichGoi,
    required this.onDoiThu,
    required this.diaChi,
    required this.dangTaiDiaChi,
    required this.onChonDiaChi,
    required this.ghiChu,
  });

  bool get _laGoi => loai == 'GoiThang';

  static String hhmm(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  static String ddmm(DateTime d) =>
      '${LichGoiThang.nhanThu[d.weekday - 1]} ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  /// Nhãn ngắn của biến thể: phần trong ngoặc của tên ("2 giờ", "4 buổi/tháng"), không có thì theo thời lượng.
  static String nhanBienThe(Map<String, dynamic> b) {
    final ten = b['tenDichVu']?.toString() ?? '';
    final m = RegExp(r'\(([^)]+)\)\s*$').firstMatch(ten);
    if (m != null) return m.group(1)!;
    final phut = CatalogUi.toInt(b['thoiGianThucHienPhut']);
    if (phut > 0) return phut % 60 == 0 ? '${phut ~/ 60} giờ' : '$phut phút';
    return ten.isEmpty ? 'Dịch vụ' : ten;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        _khoi(_laGoi ? 'Gói dịch vụ' : 'Thời lượng', _luoiBienThe()),
        const SizedBox(height: 10),
        _khoi(
          _laGoi ? 'Ngày bắt đầu gói' : 'Ngày làm việc',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LichThang(
                ngayChon: ngay,
                ngayDau: ngayDau,
                ngayCuoi: ngayCuoi,
                ngayTo: _laGoi && loiLichGoi == null ? lichGoi.toSet() : const {},
                onChon: onChonNgay,
              ),
              const SizedBox(height: 6),
              Text(
                _laGoi
                    ? 'Gói tháng chỉ được bắt đầu trong vòng 3 tháng tới.'
                    : 'Đặt theo lần chỉ được chọn ngày trong vòng 1 tháng tới.',
                style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _khoi('Giờ bắt đầu', _luoiGio()),
        if (_laGoi) ...[
          const SizedBox(height: 10),
          _khoi('Các thứ trong tuần', _thuTrongTuan()),
        ],
        const SizedBox(height: 10),
        _khoi('Địa điểm làm việc', _theDiaChi()),
        const SizedBox(height: 10),
        _khoi(
          'Ghi chú cho người làm',
          TextField(
            controller: ghiChu,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'VD: Nhà có thú cưng, cần lau kính kỹ...'),
          ),
        ),
      ],
    );
  }

  Widget _luoiBienThe() {
    if (bienThes.isEmpty) {
      return const Text('Chưa có lựa chọn cho hình thức này.',
          style: TextStyle(color: AppColors.textSecondary));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final b in bienThes)
          () {
            final id = CatalogUi.toInt(b['id']);
            final chon = id == dichVuId;
            return GestureDetector(
              onTap: () => onChonBienThe(id),
              child: Container(
                constraints: const BoxConstraints(minWidth: 96),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: chon ? AppColors.brandSurface : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: chon ? AppColors.brand500 : AppColors.divider, width: chon ? 1.5 : 1),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(nhanBienThe(b),
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(CatalogUi.money(b['donGiaThamKhao']),
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: chon ? AppColors.brand600 : AppColors.textSecondary)),
                  ],
                ),
              ),
            );
          }(),
      ],
    );
  }

  Widget _luoiGio() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final t in khungGio)
          () {
            final chon = gio == t;
            // Khung giờ chưa đủ 1 giờ so với hiện tại (tính theo buổi đầu tiên) bị khoá
            final hopLe = gioHopLe(t);
            return GestureDetector(
              onTap: hopLe ? () => onChonGio(t) : null,
              child: Container(
                width: 72,
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: chon
                      ? AppColors.brand500
                      : (hopLe ? Colors.white : AppColors.divider.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: chon ? AppColors.brand500 : AppColors.divider),
                ),
                child: Text(
                  hhmm(t),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: chon ? Colors.white : (hopLe ? AppColors.textPrimary : AppColors.textMuted),
                    decoration: hopLe ? null : TextDecoration.lineThrough,
                    decorationColor: AppColors.textMuted,
                  ),
                ),
              ),
            );
          }(),
      ],
    );
  }

  /// Chọn thứ cho gói tháng: mẫu chọn nhanh, 7 nút thứ, xem trước lịch đủ số buổi.
  Widget _thuTrongTuan() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Chọn thứ để đủ $soBuoiGoi buổi trong vòng 1 tháng kể từ ngày bắt đầu.',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final e in LichGoiThang.mau.entries)
              ActionChip(
                label: Text(e.key, style: const TextStyle(fontSize: 12.5)),
                onPressed: () => onDoiThu({...e.value}),
                side: BorderSide(
                    color: thuGoi.length == e.value.length && thuGoi.containsAll(e.value)
                        ? AppColors.brand500
                        : AppColors.divider),
                backgroundColor: Colors.white,
              ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (int w = 1; w <= 7; w++)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: w < 7 ? 6 : 0),
                  child: GestureDetector(
                    onTap: () {
                      final moi = {...thuGoi};
                      moi.contains(w) ? moi.remove(w) : moi.add(w);
                      onDoiThu(moi);
                    },
                    child: Container(
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: thuGoi.contains(w) ? AppColors.brand500 : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: thuGoi.contains(w) ? AppColors.brand500 : AppColors.divider),
                      ),
                      child: Text(
                        LichGoiThang.nhanThu[w - 1],
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: thuGoi.contains(w) ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: loiLichGoi == null ? AppColors.greenLight : AppColors.orangeLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: loiLichGoi != null
              ? Text(loiLichGoi!, style: const TextStyle(fontSize: 13, color: AppColors.orange600, height: 1.4))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$soBuoiGoi buổi, từ ${ddmm(lichGoi.first)} đến ${ddmm(lichGoi.last)}',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.green600)),
                    const SizedBox(height: 4),
                    Text(lichGoi.map(ddmm).join(' · '),
                        style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4)),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _theDiaChi() {
    final ngoaiKhuVuc = diaChi != null && !diaChi!.coKhuVuc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onChonDiaChi,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: ngoaiKhuVuc ? AppColors.error : AppColors.divider),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined, color: AppColors.brand500),
                const SizedBox(width: 10),
                Expanded(
                  child: dangTaiDiaChi
                      ? const Text('Đang tải địa chỉ...', style: TextStyle(color: AppColors.textSecondary))
                      : diaChi == null
                          ? const Text('Chưa có địa chỉ làm việc', style: TextStyle(color: AppColors.textSecondary))
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(diaChi!.tieuDe, style: const TextStyle(fontWeight: FontWeight.w700)),
                                Text(diaChi!.diaChiChiTiet,
                                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                              ],
                            ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
        if (ngoaiKhuVuc)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text('Địa chỉ này nằm ngoài khu vực bTaskee đang phục vụ.',
                style: TextStyle(fontSize: 12.5, color: AppColors.error)),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onChonDiaChi,
            icon: const Icon(Icons.add_location_alt_outlined, size: 18),
            label: const Text('Thêm địa chỉ'),
          ),
        ),
      ],
    );
  }

  static Widget _khoi(String tieuDe, Widget con) => Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tieuDe,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            con,
          ],
        ),
      );
}
