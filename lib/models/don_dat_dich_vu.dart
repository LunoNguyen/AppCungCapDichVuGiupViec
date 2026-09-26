// ignore_for_file: constant_identifier_names

/// Model tương ứng bảng DonDatDichVu
class DonDatDichVu {
  final int? id;
  final String maDonDat;
  final int khachHangId;
  final int diaChiId;
  final int? nhanVienTiepNhanId;
  final int dichVuId;
  final int? bangGiaId;
  final int? goiDichVuId;
  final int? khuyenMaiId;
  final LoaiHinhDatDon loaiHinhDat;
  final DateTime ngayThucHien;
  final String gioBatDau;
  final String? gioKetThuc;
  final String? yeuCauDacBiet;
  final int chiPhiGoc;
  final int soTienGiam;
  final int thanhTien;
  final TrangThaiDon trangThai;
  final DateTime ngayTao;
  final String? ghiChu;

  const DonDatDichVu({
    this.id,
    required this.maDonDat,
    required this.khachHangId,
    required this.diaChiId,
    this.nhanVienTiepNhanId,
    required this.dichVuId,
    this.bangGiaId,
    this.goiDichVuId,
    this.khuyenMaiId,
    required this.loaiHinhDat,
    required this.ngayThucHien,
    required this.gioBatDau,
    this.gioKetThuc,
    this.yeuCauDacBiet,
    required this.chiPhiGoc,
    this.soTienGiam = 0,
    required this.thanhTien,
    this.trangThai = TrangThaiDon.ChoDuyet,
    required this.ngayTao,
    this.ghiChu,
  });

  factory DonDatDichVu.fromJson(Map<String, dynamic> json) => DonDatDichVu(
        id: json['id'] as int?,
        maDonDat: json['MaDonDat'] as String,
        khachHangId: json['khachHangId'] as int,
        diaChiId: json['diaChiId'] as int,
        nhanVienTiepNhanId: json['nhanVienTiepNhanId'] as int?,
        dichVuId: json['dichVuId'] as int,
        bangGiaId: json['bangGiaId'] as int?,
        goiDichVuId: json['goiDichVuId'] as int?,
        khuyenMaiId: json['khuyenMaiId'] as int?,
        loaiHinhDat: LoaiHinhDatDon.values.byName(json['LoaiHinhDat'] as String),
        ngayThucHien: DateTime.parse(json['NgayThucHien'] as String),
        gioBatDau: json['GioBatDau'] as String,
        gioKetThuc: json['GioKetThuc'] as String?,
        yeuCauDacBiet: json['YeuCauDacBiet'] as String?,
        chiPhiGoc: json['ChiPhiGoc'] as int,
        soTienGiam: json['SoTienGiam'] as int? ?? 0,
        thanhTien: json['ThanhTien'] as int,
        trangThai: TrangThaiDon.values.byName(json['TrangThai'] as String),
        ngayTao: DateTime.parse(json['NgayTao'] as String),
        ghiChu: json['GhiChu'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'MaDonDat': maDonDat,
        'khachHangId': khachHangId,
        'diaChiId': diaChiId,
        'nhanVienTiepNhanId': nhanVienTiepNhanId,
        'dichVuId': dichVuId,
        'bangGiaId': bangGiaId,
        'goiDichVuId': goiDichVuId,
        'khuyenMaiId': khuyenMaiId,
        'LoaiHinhDat': loaiHinhDat.name,
        'NgayThucHien': ngayThucHien.toIso8601String().split('T')[0],
        'GioBatDau': gioBatDau,
        'GioKetThuc': gioKetThuc,
        'YeuCauDacBiet': yeuCauDacBiet,
        'ChiPhiGoc': chiPhiGoc,
        'SoTienGiam': soTienGiam,
        'ThanhTien': thanhTien,
        'TrangThai': trangThai.name,
        'NgayTao': ngayTao.toIso8601String(),
        'GhiChu': ghiChu,
      };

  DonDatDichVu copyWith({
    int? id,
    String? maDonDat,
    int? khachHangId,
    int? diaChiId,
    int? nhanVienTiepNhanId,
    int? dichVuId,
    int? bangGiaId,
    int? goiDichVuId,
    int? khuyenMaiId,
    LoaiHinhDatDon? loaiHinhDat,
    DateTime? ngayThucHien,
    String? gioBatDau,
    String? gioKetThuc,
    String? yeuCauDacBiet,
    int? chiPhiGoc,
    int? soTienGiam,
    int? thanhTien,
    TrangThaiDon? trangThai,
    DateTime? ngayTao,
    String? ghiChu,
  }) =>
      DonDatDichVu(
        id: id ?? this.id,
        maDonDat: maDonDat ?? this.maDonDat,
        khachHangId: khachHangId ?? this.khachHangId,
        diaChiId: diaChiId ?? this.diaChiId,
        nhanVienTiepNhanId: nhanVienTiepNhanId ?? this.nhanVienTiepNhanId,
        dichVuId: dichVuId ?? this.dichVuId,
        bangGiaId: bangGiaId ?? this.bangGiaId,
        goiDichVuId: goiDichVuId ?? this.goiDichVuId,
        khuyenMaiId: khuyenMaiId ?? this.khuyenMaiId,
        loaiHinhDat: loaiHinhDat ?? this.loaiHinhDat,
        ngayThucHien: ngayThucHien ?? this.ngayThucHien,
        gioBatDau: gioBatDau ?? this.gioBatDau,
        gioKetThuc: gioKetThuc ?? this.gioKetThuc,
        yeuCauDacBiet: yeuCauDacBiet ?? this.yeuCauDacBiet,
        chiPhiGoc: chiPhiGoc ?? this.chiPhiGoc,
        soTienGiam: soTienGiam ?? this.soTienGiam,
        thanhTien: thanhTien ?? this.thanhTien,
        trangThai: trangThai ?? this.trangThai,
        ngayTao: ngayTao ?? this.ngayTao,
        ghiChu: ghiChu ?? this.ghiChu,
      );
}

enum LoaiHinhDatDon { TheoLan, GoiThang }

enum TrangThaiDon { ChoDuyet, DaXacNhan, DangThucHien, HoanThanh, DaHuy }

/// Model tương ứng bảng LichSuSuDungKhuyenMai
class LichSuSuDungKhuyenMai {
  final int? id;
  final int khuyenMaiId;
  final int khachHangId;
  final int donDatId;
  final DateTime ngaySuDung;
  final int soTienDuocGiam;

