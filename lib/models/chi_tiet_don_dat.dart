/// Model tương ứng bảng ChiTietDonDat (1 đơn đặt chứa nhiều chi tiết dịch vụ)
class ChiTietDonDat {
  final int? id;
  final int? donDatId;
  final int dichVuId;
  final String? tenDichVu;
  final int soLuong;
  final num donGia;
  final num thanhTien;
  final String? ngayThucHienTrongTuan;
  final String? ghiChu;

  const ChiTietDonDat({
    this.id,
    this.donDatId,
    required this.dichVuId,
    this.tenDichVu,
    this.soLuong = 1,
    this.donGia = 0,
    this.thanhTien = 0,
    this.ngayThucHienTrongTuan,
    this.ghiChu,
  });

  factory ChiTietDonDat.fromJson(Map<String, dynamic> json) {
    return ChiTietDonDat(
      id: json['id'] as int?,
      donDatId: json['donDatId'] as int?,
      dichVuId: json['dichVuId'] as int? ?? 0,
      tenDichVu: json['tenDichVu'] as String?,
      soLuong: json['soLuong'] as int? ?? 1,
      donGia: (json['donGia'] as num?) ?? 0,
      thanhTien: (json['thanhTien'] as num?) ?? 0,
      ngayThucHienTrongTuan: json['ngayThucHienTrongTuan'] as String?,
      ghiChu: json['ghiChu'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'donDatId': donDatId,
        'dichVuId': dichVuId,
        'tenDichVu': tenDichVu,
        'soLuong': soLuong,
        'donGia': donGia,
        'thanhTien': thanhTien,
        'ngayThucHienTrongTuan': ngayThucHienTrongTuan,
        'ghiChu': ghiChu,
      };
}