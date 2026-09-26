// ignore_for_file: constant_identifier_names

/// Model tương ứng bảng BieuMauTaiSan
class BieuMauTaiSan {
  final int? id;
  final String maBieuMau;
  final int donDatId;
  final int congTacVienId;
  final LoaiBieuMau loaiBieuMau;
  final DateTime thoiGianGhiNhan;
  final bool xacNhanKhachHang;
  final String? yKienChinhSua;
  final String? ghiChuDacBiet;

  const BieuMauTaiSan({
    this.id,
    required this.maBieuMau,
    required this.donDatId,
    required this.congTacVienId,
    required this.loaiBieuMau,
    required this.thoiGianGhiNhan,
    this.xacNhanKhachHang = false,
    this.yKienChinhSua,
    this.ghiChuDacBiet,
  });

  factory BieuMauTaiSan.fromJson(Map<String, dynamic> json) => BieuMauTaiSan(
        id: json['id'] as int?,
        maBieuMau: json['MaBieuMau'] as String,
        donDatId: json['donDatId'] as int,
        congTacVienId: json['congTacVienId'] as int,
        loaiBieuMau: LoaiBieuMau.values.byName(json['LoaiBieuMau'] as String),
        thoiGianGhiNhan: DateTime.parse(json['ThoiGianGhiNhan'] as String),
        xacNhanKhachHang: (json['XacNhanKhachHang'] as int) == 1,
        yKienChinhSua: json['YKienChinhSua'] as String?,
        ghiChuDacBiet: json['GhiChuDacBiet'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'MaBieuMau': maBieuMau,
        'donDatId': donDatId,
        'congTacVienId': congTacVienId,
        'LoaiBieuMau': loaiBieuMau.name,
        'ThoiGianGhiNhan': thoiGianGhiNhan.toIso8601String(),
        'XacNhanKhachHang': xacNhanKhachHang ? 1 : 0,
        'YKienChinhSua': yKienChinhSua,
        'GhiChuDacBiet': ghiChuDacBiet,
      };

  BieuMauTaiSan copyWith({
    int? id,
    String? maBieuMau,
    int? donDatId,
    int? congTacVienId,
    LoaiBieuMau? loaiBieuMau,
    DateTime? thoiGianGhiNhan,
    bool? xacNhanKhachHang,
    String? yKienChinhSua,
    String? ghiChuDacBiet,
  }) =>
      BieuMauTaiSan(
        id: id ?? this.id,
        maBieuMau: maBieuMau ?? this.maBieuMau,
        donDatId: donDatId ?? this.donDatId,
        congTacVienId: congTacVienId ?? this.congTacVienId,
        loaiBieuMau: loaiBieuMau ?? this.loaiBieuMau,
        thoiGianGhiNhan: thoiGianGhiNhan ?? this.thoiGianGhiNhan,
        xacNhanKhachHang: xacNhanKhachHang ?? this.xacNhanKhachHang,
        yKienChinhSua: yKienChinhSua ?? this.yKienChinhSua,
        ghiChuDacBiet: ghiChuDacBiet ?? this.ghiChuDacBiet,
      );
}

enum LoaiBieuMau { TruocDichVu, SauDichVu }

/// Model tương ứng bảng ChiTietTaiSan
class ChiTietTaiSan {
  final int? id;
  final int bieuMauId;
  final String khuVucVatDung;
  final String moTaHienTrang;
  final String? hinhAnh;

  const ChiTietTaiSan({
    this.id,
    required this.bieuMauId,
    required this.khuVucVatDung,
    required this.moTaHienTrang,
    this.hinhAnh,
  });

  factory ChiTietTaiSan.fromJson(Map<String, dynamic> json) => ChiTietTaiSan(
        id: json['id'] as int?,
        bieuMauId: json['bieuMauId'] as int,
        khuVucVatDung: json['KhuVucVatDung'] as String,
        moTaHienTrang: json['MoTaHienTrang'] as String,
        hinhAnh: json['HinhAnh'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'bieuMauId': bieuMauId,
        'KhuVucVatDung': khuVucVatDung,
        'MoTaHienTrang': moTaHienTrang,
        'HinhAnh': hinhAnh,
      };

  ChiTietTaiSan copyWith({
    int? id,
    int? bieuMauId,
    String? khuVucVatDung,
    String? moTaHienTrang,
    String? hinhAnh,
  }) =>
      ChiTietTaiSan(
        id: id ?? this.id,
        bieuMauId: bieuMauId ?? this.bieuMauId,
        khuVucVatDung: khuVucVatDung ?? this.khuVucVatDung,
        moTaHienTrang: moTaHienTrang ?? this.moTaHienTrang,
        hinhAnh: hinhAnh ?? this.hinhAnh,
      );
}