  const LichSuSuDungKhuyenMai({
    this.id,
    required this.khuyenMaiId,
    required this.khachHangId,
    required this.donDatId,
    required this.ngaySuDung,
    required this.soTienDuocGiam,
  });

  factory LichSuSuDungKhuyenMai.fromJson(Map<String, dynamic> json) =>
      LichSuSuDungKhuyenMai(
        id: json['id'] as int?,
        khuyenMaiId: json['khuyenMaiId'] as int,
        khachHangId: json['khachHangId'] as int,
        donDatId: json['donDatId'] as int,
        ngaySuDung: DateTime.parse(json['NgaySuDung'] as String),
        soTienDuocGiam: json['SoTienDuocGiam'] as int,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'khuyenMaiId': khuyenMaiId,
        'khachHangId': khachHangId,
        'donDatId': donDatId,
        'NgaySuDung': ngaySuDung.toIso8601String(),
        'SoTienDuocGiam': soTienDuocGiam,
      };

  LichSuSuDungKhuyenMai copyWith({
    int? id,
    int? khuyenMaiId,
    int? khachHangId,
    int? donDatId,
    DateTime? ngaySuDung,
    int? soTienDuocGiam,
  }) =>
      LichSuSuDungKhuyenMai(
        id: id ?? this.id,
        khuyenMaiId: khuyenMaiId ?? this.khuyenMaiId,
        khachHangId: khachHangId ?? this.khachHangId,
        donDatId: donDatId ?? this.donDatId,
        ngaySuDung: ngaySuDung ?? this.ngaySuDung,
        soTienDuocGiam: soTienDuocGiam ?? this.soTienDuocGiam,
      );
}

/// Model tương ứng bảng LichSuTrangThaiDon
class LichSuTrangThaiDon {
  final int? id;
  final int donDatId;
  final String? trangThaiCu;
  final String trangThaiMoi;
  final String? nguoiThucHien;
  final DateTime thoiGian;
  final String? ghiChu;

  const LichSuTrangThaiDon({
    this.id,
    required this.donDatId,
    this.trangThaiCu,
    required this.trangThaiMoi,
    this.nguoiThucHien,
    required this.thoiGian,
    this.ghiChu,
  });

