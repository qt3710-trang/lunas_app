/// Khuôn dữ liệu của một hồ sơ người dùng.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.phone,
    this.favoriteHair = '',
    this.styleTags = const [],
    this.faceShape = '',
    this.skinTone = '',
    this.weeklyNotify = true,
  });

  final String id;               // mã người dùng (sau này là uid Firebase)
  final String name;             // tên hiển thị, ví dụ "Linh"
  final String phone;            // số điện thoại
  final String favoriteHair;     // ví dụ "Tóc layer bồng bềnh"
  final List<String> styleTags;  // ví dụ ["Ngọt ngào", "Cổ điển"]
  final String faceShape;        // MỚI: ví dụ "Mặt trái xoan"
  final String skinTone;         // MỚI: ví dụ "Da sáng"
  final bool weeklyNotify;       // MỚI: công tắc "Báo mẫu mới mỗi tuần"

  String get initial => name.isEmpty ? '?' : name[0].toUpperCase();

  /// MỚI: tạo bản sao, chỉ đổi vài ô.
  /// Ví dụ: profile.copyWith(weeklyNotify: false)
  UserProfile copyWith({
    String? name,
    String? favoriteHair,
    List<String>? styleTags,
    String? faceShape,
    String? skinTone,
    bool? weeklyNotify,
  }) {
    return UserProfile(
      id: id,
      phone: phone,
      name: name ?? this.name,
      favoriteHair: favoriteHair ?? this.favoriteHair,
      styleTags: styleTags ?? this.styleTags,
      faceShape: faceShape ?? this.faceShape,
      skinTone: skinTone ?? this.skinTone,
      weeklyNotify: weeklyNotify ?? this.weeklyNotify,
    );
  }

  factory UserProfile.fromMap(String id, Map<String, dynamic> map) {
    return UserProfile(
      id: id,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      favoriteHair: map['favoriteHair'] ?? '',
      styleTags: List<String>.from(map['styleTags'] ?? []),
      faceShape: map['faceShape'] ?? '',
      skinTone: map['skinTone'] ?? '',
      weeklyNotify: map['weeklyNotify'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'favoriteHair': favoriteHair,
      'styleTags': styleTags,
      'faceShape': faceShape,
      'skinTone': skinTone,
      'weeklyNotify': weeklyNotify,
    };
  }
}

/// MỚI: một mẫu tóc người dùng đã bấm tim để lưu.
class SavedStyle {
  const SavedStyle({
    required this.id,
    required this.name,
    required this.image,
  });

  final String id;     // ví dụ "bob_han_quoc"
  final String name;   // ví dụ "Bob Hàn Quốc"
  final String image;  // đường dẫn ảnh trong assets

  factory SavedStyle.fromMap(String id, Map<String, dynamic> map) {
    return SavedStyle(
      id: id,
      name: map['name'] ?? '',
      image: map['image'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {'name': name, 'image': image};
}