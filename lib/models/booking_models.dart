import 'package:cloud_firestore/cloud_firestore.dart';

/// A salon service that can be selected as the main booking service.
class BookingService {
  const BookingService({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationMinutes,
    required this.category,
    required this.isActive,
  });

  final String id;
  final String name;
  final String description;
  final int price;
  final int durationMinutes;
  final String category;
  final bool isActive;

  factory BookingService.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    if (!document.exists || data == null) {
      throw BookingDataException('Không tìm thấy dịch vụ chính trên Firestore.');
    }
    return BookingService(
      id: document.id,
      name: _requiredString(data, 'name', document.id),
      description: _optionalString(data, 'description'),
      price: _requiredInt(data, 'price', document.id, min: 0),
      durationMinutes: _requiredInt(
        data,
        'durationMinutes',
        document.id,
        min: 1,
      ),
      category: _requiredString(data, 'category', document.id),
      isActive: _requiredBool(data, 'isActive', document.id),
    );
  }
}

/// An optional service that can be added to a booking.
class BookingAdditionalService {
  const BookingAdditionalService({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationMinutes,
    required this.isActive,
  });

  final String id;
  final String name;
  final String description;
  final int price;
  final int durationMinutes;
  final bool isActive;

  factory BookingAdditionalService.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    if (!document.exists || data == null) {
      throw BookingDataException(
        'Không tìm thấy dịch vụ thêm ${document.id} trên Firestore.',
      );
    }
    return BookingAdditionalService(
      id: document.id,
      name: _requiredString(data, 'name', document.id),
      description: _optionalString(data, 'description'),
      price: _requiredInt(data, 'price', document.id, min: 0),
      durationMinutes: _requiredInt(
        data,
        'durationMinutes',
        document.id,
        min: 1,
      ),
      isActive: _requiredBool(data, 'isActive', document.id),
    );
  }
}

/// Salon configuration used to generate valid appointment start times.
class SalonSettings {
  const SalonSettings({
    required this.salonName,
    required this.openTime,
    required this.closeTime,
    required this.slotIntervalMinutes,
    required this.timezone,
    required this.isBookingEnabled,
  });

  final String salonName;
  final String openTime;
  final String closeTime;
  final int slotIntervalMinutes;
  final String timezone;
  final bool isBookingEnabled;

  factory SalonSettings.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    if (!document.exists || data == null) {
      throw const BookingDataException(
        'Không tìm thấy cấu hình salon trên Firestore.',
      );
    }

    final openTime = _requiredString(data, 'openTime', document.id);
    final closeTime = _requiredString(data, 'closeTime', document.id);
    final openMinutes = _parseTime(openTime, 'openTime');
    final closeMinutes = _parseTime(closeTime, 'closeTime');
    if (closeMinutes <= openMinutes) {
      throw const BookingDataException(
        'Giờ mở cửa và đóng cửa trong cấu hình salon không hợp lệ.',
      );
    }

    return SalonSettings(
      salonName: _requiredString(data, 'salonName', document.id),
      openTime: openTime,
      closeTime: closeTime,
      slotIntervalMinutes: _requiredInt(
        data,
        'slotIntervalMinutes',
        document.id,
        min: 1,
      ),
      timezone: _requiredString(data, 'timezone', document.id),
      isBookingEnabled: _requiredBool(data, 'isBookingEnabled', document.id),
    );
  }

  /// Returns starts on the salon's slot interval that finish before closing.
  /// This does not check existing bookings or availability.
  List<String> startTimesForDuration(int durationMinutes) {
    if (durationMinutes < 1) return const [];
    final openMinutes = _parseTime(openTime, 'openTime');
    final closeMinutes = _parseTime(closeTime, 'closeTime');
    final lastStart = closeMinutes - durationMinutes;
    final result = <String>[];
    for (
      var minute = openMinutes;
      minute <= lastStart;
      minute += slotIntervalMinutes
    ) {
      final hour = minute ~/ 60;
      final minutes = minute % 60;
      result.add(
        '${hour.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}',
      );
    }
    return result;
  }
}

class BookingCatalog {
  BookingCatalog({
    required this.mainService,
    required List<BookingAdditionalService> additionalServices,
    required this.salonSettings,
  }) : additionalServices = List.unmodifiable(additionalServices);

  final BookingService mainService;
  final List<BookingAdditionalService> additionalServices;
  final SalonSettings salonSettings;
}

class BookingDataException implements Exception {
  const BookingDataException(this.message);

  final String message;

  @override
  String toString() => message;
}

String _requiredString(Map<String, dynamic> data, String field, String document) {
  final value = data[field];
  if (value is! String || value.trim().isEmpty) {
    throw BookingDataException('Trường $field của $document không hợp lệ.');
  }
  return value.trim();
}

String _optionalString(Map<String, dynamic> data, String field) {
  final value = data[field];
  if (value == null) return '';
  if (value is! String) {
    throw BookingDataException('Trường $field trên Firestore không hợp lệ.');
  }
  return value.trim();
}

int _requiredInt(
  Map<String, dynamic> data,
  String field,
  String document, {
  required int min,
}) {
  final value = data[field];
  if (value is! int || value < min) {
    throw BookingDataException('Trường $field của $document không hợp lệ.');
  }
  return value;
}

bool _requiredBool(Map<String, dynamic> data, String field, String document) {
  final value = data[field];
  if (value is! bool) {
    throw BookingDataException('Trường $field của $document không hợp lệ.');
  }
  return value;
}

int _parseTime(String value, String field) {
  final match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(value);
  if (match == null) {
    throw BookingDataException('Trường $field phải có định dạng HH:mm.');
  }
  final hour = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2)!);
  if (hour > 23 || minute > 59) {
    throw BookingDataException('Trường $field có giờ không hợp lệ.');
  }
  return hour * 60 + minute;
}
