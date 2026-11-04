import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'hair_style.dart';
import '../../models/booking_models.dart';

/// In-memory booking draft shared by the retained tab screens.
class BookingDraftStore extends ChangeNotifier {
  BookingDraftStore._() {
    _ownerUid = FirebaseAuth.instance.currentUser?.uid;
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
      _handleAuthChange,
    );
  }

  static final instance = BookingDraftStore._();

  late final StreamSubscription<User?> _authSubscription;
  String? _ownerUid;

  BookingMode? _mode;
  String? _hairStyleId;
  String? _hairStyleName;
  String? _hairStyleColor;
  int? _hairStyleColorValue;
  String? _hairStyleImageUrl;
  String? _hairServiceId;
  final Set<String> _selectedServiceIds = {};
  DateTime? _selectedDate;
  String? _selectedTime;

  BookingMode? get mode {
    _syncOwner();
    return _mode;
  }

  String? get hairStyleId => _hairStyleId;
  String? get hairStyleName => _hairStyleName;
  String? get hairStyleColor => _hairStyleColor;
  int? get hairStyleColorValue => _hairStyleColorValue;
  String? get hairStyleImageUrl => _hairStyleImageUrl;
  String? get hairServiceId => _hairServiceId;
  Set<String> get selectedServiceIds => Set.unmodifiable(_selectedServiceIds);
  DateTime? get selectedDate => _selectedDate;
  String? get selectedTime => _selectedTime;

  void startServiceOnly({String? selectedServiceId}) {
    _syncOwner();
    _clearStyle();
    _mode = BookingMode.serviceOnly;
    _selectedServiceIds
      ..clear()
      ..addAll([?selectedServiceId]);
    _selectedDate = null;
    _selectedTime = null;
    notifyListeners();
  }

  void selectHairStyle({
    required HairStyle style,
    required HairColor color,
    required String? serviceId,
  }) {
    _syncOwner();
    _mode = BookingMode.hairstyle;
    _hairStyleId = style.id;
    _hairStyleName = style.name;
    _hairStyleColor = color.label;
    _hairStyleColorValue = color.color.toARGB32();
    _hairStyleImageUrl = style.imageFor(color);
    _hairServiceId = serviceId;
    _selectedServiceIds.clear();
    _selectedDate = null;
    _selectedTime = null;
    notifyListeners();
  }

  void toggleService(String serviceId) {
    _syncOwner();
    _selectedServiceIds.contains(serviceId)
        ? _selectedServiceIds.remove(serviceId)
        : _selectedServiceIds.add(serviceId);
    notifyListeners();
  }

  void selectDate(DateTime date) {
    _selectedDate = DateTime(date.year, date.month, date.day);
    notifyListeners();
  }

  void selectTime(String? time) {
    _selectedTime = time;
    notifyListeners();
  }

  /// Starts another appointment while retaining only the current booking mode
  /// and, for hairstyle bookings, the selected hairstyle and color.
  void resetForNewBooking() {
    _syncOwner();
    _selectedDate = null;
    _selectedTime = null;
    _selectedServiceIds.clear();
    if (_mode == BookingMode.serviceOnly) _clearStyle();
    notifyListeners();
  }

  void clear() {
    _mode = null;
    _clearStyle();
    _selectedServiceIds.clear();
    _selectedDate = null;
    _selectedTime = null;
    notifyListeners();
  }

  void _handleAuthChange(User? user) {
    final nextUid = user?.uid;
    if (nextUid != _ownerUid) {
      _ownerUid = nextUid;
      _mode = null;
      _clearStyle();
      _selectedServiceIds.clear();
      _selectedDate = null;
      _selectedTime = null;
      notifyListeners();
    }
  }

  void _syncOwner() {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid != _ownerUid) {
      _ownerUid = currentUid;
      _mode = null;
      _clearStyle();
      _selectedServiceIds.clear();
      _selectedDate = null;
      _selectedTime = null;
    }
  }

  void _clearStyle() {
    _hairStyleId = null;
    _hairStyleName = null;
    _hairStyleColor = null;
    _hairStyleColorValue = null;
    _hairStyleImageUrl = null;
    _hairServiceId = null;
  }

  @override
  void dispose() {
    unawaited(_authSubscription.cancel());
    super.dispose();
  }
}

/// A conservative mapping to the salon service documents present in the app.
/// Styles without a matching Firestore service remain unbookable by hairstyle.
String? bookingServiceIdForHairStyle(HairStyle style) {
  final configuredId = style.bookingServiceId?.trim();
  if (configuredId != null && configuredId.isNotEmpty) return configuredId;
  if (style.types.contains(HairType.layer)) return 'cat-toc-layer-nu';
  if (style.types.contains(HairType.curly)) return 'uon-tao-kieu';
  return null;
}

String? bookingServiceIdForCareTreatment(String treatmentId) =>
    switch (treatmentId) {
      'deep-repair' => 'hap-phuc-hoi-toc',
      'soft-moisture' => 'duong-toc-mem-muot',
      _ => null,
    };
