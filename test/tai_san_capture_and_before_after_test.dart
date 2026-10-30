import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_cung_cap_dich_vu_giup_viec/services/api_response.dart';
import 'package:app_cung_cap_dich_vu_giup_viec/services/storage_api_service.dart';
import 'package:app_cung_cap_dich_vu_giup_viec/widgets/tai_san_capture_sheet.dart';

class _FakeStorageApiService extends StorageApiService {
  int uploadCallCount = 0;

  @override
  Future<ApiResponse<Map<String, dynamic>>> uploadTaiSanImage({
    required Uint8List bytes,
    required String fileName,
  }) async {
    uploadCallCount++;
    return ApiResponse.ok({
      'objectName': 'don-dat/tai-san/mock_${uploadCallCount}_$fileName',
      'url': '/xem-file?object=don-dat/tai-san/mock_${uploadCallCount}_$fileName',
    });
  }
}

void main() {
  group('Kiểm thử chụp ảnh tài sản Trước & Sau khi thực hiện dịch vụ', () {
    testWidgets(
      '1. Chụp trước khi làm: Chưa chụp ảnh không cho bắt đầu; Chụp & Gửi trả về kết quả lưu MinIO (0 tràn viền trên màn hình 320px)',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(320, 680);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final fakeStorage = _FakeStorageApiService();
        TaiSanCaptureResult? capturedResult;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      capturedResult = await TaiSanCaptureSheet.show(
                        context,
                        isBeforeService: true,
                        maDon: 'DD-101',
                        tenDichVu: 'Dọn dẹp nhà cửa theo giờ',
                        diaChi: '123 Nguyễn Văn Cừ, Quận 5',
                        storageService: fakeStorage,
                      );
                    },
                    child: const Text('Mở chụp trước ca'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Mở chụp trước ca'));
        await tester.pumpAndSettle();

        expect(find.text('Chụp tài sản trước khi thực hiện'), findsOneWidget);
        expect(find.text('Tối thiểu 1 ảnh'), findsOneWidget);

        // Thử bấm Gửi ngay khi chưa chụp ảnh -> Phải chặn và báo lỗi
        await tester.tap(find.byKey(const Key('btn_submit_tai_san_photos')));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Vui lòng chụp ít nhất 1 ảnh tài sản'),
          findsOneWidget,
        );
        expect(capturedResult, isNull);

        // Bấm chụp ảnh hiện trạng
        await tester.ensureVisible(
          find.byKey(const Key('btn_capture_tai_san_simulated')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('btn_capture_tai_san_simulated')));
        await tester.pumpAndSettle();

        expect(fakeStorage.uploadCallCount, 1);
        expect(find.text('Đã chụp 1 ảnh'), findsOneWidget);

        // Bấm Gửi ảnh & Bắt đầu làm
        await tester.tap(find.byKey(const Key('btn_submit_tai_san_photos')));
        await tester.pumpAndSettle();

        expect(capturedResult, isNotNull);
        expect(capturedResult!.danhSachHinhAnh.length, 1);
        expect(
          capturedResult!.danhSachHinhAnh.first,
          startsWith('don-dat/tai-san/mock_1_'),
        );
        expect(capturedResult!.khuVucVatDung, 'Toàn bộ khu vực làm việc');
      },
    );

    testWidgets(
      '2. Chụp sau khi hoàn thành: Không chụp lại thì đơn KHÔNG được chuyển sang Hoàn thành',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(360, 740);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final fakeStorage = _FakeStorageApiService();
        TaiSanCaptureResult? afterResult;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      afterResult = await TaiSanCaptureSheet.show(
                        context,
                        isBeforeService: false,
                        maDon: 'DD-102',
                        tenDichVu: 'Tổng vệ sinh căn hộ',
                        storageService: fakeStorage,
                      );
                    },
                    child: const Text('Ấn hoàn thành đơn'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Ấn hoàn thành đơn'));
        await tester.pumpAndSettle();

        expect(find.text('Chụp tài sản sau khi hoàn thành'), findsOneWidget);

        // Không chụp mà bấm Gửi ảnh & Hoàn thành -> Bị chặn
        await tester.tap(find.byKey(const Key('btn_submit_tai_san_photos')));
        await tester.pumpAndSettle();

        expect(
          find.textContaining(
            'Không chụp ảnh thì đơn không được chuyển sang trạng thái Hoàn thành',
          ),
          findsOneWidget,
        );
        expect(afterResult, isNull);

        // Chụp ảnh nghiệm thu
        await tester.ensureVisible(
          find.byKey(const Key('btn_capture_tai_san_simulated')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('btn_capture_tai_san_simulated')));
        await tester.pumpAndSettle();

        expect(find.text('Đã chụp 1 ảnh'), findsOneWidget);

        // Ấn gửi -> Hoàn thành
        await tester.tap(find.byKey(const Key('btn_submit_tai_san_photos')));
        await tester.pumpAndSettle();

        expect(afterResult, isNotNull);
        expect(afterResult!.danhSachHinhAnh.length, 1);
      },
    );

    testWidgets(
      '3. Hiển thị khung ảnh Trước & Sau khi xem đơn đặt (TaiSanBeforeAfterSection) không tràn viền trên màn hình hẹp 320px',
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
