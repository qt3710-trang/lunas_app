import 'profile_models.dart';

/// Nơi DUY NHẤT trang Hồ sơ lấy và lưu dữ liệu.
/// Bây giờ: dữ liệu giả. Bài 8: đổi sang Firebase.
class ProfileService {
  ProfileService._();
  static final instance = ProfileService._();

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
    const SavedStyle(
      id: 'layer_bong_benh',
      name: 'Layer bồng bềnh',
      image: 'assets/images/hairstyles/layer_bong_benh.jpg',
    ),
    const SavedStyle(
      id: 'uon_song_tra_sua',
      name: 'Nâu trà sữa uốn sóng',
      image: 'assets/images/hairstyles/uon_song_tra_sua.jpg',
    ),
    const SavedStyle(
      id: 'bob_han_quoc',
      name: 'Bob Hàn Quốc',
      image: 'assets/images/hairstyles/bob_han_quoc.jpg',
    ),
  ];

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

  // ---------- Mẫu đã lưu (MỚI) ----------

  /// Lấy danh sách mẫu đã lưu.
  Future<List<SavedStyle>> getSavedStyles() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.of(_saved); // trả về bản sao để màn hình không sửa nhầm
  }

  /// Bỏ lưu một mẫu.
  Future<void> removeSavedStyle(String styleId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _saved.removeWhere((s) => s.id == styleId);
  }

  // ---------- Đăng xuất (MỚI) ----------

  /// Bài 8: đổi thành FirebaseAuth.instance.signOut()
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
  }
}