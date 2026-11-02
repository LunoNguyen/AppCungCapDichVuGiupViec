import 'dart:async';

import 'package:app_cung_cap_dich_vu_giup_viec/services/location_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _kenhGps = MethodChannel('flutter.baseflow.com/geolocator');

/// GPS giả: đã bật định vị, đã cấp quyền, nhưng lấy vị trí hiện tại và vị trí đã biết đều không bao giờ trả về.
void _gpsKhongPhanHoi() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_kenhGps, (call) {
    switch (call.method) {
      case 'isLocationServiceEnabled':
        return Future.value(true);
      case 'checkPermission':
        return Future.value(2); // whileInUse
      default:
        return Completer<Object?>().future; // treo vĩnh viễn
    }
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocationService - Không treo khi GPS không phản hồi (DC-06)', () {
    tearDown(() {
      LocationService.thoiGianCho = const Duration(seconds: 15);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_kenhGps, null);
    });

    test('Thời gian chờ mặc định là 15 giây', () {
      expect(LocationService.thoiGianCho, const Duration(seconds: 15));
    });

    test('Cấp quyền nhưng GPS treo: hết thời gian chờ thì báo lỗi thay vì treo', () async {
      _gpsKhongPhanHoi();
      LocationService.thoiGianCho = const Duration(milliseconds: 200);
      final kq = await LocationService.getCurrentPosition()
          .timeout(const Duration(seconds: 10));
      expect(kq.ok, isFalse);
      expect(kq.error, contains('Chưa lấy được vị trí GPS'));
    });

    test('Sau khi một lần gọi bị hết hạn, lần gọi tiếp theo không bị kẹt theo', () async {
      _gpsKhongPhanHoi();
      LocationService.thoiGianCho = const Duration(milliseconds: 200);
      final a = LocationService.getCurrentPosition();
      final b = LocationService.getCurrentPosition();
      await Future.wait([a, b]).timeout(const Duration(seconds: 10));
      final c = await LocationService.getCurrentPosition()
          .timeout(const Duration(seconds: 10));
      expect(c.ok, isFalse);
    });
  });

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
