// ignore_for_file: constant_identifier_names

/// Model tương ứng bảng ThongBao
class ThongBao {
  final int? id;
  final String maThongBao;
  final String tieuDe;
  final String noiDung;
  final String nguoiGui;
  final NhomNhan nhomNhan;
  final DateTime thoiGianGui;
  final TrangThaiThongBao trangThai;

  const ThongBao({
    this.id,
    required this.maThongBao,
    required this.tieuDe,
    required this.noiDung,
    required this.nguoiGui,
    required this.nhomNhan,
    required this.thoiGianGui,
    this.trangThai = TrangThaiThongBao.Nhap,
  });

  factory ThongBao.fromJson(Map<String, dynamic> json) => ThongBao(
        id: json['id'] as int?,
        maThongBao: json['MaThongBao'] as String,
        tieuDe: json['TieuDe'] as String,
        noiDung: json['NoiDung'] as String,
        nguoiGui: json['NguoiGui'] as String,
        nhomNhan: NhomNhan.values.byName(json['NhomNhan'] as String),
        thoiGianGui: DateTime.parse(json['ThoiGianGui'] as String),
        trangThai: TrangThaiThongBao.values.byName(json['TrangThai'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'MaThongBao': maThongBao,
        'TieuDe': tieuDe,
        'NoiDung': noiDung,
        'NguoiGui': nguoiGui,
        'NhomNhan': nhomNhan.name,
        'ThoiGianGui': thoiGianGui.toIso8601String(),
        'TrangThai': trangThai.name,
      };

  ThongBao copyWith({
    int? id,
    String? maThongBao,
    String? tieuDe,
    String? noiDung,
    String? nguoiGui,
    NhomNhan? nhomNhan,
    DateTime? thoiGianGui,
    TrangThaiThongBao? trangThai,
  }) =>
      ThongBao(
        id: id ?? this.id,
        maThongBao: maThongBao ?? this.maThongBao,
        tieuDe: tieuDe ?? this.tieuDe,
        noiDung: noiDung ?? this.noiDung,
        nguoiGui: nguoiGui ?? this.nguoiGui,
        nhomNhan: nhomNhan ?? this.nhomNhan,
        thoiGianGui: thoiGianGui ?? this.thoiGianGui,
        trangThai: trangThai ?? this.trangThai,
      );
}

enum NhomNhan { TatCa, KhachHang, CongTacVien, NhanVien, CaNhan }
enum TrangThaiThongBao { DaGui, ChuaGui, Nhap }

/// Model tương ứng bảng ThongBaoNguoiDung
class ThongBaoNguoiDung {
  final int? id;
  final int thongBaoId;
  final int taiKhoanId;
  final bool daDoc;
  final DateTime? thoiGianDoc;
  final TrangThaiTBND trangThai;

  const ThongBaoNguoiDung({
    this.id,
    required this.thongBaoId,
    required this.taiKhoanId,
    this.daDoc = false,
    this.thoiGianDoc,
    this.trangThai = TrangThaiTBND.DaGui,
  });

  factory ThongBaoNguoiDung.fromJson(Map<String, dynamic> json) =>
      ThongBaoNguoiDung(
        id: json['id'] as int?,
        thongBaoId: json['thongBaoId'] as int,
        taiKhoanId: json['taiKhoanId'] as int,
        daDoc: (json['DaDoc'] as int) == 1,
        thoiGianDoc: json['ThoiGianDoc'] != null
            ? DateTime.parse(json['ThoiGianDoc'] as String)
            : null,
        trangThai: TrangThaiTBND.values.byName(json['TrangThai'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'thongBaoId': thongBaoId,
        'taiKhoanId': taiKhoanId,
        'DaDoc': daDoc ? 1 : 0,
        'ThoiGianDoc': thoiGianDoc?.toIso8601String(),
        'TrangThai': trangThai.name,
      };

  ThongBaoNguoiDung copyWith({
    int? id,
    int? thongBaoId,
    int? taiKhoanId,
    bool? daDoc,
    DateTime? thoiGianDoc,
    TrangThaiTBND? trangThai,
  }) =>
      ThongBaoNguoiDung(
        id: id ?? this.id,
        thongBaoId: thongBaoId ?? this.thongBaoId,
        taiKhoanId: taiKhoanId ?? this.taiKhoanId,
        daDoc: daDoc ?? this.daDoc,
        thoiGianDoc: thoiGianDoc ?? this.thoiGianDoc,
        trangThai: trangThai ?? this.trangThai,
      );
}

enum TrangThaiTBND { DaGui, DaNhan, DaDoc }
