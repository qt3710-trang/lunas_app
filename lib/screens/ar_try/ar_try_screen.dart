import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import '../../app/data/hair_ar_assets.dart';
import '../../app/data/hair_fit.dart';

/// Màn hình "Thử tóc AR": mở camera trước, nhận diện khuôn mặt theo thời gian thực
/// và vẽ ảnh tóc lên đầu (bước 1: dùng ảnh tạm, bước sau thay bằng PNG tóc thật).
class ArTryOnScreen extends StatefulWidget {
  const ArTryOnScreen({super.key});

  @override
  State<ArTryOnScreen> createState() => _ArTryOnScreenState();
}

class _ArTryOnScreenState extends State<ArTryOnScreen>
    with WidgetsBindingObserver {
  // ------------------------------------------------------------------
  // CÁC SỐ ĐỂ CHỈNH CHO TÓC KHỚP ĐẦU HƠN (sửa rồi bấm hot reload là thấy)
  // ------------------------------------------------------------------
  // Ảnh tóc lấy từ selectedArHair (link imageAR trên Cloudinary, xem hair_ar_assets.dart).
  // Cỡ và vị trí tóc do FittedHair tự tính theo lỗ mặt của từng ảnh; số chỉnh
  // to/nhỏ, cao/thấp nằm ở đầu file hair_fit.dart (dùng chung với màn ảnh).

  /// Nếu đầu nghiêng một bên mà tóc nghiêng ngược chiều, đổi thành -1.0.
  static const double tiltSign = 1.0;

  static const _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  CameraController? _controller;
  CameraDescription? _camera;
  String? _error;
  bool _busy = false;
  bool _starting = false;

  /// Tab AR có đang hiện không. Các tab khác vẫn giữ màn này sống ở chế độ ẩn,
  /// nên phải tự tắt camera khi rời tab để đỡ hao pin.
  bool _active = false;

  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(performanceMode: FaceDetectorMode.fast),
  );
  final ValueNotifier<_FaceInfo?> _face = ValueNotifier<_FaceInfo?>(null);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    selectedArHair.addListener(_onHairChanged);
  }

  void _onHairChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // go_router tắt TickerMode ở các tab đang ẩn.
    final active = TickerMode.valuesOf(context).enabled;
    if (active == _active) return;
    _active = active;
    active ? _start() : _stop();
  }

  @override
  void dispose() {
    selectedArHair.removeListener(_onHairChanged);
    WidgetsBinding.instance.removeObserver(this);
    _stop();
    _detector.close();
    _face.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _stop();
      if (mounted) setState(() {});
    } else if (state == AppLifecycleState.resumed && _active) {
      _start();
    }
  }

  Future<void> _start() async {
    if (_starting || _controller != null) return;
    _starting = true;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _setError('Không tìm thấy camera trên thiết bị.');
        return;
      }
      final cam = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        cam,
        ResolutionPreset.high,
        enableAudio: false,
        // Định dạng ML Kit đọc được: Android dùng nv21, iOS dùng bgra8888.
        imageFormatGroup: Platform.isIOS
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.nv21,
      );
      await controller.initialize();
      // Trong lúc chờ mở camera mà đã rời tab / đóng màn thì tắt luôn.
      if (!mounted || !_active) {
        await controller.dispose();
        return;
      }
      _camera = cam;
      _controller = controller;
      await controller.startImageStream(_onFrame);
      if (mounted) setState(() => _error = null);
    } on CameraException catch (e) {
      _setError(
        e.code == 'CameraAccessDenied' ||
                e.code == 'CameraAccessDeniedWithoutPrompt'
            ? 'Bạn chưa cho phép dùng camera. Hãy vào Cài đặt > Ứng dụng > LUNAS > Quyền để bật Camera.'
            : 'Lỗi camera: ${e.description ?? e.code}',
      );
    } catch (e) {
      _setError('Không mở được camera: $e');
    } finally {
      _starting = false;
    }
  }

  void _setError(String message) {
    if (mounted) setState(() => _error = message);
  }

  Future<void> _stop() async {
    final c = _controller;
    _controller = null;
    _face.value = null;
    if (c == null) return;
    try {
      if (c.value.isStreamingImages) await c.stopImageStream();
    } catch (_) {}
    try {
      await c.dispose();
    } catch (_) {}
  }

  // ------------------------------------------------------------------
  // Mỗi khung hình camera: nhận diện mặt rồi lưu vị trí để vẽ tóc.
  // ------------------------------------------------------------------
  Future<void> _onFrame(CameraImage image) async {
    if (_busy) return;
    _busy = true;
    try {
      final input = _toInputImage(image);
      final rotation = input?.metadata?.rotation;
      if (input == null || rotation == null) return;

      final faces = await _detector.processImage(input);
      if (!mounted) return;
      if (faces.isEmpty) {
        _face.value = null;
        return;
      }
      // Lấy khuôn mặt to nhất trong khung hình.
      faces.sort(
        (a, b) => (b.boundingBox.width * b.boundingBox.height).compareTo(
          a.boundingBox.width * a.boundingBox.height,
        ),
      );
      final f = faces.first;

      // Ảnh đã xoay thẳng đứng: nếu xoay 90/270 độ thì rộng và cao đổi chỗ.
      final swap =
          rotation == InputImageRotation.rotation90deg ||
          rotation == InputImageRotation.rotation270deg;
      final w = image.width.toDouble();
      final h = image.height.toDouble();
      _face.value = _FaceInfo(
        box: f.boundingBox,
        rollDeg: f.headEulerAngleZ ?? 0,
        imageSize: swap ? Size(h, w) : Size(w, h),
      );
    } catch (_) {
      // Bỏ qua khung hình lỗi, chờ khung tiếp theo.
    } finally {
      _busy = false;
    }
  }

  InputImage? _toInputImage(CameraImage image) {
    final controller = _controller;
    final camera = _camera;
    if (controller == null || camera == null) return null;

    var compensation = _orientations[controller.value.deviceOrientation];
    if (compensation == null) return null;
    final sensor = camera.sensorOrientation;
    if (camera.lensDirection == CameraLensDirection.front) {
      compensation = (sensor + compensation) % 360;
    } else {
      compensation = (sensor - compensation + 360) % 360;
    }
    final rotation = InputImageRotationValue.fromRawValue(compensation);
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    final ok = Platform.isIOS
        ? format == InputImageFormat.bgra8888
        : format == InputImageFormat.nv21;
    if (!ok || image.planes.length != 1) return null;
    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format!,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  // ------------------------------------------------------------------
  // Giao diện
  // ------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _content(),
        // Mở từ màn chọn (ArMenuScreen) nên có nút quay lại.
        if (Navigator.of(context).canPop())
          const Positioned(
            left: 8,
            top: 8,
            child: SafeArea(
              child: BackButton(
                style: ButtonStyle(
                  foregroundColor: WidgetStatePropertyAll(Colors.white),
                  backgroundColor: WidgetStatePropertyAll(Colors.black38),
                ),
              ),
            ),
          ),
        // Chuyển sang thử bằng ảnh có sẵn (mở thư viện ngay), back thì về lại camera.
        Positioned(
          right: 8,
          top: 8,
          child: SafeArea(
            child: FilledButton.tonalIcon(
              onPressed: () => context.go('/ar/live/photo?pick=gallery'),
              icon: const Icon(Icons.photo_library_outlined, size: 18),
              label: const Text('Chọn ảnh'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _content() {
    final error = _error;
    if (error != null) return _Message(text: error, onRetry: _start);

    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    final preview = c.value.previewSize!; // dạng nằm ngang: rộng > cao

    return LayoutBuilder(
      builder: (context, box) {
        final screen = box.biggest;
        return Stack(
          fit: StackFit.expand,
          children: [
            ClipRect(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: preview.height,
                  height: preview.width,
                  child: CameraPreview(c),
                ),
              ),
            ),
            ValueListenableBuilder<_FaceInfo?>(
              valueListenable: _face,
              builder: (context, face, _) =>
                  face == null ? const SizedBox.shrink() : _hair(screen, face),
            ),
            // Dải chọn kiểu tóc + màu.
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ArHairPicker(),
            ),
            const Positioned(
              left: 16,
              right: 16,
              top: 16,
              child: SafeArea(
                child: Text(
                  'Thử tóc AR',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Đổi toạ độ khuôn mặt (trong ảnh camera) sang toạ độ trên màn hình rồi đặt ảnh tóc.
  Widget _hair(Size screen, _FaceInfo f) {
    final hair = selectedArHair.value;
    if (hair == null) return const SizedBox.shrink();
    final img = f.imageSize;
    // Preview hiển thị kiểu BoxFit.cover nên scale theo cạnh lớn hơn và căn giữa.
    final scale = math.max(
      screen.width / img.width,
      screen.height / img.height,
    );
    final dx = (screen.width - img.width * scale) / 2;
    final dy = (screen.height - img.height * scale) / 2;
    final front = _camera?.lensDirection == CameraLensDirection.front;

    // Camera trước hiển thị như gương nên phải lật trục ngang.
    final w = f.box.width * scale;
    final px = f.box.left * scale + dx;
    final face = Rect.fromLTWH(
      front ? screen.width - px - w : px,
      f.box.top * scale + dy,
      w,
      f.box.height * scale,
    );

    return FittedHair(
      hair: hair,
      target: HairTarget.fromFaceBox(face),
      angle: tiltSign * (front ? 1 : -1) * f.rollDeg * math.pi / 180,
      fallback: const _PlaceholderHair(),
    );
  }
}

class _FaceInfo {
  const _FaceInfo({
    required this.box,
    required this.rollDeg,
    required this.imageSize,
  });

  final Rect box; // khung mặt, toạ độ trong ảnh camera đã xoay thẳng
  final double rollDeg; // độ nghiêng đầu sang hai bên
  final Size imageSize; // kích thước ảnh camera đã xoay thẳng
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

class _Message extends StatelessWidget {
  const _Message({required this.text, required this.onRetry});

  final String text;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    ),
  );
}
