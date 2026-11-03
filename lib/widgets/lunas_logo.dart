import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app/theme.dart';
import 'lunas_decor.dart';

/// Logo LUNAS: hình cô gái + chữ "LUNAS / HAIR STUDIO / Your hair, your story".
class LunasLogo extends StatelessWidget {
  const LunasLogo({super.key, this.size = 1.0});

  /// 1.0 = cỡ lớn (màn giới thiệu), ~0.55 = cỡ nhỏ (màn đăng nhập).
  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Làm mờ viền ảnh để không lộ khung vuông trên nền màu.
        ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (rect) => const RadialGradient(
            colors: [Colors.white, Colors.white, Colors.transparent],
            stops: [0, 0.62, 0.72],
          ).createShader(rect),
          child: Image.asset(
            'assets/branding/lunas_logo.png',
            width: 220 * size,
            height: 220 * size,
            fit: BoxFit.contain,
            semanticLabel: 'LUNAS Hair Studio',
          ),
        ),
        Text(
          'LUNAS',
          style: GoogleFonts.playfairDisplay(
            fontSize: 54 * size,
            fontWeight: FontWeight.w500,
            letterSpacing: 6 * size,
            height: 1,
            color: AppColors.teal,
          ),
        ),
        SizedBox(height: 8 * size),
        Text(
          'HAIR STUDIO',
          style: GoogleFonts.playfairDisplay(
            fontSize: 18 * size,
            letterSpacing: 5 * size,
            color: AppColors.teal,
          ),
        ),
        SizedBox(height: 6 * size),
        SizedBox(
          width: 300 * size,
          child: Row(
            children: [
              const Expanded(child: FadeLine()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10 * size),
                child: Text(
                  'Your hair, your story',
                  style: GoogleFonts.greatVibes(
                    fontSize: 22 * size,
                    color: AppColors.teal,
                  ),
                ),
              ),
              const Expanded(child: FadeLine(reverse: true)),
            ],
          ),
        ),
      ],
    );
  }
}
