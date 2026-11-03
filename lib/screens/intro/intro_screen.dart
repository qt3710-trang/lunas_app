import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../widgets/lunas_decor.dart';
import '../../widgets/lunas_logo.dart';

const _bg = PastelColors.bg;
const _blush = PastelColors.blush;
const _mint = PastelColors.mint;
const _peach = PastelColors.peach;
const _gold = PastelColors.gold;

/// GD1: Màn giới thiệu – logo + nút "Chạm để bắt đầu".
class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: _bg,
        body: Stack(
          children: [
            const Positioned.fill(child: CustomPaint(painter: _WavesPainter())),
            const _Sparkle(top: 0.30, left: 0.78, size: 18),
            const _Sparkle(top: 0.58, left: 0.12, size: 12),
            const _Sparkle(top: 0.61, left: 0.20, size: 8),
            const _Sparkle(top: 0.72, left: 0.88, size: 14),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          children: [
                            const Spacer(flex: 2),
                            const LunasLogo(),
                            const SizedBox(height: 36),
                            const Text(
                              'Khám phá vẻ đẹp của bạn\nbắt đầu từ mái tóc',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textDark,
                                fontSize: 13,
                                height: 1.6,
                              ),
                            ),
                            const Spacer(flex: 3),
                            Center(
                              child: GradientButton(
                                onPressed: () => context.go('/login'),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Chạm để bắt đầu'),
                                    SizedBox(width: 10),
                                    Icon(Icons.arrow_forward),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                            const _Footer(),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 70, child: FadeLine()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '✦',
                style: TextStyle(fontSize: 10, color: AppColors.teal),
              ),
            ),
            SizedBox(width: 70, child: FadeLine(reverse: true)),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'BEAUTY  •  HAIR  •  STYLE',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 3,
            color: AppColors.textGrey.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}

/// Ngôi sao lấp lánh, vị trí tính theo tỉ lệ màn hình.
class _Sparkle extends StatelessWidget {
  const _Sparkle({required this.top, required this.left, required this.size});

  final double top;
  final double left;
  final double size;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    return Positioned(
      top: screen.height * top,
      left: screen.width * left,
      child: Sparkle(size: size),
    );
  }
}

/// Nền: các mảng màu pastel ở góc trên và các lớp sóng uốn lượn ở dưới.
class _WavesPainter extends CustomPainter {
  const _WavesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Góc trên trái: hồng phấn.
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(w * 0.45, 0)
        ..cubicTo(w * 0.30, h * 0.05, w * 0.15, h * 0.08, 0, h * 0.20)
        ..close(),
      Paint()
        ..shader = LinearGradient(
          colors: [_blush.withValues(alpha: 0.75), _blush.withValues(alpha: 0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromLTWH(0, 0, w * 0.45, h * 0.2)),
    );

    // Góc trên phải: xanh bạc hà.
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.55, 0)
        ..lineTo(w, 0)
        ..lineTo(w, h * 0.16)
        ..cubicTo(w * 0.85, h * 0.10, w * 0.75, h * 0.03, w * 0.55, 0)
        ..close(),
      Paint()
        ..shader = LinearGradient(
          colors: [_mint.withValues(alpha: 0), _mint.withValues(alpha: 0.8)],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ).createShader(Rect.fromLTWH(w * 0.55, 0, w * 0.45, h * 0.16)),
    );

    // Các lớp sóng phía dưới, vẽ từ sau ra trước.
    _wave(
      canvas,
      size,
      startY: 0.62,
      endY: 0.70,
      c1: Offset(0.35, 0.55),
      c2: Offset(0.65, 0.82),
      colors: [_mint.withValues(alpha: 0.55), _blush.withValues(alpha: 0.35)],
    );
    _wave(
      canvas,
      size,
      startY: 0.70,
      endY: 0.66,
      c1: Offset(0.30, 0.80),
      c2: Offset(0.70, 0.60),
      colors: [_blush.withValues(alpha: 0.55), _peach.withValues(alpha: 0.45)],
    );
    _wave(
      canvas,
      size,
      startY: 0.76,
      endY: 0.74,
      c1: Offset(0.40, 0.70),
      c2: Offset(0.65, 0.84),
      colors: [_mint.withValues(alpha: 0.6), _mint.withValues(alpha: 0.25)],
    );
    _wave(
      canvas,
      size,
      startY: 0.86,
      endY: 0.80,
      c1: Offset(0.35, 0.80),
      c2: Offset(0.70, 0.90),
      colors: [_bg.withValues(alpha: 0.9), _bg.withValues(alpha: 0.7)],
    );

    // Đường chỉ vàng mảnh lượn qua.
    canvas.drawPath(
      Path()
        ..moveTo(0, h * 0.66)
        ..cubicTo(w * 0.35, h * 0.58, w * 0.60, h * 0.78, w, h * 0.64),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = _gold.withValues(alpha: 0.7),
    );
  }

  void _wave(
    Canvas canvas,
    Size size, {
    required double startY,
    required double endY,
    required Offset c1,
    required Offset c2,
    required List<Color> colors,
  }) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(0, h * startY)
      ..cubicTo(w * c1.dx, h * c1.dy, w * c2.dx, h * c2.dy, w, h * endY)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(colors: colors)
            .createShader(Rect.fromLTWH(0, h * 0.5, w, h * 0.5)),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
