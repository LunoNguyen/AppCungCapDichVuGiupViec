import 'api_client.dart';
import 'api_response.dart';

class BookingApiService {
  final ApiClient _apiClient = ApiClient();

  /// Tính toán chi phí trước khi đặt dịch vụ (UC-KH04)
  /// POST /v1/bookings/calculate-price — khớp CalculatePriceRequest
  Future<ApiResponse<Map<String, dynamic>>> calculatePrice({
    required int dichVuId,
    int? bangGiaId,
    String loaiHinhDat = 'TheoLan', // TheoLan | GoiThang
    String? codeKhuyenMai,
    int? khachHangId, // mỗi khách chỉ dùng một mã khuyến mãi một lần
    String? ngayThucHien, // yyyy-MM-dd – có cả ngày giờ thì lấy đúng bảng giá tại thời điểm làm
    String? gioBatDau, // HH:mm
    List<int>? dichVuIds, // đặt nhiều dịch vụ từ giỏ hàng: giá gốc = tổng các dịch vụ
  }) async {
    return _apiClient.post<Map<String, dynamic>>(
      '/v1/bookings/calculate-price',
      body: {
        'dichVuId': dichVuId,
        if (dichVuIds != null && dichVuIds.length >= 2) 'chiTiet': [for (final x in dichVuIds) {'dichVuId': x, 'soLuong': 1}],
        if (bangGiaId != null) 'bangGiaId': bangGiaId,
        'loaiHinhDat': loaiHinhDat,
        if (ngayThucHien != null) 'ngayThucHien': ngayThucHien,
        if (gioBatDau != null) 'gioBatDau': gioBatDau,
        if (codeKhuyenMai != null && codeKhuyenMai.isNotEmpty)
          'codeKhuyenMai': codeKhuyenMai,
        if (khachHangId != null) 'khachHangId': khachHangId,
      },
    );
  }

  /// Kiểm tra tính hợp lệ của mã khuyến mại
  /// POST /v1/promotions/validate — khớp ValidatePromotionRequest
  Future<ApiResponse<Map<String, dynamic>>> validatePromotion({
    required String codeKhuyenMai,
    required double tongTienDonHang,
    int? khachHangId,
  }) async {
    return _apiClient.post<Map<String, dynamic>>(
      '/v1/promotions/validate',
      body: {
        'codeKhuyenMai': codeKhuyenMai,
        'tongTienDonHang': tongTienDonHang,
        if (khachHangId != null) 'khachHangId': khachHangId,
      },
    );
  }

  /// Thân JSON của POST /v1/bookings (khớp BookingCreateRequest). Tách riêng để kiểm tra tên trường.
  /// hinhThucThanhToan: "TienMat" | "ChuyenKhoan" (máy chủ chỉ đọc trường này).
  static Map<String, dynamic> bodyTaoDon({
    required int khachHangId,
    required int dichVuId,
    int? bangGiaId,
    required String ngayThucHien, // yyyy-MM-dd
    required String gioBatDau, // HH:mm
    String? gioKetThuc, // HH:mm
    int? diaChiId, // địa chỉ đã lưu của khách hàng
    String? diaChiChiTiet, // hoặc nhập địa chỉ mới
    int? khuVucId,
    String loaiHinhDat = 'TheoLan', // TheoLan | GoiThang
    String? ngayThucHienTrongTuan, // vd "2,4,6" khi đặt gói tháng
    String? yeuCauDacBiet,
    String? ghiChu,
    String? maKhuyenMai,
    required String hinhThucThanhToan,
    List<int>? dichVuIds, // đặt nhiều dịch vụ từ giỏ hàng: một lịch, một hóa đơn
  }) {
    String gio(String g) => g.length == 5 ? '$g:00' : g;
    return {
      'khachHangId': khachHangId,
      'dichVuId': dichVuId,
      if (dichVuIds != null && dichVuIds.length >= 2) 'chiTiet': [for (final x in dichVuIds) {'dichVuId': x, 'soLuong': 1}],
      if (bangGiaId != null) 'bangGiaId': bangGiaId,
      'ngayThucHien': ngayThucHien,
      'gioBatDau': gio(gioBatDau),
      if (gioKetThuc != null) 'gioKetThuc': gio(gioKetThuc),
      if (diaChiId != null) 'diaChiId': diaChiId,
      if (diaChiChiTiet != null) 'diaChiChiTiet': diaChiChiTiet,
      if (khuVucId != null) 'khuVucId': khuVucId,
      'loaiHinhDat': loaiHinhDat,
      if (ngayThucHienTrongTuan != null) 'ngayThucHienTrongTuan': ngayThucHienTrongTuan,
      if (yeuCauDacBiet != null) 'yeuCauDacBiet': yeuCauDacBiet,
      if (ghiChu != null) 'ghiChu': ghiChu,
      if (maKhuyenMai != null && maKhuyenMai.isNotEmpty) 'codeKhuyenMai': maKhuyenMai,
      'hinhThucThanhToan': hinhThucThanhToan,
    };
  }

