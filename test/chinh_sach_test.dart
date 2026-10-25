import 'package:app_cung_cap_dich_vu_giup_viec/services/chinh_sach.dart';
import 'package:flutter_test/flutter_test.dart';

/// Đọc nội dung chính sách từ /v1/chinh-sach (cùng nguồn với trang web /chinh-sach).
void main() {
  final json = [
    {
      'ma': 'khieu-nai',
      'ten': 'Quy trình tiếp nhận và xử lý khiếu nại',
      'moTa': 'Thời hạn và các bước giải quyết.',
      'noiDung': [
        {'loai': 'tieuDe', 'noiDung': 'I. Mục đích'},
        {'loai': 'tieuDeNho', 'noiDung': 'Bước 1: Khách hàng gửi khiếu nại'},
        {'loai': 'doan', 'noiDung': 'Thời gian xử lý tối đa 60 ngày làm việc.'},
        {
          'loai': 'ds',
          'muc': ['Email: support@btaskee.com', 'Hotline: 1900 636 736']
        },
        {
          'loai': 'bang',
          'cot': ['Loại khiếu nại', 'Thời hạn tính từ'],
          'dong': [
            ['Mất/thất lạc tài sản', '5 ngày kể từ ngày đặt công việc'],
          ],
        },
        {'loai': 'khongBiet', 'noiDung': 'bỏ qua'},
      ],
    },
  ];

  test('Đọc tài liệu và các loại khối', () {
    final ds = TaiLieuChinhSach.danhSachTuJson(json);
    expect(ds, hasLength(1));
    final t = ds.first;
    expect(t.ma, 'khieu-nai');
    expect(t.ten, 'Quy trình tiếp nhận và xử lý khiếu nại');
    expect(t.khoi.map((k) => k.runtimeType).toList(),
        [KhoiTieuDe, KhoiTieuDeNho, KhoiDoan, KhoiDanhSach, KhoiBang]);
    expect((t.khoi[3] as KhoiDanhSach).muc, hasLength(2));
    final bang = t.khoi[4] as KhoiBang;
    expect(bang.cot, ['Loại khiếu nại', 'Thời hạn tính từ']);
    expect(bang.dong.first.last, '5 ngày kể từ ngày đặt công việc');
  });

  test('Dữ liệu lỗi hoặc rỗng thì không ném lỗi', () {
    expect(TaiLieuChinhSach.danhSachTuJson(null), isEmpty);
    expect(TaiLieuChinhSach.danhSachTuJson('sai'), isEmpty);
    final t = TaiLieuChinhSach.danhSachTuJson([
      {'ma': 'x', 'ten': 'X'}
    ]).single;
    expect(t.khoi, isEmpty);
    expect(t.moTa, '');
  });
}
