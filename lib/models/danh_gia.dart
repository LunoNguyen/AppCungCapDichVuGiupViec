// ignore_for_file: constant_identifier_names

/// Model tương ứng bảng DanhGia
class DanhGia {
  final int? id;
  final String maDanhGia;
  final int donDatId;
  final int khachHangId;
  final int congTacVienId;
  final int diemChatLuong;
  final int diemThaiDo;
  final String? nhanXet;
  final DateTime ngayDanhGia;
  final TrangThaiDanhGia trangThai;

  const DanhGia({
    this.id,
    required this.maDanhGia,
    required this.donDatId,
    required this.khachHangId,
    required this.congTacVienId,
    required this.diemChatLuong,
    required this.diemThaiDo,
    this.nhanXet,
    required this.ngayDanhGia,
    this.trangThai = TrangThaiDanhGia.ChoDuyet,
  });

  factory DanhGia.fromJson(Map<String, dynamic> json) => DanhGia(
        id: json['id'] as int?,
        maDanhGia: json['MaDanhGia'] as String,
        donDatId: json['donDatId'] as int,
        khachHangId: json['khachHangId'] as int,
        congTacVienId: json['congTacVienId'] as int,
        diemChatLuong: json['DiemChatLuong'] as int,
        diemThaiDo: json['DiemThaiDo'] as int,
        nhanXet: json['NhanXet'] as String?,
        ngayDanhGia: DateTime.parse(json['NgayDanhGia'] as String),
        trangThai: TrangThaiDanhGia.values.byName(json['TrangThai'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'MaDanhGia': maDanhGia,
        'donDatId': donDatId,
        'khachHangId': khachHangId,
        'congTacVienId': congTacVienId,
        'DiemChatLuong': diemChatLuong,
        'DiemThaiDo': diemThaiDo,
        'NhanXet': nhanXet,
        'NgayDanhGia': ngayDanhGia.toIso8601String(),
        'TrangThai': trangThai.name,
      };

  DanhGia copyWith({
    int? id,
    String? maDanhGia,
    int? donDatId,
    int? khachHangId,
    int? congTacVienId,
    int? diemChatLuong,
    int? diemThaiDo,
    String? nhanXet,
    DateTime? ngayDanhGia,
    TrangThaiDanhGia? trangThai,
  }) =>
      DanhGia(
        id: id ?? this.id,
        maDanhGia: maDanhGia ?? this.maDanhGia,
        donDatId: donDatId ?? this.donDatId,
        khachHangId: khachHangId ?? this.khachHangId,
        congTacVienId: congTacVienId ?? this.congTacVienId,
        diemChatLuong: diemChatLuong ?? this.diemChatLuong,
        diemThaiDo: diemThaiDo ?? this.diemThaiDo,
        nhanXet: nhanXet ?? this.nhanXet,
        ngayDanhGia: ngayDanhGia ?? this.ngayDanhGia,
        trangThai: trangThai ?? this.trangThai,
      );
}

enum TrangThaiDanhGia { ChoDuyet, HienThi, An }

/// Model tương ứng bảng PhanHoiDanhGia
class PhanHoiDanhGia {
  final int? id;
  final int danhGiaId;
  final int? nhanVienId;
  final String noiDung;
  final DateTime thoiGian;

  const PhanHoiDanhGia({
    this.id,
    required this.danhGiaId,
    this.nhanVienId,
    required this.noiDung,
    required this.thoiGian,
  });

  factory PhanHoiDanhGia.fromJson(Map<String, dynamic> json) => PhanHoiDanhGia(
        id: json['id'] as int?,
        danhGiaId: json['danhGiaId'] as int,
        nhanVienId: json['nhanVienId'] as int?,
        noiDung: json['NoiDung'] as String,
        thoiGian: DateTime.parse(json['ThoiGian'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'danhGiaId': danhGiaId,
        'nhanVienId': nhanVienId,
        'NoiDung': noiDung,
        'ThoiGian': thoiGian.toIso8601String(),
      };

  PhanHoiDanhGia copyWith({
    int? id,
    int? danhGiaId,
    int? nhanVienId,
    String? noiDung,
    DateTime? thoiGian,
  }) =>
      PhanHoiDanhGia(
        id: id ?? this.id,
        danhGiaId: danhGiaId ?? this.danhGiaId,
        nhanVienId: nhanVienId ?? this.nhanVienId,
        noiDung: noiDung ?? this.noiDung,
        thoiGian: thoiGian ?? this.thoiGian,
      );
}
