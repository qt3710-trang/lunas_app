import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/data/hair_ar_assets.dart';
import '../../app/data/hair_fit.dart';
import '../../app/data/hair_remover.dart';

/// Màn hình "Thử tóc bằng ảnh": người dùng chọn ảnh có sẵn hoặc chụp ảnh mới,
/// app nhận diện khuôn mặt trong ảnh tĩnh rồi đặt ảnh tóc lên đầu.
class StaticTryScreen extends StatefulWidget {
  const StaticTryScreen({super.key, this.pickOnOpen});

  /// Mở xong thì tự mở thư viện / camera luôn (ví dụ bấm "Chọn ảnh" từ màn camera).
  final ImageSource? pickOnOpen;

  @override
  State<StaticTryScreen> createState() => _StaticTryScreenState();
}

class _StaticTryScreenState extends State<StaticTryScreen> {
  // Ảnh tóc lấy từ selectedArHair (link imageAR trên Cloudinary, xem hair_ar_assets.dart).
  // Cỡ và vị trí tóc do FittedHair tự tính theo lỗ mặt của từng ảnh (xem hair_fit.dart).

  /// Nếu đầu nghiêng một bên mà tóc nghiêng ngược chiều, đổi thành -1.0.
  static const double tiltSign = 1.0;

  final ImagePicker _picker = ImagePicker();

