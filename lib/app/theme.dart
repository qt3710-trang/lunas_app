import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bảng màu LUNAS, lấy theo bản vẽ giao diện.
/// Muốn đổi màu cả app thì chỉ sửa ở đây.
class AppColors {
  static const teal = Color(0xFF5E9C9E); // nút chính, chữ LUNAS
  static const tealLight = Color(0xFFDCEBEA); // nền nút phụ, chip đang chọn
  static const pink = Color(0xFFD63F72); // nút "Thử với AR"
  static const cream = Color(0xFFFBF6F2); // nền app
  static const card = Colors.white;
  static const textDark = Color(0xFF2F3E46);
  static const textGrey = Color(0xFF8A9499);
  static const border = Color(0xFFE6E1DC);
}

class AppTheme {
  /// Font tiêu đề có chân (giống chữ "LUNAS", "Chào mừng bạn trở lại!").
  static TextStyle titleFont({double size = 28, Color color = AppColors.textDark}) =>
      GoogleFonts.playfairDisplay(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.teal,
        primary: AppColors.teal,
        secondary: AppColors.pink,
        surface: AppColors.cream,
      ),
      scaffoldBackgroundColor: AppColors.cream,
    );

    return base.copyWith(
      // Font nội dung hỗ trợ tiếng Việt đầy đủ.
      textTheme: GoogleFonts.beVietnamProTextTheme(base.textTheme).apply(
        bodyColor: AppColors.textDark,
        displayColor: AppColors.textDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.teal,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(color: AppColors.textGrey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
        ),
      ),
    );
  }
}
