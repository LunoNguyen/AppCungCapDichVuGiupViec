import 'package:flutter/material.dart';
import 'package:app_cung_cap_dich_vu_giup_viec/services/dia_gioi_api_service.dart';
import 'package:app_cung_cap_dich_vu_giup_viec/widgets/dia_chi_fields.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DiaChiDangChon - ô tỉnh (mới + cũ) → ô phường, xã / quận, huyện', () {
    test('Mặc định TP.HCM (mới), chưa chọn ô thứ hai', () {
      final dc = DiaChiDangChon();
      expect(dc.tinhCu, isFalse);
      expect(dc.maTinh, equals(DiaGioiApiService.maHcm));
      expect([dc.maPhuong, dc.maQuan, dc.daChonDuoi], [null, null, false]);
    });

    test('Tỉnh mới + phường mới: gửi maPhuong, khu vực theo phường', () {
      final dc = DiaChiDangChon();
      dc.chonTinh(const TinhThanh(79, 'Thành phố Hồ Chí Minh'));
      dc.apDung(PhuongGop.fromJson({
        'ma': 26734, 'ten': 'Phường Sài Gòn', 'cu': false,
        'khuVuc': [{'id': 1, 'tenKhuVuc': 'Quận 1'}],
      }));
      expect([dc.maPhuong, dc.maQuan, dc.khuVuc?.id], [26734, null, 1]);
      expect(dc.tenPhuongHienTai, 'Phường Sài Gòn');
      expect(dc.duoi!.nhan, 'Sài Gòn (Phường)');
    });

    test('Tỉnh cùng tên + quận cũ: gửi mã tỉnh cũ + maQuan (không có maPhuong), khu vực theo quận', () {
      final dc = DiaChiDangChon();
      dc.chonTinh(const TinhThanh(79, 'Thành phố Hồ Chí Minh', maCu: 79));
      dc.apDung(PhuongGop.fromJson({
        'ma': 767, 'ten': 'Quận Tân Phú', 'cu': true, 'maTinh': 79,
        'khuVuc': [{'id': 7, 'tenKhuVuc': 'Quận Tân Phú'}],
      }));
      expect(dc.tinhCu, isFalse);
      expect(dc.isV1, isTrue);
      expect([dc.maTinhGui, dc.maPhuong, dc.maQuan, dc.khuVuc?.id], [79, null, 767, 7]);
      expect(dc.tenQuanHienTai, 'Quận Tân Phú');
      expect(dc.duoi!.nhan, 'Quận Tân Phú (cũ)');
      expect(dc.ngoaiKhuVuc, isFalse);
    });

    test('Quận cũ mang mã tỉnh cũ khác ô tỉnh: gửi mã tỉnh cũ', () {
      final dc = DiaChiDangChon();
      dc.chonTinh(const TinhThanh(1, 'Thành phố Hà Nội', maCu: 1));
      dc.apDung(const PhuongGop(ma: 5, ten: 'Quận X', cu: true, maTinh: 2));
      expect([dc.maTinh, dc.maTinhGui, dc.maQuan], [1, 2, 5]);
      dc.apDung(const PhuongGop(ma: 5, ten: 'Phường Y'));
      expect([dc.maTinhGui, dc.maPhuong, dc.maQuan, dc.isV1], [1, 5, null, false]);
    });

    test('Nhãn: tỉnh chỉ còn ở danh mục cũ ghi "(cũ)", tỉnh mới để nguyên; cùng mã vẫn phân biệt được', () {
      const moi = TinhThanh(79, 'Thành phố Hồ Chí Minh');
      const cu = TinhThanh(79, 'Thành phố Hồ Chí Minh', cu: true);
      expect(moi.nhan, 'Thành phố Hồ Chí Minh');
      expect(cu.nhan, 'Thành phố Hồ Chí Minh (cũ)');
      final dc = DiaChiDangChon();
      expect([dc.laTinh(moi), dc.laTinh(cu)], [true, false]);
    });

    test('Đổi tỉnh thì bỏ lựa chọn ô thứ hai', () {
      final dc = DiaChiDangChon();
      dc.apDung(const PhuongGop(ma: 1, ten: 'Phường A', khuVuc: [KhuVucNho(1, 'Quận 1')]));
      dc.chonTinh(const TinhThanh(74, 'Tỉnh Bình Dương', cu: true));
      expect([dc.daChonDuoi, dc.maQuan, dc.maPhuong], [false, null, null]);
    });

    test('Quận ngoài khu vực phục vụ', () {
      final dc = DiaChiDangChon();
      dc.chonTinh(const TinhThanh(74, 'Tỉnh Bình Dương', cu: true));
      dc.apDung(const PhuongGop(ma: 718, ten: 'Thành phố Thủ Dầu Một', cu: true));
      expect(dc.ngoaiKhuVuc, isTrue);
      expect(dc.khuVuc, isNull);
    });

    testWidgets('DiaChiFields hiển thị trên màn hình nhỏ (320px) không bị tràn giao diện', (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final dc = DiaChiDangChon();
      final ctrl = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DiaChiFields(
                giaTri: dc,
                soNhaCtrl: ctrl,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tỉnh, thành phố *'), findsOneWidget);
      expect(find.text('Phường, xã / quận, huyện *'), findsOneWidget);
      expect(find.text('Quận, huyện *'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
