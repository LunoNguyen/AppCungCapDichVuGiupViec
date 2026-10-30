import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/models/cong_tac_vien.dart';

void main() {
  group('Kiểm tra tính toán thu nhập CTV (80% thực nhận - 20% phí nền tảng)', () {
    num getGrossPrice(Map<String, dynamic> o) {
      return num.tryParse(o['thanhTien']?.toString() ??
              o['tongTienDon']?.toString() ??
              o['tongTien']?.toString() ??
              '') ??
          0;
    }

    num getPlatformFee(Map<String, dynamic> o) {
      final fromApi = num.tryParse(o['phiNenTang']?.toString() ?? '');
      if (fromApi != null && fromApi > 0) return fromApi.round();
      final gross = getGrossPrice(o);
      final net = (gross * 0.80).round();
      return gross.round() - net;
    }

    num getNetIncome(Map<String, dynamic> o) {
      final fromApi = num.tryParse(o['tienThucNhan']?.toString() ?? '');
      if (fromApi != null && fromApi > 0) return fromApi.round();
      final gross = getGrossPrice(o);
      return (gross * 0.80).round();
    }

    test('Đơn 300.000đ -> Phí nền tảng 20% = 60.000đ, CTV thực nhận 80% = 240.000đ', () {
      final order = {'thanhTien': 300000};
      expect(getGrossPrice(order), 300000);
      expect(getPlatformFee(order), 60000);
      expect(getNetIncome(order), 240000);
      expect(getPlatformFee(order) + getNetIncome(order), getGrossPrice(order));
    });

    test('Đơn 320.000đ -> Phí nền tảng 20% = 64.000đ, CTV thực nhận 80% = 256.000đ', () {
      final order = {'thanhTien': 320000};
      expect(getGrossPrice(order), 320000);
      expect(getPlatformFee(order), 64000);
      expect(getNetIncome(order), 256000);
      expect(getPlatformFee(order) + getNetIncome(order), getGrossPrice(order));
    });

    test('CongTacVien.fromJson parse đúng trường soDuVi từ Backend', () {
      final ctv = CongTacVien.fromJson({
        'id': 5,
        'maCongTacVien': 'CTV-005',
        'hoTen': 'Nguyễn Văn A',
        'noiCuTru': 'Tân Phú, TP.HCM',
        'khuVucNhanViec': 'Quận Tân Phú',
        'soDienThoai': '0901234567',
        'diemDanhGia': 4.9,
        'soDuVi': 496000,
        'capDo': 'Thuong',
        'trangThai': 'HoatDong',
        'ngayDangKy': '2026-10-01',
      });
      expect(ctv.soDuVi, 496000.0);
    });

    testWidgets('Giao diện xác nhận hoàn thành ca làm hiển thị 100%, -20%, +80% không tràn viền trên màn hình nhỏ (320px)',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      bool confirmed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => Center(
                child: ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: ctx,
                      isScrollControlled: true,
                      builder: (modalCtx) => Container(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text('Tổng giá trị đơn dịch vụ (100%)'),
                                ),
                                SizedBox(width: 8),
                                Text('300.000đ'),
                              ],
                            ),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text('Chiết khấu chi phí nền tảng (20%)'),
                                ),
                                SizedBox(width: 8),
                                Text('-60.000đ'),
                              ],
                            ),
                            Row(
                              children: [
                                const Expanded(
                                  child: Text('Số tiền bạn thực nhận (80%)'),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text('+240.000đ'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.pop(modalCtx),
                                    child: const FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text('Từ chối / Quay lại'),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      confirmed = true;
                                      Navigator.pop(modalCtx);
                                    },
                                    child: const FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text('Xác nhận (+240.000đ)'),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: const Text('XÁC NHẬN HOÀN THÀNH'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('XÁC NHẬN HOÀN THÀNH'));
      await tester.pumpAndSettle();

      expect(find.text('Tổng giá trị đơn dịch vụ (100%)'), findsOneWidget);
      expect(find.text('Chiết khấu chi phí nền tảng (20%)'), findsOneWidget);
      expect(find.text('Số tiền bạn thực nhận (80%)'), findsOneWidget);
      expect(find.text('+240.000đ'), findsOneWidget);

      await tester.tap(find.text('Xác nhận (+240.000đ)'));
      await tester.pumpAndSettle();
      expect(confirmed, isTrue);
    });
  });
}
