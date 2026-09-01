// lib/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz_data.initializeTimeZones();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(initSettings);
  }

  Future<void> requestPermissions() async {
    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.requestNotificationsPermission();
  }

  Future<void> showThresholdNotification(double currentTotal, int unpaidCount) async {
    const androidDetails = AndroidNotificationDetails(
      'threshold_channel',
      'Outstanding Threshold Alerts',
      channelDescription: 'Alerts when overall unpaid credit crosses set limit',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(
      101,
      '💰 Udhaaro Reminder',
      'Your total pending amount is now रु ${currentTotal.toStringAsFixed(0)}. You have $unpaidCount unpaid items.',
      details,
    );
  }

  Future<void> schedulePeriodicReminder(int intervalDays, int hour, int minute, int totalItems, double totalAmount) async {
    await _notificationsPlugin.cancel(202);
    const androidDetails = AndroidNotificationDetails(
      'reminder_channel',
      'Unpaid Item Reminders',
      channelDescription: 'Scheduled reminders for overall pending bills',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const details = NotificationDetails(android: androidDetails);

    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(Duration(days: intervalDays));
    }

    await _notificationsPlugin.zonedSchedule(
      202,
      '🔔 Udhaaro Periodic Reminder',
      'You still have $totalItems unpaid items worth रु ${totalAmount.toStringAsFixed(0)}.',
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  Future<void> cancelReminder() async {
    await _notificationsPlugin.cancel(202);
  }
}