# Đặt dịch vụ trên app giống website – Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Màn đặt dịch vụ trên app Flutter đi đúng 5 bước như website (Dịch vụ → Hình thức → Thời gian → Xác nhận → Thanh toán), cùng ràng buộc ngày, màn QR chuyển khoản và đồng hồ chờ ở chi tiết đơn.

**Architecture:** Logic nghiệp vụ phía app tách thành 4 lớp Dart thuần có unit test (`RangBuocNgayDat`, `NhomDichVu`, `BuocDat`, `DongHo`); `BookingScreen` thành khung 5 bước ráp từ một widget mỗi bước; dữ liệu lấy từ API sẵn có. Backend Spring sửa 3 chỗ nhỏ: endpoint xác nhận chuyển khoản, số giây đếm ngược ở chi tiết đơn, ảnh dịch vụ trong danh sách.

**Tech Stack:** Flutter 3.38 / Dart, `flutter_test`, `http` (qua `ApiClient`); Spring Boot 3 / Java, JUnit 5.

**Spec:** `docs/superpowers/specs/2026-10-17-app-dat-dich-vu-giong-web-design.md` (repo app).

## Global Constraints

- Không đổi cấu trúc CSDL. `hinhThucThanhToan` ∈ `"TienMat" | "ChuyenKhoan"` (đúng chữ hoa/thường).
- Theo lần: ngày làm ≤ hôm nay + 1 tháng; gói tháng: ngày bắt đầu ≤ hôm nay + 3 tháng; cộng tháng kiểu Java `plusMonths` (31/01 + 1 tháng = 28/02 hoặc 29/02).
- Không chọn ngày quá khứ; giờ bắt đầu sau hiện tại ít nhất 1 giờ; gói đủ buổi theo `LichGoiThang`; địa chỉ có `khuVucId`.
- Câu lỗi ngày giờ trùng máy chủ (`RangBuocNgayDat.java`), nguyên văn:
  `"Vui lòng chọn ngày và giờ bắt đầu."`, `"Ngày thực hiện không được ở quá khứ."`, `"Đặt theo lần chỉ được chọn ngày trong vòng 1 tháng tới (đến dd/MM/yyyy)."`, `"Gói tháng chỉ được bắt đầu trong vòng 3 tháng tới (đến dd/MM/yyyy)."`, `"Giờ bắt đầu cần sau thời điểm hiện tại ít nhất 1 giờ."`
