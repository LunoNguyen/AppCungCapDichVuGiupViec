import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CustomerOrder {
  final String id;
  final int dichVuId;
  final String dichVuTitle;
  final String? dichVuSubtitle;
  final String planLabel;
  final int soGio;
  final String ngayLamViec;
  final String gioBatDau;
  final String diaChi;
  final String tenKhachHang;
  final String soDienThoai;
  final String? ghiChu;
  final bool bringTools;
  final bool hasPets;
  final bool preferFemale;
  final bool cooking;
  final bool ironing;
  final String phuongThucThanhToan;
  final String? maKhuyenMai;
  final int basePrice;
  final int extraPrice;
  final int discount;
  final int tongTien;
  final String trangThai; // CHO_XAC_NHAN, DANG_TIM_NGUOI, DA_NHAN_VIEC, HOAN_THANH, DA_HUY
  final String createdAt;

  CustomerOrder({
    required this.id,
    required this.dichVuId,
    required this.dichVuTitle,
    this.dichVuSubtitle,
    required this.planLabel,
    required this.soGio,
    required this.ngayLamViec,
    required this.gioBatDau,
    required this.diaChi,
    required this.tenKhachHang,
    required this.soDienThoai,
    this.ghiChu,
    this.bringTools = false,
    this.hasPets = false,
    this.preferFemale = false,
    this.cooking = false,
    this.ironing = false,
    required this.phuongThucThanhToan,
    this.maKhuyenMai,
    required this.basePrice,
    required this.extraPrice,
    required this.discount,
    required this.tongTien,
    required this.trangThai,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'dichVuId': dichVuId,
        'dichVuTitle': dichVuTitle,
        'dichVuSubtitle': dichVuSubtitle,
        'planLabel': planLabel,
        'soGio': soGio,
        'ngayLamViec': ngayLamViec,
        'gioBatDau': gioBatDau,
        'diaChi': diaChi,
        'tenKhachHang': tenKhachHang,
        'soDienThoai': soDienThoai,
        'ghiChu': ghiChu,
        'bringTools': bringTools,
        'hasPets': hasPets,
        'preferFemale': preferFemale,
        'cooking': cooking,
        'ironing': ironing,
        'phuongThucThanhToan': phuongThucThanhToan,
        'maKhuyenMai': maKhuyenMai,
        'basePrice': basePrice,
        'extraPrice': extraPrice,
        'discount': discount,
        'tongTien': tongTien,
        'trangThai': trangThai,
        'createdAt': createdAt,
      };

  factory CustomerOrder.fromJson(Map<String, dynamic> json) => CustomerOrder(
        id: json['id']?.toString() ?? '',
        dichVuId: json['dichVuId'] is int ? json['dichVuId'] : int.tryParse('${json['dichVuId']}') ?? 1,
        dichVuTitle: json['dichVuTitle']?.toString() ?? 'Dịch vụ giúp việc',
        dichVuSubtitle: json['dichVuSubtitle']?.toString(),
        planLabel: json['planLabel']?.toString() ?? 'Theo giờ',
        soGio: json['soGio'] is int ? json['soGio'] : int.tryParse('${json['soGio']}') ?? 2,
        ngayLamViec: json['ngayLamViec']?.toString() ?? '',
        gioBatDau: json['gioBatDau']?.toString() ?? '',
        diaChi: json['diaChi']?.toString() ?? '',
        tenKhachHang: json['tenKhachHang']?.toString() ?? '',
        soDienThoai: json['soDienThoai']?.toString() ?? '',
        ghiChu: json['ghiChu']?.toString(),
        bringTools: json['bringTools'] == true,
        hasPets: json['hasPets'] == true,
        preferFemale: json['preferFemale'] == true,
        cooking: json['cooking'] == true,
        ironing: json['ironing'] == true,
        phuongThucThanhToan: json['phuongThucThanhToan']?.toString() ?? 'TIEN_MAT',
        maKhuyenMai: json['maKhuyenMai']?.toString(),
        basePrice: json['basePrice'] is int ? json['basePrice'] : int.tryParse('${json['basePrice']}') ?? 0,
        extraPrice: json['extraPrice'] is int ? json['extraPrice'] : int.tryParse('${json['extraPrice']}') ?? 0,
        discount: json['discount'] is int ? json['discount'] : int.tryParse('${json['discount']}') ?? 0,
        tongTien: json['tongTien'] is int ? json['tongTien'] : int.tryParse('${json['tongTien']}') ?? 0,
        trangThai: json['trangThai']?.toString() ?? 'DANG_TIM_NGUOI',
        createdAt: json['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
      );
}

class OrderStorageService {
  static const _kOrdersKey = 'customer_local_orders';

  static Future<List<CustomerOrder>> getOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kOrdersKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List list = jsonDecode(raw);
      return list.map((e) => CustomerOrder.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveOrder(CustomerOrder order) async {
    final prefs = await SharedPreferences.getInstance();
    final orders = await getOrders();
    // Chèn đơn mới lên đầu danh sách
    orders.insert(0, order);
    final raw = jsonEncode(orders.map((o) => o.toJson()).toList());
    await prefs.setString(_kOrdersKey, raw);
  }

  static Future<void> updateOrderStatus(String orderId, String newStatus) async {
    final prefs = await SharedPreferences.getInstance();
    final orders = await getOrders();
    final idx = orders.indexWhere((o) => o.id == orderId);
    if (idx != -1) {
      final old = orders[idx];
      orders[idx] = CustomerOrder(
        id: old.id,
        dichVuId: old.dichVuId,
        dichVuTitle: old.dichVuTitle,
        dichVuSubtitle: old.dichVuSubtitle,
        planLabel: old.planLabel,
        soGio: old.soGio,
        ngayLamViec: old.ngayLamViec,
        gioBatDau: old.gioBatDau,
        diaChi: old.diaChi,
        tenKhachHang: old.tenKhachHang,
        soDienThoai: old.soDienThoai,
        ghiChu: old.ghiChu,
        bringTools: old.bringTools,
        hasPets: old.hasPets,
        preferFemale: old.preferFemale,
        cooking: old.cooking,
        ironing: old.ironing,
        phuongThucThanhToan: old.phuongThucThanhToan,
        maKhuyenMai: old.maKhuyenMai,
        basePrice: old.basePrice,
        extraPrice: old.extraPrice,
        discount: old.discount,
        tongTien: old.tongTien,
        trangThai: newStatus,
        createdAt: old.createdAt,
      );
      final raw = jsonEncode(orders.map((o) => o.toJson()).toList());
      await prefs.setString(_kOrdersKey, raw);
    }
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kOrdersKey);
  }
}
