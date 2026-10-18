import 'api_client.dart';
import 'api_response.dart';

/// Địa chỉ đã lưu của khách hàng (khớp CustomerAddressService ở backend).
/// Địa chỉ = số nhà, tên đường + phường, xã + tỉnh, thành; khu vực (quận, huyện) suy ra từ phường.
class DiaChi {
  final int id;
  final String diaChiChiTiet;
  final int? khuVucId;
  final String? khuVuc;
  final double? dienTichNha;
  final String? luuYDacBiet;
  final bool laMacDinh;

  /// Số cộng tác viên đang nhận việc trong khu vực của địa chỉ.
  final int soCongTacVien;

  /// Tách từ địa chỉ đã lưu để form sửa điền sẵn (null nếu không tách được).
  final String? soNhaTenDuong;
  final int? maTinh;
  final int? maPhuong;

  const DiaChi({
    required this.id,
    required this.diaChiChiTiet,
    this.khuVucId,
    this.khuVuc,
    this.dienTichNha,
    this.luuYDacBiet,
    this.laMacDinh = false,
    this.soCongTacVien = 0,
    this.soNhaTenDuong,
    this.maTinh,
    this.maPhuong,
  });

  factory DiaChi.fromJson(Map<String, dynamic> j) => DiaChi(
        id: int.tryParse(j['id']?.toString() ?? '') ?? 0,
        diaChiChiTiet: j['diaChiChiTiet']?.toString() ?? '',
        khuVucId: int.tryParse(j['khuVucId']?.toString() ?? ''),
        khuVuc: j['khuVuc']?.toString(),
        dienTichNha: double.tryParse(j['dienTichNha']?.toString() ?? ''),
        luuYDacBiet: j['luuYDacBiet']?.toString(),
        laMacDinh: j['laMacDinh'] == true,
        soCongTacVien: int.tryParse(j['soCongTacVien']?.toString() ?? '') ?? 0,
        soNhaTenDuong: j['soNhaTenDuong']?.toString(),
        maTinh: int.tryParse(j['maTinh']?.toString() ?? ''),
        maPhuong: int.tryParse(j['maPhuong']?.toString() ?? ''),
      );

  /// Địa chỉ nằm trong khu vực (quận, huyện) bTaskee phục vụ thì mới đặt dịch vụ được.
  bool get coKhuVuc => khuVucId != null;

  String get tieuDe => (khuVuc != null && khuVuc!.isNotEmpty)
      ? 'Khu vực: ${khuVuc!.split(',').first}'
      : 'Ngoài khu vực phục vụ';
}

/// Sổ địa chỉ: GET/POST/PUT/DELETE /v1/customers/{khachHangId}/addresses.
class AddressApiService {
  final ApiClient _apiClient = ApiClient();

  String _goc(int khachHangId) => '/v1/customers/$khachHangId/addresses';

  List<DiaChi> _parseList(dynamic json) {
    if (json is List) {
      return json
          .map((e) => DiaChi.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    return <DiaChi>[];
  }

  Future<ApiResponse<List<DiaChi>>> getAddresses(int khachHangId) {
    return _apiClient.get<List<DiaChi>>(_goc(khachHangId), fromJsonT: _parseList);
  }

  /// Chỉ gửi [khuVucId] khi phường thuộc nhiều khu vực (người dùng đã chọn).
  Future<ApiResponse<Map<String, dynamic>>> createAddress(
    int khachHangId, {
    required String soNhaTenDuong,
    required int maTinh,
    required int maPhuong,
    int? khuVucId,
    String? luuYDacBiet,
    bool laMacDinh = false,
  }) {
    return _apiClient.post<Map<String, dynamic>>(
      _goc(khachHangId),
      body: {
        'soNhaTenDuong': soNhaTenDuong,
        'maTinh': maTinh,
        'maPhuong': maPhuong,
        if (khuVucId != null) 'khuVucId': khuVucId,
        if (luuYDacBiet != null) 'luuYDacBiet': luuYDacBiet,
        'laMacDinh': laMacDinh,
      },
    );
  }

  /// Gửi đủ các trường: backend ghi đè toàn bộ địa chỉ (lưu ý bỏ trống = xóa lưu ý).
  Future<ApiResponse<Map<String, dynamic>>> updateAddress(
    int khachHangId,
    int id, {
    required String soNhaTenDuong,
    required int maTinh,
    required int maPhuong,
    int? khuVucId,
    double? dienTichNha,
    String? luuYDacBiet,
    bool? laMacDinh,
  }) {
    return _apiClient.put<Map<String, dynamic>>(
      '${_goc(khachHangId)}/$id',
      body: {
        'soNhaTenDuong': soNhaTenDuong,
        'maTinh': maTinh,
        'maPhuong': maPhuong,
        if (khuVucId != null) 'khuVucId': khuVucId,
        if (dienTichNha != null) 'dienTichNha': dienTichNha,
        if (luuYDacBiet != null) 'luuYDacBiet': luuYDacBiet,
        if (laMacDinh != null) 'laMacDinh': laMacDinh,
      },
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> setDefault(int khachHangId, int id) {
    return _apiClient.put<Map<String, dynamic>>('${_goc(khachHangId)}/$id/default');
  }

  Future<ApiResponse<Map<String, dynamic>>> deleteAddress(int khachHangId, int id) {
    return _apiClient.delete<Map<String, dynamic>>('${_goc(khachHangId)}/$id');
  }
}
