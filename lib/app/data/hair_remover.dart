import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show decodeImageFromList;
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// Xoá tóc thật trong ảnh tĩnh (chỉ dùng cho màn "Thử qua Ảnh").
///
/// 1. Model MediaPipe "selfie multiclass" (chạy trên máy) chia ảnh thành
///    6 vùng: nền, tóc, da người, da mặt, quần áo, khác.
/// 2. Vùng tóc được lấp bằng màu xung quanh (nền, da người, quần áo) theo kiểu
///    "pull-push": thu nhỏ dần ảnh để lấy màu trung bình, rồi phóng ngược lên.
/// Màn ảnh chỉ dùng ảnh này BÊN NGOÀI đường viền mặt; trong mặt vẫn là ảnh gốc
/// (mặt, trán, tóc mái thật lọt vào lỗ mặt của tóc giả trông tự nhiên hơn).
///
/// Ảnh nền trơn thì xoá gần như sạch; nền nhiều chi tiết sẽ thấy vệt nhoè.
class HairRemover {
  static const _modelAsset = 'assets/models/selfie_multiclass_256x256.tflite';

  static Uint8List? _model;

  /// Trả về ảnh đã xoá tóc, cùng kích thước (đã xoay theo EXIF) với ảnh gốc.
  static Future<ui.Image> remove(File file) async {
    final model = _model ??= (await rootBundle.load(_modelAsset)).buffer
        .asUint8List();

    final source = await decodeImageFromList(await file.readAsBytes());
    final w = source.width;
    final h = source.height;
    final data = await source.toByteData(format: ui.ImageByteFormat.rawRgba);
    source.dispose();
    if (data == null) throw StateError('Không đọc được điểm ảnh');

    // Chạy model + lấp tóc trong isolate riêng để không giật giao diện.
    final out = await compute(
      _removeHair,
      _Job(model, data.buffer.asUint8List(), w, h),
    );

    final done = Completer<ui.Image>();
    ui.decodeImageFromPixels(out, w, h, ui.PixelFormat.rgba8888, done.complete);
    return done.future;
  }
}

class _Job {
  const _Job(this.model, this.rgba, this.width, this.height);

  final Uint8List model;
  final Uint8List rgba;
  final int width;
  final int height;
}

const _segSize = 256; // model nhận ảnh 256 x 256
const _workSize = 512; // cạnh dài của ảnh nhỏ dùng để lấp tóc
const _hairClass = 1;
const _faceSkinClass = 3;