- Đồng hồ đếm lùi từ số giây máy chủ trả, không tự tính từ giờ thiết bị.
- App: test bằng `flutter test test/<file>_test.dart`, kiểm tĩnh `flutter analyze`. Không chạy `flutter run` khi chưa hỏi người dùng.
- Backend (thư mục `../WebsiteCungCapDichVuGiupViec`, **không phải git repo**, bỏ bước commit): hỏi người dùng trước khi chạy `./mvnw`; chỉ chạy unit test thuần `./mvnw -q test -Dtest='com.example.Service.*Test'` (không chạy `@SpringBootTest` vì ghi vào CSDL thật).
- Commit phía app trên nhánh hiện tại `feature/Luong`; chỉ `git add` đúng file của task (nhánh đang có thay đổi dở khác của người dùng). Commit message kết thúc bằng dòng `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Chuỗi giao diện tiếng Việt có dấu.

## Review Focus

1. Cộng tháng ở ngày cuối tháng (31/01 → 28/02; 30/11 + 3 tháng → 28/02 năm sau) – Dart `DateTime(y, m + 1, d)` tràn sang tháng sau nếu không kẹp (Task 1).
2. Gửi sai chữ phương thức thanh toán → máy chủ báo "Phương thức thanh toán không hợp lệ." hoặc âm thầm thành tiền mặt (Task 5: test thân request).
3. Biến thể không có `maDichVu` (dữ liệu cũ) phải thành nhóm riêng theo `id`, không gộp chung một nhóm "null" (Task 2).
4. Mở màn đặt từ một dịch vụ chỉ có gói tháng → mở ở bước 3 với `loaiHinhDat = GoiThang`, không kẹt ở bước 2 với lựa chọn bị mờ (Task 3).
5. Máy chủ trả `soGiayConLai*` âm hoặc null → đồng hồ hiện `00:00` / ẩn banner, không ném lỗi (Task 4, Task 9).

---

### Task 0: Backend – xác nhận chuyển khoản, đồng hồ, ảnh dịch vụ

*(Làm trước vì Task 5–9 của app gọi các trường này. Thư mục `../WebsiteCungCapDichVuGiupViec`, không commit.)*

**Files:**
- Modify: `src/main/java/com/example/Service/HanNhanDonService.java`
- Modify: `src/main/java/com/example/Service/CustomerApiService.java` (`getBookingDetail`, `getServices`)
- Modify: `src/main/java/com/example/API/CustomerBookingController.java`
- Test: `src/test/java/com/example/Service/HanNhanDonServiceTest.java`

**Interfaces:**
- Produces:
  - `HanNhanDonService`: `public static Long soGiayConLai(LocalDateTime han, LocalDateTime bayGio)` – `han == null` → `null`; còn lại `max(0, giây giữa bayGio và han)`.
  - `GET /v1/customer/bookings/{id}` thêm khoá: `soGiayConLaiThanhToan` (Long|null, từ `hanThanhToanNeuDangCho`), `soGiayConLaiNhan` (Long|null, từ `hanNhanNeuDangCho`), `soPhutNhanDon` (long), `soPhutThanhToan` (long).
  - `POST /v1/customer/bookings/{id}/confirm-transfer` → `ApiResponse.ok("Đã ghi nhận thanh toán.", xacNhanThanhToanChuyenKhoan(id, "Khách xác nhận trên ứng dụng"))`; `IllegalArgumentException` → 400 với `e.getMessage()`.
  - `GET /v1/services`: mỗi phần tử thêm `hinhAnhUrl` = `minioService.getViewUrl(dv.getHinhAnh())` (null nếu chưa có ảnh).

- [ ] **Step 1: Viết test thất bại** trong `HanNhanDonServiceTest`: `soGiayConLai(null, t) == null`; `soGiayConLai(t.plusSeconds(907), t) == 907L`; `soGiayConLai(t.minusSeconds(5), t) == 0L`.
- [ ] **Step 2: Chạy** (hỏi người dùng trước) `./mvnw -q test -Dtest=HanNhanDonServiceTest` — Expected: FAIL (cannot find symbol `soGiayConLai`).
- [ ] **Step 3: Cài đặt** `soGiayConLai`; trong `getBookingDetail` gắn 4 khoá (dùng `HanNhanDonService` qua trường `@Autowired`, như các service khác đang làm); thêm endpoint `confirm-transfer`; thêm `hinhAnhUrl` trong `getServices` (inject `MinioService` qua `@Autowired` nếu `CustomerApiService` chưa có).
- [ ] **Step 4: Chạy** `./mvnw -q test -Dtest='com.example.Service.*Test'` — Expected: PASS toàn bộ (≥ 35 test).

### Task 1: Ràng buộc ngày đặt (Dart)

**Files:**
- Create: `lib/services/rang_buoc_ngay_dat.dart`
- Test: `test/rang_buoc_ngay_dat_test.dart`

**Interfaces:**
- Produces:
  - `class RangBuocNgayDat` (chỉ static):
    - `static DateTime congThang(DateTime ngay, int soThang)` – chỉ phần ngày, kẹp về ngày cuối tháng đích.
    - `static DateTime ngayToiDa(String loaiHinhDat, DateTime homNay)` – `"GoiThang"` → `congThang(homNay, 3)`, còn lại → `congThang(homNay, 1)`.
    - `static String? loiNgayDat(String loaiHinhDat, DateTime? ngay, int? gio, int? phut, DateTime bayGio)` – `null` nếu hợp lệ; thứ tự kiểm và câu lỗi như Global Constraints.

- [ ] **Step 1: Viết test thất bại** `test/rang_buoc_ngay_dat_test.dart`, `bayGio = DateTime(2026, 1, 31, 8, 0)`:
  - `congThang(DateTime(2026,1,31), 1) == DateTime(2026,2,28)`; `congThang(DateTime(2028,1,31), 1) == DateTime(2028,2,29)`; `congThang(DateTime(2026,11,30), 3) == DateTime(2027,2,28)`
  - `ngayToiDa('TheoLan', DateTime(2026,1,31)) == DateTime(2026,2,28)`; `ngayToiDa('GoiThang', DateTime(2026,1,31)) == DateTime(2026,4,30)`
  - `loiNgayDat('TheoLan', DateTime(2026,2,28), 9, 0, bayGio) == null`; `loiNgayDat('TheoLan', DateTime(2026,3,1), 9, 0, bayGio)` == `'Đặt theo lần chỉ được chọn ngày trong vòng 1 tháng tới (đến 28/02/2026).'`
  - `loiNgayDat('GoiThang', DateTime(2026,4,30), 9, 0, bayGio) == null`; `loiNgayDat('GoiThang', DateTime(2026,5,1), 9, 0, bayGio)` == `'Gói tháng chỉ được bắt đầu trong vòng 3 tháng tới (đến 30/04/2026).'`
  - quá khứ `DateTime(2026,1,30)` → `'Ngày thực hiện không được ở quá khứ.'`; `DateTime(2026,1,31)` lúc `8:30` → `'Giờ bắt đầu cần sau thời điểm hiện tại ít nhất 1 giờ.'`; lúc `9:00` → `null`
  - `ngay == null` hoặc `gio == null` → `'Vui lòng chọn ngày và giờ bắt đầu.'`
- [ ] **Step 2: Chạy** `flutter test test/rang_buoc_ngay_dat_test.dart` — Expected: FAIL (không tìm thấy `rang_buoc_ngay_dat.dart`).
- [ ] **Step 3: Cài đặt** `RangBuocNgayDat` trong `lib/services/rang_buoc_ngay_dat.dart`; `congThang` = ngày min(ngày gốc, số ngày của tháng đích) với tháng đích `DateTime(y, m + soThang, 1)`.
- [ ] **Step 4: Chạy lại** — Expected: PASS.
- [ ] **Step 5: Commit**
```bash
git add lib/services/rang_buoc_ngay_dat.dart test/rang_buoc_ngay_dat_test.dart
git commit -m "feat(dat-dich-vu): rang buoc ngay dat theo lan 1 thang, goi 3 thang"
```

### Task 2: Gom dịch vụ theo mã (Dart)

**Files:**
- Create: `lib/services/nhom_dich_vu.dart`
- Test: `test/nhom_dich_vu_test.dart`

**Interfaces:**
- Consumes: kết quả `ServiceCatalogApiService.getServices(loaiDichVuId: …)` – `List<Map<String, dynamic>>` có `id`, `maDichVu`, `tenDichVu`, `loaiHinhDat`, `donGiaThamKhao`, `thoiGianThucHienPhut`, `soBuoiGoi`, `giaGoc`, `hinhAnhUrl` (Task 0).
- Produces:
  - `class NhomDichVu { final String ma; final String ten; final String? anh; final int giaTu; final bool coTheoLan; final bool coGoiThang; final List<Map<String, dynamic>> bienThe; List<Map<String, dynamic>> bienTheTheoLoai(String loaiHinhDat); }`
  - `static List<NhomDichVu> gom(List<Map<String, dynamic>> dichVus)` – giữ thứ tự xuất hiện đầu tiên của mã; `ma` rỗng/null thì dùng `'id-<id>'`; `ten` = `tenNhom(tenDichVu đầu tiên)`; `giaTu` = giá dương nhỏ nhất (0 nếu không có); `anh` = `hinhAnhUrl` khác null đầu tiên; `bienThe` sắp: theo lần trước, rồi giá tăng dần.
  - `static String tenNhom(String tenDichVu)` – bỏ phần `" (…)"` cuối.
  - `static NhomDichVu? timTheoDichVuId(List<NhomDichVu> ds, int dichVuId)`.

- [ ] **Step 1: Viết test thất bại** với danh sách mẫu: `DV101` 3 biến thể theo lần (`(2 giờ)` 216000, `(3 giờ)` 270000, `(4 giờ)` 342000) + 1 gói 1590000; `DV102` chỉ theo lần; một dòng `maDichVu: null, id: 99`. Kiểm:
  - `gom(...).map((g) => g.ma)` == `['DV101', 'DV102', 'id-99']`
  - nhóm DV101: `ten == 'Dọn dẹp nhà theo giờ'`, `giaTu == 216000`, `coTheoLan && coGoiThang`, `bienTheTheoLoai('TheoLan').map((b) => b['donGiaThamKhao'])` == `[216000, 270000, 342000]`
  - nhóm DV102: `coGoiThang == false`
  - `timTheoDichVuId(ds, <id của DV101 (3 giờ)>)!.ma == 'DV101'`; `timTheoDichVuId(ds, 12345) == null`
  - `tenNhom('Tổng vệ sinh nhà (tối đa 60m², 2 người/3 giờ)') == 'Tổng vệ sinh nhà'`
- [ ] **Step 2: Chạy** `flutter test test/nhom_dich_vu_test.dart` — Expected: FAIL.
- [ ] **Step 3: Cài đặt** `NhomDichVu` trong `lib/services/nhom_dich_vu.dart` (đọc số bằng `CatalogUi.toInt`).
- [ ] **Step 4: Chạy lại** — Expected: PASS.
- [ ] **Step 5: Commit** `git add lib/services/nhom_dich_vu.dart test/nhom_dich_vu_test.dart` + `git commit -m "feat(dat-dich-vu): gom dich vu theo ma"`.

### Task 3: Quy tắc chuyển bước (Dart)

**Files:**
- Create: `lib/services/buoc_dat.dart`
- Test: `test/buoc_dat_test.dart`

**Interfaces:**
- Consumes: `NhomDichVu` (Task 2), `RangBuocNgayDat.ngayToiDa` (Task 1).
- Produces:
  - `class DuLieuDat { NhomDichVu? nhom; String? loaiHinhDat; int? dichVuId; bool daChonGio; bool coDiaChiTrongKhuVuc; bool coDiaChiNao; bool goiDuBuoi; String? hinhThucThanhToan; }` (constructor có tham số đặt tên, mặc định false/null).
  - `class BuocDat` (static):
    - `static bool boQuaBuoc2(NhomDichVu nhom)` – true khi nhóm chỉ có một loại.
    - `static String loaiMacDinh(NhomDichVu nhom, {String? uuTien})` – `uuTien` nếu nhóm có loại đó, không thì `TheoLan` nếu có, còn lại `GoiThang`.
    - `static int buocMoDau(NhomDichVu nhom)` – `boQuaBuoc2 ? 3 : 2`.
    - `static int buocKe(int buoc, NhomDichVu nhom)` / `static int buocLui(int buoc, NhomDichVu nhom)` – bỏ qua bước 2 khi `boQuaBuoc2`; giới hạn 1..5.
    - `static String? loiBuoc(int buoc, DuLieuDat d)` – câu lỗi (nguyên văn, giống web):
      1: `'Vui lòng chọn dịch vụ.'`; 2: `'Vui lòng chọn theo lần hoặc gói tháng.'`; 3 theo thứ tự: `'Vui lòng chọn thời lượng / gói.'`, `'Vui lòng chọn giờ bắt đầu.'`, `'Các thứ đã chọn chưa đủ số buổi của gói.'` (chỉ khi `GoiThang`), `'Các địa chỉ đã lưu nằm ngoài khu vực phục vụ. Vui lòng thêm địa chỉ khác.'` (khi `coDiaChiNao && !coDiaChiTrongKhuVuc`), `'Vui lòng chọn địa chỉ làm việc.'` (khi `!coDiaChiNao`); 4: null; 5: `'Vui lòng chọn phương thức thanh toán.'`.
    - `static DateTime keoNgay(DateTime ngay, String loaiHinhDat, DateTime homNay)` – trả `min(ngay, RangBuocNgayDat.ngayToiDa(loai, homNay))`.

- [ ] **Step 1: Viết test thất bại** (dùng nhóm mẫu dựng tay `NhomDichVu(...)`):
  - nhóm chỉ `GoiThang`: `boQuaBuoc2 == true`, `buocMoDau == 3`, `loaiMacDinh(nhom) == 'GoiThang'`, `buocKe(1, nhom) == 3`, `buocLui(3, nhom) == 1`
  - nhóm đủ hai loại: `buocMoDau == 2`, `buocKe(1) == 2`, `buocLui(3) == 2`, `buocKe(5) == 5`, `buocLui(1) == 1`, `loaiMacDinh(nhom, uuTien: 'GoiThang') == 'GoiThang'`
  - `loiBuoc(1, DuLieuDat())` == `'Vui lòng chọn dịch vụ.'`; `loiBuoc(3, DuLieuDat(nhom: n, loaiHinhDat: 'GoiThang', dichVuId: 1, daChonGio: true, coDiaChiNao: true, coDiaChiTrongKhuVuc: true, goiDuBuoi: false))` == `'Các thứ đã chọn chưa đủ số buổi của gói.'`; địa chỉ ngoài khu vực → câu tương ứng; `loiBuoc(4, DuLieuDat()) == null`; `loiBuoc(5, DuLieuDat()) == 'Vui lòng chọn phương thức thanh toán.'`
  - `keoNgay(DateTime(2026,3,20), 'TheoLan', DateTime(2026,1,31)) == DateTime(2026,2,28)`; `keoNgay(DateTime(2026,3,20), 'GoiThang', DateTime(2026,1,31)) == DateTime(2026,3,20)`
- [ ] **Step 2: Chạy** `flutter test test/buoc_dat_test.dart` — Expected: FAIL.
- [ ] **Step 3: Cài đặt** `DuLieuDat`, `BuocDat` trong `lib/services/buoc_dat.dart`.
- [ ] **Step 4: Chạy lại** — Expected: PASS.
- [ ] **Step 5: Commit** `git add lib/services/buoc_dat.dart test/buoc_dat_test.dart` + `git commit -m "feat(dat-dich-vu): quy tac chuyen 5 buoc"`.

### Task 4: Đồng hồ đếm lùi (Dart)

**Files:**
- Create: `lib/services/dong_ho.dart`
- Test: `test/dong_ho_test.dart`

**Interfaces:**
- Produces: `class DongHo` (static): `static String mmss(int? giay)` – null hoặc ≤ 0 → `'00:00'`, ngược lại `'MM:SS'` có số 0 đầu; `static bool hetGio(int? giay)` – null hoặc ≤ 0.

- [ ] **Step 1: Viết test thất bại**: `mmss(907) == '15:07'`, `mmss(59) == '00:59'`, `mmss(0) == '00:00'`, `mmss(-5) == '00:00'`, `mmss(null) == '00:00'`, `hetGio(1) == false`, `hetGio(0) == true`, `hetGio(null) == true`.
- [ ] **Step 2: Chạy** `flutter test test/dong_ho_test.dart` — Expected: FAIL.
- [ ] **Step 3: Cài đặt** `DongHo` trong `lib/services/dong_ho.dart`.
- [ ] **Step 4: Chạy lại** — Expected: PASS.
- [ ] **Step 5: Commit** `git add lib/services/dong_ho.dart test/dong_ho_test.dart` + `git commit -m "feat(dat-dich-vu): dinh dang dong ho dem lui"`.

### Task 5: Tầng API của app

**Files:**
- Modify: `lib/services/booking_api_service.dart`
- Test: `test/booking_api_body_test.dart`

**Interfaces:**
- Consumes: endpoint Task 0.
- Produces:
  - `static Map<String, dynamic> bodyTaoDon({...cùng tham số đặt tên như createBooking, thay phuongThucThanhToan bằng required String hinhThucThanhToan})` – thân JSON của `POST /v1/bookings`, có khoá `'hinhThucThanhToan'`, **không** có khoá `'phuongThucThanhToan'`; `createBooking(...)` gọi lại nó.
  - `Future<ApiResponse<List<Map<String, dynamic>>>> getAvailablePromotions({required int dichVuId, required String loaiHinhDat, String? ngayThucHien, String? gioBatDau})` → `POST /v1/bookings/available-promotions`.
  - `Future<ApiResponse<Map<String, dynamic>>> confirmTransfer(int donDatId)` → `POST /v1/customer/bookings/$donDatId/confirm-transfer`.
  - Xoá `payBooking` (Task 9 bỏ nơi gọi).

- [ ] **Step 1: Viết test thất bại** `bodyTaoDon(khachHangId: 1, dichVuId: 2, ngayThucHien: '2026-10-20', gioBatDau: '09:00', loaiHinhDat: 'TheoLan', hinhThucThanhToan: 'ChuyenKhoan')`: `body['hinhThucThanhToan'] == 'ChuyenKhoan'`, `body.containsKey('phuongThucThanhToan') == false`, `body['gioBatDau'] == '09:00:00'`.
- [ ] **Step 2: Chạy** `flutter test test/booking_api_body_test.dart` — Expected: FAIL.
- [ ] **Step 3: Cài đặt** như Interfaces.
- [ ] **Step 4: Chạy** test vừa viết + `flutter analyze lib/services` — Expected: PASS; analyze chỉ còn lỗi ở `booking_screen.dart` / `order_detail_screen.dart` (đang gọi tên cũ, Task 6 và 9 sửa).
- [ ] **Step 5: Commit** `git add lib/services/booking_api_service.dart test/booking_api_body_test.dart` + `git commit -m "feat(dat-dich-vu): gui hinhThucThanhToan, API khuyen mai va xac nhan chuyen khoan"`.

### Task 6: Khung 5 bước + bước 1, 2

**Files:**
- Modify: `lib/screens/customer/booking_screen.dart` (viết lại thành khung; giữ `class BookingScreen({required Map<String, dynamic> service})`)
- Create: `lib/screens/customer/dat_dich_vu/thanh_buoc.dart`, `buoc_dich_vu.dart`, `buoc_hinh_thuc.dart`
- Test: `test/widget_test.dart` (sửa smoke test)

**Interfaces:**
- Consumes: `NhomDichVu`, `BuocDat`, `DuLieuDat`, `ServiceCatalogApiService.getServices(loaiDichVuId:)`.
- Produces (cho Task 7–8):
  - `ThanhBuoc({required int buoc, required int daToi, required bool boQuaBuoc2, required ValueChanged<int> onChon})` – 5 nút: Dịch vụ, Hình thức, Thời gian, Xác nhận, Thanh toán; bước > `daToi` khoá; bước 2 ẩn khi `boQuaBuoc2`.
  - `BuocDichVu({required List<NhomDichVu> nhoms, required String? maChon, required ValueChanged<NhomDichVu> onChon, required bool dangTai, String? loi, VoidCallback? onThuLai})`.
  - `BuocHinhThuc({required NhomDichVu nhom, required String? loaiChon, required ValueChanged<String> onChon})` – thẻ Theo lần / Gói tháng; loại nhóm không có thì mờ, không bấm được.
  - State của `BookingScreen` giữ `int _buoc`, `int _daToi`, `List<NhomDichVu> _nhoms`, `NhomDichVu? _nhom`, `String _loai`, `int? _dichVuId`… và một `DuLieuDat get _duLieu`.
- Hành vi: `initState` lấy `loaiDichVuId` từ `widget.service`, gọi `getServices`; tạm dựng nhóm một phần tử từ `widget.service` để mở ngay ở `BuocDat.buocMoDau`; khi tải xong thay bằng danh sách đầy đủ (giữ nhóm đang chọn qua `timTheoDichVuId`). Thanh đáy: tổng tiền + Quay lại / Tiếp tục (gọi `loiBuoc`, có lỗi thì SnackBar).

- [ ] **Step 1: Sửa smoke test** `test/widget_test.dart` để `pumpWidget(MaterialApp(home: BookingScreen(service: {...dịch vụ mẫu có id, maDichVu, tenDichVu, loaiDichVuId, loaiHinhDat:'TheoLan', donGiaThamKhao})))` và kiểm `find.text('Dịch vụ')`, `find.text('Thanh toán')` mỗi cái tìm thấy ít nhất một, `find.text('Hình thức')` tìm thấy (bước 2 đang mở). Gọi mạng lỗi trong test là chấp nhận (khung lỗi + Thử lại hiện ở bước 1).
- [ ] **Step 2: Chạy** `flutter test test/widget_test.dart` — Expected: FAIL (chưa có thanh bước).
- [ ] **Step 3: Cài đặt** khung + 3 widget như Interfaces.
- [ ] **Step 4: Chạy** `flutter test` (toàn bộ) + `flutter analyze` — Expected: test PASS; analyze không còn lỗi ở các file của task này.
- [ ] **Step 5: Commit** các file của task, message `feat(dat-dich-vu): khung 5 buoc, buoc dich vu va hinh thuc`.

### Task 7: Bước 3 (thời gian) và bước 4 (xác nhận, khuyến mãi)

**Files:**
- Create: `lib/screens/customer/dat_dich_vu/buoc_thoi_gian.dart`, `buoc_xac_nhan.dart`, `bang_khuyen_mai.dart`
- Modify: `lib/screens/customer/booking_screen.dart`

**Interfaces:**
- Consumes: `RangBuocNgayDat`, `BuocDat.keoNgay`, `LichGoiThang`, `LichThang` widget (`ngayChon`, `ngayDau`, `ngayCuoi`, `ngayTo`, `onChon`), sổ địa chỉ hiện có (`address_book_screen.dart`), `BookingApiService.calculatePrice`, `getAvailablePromotions`.
- Produces:
  - `BuocThoiGian(...)`: lưới biến thể của `_nhom.bienTheTheoLoai(_loai)`; `LichThang` với `ngayCuoi = RangBuocNgayDat.ngayToiDa(_loai, homNay)`; khung giờ 07:00–17:00 khoá giờ chưa đủ +1 giờ (giữ logic `_gioHopLe` hiện có); thứ trong tuần cho gói (giữ `_thuGoi`, `LichGoiThang`); thẻ địa chỉ + nút **Thêm địa chỉ**; ô ghi chú.
  - `BuocXacNhan(...)`: tóm tắt (dịch vụ, hình thức, thời gian, lịch gói, địa chỉ, ghi chú, tạm tính, ưu đãi, tổng); ô mã + nút **Áp dụng** + nút **Chọn khuyến mãi**.
  - `Future<String?> moBangKhuyenMai(BuildContext context, {required int dichVuId, required String loaiHinhDat, String? ngayThucHien, String? gioBatDau, String? maDangDung})` – bottom sheet; trả code được chọn (null nếu đóng). Mỗi dòng: tên, code, mô tả giảm, HSD, `-<soTienGiam>` khi `dungDuoc`, `lyDo` khi không; nút Áp dụng khoá khi `!dungDuoc`.
- Hành vi: đổi `_loai` → `_ngay = BuocDat.keoNgay(...)`, nếu bị kéo thì SnackBar `'Đã đổi ngày về dd/MM vì đặt theo lần chỉ trong 1 tháng.'` (gói: `'… vì gói tháng chỉ bắt đầu trong 3 tháng.'`); đổi dịch vụ → biến thể đầu tiên, xoá mã; mã không còn hợp lệ sau khi tính lại → bỏ giảm, hiện `thongDiepKMDuocApDung`. Tính giá lỗi → giữ `donGiaThamKhao`, dòng `'Chưa tính được giá, thử lại'`.

- [ ] **Step 1:** Cài đặt 3 widget và nối vào khung.
- [ ] **Step 2: Chạy** `flutter test` + `flutter analyze` — Expected: PASS, không lỗi analyze ở các file của task.
- [ ] **Step 3: Commit** message `feat(dat-dich-vu): buoc thoi gian, xac nhan va bang khuyen mai`.

### Task 8: Bước 5 (phương thức thanh toán), gửi đơn và màn Thanh toán QR

**Files:**
- Create: `lib/screens/customer/dat_dich_vu/buoc_thanh_toan.dart`, `lib/screens/customer/thanh_toan_screen.dart`
- Modify: `lib/screens/customer/booking_screen.dart`

**Interfaces:**
- Consumes: `BookingApiService.createBooking(... hinhThucThanhToan)`, `PaymentApiService.getInvoice`, `BookingApiService.confirmTransfer`, `DongHo`, `BookingApiService.getBookingDetail` (khoá `soGiayConLaiThanhToan` từ Task 0).
- Produces:
  - `BuocThanhToan({required String? chon, required int phutThanhToan, required ValueChanged<String> onChon})` – thẻ **Tiền mặt** (`'Trả cho cộng tác viên sau buổi làm. bTaskee tìm người làm ngay.'`) / **Chuyển khoản** (`'Quét mã VietQR, cần thanh toán trong 15 phút. Thanh toán xong bTaskee mới tìm người làm.'`).
  - `ThanhToanScreen({required int donDatId})` – tải `getInvoice` + `getBookingDetail`; hiện ảnh `qrCodeUrl`, số tiền, ngân hàng, số TK, chủ TK, nội dung (nút sao chép qua `Clipboard`), đồng hồ `DongHo.mmss`; nút **Tôi đã chuyển khoản** → `confirmTransfer`; nút **Hủy đơn** → `cancelBooking` hiện có. Thành công hoặc lỗi `"Hóa đơn này đã được thanh toán."` / `"Đơn này đã bị hủy…"` → `Navigator.pushReplacement` sang `OrderDetailScreen` của đơn (lỗi thì SnackBar câu máy chủ trước). Đồng hồ về 0 → khoá nút, chữ `'Đã hết thời gian thanh toán'`, 65 giây sau mở chi tiết đơn.
- Hành vi gửi (bước 5): nút khoá + vòng xoay khi gửi; thành công → `ChuyenKhoan`: `pushReplacement(ThanhToanScreen)`, `TienMat`: `pushReplacement(OrderDetailScreen)`; lỗi máy chủ chứa `'ngày'` / `'giờ'` → về bước 3, chứa `'mã'` / `'khuyến mãi'` → về bước 4; mất mạng → SnackBar `'Không kết nối được máy chủ'`, giữ lựa chọn. Bỏ `_showBookedDialog` cũ.

- [ ] **Step 1:** Cài đặt bước 5, gửi đơn, `ThanhToanScreen`.
- [ ] **Step 2: Chạy** `flutter test` + `flutter analyze` — Expected: PASS.
- [ ] **Step 3: Commit** message `feat(dat-dich-vu): chon phuong thuc thanh toan va man QR chuyen khoan`.

### Task 9: Chi tiết đơn – trạng thái chờ

**Files:**
- Modify: `lib/screens/customer/order_detail_screen.dart`

**Interfaces:**
- Consumes: khoá `soGiayConLaiThanhToan`, `soGiayConLaiNhan`, `soPhutNhanDon`, `hoaDon.{hinhThucThanhToan, trangThaiThanhToan}` của `getBookingDetail`; `DongHo`; `ThanhToanScreen`; `AppRealtime.instance.suKien`.
- Hành vi:
  - `soGiayConLaiThanhToan != null` → nhãn **Chờ thanh toán** + banner đếm lùi + nút **Thanh toán ngay** (mở `ThanhToanScreen`).
  - `soGiayConLaiNhan != null` → banner `'Đang tìm cộng tác viên · còn mm:ss'` + dòng `'Nếu sau <soPhutNhanDon> phút chưa có ai nhận, đơn sẽ tự hủy và bạn không mất phí.'`.
  - Dòng **Thanh toán**: `'Tiền mặt – trả cho cộng tác viên sau buổi làm'` hoặc `'Chuyển khoản – Đã thanh toán' / 'Chưa thanh toán' / 'Đã hoàn tiền'`; đơn `DaHuy` + `DaThanhToan` → `'bTaskee sẽ liên hệ hoàn tiền trong 1–3 ngày làm việc.'`.
  - Đồng hồ về 0 → tải lại sau 65 giây; nghe `AppRealtime.instance.suKien` để tải lại (huỷ subscription trong `dispose`).
  - Xoá bottom sheet thanh toán cũ và `_executePayment` (đang gọi `/pay` không tồn tại và báo "thành công" cả khi lỗi).

- [ ] **Step 1:** Cài đặt như trên.
- [ ] **Step 2: Chạy** `flutter test` + `flutter analyze` (toàn dự án) — Expected: PASS, analyze không còn lỗi do thay đổi của plan này.
- [ ] **Step 3: Commit** message `feat(dat-dich-vu): chi tiet don hien dong ho cho thanh toan va cho nguoi nhan`.

### Task 10: Kiểm tra tay trên máy ảo

*(Hỏi người dùng trước khi `flutter run`; máy ảo cần cold boot, server 8083 đang chạy với code Task 0.)*

- [ ] Từ chi tiết "Dọn dẹp nhà theo giờ" bấm Đặt → mở ở bước 2, dịch vụ chọn sẵn; bấm bước 1 đổi được.
- [ ] Theo lần: lịch khoá sau +1 tháng; sang gói: tới +3 tháng; về theo lần thì ngày kéo về + thông báo.
- [ ] Bảng khuyến mãi hiện mã dùng được / chưa đủ điều kiện kèm lý do; áp mã giảm đúng.
- [ ] Tiền mặt → chi tiết đơn có đồng hồ 15 phút; CSDL `HoaDon.HinhThucThanhToan = TienMat`.
- [ ] Chuyển khoản → màn QR đúng số tiền / nội dung; "Tôi đã chuyển khoản" → Đã thanh toán, đồng hồ chờ người nhận, CSKH trên web thấy đơn; bấm lại → "đã được thanh toán"; đơn khác để quá 15 phút → tự hủy, app hiện Đã hủy.
- [ ] Màn 360dp: không tràn, thanh đáy không che nội dung.
