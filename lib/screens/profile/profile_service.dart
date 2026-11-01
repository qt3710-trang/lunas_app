import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/data/favorite_styles.dart';
import '../../app/data/hair_style.dart';
import '../../app/data/hair_style_api.dart';
import '../../services/auth_service.dart';
import 'profile_models.dart';

/// Nơi DUY NHẤT trang Hồ sơ lấy và lưu dữ liệu.
///
/// ĐÃ THẬT:
///  - id, tên, SĐT: lấy từ Firebase Auth.
///  - Dáng mặt, tông da, phong cách...: lưu trên Firestore qua API
///    (GET /me, PUT /me), kèm một bản trên máy để dùng khi mất mạng.
///  - Mẫu đã lưu: chính là các mẫu bấm tim ở tab Mẫu (favoriteStyles).
///  - AI gợi ý: chọn từ bộ sưu tập kiểu tóc thật, theo vibe (chưa phải AI thật).
///
/// CÒN GIẢ: lịch hẹn.
class ProfileService {
  ProfileService._();
  static final instance = ProfileService._();

  static const _img = 'assets/images/hairstyles';

  /// Hồ sơ dự phòng khi chưa đăng nhập (không nên xảy ra vì router đã chặn).
  static const _guestProfile = UserProfile(id: 'guest', name: 'Khách', phone: '');

  /// Hồ sơ của người đang đăng nhập (giữ trong RAM cho nhanh).
  UserProfile? _profile;

  /// Tên "ô nhớ" trên máy của từng tài khoản: profile_<uid>
  String _keyFor(String uid) => 'profile_$uid';

  // ---------- Lịch hẹn (còn giả) ----------

  /// Lịch hẹn giả, tính ngày theo hôm nay để lúc nào cũng có lịch "sắp tới".
  late final List<Appointment> _appointments = _makeDemoAppointments();

  List<Appointment> _makeDemoAppointments() {
    final now = DateTime.now();
    // day(3, 10) = 3 ngày nữa, lúc 10 giờ. day(-11, 15) = 11 ngày trước, 15 giờ.
    DateTime day(int offset, int hour) =>
        DateTime(now.year, now.month, now.day + offset, hour);

    const salon = 'LUNAS Hair Studio - Quận 1';
    const address = '123 Đường Hoa Mai, Quận 1, TP.HCM';

    return [
      Appointment(
        id: 'a1', code: '#LUNAS1031', serviceName: 'Cắt + Nhuộm',
        salonName: salon, salonAddress: address,
        startTime: day(3, 10), image: '$_img/butterfly_layer.jpg',
        totalPrice: 750000, status: AppointmentStatus.confirmed,
        stylistName: 'Chị Mai (Hair Stylist)',
      ),
      Appointment(
        id: 'a2', code: '#LUNAS0915', serviceName: 'Tạo kiểu layer',
        salonName: salon, salonAddress: address,
        startTime: day(-11, 15), image: '$_img/layer_bong_benh.jpg',
        totalPrice: 300000, status: AppointmentStatus.completed,
      ),
      Appointment(
        id: 'a3', code: '#LUNAS0820', serviceName: 'Nhuộm nâu trà sữa',
        salonName: salon, salonAddress: address,
        startTime: day(-20, 14), image: '$_img/uon_song_tra_sua.jpg',
        totalPrice: 650000, status: AppointmentStatus.completed,
      ),
      Appointment(
        id: 'a4', code: '#LUNAS0712', serviceName: 'Uốn sóng lơi',
        salonName: salon, salonAddress: address,
        startTime: day(-32, 11), image: '$_img/bob_xoan.jpg',
        totalPrice: 450000, status: AppointmentStatus.completed,
      ),
    ];
  }

  // ---------- Hồ sơ (lưu trên Firestore qua API) ----------

