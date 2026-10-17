# Đánh giá đơn: kiểm duyệt, phản hồi công khai, thông báo phản hồi

Ngày: 2026-10-17 · Phạm vi: website `WebsiteCungCapDichVuGiupViec` (Spring Boot + Thymeleaf) và app `app_cung_cap_dich_vu_giup_viec` (Flutter).

## Mục tiêu

Khi đơn hoàn thành, khách được mời đánh giá và bình luận; nhân viên xem, kiểm duyệt đánh giá và trả lời; khách thấy phản hồi trong app và trên website. Kết quả đúng là: chỉ đánh giá đã duyệt mới hiển thị công khai, mọi nút kiểm duyệt trên trang quản trị thật sự đổi dữ liệu, và khách được báo khi bTaskee trả lời.

## Hiện trạng (đã có, giữ nguyên)

- `DanhGia`: mỗi đơn 1 đánh giá (`donDatId` unique), `DiemChatLuong`, `DiemThaiDo` (1–5), `NhanXet`, `TrangThai` (mặc định `ChoDuyet`).
- `PhanHoiDanhGia`: chuỗi trao đổi dưới đánh giá; dòng có `nhanVienId` là của nhân viên, không có là của khách.
- `DanhGiaService`: tạo, sửa trong 7 ngày, khách bình luận, nhân viên trả lời, `toMap` kèm `traoDoi`.
- Khách: form + trao đổi trên `khach-hang/don-chi-tiet.html` và `lib/widgets/danh_gia_don.dart`.
- CSKH `/cskh/danh-gia`: danh sách, bộ lọc, modal trả lời (thật).
- Thông báo hoàn thành trong `ThongBaoSuKienService.khiDonDoiTrangThai`: "Đơn … đã hoàn thành. Mời bạn đánh giá…".
- `ThongBaoService.gui` đã đẩy SSE `thong-bao-moi` tới tài khoản; màn chi tiết đơn của app tải lại khi có sự kiện realtime.

## Thiếu sót cần sửa

1. Nút kiểm duyệt CSKH chỉ hiện toast (Ẩn, Duyệt tất cả, Ẩn đã chọn, Xóa, Sửa, Thêm đánh giá); modal sửa dùng trạng thái sai `DaDuyet`/`DaAn`.
2. `HienThi` bị dùng hai nghĩa: Marketing = "ghim trang chủ", CSKH = "đang hiển thị".
3. Danh sách công khai theo dịch vụ (`CustomerApiService.getReviewsByService`, chi tiết dịch vụ) bỏ qua `TrangThai`.
4. Khách không được báo khi nhân viên trả lời.
5. Khách không thấy trạng thái duyệt của đánh giá mình.

## Quyết định

| Chủ đề | Quyết định |
|---|---|
| Nghĩa trạng thái | `ChoDuyet` = mới gửi, chưa công khai; `HienThi` = đã duyệt, công khai; `An` = ẩn khỏi mọi danh sách công khai. Marketing dùng cùng nghĩa, không còn "ghim" riêng. |
| Phản hồi công khai | Danh sách công khai hiện phản hồi **mới nhất của nhân viên** dưới đánh giá `HienThi`. Bình luận của khách luôn riêng tư. |
| Thông báo | Chỉ báo khách khi nhân viên trả lời (kèm SSE qua `thong-bao-moi`). Không báo khi duyệt/ẩn. |
| Quyền CSKH | Duyệt, Ẩn, đưa về Chờ duyệt (từng dòng và hàng loạt) + trả lời. Bỏ Sửa, Xóa, Thêm đánh giá. Đánh giá ẩn vẫn tính vào điểm CTV. |
| Khách sửa đánh giá | `HienThi` → `ChoDuyet`; `An` giữ `An`; `ChoDuyet` giữ `ChoDuyet`. |
| Kiến trúc | Mọi quy tắc nằm trong `DanhGiaService`; thông báo phản hồi đi qua sự kiện `SuKienDanhGia.PhanHoiMoi`, xử lý sau khi giao dịch ghi xong. |
| CSDL | Không thêm/xóa bảng hay cột. Không chuyển đổi dữ liệu cũ. |

## Thiết kế

### 1. Backend (website)

**`Service/DanhGiaService`** — nơi duy nhất chứa quy tắc đánh giá:

- `int doiTrangThai(List<Integer> ids, String trangThai)`:
  - Chỉ nhận `ChoDuyet | HienThi | An`; khác thì `IllegalArgumentException("Trạng thái không hợp lệ.")`.
  - `ids` rỗng/null → `IllegalArgumentException("Chưa chọn đánh giá nào.")`.
  - Id không tồn tại bị bỏ qua; trả về số đánh giá đã đổi.
  - Xóa cache `DANH_GIA`, `DICH_VU`. Không đụng điểm CTV.
