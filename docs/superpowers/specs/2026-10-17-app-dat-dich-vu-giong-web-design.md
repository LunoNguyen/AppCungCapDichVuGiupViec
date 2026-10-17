# Đặt dịch vụ trên app giống website – Design

**Ngày:** 2026-10-17
**Phạm vi:** app Flutter `app_cung_cap_dich_vu_giup_viec` (phía khách hàng) + vài chỗ sửa nhỏ ở backend Spring `WebsiteCungCapDichVuGiupViec`.

## 1. Mục tiêu và lý do

Luồng đặt dịch vụ trên app đang khác website (đã làm lại theo plan `WebsiteCungCapDichVuGiupViec/docs/superpowers/plans/2026-10-16-dat-dich-vu-thanh-toan.md`). Người dùng muốn app **giống toàn bộ luồng của web**:
chọn dịch vụ → chọn theo lần / gói tháng → chọn thời gian thực hiện (kèm ràng buộc ngày) → đặt dịch vụ → chọn phương thức thanh toán → thanh toán → chờ người nhận (được nhận / phân công, hoặc đơn bị hủy).

Hiện trạng app (lý do phải sửa):

| | Web | App hiện tại |
|---|---|---|
| Các bước | 5 bước: Dịch vụ → Hình thức → Thời gian → Xác nhận → Thanh toán | 3 bước: Chọn gói → Chọn thời gian → Xác nhận |
| Giới hạn ngày | Theo lần ≤ +1 tháng; gói bắt đầu ≤ +3 tháng | 60 ngày cho mọi loại |
| Biến thể | Chọn thời lượng / diện tích trong nhóm cùng `maDichVu` | Chỉ liệt kê bảng giá của một dịch vụ |
| Thanh toán | Chuyển khoản → màn VietQR, 15 phút chưa trả thì hủy | Có chọn trong form nhưng gửi sai tên trường (`phuongThucThanhToan: "TIEN_MAT"`), máy chủ bỏ qua → mọi đơn thành tiền mặt; nút thanh toán ở chi tiết đơn gọi `POST /v1/customer/bookings/{id}/pay` không tồn tại (404) |
| Khuyến mãi | Nút mở bảng mã dùng được | Chỉ ô nhập mã |
| Sau khi đặt | Đồng hồ 15 phút chờ người nhận / hạn chuyển khoản | Không có |

**Thành công khi:** khách đặt trên app đi đúng 5 bước như web, chịu đúng ràng buộc ngày, chọn được tiền mặt hoặc chuyển khoản, chuyển khoản thì thanh toán qua màn QR, và chi tiết đơn hiện đúng trạng thái chờ (đồng hồ) như web.

**Không làm (non-goals):** tích hợp API VietQR thật (người dùng sẽ thêm sau; xác nhận chuyển khoản tạm bằng nút); thay đổi luồng phía cộng tác viên; thay đổi cấu trúc CSDL; WebView nhúng trang web.

## 2. Ràng buộc

- Không thêm / xoá bảng, cột, ràng buộc CHECK. `HoaDon.HinhThucThanhToan` ∈ `TienMat | ChuyenKhoan`.
- Quy tắc nghiệp vụ dùng chung với web, máy chủ là nơi kiểm cuối:
  - theo lần: ngày làm ≤ hôm nay + 1 tháng; gói tháng (kéo dài 1 tháng): ngày bắt đầu ≤ hôm nay + 3 tháng;
  - không chọn ngày quá khứ; giờ bắt đầu (buổi đầu) sau hiện tại ít nhất 1 giờ;
  - gói tháng chọn thứ trong tuần đủ số buổi trong 1 tháng (`LichGoiThang`);
  - địa chỉ thuộc khu vực phục vụ;
  - chuyển khoản phải trả trong 15 phút kể từ lúc tạo đơn, trả xong mới phát hành cho CTV; đơn đã phát hành mà 15 phút không ai nhận thì tự hủy.
