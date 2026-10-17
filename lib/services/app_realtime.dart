import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'thong_bao_cuc_bo.dart';

/// Kết nối realtime tới máy chủ (Server-Sent Events: GET /v1/realtime/stream).
/// - Có thông báo mới ("thong-bao-moi"): hiện thông báo trên điện thoại, cập nhật số chưa đọc,
///   và phát [suKien] để các màn (đơn hàng, thông báo) tự tải lại dữ liệu.
/// - Mất kết nối thì tự kết nối lại sau vài giây.
class AppRealtime {
  AppRealtime._();
  static final AppRealtime instance = AppRealtime._();

  /// Số thông báo chưa đọc (badge trên biểu tượng chuông).
  final ValueNotifier<int> soChuaDoc = ValueNotifier<int>(0);

  final _suKien = StreamController<String>.broadcast();

  /// Tên sự kiện vừa nhận ("thong-bao-moi"...): màn nào cần dữ liệu mới thì lắng nghe và tải lại.
  Stream<String> get suKien => _suKien.stream;

  int? _taiKhoanId;
  String _vaiTro = 'KhachHang';
  http.Client? _client;
  StreamSubscription<String>? _dong;
  /// Hoàn thành để cắt hẳn kết nối SSE đang mở (http.Client.close() không cắt luồng đang đọc).
  Completer<void>? _huyKetNoi;
  /// Tăng mỗi lần kết nối / dừng: callback của kết nối cũ (của tài khoản trước) bị bỏ qua.
  int _theHe = 0;
  Timer? _ketNoiLai;
  Timer? _dinhKy;
  bool _dangChay = false;

  /// Gọi sau khi đăng nhập (màn chính khách hàng / cộng tác viên).
  Future<void> batDau({required int taiKhoanId, required bool laCongTacVien}) async {
    final vaiTro = laCongTacVien ? 'CongTacVien' : 'KhachHang';
    if (_dangChay && _taiKhoanId == taiKhoanId && _vaiTro == vaiTro) return;
    dung();
    _taiKhoanId = taiKhoanId;
    _vaiTro = vaiTro;
    _dangChay = true;
    await ThongBaoCucBo.khoiTao();
    capNhatSoChuaDoc();
    _ketNoi();
    // Dự phòng khi kết nối realtime bị chặn: vẫn cập nhật số chưa đọc mỗi phút
    _dinhKy = Timer.periodic(const Duration(minutes: 1), (_) => capNhatSoChuaDoc());
  }

  /// Gọi khi đăng xuất.
  void dung() {
    _dangChay = false;
    _theHe++;
    _ketNoiLai?.cancel();
    _dinhKy?.cancel();
    _catKetNoi();
    _taiKhoanId = null;
    soChuaDoc.value = 0;
  }

  void _catKetNoi() {
    if (_huyKetNoi != null && !_huyKetNoi!.isCompleted) _huyKetNoi!.complete();
    _huyKetNoi = null;
    _dong?.cancel();
    _dong = null;
    _client?.close();
    _client = null;
  }

  Future<void> capNhatSoChuaDoc() async {
    final id = _taiKhoanId;
    if (id == null) return;
    try {
      final res = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/v1/notifications/unread-count?taiKhoanId=$id&vaiTro=$_vaiTro'))
          .timeout(ApiConfig.receiveTimeout);
      if (res.statusCode == 200) {
        final body = jsonDecode(utf8.decode(res.bodyBytes));
        final n = int.tryParse('${body['data']?['soChuaDoc']}');
        if (n != null) soChuaDoc.value = n;
      }
    } catch (_) {
      // giữ số cũ, thử lại lần sau
    }
  }

  void _ketNoi() {
    if (!_dangChay || _taiKhoanId == null) return;
    _catKetNoi();
    final theHe = ++_theHe;
    final huy = Completer<void>();
    _huyKetNoi = huy;
    final client = http.Client();
    _client = client;
    final req = http.AbortableRequest(
      'GET',
      Uri.parse('${ApiConfig.baseUrl}/v1/realtime/stream?taiKhoanId=$_taiKhoanId&vaiTro=$_vaiTro'),
      abortTrigger: huy.future,
    )..headers['Accept'] = 'text/event-stream';

    client.send(req).then((res) {
      if (theHe != _theHe) return; // đã đổi tài khoản / dừng trong lúc chờ
      if (res.statusCode != 200) {
        _henKetNoiLai(theHe);
        return;
      }
      String tenSuKien = 'message';
      final duLieu = StringBuffer();
      _dong = res.stream.transform(utf8.decoder).transform(const LineSplitter()).listen(
        (dong) {
          if (theHe != _theHe) return;
          if (dong.isEmpty) {
            // Hết một sự kiện SSE
            _xuLy(tenSuKien, duLieu.toString());
            tenSuKien = 'message';
            duLieu.clear();
          } else if (dong.startsWith('event:')) {
            tenSuKien = dong.substring(6).trim();
          } else if (dong.startsWith('data:')) {
            if (duLieu.isNotEmpty) duLieu.write('\n');
            duLieu.write(dong.substring(5).trimLeft());
          }
        },
        onError: (_) => _henKetNoiLai(theHe),
        onDone: () => _henKetNoiLai(theHe),
        cancelOnError: true,
      );
    }).catchError((_) {
      _henKetNoiLai(theHe);
    });
  }

  void _henKetNoiLai(int theHe) {
    if (!_dangChay || theHe != _theHe) return; // kết nối của tài khoản trước: không nối lại
    _ketNoiLai?.cancel();
    _ketNoiLai = Timer(const Duration(seconds: 5), _ketNoi);
  }

  void _xuLy(String ten, String duLieu) {
    if (ten == 'nhip' || ten == 'san-sang') return;
    if (ten == 'thong-bao-moi') {
      String tieuDe = 'Thông báo mới';
      String noiDung = '';
      int? id;
      try {
        final m = jsonDecode(duLieu) as Map<String, dynamic>;
        tieuDe = m['tieuDe']?.toString() ?? tieuDe;
        noiDung = m['noiDung']?.toString() ?? '';
        id = int.tryParse('${m['id']}');
      } catch (_) {}
      // Thông báo đẩy lên thanh thông báo của điện thoại
      ThongBaoCucBo.hien(tieuDe, noiDung, id: id);
      capNhatSoChuaDoc();
    }
    _suKien.add(ten);
  }
}
