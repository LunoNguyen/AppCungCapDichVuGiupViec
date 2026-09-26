// ignore_for_file: constant_identifier_names

/// Model tương ứng bảng TaiKhoan
class TaiKhoan {
  final int? id;
  final String maTaiKhoan;
  final String tenDangNhap;
  final String matKhau;
  final String email;
  final String soDienThoai;
  final LoaiTaiKhoan loaiTaiKhoan;
  final TrangThaiTaiKhoan trangThai;
  final DateTime ngayTao;
  final DateTime? ngayCapNhat;

  const TaiKhoan({
    this.id,
    required this.maTaiKhoan,
    required this.tenDangNhap,
    required this.matKhau,
    required this.email,
    required this.soDienThoai,
    required this.loaiTaiKhoan,
    this.trangThai = TrangThaiTaiKhoan.HoatDong,
    required this.ngayTao,
    this.ngayCapNhat,
  });

  factory TaiKhoan.fromJson(Map<String, dynamic> json) => TaiKhoan(
        id: json['id'] as int?,
        maTaiKhoan: json['MaTaiKhoan'] as String,
        tenDangNhap: json['TenDangNhap'] as String,
        matKhau: json['MatKhau'] as String,
        email: json['Email'] as String,
        soDienThoai: json['SoDienThoai'] as String,
        loaiTaiKhoan: LoaiTaiKhoan.values.byName(json['LoaiTaiKhoan'] as String),
        trangThai: TrangThaiTaiKhoan.values.byName(json['TrangThai'] as String),
        ngayTao: DateTime.parse(json['NgayTao'] as String),
        ngayCapNhat: json['NgayCapNhat'] != null
            ? DateTime.parse(json['NgayCapNhat'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'MaTaiKhoan': maTaiKhoan,
        'TenDangNhap': tenDangNhap,
        'MatKhau': matKhau,
        'Email': email,
        'SoDienThoai': soDienThoai,
        'LoaiTaiKhoan': loaiTaiKhoan.name,
        'TrangThai': trangThai.name,
        'NgayTao': ngayTao.toIso8601String(),
        'NgayCapNhat': ngayCapNhat?.toIso8601String(),
      };

  TaiKhoan copyWith({
    int? id,
    String? maTaiKhoan,
    String? tenDangNhap,
    String? matKhau,
    String? email,
    String? soDienThoai,
    LoaiTaiKhoan? loaiTaiKhoan,
    TrangThaiTaiKhoan? trangThai,
    DateTime? ngayTao,
    DateTime? ngayCapNhat,
  }) =>
      TaiKhoan(
        id: id ?? this.id,
        maTaiKhoan: maTaiKhoan ?? this.maTaiKhoan,
        tenDangNhap: tenDangNhap ?? this.tenDangNhap,
        matKhau: matKhau ?? this.matKhau,
        email: email ?? this.email,
        soDienThoai: soDienThoai ?? this.soDienThoai,
        loaiTaiKhoan: loaiTaiKhoan ?? this.loaiTaiKhoan,
        trangThai: trangThai ?? this.trangThai,
        ngayTao: ngayTao ?? this.ngayTao,
        ngayCapNhat: ngayCapNhat ?? this.ngayCapNhat,
      );
}

enum LoaiTaiKhoan { KhachHang, CongTacVien, NhanVien }

enum TrangThaiTaiKhoan { HoatDong, BiKhoa, ChoDuyet }
