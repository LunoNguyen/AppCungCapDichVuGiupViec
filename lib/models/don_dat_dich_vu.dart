// ignore_for_file: constant_identifier_names

/// Model tương ứng bảng DonDatDichVu
class DonDatDichVu {
  final int? id;
  final String maDonDat;
  final int khachHangId;
  final int dichVuId;
  final String? tenDichVu;
  final String? khachHangTen;
  final String? khachHangPhone;
  final String? diaChi;
  final DateTime ngayThucHien;
  final String gioBatDau;
  final String? gioKetThuc;
  final int thanhTien;
  final String trangThai;

  const DonDatDichVu({
    this.id,
    required this.maDonDat,
    required this.khachHangId,
    required this.dichVuId,
    this.tenDichVu,
    this.khachHangTen,
    this.khachHangPhone,
    this.diaChi,
    required this.ngayThucHien,
    required this.gioBatDau,
    this.gioKetThuc,
    required this.thanhTien,
    required this.trangThai,
  });

  factory DonDatDichVu.fromJson(Map<String, dynamic> json) {
    return DonDatDichVu(
      id: json['id'] as int? ?? json['donDatId'] as int?,
      maDonDat: json['maDonDat'] ?? '',
      khachHangId: json['khachHangId'] ?? 0,
      dichVuId: json['dichVuId'] ?? 0,
      tenDichVu: json['tenDichVu'],
      khachHangTen: json['khachHangTen'],
      khachHangPhone: json['khachHangPhone'],
      diaChi: json['diaChi'],
      ngayThucHien: json['ngayThucHien'] != null 
          ? DateTime.parse(json['ngayThucHien'].toString()) 
          : DateTime.now(),
      gioBatDau: json['gioBatDau'] ?? '',
      gioKetThuc: json['gioKetThuc'],
      thanhTien: (json['thanhTien'] as num?)?.toInt() ?? 0,
      trangThai: json['trangThai'] ?? json['trangThaiDon'] ?? '',
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
