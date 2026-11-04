import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/booking_models.dart';

/// Reads the explicit service documents used by the Booking screen.
class BookingRepository {
  BookingRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const _serviceIds = ['cat-toc-layer-nu', 'uon-tao-kieu'];
  static const _additionalServiceIds = [
    'goi-say-tao-kieu',
    'hap-phuc-hoi-toc',
    'duong-toc-mem-muot',
  ];
  static const _salonSettingsId = 'main';

  final FirebaseFirestore _firestore;

  Future<BookingCatalog> loadCatalog() async {
    final settingsReference = _firestore
        .collection('salon_settings')
        .doc(_salonSettingsId);
    developer.log(
      'Booking salon settings read: '
      'loggedIn=${FirebaseAuth.instance.currentUser != null}, '
      'projectId=${_firestore.app.options.projectId}, '
      'databaseId=${_firestore.databaseId}, '
      'path=${settingsReference.path}',
      name: 'lunas.booking.firestore',
    );
    final settingsDocument = await _getDocument(settingsReference);
    if (!settingsDocument.exists) {
      throw const BookingDataException(
        'Không tìm thấy cấu hình salon trên Firestore.',
      );
    }

    final serviceDocuments = await Future.wait([
      for (final id in _serviceIds)
        _getDocument(_firestore.collection('services').doc(id)),
    ]);
    final additionalServiceDocuments = await Future.wait([
      for (final id in _additionalServiceIds)
        _getDocument(_firestore.collection('additional_services').doc(id)),
    ]);

    final services = [
      for (final document in serviceDocuments)
        if (document.exists) BookingService.fromDocument(document),
    ];
    final additionalServices = [
      for (final document in additionalServiceDocuments)
        if (document.exists) BookingAdditionalService.fromDocument(document),
    ];

    return BookingCatalog(
      services: services,
      additionalServices: additionalServices,
      salonSettings: SalonSettings.fromDocument(settingsDocument),
    );
  }

  /// Validates selected Firestore services, checks personal time overlap, then
  /// writes one booking document and returns its ID.
  Future<String> createBooking({
    required BookingMode mode,
    required BookingService? hairstyleService,
    required List<BookingLineItem> selectedServices,
    required String? hairStyleId,
    required String? hairStyleName,
    required String? hairStyleColor,
    required String? hairStyleImageUrl,
    required SalonSettings salonSettings,
    required DateTime date,
    required String time,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw const BookingDataException('Bạn cần đăng nhập để đặt lịch.');
    }
    if (!salonSettings.isBookingEnabled) {
      throw const BookingDataException(
        'Salon hiện đang tạm ngưng nhận đặt lịch.',
      );
    }
    if (mode == BookingMode.hairstyle &&
        (hairstyleService == null ||
            hairStyleId == null ||
            hairStyleId.trim().isEmpty)) {
      throw const BookingDataException(
        'Mẫu tóc chưa được liên kết với dịch vụ salon hợp lệ.',
      );
    }
    if (selectedServices.isEmpty) {
      throw const BookingDataException('Hãy chọn ít nhất một dịch vụ.');
    }
    if (mode == BookingMode.hairstyle &&
        !selectedServices.any(
          (service) =>
              service.collectionName == hairstyleService!.collectionName &&
              service.id == hairstyleService.id,
        )) {
      throw const BookingDataException(
        'Dịch vụ liên kết với mẫu tóc chưa được chọn để đặt lịch.',
      );
    }

    final uniqueKeys = selectedServices
        .map((service) => '${service.collectionName}/${service.id}')
        .toSet();
    if (uniqueKeys.length != selectedServices.length) {
      throw const BookingDataException('Danh sách dịch vụ bị trùng.');
    }

    final refreshedServices = await Future.wait(
      selectedServices.map(_readActiveService),
    );
    final parts = time.split(':');
    final hour = parts.length == 2 ? int.tryParse(parts[0]) : null;
    final minute = parts.length == 2 ? int.tryParse(parts[1]) : null;
    if (hour == null || minute == null || hour > 23 || minute > 59) {
      throw const BookingDataException('Giờ hẹn không hợp lệ.');
    }

    final startTime = DateTime(date.year, date.month, date.day, hour, minute);
    if (!startTime.isAfter(DateTime.now())) {
      throw const BookingDataException(
        'Giờ hẹn đã qua. Vui lòng chọn giờ khác.',
      );
    }
    final totalPrice = refreshedServices.fold<int>(
      0,
      (total, service) => total + service.price,
    );
    final totalDuration = refreshedServices.fold<int>(
      0,
      (total, service) => total + service.durationMinutes,
    );
    if (totalPrice < 0 ||
        totalDuration < 1 ||
        !salonSettings.startTimesForDuration(totalDuration).contains(time)) {
      throw const BookingDataException(
        'Tổng giá hoặc thời lượng dịch vụ không hợp lệ với giờ hoạt động.',
      );
    }

    await _ensureNoPersonalOverlap(
      userId: user.uid,
      startTime: startTime,
      durationMinutes: totalDuration,
    );

    final primaryService = hairstyleService ?? refreshedServices.first;
    final remainingServices = mode == BookingMode.hairstyle
        ? refreshedServices
              .where(
                (service) =>
                    service.collectionName != primaryService.collectionName ||
                    service.id != primaryService.id,
              )
              .toList(growable: false)
        : refreshedServices.skip(1).toList(growable: false);
    final reference = _firestore.collection('bookings').doc();
    final bookingCode =
        '#LUNAS${(DateTime.now().millisecondsSinceEpoch % 1000000).toString().padLeft(6, '0')}';
    final data = <String, dynamic>{
      'userId': user.uid,
      'code': bookingCode,
      'bookingType': mode.firestoreValue,
      'serviceName': refreshedServices
          .map((service) => service.name)
          .join(' · '),
      'serviceId': primaryService.id,
      'additionalServices': [
        for (final service in remainingServices)
          {'id': service.id, 'name': service.name, 'price': service.price},
      ],
      'salonName': salonSettings.salonName,
      'salonAddress': '',
      'startTime': Timestamp.fromDate(startTime),
      'totalDurationMinutes': totalDuration,
      'totalPrice': totalPrice,
      'status': 'pending',
      'stylistName': null,
      'image': mode == BookingMode.hairstyle ? hairStyleImageUrl ?? '' : '',
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (mode == BookingMode.hairstyle) {
      data.addAll({
        'hairStyleId': hairStyleId,
        'hairStyleName': hairStyleName,
        'hairStyleColor': hairStyleColor,
        'hairStyleImageUrl': hairStyleImageUrl,
      });
    }

    developer.log(
      'Booking create started: path=${reference.path}',
      name: 'lunas.booking.firestore',
    );
    try {
      await reference.set(data);
    } on FirebaseException catch (error) {
      developer.log(
        'Booking create failed: code=${error.code}',
        name: 'lunas.booking.firestore',
      );
      if (error.code == 'permission-denied') {
        throw const BookingDataException(
          'Firestore từ chối quyền lưu lịch hẹn. Hãy kiểm tra security rules.',
        );
      }
      throw const BookingDataException(
        'Không thể lưu lịch hẹn. Hãy kiểm tra kết nối rồi thử lại.',
      );
    }
    developer.log(
      'Booking create completed: path=${reference.path}',
      name: 'lunas.booking.firestore',
    );
    return reference.id;
  }

  Future<BookingLineItem> _readActiveService(BookingLineItem requested) async {
    final document = await _getDocument(
      _firestore.collection(requested.collectionName).doc(requested.id),
    );
    final BookingLineItem service = requested.collectionName == 'services'
        ? BookingService.fromDocument(document)
        : BookingAdditionalService.fromDocument(document);
    if (!service.isActive) {
      throw BookingDataException(
        'Dịch vụ ${service.name} hiện không hoạt động.',
      );
    }
    return service;
  }

  Future<void> _ensureNoPersonalOverlap({
    required String userId,
    required DateTime startTime,
    required int durationMinutes,
  }) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot;
    try {
      snapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .get();
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        throw const BookingDataException(
          'Không thể kiểm tra lịch cá nhân do Firestore chưa cho phép đọc booking của bạn.',
        );
      }
      rethrow;
    }

