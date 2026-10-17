# Đánh giá đơn: kiểm duyệt & phản hồi — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Chỉ đánh giá đã duyệt mới công khai (kèm phản hồi mới nhất của bTaskee), nút kiểm duyệt CSKH/Marketing đổi dữ liệu thật, và khách được báo khi bTaskee trả lời.

**Architecture:** Mọi quy tắc trạng thái nằm trong `DanhGiaService` (hàm `static` thuần để test + phương thức giao dịch). Controller/Service khác chỉ gọi vào. Trả lời của nhân viên phát `SuKienDanhGia.PhanHoiMoi`, `ThongBaoSuKienService` gửi thông báo sau commit; `ThongBaoService.gui` tự đẩy SSE `thong-bao-moi` nên app tự tải lại.

**Tech Stack:** Spring Boot 3 + JPA + Thymeleaf, JUnit 5; Flutter (Dart), `flutter_test`.

**Spec:** `docs/superpowers/specs/2026-10-17-danh-gia-don-kiem-duyet-design.md` (repo app). Đọc spec trước.

**Đường dẫn:** `WEB = D:/2026/HK1_Nam4/LuanAn/SourceCode/WebsiteCungCapDichVuGiupViec/src` (không phải git repo — không commit), `APP = D:/2026/HK1_Nam4/LuanAn/SourceCode/app_cung_cap_dich_vu_giup_viec` (git, nhánh `feature/Luong`).

## Global Constraints

