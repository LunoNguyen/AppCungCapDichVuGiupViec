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
  final double soDuVi; // Số dư ví thu nhập
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
    this.soDuVi = 0.0,
    this.capDo = CapDoCTV.Moi,
    required this.trangThai,
    required this.ngayDangKy,
  });

  factory CongTacVien.fromJson(Map<String, dynamic> json) {
    // Xử lý lấy taiKhoanId từ object lồng nhau nếu có
    int? tId = json['taiKhoanId'] as int?;
    if (tId == null && json['taiKhoan'] != null) {
      tId = json['taiKhoan']['id'] as int?;
    }

    return CongTacVien(
      id: json['id'] as int?,
      maCongTacVien: json['maCongTacVien'] ?? '',
      taiKhoanId: tId,
      hoTen: json['hoTen'] ?? '',
      ngaySinh: json['ngaySinh'] != null
          ? DateTime.parse(json['ngaySinh'] as String)
          : null,
      gioiTinh: (json['gioiTinh'] != null)
          ? _parseGioiTinh(json['gioiTinh'])
          : null,
      noiCuTru: json['noiCuTru'] ?? '',
      soDienThoai: json['soDienThoai'] ?? '',
      diemDanhGia: (json['diemDanhGia'] as num?)?.toDouble() ?? 0.0,
      soDuVi: (json['soDuVi'] as num?)?.toDouble() ?? 0.0,
      capDo: _parseCapDo(json['capDo']),
      trangThai: _parseTrangThai(json['trangThai']),
      ngayDangKy: json['ngayDangKy'] != null 
          ? DateTime.parse(json['ngayDangKy'] as String)
          : DateTime.now(),
    );
  }

  static GioiTinhCTV _parseGioiTinh(dynamic value) {
    try {
      return GioiTinhCTV.values.byName(value.toString());
    } catch (_) {
      return GioiTinhCTV.Khac;
    }
  }

  static CapDoCTV _parseCapDo(dynamic value) {
    try {
      return CapDoCTV.values.byName(value.toString());
    } catch (_) {
      return CapDoCTV.Moi;
    }
  }

  static TrangThaiCTV _parseTrangThai(dynamic value) {
    try {
      return TrangThaiCTV.values.byName(value.toString());
    } catch (_) {
      if (value.toString() == 'TamDung') return TrangThaiCTV.TamDung;
      return TrangThaiCTV.ChoDuyet;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'maCongTacVien': maCongTacVien,
        'taiKhoanId': taiKhoanId,
        'hoTen': hoTen,
        'ngaySinh': ngaySinh?.toIso8601String().split('T')[0],
        'gioiTinh': gioiTinh?.name,
        'noiCuTru': noiCuTru,
        'soDienThoai': soDienThoai,
        'diemDanhGia': diemDanhGia,
        'soDuVi': soDuVi,
        'capDo': capDo.name,
        'trangThai': trangThai.name,
        'ngayDangKy': ngayDangKy.toIso8601String().split('T')[0],
      };
}

enum CapDoCTV { Moi, Thuong, UuTu }

enum TrangThaiCTV { ChoDuyet, HoatDong, DinhChi, TuChoi, TamDung }

enum GioiTinhCTV { Nam, Nu, Khac }