  /// Lấy hồ sơ của người ĐANG ĐĂNG NHẬP.
  Future<UserProfile> getProfile() async {
    final user = AuthService.instance.currentUser;
    if (user == null) return _guestProfile;

    // Đã tải rồi và vẫn là người đó -> dùng luôn.
    if (_profile != null && _profile!.id == user.id) return _profile!;

    // 1. Hỏi API (Firestore). 2. Đọc bản trên máy.
    final remote = await _fetchRemote();
    final local = await _loadLocal(user.id);

    UserProfile? saved;
    if (remote != null && _hasProfileData(remote)) {
      // Firestore đã có hồ sơ -> dùng bản trên Firestore.
      saved = UserProfile.fromMap(user.id, remote);
    } else {
      // Firestore chưa có (người mới, hoặc trước đây chỉ lưu trên máy),
      // hoặc mất mạng -> dùng bản trên máy.
      saved = local;
      // Có mạng mà Firestore còn trống, trên máy lại có dữ liệu cũ -> chuyển lên Firestore.
      if (remote != null && local != null) {
        await _pushRemote(local);
      }
    }

    // Tên: ưu tiên tên đã lưu (đổi tên trong Hồ sơ), không có thì lấy tên lúc đăng ký.
    final name = (saved != null && saved.name.isNotEmpty)
        ? saved.name
        : (user.name.isEmpty ? 'Bạn' : user.name);

    _profile = UserProfile(
      id: user.id,
      name: name,
      phone: user.phone, // SĐT luôn lấy từ tài khoản Firebase
      // Người mới: saved == null -> các mục dưới đều TRỐNG.
      favoriteHair: saved?.favoriteHair ?? '',
      styleTags: saved?.styleTags ?? const [],
      faceShape: saved?.faceShape ?? '',
      skinTone: saved?.skinTone ?? '',
      weeklyNotify: saved?.weeklyNotify ?? true,
    );

    await _saveLocal(_profile!); // giữ một bản trên máy để dùng khi mất mạng
    return _profile!;
  }

  /// Lưu hồ sơ sau khi sửa: lên Firestore (qua API) + một bản trên máy.
  /// Đổi tên thì lưu luôn lên Firebase Auth.
  Future<UserProfile> updateProfile(UserProfile profile) async {
    final nameChanged = _profile != null && profile.name != _profile!.name;
    _profile = profile;

    await _saveLocal(profile);
    await _pushRemote(profile); // mất mạng thì bỏ qua, lần sau mở app sẽ đồng bộ lại

    if (nameChanged) {
      try {
        await FirebaseAuth.instance.currentUser?.updateDisplayName(profile.name);
      } on FirebaseAuthException {
        // Lỗi mạng... -> bỏ qua, tên vẫn đã lưu trên máy và Firestore.
      }
    }
    return _profile!;
  }

  // ---------- Gọi API /me ----------