Uint8List _removeHair(_Job job) {
  final w = job.width, h = job.height, src = job.rgba;

  // ---- 1. Phân vùng bằng model (ảnh kéo giãn về 256 x 256, giá trị -1..1) ----
  final input = Float32List(_segSize * _segSize * 3);
  for (var y = 0; y < _segSize; y++) {
    for (var x = 0; x < _segSize; x++) {
      final sx = (x + 0.5) * w / _segSize - 0.5;
      final sy = (y + 0.5) * h / _segSize - 0.5;
      for (var c = 0; c < 3; c++) {
        input[(y * _segSize + x) * 3 + c] =
            _sample(src, w, h, 4, c, sx, sy) / 127.5 - 1;
      }
    }
  }
  final interpreter = Interpreter.fromBuffer(job.model);
  late final Float32List scores;
  try {
    interpreter.allocateTensors();
    interpreter.getInputTensor(0).data = input.buffer.asUint8List();
    interpreter.invoke();
    scores = Uint8List.fromList(interpreter.getOutputTensor(0).data).buffer
        .asFloat32List();
  } finally {
    interpreter.close();
  }
  const classes = 6;
  final label = Uint8List(_segSize * _segSize);
  for (var i = 0; i < label.length; i++) {
    var best = 0;
    for (var c = 1; c < classes; c++) {
      if (scores[i * classes + c] > scores[i * classes + best]) best = c;
    }
    label[i] = best;
  }

  // ---- 2. Ảnh nhỏ để lấp tóc ----
  final k = _workSize / math.max(w, h);
  final ww = math.max(1, (w * k).round());
  final wh = math.max(1, (h * k).round());
  final work = Float32List(ww * wh * 3);
  final hair = Float32List(ww * wh);
  final face = Uint8List(ww * wh);
  for (var y = 0; y < wh; y++) {
    for (var x = 0; x < ww; x++) {
      final i = y * ww + x;
      final sx = (x + 0.5) * w / ww - 0.5;
      final sy = (y + 0.5) * h / wh - 0.5;
      for (var c = 0; c < 3; c++) {
        work[i * 3 + c] = _sample(src, w, h, 4, c, sx, sy);
      }
      final lx = ((x + 0.5) * _segSize / ww).floor().clamp(0, _segSize - 1);
      final ly = ((y + 0.5) * _segSize / wh).floor().clamp(0, _segSize - 1);
      final l = label[ly * _segSize + lx];
      if (l == _hairClass) hair[i] = 1;
      if (l == _faceSkinClass) face[i] = 1;
    }
  }

  // ---- 3. Nới rộng vùng tóc một chút rồi làm mềm mép ----
  const grow = 6;
  var mask = _maxFilter(hair, ww, wh, grow);
  mask = _boxBlur(_boxBlur(mask, ww, wh, grow ~/ 2), ww, wh, grow ~/ 2);

  // ---- 4. Lấp vùng tóc bằng màu nền / da người / quần áo xung quanh (pull-push) ----
  // Không lấy màu da mặt để khỏi loang quầng sáng quanh đầu. Vùng trong đường
  // viền mặt thì màn ảnh hiện ảnh gốc đè lên, nên không cần lấp đẹp chỗ đó.
  final weight = Float32List(ww * wh);
  for (var i = 0; i < weight.length; i++) {
    weight[i] = mask[i] < 0.02 && face[i] == 0 ? 1 : 0;
  }
  var fill = _pullPush(work, weight, ww, wh);
  fill = _boxBlur(fill, ww, wh, 1, channels: 3);

  // ---- 5. Trộn vào ảnh gốc cỡ đầy đủ ----
  final out = Uint8List(w * h * 4);
  for (var y = 0; y < h; y++) {
    final sy = (y + 0.5) * wh / h - 0.5;
    for (var x = 0; x < w; x++) {
      final sx = (x + 0.5) * ww / w - 0.5;
      final i = (y * w + x) * 4;
      final a = _sampleF(mask, ww, wh, 1, 0, sx, sy);
      for (var c = 0; c < 3; c++) {
        final f = _sampleF(fill, ww, wh, 3, c, sx, sy);
        out[i + c] = (src[i + c] * (1 - a) + f * a).round().clamp(0, 255);
      }
      out[i + 3] = 255;
    }
  }
  return out;
}

/// Lấy giá trị kênh [c] tại toạ độ thực (x, y) theo kiểu bilinear.
double _sample(Uint8List p, int w, int h, int ch, int c, double x, double y) {
  x = x.clamp(0, w - 1).toDouble();
  y = y.clamp(0, h - 1).toDouble();
  final x0 = x.floor(), y0 = y.floor();
  final x1 = math.min(x0 + 1, w - 1), y1 = math.min(y0 + 1, h - 1);
  final fx = x - x0, fy = y - y0;
  final a = p[(y0 * w + x0) * ch + c], b = p[(y0 * w + x1) * ch + c];
  final d = p[(y1 * w + x0) * ch + c], e = p[(y1 * w + x1) * ch + c];
  return (a * (1 - fx) + b * fx) * (1 - fy) + (d * (1 - fx) + e * fx) * fy;
}

double _sampleF(
  Float32List p,
  int w,
  int h,
  int ch,
  int c,
  double x,
  double y,
) {
  x = x.clamp(0, w - 1).toDouble();
  y = y.clamp(0, h - 1).toDouble();
  final x0 = x.floor(), y0 = y.floor();
  final x1 = math.min(x0 + 1, w - 1), y1 = math.min(y0 + 1, h - 1);
  final fx = x - x0, fy = y - y0;
  final a = p[(y0 * w + x0) * ch + c], b = p[(y0 * w + x1) * ch + c];
  final d = p[(y1 * w + x0) * ch + c], e = p[(y1 * w + x1) * ch + c];
  return (a * (1 - fx) + b * fx) * (1 - fy) + (d * (1 - fx) + e * fx) * fy;
}

