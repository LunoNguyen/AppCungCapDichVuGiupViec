// ignore_for_file: constant_identifier_names

/// Model tương ứng bảng KhachHang
class KhachHang {
  final int? id;
  final String maKhachHang;
  final int? taiKhoanId;
  final String hoTen;
  final DateTime? ngaySinh;
  final String? gioiTinh;
  final String soDienThoai;
  final String? email;
  final DateTime ngayDangKy;
  final TrangThaiKhachHang trangThai;

  const KhachHang({
    this.id,
    required this.maKhachHang,
    this.taiKhoanId,
    required this.hoTen,
    this.ngaySinh,
    this.gioiTinh,
    required this.soDienThoai,
    this.email,
    required this.ngayDangKy,
    this.trangThai = TrangThaiKhachHang.HoatDong,
  });

  factory KhachHang.fromJson(Map<String, dynamic> json) => KhachHang(
        id: json['id'] as int?,
        maKhachHang: json['MaKhachHang'] as String,
        taiKhoanId: json['taiKhoanId'] as int?,
        hoTen: json['HoTen'] as String,
        ngaySinh: json['NgaySinh'] != null
            ? DateTime.parse(json['NgaySinh'] as String)
            : null,
        gioiTinh: json['GioiTinh'] as String?,
        soDienThoai: json['SoDienThoai'] as String,
        email: json['Email'] as String?,
        ngayDangKy: DateTime.parse(json['NgayDangKy'] as String),
        trangThai: TrangThaiKhachHang.values.byName(json['TrangThai'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'MaKhachHang': maKhachHang,
        'taiKhoanId': taiKhoanId,
        'HoTen': hoTen,
        'NgaySinh': ngaySinh?.toIso8601String().split('T')[0],
        'GioiTinh': gioiTinh,
        'SoDienThoai': soDienThoai,
        'Email': email,
        'NgayDangKy': ngayDangKy.toIso8601String().split('T')[0],
        'TrangThai': trangThai.name,
      };

  KhachHang copyWith({
    int? id,
    String? maKhachHang,
    int? taiKhoanId,
    String? hoTen,
    DateTime? ngaySinh,
    String? gioiTinh,
    String? soDienThoai,
    String? email,
    DateTime? ngayDangKy,
    TrangThaiKhachHang? trangThai,
  }) =>
      KhachHang(
        id: id ?? this.id,
        maKhachHang: maKhachHang ?? this.maKhachHang,
        taiKhoanId: taiKhoanId ?? this.taiKhoanId,
        hoTen: hoTen ?? this.hoTen,
        ngaySinh: ngaySinh ?? this.ngaySinh,
        gioiTinh: gioiTinh ?? this.gioiTinh,
        soDienThoai: soDienThoai ?? this.soDienThoai,
        email: email ?? this.email,
        ngayDangKy: ngayDangKy ?? this.ngayDangKy,
        trangThai: trangThai ?? this.trangThai,
      );
}

enum TrangThaiKhachHang { HoatDong, BiKhoa }
