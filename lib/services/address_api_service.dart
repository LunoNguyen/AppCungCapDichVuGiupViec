import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'diaChiChiTiet': diaChiChiTiet,
        'khuVucId': khuVucId,
        'khuVuc': khuVuc,
        'dienTichNha': dienTichNha,
        'luuYDacBiet': luuYDacBiet,
        'laMacDinh': laMacDinh,
      };

  String get tieuDe =>
      (khuVuc != null && khuVuc!.isNotEmpty) ? khuVuc! : 'Địa chỉ';
}

/// Sổ địa chỉ: hỗ trợ đa điểm cuối Backend + tự động lưu máy (Local Storage) nếu Backend 404
class AddressApiService {
  final ApiClient _apiClient = ApiClient();

  static String _localKey(int khachHangId) => 'customer_addresses_$khachHangId';

  Future<List<DiaChi>> _loadLocalAddresses(int khachHangId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_localKey(khachHangId));
      if (jsonStr == null || jsonStr.isEmpty) return [];
      final List decoded = jsonDecode(jsonStr);
      return decoded
          .map((e) => DiaChi.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveLocalAddresses(int khachHangId, List<DiaChi> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = list.map((d) => d.toJson()).toList();
      await prefs.setString(_localKey(khachHangId), jsonEncode(jsonList));
    } catch (_) {}
  }

  bool _isNotFound(ApiResponse res) {
    if (res.success) return false;
    final msg = res.message ?? '';
    return msg.contains('404') ||
        msg.contains('static resource') ||
        msg.contains('Phản hồi HTML') ||
        msg.contains('3xx');
  }