  /// Header gửi kèm: "vé" đăng nhập (ID token) của Firebase.
  /// Chưa đăng nhập -> null.
  Future<Map<String, String>?> _authHeaders() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) return null;
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// GET /me -> hồ sơ trên Firestore. Lỗi mạng / API lỗi -> null.
  Future<Map<String, dynamic>?> _fetchRemote() async {
    try {
      final headers = await _authHeaders();
      if (headers == null) return null;
      final res = await http
          .get(Uri.parse('$apiBaseUrl/me'), headers: headers)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return null;
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// PUT /me -> lưu hồ sơ lên Firestore. Trả về true nếu lưu được.
  Future<bool> _pushRemote(UserProfile profile) async {
    try {
      final headers = await _authHeaders();
      if (headers == null) return false;
      final body = profile.toMap()..remove('phone'); // SĐT không lưu ở đây
      final res = await http
          .put(Uri.parse('$apiBaseUrl/me'), headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Firestore trả về có dữ liệu hồ sơ không (ngoài trường id)?
  bool _hasProfileData(Map<String, dynamic> remote) =>
      remote.keys.any((k) => k != 'id');

  // ---------- Bản lưu trên máy ----------

  /// Đọc hồ sơ đã lưu trên máy. Không có hoặc lỗi -> null.
  Future<UserProfile?> _loadLocal(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final text = prefs.getString(_keyFor(uid));
      if (text == null) return null;
      final map = jsonDecode(text) as Map<String, dynamic>;
      return UserProfile.fromMap(uid, map);
    } catch (_) {
      return null; // dữ liệu hỏng -> coi như chưa có
    }
  }

  /// Ghi hồ sơ xuống máy, dạng chữ JSON.
  Future<void> _saveLocal(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFor(profile.id), jsonEncode(profile.toMap()));
  }

  // ---------- Mẫu đã lưu (chính là các mẫu bấm tim) ----------

  /// Đổi một kiểu tóc trong bộ sưu tập thành SavedStyle để hiện ở Hồ sơ.
  SavedStyle _toSaved(HairStyle s) =>
      SavedStyle(id: s.id, name: s.name, image: s.thumbUrl ?? '');

  /// Nếu có mẫu đã lưu mà chưa có trong danh sách kiểu tóc (ví dụ chưa mở tab Mẫu
  /// nên app vẫn đang dùng dữ liệu dự phòng) -> tải danh sách từ API.
  Future<void> ensureHairStylesLoaded() async {
    final known = hairStyles.map((s) => s.id).toSet();
    if (favoriteStyles.ids.any((id) => !known.contains(id))) {
      await loadHairStyles();
    }
  }

  /// Mẫu đã lưu, mới lưu nằm trước. Đọc ngay (không cần chờ).
  List<SavedStyle> savedStyles() {
    final byId = {for (final s in hairStyles) s.id: s};
    return [
      for (final id in favoriteStyles.ids.reversed)
        if (byId[id] != null) _toSaved(byId[id]!),
    ];
  }

  Future<List<SavedStyle>> getSavedStyles() async {
    await ensureHairStylesLoaded();
    return savedStyles();
  }

  /// Bỏ lưu (tab Mẫu cũng bỏ tim theo).
  Future<void> removeSavedStyle(String styleId) async {
    favoriteStyles.remove(styleId);
  }

  /// Lưu một mẫu (tab Mẫu cũng hiện tim theo).
  Future<void> addSavedStyle(SavedStyle style) async {
    favoriteStyles.add(style.id);
  }

  // ---------- Lịch hẹn (còn giả) ----------

  /// Lấy lịch hẹn của người dùng, mới nhất lên trước.
  Future<List<Appointment>> getAppointments() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final list = List.of(_appointments);
    list.sort((a, b) => b.startTime.compareTo(a.startTime));
    return list;
  }

  /// Hủy một lịch hẹn: đổi trạng thái thành "Đã hủy".
  Future<void> cancelAppointment(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final i = _appointments.indexWhere((a) => a.id == id);
    if (i >= 0) {
      _appointments[i] = _appointments[i].copyWith(status: AppointmentStatus.cancelled);
    }
  }

  // ---------- Đăng xuất ----------

  /// Đăng xuất Firebase và quên hồ sơ trong RAM.
  Future<void> logout() async {
    await AuthService.instance.logout();
    _profile = null;
  }

  // ---------- AI gợi ý (chọn từ bộ sưu tập thật, chưa phải AI thật) ----------

  /// Vibe -> các kiểu tóc hợp.
  static const Map<String, Set<HairType>> _vibeTypes = {
    'Cá tính': {HairType.pixie, HairType.wolfCut},
    'Dễ thương': {HairType.bob, HairType.curly},
    'Thanh lịch': {HairType.layer, HairType.hushCut, HairType.straight},
  };

  /// Chọn 3 kiểu tóc trong bộ sưu tập hợp với vibe. Sau này: thay bằng AI thật.
  Future<List<AiSuggestion>> getAiSuggestions({
    required String occasion,
    required String skinTone,
    required String undertone,
    required String vibe,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1200)); // giả vờ AI đang nghĩ

    final wanted = _vibeTypes[vibe] ?? const <HairType>{};
    var pool = hairStyles.where((s) => s.types.any(wanted.contains)).toList();
    if (pool.length < 3) pool = List.of(hairStyles); // ít quá thì lấy cả bộ sưu tập
    if (pool.isEmpty) return [];

    // Chọn vị trí bắt đầu khác nhau tùy lựa chọn, để mỗi lần chọn khác ra kết quả khác
    final start = (occasion.length + skinTone.length + undertone.length) % pool.length;
    final count = pool.length < 3 ? pool.length : 3;

    return [
      for (var i = 0; i < count; i++)
        AiSuggestion(
          style: _toSaved(pool[(start + i) % pool.length]),
          reason: 'Hợp vibe $vibe khi $occasion, tôn $skinTone ($undertone).',
        ),
    ];
  }
}