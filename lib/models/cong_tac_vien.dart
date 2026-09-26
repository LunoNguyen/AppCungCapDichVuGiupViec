// ignore_for_file: constant_identifier_names

/// Model tương ứng bảng CongTacVien
class CongTacVien {
  final int? id;
  final String maCongTacVien;
  final int? taiKhoanId;
  final String hoTen;
  final DateTime? ngaySinh;
  final GioiTinhCTV? gioiTinh;
  final String noiCuTru;
  final String soDienThoai;
  final double diemDanhGia;
  final CapDoCTV capDo;
  final TrangThaiCTV trangThai;
  final DateTime ngayDangKy;

  const CongTacVien({
    this.id,
    required this.maCongTacVien,
    this.taiKhoanId,
    required this.hoTen,
    this.ngaySinh,
    this.gioiTinh,
    required this.noiCuTru,
    required this.soDienThoai,
    this.diemDanhGia = 0.0,
    this.capDo = CapDoCTV.Moi,
    required this.trangThai,
    required this.ngayDangKy,
  });

  factory CongTacVien.fromJson(Map<String, dynamic> json) => CongTacVien(
        id: json['id'] as int?,
        maCongTacVien: json['MaCongTacVien'] as String,
        taiKhoanId: json['taiKhoanId'] as int?,
        hoTen: json['HoTen'] as String,
        ngaySinh: json['NgaySinh'] != null
            ? DateTime.parse(json['NgaySinh'] as String)
            : null,
        gioiTinh: json['GioiTinh'] != null
            ? GioiTinhCTV.values.byName(json['GioiTinh'] as String)
            : null,
        noiCuTru: json['NoiCuTru'] as String,
        soDienThoai: json['SoDienThoai'] as String,
        diemDanhGia: (json['DiemDanhGia'] as num).toDouble(),
        capDo: CapDoCTV.values.byName(json['CapDo'] as String),
        trangThai: TrangThaiCTV.values.byName(json['TrangThai'] as String),
        ngayDangKy: DateTime.parse(json['NgayDangKy'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'MaCongTacVien': maCongTacVien,
        'taiKhoanId': taiKhoanId,
        'HoTen': hoTen,
        'NgaySinh': ngaySinh?.toIso8601String().split('T')[0],
        'GioiTinh': gioiTinh?.name,
        'NoiCuTru': noiCuTru,
        'SoDienThoai': soDienThoai,
        'DiemDanhGia': diemDanhGia,
        'CapDo': capDo.name,
        'TrangThai': trangThai.name,
        'NgayDangKy': ngayDangKy.toIso8601String().split('T')[0],
      };

  CongTacVien copyWith({
    int? id,
    String? maCongTacVien,
    int? taiKhoanId,
    String? hoTen,
    DateTime? ngaySinh,
    GioiTinhCTV? gioiTinh,
    String? noiCuTru,
    String? soDienThoai,
    double? diemDanhGia,
    CapDoCTV? capDo,
    TrangThaiCTV? trangThai,
    DateTime? ngayDangKy,
  }) =>
      CongTacVien(
        id: id ?? this.id,
        maCongTacVien: maCongTacVien ?? this.maCongTacVien,
        taiKhoanId: taiKhoanId ?? this.taiKhoanId,
        hoTen: hoTen ?? this.hoTen,
        ngaySinh: ngaySinh ?? this.ngaySinh,
        gioiTinh: gioiTinh ?? this.gioiTinh,
        noiCuTru: noiCuTru ?? this.noiCuTru,
        soDienThoai: soDienThoai ?? this.soDienThoai,
        diemDanhGia: diemDanhGia ?? this.diemDanhGia,
        capDo: capDo ?? this.capDo,
        trangThai: trangThai ?? this.trangThai,
        ngayDangKy: ngayDangKy ?? this.ngayDangKy,
      );
}

enum CapDoCTV { Moi, Thuong, UuTu }

enum TrangThaiCTV { ChoDuyet, HoatDong, DinhChi, TuChoi }

enum GioiTinhCTV { Nam, Nu, Khac }

/// Model tương ứng bảng ChungChiCTV
class ChungChiCTV {
  final int? id;
  final String maChungChi;
  final int congTacVienId;
  final LoaiChungChi loaiChungChi;
  final String tenChungChi;
  final String? noiCap;
  final DateTime? ngayCap;
  final String? duongDanFile;

  const ChungChiCTV({
    this.id,
    required this.maChungChi,
    required this.congTacVienId,
    required this.loaiChungChi,
    required this.tenChungChi,
    this.noiCap,
    this.ngayCap,
    this.duongDanFile,
  });

  factory ChungChiCTV.fromJson(Map<String, dynamic> json) => ChungChiCTV(
        id: json['id'] as int?,
        maChungChi: json['MaChungChi'] as String,
        congTacVienId: json['congTacVienId'] as int,
        loaiChungChi: LoaiChungChi.values.byName(json['LoaiChungChi'] as String),
        tenChungChi: json['TenChungChi'] as String,
        noiCap: json['NoiCap'] as String?,
        ngayCap: json['NgayCap'] != null
            ? DateTime.parse(json['NgayCap'] as String)
            : null,
        duongDanFile: json['DuongDanFile'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'MaChungChi': maChungChi,
        'congTacVienId': congTacVienId,
        'LoaiChungChi': loaiChungChi.name,
        'TenChungChi': tenChungChi,
        'NoiCap': noiCap,
        'NgayCap': ngayCap?.toIso8601String().split('T')[0],
        'DuongDanFile': duongDanFile,
      };

  ChungChiCTV copyWith({
    int? id,
    String? maChungChi,
    int? congTacVienId,
    LoaiChungChi? loaiChungChi,
    String? tenChungChi,
    String? noiCap,
    DateTime? ngayCap,
    String? duongDanFile,
  }) =>
      ChungChiCTV(
        id: id ?? this.id,
        maChungChi: maChungChi ?? this.maChungChi,
        congTacVienId: congTacVienId ?? this.congTacVienId,
        loaiChungChi: loaiChungChi ?? this.loaiChungChi,
        tenChungChi: tenChungChi ?? this.tenChungChi,
        noiCap: noiCap ?? this.noiCap,
        ngayCap: ngayCap ?? this.ngayCap,
        duongDanFile: duongDanFile ?? this.duongDanFile,
      );
}

enum LoaiChungChi { BangCap, ChungNhan, ChungChi }

/// Model tương ứng bảng HoSoCTV
class HoSoCTV {
  final int? id;
  final String maHoSo;
  final int congTacVienId;
  final LoaiTaiLieuHoSo loaiTaiLieu;
  final String duongDanFile;
  final DateTime ngayTai;

  const HoSoCTV({
    this.id,
    required this.maHoSo,
    required this.congTacVienId,
    required this.loaiTaiLieu,
    required this.duongDanFile,
    required this.ngayTai,
  });

  factory HoSoCTV.fromJson(Map<String, dynamic> json) => HoSoCTV(
        id: json['id'] as int?,
        maHoSo: json['MaHoSo'] as String,
        congTacVienId: json['congTacVienId'] as int,
        loaiTaiLieu: LoaiTaiLieuHoSo.values.byName(json['LoaiTaiLieu'] as String),
        duongDanFile: json['DuongDanFile'] as String,
        ngayTai: DateTime.parse(json['NgayTai'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'MaHoSo': maHoSo,
        'congTacVienId': congTacVienId,
        'LoaiTaiLieu': loaiTaiLieu.name,
        'DuongDanFile': duongDanFile,
        'NgayTai': ngayTai.toIso8601String(),
      };

  HoSoCTV copyWith({
    int? id,
    String? maHoSo,
    int? congTacVienId,
    LoaiTaiLieuHoSo? loaiTaiLieu,
    String? duongDanFile,
    DateTime? ngayTai,
  }) =>
      HoSoCTV(
        id: id ?? this.id,
        maHoSo: maHoSo ?? this.maHoSo,
        congTacVienId: congTacVienId ?? this.congTacVienId,
        loaiTaiLieu: loaiTaiLieu ?? this.loaiTaiLieu,
        duongDanFile: duongDanFile ?? this.duongDanFile,
        ngayTai: ngayTai ?? this.ngayTai,
      );
}

enum LoaiTaiLieuHoSo { AnhChanDung, CCCD_Mat_Truoc, CCCD_Mat_Sau, TaiLieuKhac }

/// Model tương ứng bảng ChuyenMon
class ChuyenMon {
  final String maChuyenMon;
  final String maCongTacVien;
  final String tenChuyenMon;
  final int? soKinhNghiem;

  const ChuyenMon({
    required this.maChuyenMon,
    required this.maCongTacVien,
    required this.tenChuyenMon,
    this.soKinhNghiem,
  });

  factory ChuyenMon.fromJson(Map<String, dynamic> json) => ChuyenMon(
        maChuyenMon: json['MaChuyenMon'] as String,
        maCongTacVien: json['MaCongTacVien'] as String,
        tenChuyenMon: json['TenChuyenMon'] as String,
        soKinhNghiem: json['SoKinhNghiem'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'MaChuyenMon': maChuyenMon,
        'MaCongTacVien': maCongTacVien,
        'TenChuyenMon': tenChuyenMon,
        'SoKinhNghiem': soKinhNghiem,
      };

  ChuyenMon copyWith({
    String? maChuyenMon,
    String? maCongTacVien,
    String? tenChuyenMon,
    int? soKinhNghiem,
  }) =>
      ChuyenMon(
        maChuyenMon: maChuyenMon ?? this.maChuyenMon,
        maCongTacVien: maCongTacVien ?? this.maCongTacVien,
        tenChuyenMon: tenChuyenMon ?? this.tenChuyenMon,
        soKinhNghiem: soKinhNghiem ?? this.soKinhNghiem,
      );
}
