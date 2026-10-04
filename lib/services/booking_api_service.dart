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
  }) async {
    return _apiClient.post<Map<String, dynamic>>(
      '/v1/bookings/calculate-price',
      body: {
        'dichVuId': dichVuId,
        if (bangGiaId != null) 'bangGiaId': bangGiaId,
        'loaiHinhDat': loaiHinhDat,
        if (codeKhuyenMai != null && codeKhuyenMai.isNotEmpty)
          'codeKhuyenMai': codeKhuyenMai,
      },
    );
  }

  /// Kiểm tra tính hợp lệ của mã khuyến mại
  /// POST /v1/promotions/validate — khớp ValidatePromotionRequest
  Future<ApiResponse<Map<String, dynamic>>> validatePromotion({
    required String codeKhuyenMai,
    required double tongTienDonHang,
  }) async {
    return _apiClient.post<Map<String, dynamic>>(
      '/v1/promotions/validate',
      body: {
        'codeKhuyenMai': codeKhuyenMai,
        'tongTienDonHang': tongTienDonHang,
      },
    );
  }

  /// Khách hàng xác nhận và tạo đơn đặt dịch vụ (UC-KH04)
  /// POST /v1/bookings — khớp BookingCreateRequest
  Future<ApiResponse<Map<String, dynamic>>> createBooking({
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
    String? codeKhuyenMai,
  }) async {
    return _apiClient.post<Map<String, dynamic>>(
      '/v1/bookings',
      body: {
        'khachHangId': khachHangId,
        'dichVuId': dichVuId,
        if (bangGiaId != null) 'bangGiaId': bangGiaId,
        'ngayThucHien': ngayThucHien,
        'gioBatDau': gioBatDau,
        if (gioKetThuc != null) 'gioKetThuc': gioKetThuc,
        if (diaChiId != null) 'diaChiId': diaChiId,
        if (diaChiChiTiet != null) 'diaChiChiTiet': diaChiChiTiet,
        if (khuVucId != null) 'khuVucId': khuVucId,
        'loaiHinhDat': loaiHinhDat,
        if (ngayThucHienTrongTuan != null)
          'ngayThucHienTrongTuan': ngayThucHienTrongTuan,
        if (yeuCauDacBiet != null) 'yeuCauDacBiet': yeuCauDacBiet,
        if (ghiChu != null) 'ghiChu': ghiChu,
        if (codeKhuyenMai != null && codeKhuyenMai.isNotEmpty)
          'codeKhuyenMai': codeKhuyenMai,
      },
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
    final queryParams = <String, dynamic>{
      'khachHangId': khachHangId,
    };
    if (lyDo != null && lyDo.isNotEmpty) {
      queryParams['lyDo'] = lyDo;
    }

    return _apiClient.put<Map<String, dynamic>>(
      '/v1/customer/bookings/$id/cancel',
      queryParams: queryParams,
    );
  }
}
