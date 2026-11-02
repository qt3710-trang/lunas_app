import 'package:flutter/foundation.dart';

import 'hair_style.dart';

/// Mẫu tóc (và màu) người dùng chọn ở tab Mẫu để mang sang tab Đặt lịch.
class BookingChoice {
  const BookingChoice({required this.style, required this.color});

  final HairStyle style;
  final HairColor color;

  /// Ảnh theo màu đã chọn (có thể không có).
  String? get imageUrl => style.imageFor(color);

  /// Giá dạng số (đồng). Mẫu ghi "Từ 250.000đ" thì ra 250000.
  int get price => parsePriceVnd(style.price);

  /// Thời lượng dạng số (phút). Mẫu ghi "45–60 phút" thì ra 60.
  int get durationMinutes => parseDurationMinutes(style.duration);
}

/// Giữ mẫu đang được chọn để đặt lịch. Màn Đặt lịch lắng nghe cái này.
class BookingSelection extends ValueNotifier<BookingChoice?> {
  BookingSelection() : super(null);

  void choose(HairStyle style, HairColor color) {
    value = BookingChoice(style: style, color: color);
  }

  void clear() => value = null;
}

final bookingSelection = BookingSelection();

/// Lấy con số đầu tiên trong chuỗi giá: "Từ 250.000đ" -> 250000.
int parsePriceVnd(String text) {
  final match = RegExp(r'\d[\d.,]*').firstMatch(text);
  if (match == null) return 0;
  final digits = match.group(0)!.replaceAll(RegExp(r'[.,]'), '');
  return int.tryParse(digits) ?? 0;
}

/// Lấy số lớn nhất trong chuỗi thời lượng: "45–60 phút" -> 60.
/// Không đọc được thì mặc định 60 phút.
int parseDurationMinutes(String text) {
  final numbers = RegExp(
    r'\d+',
  ).allMatches(text).map((m) => int.parse(m.group(0)!)).toList();
  if (numbers.isEmpty) return 60;
  final longest = numbers.reduce((a, b) => a > b ? a : b);
  return longest < 1 ? 60 : longest;
}