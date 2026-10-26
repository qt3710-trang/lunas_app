/// Khuôn dữ liệu của một hồ sơ người dùng.
class UserProfile {
  // 1. Hàm tạo (constructor): cách tạo ra một hồ sơ
  const UserProfile({
    required this.id,
    required this.name,
    required this.phone,
    this.favoriteHair = '',
    this.styleTags = const [],
  });

  // 2. Các thông tin của hồ sơ
  final String id;               // mã người dùng (sau này là uid Firebase)
  final String name;             // tên hiển thị, ví dụ "Linh"
  final String phone;            // số điện thoại
  final String favoriteHair;     // ví dụ "Tóc layer bồng bềnh"
  final List<String> styleTags;  // ví dụ ["Ngọt ngào", "Cổ điển"]

  // 3. Chữ cái đầu của tên, dùng cho ảnh đại diện tròn
  String get initial => name.isEmpty ? '?' : name[0].toUpperCase();

  // 4. Đọc từ database (dùng ở bài 8)
  factory UserProfile.fromMap(String id, Map<String, dynamic> map) {
    return UserProfile(
      id: id,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      favoriteHair: map['favoriteHair'] ?? '',
      styleTags: List<String>.from(map['styleTags'] ?? []),
    );
  }

  // 5. Ghi xuống database (dùng ở bài 8)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'favoriteHair': favoriteHair,
      'styleTags': styleTags,
    };
  }
}