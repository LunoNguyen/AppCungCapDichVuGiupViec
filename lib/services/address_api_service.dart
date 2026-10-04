import 'api_client.dart';
import 'api_response.dart';

/// Địa chỉ đã lưu của khách hàng (khớp CustomerAddressService ở backend).
class DiaChi {
  final int id;
  final String diaChiChiTiet;
  final int? khuVucId;
  final String? khuVuc;
  final double? dienTichNha;
  final String? luuYDacBiet;
  final bool laMacDinh;

  const DiaChi({
    required this.id,
    required this.diaChiChiTiet,
    this.khuVucId,
    this.khuVuc,
    this.dienTichNha,
    this.luuYDacBiet,
    this.laMacDinh = false,
  });

  factory DiaChi.fromJson(Map<String, dynamic> j) => DiaChi(
        id: int.tryParse(j['id']?.toString() ?? '') ?? 0,
        diaChiChiTiet: j['diaChiChiTiet']?.toString() ?? '',
        khuVucId: int.tryParse(j['khuVucId']?.toString() ?? ''),
        khuVuc: j['khuVuc']?.toString(),
        dienTichNha: double.tryParse(j['dienTichNha']?.toString() ?? ''),
        luuYDacBiet: j['luuYDacBiet']?.toString(),
        laMacDinh: j['laMacDinh'] == true,
      );

  String get tieuDe =>
      (khuVuc != null && khuVuc!.isNotEmpty) ? khuVuc! : 'Địa chỉ';
}

/// Sổ địa chỉ: /v1/customers/{khachHangId}/addresses
class AddressApiService {
  final ApiClient _apiClient = ApiClient();

  String _base(int khachHangId) => '/v1/customers/$khachHangId/addresses';

  Future<ApiResponse<List<DiaChi>>> getAddresses(int khachHangId) {
    return _apiClient.get<List<DiaChi>>(
      _base(khachHangId),
      fromJsonT: (json) => json is List
          ? json.map((e) => DiaChi.fromJson(Map<String, dynamic>.from(e as Map))).toList()
          : <DiaChi>[],
    );
  }

  Map<String, dynamic> _body({
    required String diaChiChiTiet,
    int? khuVucId,
    String? luuYDacBiet,
    bool? laMacDinh,
  }) =>
      {
        'diaChiChiTiet': diaChiChiTiet,
        'khuVucId': khuVucId,
        'luuYDacBiet': luuYDacBiet,
        if (laMacDinh != null) 'laMacDinh': laMacDinh,
      };

  Future<ApiResponse<Map<String, dynamic>>> createAddress(
    int khachHangId, {
    required String diaChiChiTiet,
    int? khuVucId,
    String? luuYDacBiet,
    bool laMacDinh = false,
  }) {
    return _apiClient.post<Map<String, dynamic>>(
      _base(khachHangId),
      body: _body(
        diaChiChiTiet: diaChiChiTiet,
        khuVucId: khuVucId,
        luuYDacBiet: luuYDacBiet,
        laMacDinh: laMacDinh,
      ),
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> updateAddress(
    int khachHangId,
    int id, {
    required String diaChiChiTiet,
    int? khuVucId,
    String? luuYDacBiet,
    bool? laMacDinh,
  }) {
    return _apiClient.put<Map<String, dynamic>>(
      '${_base(khachHangId)}/$id',
      body: _body(
        diaChiChiTiet: diaChiChiTiet,
        khuVucId: khuVucId,
        luuYDacBiet: luuYDacBiet,
        laMacDinh: laMacDinh,
      ),
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> setDefault(int khachHangId, int id) {
    return _apiClient.put<Map<String, dynamic>>('${_base(khachHangId)}/$id/default');
  }

  Future<ApiResponse<Map<String, dynamic>>> deleteAddress(int khachHangId, int id) {
    return _apiClient.delete<Map<String, dynamic>>('${_base(khachHangId)}/$id');
  }
}
