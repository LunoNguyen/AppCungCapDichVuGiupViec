import 'package:flutter/material.dart';
import 'package:app_cung_cap_dich_vu_giup_viec/services/dia_gioi_api_service.dart';
import 'package:app_cung_cap_dich_vu_giup_viec/widgets/dia_chi_fields.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DiaChiDangChon - form 2 ô, phường gộp mới + cũ', () {
    test('Mặc định TP.HCM, chưa chọn phường', () {
      final dc = DiaChiDangChon();
      expect(dc.isV1, isFalse);
      expect(dc.maTinh, equals(DiaGioiApiService.maHcm));
      expect(dc.maPhuong, isNull);
    });

    test('Chọn phường cũ từ danh sách gộp: gửi kèm maQuan, khu vực theo quận cũ', () {
      final dc = DiaChiDangChon();
      dc.apDung(PhuongGop.fromJson({
        'ma': 26734, 'ten': 'Phường Bến Nghé', 'loai': 'cu',
        'maQuan': 760, 'tenQuan': 'Quận 1', 'khuVucId': 1, 'tenKhuVuc': 'Quận 1',
      }));
      expect(dc.isV1, isTrue);
      expect([dc.maPhuong, dc.maQuan, dc.khuVuc?.id], [26734, 760, 1]);
    });

    test('Chọn phường mới: không có maQuan; mã trùng phường cũ vẫn phân biệt được', () {
      final dc = DiaChiDangChon();
      final moi = PhuongGop.fromJson({'ma': 26734, 'ten': 'Phường Sài Gòn', 'loai': 'moi', 'khuVuc': [{'id': 1, 'tenKhuVuc': 'Quận 1'}]});
      final cu = PhuongGop.fromJson({'ma': 26734, 'ten': 'Phường Bến Nghé', 'loai': 'cu', 'maQuan': 760, 'tenQuan': 'Quận 1'});
      dc.apDung(moi);
      expect([dc.isV1, dc.maPhuong, dc.maQuan], [false, 26734, null]);
      expect(dc.laPhuong(moi), isTrue);
      expect(dc.laPhuong(cu), isFalse);
      expect(moi.nhan, 'Sài Gòn (Phường) — mới');
      expect(cu.nhan, 'Bến Nghé (Phường) — Quận 1 (cũ)');
    });

    test('Chế độ V1: Gán quận Tân Phú và phường Tây Thạnh chuẩn xác', () {
      final dc = DiaChiDangChon();
      dc.isV1 = true;
      dc.quanV1 = const QuanHuyenV1(
        ma: 767,
        ten: 'Quận Tân Phú',
        maTinh: 79,
        khuVucId: 7,
        tenKhuVuc: 'Quận Tân Phú',
      );
      dc.phuongV1 = const PhuongXaV1(
        ma: 27013,
        ten: 'Phường Tây Thạnh',
        maQuan: 767,
      );

      expect(dc.tenQuanHienTai, equals('Quận Tân Phú'));
      expect(dc.tenPhuongHienTai, equals('Phường Tây Thạnh'));
      expect(dc.khuVuc?.id, equals(7));
      expect(dc.ngoaiKhuVuc, isFalse);
    });

    test('Chế độ V2: Gán phường sau sáp nhập chuẩn xác', () {
      final dc = DiaChiDangChon();
      dc.isV1 = false;
      dc.phuong = const PhuongXa(
        27013,
        'Phường Tây Thạnh',
        [KhuVucNho(7, 'Quận Tân Phú')],
      );

      expect(dc.tenQuanHienTai, isNull);
      expect(dc.tenPhuongHienTai, equals('Phường Tây Thạnh'));
      expect(dc.khuVuc?.id, equals(7));
      expect(dc.ngoaiKhuVuc, isFalse);
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

      expect(find.text('📍 Địa chỉ cũ (Quận/Huyện)'), findsNothing);
      expect(find.text('Tỉnh, thành phố *'), findsOneWidget);
      expect(find.text('Phường, xã *'), findsOneWidget);
      expect(find.text('Quận, huyện *'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
