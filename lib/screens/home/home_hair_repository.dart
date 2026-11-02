import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../app/data/hair_style.dart';
import '../../app/data/hair_style_api.dart' show apiBaseUrl;

/// Uses the exact Firestore-backed endpoint and model mapping used by Styles.
/// Loading stays local to Home so an error or empty response never exposes
/// the shared loader's hardcoded fallback catalogue.
Future<List<HairStyle>> loadHomeHairStyles({http.Client? client}) async {
  final uri = Uri.parse('$apiBaseUrl/hair-styles');
  final response = await (client == null ? http.get(uri) : client.get(uri))
      .timeout(const Duration(seconds: 15));
  if (response.statusCode != 200) {
    throw StateError('Không thể tải mẫu tóc (${response.statusCode}).');
  }
  final data = jsonDecode(utf8.decode(response.bodyBytes));
  if (data is! List) {
    throw const FormatException('Danh sách mẫu tóc không hợp lệ.');
  }
  return [
    for (final row in data)
      if (row is Map<String, dynamic>)
        HairStyle.fromJson(row, baseUrl: apiBaseUrl),
  ];
}