  factory LichSuTrangThaiDon.fromJson(Map<String, dynamic> json) =>
      LichSuTrangThaiDon(
        id: json['id'] as int?,
        donDatId: json['donDatId'] as int,
        trangThaiCu: json['TrangThaiCu'] as String?,
        trangThaiMoi: json['TrangThaiMoi'] as String,
        nguoiThucHien: json['NguoiThucHien'] as String?,
        thoiGian: DateTime.parse(json['ThoiGian'] as String),
        ghiChu: json['GhiChu'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'donDatId': donDatId,
        'TrangThaiCu': trangThaiCu,
        'TrangThaiMoi': trangThaiMoi,
        'NguoiThucHien': nguoiThucHien,
        'ThoiGian': thoiGian.toIso8601String(),
        'GhiChu': ghiChu,
      };

  LichSuTrangThaiDon copyWith({
    int? id,
    int? donDatId,
    String? trangThaiCu,
    String? trangThaiMoi,
    String? nguoiThucHien,
    DateTime? thoiGian,
    String? ghiChu,
  }) =>
      LichSuTrangThaiDon(
        id: id ?? this.id,
        donDatId: donDatId ?? this.donDatId,
        trangThaiCu: trangThaiCu ?? this.trangThaiCu,
        trangThaiMoi: trangThaiMoi ?? this.trangThaiMoi,
        nguoiThucHien: nguoiThucHien ?? this.nguoiThucHien,
        thoiGian: thoiGian ?? this.thoiGian,
        ghiChu: ghiChu ?? this.ghiChu,
      );
}

/// Model tương ứng bảng PhanCongCTV
class PhanCongCTV {
  final int? id;
  final String maPhanCong;
  final int donDatId;
  final int congTacVienId;
  final TrangThaiPhanCong trangThai;
  final DateTime thoiGianPhanCong;
  final DateTime? thoiGianXacNhan;
  final String? lyDoTuChoi;

  const PhanCongCTV({
    this.id,
    required this.maPhanCong,
    required this.donDatId,
    required this.congTacVienId,
    this.trangThai = TrangThaiPhanCong.ChoPhanCong,
    required this.thoiGianPhanCong,
    this.thoiGianXacNhan,
    this.lyDoTuChoi,
  });

  factory PhanCongCTV.fromJson(Map<String, dynamic> json) => PhanCongCTV(
        id: json['id'] as int?,
        maPhanCong: json['MaPhanCong'] as String,
        donDatId: json['donDatId'] as int,
        congTacVienId: json['congTacVienId'] as int,
        trangThai: TrangThaiPhanCong.values.byName(json['TrangThai'] as String),
        thoiGianPhanCong: DateTime.parse(json['ThoiGianPhanCong'] as String),
        thoiGianXacNhan: json['ThoiGianXacNhan'] != null
            ? DateTime.parse(json['ThoiGianXacNhan'] as String)
            : null,
        lyDoTuChoi: json['LyDoTuChoi'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'MaPhanCong': maPhanCong,
        'donDatId': donDatId,
        'congTacVienId': congTacVienId,
        'TrangThai': trangThai.name,
        'ThoiGianPhanCong': thoiGianPhanCong.toIso8601String(),
        'ThoiGianXacNhan': thoiGianXacNhan?.toIso8601String(),
        'LyDoTuChoi': lyDoTuChoi,
      };

  PhanCongCTV copyWith({
    int? id,
    String? maPhanCong,
    int? donDatId,
    int? congTacVienId,
    TrangThaiPhanCong? trangThai,
    DateTime? thoiGianPhanCong,
    DateTime? thoiGianXacNhan,
    String? lyDoTuChoi,
  }) =>
      PhanCongCTV(
        id: id ?? this.id,
        maPhanCong: maPhanCong ?? this.maPhanCong,
        donDatId: donDatId ?? this.donDatId,
        congTacVienId: congTacVienId ?? this.congTacVienId,
        trangThai: trangThai ?? this.trangThai,
        thoiGianPhanCong: thoiGianPhanCong ?? this.thoiGianPhanCong,
        thoiGianXacNhan: thoiGianXacNhan ?? this.thoiGianXacNhan,
        lyDoTuChoi: lyDoTuChoi ?? this.lyDoTuChoi,
      );
}

enum TrangThaiPhanCong { ChoPhanCong, DaXacNhan, TuChoi, HoanThanh }
