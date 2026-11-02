import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'hair_ar_assets.dart';

// ------------------------------------------------------------------
// CÁC SỐ ĐỂ CHỈNH CHO TÓC KHỚP MẶT (dùng chung cho màn camera và màn ảnh)
// ------------------------------------------------------------------

/// Bề ngang lỗ mặt của ảnh tóc so với bề ngang khung mặt ML Kit.
/// Tóc nhỏ quá thì giảm số này (ví dụ 0.75), to quá thì tăng (ví dụ 0.95).
const double holeToFace = 0.85;

/// Chỗ lỗ mặt rộng nhất (ngang lông mày / mắt) nằm ở đâu trong khung mặt ML Kit,
/// tính từ mép trên khung, theo chiều cao khung. Tóc cao quá thì tăng, thấp quá thì giảm.
const double holeRowInFace = 0.3;

// Hai số dưới dùng cho màn ảnh, đặt tóc theo tâm 2 mắt + đường viền mặt của ML Kit
// (đã ghép thử 7 kiểu tóc trên ảnh thật). Tính theo bề ngang mặt ở ngang mắt.

/// Bề ngang lỗ mặt của ảnh tóc so với bề ngang mặt ở ngang mắt.
/// Tóc to quá thì tăng (ví dụ 1.0), nhỏ / che má thì giảm (ví dụ 0.8).
const double holeToFaceAtEyes = 0.9;

/// Dòng lỗ mặt rộng nhất nằm trên đường nối 2 mắt bao nhiêu (theo bề ngang mặt).
/// Tóc thấp quá thì tăng, cao quá thì giảm.
const double holeAboveEyes = 0.11;

/// Chỗ đặt tóc trên màn hình: dòng lỗ mặt rộng nhất của ảnh tóc nằm ở [anchor]
/// và rộng [holeWidth]; tóc xoay / phóng to quanh [center] (tâm mặt).
class HairTarget {
  const HairTarget({
    required this.anchor,
    required this.holeWidth,
    required this.center,
  });

  /// Từ khung mặt ML Kit (dùng cho cả màn camera và màn ảnh).
  factory HairTarget.fromFaceBox(Rect box) => HairTarget(
    anchor: Offset(box.center.dx, box.top + box.height * holeRowInFace),
    holeWidth: box.width * holeToFace,
    center: box.center,
  );

  /// Từ tâm 2 mắt [eyeMid] và bề ngang mặt ở ngang mắt [faceWidth] (màn ảnh).
  factory HairTarget.fromEyes(Offset eyeMid, double faceWidth) => HairTarget(
    anchor: eyeMid - Offset(0, faceWidth * holeAboveEyes),
    holeWidth: faceWidth * holeToFaceAtEyes,
    center: eyeMid,
  );

  final Offset anchor;
  final double holeWidth;
  final Offset center;
}

/// Số đo của một ảnh tóc, tính bằng pixel của chính ảnh đó.
///
/// Các ảnh tóc trên Cloudinary cùng khung 1000 x 1800 nhưng mỗi ảnh vẽ tóc
/// to nhỏ, cao thấp khác nhau, nên app tự đo "lỗ mặt" (khoảng trống giữa
/// hai bên tóc, chỗ khuôn mặt lộ ra) rồi dùng nó để khớp với mặt thật.
class HairFit {
  const HairFit({
    required this.size,
    required this.holeCx,
    required this.holeY,
    required this.holeW,
    this.mask,
  });

  final Size size; // kích thước ảnh tóc
  final double holeCx; // tâm ngang của lỗ mặt
  final double holeY; // dòng lỗ mặt rộng nhất
  final double holeW; // bề ngang lỗ mặt ở dòng đó

  /// Mặt nạ chỉ giữ khối tóc chính (trắng = giữ, trong suốt = ẩn),
  /// để ẩn mẩu đuôi tóc khác bị cắt dính vào ảnh. null = vẽ cả ảnh.
  final ui.Image? mask;

  /// Dùng khi không đo được (ảnh lỗi, ảnh không có lỗ mặt).
  static const fallback = HairFit(
    size: Size(1000, 1800),
    holeCx: 500,
    holeY: 400,
    holeW: 220,
  );
}

final Map<String, Future<HairFit>> _cache = {};

/// Số đo của ảnh tóc, mỗi link chỉ đo một lần.
Future<HairFit> hairFitFor(String url) =>
    _cache.putIfAbsent(url, () => _measureUrl(url));

