import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_colors.dart';
import '../../services/collaborator_api_service.dart';

class CollaboratorOrdersScreen extends StatefulWidget {
  const CollaboratorOrdersScreen({super.key});

  @override
  State<CollaboratorOrdersScreen> createState() =>
      _CollaboratorOrdersScreenState();
}

class _CollaboratorOrdersScreenState extends State<CollaboratorOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CollaboratorApiService _apiService = CollaboratorApiService();
  
  bool _isLoading = true;
  int _currentUserId = 0;
  List<Map<String, dynamic>> _allAssignments = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserAndFetchData();
    
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {}); 
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserAndFetchData() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getInt('userId') ?? 0;
    if (_currentUserId == 0) {
      setState(() => _isLoading = false);
      return;
    }
    await _fetchAssignments();
  }

  Future<void> _fetchAssignments() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.getAssignments(congTacVienId: _currentUserId);
      if (response.success && response.data != null) {
        setState(() {
          _allAssignments = List<Map<String, dynamic>>.from(response.data!);
        });
      } else {
        _showError(response.message ?? 'Không thể tải danh sách đơn');
      }
    } catch (e) {
      _showError('Lỗi kết nối: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  List<Map<String, dynamic>> _getFilteredList(String tabType) {
    if (tabType == 'new') {
      return _allAssignments.where((item) {
        final status = (item['trangThaiPhanCong']?.toString() ?? '').toLowerCase();
        return status == 'chophancong' || 
               status == 'cho_xac_nhan' || 
               status == 'new';
      }).toList();
    } else if (tabType == 'confirmed') {
      return _allAssignments.where((item) {
        final status = (item['trangThaiPhanCong']?.toString() ?? '').toLowerCase();
        return status == 'daxacnhan' || 
               status == 'da_xac_nhan' || 
               status == 'danhan' || 
               status == 'dang_thuc_hien' ||
               status == 'confirmed';
      }).toList();
    } else {
      return _allAssignments.where((item) {
        final status = (item['trangThaiPhanCong']?.toString() ?? '').toLowerCase();
        return status == 'hoanthanh' || 
               status == 'hoan_thanh' ||
               status == 'completed';
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Đơn của tôi'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAssignments,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: AppColors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'Mới'),
            Tab(text: 'Đã xác nhận'),
            Tab(text: 'Hoàn thành'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.brand500))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList('new'),
                _buildOrderList('confirmed'),
                _buildOrderList('completed'),
              ],
            ),
    );
  }

  Widget _buildOrderList(String status) {
    final filtered = _getFilteredList(status);

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 60, color: AppColors.brand300),
            const SizedBox(height: 12),
            const Text(
              'Chưa có đơn nào',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 12, bottom: 20),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final o = filtered[index];
        return _buildOrderCard(o, status);
      },
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> o, String currentTab) {
    final String serviceName = o['tenDichVu'] ?? 'Dịch vụ giúp việc';
    final String customerName = o['khachHangTen'] ?? 'Khách hàng';
    final String address = o['diaChi'] ?? 'Chưa cập nhật địa chỉ';
    final String price = o['thanhTien'] != null ? '${o['thanhTien']}đ' : '0đ';
    final String dateStr = o['ngayThucHien'] ?? '';
    final String timeStr = '${o['gioBatDau'] ?? ''} - ${o['gioKetThuc'] ?? ''}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: currentTab == 'new'
                  ? AppColors.brand300.withOpacity(0.1)
                  : AppColors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.brand500.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.cleaning_services,
                      color: AppColors.brand500, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        serviceName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'KH: $customerName',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (currentTab == 'new')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.brand500,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Mới',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _infoRow(Icons.calendar_today, dateStr),
                const SizedBox(height: 6),
                _infoRow(Icons.access_time, timeStr),
                const SizedBox(height: 6),
                _infoRow(Icons.location_on_outlined, address),
                const SizedBox(height: 12),
                if (currentTab == 'new') ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _handleAction(o, 'reject'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Từ chối'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _handleAction(o, 'accept'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brand500,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Nhận đơn'),
                        ),
                      ),
                    ],
                  ),
                ] else if (currentTab == 'confirmed') ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _handleAction(o, 'complete'),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Đánh dấu hoàn thành'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ] else ...[
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.success, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Hoàn thành • $price',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Future<void> _handleAction(Map<String, dynamic> o, String action) async {
    final int phanCongId = o['phanCongId'] ?? 0;
    if (phanCongId == 0) {
      _showError('Lỗi: Không tìm thấy ID phân công');
      return;
    }

    setState(() => _isLoading = true);
    try {
      dynamic res;
      if (action == 'accept') {
        res = await _apiService.acceptAssignment(phanCongId);
      } else if (action == 'reject') {
        res = await _apiService.rejectAssignment(id: phanCongId);
      } else if (action == 'complete') {
        res = await _apiService.completeAssignment(id: phanCongId, ghiChu: "Hoàn thành qua ứng dụng");
      }

      if (res != null && res.success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(action == 'accept' ? 'Đã nhận việc thành công!' : 'Thao tác thành công!'),
            backgroundColor: AppColors.success,
          ),
        );
        // Tải lại danh sách để cập nhật trạng thái mới nhất
        await _fetchAssignments();
        
        // Chuyển tab tương ứng
        if (action == 'accept') _tabController.animateTo(1);
        if (action == 'complete') _tabController.animateTo(2);
      } else {
        _showError(res?.message ?? 'Thao tác thất bại');
      }
    } catch (e) {
      _showError('Lỗi hệ thống: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