  List<DiaChi> _parseList(dynamic json) {
    if (json is List) {
      return json
          .map((e) => DiaChi.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    return <DiaChi>[];
  }

  Future<ApiResponse<List<DiaChi>>> getAddresses(int khachHangId) async {
    // Attempt 1: /v1/customers/$khachHangId/addresses
    var res = await _apiClient.get<List<DiaChi>>(
      '/v1/customers/$khachHangId/addresses',
      fromJsonT: _parseList,
    );
    if (res.success && res.data != null) {
      await _saveLocalAddresses(khachHangId, res.data!);
      return res;
    }
    if (!_isNotFound(res)) return res;

    // Attempt 2: /v1/customer/$khachHangId/addresses
    res = await _apiClient.get<List<DiaChi>>(
      '/v1/customer/$khachHangId/addresses',
      fromJsonT: _parseList,
    );
    if (res.success && res.data != null) {
      await _saveLocalAddresses(khachHangId, res.data!);
      return res;
    }
    if (!_isNotFound(res)) return res;

    // Attempt 3: /v1/customer/addresses?khachHangId=...
    res = await _apiClient.get<List<DiaChi>>(
      '/v1/customer/addresses',
      queryParams: {'khachHangId': khachHangId},
      fromJsonT: _parseList,
    );
    if (res.success && res.data != null) {
      await _saveLocalAddresses(khachHangId, res.data!);
      return res;
    }
    if (!_isNotFound(res)) return res;

    // Fallback: Read local storage
    final localList = await _loadLocalAddresses(khachHangId);
    return ApiResponse.ok(localList);
  }

  Future<ApiResponse<Map<String, dynamic>>> createAddress(
    int khachHangId, {
    required String diaChiChiTiet,
    int? khuVucId,
    String? luuYDacBiet,
    bool laMacDinh = false,
  }) async {
    final payload = {
      'khachHangId': khachHangId,
      'diaChiChiTiet': diaChiChiTiet,
      if (khuVucId != null) 'khuVucId': khuVucId,
      if (luuYDacBiet != null) 'luuYDacBiet': luuYDacBiet,
      'laMacDinh': laMacDinh,
    };

    var res = await _apiClient.post<Map<String, dynamic>>(
      '/v1/customers/$khachHangId/addresses',
      body: payload,
    );
    if (res.success) return res;
    if (!_isNotFound(res)) return res;

    res = await _apiClient.post<Map<String, dynamic>>(
      '/v1/customer/$khachHangId/addresses',
      body: payload,
    );
    if (res.success) return res;
    if (!_isNotFound(res)) return res;

    res = await _apiClient.post<Map<String, dynamic>>(
      '/v1/customer/addresses',
      body: payload,
    );
    if (res.success) return res;
    if (!_isNotFound(res)) return res;

    // Fallback: Create locally in SharedPreferences
    final currentList = await _loadLocalAddresses(khachHangId);
    final newId = DateTime.now().millisecondsSinceEpoch % 1000000;
    final isDefault = laMacDinh || currentList.isEmpty;

    final updatedList = <DiaChi>[];
    for (final item in currentList) {
      if (isDefault) {
        updatedList.add(DiaChi(
          id: item.id,
          diaChiChiTiet: item.diaChiChiTiet,
          khuVucId: item.khuVucId,
          khuVuc: item.khuVuc,
          dienTichNha: item.dienTichNha,
          luuYDacBiet: item.luuYDacBiet,
          laMacDinh: false,
        ));
      } else {
        updatedList.add(item);
      }
    }

    final newDiaChi = DiaChi(
      id: newId,
      diaChiChiTiet: diaChiChiTiet,
      khuVucId: khuVucId,
      luuYDacBiet: luuYDacBiet,
      laMacDinh: isDefault,
    );
    updatedList.add(newDiaChi);
    await _saveLocalAddresses(khachHangId, updatedList);

    return ApiResponse.ok({'id': newId, 'message': 'Đã lưu địa chỉ thành công'});
  }

  Future<ApiResponse<Map<String, dynamic>>> updateAddress(
    int khachHangId,
    int id, {
    required String diaChiChiTiet,
    int? khuVucId,
    String? luuYDacBiet,
    bool? laMacDinh,
  }) async {
    final payload = {
      'khachHangId': khachHangId,
      'diaChiChiTiet': diaChiChiTiet,
      if (khuVucId != null) 'khuVucId': khuVucId,
      if (luuYDacBiet != null) 'luuYDacBiet': luuYDacBiet,
      if (laMacDinh != null) 'laMacDinh': laMacDinh,
    };

    var res = await _apiClient.put<Map<String, dynamic>>(
      '/v1/customers/$khachHangId/addresses/$id',
      body: payload,
    );
    if (res.success) return res;
    if (!_isNotFound(res)) return res;

    res = await _apiClient.put<Map<String, dynamic>>(
      '/v1/customer/$khachHangId/addresses/$id',
      body: payload,
    );
    if (res.success) return res;
    if (!_isNotFound(res)) return res;

    // Fallback: Update locally in SharedPreferences
    final currentList = await _loadLocalAddresses(khachHangId);
    final isDefault = laMacDinh == true;

    final updatedList = currentList.map((item) {
      if (item.id == id) {
        return DiaChi(
          id: id,
          diaChiChiTiet: diaChiChiTiet,
          khuVucId: khuVucId ?? item.khuVucId,
          khuVuc: item.khuVuc,
          dienTichNha: item.dienTichNha,
          luuYDacBiet: luuYDacBiet ?? item.luuYDacBiet,
          laMacDinh: isDefault ? true : item.laMacDinh,
        );
      } else {
        return isDefault
            ? DiaChi(
                id: item.id,
                diaChiChiTiet: item.diaChiChiTiet,
                khuVucId: item.khuVucId,
                khuVuc: item.khuVuc,
                dienTichNha: item.dienTichNha,
                luuYDacBiet: item.luuYDacBiet,
                laMacDinh: false,
              )
            : item;
      }
    }).toList();

    await _saveLocalAddresses(khachHangId, updatedList);
    return ApiResponse.ok({'id': id, 'message': 'Cập nhật địa chỉ thành công'});
  }

  Future<ApiResponse<Map<String, dynamic>>> setDefault(
      int khachHangId, int id) async {
    var res = await _apiClient.put<Map<String, dynamic>>(
        '/v1/customers/$khachHangId/addresses/$id/default');
    if (res.success) return res;
    if (!_isNotFound(res)) return res;

    // Fallback: Set default locally in SharedPreferences
    final currentList = await _loadLocalAddresses(khachHangId);
    final updatedList = currentList.map((item) {
      return DiaChi(
        id: item.id,
        diaChiChiTiet: item.diaChiChiTiet,
        khuVucId: item.khuVucId,
        khuVuc: item.khuVuc,
        dienTichNha: item.dienTichNha,
        luuYDacBiet: item.luuYDacBiet,
        laMacDinh: item.id == id,
      );
    }).toList();

    await _saveLocalAddresses(khachHangId, updatedList);
    return ApiResponse.ok({'id': id, 'message': 'Đã đặt địa chỉ mặc định'});
  }

  Future<ApiResponse<Map<String, dynamic>>> deleteAddress(
      int khachHangId, int id) async {
    var res = await _apiClient.delete<Map<String, dynamic>>(
        '/v1/customers/$khachHangId/addresses/$id');
    if (res.success) return res;
    if (!_isNotFound(res)) return res;

    // Fallback: Delete locally in SharedPreferences
    final currentList = await _loadLocalAddresses(khachHangId);
    final updatedList = currentList.where((item) => item.id != id).toList();
    if (updatedList.isNotEmpty && !updatedList.any((e) => e.laMacDinh)) {
      updatedList[0] = DiaChi(
        id: updatedList[0].id,
        diaChiChiTiet: updatedList[0].diaChiChiTiet,
        khuVucId: updatedList[0].khuVucId,
        khuVuc: updatedList[0].khuVuc,
        dienTichNha: updatedList[0].dienTichNha,
        luuYDacBiet: updatedList[0].luuYDacBiet,
        laMacDinh: true,
      );
    }

    await _saveLocalAddresses(khachHangId, updatedList);
    return ApiResponse.ok({'id': id, 'message': 'Đã xoá địa chỉ'});
  }
}
