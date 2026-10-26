import 'package:app_cung_cap_dich_vu_giup_viec/services/gio_hang.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Giỏ hàng trên app: cùng quy tắc với giỏ hàng web (site.js CartCache, gio-hang.html).
void main() {
  MonGio mon(int id, {String loai = 'TheoLan', int phut = 120, int gia = 100000}) => MonGio(
        id: id,
        ten: 'DV$id',
        gia: gia,
        phut: phut,
        loaiHinhDat: loai,
        danhMucId: 1,
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await GioHang.instance.tai();
    await GioHang.instance.xoaTatCa();
  });

  test('thêm dịch vụ, thêm trùng thì báo đã có', () async {
    expect(await GioHang.instance.them(mon(1)), isTrue);
    expect(await GioHang.instance.them(mon(1)), isFalse);
    expect(GioHang.instance.mon.length, 1);
  });

  test('lưu lại sau khi mở lại app', () async {
    await GioHang.instance.them(mon(1));
    await GioHang.instance.them(mon(2));
    await GioHang.instance.tai();
    expect(GioHang.instance.mon.map((m) => m.id), [1, 2]);
  });

  test('gói tháng không được chọn đặt chung', () async {
    await GioHang.instance.them(mon(1));
    await GioHang.instance.them(mon(2, loai: 'GoiThang'));
    await GioHang.instance.chonTatCa(true);
    expect(GioHang.instance.daChon.map((m) => m.id), [1]);
  });

  test('tổng giá và tổng thời lượng của các dịch vụ đã chọn', () async {
    await GioHang.instance.them(mon(1, phut: 180, gia: 270000));
    await GioHang.instance.them(mon(2, phut: 240, gia: 1760000));
    expect(GioHang.instance.tongGia, 2030000);
    expect(GioHang.instance.tongPhut, 420);
  });

  test('giới hạn 5 dịch vụ và 8 giờ', () {
    expect(GioHang.loiDatChung([for (var i = 1; i <= 6; i++) mon(i, phut: 30)]), 'Mỗi lần đặt tối đa 5 dịch vụ.');
    expect(GioHang.loiDatChung([mon(1, phut: 240), mon(2, phut: 270)]), 'Tổng thời lượng tối đa 8 giờ (đang chọn 8 giờ 30 phút).');
    expect(GioHang.loiDatChung([mon(1, phut: 180), mon(2, phut: 240)]), isNull);
  });

  test('đặt xong thì bỏ các dịch vụ vừa đặt khỏi giỏ', () async {
    await GioHang.instance.them(mon(1));
    await GioHang.instance.them(mon(2));
    await GioHang.instance.them(mon(3, loai: 'GoiThang'));
    await GioHang.instance.xoaNhieu([1, 2]);
    expect(GioHang.instance.mon.map((m) => m.id), [3]);
  });

  test('tạo món giỏ từ dữ liệu dịch vụ của API', () {
    final m = MonGio.tuDichVu({
      'id': 319, 'tenDichVu': 'Dọn dẹp nhà theo giờ (3 giờ)', 'donGiaThamKhao': 270000,
      'thoiGianThucHienPhut': 180, 'loaiHinhDat': 'TheoLan', 'loaiDichVuId': 1, 'hinhAnhUrl': '/files/a.jpg',
    });
    expect([m.id, m.gia, m.phut, m.danhMucId, m.laGoi], [319, 270000, 180, 1, false]);
    expect(m.ten, 'Dọn dẹp nhà theo giờ (3 giờ)');
  });
}