- **Múi giờ:** máy chủ tính theo giờ Việt Nam (`serverTimezone=Asia/Ho_Chi_Minh`). App dùng giờ thiết bị (người dùng đã đặt đúng múi giờ) cho lịch và khung giờ. Đồng hồ 15 phút đếm lùi từ **số giây máy chủ trả**, không tự lấy giờ thiết bị trừ hạn.
- Người dùng tự chạy server 8083 và `flutter run`: hỏi trước khi chạy `mvnw` / `flutter run`; `flutter test`, `flutter analyze` chạy được tự do.

## 3. Luồng màn hình

**Màn đặt dịch vụ** (`BookingScreen`, mở từ trang chi tiết dịch vụ): thanh 5 bước ở đầu, thanh đáy cố định có **Quay lại / Tiếp tục** và tổng tiền.

| Bước | Nội dung | Chặn sang bước sau khi |
|---|---|---|
| 1. Dịch vụ | Thẻ các dịch vụ cùng danh mục (gom theo `maDichVu`): ảnh, tên, "Từ …đ". Dịch vụ khách vừa xem được chọn sẵn | chưa chọn |
| 2. Hình thức | Hai thẻ **Theo lần** / **Gói tháng**; loại dịch vụ không có thì mờ; dịch vụ chỉ có một loại thì bỏ qua bước | chưa chọn |
| 3. Thời gian | Chọn biến thể (thời lượng / diện tích), lịch + khung giờ, thứ trong tuần (gói, tô các buổi trên lịch), địa chỉ từ sổ địa chỉ, ghi chú | chưa chọn giờ; gói chưa đủ buổi; chưa có địa chỉ trong khu vực phục vụ |
| 4. Xác nhận | Tóm tắt đơn; ô mã ưu đãi + nút **"Chọn khuyến mãi"** mở bảng trượt dưới (mã dùng được, mã chưa đủ điều kiện kèm lý do); nút chính **Đặt dịch vụ** | — |
| 5. Thanh toán | Thẻ **Tiền mặt** / **Chuyển khoản (cần trả trong 15 phút)**; nút đổi chữ "Xác nhận đặt" / "Thanh toán" | chưa chọn |

- **Mở màn:** mở thẳng ở **bước 2** (bước 3 nếu bước 2 bị bỏ qua) với dịch vụ chọn sẵn; bấm bước 1 trên thanh bước để đổi.
- **Lịch:** theo lần khoá sau +1 tháng; gói khoá sau +3 tháng; đổi hình thức mà ngày vượt mốc thì kéo về mốc, SnackBar *"Đã đổi ngày về dd/MM vì đặt theo lần chỉ trong 1 tháng."*.
- **Sau khi gửi:**
  - Tiền mặt → **chi tiết đơn**, banner *"Đang tìm cộng tác viên · còn mm:ss"*.
  - Chuyển khoản → màn **Thanh toán** mới: mã VietQR, số tiền, ngân hàng, số tài khoản, nội dung (nút sao chép), đồng hồ hạn 15 phút, nút **"Tôi đã chuyển khoản"**, nút **"Hủy đơn"**. Trả xong → chi tiết đơn với banner chờ người nhận.
- **Chi tiết đơn** thêm: nhãn **"Chờ thanh toán"** + nút **"Thanh toán ngay"** (đơn chuyển khoản chưa trả, còn hạn); dòng phương thức thanh toán; đơn đã chuyển khoản mà bị hủy → *"bTaskee sẽ liên hệ hoàn tiền"*.

## 4. Dữ liệu và API

**Dùng lại (backend không đổi):**

| App cần | Gọi | Ghi chú |
|---|---|---|
| Dịch vụ + biến thể của danh mục | `GET /v1/services?loaiDichVuId=` | Gom theo `maDichVu`; trường dùng: `id`, `maDichVu`, `tenDichVu`, `loaiHinhDat`, `donViTinh`, `thoiGianThucHienPhut`, `soBuoiGoi`, `donGiaThamKhao`, `giaGoc` |
| Tính giá / kiểm mã | `POST /v1/bookings/calculate-price` | như hiện tại |
| Bảng khuyến mãi | `POST /v1/bookings/available-promotions` | `{dichVuId, loaiHinhDat, ngayThucHien, gioBatDau}` → danh sách có `dungDuoc`, `soTienGiam`, `lyDo` |
| Tạo đơn | `POST /v1/bookings` | **app sửa**: gửi `hinhThucThanhToan: "TienMat" \| "ChuyenKhoan"` (bỏ `phuongThucThanhToan`) |
| Thông tin QR | `GET /v1/payments/invoice/{donDatId}` | `tongThanhToan`, `thongTinNganHang.{qrCodeUrl, nganHang, soTaiKhoan, chuTaiKhoan, noiDungChuyenKhoan}` |