- Không thêm/xóa bảng hoặc cột CSDL. Trạng thái hợp lệ đúng 3 giá trị: `ChoDuyet`, `HienThi`, `An`.
- **Không tự chạy `./mvnw`** (compile làm server 8083 tải lại, đăng xuất người dùng). Viết xong Task 1–6 rồi hỏi người dùng một lần trước khi chạy `./mvnw test -Dtest=DanhGiaServiceTest`. Không bao giờ chạy `@SpringBootTest`.
- `flutter test`, `flutter analyze` được chạy tự do; hỏi trước `flutter run`.
- Chữ giao diện tiếng Việt có dấu, đúng như spec.
- Repo app: chỉ `git add` file mình sửa (có file chưa commit của người khác). Commit message kết thúc bằng `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Đánh giá `An` vẫn tính vào điểm CTV; không đổi `capNhatDiemCtv`.

## Review Focus

1. Đánh giá `HienThi` bị khách sửa phải biến khỏi trang dịch vụ và trang chủ ngay (cache `DANH_GIA`/`DICH_VU` phải bị xóa) — test `trangThaiSauKhiSua` ở Task 1 + kiểm thủ công.
2. Bình luận của **khách** không bao giờ lộ ra danh sách công khai dù mới hơn phản hồi nhân viên — test `phanHoiMoiNhat_boQuaBinhLuanKhach` ở Task 1.
3. CSKH bấm hàng loạt khi không chọn dòng nào / gửi trạng thái lạ (`DaDuyet` cũ) → 400 + toast lỗi, không đổi dòng — test `loiDoiTrangThai_canChonIt1` ở Task 1.
4. JSON chi tiết dịch vụ cũ không có `phanHoi` hoặc `phanHoi` sai kiểu → app không crash — test `PhanHoiBTaskee.tuJson` Task 7.
5. `trangThai` null/lạ trong map đánh giá của khách → app không hiện dòng trạng thái thay vì crash — test `nhanTrangThaiDanhGia(null)` Task 7.

---

### Task 1: Quy tắc thuần trong DanhGiaService

**Files:**
- Modify: `WEB/main/java/com/example/Service/DanhGiaService.java`
- Create: `WEB/test/java/com/example/Service/DanhGiaServiceTest.java`

**Interfaces — Produces:**
- `public static final Set<String> TRANG_THAI = Set.of("ChoDuyet","HienThi","An")`
- `static String loiTrangThai(String trangThai)` → `null` nếu thuộc `TRANG_THAI`, ngược lại `"Trạng thái không hợp lệ."`
- `static String loiDoiTrangThai(List<Integer> ids, String trangThai)` → `"Chưa chọn đánh giá nào."` khi `ids` null/rỗng, ngược lại `loiTrangThai(trangThai)`
- `static String trangThaiSauKhiSua(String cu)` → `"HienThi"` thành `"ChoDuyet"`, còn lại trả `cu`
- `static boolean laCongKhai(DanhGia dg)` → `"HienThi".equals(dg.getTrangThai())`
- `static PhanHoiDanhGia phanHoiMoiNhatCuaNhanVien(List<PhanHoiDanhGia> traoDoi)` → dòng có `nhanVien != null` với `thoiGian` lớn nhất (hòa thì `id` lớn hơn), hoặc `null`

- [ ] **Step 1: Viết test** (JUnit thuần, không mock, theo kiểu `QuanLyDonServiceTest`):

```java
@Test void loiTrangThai_chiNhanBaGiaTri() {
    assertNull(DanhGiaService.loiTrangThai("ChoDuyet"));
    assertNull(DanhGiaService.loiTrangThai("HienThi"));
    assertNull(DanhGiaService.loiTrangThai("An"));
    assertEquals("Trạng thái không hợp lệ.", DanhGiaService.loiTrangThai("DaDuyet"));
    assertEquals("Trạng thái không hợp lệ.", DanhGiaService.loiTrangThai(null));
}
@Test void loiDoiTrangThai_canChonIt1() {
    assertEquals("Chưa chọn đánh giá nào.", DanhGiaService.loiDoiTrangThai(List.of(), "HienThi"));
    assertEquals("Chưa chọn đánh giá nào.", DanhGiaService.loiDoiTrangThai(null, "HienThi"));
    assertEquals("Trạng thái không hợp lệ.", DanhGiaService.loiDoiTrangThai(List.of(1), "DaAn"));
    assertNull(DanhGiaService.loiDoiTrangThai(List.of(1, 2), "An"));
}
@Test void trangThaiSauKhiSua_hienThiVeChoDuyet() {
    assertEquals("ChoDuyet", DanhGiaService.trangThaiSauKhiSua("HienThi"));
    assertEquals("An", DanhGiaService.trangThaiSauKhiSua("An"));
    assertEquals("ChoDuyet", DanhGiaService.trangThaiSauKhiSua("ChoDuyet"));
}
@Test void laCongKhai_chiHienThi() { /* HienThi → true; ChoDuyet, An, null → false */ }
@Test void phanHoiMoiNhat_boQuaBinhLuanKhach() {
    // nv1 lúc 10:00 (nhanVien != null), kh lúc 11:00 (nhanVien null), nv2 lúc 10:30
    assertSame(nv2, DanhGiaService.phanHoiMoiNhatCuaNhanVien(List.of(nv1, kh, nv2)));
}
@Test void phanHoiMoiNhat_nullKhiChuaCoNhanVien() {
    assertNull(DanhGiaService.phanHoiMoiNhatCuaNhanVien(List.of(kh)));
    assertNull(DanhGiaService.phanHoiMoiNhatCuaNhanVien(List.of()));
}
```
Dựng `PhanHoiDanhGia` bằng builder; `NhanVien` chỉ cần `new NhanVien()`.

- [ ] **Step 2: Thêm 5 hàm + hằng ở trên vào `DanhGiaService`** (phần NỘI BỘ). Không chạy compile (xem Global Constraints).

---

### Task 2: Phương thức kiểm duyệt & danh sách công khai

**Files:**
- Modify: `WEB/main/java/com/example/Service/DanhGiaService.java`
- Modify: `WEB/main/java/com/example/Repository/DanhGiaRepository.java` (thêm `long countByTrangThai(String trangThai)`)
- Modify: `WEB/main/java/com/example/Service/CustomerApiService.java:~930-952, ~1749-1757`
- Modify: `WEB/main/java/com/example/API/ReviewApiController.java:~80-90`
- Modify: `WEB/main/java/com/example/Service/CatalogService.java:~355-380`, `WEB/main/java/com/example/DTO/view/DanhGiaView.java`

**Interfaces:**
- Consumes: Task 1.
- Produces (trong `DanhGiaService`):
  - `int doiTrangThai(List<Integer> ids, String trangThai)` — `loiDoiTrangThai(ids, trangThai)` khác null → `IllegalArgumentException` với thông báo đó; id không tồn tại bỏ qua; `saveAll`; `xoaCache()`; trả số đã đổi.
  - `long demChoDuyet()` → `countByTrangThai("ChoDuyet")`.
  - `@Transactional(readOnly=true) Map<String,Object> phanHoiCongKhai(Integer danhGiaId)` → `{noiDung, thoiGian}` từ `phanHoiMoiNhatCuaNhanVien(findByDanhGia_IdOrderByThoiGianAscIdAsc(id))`, hoặc `null`.
  - `@Transactional(readOnly=true) List<Map<String,Object>> congKhaiTheoDichVu(Integer dichVuId)` — lọc như `CustomerApiService.getReviewsByService` hiện tại (đơn có chi tiết chứa dịch vụ) + `laCongKhai`; sắp `ngayDanhGia` giảm dần (null cuối); mỗi map: `id, khachHang (hoTen|null), diem ((cl+td)/2.0), nhanXet, ngayDanhGia, phanHoi`.
- `CustomerApiService.getReviewsByService(Integer)` đổi kiểu trả về thành `List<Map<String,Object>>` = `danhGiaService.congKhaiTheoDichVu(id)`.

- [ ] **Step 1: Thêm `doiTrangThai`, `demChoDuyet`, `phanHoiCongKhai`, `congKhaiTheoDichVu`** như trên.
- [ ] **Step 2: Trong `suaDanhGia`**, ngay trước `danhGiaRepository.save(dg)`: `dg.setTrangThai(trangThaiSauKhiSua(dg.getTrangThai()))`.
- [ ] **Step 3: `CustomerApiService` chi tiết dịch vụ** (~933): `danhGias = getReviewsByService(dv.getId())` (list map); `soLuongDanhGia = danhGias.size()`; `diemDanhGiaTrungBinh` = trung bình `diem` (mặc định 5.0, scale 1 HALF_UP); `danhGias` = 10 phần tử đầu. Bỏ khối build map cũ.
- [ ] **Step 4: `ReviewApiController.getReviewsByService`** đổi generic thành `ApiResponse<List<Map<String,Object>>>`; bỏ import `DanhGia` nếu thừa.
- [ ] **Step 5: `DanhGiaView`** thêm `private String phanHoi;`. `CatalogService.getDanhGiaNoiBat` gán `.phanHoi(p == null ? null : (String) p.get("noiDung"))` với `p = danhGiaService.phanHoiCongKhai(dg.getId())` (inject `DanhGiaService`; nếu gây vòng phụ thuộc thì gọi `PhanHoiDanhGiaRepository` + `DanhGiaService.phanHoiMoiNhatCuaNhanVien` tĩnh).

---

### Task 3: Sự kiện & thông báo phản hồi

**Files:**
- Create: `WEB/main/java/com/example/SuKien/SuKienDanhGia.java`
- Modify: `WEB/main/java/com/example/Service/DanhGiaService.java` (constructor + `traLoiCuaNhanVien`)
- Modify: `WEB/main/java/com/example/Service/ThongBaoSuKienService.java`

**Interfaces — Produces:** `SuKienDanhGia.PhanHoiMoi(Integer danhGiaId)` (record trong lớp `final` có constructor private, javadoc tiếng Việt như `SuKienDon`).

- [ ] **Step 1: Tạo `SuKienDanhGia`.**
- [ ] **Step 2:** `DanhGiaService` nhận thêm `ApplicationEventPublisher publisher`; cuối `traLoiCuaNhanVien`, trước `return`: `publisher.publishEvent(new SuKienDanhGia.PhanHoiMoi(dg.getId()))`.
- [ ] **Step 3: `ThongBaoSuKienService.khiCoPhanHoiDanhGia(SuKienDanhGia.PhanHoiMoi e)`** với đúng 3 annotation của `khiDonDoiTrangThai` (`@Async("taskExecutor")`, `@TransactionalEventListener(fallbackExecution = true)`, `@Transactional(propagation = Propagation.REQUIRES_NEW)`). Nạp `DanhGia` (inject `DanhGiaRepository`, `PhanHoiDanhGiaRepository`), lấy `don = dg.getDonDat()`, phản hồi = `DanhGiaService.phanHoiMoiNhatCuaNhanVien(...)`; không có đơn/phản hồi thì return. Gửi `guiKhach(don, tieuDe, noiDung)`:
  - `tieuDe = "bTaskee đã phản hồi đánh giá đơn " + don.getMaDonDat()`
  - `noiDung = trich + " Xem chi tiết trong đơn hàng của bạn."` với `trich` = nội dung phản hồi, nếu dài hơn 200 ký tự thì 200 ký tự đầu + `"…"`.

---

### Task 4: Trang CSKH kiểm duyệt thật

**Files:**
- Modify: `WEB/main/java/com/example/Controller/CSKHController.java:~110-125 (dashboard), 368-412`
- Modify: `WEB/main/resources/templates/cskh/danh-gia.html`
- Modify: `WEB/main/resources/templates/cskh/dashboard.html`

**Interfaces — Consumes:** `doiTrangThai`, `demChoDuyet` (Task 2).

- [ ] **Step 1: Endpoint** `@PostMapping("/danh-gia/trang-thai") @ResponseBody ResponseEntity<?> doiTrangThaiDanhGia(@RequestParam List<Integer> ids, @RequestParam String trangThai)` → `ok(Map.of("soLuong", n))`; `IllegalArgumentException` → `badRequest().body(Map.of("message", ...))` (giống `traLoiDanhGia`).
- [ ] **Step 2: `danhGia(Model, @RequestParam(required=false) String trangThai)`**: sắp `danhGiaList` theo `id` giảm dần; thêm `choDuyetCount = danhGiaService.demChoDuyet()`, `trangThaiLoc = trangThai`; bỏ `phanHoiList`, `congTacViens`, `khachHangs` khi template không còn dùng (grep trước khi xóa).
- [ ] **Step 3: Template — xóa** nút "Thêm đánh giá" + `addReviewModal`, nút Sửa + `editReviewModal`, nút Xóa + `deleteReviewModal`, nút "Xóa đã chọn", nút Ẩn chỉ toast, và mọi hàm JS của chúng (`openEditReviewModal`, `saveEditReview`, `deleteCurrentEditReview`, `deleteReview`, `executeDeleteReview`, `bulkDeleteReviews`, add-review). Làm ở cả bảng và dạng thẻ (dòng ~207-250).
- [ ] **Step 4: Template — thêm** trên mỗi dòng/thẻ (có `data-id`): nút **Duyệt** (`ti-check`) hiện khi trạng thái `ChoDuyet`/`An`, **Ẩn** (`ti-eye-off`) khi `HienThi`, **Chờ duyệt** (`ti-clock`, nhỏ) khi khác `ChoDuyet`. Hàm JS `doiTrangThai(ids, trangThai)` gọi `fetch('/cskh/danh-gia/trang-thai', {method:'POST', body: URLSearchParams với ids lặp lại + trangThai})` theo đúng cách `tra-loi` đang gửi (cùng header/CSRF nếu có). Thành công: cập nhật `data-status`, badge (3 badge sẵn có), nút hiển thị của các dòng đó, `CSKH.toast('Đã cập nhật ' + soLuong + ' đánh giá')`; lỗi: `CSKH.toast(message, 'error')`, không đổi dòng. `bulkApprove`/`bulkHide` gọi `doiTrangThai(idsĐãChọn, 'HienThi'|'An')`, rồi `clearBulk()`.
- [ ] **Step 5: Thẻ thống kê "Chờ duyệt"** (`choDuyetCount`) cạnh các thẻ có sẵn. Khi tải trang, nếu `trangThaiLoc` có giá trị thì đặt `#statusFilter` và gọi `filterReviews()`.
- [ ] **Step 6: Dashboard:** controller thêm `danhGiaChoDuyet = danhGiaService.demChoDuyet()`; `dashboard.html` thêm ô "Đánh giá chờ duyệt" (cùng kiểu `stat-value` dòng 44) bọc link `/cskh/danh-gia?trangThai=ChoDuyet`.

