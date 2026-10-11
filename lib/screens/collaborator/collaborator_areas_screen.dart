import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../services/collaborator_api_service.dart';
import '../../services/service_catalog_api_service.dart';

/// Khu vực nhận việc của cộng tác viên: chọn 1 đến 5 quận, huyện (cùng danh sách với địa chỉ khách hàng).
/// CSKH ưu tiên xếp đơn trong các quận đã chọn. Trả về `true` khi đã lưu.
class CollaboratorAreasScreen extends StatefulWidget {
  final int congTacVienId;

  const CollaboratorAreasScreen({super.key, required this.congTacVienId});

  @override
  State<CollaboratorAreasScreen> createState() => _CollaboratorAreasScreenState();
}

class _CollaboratorAreasScreenState extends State<CollaboratorAreasScreen> {
  static const _toiDa = 5;

  final _api = CollaboratorApiService();
  List<Map<String, dynamic>> _tatCa = [];
  final Set<int> _chon = {};
  bool _dangTai = true;
  bool _dangLuu = false;
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
    final kq = await Future.wait([
      ServiceCatalogApiService().getAreas(),
      _api.getWorkAreas(widget.congTacVienId),
    ]);
    if (!mounted) return;
    final ds = kq[0];
    final cuaToi = kq[1];
    setState(() {
      _dangTai = false;
      if (!ds.success || ds.data == null) {
        _loi = ds.message ?? 'Không tải được danh sách quận, huyện.';
        return;
      }
      _tatCa = ds.data!;
      _chon
        ..clear()
        ..addAll((cuaToi.data ?? const [])
            .map((k) => int.tryParse('${k['id']}'))
            .whereType<int>());
    });
  }

  void _doiChon(int id, bool chon) {
    if (chon && _chon.length >= _toiDa) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Chọn tối đa $_toiDa quận, huyện để kịp di chuyển giữa các đơn.'),
      ));
      return;
    }
    setState(() => chon ? _chon.add(id) : _chon.remove(id));
  }

  Future<void> _luu() async {
    if (_chon.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Chọn ít nhất 1 quận, huyện nhận việc.'),
        backgroundColor: AppColors.error,
      ));
      return;
    }
    setState(() => _dangLuu = true);
    final res = await _api.updateWorkAreas(widget.congTacVienId, _chon.toList());
    if (!mounted) return;
    setState(() => _dangLuu = false);
    if (!res.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res.message ?? 'Không lưu được khu vực nhận việc.'),
        backgroundColor: AppColors.error,
      ));
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Khu vực nhận việc')),
      body: _dangTai
          ? const Center(child: CircularProgressIndicator())
          : _loi != null
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(_loi!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    OutlinedButton(onPressed: _tai, child: const Text('Thử lại')),
                  ]),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Text(
                        'Chọn 1 đến $_toiDa quận, huyện bạn muốn nhận việc (đã chọn ${_chon.length}). '
                        'bTaskee ưu tiên giao đơn trong các quận này.',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _tatCa.length,
                        itemBuilder: (_, i) {
                          final id = int.tryParse('${_tatCa[i]['id']}');
                          if (id == null) return const SizedBox.shrink();
                          return CheckboxListTile(
                            value: _chon.contains(id),
                            activeColor: AppColors.brand500,
                            title: Text(_tatCa[i]['tenKhuVuc']?.toString() ?? ''),
                            onChanged: _dangLuu ? null : (v) => _doiChon(id, v ?? false),
                          );
                        },
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _dangLuu ? null : _luu,
                            child: _dangLuu
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                : const Text('Lưu khu vực'),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