**Backend sửa nhỏ:**
1. `POST /v1/customer/bookings/{id}/confirm-transfer` → `CustomerApiService.xacNhanThanhToanChuyenKhoan(id, "Khách xác nhận trên ứng dụng")` (cùng hàm với web và webhook VietQR sau này). Thay cho `/pay` không tồn tại.
2. `GET /v1/customer/bookings/{id}` trả thêm `soGiayConLaiThanhToan` (đơn chuyển khoản chờ trả), `soGiayConLaiNhan` (đơn đã phát hành chờ người nhận), `soPhutNhanDon` — tính từ `HanNhanDonService` (`hanThanhToanNeuDangCho`, `hanNhanNeuDangCho`), logic tính số giây tách thành hàm tĩnh có unit test.
3. `GET /v1/services` trả thêm `hinhAnhUrl` (ảnh dịch vụ HCNS đặt, qua `MinioService.getViewUrl`); null thì app dùng icon danh mục.

**Phía app:**
- `BookingApiService`: thêm `getAvailablePromotions(...)`, `confirmTransfer(donDatId)`; `createBooking` gửi `hinhThucThanhToan`; bỏ `payBooking` (chi tiết đơn chuyển sang `confirmTransfer`).
- `PaymentApiService.getInvoice` giữ nguyên.
- Lớp thuần mới (không phụ thuộc Flutter UI, test được):
  - `RangBuocNgayDat`: `ngayToiDa(loaiHinhDat, homNay)`, `loiNgayDat(loaiHinhDat, ngay, gio, bayGio)` — cùng quy tắc và câu lỗi với máy chủ.
  - `NhomDichVu`: gom kết quả `/v1/services` thành thẻ dịch vụ (giá từ, cờ theo lần / gói, biến thể sắp theo giá, chọn sẵn theo dịch vụ đang xem).
  - `BuocDat`: trạng thái 5 bước (bước kế / lùi, bỏ qua bước 2, điều kiện chặn từng bước, đặt lại khi đổi dịch vụ / hình thức).
  - `DongHo`: định dạng `mm:ss` từ số giây, trạng thái hết giờ.
- `booking_screen.dart` (1.226 dòng) tách thành khung 5 bước + một widget mỗi bước; màn **Thanh toán** mới; chi tiết đơn bổ sung banner và nút như mục 3.
- Đồng hồ: đếm lùi mỗi giây từ số giây máy chủ; về 0 thì tải lại chi tiết đơn sau ~65 giây; realtime `thong-bao-moi` làm chi tiết đơn tự tải lại khi có người nhận / bị hủy.

## 5. Xử lý lỗi và ca biên

**Tải dữ liệu**
- `/v1/services` lỗi / mất mạng ở bước 1: khung lỗi + **Thử lại**; dịch vụ đang xem vẫn chọn sẵn để đi tiếp.
- Danh mục chỉ một dịch vụ: bước 1 hiện một thẻ đã chọn, không bỏ bước.
- Tính giá lỗi: giữ giá tham khảo của biến thể + dòng "Chưa tính được giá, thử lại"; vẫn cho đi tiếp (máy chủ tính lại khi tạo đơn).
- Bảng khuyến mãi lỗi / rỗng: "Chưa tải được khuyến mãi" + Thử lại, hoặc "Hiện chưa có khuyến mãi nào".

**Chọn**
- Đổi dịch vụ: hình thức, biến thể, mã ưu đãi về mặc định; ngày, giờ, địa chỉ giữ nếu còn hợp lệ.
- Đổi theo lần ↔ gói khi ngày vượt mốc: kéo về mốc + SnackBar.
- Hôm nay hết giờ hợp lệ: mở lịch ở ngày mai.
- Không có địa chỉ / địa chỉ ngoài khu vực: chặn bước 3, báo *"Các địa chỉ đã lưu nằm ngoài khu vực phục vụ"*, nút **Thêm địa chỉ** mở sổ địa chỉ.
- Mã không còn hợp lệ sau khi đổi dịch vụ / ngày: tính lại, bỏ giảm, hiện lý do máy chủ trả.