---

### Task 5: Trang Marketing dùng chung trạng thái

**Files:**
- Modify: `WEB/main/java/com/example/Controller/MarketingController.java:320-328`
- Modify: `WEB/main/resources/templates/marketing/danh-gia.html:~88-140`

- [ ] **Step 1:** `capNhatTrangThaiDanhGia(id, trangThai, RedirectAttributes ra)` gọi `danhGiaService.doiTrangThai(List.of(id), trangThai)`; `IllegalArgumentException` → `ra.addFlashAttribute("error", msg)` (dùng tên flash mà template Marketing đang hiển thị; nếu không có thì thêm khối hiện `error`). Sửa comment "Ghim/Bỏ ghim" thành "Hiển thị/Ẩn đánh giá".
- [ ] **Step 2: Template:** tiêu đề cột `Hiển thị trang chủ` → `Trạng thái`; badge: `ChoDuyet` "Chờ duyệt" (`badge-warning`), `HienThi` "Đang hiển thị" (`badge-success`), `An` "Đã ẩn" (`badge-secondary`). Nút: **Hiển thị** (value `HienThi`) khi khác `HienThi`, **Ẩn** (value `An`) khi `HienThi`. Thêm dòng gợi ý dưới tiêu đề: "Trang chủ hiện 6 đánh giá đang hiển thị mới nhất có nhận xét."

