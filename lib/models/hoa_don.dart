// ignore_for_file: constant_identifier_names

/// Model tương ứng bảng HoaDon
class HoaDon {
  final int? id;
  final String maHoaDon;
  final int donDatId;
  final int khachHangId;
  final DateTime ngayLap;
  final HinhThucThanhToan hinhThucThanhToan;
  final int tongTienHang;
  final int soTienGiam;
  final int tongThanhToan;
  final TrangThaiHoaDon trangThaiThanhToan;
  final DateTime? ngayThanhToan;

  const HoaDon({
    this.id,
    required this.maHoaDon,
    required this.donDatId,
    required this.khachHangId,
    required this.ngayLap,
    required this.hinhThucThanhToan,
    required this.tongTienHang,
    this.soTienGiam = 0,
    required this.tongThanhToan,
    this.trangThaiThanhToan = TrangThaiHoaDon.ChuaThanhToan,
    this.ngayThanhToan,
  });

  factory HoaDon.fromJson(Map<String, dynamic> json) => HoaDon(
        id: json['id'] as int?,
        maHoaDon: json['MaHoaDon'] as String,
        donDatId: json['donDatId'] as int,
        khachHangId: json['khachHangId'] as int,
        ngayLap: DateTime.parse(json['NgayLap'] as String),
        hinhThucThanhToan: HinhThucThanhToan.values
            .byName(json['HinhThucThanhToan'] as String),
        tongTienHang: json['TongTienHang'] as int,
        soTienGiam: json['SoTienGiam'] as int? ?? 0,
        tongThanhToan: json['TongThanhToan'] as int,
        trangThaiThanhToan: TrangThaiHoaDon.values
            .byName(json['TrangThaiThanhToan'] as String),
        ngayThanhToan: json['NgayThanhToan'] != null
            ? DateTime.parse(json['NgayThanhToan'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'MaHoaDon': maHoaDon,
        'donDatId': donDatId,
        'khachHangId': khachHangId,
        'NgayLap': ngayLap.toIso8601String(),
        'HinhThucThanhToan': hinhThucThanhToan.name,
        'TongTienHang': tongTienHang,
        'SoTienGiam': soTienGiam,
        'TongThanhToan': tongThanhToan,
        'TrangThaiThanhToan': trangThaiThanhToan.name,
        'NgayThanhToan': ngayThanhToan?.toIso8601String(),
      };

  HoaDon copyWith({
    int? id,
    String? maHoaDon,
    int? donDatId,
    int? khachHangId,
    DateTime? ngayLap,
    HinhThucThanhToan? hinhThucThanhToan,
    int? tongTienHang,
    int? soTienGiam,
    int? tongThanhToan,
    TrangThaiHoaDon? trangThaiThanhToan,
    DateTime? ngayThanhToan,
  }) =>
      HoaDon(
        id: id ?? this.id,
        maHoaDon: maHoaDon ?? this.maHoaDon,
        donDatId: donDatId ?? this.donDatId,
        khachHangId: khachHangId ?? this.khachHangId,
        ngayLap: ngayLap ?? this.ngayLap,
        hinhThucThanhToan: hinhThucThanhToan ?? this.hinhThucThanhToan,
        tongTienHang: tongTienHang ?? this.tongTienHang,
        soTienGiam: soTienGiam ?? this.soTienGiam,
        tongThanhToan: tongThanhToan ?? this.tongThanhToan,
        trangThaiThanhToan: trangThaiThanhToan ?? this.trangThaiThanhToan,
        ngayThanhToan: ngayThanhToan ?? this.ngayThanhToan,
      );
}

enum HinhThucThanhToan { TienMat, ChuyenKhoan }
enum TrangThaiHoaDon { ChuaThanhToan, DaThanhToan, HoanTien }

/// Model tương ứng bảng ChiTietHoaDon
class ChiTietHoaDon {
  final int? id;
  final int hoaDonId;
  final String tenDichVu;
  final String? yeuCauDacBiet;
  final String donViTinh;
  final double soLuong;
  final int donGia;
  final int thanhTien;
  final LoaiDong loaiDong;

  const ChiTietHoaDon({
    this.id,
    required this.hoaDonId,
    required this.tenDichVu,
    this.yeuCauDacBiet,
    required this.donViTinh,
    required this.soLuong,
    required this.donGia,
    required this.thanhTien,
    this.loaiDong = LoaiDong.DichVuChinh,
  });

  factory ChiTietHoaDon.fromJson(Map<String, dynamic> json) => ChiTietHoaDon(
        id: json['id'] as int?,
        hoaDonId: json['hoaDonId'] as int,
        tenDichVu: json['TenDichVu'] as String,
        yeuCauDacBiet: json['YeuCauDacBiet'] as String?,
        donViTinh: json['DonViTinh'] as String,
        soLuong: (json['SoLuong'] as num).toDouble(),
        donGia: json['DonGia'] as int,
        thanhTien: json['ThanhTien'] as int,
        loaiDong: LoaiDong.values.byName(json['LoaiDong'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'hoaDonId': hoaDonId,
        'TenDichVu': tenDichVu,
        'YeuCauDacBiet': yeuCauDacBiet,
        'DonViTinh': donViTinh,
        'SoLuong': soLuong,
        'DonGia': donGia,
        'ThanhTien': thanhTien,
        'LoaiDong': loaiDong.name,
      };

  ChiTietHoaDon copyWith({
    int? id,
    int? hoaDonId,
    String? tenDichVu,
    String? yeuCauDacBiet,
    String? donViTinh,
    double? soLuong,
    int? donGia,
    int? thanhTien,
    LoaiDong? loaiDong,
  }) =>
      ChiTietHoaDon(
        id: id ?? this.id,
        hoaDonId: hoaDonId ?? this.hoaDonId,
        tenDichVu: tenDichVu ?? this.tenDichVu,
        yeuCauDacBiet: yeuCauDacBiet ?? this.yeuCauDacBiet,
        donViTinh: donViTinh ?? this.donViTinh,
        soLuong: soLuong ?? this.soLuong,
        donGia: donGia ?? this.donGia,
        thanhTien: thanhTien ?? this.thanhTien,
        loaiDong: loaiDong ?? this.loaiDong,
      );
}

enum LoaiDong { DichVuChinh, DichVuPhatSinh }

/// Model tương ứng bảng BienLai
class BienLai {
  final int? id;
  final String maBienLai;
  final int hoaDonId;
  final DateTime ngayGioThuTien;
  final int soTienNhan;
  final HinhThucThanhToan hinhThucThanhToan;
  final String nguoiNopTien;
  final String nguoiThuTien;

  const BienLai({
    this.id,
    required this.maBienLai,
    required this.hoaDonId,
    required this.ngayGioThuTien,
    required this.soTienNhan,
    required this.hinhThucThanhToan,
    required this.nguoiNopTien,
    required this.nguoiThuTien,
  });

  factory BienLai.fromJson(Map<String, dynamic> json) => BienLai(
        id: json['id'] as int?,
        maBienLai: json['MaBienLai'] as String,
        hoaDonId: json['hoaDonId'] as int,
        ngayGioThuTien: DateTime.parse(json['NgayGioThuTien'] as String),
        soTienNhan: json['SoTienNhan'] as int,
        hinhThucThanhToan: HinhThucThanhToan.values
            .byName(json['HinhThucThanhToan'] as String),
        nguoiNopTien: json['NguoiNopTien'] as String,
        nguoiThuTien: json['NguoiThuTien'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'MaBienLai': maBienLai,
        'hoaDonId': hoaDonId,
        'NgayGioThuTien': ngayGioThuTien.toIso8601String(),
        'SoTienNhan': soTienNhan,
        'HinhThucThanhToan': hinhThucThanhToan.name,
        'NguoiNopTien': nguoiNopTien,
        'NguoiThuTien': nguoiThuTien,
      };

  BienLai copyWith({
    int? id,
    String? maBienLai,
    int? hoaDonId,
    DateTime? ngayGioThuTien,
    int? soTienNhan,
    HinhThucThanhToan? hinhThucThanhToan,
    String? nguoiNopTien,
    String? nguoiThuTien,
  }) =>
      BienLai(
        id: id ?? this.id,
        maBienLai: maBienLai ?? this.maBienLai,
        hoaDonId: hoaDonId ?? this.hoaDonId,
        ngayGioThuTien: ngayGioThuTien ?? this.ngayGioThuTien,
        soTienNhan: soTienNhan ?? this.soTienNhan,
        hinhThucThanhToan: hinhThucThanhToan ?? this.hinhThucThanhToan,
        nguoiNopTien: nguoiNopTien ?? this.nguoiNopTien,
        nguoiThuTien: nguoiThuTien ?? this.nguoiThuTien,
      );
}
