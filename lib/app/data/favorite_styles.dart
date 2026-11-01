import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Danh sách mẫu tóc đã lưu (bấm tim), dùng chung cho trang Mẫu,
/// trang chi tiết, Hồ sơ và AI gợi ý.
///
/// Lưu trên máy (shared_preferences), RIÊNG cho từng tài khoản:
/// ô nhớ tên "favorites_<uid>". Đăng nhập tài khoản nào thì tự đọc
/// danh sách của tài khoản đó; đăng xuất thì danh sách trống.
/// Sau này có thể chuyển sang lưu trên server.
class FavoriteStyles extends ChangeNotifier {
  FavoriteStyles() {
    // Mỗi khi đăng nhập / đăng xuất, Firebase báo về -> đọc lại danh sách.
    FirebaseAuth.instance.authStateChanges().listen(_onUserChanged);
  }

  final Set<String> _ids = {}; // giữ thứ tự thêm vào: mẫu mới lưu nằm cuối
  String? _uid;

  int get count => _ids.length;

  bool contains(String id) => _ids.contains(id);

  /// Danh sách mã mẫu đã lưu (cũ trước, mới sau).
  List<String> get ids => List.unmodifiable(_ids);

  /// Bấm tim: chưa có thì thêm, có rồi thì bỏ.
  void toggle(String id) {
    if (!_ids.remove(id)) _ids.add(id);
    notifyListeners();
    _save();
  }

  /// Thêm (nếu chưa có).
  void add(String id) {
    if (_ids.add(id)) {
      notifyListeners();
      _save();
    }
  }

  /// Bỏ (nếu đang có).
  void remove(String id) {
    if (_ids.remove(id)) {
      notifyListeners();
      _save();
    }
  }

  /// Đổi người dùng: xoá danh sách cũ, đọc danh sách của người mới.
  Future<void> _onUserChanged(User? user) async {
    _uid = user?.uid;
    _ids.clear();
    final uid = _uid;
    if (uid != null) {
      final prefs = await SharedPreferences.getInstance();
      _ids.addAll(prefs.getStringList('favorites_$uid') ?? const []);
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final uid = _uid;
    if (uid == null) return; // chưa đăng nhập thì không lưu
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites_$uid', _ids.toList());
  }
}

final favoriteStyles = FavoriteStyles();