import 'package:flutter/foundation.dart';

/// Danh sách mẫu tóc người dùng đã thêm vào Bộ sưu tập của tôi.
class CollectionStyles extends ChangeNotifier {
  final Set<String> _ids = {};

  int get count => _ids.length;

  bool contains(String id) => _ids.contains(id);

  void add(String id) {
    if (_ids.add(id)) notifyListeners();
  }

  void remove(String id) {
    if (_ids.remove(id)) notifyListeners();
  }
}

final collectionStyles = CollectionStyles();
