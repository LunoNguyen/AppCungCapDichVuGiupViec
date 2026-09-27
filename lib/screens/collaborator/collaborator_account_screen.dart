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
  
  // Định dạng tiền tệ VNĐ
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
        backgroundColor: AppColors.scaffoldBg,
        body: Center(child: CircularProgressIndicator(color: AppColors.brand500)),
      );
    }

    if (_profile == null) {
      return Scaffold(
        backgroundColor: AppColors.scaffoldBg,
        appBar: AppBar(title: const Text('Hồ sơ & Thu nhập')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Không thể tải thông tin tài khoản'),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _fetchProfileData, child: const Text('Thử lại')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Hồ sơ & Thu nhập'),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchProfileData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildProfileHeader(),
              const SizedBox(height: 12),
              _buildAvailabilityToggle(),
              const SizedBox(height: 12),
              _buildEarningsCard(),
              const SizedBox(height: 12),
              _buildPerformanceStats(),
              const SizedBox(height: 16),
              _buildMenuSection('Tài chính & Ví', [
                _CollaboratorMenuItem(
                  Icons.account_balance_wallet_outlined,
                  'Ví thu nhập',
                  AppColors.brand500,
                  _currencyFormat.format(_profile?.soDuVi ?? 0),
                  () {},
                ),
                _CollaboratorMenuItem(
                  Icons.credit_card_outlined,
                  'Tài khoản ngân hàng',
                  const Color(0xFF9C27B0),
                  'Chưa liên kết',
                  () {},
                ),
              ]),
              const SizedBox(height: 16),
              _buildLogoutButton(context),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.brand700, AppColors.brand500]),
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: Colors.white,
            child: Text(
              _profile!.hoTen.isNotEmpty ? _profile!.hoTen[0].toUpperCase() : 'C',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.brand600),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_profile!.hoTen, style: const TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Mã CTV: ${_profile!.maCongTacVien}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: AppColors.star, size: 14),
                    const SizedBox(width: 4),
                    Text(_profile!.diemDanhGia.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityToggle() {
    bool isAvailable = _profile!.trangThai == TrangThaiCTV.HoatDong;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Expanded(child: Text(isAvailable ? 'Sẵn sàng nhận việc' : 'Tạm dừng nhận việc', style: const TextStyle(fontWeight: FontWeight.bold))),
          Switch(
            value: isAvailable,
            activeColor: AppColors.success,
            onChanged: (val) async {
              String newStatus = val ? 'HoatDong' : 'TamDung';
              final res = await _apiService.updateStatus(_currentUserId, newStatus);
              if (res.success) {
                _fetchProfileData();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0F3B46), Color(0xFF1B5E6E)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Số dư ví thu nhập', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          Text(_currencyFormat.format(_profile?.soDuVi ?? 0), style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: ElevatedButton(onPressed: () {}, child: const Text('Rút tiền'))),
              const SizedBox(width: 10),
              OutlinedButton(onPressed: () {}, style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white38)), child: const Text('Sao kê')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          _buildStatItem('0', 'Hoàn thành', Icons.check_circle_outline, AppColors.success),
          _buildStatItem('0%', 'Tỷ lệ nhận', Icons.trending_up, AppColors.brand500),
          _buildStatItem(_profile!.diemDanhGia.toStringAsFixed(1), 'Đánh giá', Icons.star_outline, AppColors.star),
        ],
      ),
    );
  }

  Widget _buildStatItem(String val, String label, IconData icon, Color color) {
    return Expanded(child: Column(children: [Icon(icon, color: color, size: 20), Text(val, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)), Text(label, style: const TextStyle(fontSize: 10))]));
  }

  Widget _buildMenuSection(String title, List<_CollaboratorMenuItem> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 4), child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary))),
          ...items.map((item) => ListTile(
            leading: Icon(item.icon, color: item.color, size: 20),
            title: Text(item.title, style: const TextStyle(fontSize: 14)),
            trailing: Text(item.subtext, style: const TextStyle(fontSize: 12)),
            onTap: item.onTap,
          )),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16), width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.clear();
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen(initialRoleTab: 1)), (route) => false);
        },
        icon: const Icon(Icons.logout, color: AppColors.error),
        label: const Text('Đăng xuất tài khoản CTV', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
      ),
    );
  }
}

class _CollaboratorMenuItem {
  final IconData icon; final String title; final Color color; final String subtext; final VoidCallback onTap;
  _CollaboratorMenuItem(this.icon, this.title, this.color, this.subtext, this.onTap);
}
