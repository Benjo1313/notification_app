// ...existing code...
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _fln = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tzdata.initializeTimeZones();
    final android = AndroidInitializationSettings('@mipmap/ic_launcher');
    final iOS = DarwinInitializationSettings();
    await _fln.initialize(
      InitializationSettings(android: android, iOS: iOS),
    );
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    final tz.TZDateTime zdt = tz.TZDateTime.from(scheduledDate, tz.local);
    final androidDetails = AndroidNotificationDetails(
      'timer_channel',
      'Timer notifications',
      channelDescription: 'Timer expiry warnings',
      importance: Importance.high,
      priority: Priority.high,
    );
    final iosDetails = DarwinNotificationDetails();
    await _fln.zonedSchedule(
      id,
      title,
      body,
      zdt,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> showNow({
    required int id,
    required String title,
    required String body,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'timer_channel',
      'Timer notifications',
      channelDescription: 'Timer expiry warnings',
      importance: Importance.high,
      priority: Priority.high,
    );
    final iosDetails = DarwinNotificationDetails();
    await _fln.show(id, title, body, NotificationDetails(android: androidDetails, iOS: iosDetails));
  }

  Future<void> cancel(int id) => _fln.cancel(id);
}