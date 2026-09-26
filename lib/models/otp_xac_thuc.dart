// ignore_for_file: constant_identifier_names

/// Model tương ứng bảng OTPXacThuc
class OTPXacThuc {
  final int? id;
  final int taiKhoanId;
  final MucDichOTP mucDich;
  final String maCode;
  final DateTime thoiGianTao;
  final DateTime thoiGianHetHan;
  final bool daSuDung;

  const OTPXacThuc({
    this.id,
    required this.taiKhoanId,
    required this.mucDich,
    required this.maCode,
    required this.thoiGianTao,
    required this.thoiGianHetHan,
    this.daSuDung = false,
  });

  factory OTPXacThuc.fromJson(Map<String, dynamic> json) => OTPXacThuc(
        id: json['id'] as int?,
        taiKhoanId: json['taiKhoanId'] as int,
        mucDich: MucDichOTP.values.byName(json['MucDich'] as String),
        maCode: json['MaCode'] as String,
        thoiGianTao: DateTime.parse(json['ThoiGianTao'] as String),
        thoiGianHetHan: DateTime.parse(json['ThoiGianHetHan'] as String),
        daSuDung: (json['DaSuDung'] as int) == 1,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'taiKhoanId': taiKhoanId,
        'MucDich': mucDich.name,
        'MaCode': maCode,
        'ThoiGianTao': thoiGianTao.toIso8601String(),
        'ThoiGianHetHan': thoiGianHetHan.toIso8601String(),
        'DaSuDung': daSuDung ? 1 : 0,
      };

  OTPXacThuc copyWith({
    int? id,
    int? taiKhoanId,
    MucDichOTP? mucDich,
    String? maCode,
    DateTime? thoiGianTao,
    DateTime? thoiGianHetHan,
    bool? daSuDung,
  }) =>
      OTPXacThuc(
        id: id ?? this.id,
        taiKhoanId: taiKhoanId ?? this.taiKhoanId,
        mucDich: mucDich ?? this.mucDich,
        maCode: maCode ?? this.maCode,
        thoiGianTao: thoiGianTao ?? this.thoiGianTao,
        thoiGianHetHan: thoiGianHetHan ?? this.thoiGianHetHan,
        daSuDung: daSuDung ?? this.daSuDung,
      );
}

enum MucDichOTP { DangKy, DatLaiMatKhau, XacNhanGD }
