import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../services/address_api_service.dart';
import '../../services/location_service.dart';
import '../../services/service_catalog_api_service.dart';

/// Thêm / sửa một địa chỉ của khách hàng. Có thể điền địa chỉ từ vị trí GPS hiện tại.
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
  final AddressApiService _api = AddressApiService();
  late final TextEditingController _diaChiCtrl;
  late final TextEditingController _luuYCtrl;

  List<Map<String, dynamic>> _khuVucs = [];
  int? _khuVucId;
  bool _laMacDinh = false;
  bool _saving = false;
  bool _locating = false;

  bool get _isEdit => widget.diaChi != null;

  @override
  void initState() {
    super.initState();
    final d = widget.diaChi;
    _diaChiCtrl = TextEditingController(text: d?.diaChiChiTiet ?? '');
    _luuYCtrl = TextEditingController(text: d?.luuYDacBiet ?? '');
    _khuVucId = d?.khuVucId;
    _laMacDinh = d?.laMacDinh ?? false;
    _loadAreas();
    if (widget.autoLocate) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _useCurrentLocation());
    }
  }

  @override
  void dispose() {
    _diaChiCtrl.dispose();
    _luuYCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAreas() async {
    final res = await ServiceCatalogApiService().getAreas();
    if (!mounted || !res.success || res.data == null) return;
    setState(() {
      _khuVucs = res.data!
          .where((k) => k['trangThai'] == null || k['trangThai'] == 'HoatDong'
              || k['id'] == _khuVucId)
          .toList();
      if (_khuVucId != null && !_khuVucs.any((k) => k['id'] == _khuVucId)) {
        _khuVucId = null;
      }
    });
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
      setState(() => _diaChiCtrl.text = text);
      _showSnack(
          'Đã điền địa chỉ theo vị trí hiện tại. Bạn có thể bổ sung số nhà, tầng, căn hộ.',
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
      final res = _isEdit
          ? await _api.updateAddress(
              widget.khachHangId,
              widget.diaChi!.id,
              diaChiChiTiet: _diaChiCtrl.text.trim(),
              khuVucId: _khuVucId,
              luuYDacBiet: luuY.isEmpty ? null : luuY,
              laMacDinh: _laMacDinh ? true : null,
            )
          : await _api.createAddress(
              widget.khachHangId,
              diaChiChiTiet: _diaChiCtrl.text.trim(),
              khuVucId: _khuVucId,
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
              TextFormField(
                controller: _diaChiCtrl,
                maxLines: 2,
                maxLength: 300,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ chi tiết *',
                  hintText: 'Số nhà, đường, phường/xã, tỉnh/thành',
                  prefixIcon: Icon(Icons.home_outlined),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Vui lòng nhập địa chỉ'
                    : null,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int?>(
                initialValue: _khuVucId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Khu vực (không bắt buộc)',
                  prefixIcon: Icon(Icons.map_outlined),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                      value: null, child: Text('Chưa chọn')),
                  ..._khuVucs.map((k) => DropdownMenuItem<int?>(
                        value: int.tryParse(k['id'].toString()),
                        child: Text(
                          [k['tenKhuVuc'], k['tinhThanh']]
                              .where((e) => e != null)
                              .join(', '),
                          overflow: TextOverflow.ellipsis,
                        ),
                      )),
                ],
                onChanged: (v) => setState(() => _khuVucId = v),
              ),
              const SizedBox(height: 16),
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