  // Ảnh tĩnh không cần nhanh nên dùng chế độ chính xác. Lấy thêm tâm 2 mắt
  // và đường viền mặt để đặt tóc đúng chỗ.
  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      enableLandmarks: true,
      enableContours: true,
    ),
  );

  File? _file;
  _FaceInfo? _face;
  String? _message;
  bool _busy = false;

  // Xoá tóc thật trong ảnh (xem hair_remover.dart). Bật/tắt để so sánh.
  bool _hideOwnHair = true;
  ui.Image? _noHair; // ảnh đã xoá tóc, null = chưa xong / lỗi
  bool _removing = false;
  int _removeJob = 0; // đổi ảnh khác giữa chừng thì bỏ kết quả cũ

  Future<void> _removeOwnHair(File file) async {
    final job = ++_removeJob;
    _noHair?.dispose();
    setState(() {
      _noHair = null;
      _removing = true;
    });
    try {
      final image = await HairRemover.remove(file);
      if (!mounted || job != _removeJob) {
        image.dispose();
        return;
      }
      setState(() => _noHair = image);
    } catch (_) {
      if (mounted && job == _removeJob) {
        setState(() => _message = 'Không xoá được tóc gốc, đang hiện ảnh gốc.');
      }
    } finally {
      if (mounted && job == _removeJob) setState(() => _removing = false);
    }
  }

  // Người dùng tự chỉnh thêm bằng tay (cộng dồn lên vị trí app tự đặt):
  // kéo 1 ngón = dời tóc, chụm 2 ngón = phóng to/thu nhỏ, xoay 2 ngón = xoay tóc.
  Offset _drag = Offset.zero; // dời, tính bằng pixel màn hình
  double _zoom = 1; // phóng to/thu nhỏ quanh tâm khuôn mặt
  double _turn = 0; // góc xoay thêm, radian

  // Giá trị lúc bắt đầu chạm, để cộng dồn trong lúc đang kéo.
  Offset _startFocal = Offset.zero;
  Offset _startDrag = Offset.zero;
  double _startZoom = 1;
  double _startTurn = 0;

  bool get _adjusted => _drag != Offset.zero || _zoom != 1 || _turn != 0;

  void _resetAdjust() {
    _drag = Offset.zero;
    _zoom = 1;
    _turn = 0;
  }

  void _onScaleStart(ScaleStartDetails d) {
    _startFocal = d.focalPoint;
    _startDrag = _drag;
    _startZoom = _zoom;
    _startTurn = _turn;
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    setState(() {
      _drag = _startDrag + (d.focalPoint - _startFocal);
      _zoom = (_startZoom * d.scale).clamp(0.3, 3.0);
      _turn = _startTurn + d.rotation;
    });
  }

  @override
  void initState() {
    super.initState();
    selectedArHair.addListener(_onHairChanged);
    final source = widget.pickOnOpen;
    if (source != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _pick(source);
      });
    }
  }

  void _onHairChanged() {
    // Đổi kiểu / màu tóc thì bỏ phần kéo tay của kiểu cũ, để kiểu mới tự khớp mặt.
    if (mounted) setState(_resetAdjust);
  }

  @override
  void dispose() {
    selectedArHair.removeListener(_onHairChanged);
    _detector.close();
    _noHair?.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------------
  // Chọn / chụp ảnh rồi nhận diện khuôn mặt.
  // ------------------------------------------------------------------
  Future<void> _pick(ImageSource source) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final picked = await _picker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.front,
        // Thu nhỏ ảnh cho nhẹ, ML Kit vẫn nhận diện tốt ở cỡ này.
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (picked == null) return; // người dùng bấm huỷ
      final file = File(picked.path);

      // Lấy kích thước ảnh sau khi đã xoay theo EXIF (giống cách Image.file hiển thị).
      final decoded = await decodeImageFromList(await file.readAsBytes());
      final imageSize = Size(
        decoded.width.toDouble(),
        decoded.height.toDouble(),
      );
      decoded.dispose();

      // ML Kit tự đọc hướng xoay EXIF từ file nên toạ độ trả về là ảnh đã xoay thẳng.
      final faces = await _detector.processImage(
        InputImage.fromFilePath(file.path),
      );
      if (!mounted) return;

      // Không thấy mặt thì vẫn đặt tóc giữa ảnh để người dùng tự kéo vào chỗ.
      var face = _FaceInfo(
        box: Rect.fromCenter(
          center: Offset(imageSize.width / 2, imageSize.height * 0.4),
          width: imageSize.width * 0.4,
          height: imageSize.width * 0.5,
        ),
        rollDeg: 0,
        imageSize: imageSize,
      );
      final found = faces.isNotEmpty;
      if (found) {
        // Lấy khuôn mặt to nhất trong ảnh.
        faces.sort(
          (a, b) => (b.boundingBox.width * b.boundingBox.height).compareTo(
            a.boundingBox.width * a.boundingBox.height,
          ),
        );
        final f = faces.first;
        Offset? at(FaceLandmarkType t) {
          final p = f.landmarks[t]?.position;
          return p == null ? null : Offset(p.x.toDouble(), p.y.toDouble());
        }

        face = _FaceInfo(
          box: f.boundingBox,
          rollDeg: f.headEulerAngleZ ?? 0,
          imageSize: imageSize,
          leftEye: at(FaceLandmarkType.leftEye),
          rightEye: at(FaceLandmarkType.rightEye),
          outline: [
            for (final p in f.contours[FaceContourType.face]?.points ?? [])
              Offset(p.x.toDouble(), p.y.toDouble()),
          ],
        );
      }
      setState(() {
        _file = file;
        _face = face;
        _resetAdjust();
        _message = found
            ? 'Kéo để dời tóc, chụm hoặc xoay 2 ngón để chỉnh cỡ và góc.'
            : 'Không tìm thấy khuôn mặt. Hãy kéo tóc vào đúng vị trí, chụm 2 ngón để chỉnh cỡ.';
      });
      _removeOwnHair(file); // chạy nền, xong thì tự đổi ảnh
    } catch (e) {
      if (mounted) setState(() => _message = 'Không xử lý được ảnh: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ------------------------------------------------------------------
  // Giao diện
  // ------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thử tóc bằng ảnh')),
      body: Column(
        children: [
          Expanded(child: _preview()),
          const ArHairPicker(),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(_message!, textAlign: TextAlign.center),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy
                          ? null
                          : () => _pick(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Chọn ảnh'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _busy ? null : () => _pick(ImageSource.camera),
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Chụp ảnh'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _preview() {
    final file = _file;
    final face = _face;
    if (file == null) {
      return Center(
        child: _busy
            ? const CircularProgressIndicator()
            : const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Chọn một ảnh chân dung hoặc chụp ảnh mới để thử kiểu tóc.',
                  textAlign: TextAlign.center,
                ),
              ),
      );
    }
    return LayoutBuilder(
      builder: (context, box) {
        final area = box.biggest;
        // Chạm ở đâu trong khung ảnh cũng kéo được tóc, không cần trúng đúng sợi tóc.
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onScaleStart: face == null ? null : _onScaleStart,
          onScaleUpdate: face == null ? null : _onScaleUpdate,
          child: ClipRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Cùng kích thước với ảnh gốc nên toạ độ khuôn mặt vẫn khớp.
                if (_hideOwnHair && _noHair != null) ...[
                  RawImage(image: _noHair, fit: BoxFit.contain),
                  // Trong đường viền mặt vẫn hiện ảnh gốc (mặt, trán, mái thật);
                  // chỉ xoá phần tóc thật lòi ra ngoài.
                  if (face != null && face.outline.length > 2)
                    ClipPath(
                      clipper: _OutlineClipper([
                        for (final p in face.keepOutline)
                          _imageToScreen(area, face.imageSize, p),
                      ]),
                      child: Image.file(file, fit: BoxFit.contain),
                    ),
                ] else
                  Image.file(file, fit: BoxFit.contain),
                if (face != null) _hair(area, face),
                Positioned(
                  left: 8,
                  top: 8,
                  child: FilterChip(
                    avatar: _removing
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                    label: Text(
                      _removing && _hideOwnHair
                          ? 'Đang xoá tóc gốc…'
                          : 'Xoá tóc gốc',
                    ),
                    selected: _hideOwnHair,
                    onSelected: (v) => setState(() => _hideOwnHair = v),
                  ),
                ),
                if (_adjusted)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: IconButton.filledTonal(
                      tooltip: 'Đặt lại vị trí tóc',
                      onPressed: () => setState(_resetAdjust),
                      icon: const Icon(Icons.restart_alt),
                    ),
                  ),
                if (_busy) const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Đổi toạ độ khuôn mặt (trong ảnh gốc) sang toạ độ trên màn hình rồi đặt ảnh tóc.
  Widget _hair(Size area, _FaceInfo f) {
    final hair = selectedArHair.value;
    if (hair == null) return const SizedBox.shrink();
    final img = f.imageSize;
    final scale = _fitScale(area, img);
    Offset toScreen(Offset p) => _imageToScreen(area, img, p);

    // Có đủ tâm 2 mắt + đường viền mặt: đặt tóc theo chúng (chính xác nhất),
    // nghiêng tóc theo đường nối 2 mắt. Không có thì dùng khung mặt.
    final eyes = f.eyesLeftToRight;
    final faceW = eyes == null
        ? null
        : _widthAt(f.outline, (eyes.$1.dy + eyes.$2.dy) / 2);
    final HairTarget target;
    final double tilt;
    if (eyes != null && faceW != null) {
      final (a, b) = eyes;
      target = HairTarget.fromEyes(toScreen((a + b) / 2), faceW * scale);
      tilt = math.atan2(b.dy - a.dy, b.dx - a.dx);
    } else {
      final box = f.box;
      target = HairTarget.fromFaceBox(
        Rect.fromPoints(toScreen(box.topLeft), toScreen(box.bottomRight)),
      );
      // Giống camera sau ở màn AR (không lật gương).
      tilt = tiltSign * -1 * f.rollDeg * math.pi / 180;
    }

    return FittedHair(
      hair: hair,
      target: target,
      angle: tilt + _turn,
      zoom: _zoom,
      shift: _drag,
      fallback: const _PlaceholderHair(),
    );
  }
}

/// Ảnh hiển thị kiểu BoxFit.contain: scale theo cạnh nhỏ hơn và căn giữa.
double _fitScale(Size area, Size img) =>
    math.min(area.width / img.width, area.height / img.height);

/// Đổi toạ độ pixel ảnh sang toạ độ màn hình. Ảnh tĩnh không lật gương.
Offset _imageToScreen(Size area, Size img, Offset p) {
  final scale = _fitScale(area, img);
  return Offset(
    p.dx * scale + (area.width - img.width * scale) / 2,
    p.dy * scale + (area.height - img.height * scale) / 2,
  );
}

/// Cắt theo đường viền mặt (đa giác khép kín, toạ độ màn hình).
class _OutlineClipper extends CustomClipper<Path> {
  const _OutlineClipper(this.points);

  final List<Offset> points;

  @override
  Path getClip(Size size) => Path()..addPolygon(points, true);

  @override
  bool shouldReclip(_OutlineClipper old) => old.points != points;
}

class _FaceInfo {
  const _FaceInfo({
    required this.box,
    required this.rollDeg,
    required this.imageSize,
    this.leftEye,
    this.rightEye,
    this.outline = const [],
  });

  final Rect box; // khung mặt, toạ độ trong ảnh đã xoay thẳng
  final double rollDeg; // độ nghiêng đầu sang hai bên
  final Size imageSize; // kích thước ảnh đã xoay thẳng
  final Offset? leftEye; // tâm mắt (null nếu ML Kit không thấy)
  final Offset? rightEye;
  final List<Offset> outline; // đường viền mặt (rỗng nếu không có)

  /// Vùng giữ ảnh gốc khi xoá tóc: đường viền mặt nới rộng 8%, phần trán kéo
  /// cao thêm 35% (tính từ tâm 2 mắt), để trán / tóc thật dưới đường ngôi của
  /// tóc giả không bị lấp thành mảng màu nền.
  List<Offset> get keepOutline {
    final eyes = eyesLeftToRight;
    if (eyes == null) return outline;
    final mid = (eyes.$1 + eyes.$2) / 2;
    return [
      for (final p in outline)
        mid +
            Offset(
              (p.dx - mid.dx) * 1.08,
              (p.dy - mid.dy) * (p.dy < mid.dy ? 1.35 : 1.0),
            ),
    ];
  }

  /// 2 mắt theo thứ tự trái sang phải trên ảnh, null nếu thiếu.
  (Offset, Offset)? get eyesLeftToRight {
    final l = leftEye, r = rightEye;
    if (l == null || r == null) return null;
    return l.dx <= r.dx ? (l, r) : (r, l);
  }
}

/// Bề ngang đường viền mặt (đa giác khép kín) tại dòng [y]. null nếu không cắt.
double? _widthAt(List<Offset> outline, double y) {
  double? lo, hi;
  for (var i = 0; i < outline.length; i++) {
    final a = outline[i], b = outline[(i + 1) % outline.length];
    if ((a.dy - y) * (b.dy - y) > 0 || a.dy == b.dy) continue;
    final x = a.dx + (y - a.dy) / (b.dy - a.dy) * (b.dx - a.dx);
    lo = lo == null ? x : math.min(lo, x);
    hi = hi == null ? x : math.max(hi, x);
  }
  if (lo == null || hi == null || hi - lo <= 0) return null;
  return hi - lo;
}

/// Hình tạm (tròn màu nâu mờ) khi chưa có ảnh tóc thật.
class _PlaceholderHair extends StatelessWidget {
  const _PlaceholderHair();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.fromBorderSide(
        BorderSide(color: Color(0xB37B4B34), width: 10),
      ),
    ),
  );
}
