import 'package:flutter/material.dart';
import 'package:app_cung_cap_dich_vu_giup_viec/services/dia_gioi_api_service.dart';
import 'package:app_cung_cap_dich_vu_giup_viec/widgets/dia_chi_fields.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DiaChiDangChon - Hỗ trợ song song 2 hệ thống địa chỉ', () {
    test('Mặc định khởi tạo ở chế độ địa chỉ cũ v1 (3 cấp)', () {
      final dc = DiaChiDangChon();
      expect(dc.isV1, isTrue);
      expect(dc.maTinh, equals(DiaGioiApiService.maHcm));
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

      expect(find.text('📍 Địa chỉ cũ (Quận/Huyện)'), findsOneWidget);
      expect(find.text('🏛️ Địa chỉ mới (Sáp nhập)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