---

### Task 6: Giao diện khách trên website

**Files:**
- Modify: `WEB/main/resources/templates/khach-hang/don-chi-tiet.html:~106-150`
- Modify: `WEB/main/resources/templates/site/dich-vu-thong-tin.html:47-52`
- Modify: `WEB/main/resources/templates/index.html:~142-160`

- [ ] **Step 1: `don-chi-tiet.html`**, ngay dưới dòng "Gửi lúc" (113): `<p class="hint">` với chữ theo `dg.trangThai`: `ChoDuyet` → "Đang chờ bTaskee duyệt", `HienThi` → "Đang hiển thị công khai", `An` → "Không hiển thị công khai"; giá trị khác → không hiện. Trong form sửa, khi `dg.trangThai == 'HienThi'`: gợi ý "Sau khi sửa, đánh giá sẽ chờ duyệt lại trước khi hiển thị công khai."
- [ ] **Step 2: `dich-vu-thong-tin.html`** trong `.review-item`: `<div class="review-reply" th:if="${r.phanHoi != null}"><b>Phản hồi từ bTaskee</b><p th:text="${r.phanHoi.noiDung}"></p></div>`. CSS trong file (hoặc stylesheet site đang dùng): thụt lề trái 12px, viền trái 3px màu chủ đạo, chữ 0.9em.
- [ ] **Step 3: `index.html`** trong `.review-card`, sau `.review-content`: khối tương tự với `th:if="${dg.phanHoi != null}"`, `th:text="${dg.phanHoi}"`.
- [ ] **Step 4: Kiểm tra backend (cần người dùng đồng ý):** hỏi người dùng rồi chạy `./mvnw test -Dtest=DanhGiaServiceTest` trong `WebsiteCungCapDichVuGiupViec`. Expected: `Tests run: 6, Failures: 0, Errors: 0`, BUILD SUCCESS. Lỗi compile ở Task 1–6 sửa tại đây.

