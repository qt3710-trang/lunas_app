import 'package:flutter/material.dart';

import '../app/theme.dart';

/// Màu pastel dùng cho nền trang trí (màn giới thiệu, đăng nhập...).
class PastelColors {
  static const bg = Color(0xFFFDF9F5); // trùng màu nền của ảnh logo
  static const blush = Color(0xFFF2C9C6);
  static const mint = Color(0xFFBFDCDC);
  static const peach = Color(0xFFF6DCC8);
  static const gold = Color(0xFFE2B98F);
}

/// Nút chính bo tròn, nền teal chuyển sắc, có bóng đổ.
/// [expand] = true thì kéo hết chiều ngang.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.expand = false,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Opacity(
      opacity: enabled ? 1 : 0.7,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [Color(0xFF7DB3B4), AppColors.teal],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.teal.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
              child: DefaultTextStyle.merge(
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                child: IconTheme.merge(
                  data: const IconThemeData(color: Colors.white, size: 20),
                  child: Row(
                    mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [child],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Đường kẻ mảnh mờ dần về một phía.
class FadeLine extends StatelessWidget {
  const FadeLine({super.key, this.reverse = false});

  final bool reverse;

  @override
  Widget build(BuildContext context) {
    final colors = [
      AppColors.teal.withValues(alpha: 0),
      AppColors.teal.withValues(alpha: 0.6),
    ];
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: reverse ? colors.reversed.toList() : colors,
        ),
      ),
    );
  }
}

/// Ngôi sao lấp lánh 4 cánh màu vàng.
class Sparkle extends StatelessWidget {
  const Sparkle({super.key, this.size = 14});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: const _SparklePainter(),
    );
  }
}

class _SparklePainter extends CustomPainter {
  const _SparklePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final k = r * 0.18;
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx + k, c.dy - k, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx + k, c.dy + k, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx - k, c.dy + k, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx - k, c.dy - k, c.dx, c.dy - r)
      ..close();
    canvas.drawPath(path, Paint()..color = PastelColors.gold);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Nền pastel: các vệt màu hồng, bạc hà, đào mờ ở góc và hai bên.
/// Đặt sau nội dung trong một Stack (Positioned.fill).
class PastelBackdrop extends StatelessWidget {
  const PastelBackdrop({super.key});

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: PastelColors.bg,
    child: CustomPaint(
      painter: _PastelBackdropPainter(),
      child: SizedBox.expand(),
    ),
  );
}

class _PastelBackdropPainter extends CustomPainter {
  const _PastelBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    void blob(Offset center, double radius, Color color) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)])
              .createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }

    final w = size.width, h = size.height;
    blob(Offset.zero, w * 0.55, PastelColors.blush.withValues(alpha: .55));
    blob(Offset(w, h * 0.12), w * 0.5, PastelColors.mint.withValues(alpha: .5));
    blob(
      Offset(0, h * 0.62),
      w * 0.45,
      PastelColors.mint.withValues(alpha: .4),
    );
    blob(Offset(w, h), w * 0.6, PastelColors.peach.withValues(alpha: .45));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Nền giống trang Đăng nhập: vệt màu nước hồng ở hai góc và các chấm tròn pastel.
class BubbleBackdrop extends StatelessWidget {
  const BubbleBackdrop({super.key});

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: PastelColors.bg,
    child: CustomPaint(
      painter: _BubbleBackdropPainter(),
      child: SizedBox.expand(),
    ),
  );
}

class _BubbleBackdropPainter extends CustomPainter {
  const _BubbleBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    void blob(Offset center, double radius, Color color) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)])
              .createShader(rect),
      );
    }

    void dot(double x, double y, double r, Color color) =>
        canvas.drawCircle(Offset(w * x, h * y), r, Paint()..color = color);

    // Vệt màu nước ở góc trên trái và góc dưới phải.
    blob(Offset(0, 0), w * 0.55, PastelColors.blush.withValues(alpha: 0.8));
    blob(Offset(w, h), w * 0.6, PastelColors.blush.withValues(alpha: 0.7));

    // Các chấm tròn.
    dot(1.02, 0.17, w * 0.17, PastelColors.mint.withValues(alpha: 0.75));
    dot(0.98, 0.25, w * 0.07, PastelColors.peach);
    dot(0.85, 0.27, 5, PastelColors.peach);
    dot(0.11, 0.18, 12, PastelColors.blush);
    dot(0.0, 0.24, w * 0.06, PastelColors.mint.withValues(alpha: 0.8));
    dot(0.0, 0.84, w * 0.09, PastelColors.peach.withValues(alpha: 0.9));
    dot(1.0, 0.74, w * 0.05, PastelColors.mint.withValues(alpha: 0.8));
    dot(0.09, 0.91, 8, PastelColors.mint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