Future<HairFit> _measureUrl(String url) async {
  try {
    // Cùng NetworkImage với Image.network nên dùng lại ảnh đã tải, không tải 2 lần.
    final info = await _loadImage(NetworkImage(url));
    final image = info.image;
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final w = image.width;
    final h = image.height;
    info.dispose();
    if (data == null) return HairFit.fallback;
    // Đo trong isolate riêng để không giật giao diện.
    final r = await compute(_measure, _Pixels(data.buffer.asUint8List(), w, h));
    if (r == null) return HairFit.fallback;
    final mask = await _maskImage(r);
    final hole = r.hole;
    if (hole == null) {
      // Không thấy lỗ mặt thì dùng số mặc định nhưng vẫn ẩn mẩu tóc thừa.
      const f = HairFit.fallback;
      return HairFit(
        size: Size(w.toDouble(), h.toDouble()),
        holeCx: f.holeCx,
        holeY: f.holeY,
        holeW: f.holeW,
        mask: mask,
      );
    }
    return HairFit(
      size: Size(w.toDouble(), h.toDouble()),
      holeCx: hole[0],
      holeY: hole[1],
      holeW: hole[2],
      mask: mask,
    );
  } catch (_) {
    _cache.remove(url); // lần sau thử đo lại
    return HairFit.fallback;
  }
}

Future<ImageInfo> _loadImage(ImageProvider provider) {
  final done = Completer<ImageInfo>();
  final stream = provider.resolve(ImageConfiguration.empty);
  late final ImageStreamListener listener;
  listener = ImageStreamListener(
    (info, _) {
      stream.removeListener(listener);
      done.complete(info);
    },
    onError: (error, stack) {
      stream.removeListener(listener);
      done.completeError(error, stack);
    },
  );
  stream.addListener(listener);
  return done.future;
}

Future<ui.Image> _maskImage(_Measured r) {
  final done = Completer<ui.Image>();
  ui.decodeImageFromPixels(
    r.mask,
    r.maskW,
    r.maskH,
    ui.PixelFormat.rgba8888,
    done.complete,
  );
  return done.future;
}

class _Pixels {
  const _Pixels(this.rgba, this.width, this.height);

  final Uint8List rgba;
  final int width;
  final int height;
}

class _Measured {
  const _Measured(this.hole, this.mask, this.maskW, this.maskH);

  final List<double>? hole; // [tâm ngang lỗ mặt, dòng rộng nhất, bề ngang]
  final Uint8List mask; // RGBA, mỗi điểm ứng với 1 ô lưới
  final int maskW;
  final int maskH;
}

/// Đo lỗ mặt và làm mặt nạ khối tóc chính. null nếu ảnh trong suốt hoàn toàn.
_Measured? _measure(_Pixels p) {
  const step = 4; // đo trên lưới thưa cho nhanh
  const alphaMin = 40; // điểm mờ hơn coi như trong suốt
  final gw = p.width ~/ step;
  final gh = p.height ~/ step;
  final hairAt = Uint8List(gw * gh);
  for (var y = 0; y < gh; y++) {
    for (var x = 0; x < gw; x++) {
      final a = p.rgba[((y * step) * p.width + x * step) * 4 + 3];
      if (a > alphaMin) hairAt[y * gw + x] = 1;
    }
  }

  // 1. Chỉ giữ khối tóc liền lớn nhất: nhiều ảnh dính mẩu tóc thừa ở mép trên / vụn hai bên.
  final label = Int32List(gw * gh);
  var bestLabel = 0, bestCount = 0, next = 0;
  final queue = Queue<int>();
  for (var i = 0; i < gw * gh; i++) {
    if (hairAt[i] == 0 || label[i] != 0) continue;
    next++;
    label[i] = next;
    queue.add(i);
    var count = 0;
    while (queue.isNotEmpty) {
      final c = queue.removeFirst();
      count++;
      final cx = c % gw, cy = c ~/ gw;
      for (var dy = -1; dy <= 1; dy++) {
        for (var dx = -1; dx <= 1; dx++) {
          final nx = cx + dx, ny = cy + dy;
          if (nx < 0 || ny < 0 || nx >= gw || ny >= gh) continue;
          final n = ny * gw + nx;
          if (hairAt[n] == 1 && label[n] == 0) {
            label[n] = next;
            queue.add(n);
          }
        }
      }
    }
    if (count > bestCount) {
      bestCount = count;
      bestLabel = next;
    }
  }
  if (bestCount == 0) return null;
  bool on(int x, int y) => label[y * gw + x] == bestLabel;

  // Mặt nạ: ô thuộc khối chính, nới rộng thêm 2 ô (8px) để giữ phần tóc mờ ở mép.
  const grow = 2;
  final mask = Uint8List(gw * gh * 4);
  for (var y = 0; y < gh; y++) {
    for (var x = 0; x < gw; x++) {
      if (!on(x, y)) continue;
      for (
        var yy = math.max(0, y - grow);
        yy <= math.min(gh - 1, y + grow);
        yy++
      ) {
        for (
          var xx = math.max(0, x - grow);
          xx <= math.min(gw - 1, x + grow);
          xx++
        ) {
          final i = (yy * gw + xx) * 4;
          mask[i] = mask[i + 1] = mask[i + 2] = mask[i + 3] = 255;
        }
      }
    }
  }
  _Measured result(List<double>? hole) => _Measured(hole, mask, gw, gh);

  // 2. Tâm ngang (trung vị) và bề ngang cả khối tóc.
  final xs = <int>[];
  var top = -1;
  for (var y = 0; y < gh; y++) {
    for (var x = 0; x < gw; x++) {
      if (on(x, y)) {
        xs.add(x);
        if (top < 0) top = y;
      }
    }
  }
  xs.sort();
  final mid = xs[xs.length ~/ 2];
  final full = xs.last - xs.first;

  // 3. Đi từ đỉnh đầu xuống: dòng nào ở giữa trống, hai bên có tóc, khoảng trống
  // đủ rộng (bỏ qua đường ngôi) thì là lỗ mặt. Lấy dòng lỗ rộng nhất ở phần trên.
  var bestW = 0, bestY = 0, bestL = 0, bestR = 0;
  int? holeStart;
  for (var y = top; y < gh; y++) {
    if (on(mid, y)) {
      if (holeStart != null) break; // hết lỗ (cằm / tóc phía dưới)
      continue;
    }
    var l = mid, r = mid;
    while (l > 0 && !on(l, y)) {
      l--;
    }
    while (r < gw - 1 && !on(r, y)) {
      r++;
    }
    if (!on(l, y) || !on(r, y)) {
      if (holeStart != null) break; // một bên hết tóc
      continue;
    }
    var first = 0, last = gw - 1;
    while (!on(first, y)) {
      first++;
    }
    while (!on(last, y)) {
      last--;
    }
    final span = last - first;
    if (span < 0.5 * full || r - l < 0.3 * span) continue;
    holeStart ??= y;
    if (r - l > bestW) {
      bestW = r - l;
      bestY = y;
      bestL = l;
      bestR = r;
    }
    if (y > holeStart + 1.3 * bestW) break;
  }
  if (bestW == 0) return result(null);
  return result([
    (bestL + bestR) * step / 2,
    (bestY * step).toDouble(),
    (bestW * step).toDouble(),
  ]);
}

