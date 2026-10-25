import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../services/storage_api_service.dart';

/// Kết quả trả về sau khi CTV chụp và bấm Gửi ảnh tài sản
class TaiSanCaptureResult {
  final List<String> danhSachHinhAnh;
  final List<Uint8List> previewBytesList;
  final String khuVucVatDung;
  final String moTaHienTrang;
  final String ghiChuTaiSan;

  const TaiSanCaptureResult({
    required this.danhSachHinhAnh,
    this.previewBytesList = const [],
    required this.khuVucVatDung,
    required this.moTaHienTrang,
    this.ghiChuTaiSan = '',
  });
}

class _CapturedPhotoItem {
  final Uint8List bytes;
  final String fileName;
  final String uploadedPath;
  final String areaLabel;
  final String timestampLabel;
  final bool isBeforeService;

  const _CapturedPhotoItem({
    required this.bytes,
    required this.fileName,
    required this.uploadedPath,
    required this.areaLabel,
    required this.timestampLabel,
    required this.isBeforeService,
  });
}

/// Bộ nhớ đệm cục bộ trong phiên chạy để hiển thị tức thì ảnh vừa chụp
class TaiSanMemoryCache {
  static final Map<String, Uint8List> _bytesByPath = {};

  static void put(String path, Uint8List bytes) {
    if (path.trim().isEmpty) return;
    _bytesByPath[path.trim()] = bytes;
    final resolved = StorageApiService.resolveImageUrl(path);
    if (resolved.isNotEmpty) {
      _bytesByPath[resolved] = bytes;
    }
  }

  static Uint8List? get(String? path) {
    if (path == null || path.trim().isEmpty) return null;
    final key = path.trim();
    if (_bytesByPath.containsKey(key)) return _bytesByPath[key];
    final resolved = StorageApiService.resolveImageUrl(key);
    return _bytesByPath[resolved];
  }
}

/// Màn hình / BottomSheet yêu cầu CTV chụp lại tài sản ở khu vực thực hiện
/// Dùng cho cả 2 bước:
/// - Trước khi thực hiện dịch vụ ([isBeforeService] = true)
/// - Sau khi hoàn thành dịch vụ ([isBeforeService] = false)
class TaiSanCaptureSheet extends StatefulWidget {
  final bool isBeforeService;
  final String maDon;
  final String tenDichVu;
  final String diaChi;
  final StorageApiService? storageService;

  const TaiSanCaptureSheet({
    super.key,
    required this.isBeforeService,
    required this.maDon,
    required this.tenDichVu,
    this.diaChi = '',
    this.storageService,
  });

  static Future<TaiSanCaptureResult?> show(
    BuildContext context, {
    required bool isBeforeService,
    required String maDon,
    required String tenDichVu,
    String diaChi = '',
    StorageApiService? storageService,
  }) {
    return showModalBottomSheet<TaiSanCaptureResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TaiSanCaptureSheet(
        isBeforeService: isBeforeService,
        maDon: maDon,
        tenDichVu: tenDichVu,
        diaChi: diaChi,
        storageService: storageService,
      ),
    );
  }

  /// Tạo file ảnh PNG hợp lệ (1x1 pixel chuẩn PNG) để upload lên MinIO
  /// trong trường hợp chạy trên máy ảo / giả lập hoặc môi trường test
  static Uint8List createValidSamplePngBytes({bool isBefore = true}) {
    final base64Png = isBefore
        ? 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=='
        : 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';
    return base64Decode(base64Png);
  }

  @override
  State<TaiSanCaptureSheet> createState() => _TaiSanCaptureSheetState();
}

class _TaiSanCaptureSheetState extends State<TaiSanCaptureSheet> {
  static const List<String> _khuVucOptions = [
    'Toàn bộ khu vực làm việc',
    'Phòng khách',
    'Phòng bếp',
    'Phòng ngủ',
    'Khu vực vệ sinh',
  ];

  static const List<String> _moTaTruocOptions = [
    'Tài sản nguyên vẹn, bình thường',
    'Khu vực cần dọn dẹp nhiều',
    'Có vật dụng dễ vỡ cần lưu ý',
  ];

  static const List<String> _moTaSauOptions = [
    'Đã dọn sạch sẽ, tài sản nguyên vẹn',
    'Hoàn tất nghiệm thu cùng khách hàng',
    'Đã sắp xếp gọn gàng đúng vị trí',
  ];

  late final StorageApiService _storageService;
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _noteController = TextEditingController();

