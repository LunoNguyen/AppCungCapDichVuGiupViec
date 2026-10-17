import 'booking_api_service.dart';

/// Thông báo về đơn đặt luôn nhắc mã đơn dạng "DD-XXXXXXXXXX" (bảng ThongBao không lưu id đơn),
/// nên app tìm đơn theo mã để mở thẳng màn chi tiết đơn.
final _maDon = RegExp(r'(?<![A-Za-z0-9-])DD-[A-Z0-9]+');

/// Mã đơn nhắc trong thông báo, null nếu không phải thông báo về đơn.
String? maDonTrongThongBao(String text) => _maDon.firstMatch(text)?.group(0);

/// Id của đơn có mã [maDon] trong danh sách đơn của khách, null nếu không có.
int? idDonTheoMa(List<Map<String, dynamic>> dsDon, String maDon) {
  for (final d in dsDon) {
    if (d['maDonDat'] == maDon) return int.tryParse('${d['id']}');
  }
  return null;
}

/// Tìm id đơn của khách theo mã đơn; null khi không tìm thấy hoặc lỗi mạng.
Future<int?> timIdDonCuaKhach(int khachHangId, String maDon) async {
  try {
    final res = await BookingApiService().getCustomerBookings(khachHangId: khachHangId);
    if (!res.success || res.data == null) return null;
    return idDonTheoMa(res.data!, maDon);
  } catch (_) {
    return null;
  }
}
