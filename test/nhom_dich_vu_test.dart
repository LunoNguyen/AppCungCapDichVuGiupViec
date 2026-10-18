import 'package:app_cung_cap_dich_vu_giup_viec/services/nhom_dich_vu.dart';
import 'package:flutter_test/flutter_test.dart';

/// Gom kết quả /v1/services theo mã dịch vụ thành thẻ ở bước 1 của màn đặt.
void main() {
  Map<String, dynamic> dv(int id, String? ma, String ten, String loai, int gia, {String? anh}) => {
        'id': id,
        'maDichVu': ma,
        'tenDichVu': ten,
        'loaiHinhDat': loai,
        'donGiaThamKhao': gia,
        if (anh != null) 'hinhAnhUrl': anh,
      };

  final dichVus = [
    dv(4, 'DV101', 'Dọn dẹp nhà theo giờ (Gói 8 buổi/tháng, 2 giờ/buổi)', 'GoiThang', 1590000),
    dv(2, 'DV101', 'Dọn dẹp nhà theo giờ (3 giờ)', 'TheoLan', 270000, anh: '/images/a.webp'),
    dv(1, 'DV101', 'Dọn dẹp nhà theo giờ (2 giờ)', 'TheoLan', 216000),
    dv(3, 'DV101', 'Dọn dẹp nhà theo giờ (4 giờ)', 'TheoLan', 342000),
    dv(10, 'DV102', 'Tổng vệ sinh nhà (tối đa 60m², 2 người/3 giờ)', 'TheoLan', 660000),
    dv(99, null, 'Dịch vụ cũ', 'TheoLan', 0),
  ];

  test('Gom theo mã, giữ thứ tự xuất hiện, mã rỗng tách theo id', () {
    expect(NhomDichVu.gom(dichVus).map((g) => g.ma).toList(), ['DV101', 'DV102', 'id-99']);
  });

  test('Nhóm có đủ thông tin thẻ và biến thể sắp theo giá', () {
    final g = NhomDichVu.gom(dichVus).first;
    expect(g.ten, 'Dọn dẹp nhà theo giờ');
    expect(g.giaTu, 216000);
    expect(g.anh, '/images/a.webp');
    expect(g.coTheoLan && g.coGoiThang, isTrue);
    expect(g.bienTheTheoLoai('TheoLan').map((b) => b['donGiaThamKhao']).toList(), [216000, 270000, 342000]);
    expect(g.bienThe.first['loaiHinhDat'], 'TheoLan');
  });

  test('Nhóm chỉ theo lần, nhóm không có giá', () {
    final ds = NhomDichVu.gom(dichVus);
    expect(ds[1].coGoiThang, isFalse);
    expect(ds[2].giaTu, 0);
  });

  test('Tìm nhóm theo id dịch vụ đang xem', () {
    final ds = NhomDichVu.gom(dichVus);
    expect(NhomDichVu.timTheoDichVuId(ds, 2)!.ma, 'DV101');
    expect(NhomDichVu.timTheoDichVuId(ds, 12345), isNull);
  });

  test('Tên nhóm bỏ phần biến thể trong ngoặc', () {
    expect(NhomDichVu.tenNhom('Tổng vệ sinh nhà (tối đa 60m², 2 người/3 giờ)'), 'Tổng vệ sinh nhà');
    expect(NhomDichVu.tenNhom('Đi chợ hộ'), 'Đi chợ hộ');
  });

  test('Biến thể đại diện khi mở chi tiết: ưu tiên hình thức đang lọc, rẻ nhất', () {
    final g = NhomDichVu.gom(dichVus).first;
    expect(g.bienTheDaiDien(null)['donGiaThamKhao'], 216000);
    expect(g.bienTheDaiDien('TheoLan')['donGiaThamKhao'], 216000);
    expect(g.bienTheDaiDien('GoiThang')['loaiHinhDat'], 'GoiThang');
    // Nhóm không có hình thức đang lọc: lấy biến thể đầu tiên
    expect(NhomDichVu.gom(dichVus)[1].bienTheDaiDien('GoiThang')['loaiHinhDat'] ?? 'TheoLan', 'TheoLan');
  });

  test('Số lựa chọn và nhãn hình thức của nhóm', () {
    final g = NhomDichVu.gom(dichVus).first;
    expect(g.nhanHinhThuc, 'Theo lần · Gói tháng');
    expect(NhomDichVu.gom(dichVus)[1].nhanHinhThuc, 'Theo lần');
  });

  test('Nhãn ngắn của biến thể: phần trong ngoặc, không có thì theo thời lượng', () {
    expect(NhomDichVu.nhanBienThe({'tenDichVu': 'Dọn dẹp nhà theo giờ (2 giờ)'}), '2 giờ');
    expect(NhomDichVu.nhanBienThe({'tenDichVu': 'Dọn dẹp nhà theo giờ (Gói 8 buổi/tháng, 2 giờ/buổi)'}),
        'Gói 8 buổi/tháng, 2 giờ/buổi');
    expect(NhomDichVu.nhanBienThe({'tenDichVu': 'Đi chợ hộ', 'thoiGianThucHienPhut': 90}), '90 phút');
    expect(NhomDichVu.nhanBienThe({'tenDichVu': 'Đi chợ hộ', 'thoiGianThucHienPhut': 120}), '2 giờ');
    expect(NhomDichVu.nhanBienThe({'tenDichVu': 'Đi chợ hộ'}), 'Đi chợ hộ');
  });
}
