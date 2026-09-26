// ignore_for_file: constant_identifier_names

/// Model tương ứng bảng KhuVuc
class KhuVuc {
  final int? id;
  final String maKhuVuc;
  final String tenKhuVuc;
  final String quanHuyen;
  final String tinhThanh;
  final TrangThaiKhuVuc trangThai;

  const KhuVuc({
    this.id,
    required this.maKhuVuc,
    required this.tenKhuVuc,
    required this.quanHuyen,
    required this.tinhThanh,
    this.trangThai = TrangThaiKhuVuc.HoatDong,
  });

  factory KhuVuc.fromJson(Map<String, dynamic> json) => KhuVuc(
        id: json['id'] as int?,
        maKhuVuc: json['MaKhuVuc'] as String,
        tenKhuVuc: json['TenKhuVuc'] as String,
        quanHuyen: json['QuanHuyen'] as String,
        tinhThanh: json['TinhThanh'] as String,
        trangThai: TrangThaiKhuVuc.values.byName(json['TrangThai'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'MaKhuVuc': maKhuVuc,
        'TenKhuVuc': tenKhuVuc,
        'QuanHuyen': quanHuyen,
        'TinhThanh': tinhThanh,
        'TrangThai': trangThai.name,
      };

  KhuVuc copyWith({
    int? id,
    String? maKhuVuc,
    String? tenKhuVuc,
    String? quanHuyen,
    String? tinhThanh,
    TrangThaiKhuVuc? trangThai,
  }) =>
      KhuVuc(
        id: id ?? this.id,
        maKhuVuc: maKhuVuc ?? this.maKhuVuc,
        tenKhuVuc: tenKhuVuc ?? this.tenKhuVuc,
        quanHuyen: quanHuyen ?? this.quanHuyen,
        tinhThanh: tinhThanh ?? this.tinhThanh,
        trangThai: trangThai ?? this.trangThai,
      );
}

enum TrangThaiKhuVuc { HoatDong, TamNgung }

/// Model tương ứng bảng KhuVucCTV
class KhuVucCTV {
  final int? id;
  final String maKhuVucCTV;
  final int congTacVienId;
  final int khuVucId;
  final TrangThaiKhuVucCTV trangThai;

  const KhuVucCTV({
    this.id,
    required this.maKhuVucCTV,
    required this.congTacVienId,
    required this.khuVucId,
    this.trangThai = TrangThaiKhuVucCTV.HoatDong,
  });

  factory KhuVucCTV.fromJson(Map<String, dynamic> json) => KhuVucCTV(
        id: json['id'] as int?,
        maKhuVucCTV: json['MaKhuVucCTV'] as String,
        congTacVienId: json['congTacVienId'] as int,
        khuVucId: json['khuVucId'] as int,
        trangThai: TrangThaiKhuVucCTV.values.byName(json['TrangThai'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'MaKhuVucCTV': maKhuVucCTV,
        'congTacVienId': congTacVienId,
        'khuVucId': khuVucId,
        'TrangThai': trangThai.name,
      };

  KhuVucCTV copyWith({
    int? id,
    String? maKhuVucCTV,
    int? congTacVienId,
    int? khuVucId,
    TrangThaiKhuVucCTV? trangThai,
  }) =>
      KhuVucCTV(
        id: id ?? this.id,
        maKhuVucCTV: maKhuVucCTV ?? this.maKhuVucCTV,
        congTacVienId: congTacVienId ?? this.congTacVienId,
        khuVucId: khuVucId ?? this.khuVucId,
        trangThai: trangThai ?? this.trangThai,
      );
}

enum TrangThaiKhuVucCTV { HoatDong, TamNgung }

/// Model tương ứng bảng DiaChiKhachHang
class DiaChiKhachHang {
  final int? id;
  final String maDiaChi;
  final int khachHangId;
  final int? khuVucId;
  final String diaChiChiTiet;
  final double? dienTichNha;
  final String? luuYDacBiet;
  final bool laMacDinh;
  final TrangThaiDiaChi trangThai;

  const DiaChiKhachHang({
    this.id,
    required this.maDiaChi,
    required this.khachHangId,
    this.khuVucId,
    required this.diaChiChiTiet,
    this.dienTichNha,
    this.luuYDacBiet,
    this.laMacDinh = false,
    this.trangThai = TrangThaiDiaChi.HoatDong,
  });

  factory DiaChiKhachHang.fromJson(Map<String, dynamic> json) => DiaChiKhachHang(
        id: json['id'] as int?,
        maDiaChi: json['MaDiaChi'] as String,
        khachHangId: json['khachHangId'] as int,
        khuVucId: json['khuVucId'] as int?,
        diaChiChiTiet: json['DiaChiChiTiet'] as String,
        dienTichNha: json['DienTichNha'] != null
            ? (json['DienTichNha'] as num).toDouble()
            : null,
        luuYDacBiet: json['LuuYDacBiet'] as String?,
        laMacDinh: (json['LaMacDinh'] as int) == 1,
        trangThai: TrangThaiDiaChi.values.byName(json['TrangThai'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'MaDiaChi': maDiaChi,
        'khachHangId': khachHangId,
        'khuVucId': khuVucId,
        'DiaChiChiTiet': diaChiChiTiet,
        'DienTichNha': dienTichNha,
        'LuuYDacBiet': luuYDacBiet,
        'LaMacDinh': laMacDinh ? 1 : 0,
        'TrangThai': trangThai.name,
      };

  DiaChiKhachHang copyWith({
    int? id,
    String? maDiaChi,
    int? khachHangId,
    int? khuVucId,
    String? diaChiChiTiet,
    double? dienTichNha,
    String? luuYDacBiet,
    bool? laMacDinh,
    TrangThaiDiaChi? trangThai,
  }) =>
      DiaChiKhachHang(
        id: id ?? this.id,
        maDiaChi: maDiaChi ?? this.maDiaChi,
        khachHangId: khachHangId ?? this.khachHangId,
        khuVucId: khuVucId ?? this.khuVucId,
        diaChiChiTiet: diaChiChiTiet ?? this.diaChiChiTiet,
        dienTichNha: dienTichNha ?? this.dienTichNha,
        luuYDacBiet: luuYDacBiet ?? this.luuYDacBiet,
        laMacDinh: laMacDinh ?? this.laMacDinh,
        trangThai: trangThai ?? this.trangThai,
      );
}

enum TrangThaiDiaChi { HoatDong, DaXoa }
