import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Displays local Android notifications for successfully persisted bookings.
class BookingNotificationService {
  BookingNotificationService._();

  static final instance = BookingNotificationService._();

  static const _channelId = 'booking_success';
  static const _channelName = 'Đặt lịch thành công';
  static const _channelDescription =
      'Thông báo khi LUNAS ghi nhận lịch hẹn của bạn.';
  static const _channel = AndroidNotificationChannel(
    _channelId,
    _channelName,
    description: _channelDescription,
    importance: Importance.high,
  );
  static const _permissionRequestedKey =
      'lunas_booking_notification_permission_requested';
  static final _notificationPlugin = FlutterLocalNotificationsPlugin();

  final Set<String> _attemptedBookingIds = <String>{};
  Future<bool?>? _initialization;
  bool _permissionRequestAttempted = false;

  Future<void> showBookingSuccess({required String bookingId}) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    if (!_attemptedBookingIds.add(bookingId)) {
      developer.log(
        'Skipped duplicate booking notification.',
        name: 'lunas.booking.notifications',
      );
      return;
    }

    try {
      await (_initialization ??= _notificationPlugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_stat_lunas'),
        ),
      ));

      final android = _notificationPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android == null) {
        developer.log(
          'Android notification implementation is unavailable.',
          name: 'lunas.booking.notifications',
        );
        return;
      }

      await android.createNotificationChannel(_channel);
      final notificationsEnabled = await android.areNotificationsEnabled();
      if (notificationsEnabled != true) {
        if (!await _shouldRequestPermission()) {
          developer.log(
            'Notifications are disabled; permission was already requested.',
            name: 'lunas.booking.notifications',
          );
          return;
        }

        final granted = await android.requestNotificationsPermission();
        if (granted != true) {
          developer.log(
            'Notification permission was not granted.',
            name: 'lunas.booking.notifications',
          );
          return;
        }
      }

      await _notificationPlugin.show(
        id: bookingId.hashCode & 0x7fffffff,
        title: 'Đặt lịch thành công!',
        body: 'LUNAS đã ghi nhận yêu cầu đặt lịch của bạn. Lịch hẹn đang chờ salon xác nhận.',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            icon: 'ic_stat_lunas',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
      developer.log(
        'Booking notification displayed.',
        name: 'lunas.booking.notifications',
      );
    } catch (error, stackTrace) {
      developer.log(
        'Failed to display booking notification: ${error.runtimeType}',
        name: 'lunas.booking.notifications',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<bool> _shouldRequestPermission() async {
    if (_permissionRequestAttempted) return false;
    _permissionRequestAttempted = true;

    try {
      final preferences = await SharedPreferences.getInstance();
      if (preferences.getBool(_permissionRequestedKey) ?? false) return false;
      await preferences.setBool(_permissionRequestedKey, true);
    } catch (error) {
      developer.log(
        'Could not persist notification permission prompt state: '
        '${error.runtimeType}',
        name: 'lunas.booking.notifications',
      );
    }
    return true;
  }
}