---

### Task 7: App — trạng thái đánh giá & phản hồi công khai

**Files:**
- Modify: `APP/lib/widgets/danh_gia_don.dart`
- Create: `APP/lib/widgets/phan_hoi_btaskee.dart`
- Modify: `APP/lib/screens/customer/service_detail_screen.dart:354-395`
- Create: `APP/test/danh_gia_don_test.dart`

**Interfaces — Produces:**
- Trong `danh_gia_don.dart` (top-level): `String? nhanTrangThaiDanhGia(Object? trangThai)` → `'Đang chờ bTaskee duyệt'` / `'Đang hiển thị công khai'` / `'Không hiển thị công khai'` cho `ChoDuyet` / `HienThi` / `An`, `null` cho giá trị khác.
- `phan_hoi_btaskee.dart`: `class PhanHoiBTaskee extends StatelessWidget { final String noiDung; ... static PhanHoiBTaskee? tuJson(Object? phanHoi); }` — `tuJson` trả widget khi `phanHoi` là `Map` có `noiDung` chuỗi không rỗng, ngược lại `null`. Hiển thị tiêu đề "Phản hồi từ bTaskee" (đậm, 12) + nội dung (13, `AppColors.textSecondary`), viền trái 3px `AppColors.brand500`, padding trái 10.

