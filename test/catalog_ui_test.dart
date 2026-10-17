import 'package:app_cung_cap_dich_vu_giup_viec/services/api_config.dart';
import 'package:app_cung_cap_dich_vu_giup_viec/services/catalog_ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ghép URL ảnh từ giá trị máy chủ trả (hinhAnhUrl / hinhAnh).
void main() {
  final goc = ApiConfig.baseUrl;

  test('URL đầy đủ giữ nguyên', () {
    expect(CatalogUi.fileUrl('https://img.example.com/a.png'), 'https://img.example.com/a.png');
  });

  test('Đường dẫn tĩnh của máy chủ ghép thẳng vào baseUrl', () {
    expect(CatalogUi.fileUrl('/images/btaskee/don-dep.webp'), '$goc/images/btaskee/don-dep.webp');
    expect(CatalogUi.fileUrl('/files/cong-khai/a.jpg'), '$goc/files/cong-khai/a.jpg');
  });

  test('Key MinIO trần đi qua /files/', () {
    expect(CatalogUi.fileUrl('cong-khai/loai-dich-vu/a.jpg'), '$goc/files/cong-khai/loai-dich-vu/a.jpg');
  });

  test('Rỗng hoặc null thì không có ảnh', () {
    expect(CatalogUi.fileUrl(null), isNull);
    expect(CatalogUi.fileUrl('  '), isNull);
  });
}
