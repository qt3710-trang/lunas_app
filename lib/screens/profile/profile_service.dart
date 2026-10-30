import 'package:firebase_auth/firebase_auth.dart';

import '../../services/auth_service.dart';
import 'profile_models.dart';

/// Nơi DUY NHẤT trang Hồ sơ lấy và lưu dữ liệu.
///
/// ĐÃ THẬT (Firebase Auth): id, tên, số điện thoại, đăng xuất.
/// CÒN GIẢ (chờ API Node.js + Firestore): dáng mặt, tông da, phong cách,
/// mẫu đã lưu, lịch hẹn, AI gợi ý. Mọi tài khoản tạm thấy chung dữ liệu giả này.
class ProfileService {
  ProfileService._();
  static final instance = ProfileService._();

  static const _img = 'assets/images/hairstyles';

  // ---------- Dữ liệu giả ----------

  /// Sở thích mẫu, tạm gán cho mọi tài khoản cho tới khi có Firestore.
  static const _demoProfile = UserProfile(
    id: 'demo_user',
    name: 'Linh',
    phone: '0901234567',
    favoriteHair: 'Tóc layer bồng bềnh',
    styleTags: ['Ngọt ngào', 'Cổ điển'],
    faceShape: 'Mặt trái xoan',
    skinTone: 'Da sáng',
    weeklyNotify: true,
  );

  /// Hồ sơ đang hiển thị (đã gộp thông tin thật từ Firebase).
  UserProfile _profile = _demoProfile;

  final List<SavedStyle> _saved = [
    const SavedStyle(id: 'layer_bong_benh', name: 'Layer bồng bềnh', image: '$_img/layer_bong_benh.jpg'),
    const SavedStyle(id: 'uon_song_tra_sua', name: 'Nâu trà sữa uốn sóng', image: '$_img/uon_song_tra_sua.jpg'),
    const SavedStyle(id: 'bob_han_quoc', name: 'Bob Hàn Quốc', image: '$_img/bob_han_quoc.jpg'),
  ];

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

  // ---------- Hồ sơ ----------

  /// Lấy hồ sơ của người ĐANG ĐĂNG NHẬP.
  /// id, tên, SĐT lấy thật từ Firebase; các sở thích còn lại tạm lấy từ dữ liệu giả.
  Future<UserProfile> getProfile() async {
    final user = AuthService.instance.currentUser;

    // Chưa đăng nhập (không nên xảy ra) -> dùng dữ liệu giả để màn hình không lỗi.
    if (user == null) return _profile;

    // Người đăng nhập khác với hồ sơ đang giữ -> tạo hồ sơ mới cho người này.
    if (_profile.id != user.id) {
      _profile = UserProfile(
        id: user.id,
        name: user.name.isEmpty ? 'Bạn' : user.name,
        phone: user.phone,
        favoriteHair: _demoProfile.favoriteHair,
        styleTags: _demoProfile.styleTags,
        faceShape: _demoProfile.faceShape,
        skinTone: _demoProfile.skinTone,
        weeklyNotify: _demoProfile.weeklyNotify,
      );
    }
    return _profile;
  }

  /// Lưu hồ sơ sau khi sửa.
  /// Nếu đổi tên -> lưu tên lên Firebase Auth (mở lại app vẫn còn).
  /// Các sở thích khác: tạm lưu trong máy, tắt app sẽ mất (chờ Firestore).
  Future<UserProfile> updateProfile(UserProfile profile) async {
    final nameChanged = profile.name != _profile.name;
    _profile = profile;

    if (nameChanged) {
      try {
        await FirebaseAuth.instance.currentUser?.updateDisplayName(profile.name);
      } on FirebaseAuthException {
        // Lỗi mạng... -> bỏ qua, tên vẫn đổi trên màn hình lần này.
      }
    }
    return _profile;
  }

  // ---------- Mẫu đã lưu (còn giả) ----------

  Future<List<SavedStyle>> getSavedStyles() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.of(_saved);
  }

  Future<void> removeSavedStyle(String styleId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _saved.removeWhere((s) => s.id == styleId);
  }

  // ---------- Lịch hẹn (còn giả) ----------

  /// Lấy lịch hẹn của người dùng, mới nhất lên trước.
  /// Sau này: đọc 'bookings' có userId == uid (qua API của nhóm).
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

  // ---------- Đăng xuất (ĐÃ THẬT) ----------

  /// Đăng xuất Firebase, và quên hồ sơ cũ để người sau không thấy.
  Future<void> logout() async {
    await AuthService.instance.logout();
    _profile = _demoProfile;
  }

  // ---------- Lưu thêm mẫu (còn giả) ----------

  /// Lưu một mẫu vào "Mẫu đã lưu" (nếu chưa có).
  Future<void> addSavedStyle(SavedStyle style) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final exists = _saved.any((s) => s.id == style.id);
    if (!exists) _saved.insert(0, style);   // thêm lên đầu danh sách
  }

  // ---------- AI gợi ý (còn giả) ----------

  /// Kho kiểu tóc để "AI" chọn ra.
  static const _catalog = [
    SavedStyle(id: 'butterfly_layer', name: 'Butterfly Layer', image: '$_img/butterfly_layer.jpg'),
    SavedStyle(id: 'hush_cut', name: 'Hush Cut', image: '$_img/hush_cut.jpg'),
    SavedStyle(id: 'long_layer', name: 'Long Layer', image: '$_img/long_layer.jpg'),
    SavedStyle(id: 'soft_wolf_cut', name: 'Soft Wolf Cut', image: '$_img/soft_wolf_cut.jpg'),
    SavedStyle(id: 'pixie_cut', name: 'Pixie Cut', image: '$_img/pixie_cut.jpg'),
    SavedStyle(id: 'bob_han_quoc', name: 'Bob Hàn Quốc', image: '$_img/bob_han_quoc.jpg'),
  ];

  /// Bây giờ: chọn GIẢ 3 kiểu theo lựa chọn của khách.
  /// Sau này: gọi AI thật.
  Future<List<AiSuggestion>> getAiSuggestions({
    required String occasion,
    required String skinTone,
    required String undertone,
    required String vibe,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1200)); // giả vờ AI đang nghĩ

    // Chọn vị trí bắt đầu khác nhau tùy lựa chọn, để mỗi lần chọn khác ra kết quả khác
    final start = (occasion.length + vibe.length + skinTone.length) % _catalog.length;

    return [
      for (var i = 0; i < 3; i++)
        AiSuggestion(
          style: _catalog[(start + i) % _catalog.length],
          reason: 'Hợp vibe $vibe khi $occasion, tôn $skinTone ($undertone).',
        ),
    ];
  }
}