  /// Khách hàng xác nhận và tạo đơn đặt dịch vụ (UC-KH04) – POST /v1/bookings
  Future<ApiResponse<Map<String, dynamic>>> createBooking({
    required int khachHangId,
    required int dichVuId,
    int? bangGiaId,
    required String ngayThucHien,
    required String gioBatDau,
    String? gioKetThuc,
    int? diaChiId,
    String? diaChiChiTiet,
    int? khuVucId,
    String loaiHinhDat = 'TheoLan',
    String? ngayThucHienTrongTuan,
    String? yeuCauDacBiet,
    String? ghiChu,
    String? maKhuyenMai,
    required String hinhThucThanhToan,
    List<int>? dichVuIds,
  }) async {
    return _apiClient.post<Map<String, dynamic>>(
      '/v1/bookings',
      body: bodyTaoDon(
        dichVuIds: dichVuIds,
        khachHangId: khachHangId,
        dichVuId: dichVuId,
        bangGiaId: bangGiaId,
        ngayThucHien: ngayThucHien,
        gioBatDau: gioBatDau,
        gioKetThuc: gioKetThuc,
        diaChiId: diaChiId,
        diaChiChiTiet: diaChiChiTiet,
        khuVucId: khuVucId,
        loaiHinhDat: loaiHinhDat,
        ngayThucHienTrongTuan: ngayThucHienTrongTuan,
        yeuCauDacBiet: yeuCauDacBiet,
        ghiChu: ghiChu,
        maKhuyenMai: maKhuyenMai,
        hinhThucThanhToan: hinhThucThanhToan,
      ),
    );
  }

  /// Các mã khuyến mãi còn hiệu lực cho dịch vụ đang chọn, tính sẵn số tiền giảm
  /// POST /v1/bookings/available-promotions → [{codeKhuyenMai, tenChuongTrinh, dungDuoc, soTienGiam, lyDo, ...}]
  Future<ApiResponse<List<Map<String, dynamic>>>> getAvailablePromotions({
    required int dichVuId,
    required String loaiHinhDat,
    String? ngayThucHien, // yyyy-MM-dd
    String? gioBatDau, // HH:mm
    List<int>? dichVuIds,
  }) async {
    return _apiClient.post<List<Map<String, dynamic>>>(
      '/v1/bookings/available-promotions',
      body: {
        'dichVuId': dichVuId,
        if (dichVuIds != null && dichVuIds.length >= 2) 'chiTiet': [for (final x in dichVuIds) {'dichVuId': x, 'soLuong': 1}],
        'loaiHinhDat': loaiHinhDat,
        if (ngayThucHien != null) 'ngayThucHien': ngayThucHien,
        if (gioBatDau != null) 'gioBatDau': gioBatDau,
      },
      fromJsonT: (json) => json is List
          ? json.map((e) => Map<String, dynamic>.from(e as Map)).toList()
          : <Map<String, dynamic>>[],
    );
  }

  /// Lấy danh sách lịch dịch vụ của khách hàng (UC-KH05)
  /// GET /v1/customer/bookings?khachHangId=...&trangThai=...
  Future<ApiResponse<List<Map<String, dynamic>>>> getCustomerBookings({
    required int khachHangId,
    String? trangThai,
  }) async {
    final queryParams = <String, dynamic>{'khachHangId': khachHangId};
    if (trangThai != null && trangThai.isNotEmpty) {
      queryParams['trangThai'] = trangThai;
    }

    return _apiClient.get<List<Map<String, dynamic>>>(
      '/v1/customer/bookings',
      queryParams: queryParams,
      fromJsonT: (json) {
        if (json is List) {
          return json.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
        return [];
      },
    );
  }

  /// Xem chi tiết đơn đặt dịch vụ (UC-KH05)
  /// GET /v1/customer/bookings/{id}
  Future<ApiResponse<Map<String, dynamic>>> getBookingDetail(int id) async {
    return _apiClient.get<Map<String, dynamic>>(
      '/v1/customer/bookings/$id',
      fromJsonT: (json) => Map<String, dynamic>.from(json as Map),
    );
  }

  /// Hủy đơn đặt khi ở trạng thái "Chờ xác nhận" (UC-KH05)
  /// PUT /v1/customer/bookings/{id}/cancel?khachHangId=...&lyDo=...
  Future<ApiResponse<Map<String, dynamic>>> cancelBooking({
    required int id,
    required int khachHangId,
    String? lyDo,
  }) async {
    final queryParams = <String, dynamic>{'khachHangId': khachHangId};
    if (lyDo != null && lyDo.isNotEmpty) {
      queryParams['lyDo'] = lyDo;
    }

    return _apiClient.put<Map<String, dynamic>>(
      '/v1/customer/bookings/$id/cancel',
      queryParams: queryParams,
    );
  }
}
