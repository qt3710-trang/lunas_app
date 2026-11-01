import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/booking_models.dart';

/// Reads only the documents currently used by the Booking screen.
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
