import 'profile_models.dart';

/// Nơi DUY NHẤT trang Hồ sơ lấy và lưu dữ liệu.
/// Bây giờ: dữ liệu giả. Bài 8: đổi sang Firebase.
class ProfileService {
  // Cả app dùng chung MỘT ProfileService
  ProfileService._();
  static final instance = ProfileService._();

  // Dữ liệu giả
  UserProfile _profile = const UserProfile(
    id: 'demo_user',
    name: 'Linh',
    phone: '0901234567',
    favoriteHair: 'Tóc layer bồng bềnh',
    styleTags: ['Ngọt ngào', 'Cổ điển'],
  );

  /// Lấy hồ sơ của người đang đăng nhập.
  Future<UserProfile> getProfile() async {
    await Future.delayed(const Duration(milliseconds: 500)); // giả vờ chờ mạng
    return _profile;
  }

  /// Lưu hồ sơ sau khi người dùng sửa.
  Future<UserProfile> updateProfile(UserProfile profile) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _profile = profile;
    return _profile;
  }
}