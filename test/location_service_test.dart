import 'package:app_cung_cap_dich_vu_giup_viec/services/location_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LocationService - Nhận diện quận theo toạ độ GPS', () {
    test('Toạ độ Quận Tân Phú ra đúng Quận Tân Phú', () {
      final quan = LocationService.doanQuanTheoToaDo(10.7901, 106.6281);
      expect(quan, equals('Quận Tân Phú'));
    });

    test('Toạ độ Tây Thạnh Tân Phú ra đúng Quận Tân Phú', () {
      final quan = LocationService.doanQuanTheoToaDo(10.8120, 106.6275);
      expect(quan, equals('Quận Tân Phú'));
    });

    test('Toạ độ Quận Bình Thạnh ra đúng Quận Bình Thạnh', () {
      final quan = LocationService.doanQuanTheoToaDo(10.8106, 106.7091);
      expect(quan, equals('Quận Bình Thạnh'));
    });

    test('Toạ độ Quận 1 ra đúng Quận 1', () {
      final quan = LocationService.doanQuanTheoToaDo(10.7769, 106.7009);
      expect(quan, equals('Quận 1'));
    });

    test('Toạ độ ngoài TP.HCM (Hà Nội) trả về null', () {
      final quan = LocationService.doanQuanTheoToaDo(21.0285, 105.8542);
      expect(quan, isNull);
    });
  });
}
