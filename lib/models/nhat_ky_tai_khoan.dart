// ignore_for_file: constant_identifier_names

/// Model tương ứng bảng NhatKyTaiKhoan
class NhatKyTaiKhoan {
  final int? id;
  final int taiKhoanId;
  final String hanhDong;
  final String? diaChiIP;
  final String? thietBi;
  final DateTime thoiGian;
  final KetQuaNhatKy ketQua;

  const NhatKyTaiKhoan({
    this.id,
    required this.taiKhoanId,
    required this.hanhDong,
    this.diaChiIP,
    this.thietBi,
    required this.thoiGian,
    required this.ketQua,
  });

  factory NhatKyTaiKhoan.fromJson(Map<String, dynamic> json) => NhatKyTaiKhoan(
        id: json['id'] as int?,
        taiKhoanId: json['taiKhoanId'] as int,
        hanhDong: json['HanhDong'] as String,
        diaChiIP: json['DiaChiIP'] as String?,
        thietBi: json['ThietBi'] as String?,
        thoiGian: DateTime.parse(json['ThoiGian'] as String),
        ketQua: KetQuaNhatKy.values.byName(json['KetQua'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'taiKhoanId': taiKhoanId,
        'HanhDong': hanhDong,
        'DiaChiIP': diaChiIP,
        'ThietBi': thietBi,
        'ThoiGian': thoiGian.toIso8601String(),
        'KetQua': ketQua.name,
      };

  NhatKyTaiKhoan copyWith({
    int? id,
    int? taiKhoanId,
    String? hanhDong,
    String? diaChiIP,
    String? thietBi,
    DateTime? thoiGian,
    KetQuaNhatKy? ketQua,
  }) =>
      NhatKyTaiKhoan(
        id: id ?? this.id,
        taiKhoanId: taiKhoanId ?? this.taiKhoanId,
        hanhDong: hanhDong ?? this.hanhDong,
        diaChiIP: diaChiIP ?? this.diaChiIP,
        thietBi: thietBi ?? this.thietBi,
        thoiGian: thoiGian ?? this.thoiGian,
        ketQua: ketQua ?? this.ketQua,
      );
}

enum KetQuaNhatKy { ThanhCong, ThatBai }
