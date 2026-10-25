import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../services/ctv_location_tracker.dart';
import '../../services/location_service.dart';

/// Màn hình chi tiết: Khu vực & Vị trí nhận việc theo GPS của Cộng tác viên.
class CollaboratorLocationScreen extends StatefulWidget {
  const CollaboratorLocationScreen({super.key});

  @override
  State<CollaboratorLocationScreen> createState() => _CollaboratorLocationScreenState();
}

class _CollaboratorLocationScreenState extends State<CollaboratorLocationScreen> {
  bool _isRefreshing = false;
  String? _addressText;

  @override
  void initState() {
    super.initState();
    _addressText = CtvLocationTracker.instance.currentAddress;
    CtvLocationTracker.instance.addListener(_onTrackerUpdated);
    _loadCurrentAddress();
  }

  @override
  void dispose() {
    CtvLocationTracker.instance.removeListener(_onTrackerUpdated);
    super.dispose();
  }

  void _onTrackerUpdated() {
    if (mounted) {
      final addr = CtvLocationTracker.instance.currentAddress;
      setState(() {
        if (addr != null && addr.isNotEmpty) {
          _addressText = addr;
        }
      });
    }
  }

  Future<void> _loadCurrentAddress() async {
    try {
      final cachedPos = CtvLocationTracker.instance.latestPosition;
      final pos = cachedPos != null
          ? cachedPos
          : (await LocationService.getCurrentPosition()).position;
      if (pos != null) {
        final details = await LocationService.getAddressDetails(
          pos.latitude,
          pos.longitude,
        );
        if (mounted) {
          setState(() {
            _addressText = details['diaChi'];
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _refreshLocation() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);

    try {
      await CtvLocationTracker.instance.forceSend();
      await _loadCurrentAddress();

      if (!mounted) return;
      final district = CtvLocationTracker.instance.currentDistrict ?? 'Khu vực hiện tại';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã cập nhật vị trí mới nhất: $district'),
          backgroundColor: AppColors.green500,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi định vị: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Future<void> _openGoogleMaps() async {
    final district = CtvLocationTracker.instance.currentDistrict;
    final address = (_addressText != null && _addressText!.isNotEmpty)
        ? _addressText!
        : (district != null && district.isNotEmpty ? '$district, TP. Hồ Chí Minh' : 'Thành phố Hồ Chí Minh');

    final pos = CtvLocationTracker.instance.latestPosition;
    bool opened = false;
    if (pos != null) {
      opened = await LocationService.openMap(pos.latitude, pos.longitude);
    }
    if (!opened) {
      opened = await LocationService.openDirections(address: address);
    }

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể mở ứng dụng bản đồ trên thiết bị này.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final district = CtvLocationTracker.instance.currentDistrict;
    final hasDistrict = district != null && district.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          'Khu vực & Vị trí nhận việc',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.partner800,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thẻ trạng thái vị trí chính
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.partnerLight,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.partner400.withValues(alpha: 0.3), width: 2),
                    ),
                    child: const Icon(
                      Icons.my_location_rounded,
                      size: 36,
                      color: AppColors.partner500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Khu vực nhận việc hiện tại',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    hasDistrict ? district : 'Đang lấy vị trí GPS...',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: hasDistrict ? AppColors.partner800 : const Color(0xFFD97706),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Thành phố Hồ Chí Minh',
                    style: TextStyle(fontSize: 13.5, color: Color(0xFF4B5563)),
                  ),
                  if (_addressText != null && _addressText!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.place_outlined, size: 16, color: AppColors.partner500),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              _addressText!,
                              style: const TextStyle(fontSize: 12.5, color: Color(0xFF374151)),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  // Trạng thái định vị
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: hasDistrict ? AppColors.greenLight : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: hasDistrict ? AppColors.green500 : const Color(0xFFD97706),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          hasDistrict ? 'Định vị GPS hoạt động tốt · Tự động đồng bộ' : 'Đang dò sóng định vị...',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: hasDistrict ? AppColors.green600 : const Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Thẻ hướng dẫn & quy chế
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.info_outline_rounded, color: AppColors.partner500, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Cơ chế phân phối đơn việc',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.partner800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildBulletItem('Hệ thống tự động ưu tiên phân phối các đơn việc mới trong bán kính quanh vị trí thực tế của bạn.'),
                  _buildBulletItem('Khi bạn di chuyển sang quận khác, app sẽ tự động nhận diện và cập nhật khu vực làm việc theo vị trí mới.'),
                  _buildBulletItem('Bạn không cần phải chọn quận thủ công. Mọi thao tác đều được tự động hóa qua GPS điện thoại.'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Nút bấm hành động 1: Quét lại vị trí ngay
            ElevatedButton.icon(
              onPressed: _isRefreshing ? null : _refreshLocation,
              icon: _isRefreshing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded, color: Colors.white),
              label: Text(
                _isRefreshing ? 'Đang quét định vị GPS...' : 'Làm mới vị trí GPS ngay',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.partner500,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 1,
              ),
            ),

            const SizedBox(height: 12),

            // Nút bấm hành động 2: Xem trên Google Maps
            OutlinedButton.icon(
              onPressed: _openGoogleMaps,
              icon: const Icon(Icons.map_outlined, color: AppColors.partner500, size: 20),
              label: const Text(
                'Xem vị trí trên Google Maps',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.partner500),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.partner400, width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                backgroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppColors.partner500, fontWeight: FontWeight.bold, fontSize: 14)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