**Gửi đơn và thanh toán**
- Máy chủ từ chối tạo đơn: hiện đúng câu lỗi; lỗi ngày giờ → về bước 3, lỗi mã → về bước 4.
- Bấm gửi hai lần: nút khoá + vòng xoay trong lúc gửi.
- Mất mạng khi gửi: SnackBar "Không kết nối được máy chủ", giữ mọi lựa chọn.
- "Tôi đã chuyển khoản" hai lần / hai máy: lần sau nhận "Hóa đơn này đã được thanh toán." → coi như đã trả, sang chi tiết đơn.
- Xác nhận đúng lúc đơn vừa tự hủy: nhận "Đơn này đã bị hủy…" → hiện lỗi, sang chi tiết đơn (nhãn Đã hủy + lý do).
- Đồng hồ màn QR về 0: khoá nút, "Đã hết thời gian thanh toán", tải lại sau ~65 giây.
- Thoát app khi ở màn QR: đơn vẫn ở "Đơn của tôi" với nhãn **Chờ thanh toán** + **Thanh toán ngay** (khi còn hạn).
- Giờ thiết bị sai: máy chủ từ chối đơn với câu lỗi, app về bước 3 (dòng "máy chủ từ chối" ở trên).

**Chờ người nhận**
- Có người nhận / bị hủy: realtime `thong-bao-moi` → chi tiết đơn tự tải lại.
- Mất realtime: tải lại khi quay lại app (đã có) và khi đồng hồ về 0.

## 6. Kiểm thử

**Tự động – app (`flutter test`, không cần máy ảo / server, không thêm thư viện mock):**
- `test/rang_buoc_ngay_dat_test.dart`: ngày tối đa (+1 / +3 tháng, kể cả 31/01), quá khứ, giờ sát hơn 1 giờ, đúng biên, câu lỗi trùng máy chủ.
- `test/nhom_dich_vu_test.dart`: gom theo `maDichVu`, giá từ, cờ theo lần / gói, sắp biến thể, chọn sẵn, danh mục một dịch vụ.
- `test/buoc_dat_test.dart`: bỏ qua bước 2, điều kiện chặn từng bước, kéo ngày khi đổi hình thức, đặt lại khi đổi dịch vụ.
- `test/dong_ho_test.dart`: `mm:ss`, về 0, nhãn "Chờ thanh toán" / "Đang tìm cộng tác viên".
- `test/widget_test.dart`: sửa smoke test cho khung 5 bước.

**Tự động – backend (unit thuần, không CSDL):** hàm tĩnh tính `soGiayConLaiThanhToan` / `soGiayConLaiNhan`, cùng kiểu `HanNhanDonServiceTest`. `confirm-transfer` chỉ uỷ quyền cho `xacNhanThanhToanChuyenKhoan` → kiểm tay.

**Kiểm tay trên máy ảo** (sau khi cold boot máy ảo, chạy server 8083):
1. Từ chi tiết "Dọn dẹp nhà theo giờ" bấm Đặt → mở ở bước 2, dịch vụ chọn sẵn; bấm bước 1 đổi được.
2. Theo lần: lịch khoá sau +1 tháng; sang gói: tới +3 tháng; về theo lần thì ngày kéo về + thông báo.
3. Bảng khuyến mãi hiện mã dùng được / chưa đủ điều kiện kèm lý do; áp mã giảm đúng.
4. Tiền mặt → chi tiết đơn có đồng hồ 15 phút; CSDL `HoaDon.HinhThucThanhToan = TienMat`.
5. Chuyển khoản → màn QR đúng số tiền / nội dung; "Tôi đã chuyển khoản" → Đã thanh toán, đồng hồ chờ người nhận, CSKH trên web thấy đơn; bấm lại → "đã được thanh toán"; đơn khác để quá 15 phút → tự hủy, app hiện Đã hủy.
6. Màn 360dp: không tràn, thanh đáy không che nội dung.