- [ ] **Step 1: Viết test** `test/danh_gia_don_test.dart`:

```dart
test('nhãn trạng thái', () {
  expect(nhanTrangThaiDanhGia('ChoDuyet'), 'Đang chờ bTaskee duyệt');
  expect(nhanTrangThaiDanhGia('HienThi'), 'Đang hiển thị công khai');
  expect(nhanTrangThaiDanhGia('An'), 'Không hiển thị công khai');
  expect(nhanTrangThaiDanhGia(null), isNull);
  expect(nhanTrangThaiDanhGia('DaDuyet'), isNull);
});
test('PhanHoiBTaskee.tuJson an toàn', () {
  expect(PhanHoiBTaskee.tuJson(null), isNull);
  expect(PhanHoiBTaskee.tuJson('abc'), isNull);
  expect(PhanHoiBTaskee.tuJson({'noiDung': ''}), isNull);
  expect(PhanHoiBTaskee.tuJson({'noiDung': 'Cảm ơn bạn'})?.noiDung, 'Cảm ơn bạn');
});
testWidgets('hiện khối phản hồi', (t) async {
  await t.pumpWidget(const MaterialApp(home: Scaffold(body: PhanHoiBTaskee(noiDung: 'Cảm ơn bạn'))));
  expect(find.text('Phản hồi từ bTaskee'), findsOneWidget);
  expect(find.text('Cảm ơn bạn'), findsOneWidget);
});
```

- [ ] **Step 2: Chạy** `flutter test test/danh_gia_don_test.dart` trong `APP`. Expected: FAIL (chưa có `nhanTrangThaiDanhGia`, `PhanHoiBTaskee`).
- [ ] **Step 3: Thêm `nhanTrangThaiDanhGia`** vào `danh_gia_don.dart`; trong phần đã đánh giá, dưới hàng "Gửi lúc …" hiện `Text(nhan, fontSize 12, AppColors.textMuted)` khi khác null. Trong `_formDanhGia()`, khi `_dg?['trangThai'] == 'HienThi'`, thêm gợi ý "Sau khi sửa, đánh giá sẽ chờ duyệt lại trước khi hiển thị công khai."
- [ ] **Step 4: Tạo `phan_hoi_btaskee.dart`**; trong `service_detail_screen.dart` `_buildDanhGia()`, sau khối `nhanXet`: `if (PhanHoiBTaskee.tuJson(d['phanHoi']) case final w?) ...[const SizedBox(height: 6), w]` (hoặc biến tạm tương đương).
- [ ] **Step 5: Chạy** `flutter test` và `flutter analyze` trong `APP`. Expected: tất cả test PASS; analyze không có lỗi/cảnh báo mới ở các file đã sửa.
- [ ] **Step 6: Commit**

```bash
git add lib/widgets/danh_gia_don.dart lib/widgets/phan_hoi_btaskee.dart lib/screens/customer/service_detail_screen.dart test/danh_gia_don_test.dart
git commit -m "feat(danh-gia): hien trang thai duyet va phan hoi cong khai cua bTaskee

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 8: Kiểm thủ công (người dùng)

- [ ] Sau khi server 8083 tải lại: CSKH duyệt một đánh giá → xuất hiện trên trang dịch vụ (web + app); Ẩn → biến mất; chọn nhiều → Duyệt tất cả / Ẩn đã chọn đổi badge.
- [ ] CSKH trả lời → app nhận thông báo "bTaskee đã phản hồi đánh giá đơn DD-…", màn chi tiết đơn đang mở tự tải lại; trang dịch vụ hiện "Phản hồi từ bTaskee".
- [ ] Khách sửa đánh giá đang hiển thị → trạng thái "Đang chờ bTaskee duyệt", biến khỏi trang dịch vụ và trang chủ.
- [ ] Marketing: cột "Trạng thái" đúng 3 badge; Hiển thị/Ẩn đổi được.
