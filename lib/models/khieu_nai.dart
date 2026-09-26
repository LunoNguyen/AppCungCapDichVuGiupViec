// ignore_for_file: constant_identifier_names

/// Model tương ứng bảng KhieuNai
class KhieuNai {
  final int? id;
  final String maKhieuNai;
  final int donDatId;
  final int khachHangId;
  final LoaiVanDe loaiVanDe;
  final String noiDung;
  final TrangThaiKhieuNai trangThai;
  final DateTime ngayGui;
  final DateTime? ngayGiaiQuyet;

  const KhieuNai({
    this.id,
    required this.maKhieuNai,
    required this.donDatId,
    required this.khachHangId,
    required this.loaiVanDe,
    required this.noiDung,
    this.trangThai = TrangThaiKhieuNai.Moi,
    required this.ngayGui,
    this.ngayGiaiQuyet,
  });

  factory KhieuNai.fromJson(Map<String, dynamic> json) => KhieuNai(
        id: json['id'] as int?,
        maKhieuNai: json['MaKhieuNai'] as String,
        donDatId: json['donDatId'] as int,
        khachHangId: json['khachHangId'] as int,
        loaiVanDe: LoaiVanDe.values.byName(json['LoaiVanDe'] as String),
        noiDung: json['NoiDung'] as String,
        trangThai: TrangThaiKhieuNai.values.byName(json['TrangThai'] as String),
        ngayGui: DateTime.parse(json['NgayGui'] as String),
        ngayGiaiQuyet: json['NgayGiaiQuyet'] != null
            ? DateTime.parse(json['NgayGiaiQuyet'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'MaKhieuNai': maKhieuNai,
        'donDatId': donDatId,
        'khachHangId': khachHangId,
        'LoaiVanDe': loaiVanDe.name,
        'NoiDung': noiDung,
        'TrangThai': trangThai.name,
        'NgayGui': ngayGui.toIso8601String(),
        'NgayGiaiQuyet': ngayGiaiQuyet?.toIso8601String(),
      };

  KhieuNai copyWith({
    int? id,
    String? maKhieuNai,
    int? donDatId,
    int? khachHangId,
    LoaiVanDe? loaiVanDe,
    String? noiDung,
    TrangThaiKhieuNai? trangThai,
    DateTime? ngayGui,
    DateTime? ngayGiaiQuyet,
  }) =>
      KhieuNai(
        id: id ?? this.id,
        maKhieuNai: maKhieuNai ?? this.maKhieuNai,
        donDatId: donDatId ?? this.donDatId,
        khachHangId: khachHangId ?? this.khachHangId,
        loaiVanDe: loaiVanDe ?? this.loaiVanDe,
        noiDung: noiDung ?? this.noiDung,
        trangThai: trangThai ?? this.trangThai,
        ngayGui: ngayGui ?? this.ngayGui,
        ngayGiaiQuyet: ngayGiaiQuyet ?? this.ngayGiaiQuyet,
      );
}

enum LoaiVanDe { ChatLuongDichVu, TaiSanHuHong, ThaiFDoPhucVu, Khac }

enum TrangThaiKhieuNai { Moi, DangXuLy, ChoXacMinh, DaGiaiQuyet, LeoCao }

/// Model tương ứng bảng TaiLieuKhieuNai
class TaiLieuKhieuNai {
  final int? id;
  final int khieuNaiId;
  final LoaiFileTL loaiFile;
  final String duongDanFile;
  final DateTime ngayTai;

  const TaiLieuKhieuNai({
    this.id,
    required this.khieuNaiId,
    required this.loaiFile,
    required this.duongDanFile,
    required this.ngayTai,
  });

  factory TaiLieuKhieuNai.fromJson(Map<String, dynamic> json) => TaiLieuKhieuNai(
        id: json['id'] as int?,
        khieuNaiId: json['khieuNaiId'] as int,
        loaiFile: LoaiFileTL.values.byName(json['LoaiFile'] as String),
        duongDanFile: json['DuongDanFile'] as String,
        ngayTai: DateTime.parse(json['NgayTai'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'khieuNaiId': khieuNaiId,
        'LoaiFile': loaiFile.name,
        'DuongDanFile': duongDanFile,
        'NgayTai': ngayTai.toIso8601String(),
      };

  TaiLieuKhieuNai copyWith({
    int? id,
    int? khieuNaiId,
    LoaiFileTL? loaiFile,
    String? duongDanFile,
    DateTime? ngayTai,
  }) =>
      TaiLieuKhieuNai(
        id: id ?? this.id,
        khieuNaiId: khieuNaiId ?? this.khieuNaiId,
        loaiFile: loaiFile ?? this.loaiFile,
        duongDanFile: duongDanFile ?? this.duongDanFile,
        ngayTai: ngayTai ?? this.ngayTai,
      );
}

enum LoaiFileTL { HinhAnh, Video, TaiLieuKhac }

/// Model tương ứng bảng LichSuXuLyKhieuNai
class LichSuXuLyKhieuNai {
  final int? id;
  final int khieuNaiId;
  final int? nhanVienId;
  final String hanhDong;
  final KetQuaXuLy? ketQua;
  final DateTime thoiGian;

  const LichSuXuLyKhieuNai({
    this.id,
    required this.khieuNaiId,
    this.nhanVienId,
    required this.hanhDong,
    this.ketQua,
    required this.thoiGian,
  });

  factory LichSuXuLyKhieuNai.fromJson(Map<String, dynamic> json) =>
      LichSuXuLyKhieuNai(
        id: json['id'] as int?,
        khieuNaiId: json['khieuNaiId'] as int,
        nhanVienId: json['nhanVienId'] as int?,
        hanhDong: json['HanhDong'] as String,
        ketQua: json['KetQua'] != null
            ? KetQuaXuLy.values.byName(json['KetQua'] as String)
            : null,
        thoiGian: DateTime.parse(json['ThoiGian'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'khieuNaiId': khieuNaiId,
        'nhanVienId': nhanVienId,
        'HanhDong': hanhDong,
        'KetQua': ketQua?.name,
        'ThoiGian': thoiGian.toIso8601String(),
      };

  LichSuXuLyKhieuNai copyWith({
    int? id,
    int? khieuNaiId,
    int? nhanVienId,
    String? hanhDong,
    KetQuaXuLy? ketQua,
    DateTime? thoiGian,
  }) =>
      LichSuXuLyKhieuNai(
        id: id ?? this.id,
        khieuNaiId: khieuNaiId ?? this.khieuNaiId,
        nhanVienId: nhanVienId ?? this.nhanVienId,
        hanhDong: hanhDong ?? this.hanhDong,
        ketQua: ketQua ?? this.ketQua,
        thoiGian: thoiGian ?? this.thoiGian,
      );
}

enum KetQuaXuLy { HopLe, KhongHopLe, LeoCao, ChoBoiThuong }

/// Model tương ứng bảng BoiThuong
class BoiThuong {
  final int? id;
  final String maBoiThuong;
  final int khieuNaiId;
  final String phuongAnBoiThuong;
  final int giaTriBoiThuong;
  final TrangThaiBoiThuong trangThai;
  final DateTime? ngayPheduyet;
  final DateTime? ngayThucHien;

  const BoiThuong({
    this.id,
    required this.maBoiThuong,
    required this.khieuNaiId,
    required this.phuongAnBoiThuong,
    this.giaTriBoiThuong = 0,
    this.trangThai = TrangThaiBoiThuong.ChoPheduyet,
    this.ngayPheduyet,
    this.ngayThucHien,
  });

  factory BoiThuong.fromJson(Map<String, dynamic> json) => BoiThuong(
        id: json['id'] as int?,
        maBoiThuong: json['MaBoiThuong'] as String,
        khieuNaiId: json['khieuNaiId'] as int,
        phuongAnBoiThuong: json['PhuongAnBoiThuong'] as String,
        giaTriBoiThuong: json['GiaTriBoiThuong'] as int? ?? 0,
        trangThai: TrangThaiBoiThuong.values.byName(json['TrangThai'] as String),
        ngayPheduyet: json['NgayPheduyet'] != null
            ? DateTime.parse(json['NgayPheduyet'] as String)
            : null,
        ngayThucHien: json['NgayThucHien'] != null
            ? DateTime.parse(json['NgayThucHien'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'MaBoiThuong': maBoiThuong,
        'khieuNaiId': khieuNaiId,
        'PhuongAnBoiThuong': phuongAnBoiThuong,
        'GiaTriBoiThuong': giaTriBoiThuong,
        'TrangThai': trangThai.name,
        'NgayPheduyet': ngayPheduyet?.toIso8601String(),
        'NgayThucHien': ngayThucHien?.toIso8601String(),
      };

  BoiThuong copyWith({
    int? id,
    String? maBoiThuong,
    int? khieuNaiId,
    String? phuongAnBoiThuong,
    int? giaTriBoiThuong,
    TrangThaiBoiThuong? trangThai,
    DateTime? ngayPheduyet,
    DateTime? ngayThucHien,
  }) =>
      BoiThuong(
        id: id ?? this.id,
        maBoiThuong: maBoiThuong ?? this.maBoiThuong,
        khieuNaiId: khieuNaiId ?? this.khieuNaiId,
        phuongAnBoiThuong: phuongAnBoiThuong ?? this.phuongAnBoiThuong,
        giaTriBoiThuong: giaTriBoiThuong ?? this.giaTriBoiThuong,
        trangThai: trangThai ?? this.trangThai,
        ngayPheduyet: ngayPheduyet ?? this.ngayPheduyet,
        ngayThucHien: ngayThucHien ?? this.ngayThucHien,
      );
}

enum TrangThaiBoiThuong { ChoPheduyet, DaPheduyet, DaThucHien, KhachHangTuChoi }