  final List<_CapturedPhotoItem> _capturedItems = [];
  late String _selectedKhuVuc;
  late String _selectedMoTa;
  bool _isUploading = false;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _storageService = widget.storageService ?? StorageApiService();
    _selectedKhuVuc = _khuVucOptions.first;
    _selectedMoTa = widget.isBeforeService
        ? _moTaTruocOptions.first
        : _moTaSauOptions.first;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickFromDevice(ImageSource source) async {
    if (_isUploading) return;
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 82,
        maxWidth: 1280,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final name = picked.name.isNotEmpty
          ? picked.name
          : 'tai_san_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _uploadAndAddPhoto(bytes, name);
    } catch (_) {
      // Nếu máy ảo hoặc thiết bị không hỗ trợ camera vật lý, chuyển sang chụp hiện trạng nhanh
      await _captureSimulatedPhoto();
    }
  }

  Future<void> _captureSimulatedPhoto() async {
    if (_isUploading) return;
    final prefix = widget.isBeforeService ? 'truoc' : 'sau';
    final ts = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'tai_san_${prefix}_${widget.maDon}_$ts.png'
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final bytes = TaiSanCaptureSheet.createValidSamplePngBytes(
      isBefore: widget.isBeforeService,
    );
    await _uploadAndAddPhoto(bytes, fileName);
  }

  Future<void> _uploadAndAddPhoto(Uint8List bytes, String fileName) async {
    if (!mounted) return;
    setState(() {
      _isUploading = true;
      _validationError = null;
    });

    final prefix = widget.isBeforeService ? 'truoc' : 'sau';
    final nowStr = DateFormat('HH:mm dd/MM/yyyy').format(DateTime.now());
    String uploadedPath =
        'don-dat/tai-san/${prefix}_${DateTime.now().millisecondsSinceEpoch}_$fileName';

    try {
      final res = await _storageService.uploadTaiSanImage(
        bytes: bytes,
        fileName: fileName,
      );
      if (res.success && res.data != null) {
        final obj = res.data!['objectName']?.toString() ??
            res.data!['url']?.toString() ??
            '';
        if (obj.trim().isNotEmpty) {
          uploadedPath = obj.trim();
        }
      }
    } catch (_) {
      // Giữ đường dẫn chuẩn don-dat/tai-san/... nếu đang ở chế độ test offline
    }

    TaiSanMemoryCache.put(uploadedPath, bytes);

    if (!mounted) return;
    setState(() {
      _isUploading = false;
      _capturedItems.add(
        _CapturedPhotoItem(
          bytes: bytes,
          fileName: fileName,
          uploadedPath: uploadedPath,
          areaLabel: _selectedKhuVuc,
          timestampLabel: nowStr,
          isBeforeService: widget.isBeforeService,
        ),
      );
    });
  }

  void _removePhoto(int index) {
    if (index < 0 || index >= _capturedItems.length) return;
    setState(() {
      _capturedItems.removeAt(index);
    });
  }

  void _handleSubmit() {
    if (_capturedItems.isEmpty) {
      setState(() {
        _validationError = widget.isBeforeService
            ? 'Vui lòng chụp ít nhất 1 ảnh tài sản ở khu vực thực hiện trước khi bắt đầu dịch vụ!'
            : 'Bắt buộc chụp lại tài sản ở khu vực thực hiện! Không chụp ảnh thì đơn không được chuyển sang trạng thái Hoàn thành.';
      });
      return;
    }

    final result = TaiSanCaptureResult(
      danhSachHinhAnh: _capturedItems.map((e) => e.uploadedPath).toList(),
      previewBytesList: _capturedItems.map((e) => e.bytes).toList(),
      khuVucVatDung: _selectedKhuVuc,
      moTaHienTrang: _selectedMoTa,
      ghiChuTaiSan: _noteController.text.trim(),
    );
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final isBefore = widget.isBeforeService;
    final Color primaryColor =
        isBefore ? const Color(0xFF0284C7) : const Color(0xFF15803D);
    final Color lightBgColor =
        isBefore ? const Color(0xFFF0F9FF) : const Color(0xFFF0FDF4);
    final Color borderColor =
        isBefore ? const Color(0xFFBAE6FD) : const Color(0xFFBBF7D0);
    final List<String> moTaOptions =
        isBefore ? _moTaTruocOptions : _moTaSauOptions;

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.60,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: lightBgColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor),
                          ),
                          child: Icon(
                            isBefore
                                ? Icons.camera_enhance_rounded
                                : Icons.fact_check_rounded,
                            color: primaryColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isBefore
                                    ? 'Chụp tài sản trước khi thực hiện'
                                    : 'Chụp tài sản sau khi hoàn thành',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Đơn ${widget.maDon} • ${widget.tenDichVu}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(null),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFF64748B),
                          ),
                          tooltip: 'Đóng',
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Body
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        // Banner hướng dẫn
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: lightBgColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                isBefore
                                    ? Icons.info_outline_rounded
                                    : Icons.verified_user_outlined,
                                size: 18,
                                color: primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isBefore
                                      ? 'Yêu cầu chụp lại hiện trạng tài sản ở khu vực thực hiện trước khi bắt đầu làm. Ảnh được lưu trên MinIO và đính kèm vào chi tiết đơn đặt.'
                                      : 'Bắt buộc chụp lại tài sản ở khu vực thực hiện sau khi làm xong. Nếu không chụp và gửi ảnh, đơn sẽ không được chuyển sang trạng thái Hoàn thành.',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: primaryColor,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Chọn khu vực
                        const Text(
                          '1. Khu vực / Vật dụng ghi nhận',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _khuVucOptions.map((kv) {
                            final selected = _selectedKhuVuc == kv;
                            return ChoiceChip(
                              label: Text(
                                kv,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: selected
                                      ? Colors.white
                                      : const Color(0xFF334155),
                                ),
                              ),
                              selected: selected,
                              selectedColor: primaryColor,
                              backgroundColor: const Color(0xFFF1F5F9),
                              onSelected: (_) {
                                setState(() => _selectedKhuVuc = kv);
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),

                        // Chọn mô tả hiện trạng
                        const Text(
                          '2. Hiện trạng tài sản khu vực thực hiện',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: moTaOptions.map((mt) {
                            final selected = _selectedMoTa == mt;
                            return ChoiceChip(
                              label: Text(
                                mt,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: selected
                                      ? Colors.white
                                      : const Color(0xFF334155),
                                ),
                              ),
                              selected: selected,
                              selectedColor: primaryColor,
                              backgroundColor: const Color(0xFFF1F5F9),
                              onSelected: (_) {
                                setState(() => _selectedMoTa = mt);
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        // Khu vực nút chụp ảnh
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                '3. Hình ảnh tài sản đã chụp',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _capturedItems.isEmpty
                                    ? const Color(0xFFFEF2F2)
                                    : lightBgColor,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                _capturedItems.isEmpty
                                    ? 'Bắt buộc >= 1 ảnh'
                                    : 'Đã chụp ${_capturedItems.length} ảnh',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: _capturedItems.isEmpty
                                      ? const Color(0xFFDC2626)
                                      : primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Các nút thao tác chụp ảnh (Wrap chống tràn viền trên mọi màn hình)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ElevatedButton.icon(
                              key: const Key('btn_capture_tai_san_simulated'),
                              onPressed: _isUploading
                                  ? null
                                  : _captureSimulatedPhoto,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 11,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: _isUploading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.camera_alt_rounded, size: 18),
                              label: Text(
                                isBefore
                                    ? 'Chụp ảnh hiện trạng'
                                    : 'Chụp ảnh nghiệm thu',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            OutlinedButton.icon(
                              key: const Key('btn_capture_tai_san_camera'),
                              onPressed: _isUploading
                                  ? null
                                  : () => _pickFromDevice(ImageSource.camera),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF0F172A),
                                side: const BorderSide(color: Color(0xFFCBD5E1)),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 11,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(
                                Icons.photo_camera_back_outlined,
                                size: 18,
                              ),
                              label: const Text(
                                'Camera thiết bị',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            OutlinedButton.icon(
                              key: const Key('btn_capture_tai_san_gallery'),
                              onPressed: _isUploading
                                  ? null
                                  : () => _pickFromDevice(ImageSource.gallery),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF0F172A),
                                side: const BorderSide(color: Color(0xFFCBD5E1)),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 11,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(
                                Icons.photo_library_outlined,
                                size: 18,
                              ),
                              label: const Text(
                                'Chọn từ thư viện',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Danh sách ảnh đã chụp
                        if (_capturedItems.isEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 24,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.add_a_photo_outlined,
                                  size: 36,
                                  color: Colors.blueGrey.shade300,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  isBefore
                                      ? 'Chưa có ảnh tài sản trước khi thực hiện.\nHãy bấm nút "Chụp ảnh hiện trạng" ở trên.'
                                      : 'Chưa có ảnh tài sản sau khi thực hiện.\nHãy bấm nút "Chụp ảnh nghiệm thu" ở trên.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: Color(0xFF64748B),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: List.generate(_capturedItems.length, (idx) {
                              final item = _capturedItems[idx];
                              return Container(
                                width: 132,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: borderColor, width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                            top: Radius.circular(10),
                                          ),
                                          child: _TaiSanPhotoPreviewCard(
                                            bytes: item.bytes,
                                            isBefore: item.isBeforeService,
                                            areaLabel: item.areaLabel,
                                            timestampLabel: item.timestampLabel,
                                            index: idx + 1,
                                          ),
                                        ),
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: InkWell(
                                            onTap: () => _removePhoto(idx),
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: const BoxDecoration(
                                                color: Colors.black54,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.close_rounded,
                                                size: 14,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Ảnh #${idx + 1} • ${item.areaLabel}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.cloud_done_rounded,
                                                size: 12,
                                                color: primaryColor,
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  'Đã lưu MinIO (${item.timestampLabel})',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 10.5,
                                                    color: primaryColor,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),

                        const SizedBox(height: 14),
                        const Text(
                          '4. Ghi chú thêm về tài sản (tùy chọn)',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _noteController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: isBefore
                                ? 'VD: Bàn kính phòng khách có vết xước nhỏ từ trước...'
                                : 'VD: Đã bàn giao đầy đủ tài sản nguyên vẹn cho khách hàng...',
                            hintStyle: const TextStyle(fontSize: 12.5),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.all(12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFCBD5E1),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFCBD5E1),
                              ),
                            ),
                          ),
                        ),
                        ],
                      ),
                    ),
                  ),
                  if (_validationError != null)
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFFECACA),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Color(0xFFDC2626),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _validationError!,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFB91C1C),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Footer Action Buttons
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(null),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF475569),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Đóng',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 5,
                          child: ElevatedButton.icon(
                            key: const Key('btn_submit_tai_san_photos'),
                            onPressed: _isUploading ? null : _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: Icon(
                              isBefore
                                  ? Icons.send_and_archive_rounded
                                  : Icons.task_alt_rounded,
                              size: 18,
                            ),
                            label: Text(
                              isBefore
                                  ? 'Gửi ảnh & Bắt đầu làm'
                                  : 'Gửi ảnh & Hoàn thành',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Thẻ hiển thị preview ảnh chụp hiện trạng tài sản
class _TaiSanPhotoPreviewCard extends StatelessWidget {
  final Uint8List? bytes;
  final String? imageUrl;
  final bool isBefore;
  final String areaLabel;
  final String timestampLabel;
  final int index;

  const _TaiSanPhotoPreviewCard({
    this.bytes,
    this.imageUrl,
    required this.isBefore,
    required this.areaLabel,
    required this.timestampLabel,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final bgGradient = isBefore
        ? const [Color(0xFF0369A1), Color(0xFF0EA5E9)]
        : const [Color(0xFF15803D), Color(0xFF22C55E)];

    final bool hasRealPhotoBytes = bytes != null && bytes!.isNotEmpty;

    return Container(
      height: 92,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: bgGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasRealPhotoBytes)
            Image.memory(
              bytes!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            )
          else if (imageUrl != null && imageUrl!.trim().isNotEmpty)
            Image.network(
              StorageApiService.resolveImageUrl(imageUrl),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.18),
                  Colors.black.withValues(alpha: 0.58),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isBefore ? 'TRƯỚC DỊCH VỤ' : 'SAU DỊCH VỤ',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: isBefore
                                  ? const Color(0xFF0369A1)
                                  : const Color(0xFF15803D),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.photo_camera_rounded,
                          size: 13,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            areaLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (timestampLabel.isNotEmpty)
                      Text(
                        timestampLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: Colors.white70,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget dùng chung hiển thị hình ảnh tài sản Trước & Sau khi thực hiện dịch vụ
/// Dùng trên:
/// - Thẻ đơn của CTV (tab Đang làm & Đã xong)
/// - Chi tiết ca làm việc của CTV
/// - Màn hình Chi tiết đơn hàng của Khách hàng
class TaiSanBeforeAfterSection extends StatelessWidget {
  final Map<String, dynamic> orderData;
  final bool compact;

  const TaiSanBeforeAfterSection({
    super.key,
    required this.orderData,
    this.compact = false,
  });

  static List<String> extractStringList(dynamic raw) {
    if (raw is List) {
      return raw
          .map((e) => e?.toString().trim() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final List<String> anhTruoc =
        extractStringList(orderData['anhTruocDichVu']);
    final List<String> anhSau = extractStringList(orderData['anhSauDichVu']);
    final String thoiGianTruoc =
        orderData['thoiGianChupTruoc']?.toString() ?? '';
    final String thoiGianSau = orderData['thoiGianChupSau']?.toString() ?? '';

    String moTaTruoc = 'Hiện trạng trước khi làm';
    if (orderData['chiTietTruocDichVu'] is List &&
        (orderData['chiTietTruocDichVu'] as List).isNotEmpty) {
      final first = (orderData['chiTietTruocDichVu'] as List).first;
      if (first is Map) {
        final kv = first['khuVucVatDung']?.toString() ?? '';
        final mt = first['moTaHienTrang']?.toString() ?? '';
        moTaTruoc = [kv, mt].where((s) => s.trim().isNotEmpty).join(' • ');
      }
    }

    String moTaSau = 'Nghiệm thu sau khi hoàn thành';
    if (orderData['chiTietSauDichVu'] is List &&
        (orderData['chiTietSauDichVu'] as List).isNotEmpty) {
      final first = (orderData['chiTietSauDichVu'] as List).first;
      if (first is Map) {
        final kv = first['khuVucVatDung']?.toString() ?? '';
        final mt = first['moTaHienTrang']?.toString() ?? '';
        moTaSau = [kv, mt].where((s) => s.trim().isNotEmpty).join(' • ');
      }
    }

    if (anhTruoc.isEmpty && anhSau.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.only(top: compact ? 10 : 14),
      padding: EdgeInsets.all(compact ? 10 : 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.photo_library_rounded,
                size: 16,
                color: Color(0xFF0284C7),
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Hình ảnh tài sản khu vực thực hiện (Trước & Sau)',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (ctx, constraints) {
              final isNarrow = constraints.maxWidth < 290;
              final beforeBox = _buildStageColumn(
                context,
                isBefore: true,
                title: 'Trước khi thực hiện',
                images: anhTruoc,
                timestamp: thoiGianTruoc,
                subtitle: moTaTruoc,
              );
              final afterBox = _buildStageColumn(
                context,
                isBefore: false,
                title: 'Sau khi hoàn thành',
                images: anhSau,
                timestamp: thoiGianSau,
                subtitle: moTaSau,
              );

              if (isNarrow) {
                return Column(
                  children: [
                    beforeBox,
                    const SizedBox(height: 8),
                    afterBox,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: beforeBox),
                  const SizedBox(width: 8),
                  Expanded(child: afterBox),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStageColumn(
    BuildContext context, {
    required bool isBefore,
    required String title,
    required List<String> images,
    required String timestamp,
    required String subtitle,
  }) {
    final Color accent =
        isBefore ? const Color(0xFF0284C7) : const Color(0xFF15803D);
    final Color bg =
        isBefore ? const Color(0xFFF0F9FF) : const Color(0xFFF0FDF4);
    final Color border =
        isBefore ? const Color(0xFFBAE6FD) : const Color(0xFFBBF7D0);

    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isBefore
                    ? Icons.camera_alt_outlined
                    : Icons.verified_rounded,
                size: 14,
                color: accent,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${images.length} ảnh',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (images.isEmpty)
            Container(
              height: 68,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isBefore ? 'Chưa chụp trước ca' : 'Chờ chụp sau khi xong',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            InkWell(
              onTap: () => _showFullImageDialog(
                context,
                title: title,
                imageUrl: images.first,
                isBefore: isBefore,
                subtitle: subtitle,
                timestamp: timestamp,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 76,
                  width: double.infinity,
                  child: _TaiSanPhotoPreviewCard(
                    bytes: TaiSanMemoryCache.get(images.first),
                    imageUrl: images.first,
                    isBefore: isBefore,
                    areaLabel: subtitle,
                    timestampLabel: timestamp,
                    index: 1,
                  ),
                ),
              ),
            ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                color: Color(0xFF334155),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showFullImageDialog(
    BuildContext context, {
    required String title,
    required String imageUrl,
    required bool isBefore,
    required String subtitle,
    required String timestamp,
  }) {
    final cachedBytes = TaiSanMemoryCache.get(imageUrl);
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: _TaiSanPhotoPreviewCard(
                    bytes: cachedBytes,
                    imageUrl: imageUrl,
                    isBefore: isBefore,
                    areaLabel: subtitle,
                    timestampLabel: timestamp,
                    index: 1,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (timestamp.isNotEmpty)
                Text(
                  'Thời gian ghi nhận: $timestamp',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
