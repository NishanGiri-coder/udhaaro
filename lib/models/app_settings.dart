// lib/models/app_settings.dart
import 'package:hive/hive.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 2)
class AppSettings extends HiveObject {
  @HiveField(0)
  bool outstandingAlertEnabled;

  @HiveField(1)
  double thresholdAmount;

  @HiveField(2)
  bool unpaidReminderEnabled;

  @HiveField(3)
  int reminderFrequencyDays;

  @HiveField(4)
  int reminderHour;

  @HiveField(5)
  int reminderMinute;

  @HiveField(6)
  bool thresholdNotified;

  AppSettings({
    this.outstandingAlertEnabled = true,
    this.thresholdAmount = 5000,
    this.unpaidReminderEnabled = false,
    this.reminderFrequencyDays = 7,
    this.reminderHour = 20,
    this.reminderMinute = 0,
    this.thresholdNotified = false,
  });

  Map<String, dynamic> toJson() => {
        'outstandingAlertEnabled': outstandingAlertEnabled,
        'thresholdAmount': thresholdAmount,
        'unpaidReminderEnabled': unpaidReminderEnabled,
        'reminderFrequencyDays': reminderFrequencyDays,
        'reminderHour': reminderHour,
        'reminderMinute': reminderMinute,
        'thresholdNotified': thresholdNotified,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        outstandingAlertEnabled: json['outstandingAlertEnabled'] ?? true,
        thresholdAmount: (json['thresholdAmount'] as num?)?.toDouble() ?? 5000,
        unpaidReminderEnabled: json['unpaidReminderEnabled'] ?? false,
        reminderFrequencyDays: json['reminderFrequencyDays'] ?? 7,
        reminderHour: json['reminderHour'] ?? 20,
        reminderMinute: json['reminderMinute'] ?? 0,
        thresholdNotified: json['thresholdNotified'] ?? false,
      );
}