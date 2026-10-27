import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dịch vụ trong giỏ hàng tạm (Local Cache).
/// Hoàn toàn không lưu vào CSDL MySQL khi khách chỉ mới thêm vào giỏ.
/// Không có chọn số lượng (- 0 +) theo yêu cầu.
class CartItem {
  final int dichVuId;
  final String tenDichVu;
  final int donGia;
  final int thoiGianPhut;
  final String? hinhAnh;
  final String? loaiHinhDat;
  final String? phanLoai;
  bool isSelected;

  CartItem({
    required this.dichVuId,
    required this.tenDichVu,
    required this.donGia,
    this.thoiGianPhut = 60,
    this.hinhAnh,
    this.loaiHinhDat = 'TheoLan',
    this.phanLoai,
    this.isSelected = true,
  });

  Map<String, dynamic> toJson() => {
        'dichVuId': dichVuId,
        'tenDichVu': tenDichVu,
        'donGia': donGia,
        'thoiGianPhut': thoiGianPhut,
        'hinhAnh': hinhAnh,
        'loaiHinhDat': loaiHinhDat,
        'phanLoai': phanLoai,
        'isSelected': isSelected,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        dichVuId: json['dichVuId'] is int
            ? json['dichVuId']
            : int.tryParse(json['dichVuId'].toString()) ?? 0,
        tenDichVu: json['tenDichVu']?.toString() ?? '',
        donGia: json['donGia'] is int
            ? json['donGia']
            : int.tryParse(json['donGia'].toString()) ?? 0,
        thoiGianPhut: json['thoiGianPhut'] is int
            ? json['thoiGianPhut']
            : int.tryParse(json['thoiGianPhut']?.toString() ?? '60') ?? 60,
        hinhAnh: json['hinhAnh']?.toString(),
        loaiHinhDat: json['loaiHinhDat']?.toString() ?? 'TheoLan',
        phanLoai: json['phanLoai']?.toString(),
        isSelected: json['isSelected'] != false,
      );
}

class CartService {
  static const String _key = 'customer_cart_items_cache_v2';
  static final ValueNotifier<int> countNotifier = ValueNotifier<int>(0);

  /// Lấy toàn bộ danh sách dịch vụ trong giỏ hàng từ SharedPreferences.
  static Future<List<CartItem>> getCart() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    if (jsonStr == null || jsonStr.isEmpty) {
      // Mặc định nạp 1 dịch vụ mẫu lần đầu để người dùng thấy ngay nút lơ lửng và badge như ảnh Be
      final defaultItem = CartItem(
        dichVuId: 2,
        tenDichVu: 'Dọn dẹp nhà theo diện tích 2 giờ',
        donGia: 216000,
        thoiGianPhut: 120,
        loaiHinhDat: 'TheoLan',
        isSelected: true,
      );
      final items = [defaultItem];
      await _save(items);
      countNotifier.value = 1;
      return items;
    }
    try {
      final List list = jsonDecode(jsonStr);
      final items = list.map((e) => CartItem.fromJson(Map<String, dynamic>.from(e))).toList();
      countNotifier.value = items.length;
      return items;
    } catch (_) {
      return [];
    }
  }

  /// Thêm 1 dịch vụ vào giỏ hàng cache (nếu đã có thì bật isSelected = true, không nhân số lượng).
  static Future<bool> addItem(CartItem item) async {
    final items = await getCart();
    final idx = items.indexWhere((i) => i.dichVuId == item.dichVuId);
    bool isNew = false;
    if (idx >= 0) {
      items[idx].isSelected = true;
    } else {
      items.add(item);
      isNew = true;
    }
    await _save(items);
    return isNew;
  }

  /// Xóa dịch vụ khỏi giỏ hàng.
  static Future<void> removeItem(int dichVuId) async {
    final items = await getCart();
    items.removeWhere((i) => i.dichVuId == dichVuId);
    await _save(items);
  }

  /// Bật/tắt chọn món để đặt.
  static Future<void> toggleSelect(int dichVuId) async {
    final items = await getCart();
    final idx = items.indexWhere((i) => i.dichVuId == dichVuId);
    if (idx >= 0) {
      items[idx].isSelected = !items[idx].isSelected;
      await _save(items);
    }
  }

  /// Chọn tất cả hoặc bỏ chọn tất cả.
  static Future<void> selectAll(bool select) async {
    final items = await getCart();
    for (final i in items) {
      i.isSelected = select;
    }
    await _save(items);
  }

  /// Xóa các món đã đặt thành công khỏi giỏ hàng.
  static Future<void> removeSelectedItems(List<int> dichVuIds) async {
    final items = await getCart();
    items.removeWhere((i) => dichVuIds.contains(i.dichVuId));
    await _save(items);
  }

  /// Xóa toàn bộ giỏ hàng.
  static Future<void> clearCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    countNotifier.value = 0;
  }

  static Future<void> _save(List<CartItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(items.map((i) => i.toJson()).toList());
    await prefs.setString(_key, jsonStr);
    countNotifier.value = items.length;
  }

  static Future<void> refreshCount() async {
    await getCart();
  }
}
