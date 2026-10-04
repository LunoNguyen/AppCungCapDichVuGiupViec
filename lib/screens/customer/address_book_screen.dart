import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../services/address_api_service.dart';
import '../../services/location_service.dart';
import 'address_form_screen.dart';

/// Sổ địa chỉ của khách hàng. Với [selectMode] = true, chạm vào một địa chỉ để chọn
/// (màn đặt lịch dùng) và màn hình trả về [DiaChi] đã chọn.
class AddressBookScreen extends StatefulWidget {
  final int khachHangId;
  final bool selectMode;
  final int? selectedId;

  const AddressBookScreen({
    super.key,
    required this.khachHangId,
    this.selectMode = false,
    this.selectedId,
  });

  @override
  State<AddressBookScreen> createState() => _AddressBookScreenState();
}

class _AddressBookScreenState extends State<AddressBookScreen> {
  final AddressApiService _api = AddressApiService();
  List<DiaChi> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.getAddresses(widget.khachHangId);
      if (!mounted) return;
      setState(() {
        if (res.success) {
          _items = res.data ?? [];
        } else {
          _error = res.message ?? 'Không tải được danh sách địa chỉ';
        }
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Lỗi kết nối: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  Future<void> _openForm([DiaChi? d, bool autoLocate = false]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddressFormScreen(
            khachHangId: widget.khachHangId, diaChi: d, autoLocate: autoLocate),
      ),
    );
    if (saved == true) {
      _showSnack(d == null ? 'Đã thêm địa chỉ' : 'Đã cập nhật địa chỉ',
          AppColors.success);
      _load();
    }
  }

  Future<void> _setDefault(DiaChi d) async {
    final res = await _api.setDefault(widget.khachHangId, d.id);
    if (!mounted) return;
    if (res.success) {
      _load();
    } else {
      _showSnack(res.message ?? 'Không đặt được mặc định', AppColors.error);
    }
  }

  Future<void> _delete(DiaChi d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá địa chỉ?'),
        content: Text(d.diaChiChiTiet),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Huỷ')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xoá', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final res = await _api.deleteAddress(widget.khachHangId, d.id);
    if (!mounted) return;
    if (res.success) {
      _showSnack('Đã xoá địa chỉ', AppColors.success);
      _load();
    } else {
      _showSnack(res.message ?? 'Không xoá được địa chỉ', AppColors.error);
    }
  }

  Widget _buildItem(DiaChi d) {
    final selected = widget.selectMode && d.id == widget.selectedId;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? AppColors.brand500 : AppColors.divider,
          width: selected ? 2 : 1,
        ),
      ),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: widget.selectMode ? () => Navigator.pop(context, d) : () => _openForm(d),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.home_outlined,
                color: AppColors.brand500,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(d.tieuDe,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                        if (d.laMacDinh) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.brandLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Mặc định',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.brand700,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(d.diaChiChiTiet,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
                    if (d.khuVuc != null)
                      Text(d.khuVuc!,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  switch (v) {
                    case 'edit':
                      _openForm(d);
                    case 'default':
                      _setDefault(d);
                    case 'map':
                      LocationService.openDirections(address: d.diaChiChiTiet);
                    case 'delete':
                      _delete(d);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Sửa')),
                  if (!d.laMacDinh)
                    const PopupMenuItem(
                        value: 'default', child: Text('Đặt làm mặc định')),
                  const PopupMenuItem(value: 'map', child: Text('Xem trên bản đồ')),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Xoá', style: TextStyle(color: AppColors.error)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            TextButton(onPressed: _load, child: const Text('Thử lại')),
          ],
        ),
      );
    } else if (_items.isEmpty) {
      body = const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Bạn chưa lưu địa chỉ nào.\nThêm địa chỉ để đặt dịch vụ nhanh hơn.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    } else {
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.only(top: 16, bottom: 160),
          children: _items.map(_buildItem).toList(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
          title: Text(widget.selectMode ? 'Chọn địa chỉ' : 'Sổ địa chỉ')),
      body: body,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'gps',
            onPressed: () => _openForm(null, true),
            backgroundColor: Colors.white,
            foregroundColor: AppColors.brand600,
            icon: const Icon(Icons.my_location),
            label: const Text('Thêm từ vị trí hiện tại'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'add',
            onPressed: () => _openForm(),
            backgroundColor: AppColors.brand500,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_location_alt_outlined),
            label: const Text('Thêm địa chỉ'),
          ),
        ],
      ),
    );
  }
}
