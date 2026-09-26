// ignore_for_file: constant_identifier_names

/// Model tương ứng bảng LoaiDichVu
class LoaiDichVu {
  final int? id;
  final String maLoaiDichVu;
  final String tenLoaiDichVu;
  final String? moTa;
  final String? hinhAnh;
  final int thuTuHienThi;
  final TrangThaiLoaiDV trangThai;

  const LoaiDichVu({
    this.id,
    required this.maLoaiDichVu,
    required this.tenLoaiDichVu,
    this.moTa,
    this.hinhAnh,
    this.thuTuHienThi = 0,
    this.trangThai = TrangThaiLoaiDV.HienThi,
  });

  factory LoaiDichVu.fromJson(Map<String, dynamic> json) => LoaiDichVu(
        id: json['id'] as int?,
        maLoaiDichVu: json['MaLoaiDichVu'] as String,
        tenLoaiDichVu: json['TenLoaiDichVu'] as String,
        moTa: json['MoTa'] as String?,
        hinhAnh: json['HinhAnh'] as String?,
        thuTuHienThi: json['ThuTuHienThi'] as int? ?? 0,
        trangThai: TrangThaiLoaiDV.values.byName(json['TrangThai'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'MaLoaiDichVu': maLoaiDichVu,
        'TenLoaiDichVu': tenLoaiDichVu,
        'MoTa': moTa,
        'HinhAnh': hinhAnh,
        'ThuTuHienThi': thuTuHienThi,
        'TrangThai': trangThai.name,
      };

  LoaiDichVu copyWith({
    int? id,
    String? maLoaiDichVu,
    String? tenLoaiDichVu,
    String? moTa,
    String? hinhAnh,
    int? thuTuHienThi,
    TrangThaiLoaiDV? trangThai,
  }) =>
      LoaiDichVu(
        id: id ?? this.id,
        maLoaiDichVu: maLoaiDichVu ?? this.maLoaiDichVu,
        tenLoaiDichVu: tenLoaiDichVu ?? this.tenLoaiDichVu,
        moTa: moTa ?? this.moTa,
        hinhAnh: hinhAnh ?? this.hinhAnh,
        thuTuHienThi: thuTuHienThi ?? this.thuTuHienThi,
        trangThai: trangThai ?? this.trangThai,
      );
}

enum TrangThaiLoaiDV { HienThi, An }

/// Model tương ứng bảng DichVu
class DichVu {
  final int? id;
  final String maDichVu;
  final int loaiDichVuId;
  final String tenDichVu;
  final String? moTaChiTiet;
  /// Thời gian thực hiện tính bằng phút. null = không cố định
  final int? thoiGianThucHien;
  final LoaiHinhDat loaiHinhDat;
  final String donViTinh;
  final TrangThaiDichVu trangThai;

  const DichVu({
    this.id,
    required this.maDichVu,
    required this.loaiDichVuId,
    required this.tenDichVu,
    this.moTaChiTiet,
    this.thoiGianThucHien,
    this.loaiHinhDat = LoaiHinhDat.TheoLan,
    required this.donViTinh,
    this.trangThai = TrangThaiDichVu.HoatDong,
  });

  factory DichVu.fromJson(Map<String, dynamic> json) => DichVu(
        id: json['id'] as int?,
        maDichVu: json['MaDichVu'] as String,
        loaiDichVuId: json['loaiDichVuId'] as int,
        tenDichVu: json['TenDichVu'] as String,
        moTaChiTiet: json['MoTaChiTiet'] as String?,
        thoiGianThucHien: json['ThoiGianThucHien'] as int?,
        loaiHinhDat: LoaiHinhDat.values.byName(json['LoaiHinhDat'] as String),
        donViTinh: json['DonViTinh'] as String,
        trangThai: TrangThaiDichVu.values.byName(json['TrangThai'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'MaDichVu': maDichVu,
        'loaiDichVuId': loaiDichVuId,
        'TenDichVu': tenDichVu,
        'MoTaChiTiet': moTaChiTiet,
        'ThoiGianThucHien': thoiGianThucHien,
        'LoaiHinhDat': loaiHinhDat.name,
        'DonViTinh': donViTinh,
        'TrangThai': trangThai.name,
      };

  DichVu copyWith({
    int? id,
    String? maDichVu,
    int? loaiDichVuId,
    String? tenDichVu,
    String? moTaChiTiet,
    int? thoiGianThucHien,
    LoaiHinhDat? loaiHinhDat,
    String? donViTinh,
    TrangThaiDichVu? trangThai,
  }) =>
      DichVu(
        id: id ?? this.id,
        maDichVu: maDichVu ?? this.maDichVu,
        loaiDichVuId: loaiDichVuId ?? this.loaiDichVuId,
        tenDichVu: tenDichVu ?? this.tenDichVu,
        moTaChiTiet: moTaChiTiet ?? this.moTaChiTiet,
        thoiGianThucHien: thoiGianThucHien ?? this.thoiGianThucHien,
        loaiHinhDat: loaiHinhDat ?? this.loaiHinhDat,
        donViTinh: donViTinh ?? this.donViTinh,
        trangThai: trangThai ?? this.trangThai,
      );
}

enum LoaiHinhDat { TheoLan, GoiThang }
enum TrangThaiDichVu { HoatDong, An }

/// Model tương ứng bảng DichVuCTV
class DichVuCTV {
  final int? id;
  final String maDichVuCTV;
  final int congTacVienId;
  final int dichVuId;
  final TrangThaiDichVuCTV trangThai;
  final DateTime? ngayBatDau;

  const DichVuCTV({
    this.id,
    required this.maDichVuCTV,
    required this.congTacVienId,
    required this.dichVuId,
    this.trangThai = TrangThaiDichVuCTV.HoatDong,
    this.ngayBatDau,
  });

  factory DichVuCTV.fromJson(Map<String, dynamic> json) => DichVuCTV(
        id: json['id'] as int?,
        maDichVuCTV: json['MaDichVuCTV'] as String,
        congTacVienId: json['congTacVienId'] as int,
        dichVuId: json['dichVuId'] as int,
        trangThai: TrangThaiDichVuCTV.values.byName(json['TrangThai'] as String),
        ngayBatDau: json['NgayBatDau'] != null
            ? DateTime.parse(json['NgayBatDau'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'MaDichVuCTV': maDichVuCTV,
        'congTacVienId': congTacVienId,
        'dichVuId': dichVuId,
        'TrangThai': trangThai.name,
        'NgayBatDau': ngayBatDau?.toIso8601String().split('T')[0],
      };

  DichVuCTV copyWith({
    int? id,
    String? maDichVuCTV,
    int? congTacVienId,
    int? dichVuId,
    TrangThaiDichVuCTV? trangThai,
    DateTime? ngayBatDau,
  }) =>
      DichVuCTV(
        id: id ?? this.id,
        maDichVuCTV: maDichVuCTV ?? this.maDichVuCTV,
        congTacVienId: congTacVienId ?? this.congTacVienId,
        dichVuId: dichVuId ?? this.dichVuId,
        trangThai: trangThai ?? this.trangThai,
        ngayBatDau: ngayBatDau ?? this.ngayBatDau,
      );
}

enum TrangThaiDichVuCTV { HoatDong, TamNgung }

/// Model tương ứng bảng BangGiaDichVu
class BangGiaDichVu {
  final int? id;
  final String maBangGia;
  final int dichVuId;
  final int? khuVucId;
  final LoaiHinhDat loaiHinhDat;
  final String donViTinh;
  final int donGia;
  final DateTime ngayApDung;
  final DateTime? ngayKetThuc;
  final TrangThaiBangGia trangThai;

  const BangGiaDichVu({
    this.id,
    required this.maBangGia,
    required this.dichVuId,
    this.khuVucId,
    required this.loaiHinhDat,
    required this.donViTinh,
    required this.donGia,
    required this.ngayApDung,
    this.ngayKetThuc,
    this.trangThai = TrangThaiBangGia.DangApDung,
  });

  factory BangGiaDichVu.fromJson(Map<String, dynamic> json) => BangGiaDichVu(
        id: json['id'] as int?,
        maBangGia: json['MaBangGia'] as String,
        dichVuId: json['dichVuId'] as int,
        khuVucId: json['khuVucId'] as int?,
        loaiHinhDat: LoaiHinhDat.values.byName(json['LoaiHinhDat'] as String),
        donViTinh: json['DonViTinh'] as String,
        donGia: json['DonGia'] as int,
        ngayApDung: DateTime.parse(json['NgayApDung'] as String),
        ngayKetThuc: json['NgayKetThuc'] != null
            ? DateTime.parse(json['NgayKetThuc'] as String)
            : null,
        trangThai: TrangThaiBangGia.values.byName(json['TrangThai'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'MaBangGia': maBangGia,
        'dichVuId': dichVuId,
        'khuVucId': khuVucId,
        'LoaiHinhDat': loaiHinhDat.name,
        'DonViTinh': donViTinh,
        'DonGia': donGia,
        'NgayApDung': ngayApDung.toIso8601String().split('T')[0],
        'NgayKetThuc': ngayKetThuc?.toIso8601String().split('T')[0],
        'TrangThai': trangThai.name,
      };

  BangGiaDichVu copyWith({
    int? id,
    String? maBangGia,
    int? dichVuId,
    int? khuVucId,
    LoaiHinhDat? loaiHinhDat,
    String? donViTinh,
    int? donGia,
    DateTime? ngayApDung,
    DateTime? ngayKetThuc,
    TrangThaiBangGia? trangThai,
  }) =>
      BangGiaDichVu(
        id: id ?? this.id,
        maBangGia: maBangGia ?? this.maBangGia,
        dichVuId: dichVuId ?? this.dichVuId,
        khuVucId: khuVucId ?? this.khuVucId,
        loaiHinhDat: loaiHinhDat ?? this.loaiHinhDat,
        donViTinh: donViTinh ?? this.donViTinh,
        donGia: donGia ?? this.donGia,
        ngayApDung: ngayApDung ?? this.ngayApDung,
        ngayKetThuc: ngayKetThuc ?? this.ngayKetThuc,
        trangThai: trangThai ?? this.trangThai,
      );
}

enum TrangThaiBangGia { DangApDung, HetHan }

/// Model tương ứng bảng GoiDichVu
class GoiDichVu {
  final int? id;
  final String maGoi;
  final int dichVuId;
  final String tenGoi;
  final int soBuoi;
  final String tanSuat;
  final int giaGoi;
  final String? moTa;
  final TrangThaiGoiDV trangThai;

  const GoiDichVu({
    this.id,
    required this.maGoi,
    required this.dichVuId,
    required this.tenGoi,
    required this.soBuoi,
    required this.tanSuat,
    required this.giaGoi,
    this.moTa,
    this.trangThai = TrangThaiGoiDV.HoatDong,
  });

  factory GoiDichVu.fromJson(Map<String, dynamic> json) => GoiDichVu(
        id: json['id'] as int?,
        maGoi: json['MaGoi'] as String,
        dichVuId: json['dichVuId'] as int,
        tenGoi: json['TenGoi'] as String,
        soBuoi: json['SoBuoi'] as int,
        tanSuat: json['TanSuat'] as String,
        giaGoi: json['GiaGoi'] as int,
        moTa: json['MoTa'] as String?,
        trangThai: TrangThaiGoiDV.values.byName(json['TrangThai'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'MaGoi': maGoi,
        'dichVuId': dichVuId,
        'TenGoi': tenGoi,
        'SoBuoi': soBuoi,
        'TanSuat': tanSuat,
        'GiaGoi': giaGoi,
        'MoTa': moTa,
        'TrangThai': trangThai.name,
      };

  GoiDichVu copyWith({
    int? id,
    String? maGoi,
    int? dichVuId,
    String? tenGoi,
    int? soBuoi,
    String? tanSuat,
    int? giaGoi,
    String? moTa,
    TrangThaiGoiDV? trangThai,
  }) =>
      GoiDichVu(
        id: id ?? this.id,
        maGoi: maGoi ?? this.maGoi,
        dichVuId: dichVuId ?? this.dichVuId,
        tenGoi: tenGoi ?? this.tenGoi,
        soBuoi: soBuoi ?? this.soBuoi,
        tanSuat: tanSuat ?? this.tanSuat,
        giaGoi: giaGoi ?? this.giaGoi,
        moTa: moTa ?? this.moTa,
        trangThai: trangThai ?? this.trangThai,
      );
}

enum TrangThaiGoiDV { HoatDong, An }
