import 'package:flutter/foundation.dart';

/// Danh sách mẫu tóc đã lưu, dùng chung cho trang Mẫu và trang chi tiết.
/// Tạm lưu trong bộ nhớ, sau này có thể lưu vào shared_preferences / server.
class FavoriteStyles extends ChangeNotifier {
  final Set<String> _ids = {};

  int get count => _ids.length;

  bool contains(String id) => _ids.contains(id);

  void toggle(String id) {
    if (!_ids.remove(id)) _ids.add(id);
    notifyListeners();
  }
}

final favoriteStyles = FavoriteStyles();
