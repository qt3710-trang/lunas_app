import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/booking_models.dart';

/// Đọc catalog cho màn hình Đặt lịch và ghi lịch hẹn vào collection 'bookings'.
class BookingRepository {
  BookingRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const _mainServiceId = 'cat-toc-layer-nu';
  static const _salonSettingsId = 'main';
  static const _additionalServiceIds = [
    'goi-say-tao-kieu',
    'hap-phuc-hoi-toc',
  ];

  final FirebaseFirestore _firestore;

  Future<BookingCatalog> loadCatalog() async {
    final salonSettingsReference = _firestore
        .collection('salon_settings')
        .doc(_salonSettingsId);
    developer.log(
      'Booking salon settings read: '
      'loggedIn=${FirebaseAuth.instance.currentUser != null}, '
      'projectId=${_firestore.app.options.projectId}, '
      'databaseId=${_firestore.databaseId}, '
      'path=${salonSettingsReference.path}',
      name: 'lunas.booking.firestore',
    );
    final settingsDocument = await _getDocument(salonSettingsReference);

    final serviceDocuments = await Future.wait<
      DocumentSnapshot<Map<String, dynamic>>
    >(
      [
        _getDocument(_firestore.collection('services').doc(_mainServiceId)),
        for (final id in _additionalServiceIds)
          _getDocument(_firestore.collection('additional_services').doc(id)),
      ],
    );

    final mainService = BookingService.fromDocument(serviceDocuments.first);
    if (!mainService.isActive) {
      throw const BookingDataException(
        'Dịch vụ Cắt tóc Layer nữ hiện không hoạt động.',
      );
    }

    final additionalServices = serviceDocuments
        .skip(1)
        .take(_additionalServiceIds.length)
        .map(BookingAdditionalService.fromDocument)
        .where((service) => service.isActive)
        .toList(growable: false);

    return BookingCatalog(
      mainService: mainService,
      additionalServices: additionalServices,
      salonSettings: SalonSettings.fromDocument(settingsDocument),
    );
  }

  /// Lưu một lịch hẹn mới vào collection 'bookings' và trả về mã lịch (#LUNAS...).
  ///
  /// - userId luôn là uid của người đang đăng nhập (Security Rules sẽ kiểm tra lại).
  /// - Tổng tiền và tổng thời lượng được tính lại tại đây từ dịch vụ.
  /// - Địa chỉ salon lấy từ [salonSettings] (salon_settings/main).
  /// - [image] là link ảnh của mẫu tóc đã chọn (có thể để trống).
  Future<String> createBooking({
    required BookingService mainService,
    required List<BookingAdditionalService> additionalServices,
    required SalonSettings salonSettings,
    required DateTime date,
    required String time, // dạng "HH:mm"
    String image = '',
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

    // Ghép ngày + giờ thành một mốc thời gian.
    final parts = time.split(':');
    final hour = parts.length == 2 ? int.tryParse(parts[0]) : null;
    final minute = parts.length == 2 ? int.tryParse(parts[1]) : null;
    if (hour == null || minute == null) {
      throw const BookingDataException('Giờ hẹn không hợp lệ.');
    }
    final startTime = DateTime(date.year, date.month, date.day, hour, minute);
    if (!startTime.isAfter(DateTime.now())) {
      throw const BookingDataException(
        'Giờ hẹn đã qua. Vui lòng chọn giờ khác.',
      );
    }

    final totalPrice = mainService.price +
        additionalServices.fold<int>(0, (total, s) => total + s.price);
    final totalDuration = mainService.durationMinutes +
        additionalServices.fold<int>(
          0,
          (total, s) => total + s.durationMinutes,
        );

    // Mã lịch: #LUNAS + 6 chữ số cuối của đồng hồ (mili giây).
    final code =
        '#LUNAS${(DateTime.now().millisecondsSinceEpoch % 1000000).toString().padLeft(6, '0')}';

    final reference = _firestore.collection('bookings').doc();
    final data = <String, dynamic>{
      'userId': user.uid,
      'code': code,
      'serviceName': mainService.name,
      'serviceId': mainService.id,
      'additionalServices': [
        for (final s in additionalServices)
          {'id': s.id, 'name': s.name, 'price': s.price},
      ],
      'salonName': salonSettings.salonName,
      'salonAddress': salonSettings.address,
      'startTime': Timestamp.fromDate(startTime),
      'totalDurationMinutes': totalDuration,
      'totalPrice': totalPrice,
      'status': 'pending',
      'stylistName': null,
      'image': image,
      'createdAt': FieldValue.serverTimestamp(),
    };

    developer.log(
      'Booking create: path=${reference.path}, code=$code',
      name: 'lunas.booking.firestore',
    );

    try {
      // Khi mất mạng Firestore sẽ chờ vô hạn, nên đặt giới hạn 15 giây.
      await reference.set(data).timeout(const Duration(seconds: 15));
    } on FirebaseException catch (error) {
      developer.log(
        'Booking create error: code=${error.code}',
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
    } on Exception catch (error) {
      if (error.toString().contains('TimeoutException')) {
        throw const BookingDataException(
          'Lưu lịch hẹn quá lâu. Hãy kiểm tra kết nối mạng rồi thử lại.',
        );
      }
      rethrow;
    }

    return code;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> _getDocument(
    DocumentReference<Map<String, dynamic>> reference,
  ) async {
    try {
      // Read from the server so this diagnostic can distinguish an absent
      // remote document from a cache-only snapshot.
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