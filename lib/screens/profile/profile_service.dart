import 'profile_models.dart';

/// Nơi DUY NHẤT trang Hồ sơ lấy và lưu dữ liệu.
/// Bây giờ: dữ liệu giả. Bài 8: đổi sang Firebase.
class ProfileService {
  ProfileService._();
  static final instance = ProfileService._();

  static const _img = 'assets/images/hairstyles';

  // ---------- Dữ liệu giả ----------
  UserProfile _profile = const UserProfile(
    id: 'demo_user',
    name: 'Linh',
    phone: '0901234567',
    favoriteHair: 'Tóc layer bồng bềnh',
    styleTags: ['Ngọt ngào', 'Cổ điển'],
    faceShape: 'Mặt trái xoan',
    skinTone: 'Da sáng',
    weeklyNotify: true,
  );

  final List<SavedStyle> _saved = [
    const SavedStyle(id: 'layer_bong_benh', name: 'Layer bồng bềnh', image: '$_img/layer_bong_benh.jpg'),
    const SavedStyle(id: 'uon_song_tra_sua', name: 'Nâu trà sữa uốn sóng', image: '$_img/uon_song_tra_sua.jpg'),
    const SavedStyle(id: 'bob_han_quoc', name: 'Bob Hàn Quốc', image: '$_img/bob_han_quoc.jpg'),
  ];

  /// MỚI: lịch hẹn giả, tính ngày theo hôm nay để lúc nào cũng có lịch "sắp tới".
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

  Future<UserProfile> getProfile() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _profile;
  }

  Future<UserProfile> updateProfile(UserProfile profile) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _profile = profile;
    return _profile;
  }

  // ---------- Mẫu đã lưu ----------

  Future<List<SavedStyle>> getSavedStyles() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.of(_saved);
  }

  Future<void> removeSavedStyle(String styleId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _saved.removeWhere((s) => s.id == styleId);
  }

  // ---------- Lịch hẹn (MỚI) ----------

  /// Lấy lịch hẹn của người dùng, mới nhất lên trước.
  /// Bài 8: đọc collection 'bookings' where userId == uid.
  Future<List<Appointment>> getAppointments() async {
    await Future.delayed(const Duration(milliseconds: 500));
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

  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  // ---------- Lưu thêm mẫu (MỚI) ----------

  /// Lưu một mẫu vào "Mẫu đã lưu" (nếu chưa có).
  Future<void> addSavedStyle(SavedStyle style) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final exists = _saved.any((s) => s.id == style.id);
    if (!exists) _saved.insert(0, style);   // thêm lên đầu danh sách
  }

  // ---------- AI gợi ý (MỚI) ----------

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
  /// Bài 8: gọi Gemini thật qua package firebase_ai.
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