import 'api_client.dart';
import 'api_response.dart';

class PaymentApiService {
  final ApiClient _apiClient = ApiClient();

  /// Lấy thông tin hóa đơn & mã QR VietQR chuyển khoản ngân hàng (UC-KH06)
  /// GET /v1/payments/invoice/{donDatId}
  Future<ApiResponse<Map<String, dynamic>>> getInvoice(int donDatId) async {
    return _apiClient.get<Map<String, dynamic>>(
      '/v1/payments/invoice/$donDatId',
      fromJsonT: (json) => Map<String, dynamic>.from(json as Map),
    );
  }

  /// Xác nhận giao dịch / lập biên lai thanh toán (UC-KH06)
  /// POST /v1/payments/create-receipt
  Future<ApiResponse<Map<String, dynamic>>> createReceipt({
    required int donDatId,
    required double soTien,
    required String phuongThuc, // TIEN_MAT, CHUYEN_KHOAN, VNPAY, VIETQR
    String? maGiaoDichNganHang,
    String? ghiChu,
  }) async {
    return _apiClient.post<Map<String, dynamic>>(
      '/v1/payments/create-receipt',
      body: {
        'donDatId': donDatId,
        'soTien': soTien,
        'phuongThuc': phuongThuc,
        'maGiaoDichNganHang': maGiaoDichNganHang,
        'ghiChu': ghiChu,
      },
    );
  }
}
