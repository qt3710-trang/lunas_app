import 'dart:convert';

import 'package:http/http.dart' as http;

import 'hair_style.dart';

/// Địa chỉ server API (lunas_api) đã đưa lên Vercel.
/// Emulator và điện thoại thật đều dùng được, không cần bật server ở máy.
/// Muốn test server chạy trên máy thì đổi tạm thành 'http://10.0.2.2:3000' (emulator).
const apiBaseUrl = 'https://lunas-app-seven.vercel.app';

/// Tải danh sách kiểu tóc từ API và thay vào biến [hairStyles].
/// Trả về true nếu tải được. Lỗi mạng / server tắt thì giữ nguyên dữ liệu dự phòng.
Future<bool> loadHairStyles() async {
  try {
    final res = await http
        .get(Uri.parse('$apiBaseUrl/hair-styles'))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) return false;

    final list = jsonDecode(utf8.decode(res.bodyBytes)) as List;
    final styles = <HairStyle>[
      for (final j in list)
        if (j is Map<String, dynamic>)
          HairStyle.fromJson(j, baseUrl: apiBaseUrl),
    ];
    if (styles.isEmpty) return false;

    hairStyles = styles;
    return true;
  } catch (_) {
    return false;
  }
}
