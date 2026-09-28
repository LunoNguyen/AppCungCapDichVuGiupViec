import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_colors.dart';
import '../../models/cong_tac_vien.dart';
import '../../services/collaborator_api_service.dart';
import '../auth/login_screen.dart';

class CollaboratorAccountScreen extends StatefulWidget {
  const CollaboratorAccountScreen({super.key});

  @override
  State<CollaboratorAccountScreen> createState() =>
      _CollaboratorAccountScreenState();
}

class _CollaboratorAccountScreenState extends State<CollaboratorAccountScreen> {
  bool _isLoading = true;
  int _currentUserId = 0;
  CongTacVien? _profile;
  final CollaboratorApiService _apiService = CollaboratorApiService();
  
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getInt('userId') ?? 0;
    
    if (_currentUserId == 0) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    await _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.getProfile(_currentUserId);
      if (response.success && response.data != null) {
        setState(() {
          _profile = response.data;
        });
      }
    } catch (e) {
      debugPrint('Lỗi tải hồ sơ: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: AppColors.brand500)),
      );
    }

    if (_profile == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Không thể tải thông tin tài khoản'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchProfileData,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand500),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      // Sửa nhanh: Sử dụng AppBar chuẩn để tiêu đề không bao giờ che nội dung bên dưới
      appBar: AppBar(
        backgroundColor: AppColors.brand500,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text('Tài khoản', 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.brand700, AppColors.brand500],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchProfileData,
        color: AppColors.brand500,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildProfileCard(),
              const SizedBox(height: 16),
              _buildPerformanceStats(),
              const SizedBox(height: 16),
              _buildAvailabilitySection(),
              const SizedBox(height: 16),
              
              _buildMenuSection('CÔNG VIỆC & DỊCH VỤ', [
                _CollaboratorMenuItem(Icons.handyman_outlined, 'Dịch vụ đã đăng ký', '5 dịch vụ', () {}),
                _CollaboratorMenuItem(Icons.map_outlined, 'Khu vực nhận việc', _profile!.noiCuTru, () {}),
              ]),
              
              const SizedBox(height: 16),
              _buildMenuSection('TÀI CHÍNH', [
                _CollaboratorMenuItem(Icons.account_balance_wallet_outlined, 'Ví thu nhập', _currencyFormat.format(_profile?.soDuVi ?? 0), () {}),
                _CollaboratorMenuItem(Icons.credit_card_outlined, 'Tài khoản ngân hàng', 'Vietcombank', () {}),
              ]),

              const SizedBox(height: 16),
              _buildMenuSection('TÀI KHOẢN', [
                _CollaboratorMenuItem(Icons.badge_outlined, 'Thông tin cá nhân & CCCD', 'Đã xác thực', () {}),
                _CollaboratorMenuItem(Icons.star_outline, 'Đánh giá từ khách hàng', '${_profile!.diemDanhGia.toStringAsFixed(1)} ★', () {}),
              ]),

              const SizedBox(height: 24),
              _buildLogoutButton(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: const Color(0xFFF0F2F5),
            child: Text(
              _profile!.hoTen.isNotEmpty ? _profile!.hoTen[0].toUpperCase() : 'C',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.brand600),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _profile!.hoTen,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Mã CTV: ${_profile!.maCongTacVien}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildPerformanceStats() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _statItem('0', 'Hoàn thành', Icons.done_all_rounded, Colors.green),
          _statItem(_profile!.diemDanhGia.toStringAsFixed(1), 'Đánh giá', Icons.star_rounded, Colors.orange),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildAvailabilitySection() {
    bool isAvailable = _profile!.trangThai == TrangThaiCTV.HoatDong;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            isAvailable ? Icons.notifications_active : Icons.notifications_off,
            color: isAvailable ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isAvailable ? 'Đang bật nhận việc' : 'Đang tắt nhận việc',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Switch(
            value: isAvailable,
            activeColor: Colors.green,
            onChanged: (val) async {
              String status = val ? 'HoatDong' : 'TamDung';
              final res = await _apiService.updateStatus(_currentUserId, status);
              if (res.success) {
                _fetchProfileData();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(String title, List<_CollaboratorMenuItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 8),
          child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: items.map((item) => ListTile(
              leading: Icon(item.icon, size: 22),
              title: Text(item.title, style: const TextStyle(fontSize: 14)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.subtext.isNotEmpty)
                    Text(item.subtext, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                ],
              ),
              onTap: item.onTap,
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen(initialRoleTab: 1)),
              (route) => false,
            );
          }
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.error),
          ),
        ),
        child: const Text(
          'Đăng xuất',
          style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _CollaboratorMenuItem {
  final IconData icon;
  final String title;
  final String subtext;
  final VoidCallback onTap;

  _CollaboratorMenuItem(this.icon, this.title, this.subtext, this.onTap);
}