- `suaDanhGia(...)`: sau khi lưu điểm/nhận xét, nếu trạng thái cũ là `HienThi` thì đặt `ChoDuyet`. Map trả về đã có `trangThai`.
- `List<Map<String,Object>> congKhaiTheoDichVu(Integer dichVuId)`:
  - Lọc đánh giá có đơn chứa dịch vụ đó (cùng cách `getReviewsByService` hiện tại) và `TrangThai = HienThi`.
  - Sắp mới nhất trước. Mỗi phần tử: `id, khachHang, diem, nhanXet, ngayDanhGia, phanHoi`.
  - `phanHoi` = `{noiDung, thoiGian}` của dòng `PhanHoiDanhGia` mới nhất có `nhanVien != null`, hoặc `null`.
- `Map<String,Object> phanHoiCongKhai(Integer danhGiaId)` → `{noiDung, thoiGian}` hoặc `null`, dùng chung cho trang chủ và danh sách theo dịch vụ.
- `traLoiCuaNhanVien(...)`: lưu như cũ, rồi `publisher.publishEvent(new SuKienDanhGia.PhanHoiMoi(dg.getId()))` (`ApplicationEventPublisher` thêm vào constructor).
- `long demChoDuyet()` cho thẻ thống kê CSKH.
- Quy tắc thuần, `static`, để kiểm thử không cần CSDL (theo kiểu `QuanLyDonService.loiChuyenTrangThai`):
  - `static String loiTrangThai(String trangThai)` → `null` nếu hợp lệ, ngược lại thông báo lỗi.
  - `static String trangThaiSauKhiSua(String cu)` → `HienThi` thành `ChoDuyet`, còn lại giữ nguyên.
  - `static boolean laCongKhai(DanhGia dg)` → `HienThi`.
  - `static PhanHoiDanhGia phanHoiMoiNhatCuaNhanVien(List<PhanHoiDanhGia> traoDoi)` → dòng mới nhất có `nhanVien != null` hoặc `null`.

**`SuKien/SuKienDanhGia.java`** (mới): `public record PhanHoiMoi(Integer danhGiaId) {}` trong lớp `final` giống `SuKienDon`.

**`Service/ThongBaoSuKienService`**: thêm `khiCoPhanHoiDanhGia(SuKienDanhGia.PhanHoiMoi e)` với đúng bộ annotation của `khiDonDoiTrangThai`: `@Async("taskExecutor")`, `@TransactionalEventListener(fallbackExecution = true)` (mặc định AFTER_COMMIT), `@Transactional(propagation = REQUIRES_NEW)`. Nạp đánh giá → đơn → khách; gửi bằng `guiKhach`:
- Tiêu đề: `"bTaskee đã phản hồi đánh giá đơn " + maDonDat`.
- Nội dung: phản hồi mới nhất của nhân viên, cắt 200 ký tự kèm "…", rồi "Xem chi tiết trong đơn hàng của bạn."
- Lỗi chỉ ghi log (giống `gui`).

**Nơi gọi chuyển sang service:**
- `CustomerApiService`: chi tiết dịch vụ (khối `danhGias`, `soLuongDanhGia`, `diemDanhGiaTrungBinh`) dùng `congKhaiTheoDichVu`; số lượng và điểm trung bình tính trên danh sách công khai. `getReviewsByService` trả về list map công khai.
- `API/ReviewApiController GET /service/{dichVuId}`: trả list map công khai thay vì entity `DanhGia`.
- `CatalogService.getDanhGiaNoiBat`: giữ lọc `HienThi` + có nhận xét; thêm `phanHoi` (String, có thể null) vào `DTO/view/DanhGiaView`.
- `MarketingController POST /marketing/danh-gia/cap-nhat-trang-thai`: gọi `doiTrangThai(List.of(id), trangThai)`; lỗi → flash message, redirect như cũ.
- `CSKHController`: thêm `POST /cskh/danh-gia/trang-thai` (`@RequestParam List<Integer> ids`, `@RequestParam String trangThai`) → JSON `{soLuong}`; `IllegalArgumentException` → 400 `{message}` như `tra-loi`.

### 2. Giao diện quản trị

