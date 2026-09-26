// ignore_for_file: constant_identifier_names

/// Model tương ứng bảng ChuongTrinhKhuyenMai
class ChuongTrinhKhuyenMai {
  final int? id;
  final String maChuongTrinh;
  final String tenChuongTrinh;
  final String? moTa;
  final LoaiGiam loaiGiam;
  final double giaTriGiam;
  final int? soTienGiamToiDa;
  final int dieuKienToiThieu;
  final DateTime ngayBatDau;
  final DateTime ngayKetThuc;
  final TrangThaiKhuyenMai trangThai;

  const ChuongTrinhKhuyenMai({
    this.id,
    required this.maChuongTrinh,
    required this.tenChuongTrinh,
    this.moTa,
    required this.loaiGiam,
    required this.giaTriGiam,
    this.soTienGiamToiDa,
    this.dieuKienToiThieu = 0,
    required this.ngayBatDau,
    required this.ngayKetThuc,
    this.trangThai = TrangThaiKhuyenMai.SapDienRa,
  });

  factory ChuongTrinhKhuyenMai.fromJson(Map<String, dynamic> json) => ChuongTrinhKhuyenMai(
        id: json['id'] as int?,
        maChuongTrinh: json['MaChuongTrinh'] as String,
        tenChuongTrinh: json['TenChuongTrinh'] as String,
        moTa: json['MoTa'] as String?,
        loaiGiam: LoaiGiam.values.byName(json['LoaiGiam'] as String),
        giaTriGiam: (json['GiaTriGiam'] as num).toDouble(),
        soTienGiamToiDa: json['SoTienGiamToiDa'] as int?,
        dieuKienToiThieu: json['DieuKienToiThieu'] as int? ?? 0,
        ngayBatDau: DateTime.parse(json['NgayBatDau'] as String),
        ngayKetThuc: DateTime.parse(json['NgayKetThuc'] as String),
        trangThai: TrangThaiKhuyenMai.values.byName(json['TrangThai'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'MaChuongTrinh': maChuongTrinh,
        'TenChuongTrinh': tenChuongTrinh,
        'MoTa': moTa,
        'LoaiGiam': loaiGiam.name,
        'GiaTriGiam': giaTriGiam,
        'SoTienGiamToiDa': soTienGiamToiDa,
        'DieuKienToiThieu': dieuKienToiThieu,
        'NgayBatDau': ngayBatDau.toIso8601String().split('T')[0],
        'NgayKetThuc': ngayKetThuc.toIso8601String().split('T')[0],
        'TrangThai': trangThai.name,
      };

  ChuongTrinhKhuyenMai copyWith({
    int? id,
    String? maChuongTrinh,
    String? tenChuongTrinh,
    String? moTa,
    LoaiGiam? loaiGiam,
    double? giaTriGiam,
    int? soTienGiamToiDa,
    int? dieuKienToiThieu,
    DateTime? ngayBatDau,
    DateTime? ngayKetThuc,
    TrangThaiKhuyenMai? trangThai,
  }) =>
      ChuongTrinhKhuyenMai(
        id: id ?? this.id,
        maChuongTrinh: maChuongTrinh ?? this.maChuongTrinh,
        tenChuongTrinh: tenChuongTrinh ?? this.tenChuongTrinh,
        moTa: moTa ?? this.moTa,
        loaiGiam: loaiGiam ?? this.loaiGiam,
        giaTriGiam: giaTriGiam ?? this.giaTriGiam,
        soTienGiamToiDa: soTienGiamToiDa ?? this.soTienGiamToiDa,
        dieuKienToiThieu: dieuKienToiThieu ?? this.dieuKienToiThieu,
        ngayBatDau: ngayBatDau ?? this.ngayBatDau,
        ngayKetThuc: ngayKetThuc ?? this.ngayKetThuc,
        trangThai: trangThai ?? this.trangThai,
      );
}

enum LoaiGiam { PhanTram, SoTienCoDinh }
enum TrangThaiKhuyenMai { DangHoatDong, SapDienRa, DaKetThuc }

/// Model tương ứng bảng MaKhuyenMai
class MaKhuyenMai {
  final int? id;
  final String maKhuyenMai;
  final int chuongTrinhKMId;
  final String codeKhuyenMai;
  final int soLuotToiDa;
  final int soLuotDaDung;
  final TrangThaiMaKM trangThai;

  const MaKhuyenMai({
    this.id,
    required this.maKhuyenMai,
    required this.chuongTrinhKMId,
    required this.codeKhuyenMai,
    this.soLuotToiDa = 1,
    this.soLuotDaDung = 0,
    this.trangThai = TrangThaiMaKM.HoatDong,
  });

  factory MaKhuyenMai.fromJson(Map<String, dynamic> json) => MaKhuyenMai(
        id: json['id'] as int?,
        maKhuyenMai: json['MaKhuyenMai'] as String,
        chuongTrinhKMId: json['chuongTrinhKMId'] as int,
        codeKhuyenMai: json['CodeKhuyenMai'] as String,
        soLuotToiDa: json['SoLuotToiDa'] as int? ?? 1,
        soLuotDaDung: json['SoLuotDaDung'] as int? ?? 0,
        trangThai: TrangThaiMaKM.values.byName(json['TrangThai'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'MaKhuyenMai': maKhuyenMai,
        'chuongTrinhKMId': chuongTrinhKMId,
        'CodeKhuyenMai': codeKhuyenMai,
        'SoLuotToiDa': soLuotToiDa,
        'SoLuotDaDung': soLuotDaDung,
        'TrangThai': trangThai.name,
      };

  MaKhuyenMai copyWith({
    int? id,
    String? maKhuyenMai,
    int? chuongTrinhKMId,
    String? codeKhuyenMai,
    int? soLuotToiDa,
    int? soLuotDaDung,
    TrangThaiMaKM? trangThai,
  }) =>
      MaKhuyenMai(
        id: id ?? this.id,
        maKhuyenMai: maKhuyenMai ?? this.maKhuyenMai,
        chuongTrinhKMId: chuongTrinhKMId ?? this.chuongTrinhKMId,
        codeKhuyenMai: codeKhuyenMai ?? this.codeKhuyenMai,
        soLuotToiDa: soLuotToiDa ?? this.soLuotToiDa,
        soLuotDaDung: soLuotDaDung ?? this.soLuotDaDung,
        trangThai: trangThai ?? this.trangThai,
      );
}

enum TrangThaiMaKM { HoatDong, HetLuot, HetHan }