/// Mỗi điểm lấy giá trị lớn nhất trong ô vuông bán kính [r] (nới rộng vùng).
Float32List _maxFilter(Float32List src, int w, int h, int r) {
  final tmp = Float32List(w * h);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      var m = 0.0;
      for (var xx = math.max(0, x - r); xx <= math.min(w - 1, x + r); xx++) {
        m = math.max(m, src[y * w + xx]);
      }
      tmp[y * w + x] = m;
    }
  }
  final out = Float32List(w * h);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      var m = 0.0;
      for (var yy = math.max(0, y - r); yy <= math.min(h - 1, y + r); yy++) {
        m = math.max(m, tmp[yy * w + x]);
      }
      out[y * w + x] = m;
    }
  }
  return out;
}

/// Làm mờ trung bình trong ô vuông bán kính [r], tách 2 chiều cho nhanh.
Float32List _boxBlur(Float32List src, int w, int h, int r, {int channels = 1}) {
  if (r <= 0) return src;
  Float32List pass(Float32List p, bool horizontal) {
    final out = Float32List(p.length);
    final len = horizontal ? w : h, lines = horizontal ? h : w;
    for (var line = 0; line < lines; line++) {
      int idx(int i) => horizontal ? line * w + i : i * w + line;
      for (var c = 0; c < channels; c++) {
        for (var i = 0; i < len; i++) {
          var sum = 0.0;
          var n = 0;
          for (var j = math.max(0, i - r); j <= math.min(len - 1, i + r); j++) {
            sum += p[idx(j) * channels + c];
            n++;
          }
          out[idx(i) * channels + c] = sum / n;
        }
      }
    }
    return out;
  }

  return pass(pass(src, true), false);
}

/// Lấp các điểm có [weight] = 0 bằng màu của các điểm xung quanh.
/// "Pull": thu nhỏ một nửa, chỉ trung bình các điểm có màu.
/// "Push": phóng ngược lên (bilinear) và đổ vào chỗ còn trống.
Float32List _pullPush(Float32List color, Float32List weight, int w, int h) {
  if (w <= 1 || h <= 1) {
    final sum = [0.0, 0.0, 0.0];
    var total = 0.0;
    for (var i = 0; i < w * h; i++) {
      for (var c = 0; c < 3; c++) {
        sum[c] += color[i * 3 + c] * weight[i];
      }
      total += weight[i];
    }
    final out = Float32List(w * h * 3);
    for (var i = 0; i < w * h; i++) {
      for (var c = 0; c < 3; c++) {
        out[i * 3 + c] = total > 0 ? sum[c] / total : 0;
      }
    }
    return out;
  }

  final w2 = (w + 1) ~/ 2, h2 = (h + 1) ~/ 2;
  final cc = Float32List(w2 * h2 * 3);
  final cw = Float32List(w2 * h2);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final i = y * w + x, j = (y ~/ 2) * w2 + x ~/ 2;
      final wt = weight[i];
      cw[j] += wt;
      for (var c = 0; c < 3; c++) {
        cc[j * 3 + c] += color[i * 3 + c] * wt;
      }
    }
  }
  for (var j = 0; j < w2 * h2; j++) {
    final s = cw[j];
    for (var c = 0; c < 3; c++) {
      cc[j * 3 + c] = s > 0 ? cc[j * 3 + c] / s : 0;
    }
    cw[j] = math.min(s, 1);
  }
  final coarse = _pullPush(cc, cw, w2, h2);

  final out = Float32List(w * h * 3);
  for (var y = 0; y < h; y++) {
    final sy = (y + 0.5) / 2 - 0.5;
    for (var x = 0; x < w; x++) {
      final sx = (x + 0.5) / 2 - 0.5;
      final i = y * w + x;
      final wt = weight[i];
      for (var c = 0; c < 3; c++) {
        final up = _sampleF(coarse, w2, h2, 3, c, sx, sy);
        out[i * 3 + c] = color[i * 3 + c] * wt + up * (1 - wt);
      }
    }
  }
  return out;
}
