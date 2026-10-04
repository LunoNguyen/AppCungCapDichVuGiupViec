import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../services/catalog_ui.dart';
import '../../services/service_catalog_api_service.dart';
import 'service_detail_screen.dart';

/// Danh sách dịch vụ lấy từ API (GET /v1/services), lọc theo loại dịch vụ và từ khoá.
class CustomerServicesScreen extends StatefulWidget {
  final ValueChanged<int>? onSwitchTab;
  final int? loaiDichVuId; // mở sẵn theo một loại (từ lưới dịch vụ ở trang chủ)
  final String? tenLoai;

  const CustomerServicesScreen({
    super.key,
    this.onSwitchTab,
    this.loaiDichVuId,
    this.tenLoai,
  });

  @override
  State<CustomerServicesScreen> createState() => _CustomerServicesScreenState();
}

class _CustomerServicesScreenState extends State<CustomerServicesScreen> {
  final ServiceCatalogApiService _api = ServiceCatalogApiService();
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  List<Map<String, dynamic>> _types = [];
  List<Map<String, dynamic>> _services = [];
  int? _loaiId;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loaiId = widget.loaiDichVuId;
    _loadTypes();
    _loadServices();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTypes() async {
    try {
      final res = await _api.getServiceTypes();
      if (!mounted || !res.success) return;
      setState(() {
        _types = (res.data ?? [])
            .where((t) => t['trangThai'] == null || t['trangThai'] == 'HienThi')
            .map(CatalogUi.fromServiceType)
            .toList();
      });
    } catch (_) {}
  }

  Future<void> _loadServices() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.getServices(
        loaiDichVuId: _loaiId,
        tuKhoa: _searchCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        if (res.success) {
          _services = (res.data ?? []).map(CatalogUi.fromService).toList();
        } else {
          _error = res.message ?? 'Không tải được danh sách dịch vụ';
        }
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Lỗi kết nối máy chủ');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _loadServices);
  }

  void _chonLoai(int? id) {
    if (_loaiId == id) return;
    setState(() => _loaiId = id);
    _loadServices();
  }

  String get _tieuDe {
    if (_loaiId == null) return 'Tất cả dịch vụ';
    final t = _types.where((e) => e['id'] == _loaiId);
    return t.isNotEmpty ? t.first['title'] as String : (widget.tenLoai ?? 'Dịch vụ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: Text(_tieuDe),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _loadServices(),
              decoration: InputDecoration(
                hintText: 'Tìm dịch vụ...',
                prefixIcon: const Icon(Icons.search_rounded),
                isDense: true,
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          _loadServices();
                        },
                      ),
              ),
            ),
          ),
          if (_types.isNotEmpty)
            Container(
              color: Colors.white,
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                children: [
                  _chip('Tất cả', _loaiId == null, () => _chonLoai(null)),
                  for (final t in _types)
                    _chip(t['title'] as String, _loaiId == t['id'],
                        () => _chonLoai(t['id'] as int)),
                ],
              ),
            ),
          const Divider(height: 1),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.brandLight,
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? AppColors.brand700 : AppColors.textPrimary,
        ),
        side: BorderSide(
            color: selected ? AppColors.brand500 : AppColors.divider),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildList() {
    if (_loading && _services.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.brand500));
    }
    if (_error != null && _services.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: AppColors.textSecondary)),
            TextButton(onPressed: _loadServices, child: const Text('Thử lại')),
          ],
        ),
      );
    }
    if (_services.isEmpty) {
      return const Center(
        child: Text('Không có dịch vụ phù hợp',
            style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return RefreshIndicator(
      color: AppColors.brand500,
      onRefresh: _loadServices,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: _services.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 84),
        itemBuilder: (context, i) => _buildServiceRow(context, _services[i]),
      ),
    );
  }

  Widget _buildServiceRow(BuildContext context, Map<String, dynamic> item) {
    final Color c = item['iconColor'] as Color;
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ServiceDetailScreen(service: item),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(item['icon'] as IconData, color: c, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'] as String,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item['subtitle'] as String,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['price'] as String,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brand600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
