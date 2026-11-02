import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_cung_cap_dich_vu_giup_viec/services/api_response.dart';
import 'package:app_cung_cap_dich_vu_giup_viec/services/collaborator_api_service.dart';
import 'package:app_cung_cap_dich_vu_giup_viec/services/storage_api_service.dart';
import 'package:app_cung_cap_dich_vu_giup_viec/widgets/tai_san_capture_sheet.dart';

class _FakeStorageApiService extends StorageApiService {
  int uploadCallCount = 0;
  bool loi = false;

  @override
  Future<ApiResponse<Map<String, dynamic>>> uploadTaiSanImage({
    required Uint8List bytes,
    required String fileName,
  }) async {
    uploadCallCount++;
    if (loi) return ApiResponse.err('MinIO không phản hồi');
    return ApiResponse.ok({
      'objectName': 'don-dat/tai-san/mock_${uploadCallCount}_$fileName',
      'url': '/xem-file?object=don-dat/tai-san/mock_${uploadCallCount}_$fileName',
    });
  }
}

class _FakeCollaboratorApiService extends CollaboratorApiService {
  int goiLan = 0;
  int? phanCongId;
  String? loaiBieuMau;
  List<String> danhSach = const [];
  String? khuVuc;

  @override
  Future<ApiResponse<Map<String, dynamic>>> guiAnhTaiSan({
    required int phanCongId,
    required String loaiBieuMau,
    required List<String> danhSachHinhAnh,
    String? khuVucVatDung,
    String? moTaHienTrang,
    String? ghiChuTaiSan,
  }) async {
    goiLan++;
    this.phanCongId = phanCongId;
    this.loaiBieuMau = loaiBieuMau;
    danhSach = danhSachHinhAnh;
    khuVuc = khuVucVatDung;
    return ApiResponse.ok({});
  }
}