**CSKH `templates/cskh/danh-gia.html` + `CSKHController.danhGia`:**
- Mỗi dòng: Phản hồi (giữ). Nút trạng thái theo hiện trạng: **Duyệt** khi `ChoDuyet`/`An`, **Ẩn** khi `HienThi`; thêm nút nhỏ **Chờ duyệt** khi khác `ChoDuyet`. Gọi `POST /cskh/danh-gia/trang-thai`, cập nhật badge, `data-status` và nút của dòng không tải lại trang, báo bằng `CSKH.toast`.
- Thanh hàng loạt: "Duyệt tất cả", "Ẩn đã chọn" gửi các id đã chọn; bỏ "Xóa đã chọn".
- Bỏ nút/modal Sửa, Xóa, Thêm đánh giá và JS liên quan.
- Thêm thẻ thống kê "Chờ duyệt" (`demChoDuyet`). Danh sách sắp mới nhất trước.
- Đọc `?trangThai=` để chọn sẵn bộ lọc trạng thái.
- Controller bỏ `phanHoiList`, `congTacViens`, `khachHangs` nếu không còn template nào dùng.
- Dashboard CSKH: thêm số "Đánh giá chờ duyệt" liên kết `/cskh/danh-gia?trangThai=ChoDuyet`.

**Marketing `templates/marketing/danh-gia.html`:**
- Cột "Hiển thị trang chủ" → "Trạng thái" với 3 badge: Chờ duyệt / Đang hiển thị / Đã ẩn.
- Nút **Hiển thị** (khi khác `HienThi`) / **Ẩn** (khi `HienThi`), vẫn form POST cũ.
- Gợi ý: "Trang chủ hiện 6 đánh giá đang hiển thị mới nhất có nhận xét."
- Marketing không trả lời đánh giá.

### 3. Giao diện khách hàng

**Đánh giá của chính khách** — website `khach-hang/don-chi-tiet.html`, app `lib/widgets/danh_gia_don.dart`:
- Dòng trạng thái dưới "Gửi lúc …": *Đang chờ bTaskee duyệt* (`ChoDuyet`), *Đang hiển thị công khai* (`HienThi`), *Không hiển thị công khai* (`An`).
- Khi đang sửa đánh giá `HienThi`: gợi ý "Sau khi sửa, đánh giá sẽ chờ duyệt lại trước khi hiển thị công khai."
- Trao đổi giữ nguyên. App tự tải lại nhờ SSE `thong-bao-moi`.

**Danh sách công khai:**
- Website `site/dich-vu-thong-tin.html` và `index.html`: nếu có `phanHoi`, hiện khối thụt lề "Phản hồi từ bTaskee" + nội dung.
- App `lib/screens/customer/service_detail_screen.dart`: cùng khối, đọc `phanHoi` (map `{noiDung, thoiGian}`); thiếu trường thì hiển thị như cũ.

### Ngoài phạm vi

- Mở thẳng đơn khi bấm thông báo (cần cột liên kết trên `ThongBao`).
- Thông báo khi duyệt/ẩn; lý do ẩn; xóa cứng đánh giá; nhân viên sửa đánh giá.
- Kiểm duyệt bình luận của khách (chúng riêng tư).

## Xử lý lỗi

- Trạng thái lạ, danh sách id rỗng → 400 với thông báo tiếng Việt; trang CSKH hiện toast lỗi, không đổi dòng.
- Gửi thông báo thất bại → chỉ ghi log, không ảnh hưởng việc lưu phản hồi.
- App đọc `phanHoi`/`trangThai` an toàn khi thiếu hoặc sai kiểu.

## Kiểm thử

- `src/test/java/com/example/Service/DanhGiaServiceTest.java` (JUnit thuần, không Spring context, không CSDL, không mock — theo kiểu `QuanLyDonServiceTest`), kiểm các hàm `static`:
  - `loiTrangThai`: nhận `ChoDuyet/HienThi/An`, từ chối giá trị khác và null.
  - `trangThaiSauKhiSua`: `HienThi` → `ChoDuyet`; `An`, `ChoDuyet` giữ nguyên.
  - `laCongKhai`: chỉ `HienThi`.
  - `phanHoiMoiNhatCuaNhanVien`: chọn dòng nhân viên mới nhất, bỏ qua bình luận khách, `null` khi chưa có.
  - Chạy `./mvnw test -Dtest=DanhGiaServiceTest` chỉ sau khi người dùng đồng ý (biên dịch làm server 8083 tải lại). Không chạy `@SpringBootTest`.
  - Việc phát sự kiện và gửi thông báo kiểm thủ công (xem dưới).
- App: widget test `test/danh_gia_don_test.dart` cho dòng trạng thái theo 3 trạng thái và gợi ý chờ duyệt lại; test khối "Phản hồi từ bTaskee". `flutter analyze` + `flutter test`.
- Thủ công (người dùng): CSKH duyệt/ẩn/hàng loạt; phản hồi → thông báo tới app; đánh giá ẩn biến khỏi trang dịch vụ và trang chủ.