/// Vẽ ảnh tóc khớp với khuôn mặt. Đặt làm con của một Stack phủ kín vùng hiển thị.
///
/// Toạ độ khuôn mặt tính bằng pixel màn hình (đã đổi từ ảnh / camera sang).
/// [zoom], [shift] là phần người dùng tự chỉnh thêm bằng tay.
class FittedHair extends StatelessWidget {
  const FittedHair({
    super.key,
    required this.hair,
    required this.target,
    required this.angle,
    required this.fallback,
    this.zoom = 1,
    this.shift = Offset.zero,
  });

  final ArHair hair;
  final HairTarget target; // chỗ đặt tóc trên màn hình
  final double angle; // góc xoay tóc, radian
  final Widget fallback;
  final double zoom;
  final Offset shift;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<HairFit>(
      future: hairFitFor(hair.url),
      builder: (context, snap) {
        final fit = snap.data;
        if (fit == null) return const SizedBox.shrink(); // đang đo
        // s = số pixel màn hình ứng với 1 pixel của ảnh tóc.
        final s = target.holeWidth / fit.holeW * zoom;
        // Xoay / phóng to quanh tâm khuôn mặt chứ không quanh giữa ảnh tóc.
        final center = target.center + shift;
        // Điểm trên mặt ứng với dòng lỗ mặt rộng nhất của ảnh tóc.
        final pivot = center + (target.anchor - target.center) * zoom;
        final w = fit.size.width * s;
        final h = fit.size.height * s;
        final left = pivot.dx - fit.holeCx * s;
        final top = pivot.dy - fit.holeY * s;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: left,
              top: top,
              width: w,
              height: h,
              child: IgnorePointer(
                child: Transform.rotate(
                  origin: Offset(
                    center.dx - left - w / 2,
                    center.dy - top - h / 2,
                  ),
                  angle: angle,
                  child: _masked(
                    fit.mask,
                    ArHairImage(hair: hair, fallback: fallback),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Chỉ giữ phần ảnh nằm trong mặt nạ (khối tóc chính), phần còn lại trong suốt.
  static Widget _masked(ui.Image? mask, Widget child) {
    if (mask == null) return child;
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) => ImageShader(
        mask,
        TileMode.clamp,
        TileMode.clamp,
        // Kéo giãn mặt nạ (nhỏ hơn ảnh 4 lần) cho phủ đúng khung ảnh tóc.
        Matrix4.diagonal3Values(
          bounds.width / mask.width,
          bounds.height / mask.height,
          1,
        ).storage,
        filterQuality: FilterQuality.low, // làm mềm mép mặt nạ
      ),
      child: child,
    );
  }
}