Future<void> _moSheet(
  WidgetTester tester, {
  required bool truoc,
  required void Function(TaiSanCaptureResult?) nhanKetQua,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () async {
                nhanKetQua(await TaiSanCaptureSheet.show(
                  context,
                  isBeforeService: truoc,
                  maDon: 'DD-101',
                  tenDichVu: 'Dọn dẹp nhà cửa theo giờ',
                  diaChi: '123 Nguyễn Văn Cừ, Quận 5',
                ));
              },
              child: const Text('Mở chụp tài sản'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Mở chụp tài sản'));
  await tester.pumpAndSettle();
}

void main() {
  group('Kiểm thử chụp ảnh tài sản Trước & Sau khi thực hiện dịch vụ', () {
    testWidgets(
      '1. Chụp trước khi làm: ảnh chỉ giữ trong máy, kết quả trả về ảnh chờ gửi (không tràn viền ở 320px)',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(320, 680);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        TaiSanCaptureResult? ketQua;
        await _moSheet(tester, truoc: true, nhanKetQua: (r) => ketQua = r);

        expect(find.text('Chụp tài sản trước khi thực hiện (không bắt buộc)'), findsOneWidget);
        expect(find.text('Tối thiểu 1 ảnh'), findsOneWidget);
        expect(find.text('Bắt đầu làm (không ảnh)'), findsOneWidget);

        await tester.ensureVisible(find.byKey(const Key('btn_capture_tai_san_simulated')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('btn_capture_tai_san_simulated')));
        await tester.pumpAndSettle();

        expect(find.text('Đã chụp 1 ảnh'), findsOneWidget);
        expect(find.text('Gửi ảnh & Bắt đầu làm'), findsOneWidget);

        await tester.tap(find.byKey(const Key('btn_submit_tai_san_photos')));
        await tester.pumpAndSettle();

        expect(ketQua, isNotNull);
        expect(ketQua!.coAnh, isTrue);
        expect(ketQua!.anhCho.length, 1);
        expect(ketQua!.anhCho.first.fileName, startsWith('tai_san_truoc_DD-101_'));
        expect(ketQua!.khuVucVatDung, 'Toàn bộ khu vực làm việc');
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '2. Chụp sau khi hoàn thành: ảnh không bắt buộc, không chụp vẫn hoàn thành được',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 740);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        TaiSanCaptureResult? ketQua;
        await _moSheet(tester, truoc: false, nhanKetQua: (r) => ketQua = r);

        expect(find.text('Chụp tài sản sau khi hoàn thành (không bắt buộc)'), findsOneWidget);
        expect(find.text('Hoàn thành (không ảnh)'), findsOneWidget);

        await tester.tap(find.byKey(const Key('btn_submit_tai_san_photos')));
        await tester.pumpAndSettle();

        expect(ketQua, isNotNull);
        expect(ketQua!.coAnh, isFalse);
        expect(ketQua!.moTaHienTrang, 'Đã dọn sạch sẽ, tài sản nguyên vẹn');
      },
    );

    test('3. Sau khi máy chủ xác nhận: tải từng ảnh lên MinIO rồi gắn danh sách object key vào phân công', () async {
      final storage = _FakeStorageApiService();
      final api = _FakeCollaboratorApiService();
      final anh = TaiSanCaptureSheet.createValidSamplePngBytes(isBefore: true);
      final ketQua = TaiSanCaptureResult(
        anhCho: [
          AnhTaiSanCho(bytes: anh, fileName: 'phong_khach.png'),
          AnhTaiSanCho(bytes: anh, fileName: 'phong_bep.png'),
        ],
        khuVucVatDung: 'Phòng khách',
        moTaHienTrang: 'Tài sản nguyên vẹn, bình thường',
      );

      final keys = await guiAnhTaiSanSauXacNhan(
        phanCongId: 77,
        truocDichVu: true,
        ketQua: ketQua,
        storageService: storage,
        apiService: api,
      );

      expect(storage.uploadCallCount, 2);
      expect(keys, ['don-dat/tai-san/mock_1_phong_khach.png', 'don-dat/tai-san/mock_2_phong_bep.png']);
      expect(api.goiLan, 1);
      expect(api.phanCongId, 77);
      expect(api.loaiBieuMau, 'TruocDichVu');
      expect(api.danhSach, keys);
      expect(api.khuVuc, 'Phòng khách');
      expect(TaiSanMemoryCache.get(keys.first), isNotNull);
    });

    test('4. Không chụp ảnh thì không tải lên và không gọi API; tải ảnh lỗi thì báo lỗi, không gắn vào phân công', () async {
      final storage = _FakeStorageApiService();
      final api = _FakeCollaboratorApiService();

      final rong = await guiAnhTaiSanSauXacNhan(
        phanCongId: 78,
        truocDichVu: false,
        ketQua: const TaiSanCaptureResult(khuVucVatDung: 'Toàn bộ khu vực làm việc', moTaHienTrang: ''),
        storageService: storage,
        apiService: api,
      );
      expect(rong, isEmpty);
      expect(storage.uploadCallCount, 0);
      expect(api.goiLan, 0);

      storage.loi = true;
      final coAnh = TaiSanCaptureResult(
        anhCho: [AnhTaiSanCho(bytes: TaiSanCaptureSheet.createValidSamplePngBytes(isBefore: false), fileName: 'sau.png')],
        khuVucVatDung: 'Phòng ngủ',
        moTaHienTrang: 'Đã dọn sạch sẽ, tài sản nguyên vẹn',
      );
      await expectLater(
        guiAnhTaiSanSauXacNhan(
          phanCongId: 78,
          truocDichVu: false,
          ketQua: coAnh,
          storageService: storage,
          apiService: api,
        ),
        throwsA(isA<Exception>()),
      );
      expect(api.goiLan, 0);
    });

    testWidgets(
      '5. Hiển thị khung ảnh Trước & Sau khi xem đơn đặt (TaiSanBeforeAfterSection) không tràn viền trên màn hình hẹp 320px',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final sampleBytes =
            TaiSanCaptureSheet.createValidSamplePngBytes(isBefore: true);
        TaiSanMemoryCache.put('/xem-file?object=don-dat/tai-san/truoc.png', sampleBytes);
        TaiSanMemoryCache.put('/xem-file?object=don-dat/tai-san/sau.png', sampleBytes);

        final orderData = <String, dynamic>{
          'maDonDat': 'DD-999',
          'anhTruocDichVu': ['/xem-file?object=don-dat/tai-san/truoc.png'],
          'anhSauDichVu': ['/xem-file?object=don-dat/tai-san/sau.png'],
          'thoiGianChupTruoc': '08:05 25/10/2026',
          'thoiGianChupSau': '10:15 25/10/2026',
          'chiTietTruocDichVu': [
            {
              'khuVucVatDung': 'Phòng khách',
              'moTaHienTrang': 'Tài sản nguyên vẹn, bình thường',
            }
          ],
          'chiTietSauDichVu': [
            {
              'khuVucVatDung': 'Phòng khách',
              'moTaHienTrang': 'Đã dọn sạch sẽ, tài sản nguyên vẹn',
            }
          ],
        };

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: TaiSanBeforeAfterSection(orderData: orderData),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Hình ảnh tài sản khu vực thực hiện (Trước & Sau)'),
          findsOneWidget,
        );
        expect(find.text('Trước khi thực hiện'), findsOneWidget);
        expect(find.text('Sau khi hoàn thành'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
