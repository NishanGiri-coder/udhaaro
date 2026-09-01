// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 2;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      outstandingAlertEnabled: fields[0] as bool,
      thresholdAmount: fields[1] as double,
      unpaidReminderEnabled: fields[2] as bool,
      reminderFrequencyDays: fields[3] as int,
      reminderHour: fields[4] as int,
      reminderMinute: fields[5] as int,
      thresholdNotified: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.outstandingAlertEnabled)
      ..writeByte(1)
      ..write(obj.thresholdAmount)
      ..writeByte(2)
      ..write(obj.unpaidReminderEnabled)
      ..writeByte(3)
      ..write(obj.reminderFrequencyDays)
      ..writeByte(4)
      ..write(obj.reminderHour)
      ..writeByte(5)
      ..write(obj.reminderMinute)
      ..writeByte(6)
      ..write(obj.thresholdNotified);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
