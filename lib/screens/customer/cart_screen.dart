import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../services/cart_service.dart';
import '../../services/catalog_ui.dart';
import '../../services/service_catalog_api_service.dart';
import '../../services/session_service.dart';
import 'booking_screen.dart';
import '../auth/login_screen.dart';

/// Màn hình Giỏ hàng lưu tạm (không lưu DB).
/// Cho phép chọn nhiều dịch vụ cùng lúc kiểu Shopee/TikTok.
/// KHÔNG CÓ nút tăng/giảm số lượng (- 0 +) theo yêu cầu.
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<CartItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() => _loading = true);
    final items = await CartService.getCart();
    if (mounted) {
      setState(() {
        _items = items;
        _loading = false;
      });
    }
  }

  int get _tongTienChon {
    return _items
        .where((i) => i.isSelected)
        .fold<int>(0, (sum, i) => sum + i.donGia);
  }

  int get _soMonChon {
    return _items.where((i) => i.isSelected).length;
  }

  bool get _tatCaDuocChon {
    return _items.isNotEmpty && _items.every((i) => i.isSelected);
  }

  Future<void> _toggleSelect(CartItem item) async {
    await CartService.toggleSelect(item.dichVuId);
    await _loadCart();
  }

  Future<void> _toggleSelectAll() async {
    final newState = !_tatCaDuocChon;
    await CartService.selectAll(newState);
    await _loadCart();
  }

  Future<void> _removeItem(CartItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text('Xóa "${item.tenDichVu}" khỏi giỏ hàng?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await CartService.removeItem(item.dichVuId);
      await _loadCart();
    }
  }

  /// Mở bảng chọn thêm dịch vụ vào giỏ hàng
  Future<void> _showAddServiceSheet() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return FutureBuilder(
              future: ServiceCatalogApiService().getServices(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.brand500));
                }
                final res = snapshot.data!;
                final services = (res.data ?? []).cast<Map<String, dynamic>>();

                return Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        'Chọn dịch vụ thêm vào giỏ',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        itemCount: services.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, idx) {
                          final s = services[idx];
                          final id = CatalogUi.toInt(s['id'] ?? s['dichVuId']);
                          final name = s['tenDichVu'] ?? s['title'] ?? 'Dịch vụ';
                          final price = CatalogUi.toInt(s['donGiaThamKhao'] ?? s['donGia']);
                          final inCart = _items.any((i) => i.dichVuId == id);

                          return ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: AppColors.brandLight,
                              child: Icon(Icons.cleaning_services_rounded, color: AppColors.brand500, size: 20),
                            ),
                            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: Text(CatalogUi.money(price), style: const TextStyle(color: AppColors.brand600, fontWeight: FontWeight.w700)),
                            trailing: inCart
                                ? const Chip(
                                    label: Text('Đã có', style: TextStyle(fontSize: 12, color: Colors.green)),
                                    backgroundColor: Color(0xFFE8F5E9),
                                  )
                                : ElevatedButton(
                                    onPressed: () async {
                                      Navigator.pop(ctx);
                                      await CartService.addItem(CartItem(
                                        dichVuId: id,
                                        tenDichVu: name,
                                        donGia: price,
                                        thoiGianPhut: CatalogUi.toInt(s['thoiGianThucHienPhut'] ?? 60),
                                        loaiHinhDat: s['loaiHinhDat']?.toString() ?? 'TheoLan',
                                      ));
                                      await _loadCart();
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Đã thêm "$name" vào giỏ hàng!')),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text('Thêm', style: TextStyle(fontSize: 12)),
                                  ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _proceedBooking() async {
    final selected = _items.where((i) => i.isSelected).toList();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất 1 dịch vụ để đặt')),
      );
      return;
    }

    final session = await SessionService.load();
    if (!mounted) return;
    if (session == null || !session.isCustomer) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Cần đăng nhập',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Vui lòng đăng nhập tài khoản Khách hàng để tiến hành đặt lịch.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                  },
                  child: const Text('Đăng nhập ngay'),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    // Chuyển sang BookingScreen chuẩn 3 bước của nhóm trưởng
    final mainItem = selected.first;
    final serviceMap = {
      'dichVuId': mainItem.dichVuId,
      'id': mainItem.dichVuId,
      'tenDichVu': mainItem.tenDichVu,
      'donGiaThamKhao': mainItem.donGia,
      'thoiGianThucHienPhut': mainItem.thoiGianPhut,
      'loaiHinhDat': mainItem.loaiHinhDat ?? 'TheoLan',
      'hinhAnh': mainItem.hinhAnh,
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingScreen(service: serviceMap),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Giỏ hàng dịch vụ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        centerTitle: true,
        actions: [
          if (_items.isNotEmpty)
            TextButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Xác nhận'),
                    content: const Text('Bạn có chắc muốn xóa tất cả dịch vụ trong giỏ?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Xóa hết', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await CartService.clearCart();
                  await _loadCart();
                }
              },
              child: const Text('Xóa hết', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.brand500))
          : _items.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    // Thanh thông báo & nút thêm dịch vụ
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      color: AppColors.brandSurface,
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 18, color: AppColors.brand500),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Đang có ${_items.length} dịch vụ trong giỏ',
                              style: const TextStyle(fontSize: 13, color: AppColors.brand700, fontWeight: FontWeight.w600),
                            ),
                          ),
                          InkWell(
                            onTap: _showAddServiceSheet,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.brand500,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add, size: 14, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text('Thêm dịch vụ', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, idx) {
                          final item = _items[idx];
                          return _buildCartItemCard(item);
                        },
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: _items.isEmpty ? null : _buildBottomBar(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF3E0),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shopping_cart_outlined, size: 48, color: AppColors.brand500),
            ),
            const SizedBox(height: 18),
            const Text(
              'Giỏ hàng của bạn đang trống',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Chọn các dịch vụ bạn cần và thêm vào giỏ để đặt cùng lúc thật tiện lợi.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddServiceSheet,
              icon: const Icon(Icons.add_shopping_cart, size: 18),
              label: const Text('Chọn dịch vụ ngay'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItemCard(CartItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.isSelected ? AppColors.brand500 : AppColors.divider,
          width: item.isSelected ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Row(
        children: [
          // Checkbox chọn món (Shopee style)
          Checkbox(
            value: item.isSelected,
            onChanged: (_) => _toggleSelect(item),
            activeColor: AppColors.brand500,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),

          // Icon dịch vụ
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.brandLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.cleaning_services_rounded, color: AppColors.brand500, size: 24),
          ),
          const SizedBox(width: 12),

          // Tên + Đơn giá
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.tenDichVu,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      CatalogUi.money(item.donGia),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.brand600),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.neutral100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${item.thoiGianPhut} phút',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Nút xóa (KHÔNG CÓ nút - 0 + theo yêu cầu của bạn)
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 22, color: Colors.redAccent),
            tooltip: 'Xóa dịch vụ',
            onPressed: () => _removeItem(item),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(14, 10, 14, 10 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -1)),
        ],
      ),
      child: Row(
        children: [
          Row(
            children: [
              Checkbox(
                value: _tatCaDuocChon,
                onChanged: (_) => _toggleSelectAll(),
                activeColor: AppColors.brand500,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              const Text('Tất cả', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const Spacer(),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Tổng ($_soMonChon món):',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              Text(
                CatalogUi.money(_tongTienChon),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.brand600),
              ),
            ],
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _soMonChon > 0 ? _proceedBooking : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Đặt dịch vụ ($_soMonChon)'),
          ),
        ],
      ),
    );
  }
}
