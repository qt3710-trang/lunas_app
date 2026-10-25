import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app/theme.dart';

/// Logo tạm bằng chữ. Khi có file logo thật (PNG/SVG),
/// thay phần Icon bằng Image.asset('assets/images/logo.png').
class LunasLogo extends StatelessWidget {
  const LunasLogo({super.key, this.size = 1.0});

  /// 1.0 = cỡ lớn (màn giới thiệu), 0.7 = cỡ nhỏ hơn (màn đăng nhập).
  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.face_retouching_natural, size: 72 * size, color: AppColors.teal),
        SizedBox(height: 8 * size),
        Text(
          'LUNAS',
          style: GoogleFonts.playfairDisplay(
            fontSize: 48 * size,
            letterSpacing: 6 * size,
            color: AppColors.teal,
          ),
        ),
        Text(
          'HAIR STUDIO',
          style: TextStyle(
            fontSize: 13 * size,
            letterSpacing: 5 * size,
            color: AppColors.teal,
          ),
        ),
        SizedBox(height: 6 * size),
        Text(
          'Your hair, your story',
          style: GoogleFonts.greatVibes(fontSize: 20 * size, color: AppColors.textGrey),
        ),
      ],
    );
  }
}