    final endTime = startTime.add(Duration(minutes: durationMinutes));
    for (final document in snapshot.docs) {
      final data = document.data();
      if (data['status'] == 'cancelled') continue;
      final existingStart = _parseStoredDateTime(data['startTime']);
      if (existingStart == null || !_sameDate(existingStart, startTime)) {
        continue;
      }
      final existingEnd = _parseStoredDateTime(data['endTime']);
      final storedDuration = data['totalDurationMinutes'];
      final int? existingDuration = storedDuration is int && storedDuration > 0
          ? storedDuration
          : null;
      if (existingEnd == null && existingDuration == null) {
        throw const BookingDataException(
          'Không thể xác minh thời lượng của một lịch hiện có trong ngày này. Hãy liên hệ salon trước khi đặt tiếp.',
        );
      }
      final resolvedEnd =
          existingEnd ??
          existingStart.add(Duration(minutes: existingDuration!));
      if (startTime.isBefore(resolvedEnd) && existingStart.isBefore(endTime)) {
        throw const BookingDataException(
          'Lịch này bị trùng thời gian với một booking đang hoạt động của bạn.',
        );
      }
    }
  }

  DateTime? _parseStoredDateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  bool _sameDate(DateTime left, DateTime right) =>
      left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;

  Future<DocumentSnapshot<Map<String, dynamic>>> _getDocument(
    DocumentReference<Map<String, dynamic>> reference,
  ) async {
    try {
      final snapshot = await reference.get(
        const GetOptions(source: Source.server),
      );
      developer.log(
        'Booking Firestore snapshot: path=${reference.path}, '
        'exists=${snapshot.exists}, '
        'isFromCache=${snapshot.metadata.isFromCache}',
        name: 'lunas.booking.firestore',
      );
      return snapshot;
    } on FirebaseException catch (error) {
      developer.log(
        'Booking Firestore error: path=${reference.path}, code=${error.code}',
        name: 'lunas.booking.firestore',
      );
      rethrow;
    }
  }
}
