import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../services/address_api_service.dart';
import '../../services/location_service.dart';
import '../../widgets/dia_chi_fields.dart';

/// Thêm / sửa một địa chỉ của khách hàng: tỉnh, thành → phường, xã (provinces.open-api.vn v2) + số nhà.
/// Khu vực (quận, huyện) tự suy ra từ phường. Có thể điền địa chỉ từ vị trí GPS hiện tại.
/// Trả về `true` khi đã lưu.
class AddressFormScreen extends StatefulWidget {
  final int khachHangId;
  final DiaChi? diaChi; // null = thêm mới
  final bool autoLocate; // mở form là lấy GPS ngay (nút "Thêm từ vị trí hiện tại")

  const AddressFormScreen(
      {super.key, required this.khachHangId, this.diaChi, this.autoLocate = false});

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fieldsKey = GlobalKey<DiaChiFieldsState>();
  final AddressApiService _api = AddressApiService();
  late final TextEditingController _soNhaCtrl;
  late final TextEditingController _luuYCtrl;
  final DiaChiDangChon _diaChi = DiaChiDangChon();

  bool _laMacDinh = false;
  bool _saving = false;
  bool _locating = false;

  bool get _isEdit => widget.diaChi != null;

  @override
  void initState() {
    super.initState();
    final d = widget.diaChi;
    // Địa chỉ cũ không tách được tỉnh, phường: để cả chuỗi vào ô số nhà, người dùng chọn lại tỉnh, phường
    _soNhaCtrl = TextEditingController(text: d?.soNhaTenDuong ?? d?.diaChiChiTiet ?? '');
    _luuYCtrl = TextEditingController(text: d?.luuYDacBiet ?? '');
    if (d?.maTinh != null) _diaChi.maTinh = d!.maTinh;
    _diaChi.khuVucId = d?.khuVucId;
    _laMacDinh = d?.laMacDinh ?? false;
    if (widget.autoLocate) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _useCurrentLocation());
    }
  }

  @override
  void dispose() {
    _soNhaCtrl.dispose();
    _luuYCtrl.dispose();
    super.dispose();
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      final r = await LocationService.getCurrentPosition();
      if (!mounted) return;
      if (!r.ok) {
        _showSnack(r.error!, AppColors.error);
        return;
      }
      final text = await LocationService.reverseGeocode(
          r.position!.latitude, r.position!.longitude);
      if (!mounted) return;
      if (text == null) {
        _showSnack('Không tra được địa chỉ từ vị trí. Vui lòng nhập tay.',
            AppColors.error);
        return;
      }
      // Chọn sẵn phường nếu đọc được tên phường; ô số nhà lấy phần đầu của địa chỉ
      final timDuoc = _fieldsKey.currentState?.doanPhuong(text) ?? false;
      final phan = text.split(',').map((e) => e.trim()).toList();
      setState(() => _soNhaCtrl.text = phan.length > 2 ? phan.take(2).join(', ') : text);
      _showSnack(
          timDuoc
              ? 'Đã điền địa chỉ theo vị trí hiện tại. Kiểm tra lại số nhà, tầng, căn hộ.'
              : 'Đã điền số nhà, đường theo vị trí. Vui lòng chọn phường, xã / quận, huyện.',
          AppColors.success);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      final luuY = _luuYCtrl.text.trim();
      final maPhuong = _diaChi.maPhuong;
      final maQuan = _diaChi.maQuan;
      final khuVucId = _diaChi.nhieuKhuVuc ? _diaChi.khuVuc?.id : null;
      final res = _isEdit
          ? await _api.updateAddress(
              widget.khachHangId,
              widget.diaChi!.id,
              soNhaTenDuong: _soNhaCtrl.text.trim(),
              maTinh: _diaChi.maTinhGui!,
              maQuan: maQuan,
              maPhuong: maPhuong,
              khuVucId: khuVucId,
              dienTichNha: widget.diaChi!.dienTichNha,
              luuYDacBiet: luuY.isEmpty ? null : luuY,
              laMacDinh: _laMacDinh ? true : null,
            )
          : await _api.createAddress(
              widget.khachHangId,
              soNhaTenDuong: _soNhaCtrl.text.trim(),
              maTinh: _diaChi.maTinhGui!,
              maQuan: maQuan,
              maPhuong: maPhuong,
              khuVucId: khuVucId,
              luuYDacBiet: luuY.isEmpty ? null : luuY,
              laMacDinh: _laMacDinh,
            );
      if (!mounted) return;
      if (!res.success) {
        _showSnack(res.message ?? 'Không lưu được địa chỉ', AppColors.error);
        return;
      }
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) _showSnack('Lỗi kết nối: $e', AppColors.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text(_isEdit ? 'Sửa địa chỉ' : 'Thêm địa chỉ')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              OutlinedButton.icon(
                onPressed: _locating ? null : _useCurrentLocation,
                icon: _locating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.my_location),
                label: const Text('Dùng vị trí hiện tại (GPS)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brand600,
                  side: const BorderSide(color: AppColors.brand500),
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
              const SizedBox(height: 16),
              DiaChiFields(
                key: _fieldsKey,
                giaTri: _diaChi,
                soNhaCtrl: _soNhaCtrl,
                maPhuongBanDau: widget.diaChi?.maPhuong,
                maQuanBanDau: widget.diaChi?.maQuan,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _luuYCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Lưu ý cho người làm (không bắt buộc)',
                  hintText: 'VD: nhà có chó, gửi xe ở hầm B1...',
                  prefixIcon: Icon(Icons.sticky_note_2_outlined),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _laMacDinh,
                activeThumbColor: AppColors.brand500,
                title: const Text('Đặt làm địa chỉ mặc định'),
                onChanged: (widget.diaChi?.laMacDinh ?? false)
                    ? null // đang là mặc định: đổi bằng cách chọn địa chỉ khác
                    : (v) => setState(() => _laMacDinh = v),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text('Lưu địa chỉ'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
