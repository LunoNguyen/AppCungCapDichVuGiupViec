// ignore_for_file: constant_identifier_names

/// Model tương ứng bảng PhongBan
class PhongBan {
  final int? id;
  final String maPhongBan;
  final String tenPhongBan;
  final String? moTa;
  final TrangThaiPhongBan trangThai;

  const PhongBan({
    this.id,
    required this.maPhongBan,
    required this.tenPhongBan,
    this.moTa,
    this.trangThai = TrangThaiPhongBan.HoatDong,
  });

  factory PhongBan.fromJson(Map<String, dynamic> json) => PhongBan(
        id: json['id'] as int?,
        maPhongBan: json['MaPhongBan'] as String,
        tenPhongBan: json['TenPhongBan'] as String,
        moTa: json['MoTa'] as String?,
        trangThai: TrangThaiPhongBan.values.byName(json['TrangThai'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'MaPhongBan': maPhongBan,
        'TenPhongBan': tenPhongBan,
        'MoTa': moTa,
        'TrangThai': trangThai.name,
      };

  PhongBan copyWith({
    int? id,
    String? maPhongBan,
    String? tenPhongBan,
    String? moTa,
    TrangThaiPhongBan? trangThai,
  }) =>
      PhongBan(
        id: id ?? this.id,
        maPhongBan: maPhongBan ?? this.maPhongBan,
        tenPhongBan: tenPhongBan ?? this.tenPhongBan,
        moTa: moTa ?? this.moTa,
        trangThai: trangThai ?? this.trangThai,
      );
}

enum TrangThaiPhongBan { HoatDong, DaGiaiThe }

/// Model tương ứng bảng ChucVu
class ChucVu {
  final int? id;
  final String maChucVu;
  final int phongBanId;
  final String tenChucVu;
  final String? moTa;

  const ChucVu({
    this.id,
    required this.maChucVu,
    required this.phongBanId,
    required this.tenChucVu,
    this.moTa,
  });

  factory ChucVu.fromJson(Map<String, dynamic> json) => ChucVu(
        id: json['id'] as int?,
        maChucVu: json['MaChucVu'] as String,
        phongBanId: json['phongBanId'] as int,
        tenChucVu: json['TenChucVu'] as String,
        moTa: json['MoTa'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'MaChucVu': maChucVu,
        'phongBanId': phongBanId,
        'TenChucVu': tenChucVu,
        'MoTa': moTa,
      };

  ChucVu copyWith({
    int? id,
    String? maChucVu,
    int? phongBanId,
    String? tenChucVu,
    String? moTa,
  }) =>
      ChucVu(
        id: id ?? this.id,
        maChucVu: maChucVu ?? this.maChucVu,
        phongBanId: phongBanId ?? this.phongBanId,
        tenChucVu: tenChucVu ?? this.tenChucVu,
        moTa: moTa ?? this.moTa,
      );
}

/// Model tương ứng bảng NhanVien
class NhanVien {
  final int? id;
  final String maNhanVien;
  final int? taiKhoanId;
  final int chucVuId;
  final String hoTen;
  final DateTime? ngaySinh;
  final GioiTinh? gioiTinh;
  final String? diaChi;
  final String soDienThoai;
  final String? email;
  final DateTime ngayVaoLam;
  final TrangThaiNhanVien trangThai;

  const NhanVien({
    this.id,
    required this.maNhanVien,
    this.taiKhoanId,
    required this.chucVuId,
    required this.hoTen,
    this.ngaySinh,
    this.gioiTinh,
    this.diaChi,
    required this.soDienThoai,
    this.email,
    required this.ngayVaoLam,
    this.trangThai = TrangThaiNhanVien.DangLamViec,
  });

  factory NhanVien.fromJson(Map<String, dynamic> json) => NhanVien(
        id: json['id'] as int?,
        maNhanVien: json['MaNhanVien'] as String,
        taiKhoanId: json['taiKhoanId'] as int?,
        chucVuId: json['chucVuId'] as int,
        hoTen: json['HoTen'] as String,
        ngaySinh: json['NgaySinh'] != null
            ? DateTime.parse(json['NgaySinh'] as String)
            : null,
        gioiTinh: json['GioiTinh'] != null
            ? GioiTinh.values.byName(json['GioiTinh'] as String)
            : null,
        diaChi: json['DiaChi'] as String?,
        soDienThoai: json['SoDienThoai'] as String,
        email: json['Email'] as String?,
        ngayVaoLam: DateTime.parse(json['NgayVaoLam'] as String),
        trangThai: TrangThaiNhanVien.values.byName(json['TrangThai'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'MaNhanVien': maNhanVien,
        'taiKhoanId': taiKhoanId,
        'chucVuId': chucVuId,
        'HoTen': hoTen,
        'NgaySinh': ngaySinh?.toIso8601String().split('T')[0],
        'GioiTinh': gioiTinh?.name,
        'DiaChi': diaChi,
        'SoDienThoai': soDienThoai,
        'Email': email,
        'NgayVaoLam': ngayVaoLam.toIso8601String().split('T')[0],
        'TrangThai': trangThai.name,
      };

  NhanVien copyWith({
    int? id,
    String? maNhanVien,
    int? taiKhoanId,
    int? chucVuId,
    String? hoTen,
    DateTime? ngaySinh,
    GioiTinh? gioiTinh,
    String? diaChi,
    String? soDienThoai,
    String? email,
    DateTime? ngayVaoLam,
    TrangThaiNhanVien? trangThai,
  }) =>
      NhanVien(
        id: id ?? this.id,
        maNhanVien: maNhanVien ?? this.maNhanVien,
        taiKhoanId: taiKhoanId ?? this.taiKhoanId,
        chucVuId: chucVuId ?? this.chucVuId,
        hoTen: hoTen ?? this.hoTen,
        ngaySinh: ngaySinh ?? this.ngaySinh,
        gioiTinh: gioiTinh ?? this.gioiTinh,
        diaChi: diaChi ?? this.diaChi,
        soDienThoai: soDienThoai ?? this.soDienThoai,
        email: email ?? this.email,
        ngayVaoLam: ngayVaoLam ?? this.ngayVaoLam,
        trangThai: trangThai ?? this.trangThai,
      );
}

enum TrangThaiNhanVien { DangLamViec, DaNghi, TamNghi }

/// Enum dùng chung cho GioiTinh
enum GioiTinh { Nam, Nu, Khac }
