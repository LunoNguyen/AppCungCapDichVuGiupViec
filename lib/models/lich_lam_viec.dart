// ignore_for_file: constant_identifier_names

/// Model tương ứng bảng LichLamViec
class LichLamViec {
  final int? id;
  final String maLichLamViec;
  final int phanCongId;
  final int congTacVienId;
  final DateTime ngayLam;
  final String gioBatDau;
  final String? gioKetThuc;
  final TrangThaiLich trangThai;
  final String? ketQuaThucHien;

  const LichLamViec({
    this.id,
    required this.maLichLamViec,
    required this.phanCongId,
    required this.congTacVienId,
    required this.ngayLam,
    required this.gioBatDau,
    this.gioKetThuc,
    this.trangThai = TrangThaiLich.SapToi,
    this.ketQuaThucHien,
  });

  factory LichLamViec.fromJson(Map<String, dynamic> json) => LichLamViec(
        id: json['id'] as int?,
        maLichLamViec: json['MaLichLamViec'] as String,
        phanCongId: json['phanCongId'] as int,
        congTacVienId: json['congTacVienId'] as int,
        ngayLam: DateTime.parse(json['NgayLam'] as String),
        gioBatDau: json['GioBatDau'] as String,
        gioKetThuc: json['GioKetThuc'] as String?,
        trangThai: TrangThaiLich.values.byName(json['TrangThai'] as String),
        ketQuaThucHien: json['KetQuaThucHien'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'MaLichLamViec': maLichLamViec,
        'phanCongId': phanCongId,
        'congTacVienId': congTacVienId,
        'NgayLam': ngayLam.toIso8601String().split('T')[0],
        'GioBatDau': gioBatDau,
        'GioKetThuc': gioKetThuc,
        'TrangThai': trangThai.name,
        'KetQuaThucHien': ketQuaThucHien,
      };

  LichLamViec copyWith({
    int? id,
    String? maLichLamViec,
    int? phanCongId,
    int? congTacVienId,
    DateTime? ngayLam,
    String? gioBatDau,
    String? gioKetThuc,
    TrangThaiLich? trangThai,
    String? ketQuaThucHien,
  }) =>
      LichLamViec(
        id: id ?? this.id,
        maLichLamViec: maLichLamViec ?? this.maLichLamViec,
        phanCongId: phanCongId ?? this.phanCongId,
        congTacVienId: congTacVienId ?? this.congTacVienId,
        ngayLam: ngayLam ?? this.ngayLam,
        gioBatDau: gioBatDau ?? this.gioBatDau,
        gioKetThuc: gioKetThuc ?? this.gioKetThuc,
        trangThai: trangThai ?? this.trangThai,
        ketQuaThucHien: ketQuaThucHien ?? this.ketQuaThucHien,
      );
}

enum TrangThaiLich { SapToi, DangThucHien, HoanThanh, Huy }
