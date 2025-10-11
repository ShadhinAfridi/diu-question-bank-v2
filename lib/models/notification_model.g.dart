// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NotificationSettingsAdapter extends TypeAdapter<NotificationSettings> {
  @override
  final int typeId = 1;

  @override
  NotificationSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NotificationSettings(
      appUpdates: fields[0] as bool,
      announcements: fields[1] as bool,
      newQuestions: fields[2] as bool,
      examSchedules: fields[3] as bool,
      resultNotifications: fields[4] as bool,
      messageNotifications: fields[5] as bool,
      groupNotifications: fields[6] as bool,
      sound: fields[7] as bool,
      vibration: fields[8] as bool,
      led: fields[9] as bool,
      doNotDisturb: fields[10] as bool,
      notificationSound: fields[11] as String,
      taskReminders: fields[12] as bool,
      eventReminders: fields[13] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, NotificationSettings obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.appUpdates)
      ..writeByte(1)
      ..write(obj.announcements)
      ..writeByte(2)
      ..write(obj.newQuestions)
      ..writeByte(3)
      ..write(obj.examSchedules)
      ..writeByte(4)
      ..write(obj.resultNotifications)
      ..writeByte(5)
      ..write(obj.messageNotifications)
      ..writeByte(6)
      ..write(obj.groupNotifications)
      ..writeByte(7)
      ..write(obj.sound)
      ..writeByte(8)
      ..write(obj.vibration)
      ..writeByte(9)
      ..write(obj.led)
      ..writeByte(10)
      ..write(obj.doNotDisturb)
      ..writeByte(11)
      ..write(obj.notificationSound)
      ..writeByte(12)
      ..write(obj.taskReminders)
      ..writeByte(13)
      ..write(obj.eventReminders);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AppNotificationAdapter extends TypeAdapter<AppNotification> {
  @override
  final int typeId = 2;

  @override
  AppNotification read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppNotification(
      id: fields[0] as String,
      title: fields[1] as String,
      body: fields[2] as String,
      receivedAt: fields[3] as DateTime,
      isRead: fields[4] as bool,
      type: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AppNotification obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.body)
      ..writeByte(3)
      ..write(obj.receivedAt)
      ..writeByte(4)
      ..write(obj.isRead)
      ..writeByte(5)
      ..write(obj.type);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppNotificationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
