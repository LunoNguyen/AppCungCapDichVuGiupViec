import 'api_client.dart';
import 'api_response.dart';

class BookingApiService {
  final ApiClient _apiClient = ApiClient();

  /// Tính toán chi phí trước khi đặt dịch vụ (UC-KH04)
  /// POST /v1/bookings/calculate-price
  Future<ApiResponse<Map<String, dynamic>>> calculatePrice({
    required int dichVuId,
    required double khoiLuongCongViec, // số giờ hoặc số kg
    String? loaiHinh, // THEO_GIO, THEO_GOI
    String? maKhuyenMai,
    String? thoiGianBatDau,
  }) async {
    return _apiClient.post<Map<String, dynamic>>(
      '/v1/bookings/calculate-price',
      body: {
        'dichVuId': dichVuId,
        'khoiLuongCongViec': khoiLuongCongViec,
        'loaiHinh': loaiHinh,
        'maKhuyenMai': maKhuyenMai,
        'thoiGianBatDau': thoiGianBatDau,
      },
    );
  }

  /// Kiểm tra tính hợp lệ của mã khuyến mại
  /// POST /v1/promotions/validate
  Future<ApiResponse<Map<String, dynamic>>> validatePromotion({
    required String maKhuyenMai,
    required int dichVuId,
    required double tongTien,
  }) async {
    return _apiClient.post<Map<String, dynamic>>(
      '/v1/promotions/validate',
      body: {
        'maKhuyenMai': maKhuyenMai,
        'dichVuId': dichVuId,
        'tongTien': tongTien,
      },
    );
  }

  /// Khách hàng xác nhận và tạo đơn đặt dịch vụ (UC-KH04)
  /// POST /v1/bookings
  Future<ApiResponse<Map<String, dynamic>>> createBooking({
    required int khachHangId,
    required int dichVuId,
    int? congTacVienId,
    required String ngayLamViec,
    required String gioBatDau,
    required int soGio,
    required String diaChi,
    String? ghiChu,
    String? maKhuyenMai,
    required String phuongThucThanhToan, // TIEN_MAT, CHUYEN_KHOAN, VNPAY, VIETQR
  }) async {
    return _apiClient.post<Map<String, dynamic>>(
      '/v1/bookings',
      body: {
        'khachHangId': khachHangId,
        'dichVuId': dichVuId,
        'congTacVienId': congTacVienId,
        'ngayLamViec': ngayLamViec,
        'gioBatDau': gioBatDau,
        'soGio': soGio,
        'diaChi': diaChi,
        'ghiChu': ghiChu,
        'maKhuyenMai': maKhuyenMai,
        'phuongThucThanhToan': phuongThucThanhToan,
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
