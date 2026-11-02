import 'package:cloud_firestore/cloud_firestore.dart';

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

  final String id;
  final String name;
  final String phone;
  final String favoriteHair;
  final List<String> styleTags;
  final String faceShape;
  final String skinTone;
  final bool weeklyNotify;

  String get initial => name.isEmpty ? '?' : name[0].toUpperCase();

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

/// Một mẫu tóc người dùng đã bấm tim để lưu.
class SavedStyle {
  const SavedStyle({
    required this.id,
    required this.name,
    required this.image,
  });

  final String id;
  final String name;
  final String image;

  factory SavedStyle.fromMap(String id, Map<String, dynamic> map) {
    return SavedStyle(
      id: id,
      name: map['name'] ?? '',
      image: map['image'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {'name': name, 'image': image};
}

// =================== MỚI Ở BÀI 6 ===================

/// Trạng thái của một lịch hẹn.
enum AppointmentStatus {
  pending('Chờ xác nhận'),
  confirmed('Đã xác nhận'),
  completed('Đã hoàn thành'),
  cancelled('Đã hủy');

  const AppointmentStatus(this.label);
  final String label; // chữ hiển thị tiếng Việt

  /// Đổi chữ trong database ('completed'...) thành trạng thái.
  static AppointmentStatus fromName(String? name) {
    return AppointmentStatus.values.firstWhere(
      (s) => s.name == name,
      orElse: () => AppointmentStatus.pending,
    );
  }
}

/// Một lịch hẹn làm tóc.
class Appointment {
  const Appointment({
    required this.id,
    required this.code,
    required this.serviceName,
    required this.salonName,
    required this.salonAddress,
    required this.startTime,
    required this.image,
    required this.totalPrice,
    required this.status,
    this.stylistName,
  });

  final String id;
  final String code;           // ví dụ "#LUNAS1031"
  final String serviceName;    // ví dụ "Cắt + Nhuộm"
  final String salonName;
  final String salonAddress;
  final DateTime startTime;    // ngày giờ hẹn
  final String image;
  final int totalPrice;        // tiền, đơn vị đồng
  final AppointmentStatus status;
  final String? stylistName;   // có thể không có

  /// Lịch sắp tới = chưa tới giờ VÀ chưa hủy, chưa xong.
  bool get isUpcoming {
    final notYet = startTime.isAfter(DateTime.now());
    final active = status == AppointmentStatus.pending ||
        status == AppointmentStatus.confirmed;
    return notYet && active;
  }

  Appointment copyWith({AppointmentStatus? status}) {
    return Appointment(
      id: id,
      code: code,
      serviceName: serviceName,
      salonName: salonName,
      salonAddress: salonAddress,
      startTime: startTime,
      image: image,
      totalPrice: totalPrice,
      stylistName: stylistName,
      status: status ?? this.status,
    );
  }

  /// Đọc từ collection 'bookings' (do phần Đặt lịch ghi vào).
  /// startTime trên Firestore là Timestamp nên đọc bằng _readDateTime.
  factory Appointment.fromMap(String id, Map<String, dynamic> map) {
    return Appointment(
      id: id,
      code: map['code'] ?? '',
      serviceName: map['serviceName'] ?? '',
      salonName: map['salonName'] ?? '',
      salonAddress: map['salonAddress'] ?? '',
      startTime: _readDateTime(map['startTime']),
      image: map['image'] ?? '',
      totalPrice: (map['totalPrice'] as num?)?.toInt() ?? 0,
      status: AppointmentStatus.fromName(map['status'] as String?),
      stylistName: map['stylistName'] as String?,
    );
  }
}

/// Đổi giá trị thời gian đọc từ database thành DateTime.
/// - Timestamp của Firestore -> .toDate()
/// - Số mili giây (cách lưu cũ) -> DateTime.fromMillisecondsSinceEpoch
/// - Không đọc được -> mốc 0 (không làm app bị sập).
DateTime _readDateTime(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return DateTime.fromMillisecondsSinceEpoch(0);
}

// ---------- Hàm định dạng ----------

const _weekdays = ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'CN'];

/// Thêm số 0 phía trước: 5 -> "05"
String _two(int n) => n.toString().padLeft(2, '0');

/// DateTime -> "10:00 - Thứ 7, 26/04/2025"
String formatAppointmentTime(DateTime d) {
  return '${_two(d.hour)}:${_two(d.minute)} - '
      '${_weekdays[d.weekday - 1]}, ${_two(d.day)}/${_two(d.month)}/${d.year}';
}

/// 750000 -> "750.000đ"
String formatVnd(int amount) {
  final digits = amount.toString();
  final result = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) result.write('.');
    result.write(digits[i]);
  }
  return '${result.toString()}đ';
}

/// Một kết quả AI gợi ý: kiểu tóc + lý do.
class AiSuggestion {
  const AiSuggestion({required this.style, required this.reason});

  final SavedStyle style;   // dùng lại khuôn SavedStyle để lưu được luôn
  final String reason;      // ví dụ "Hợp vibe Thanh lịch khi đi làm..."
}