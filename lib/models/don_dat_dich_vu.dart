// ignore_for_file: constant_identifier_names

import 'chi_tiet_don_dat.dart';

/// Model tương ứng bảng DonDatDichVu
class DonDatDichVu {
  final int? id;
  final String maDonDat;
  final int khachHangId;
  final int? khuyenMaiId;
  final String? maKhuyenMai;
  final String? khachHangTen;
  final String? khachHangPhone;
  final String? diaChi;
  final DateTime ngayThucHien;
  final String gioBatDau;
  final String? gioKetThuc;
  final num? chiPhiGoc;
  final num? soTienGiam;
  final int thanhTien;
  final String trangThai;
  final List<ChiTietDonDat> chiTietList;

  // Backward compatible getters
  int get dichVuId => chiTietList.isNotEmpty ? chiTietList.first.dichVuId : 0;
  String? get tenDichVu => chiTietList.isNotEmpty ? chiTietList.first.tenDichVu : null;

  const DonDatDichVu({
    this.id,
    required this.maDonDat,
    required this.khachHangId,
    this.khuyenMaiId,
    this.maKhuyenMai,
    this.khachHangTen,
    this.khachHangPhone,
    this.diaChi,
    required this.ngayThucHien,
    required this.gioBatDau,
    this.gioKetThuc,
    this.chiPhiGoc,
    this.soTienGiam,
    required this.thanhTien,
    required this.trangThai,
    this.chiTietList = const [],
  });

  factory DonDatDichVu.fromJson(Map<String, dynamic> json) {
    // Parse chiTietList tu backend Java (chiTietList hoac chiTietDonDats)
    List<ChiTietDonDat> parsedChiTiet = [];
    var listRaw = json['chiTietList'] ?? json['chiTietDonDats'];
    if (listRaw is List) {
      parsedChiTiet = listRaw.map((e) => ChiTietDonDat.fromJson(e)).toList();
    } else if (json['dichVuId'] != null) {
      // Direct fallback for single-service legacy JSON response
      parsedChiTiet = [
        ChiTietDonDat(
          dichVuId: json['dichVuId'] as int? ?? 0,
          tenDichVu: json['tenDichVu'] as String?,
          thanhTien: (json['thanhTien'] as num?) ?? 0,
        )
      ];
    }

    return DonDatDichVu(
      id: json['id'] as int? ?? json['donDatId'] as int?,
      maDonDat: json['maDonDat'] ?? '',
      khachHangId: json['khachHangId'] ?? 0,
      khuyenMaiId: json['khuyenMaiId'] as int? ?? json['couponId'] as int?,
      maKhuyenMai: json['maKhuyenMai'] as String? ?? json['codeKhuyenMai'] as String?,
      khachHangTen: json['khachHangTen'],
      khachHangPhone: json['khachHangPhone'],
      diaChi: json['diaChi'],
      ngayThucHien: json['ngayThucHien'] != null 
          ? DateTime.parse(json['ngayThucHien'].toString()) 
          : DateTime.now(),
      gioBatDau: json['gioBatDau'] ?? '',
      gioKetThuc: json['gioKetThuc'],
      chiPhiGoc: json['chiPhiGoc'] as num? ?? json['soTienGoc'] as num?,
      soTienGiam: json['soTienGiam'] as num?,
      thanhTien: (json['thanhTien'] as num?)?.toInt() ?? 0,
      trangThai: json['trangThai'] ?? json['trangThaiDon'] ?? '',
      chiTietList: parsedChiTiet,
    );
  }
}

/// Model tương ứng bảng PhanCongCTV
class PhanCongCTV {
  final int? phanCongId;
  final String maPhanCong;
  final String trangThaiPhanCong;
  final DonDatDichVu? donDat;

  const PhanCongCTV({
    this.phanCongId,
    required this.maPhanCong,
    required this.trangThaiPhanCong,
    this.donDat,
  });

  factory PhanCongCTV.fromJson(Map<String, dynamic> json) {
    // Ưu tiên lấy phanCongId từ JSON của Java
    final int? idFromBackend = json['phanCongId'] as int? ?? json['id'] as int?;
    
    return PhanCongCTV(
      phanCongId: idFromBackend,
      maPhanCong: json['maPhanCong'] ?? '',
      trangThaiPhanCong: json['trangThaiPhanCong'] ?? json['trangThai'] ?? '',
      donDat: json.containsKey('maDonDat') 
          ? DonDatDichVu.fromJson(json) 
          : (json['donDat'] != null ? DonDatDichVu.fromJson(json['donDat']) : null),
    );
  }
}

enum TrangThaiPhanCong { ChoPhanCong, DaXacNhan, TuChoi, HoanThanh }