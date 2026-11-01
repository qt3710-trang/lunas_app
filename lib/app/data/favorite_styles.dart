import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'hair_style_api.dart' show apiBaseUrl;

/// Danh sách mẫu tóc đã lưu (bấm tim), dùng chung cho trang Mẫu,
/// trang chi tiết, Hồ sơ và AI gợi ý.
///
/// Lưu ở 2 nơi, RIÊNG cho từng tài khoản:
///  - Firestore (users/{uid}.favorites) qua API GET/PUT /me  -> bản chính
///  - Trên máy (shared_preferences, "favorites_<uid>")       -> hiện nhanh + dùng khi mất mạng
/// Đăng nhập tài khoản nào thì tự đọc danh sách của tài khoản đó;
/// đăng xuất thì danh sách trống.
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
    _changed();
  }

  /// Thêm (nếu chưa có).
  void add(String id) {
    if (_ids.add(id)) _changed();
  }

  /// Bỏ (nếu đang có).
  void remove(String id) {
    if (_ids.remove(id)) _changed();
  }

  /// Danh sách vừa đổi: báo cho màn hình vẽ lại + lưu (máy và Firestore).
  void _changed() {
    notifyListeners();
    final uid = _uid;
    if (uid == null) return; // chưa đăng nhập thì không lưu
    _saveLocal(uid);
    _pushRemote(); // mất mạng thì bỏ qua, lần sau đăng nhập sẽ đồng bộ lại
  }

  // ---------------------------------------------------------------
  // Đổi người dùng
  // ---------------------------------------------------------------

  Future<void> _onUserChanged(User? user) async {
    _uid = user?.uid;
    _ids.clear();
    notifyListeners();

    final uid = _uid;
    if (user == null || uid == null) return; // đăng xuất -> danh sách trống

    // 1. Hiện ngay bản trên máy cho nhanh.
    final local = await _loadLocal(uid);
    if (_uid != uid) return; // trong lúc chờ đã đổi người khác -> thôi
    _ids.addAll(local);
    notifyListeners();

    // 2. Hỏi Firestore (qua API) để lấy bản chính.
    final data = await _fetchRemote(user);
    if (_uid != uid) return;
    if (data == null) return; // mất mạng / API lỗi -> dùng tạm bản trên máy

    final remote = data['favorites'];
    if (remote is List) {
      // Firestore đã có danh sách -> dùng bản trên Firestore.
      _ids
        ..clear()
        ..addAll(remote.whereType<String>());
      notifyListeners();
      await _saveLocal(uid);
    } else if (local.isNotEmpty) {
      // Firestore chưa có danh sách, trên máy lại có (tim từ trước) -> chuyển lên.
      await _pushRemote();
    }
  }

  // ---------------------------------------------------------------
  // Trên máy
  // ---------------------------------------------------------------

  Future<List<String>> _loadLocal(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('favorites_$uid') ?? const [];
  }

  Future<void> _saveLocal(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites_$uid', _ids.toList());
  }

  // ---------------------------------------------------------------
  // Firestore qua API /me
  // ---------------------------------------------------------------

  /// GET /me -> toàn bộ hồ sơ (trong đó có favorites). Lỗi -> null.
  Future<Map<String, dynamic>?> _fetchRemote(User user) async {
    try {
      final token = await user.getIdToken();
      final res = await http
          .get(
            Uri.parse('$apiBaseUrl/me'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return null;
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// PUT /me với chỉ trường favorites (các trường hồ sơ khác giữ nguyên).
  Future<void> _pushRemote() async {
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token == null) return;
      await http
          .put(
            Uri.parse('$apiBaseUrl/me'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'favorites': _ids.toList()}),
          )
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      // Mất mạng -> bỏ qua, bản trên máy vẫn còn.
    }
  }
}

final favoriteStyles = FavoriteStyles();