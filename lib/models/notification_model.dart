import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'notification_model.g.dart';

/// ## File Overview
/// This file defines the data models for notification settings and individual notifications.
///
/// ### Changes
/// - **Added Hive Support for `AppNotification`:** The `AppNotification` class now
///   extends `HiveObject` and includes Hive annotations, allowing notifications
///   to be cached locally for faster load times and offline access.
/// - **Handled `Timestamp` Conversion:** Logic has been added to the `fromMap` and
///   `toMap` methods to correctly convert between Firestore's `Timestamp` and
///   Dart's `DateTime` object, which is compatible with Hive.

@HiveType(typeId: 1)
class NotificationSettings extends HiveObject {
  @HiveField(0)
  bool appUpdates;

  @HiveField(1)
  bool announcements;

  @HiveField(2)
  bool newQuestions;

  @HiveField(3)
  bool examSchedules;

  @HiveField(4)
  bool resultNotifications;

  @HiveField(5)
  bool messageNotifications;

  @HiveField(6)
  bool groupNotifications;

  @HiveField(7)
  bool sound;

  @HiveField(8)
  bool vibration;

  @HiveField(9)
  bool led;

  @HiveField(10)
  bool doNotDisturb;

  @HiveField(11)
  String notificationSound;

  @HiveField(12)
  bool taskReminders;

  @HiveField(13)
  bool eventReminders;


  NotificationSettings({
    this.appUpdates = true,
    this.announcements = true,
    this.newQuestions = true,
    this.examSchedules = true,
    this.resultNotifications = true,
    this.messageNotifications = true,
    this.groupNotifications = true,
    this.sound = true,
    this.vibration = true,
    this.led = false,
    this.doNotDisturb = false,
    this.notificationSound = 'default',
    this.taskReminders = true,
    this.eventReminders = true,
  });

  factory NotificationSettings.defaults() => NotificationSettings();

  factory NotificationSettings.fromMap(Map<String, dynamic> map) {
    return NotificationSettings(
      appUpdates: map['appUpdates'] ?? true,
      announcements: map['announcements'] ?? true,
      newQuestions: map['newQuestions'] ?? true,
      examSchedules: map['examSchedules'] ?? true,
      resultNotifications: map['resultNotifications'] ?? true,
      messageNotifications: map['messageNotifications'] ?? true,
      groupNotifications: map['groupNotifications'] ?? true,
      sound: map['sound'] ?? true,
      vibration: map['vibration'] ?? true,
      led: map['led'] ?? false,
      doNotDisturb: map['doNotDisturb'] ?? false,
      notificationSound: map['notificationSound'] ?? 'default',
      taskReminders: map['taskReminders'] ?? true,
      eventReminders: map['eventReminders'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'appUpdates': appUpdates,
      'announcements': announcements,
      'newQuestions': newQuestions,
      'examSchedules': examSchedules,
      'resultNotifications': resultNotifications,
      'messageNotifications': messageNotifications,
      'groupNotifications': groupNotifications,
      'sound': sound,
      'vibration': vibration,
      'led': led,
      'doNotDisturb': doNotDisturb,
      'notificationSound': notificationSound,
      'taskReminders': taskReminders,
      'eventReminders': eventReminders,
    };
  }
}

// Updated to support Hive caching
@HiveType(typeId: 2)
class AppNotification extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String body;

  @HiveField(3)
  final DateTime receivedAt;

  @HiveField(4)
  bool isRead;

  @HiveField(5)
  final String type;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.receivedAt,
    this.isRead = false,
    required this.type,
  });

  factory AppNotification.fromMap(String id, Map<String, dynamic> map) {
    return AppNotification(
      id: id,
      title: map['title'] ?? 'No Title',
      body: map['body'] ?? '',
      receivedAt: (map['receivedAt'] as Timestamp? ?? Timestamp.now()).toDate(),
      isRead: map['isRead'] ?? false,
      type: map['type'] ?? 'general',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'receivedAt': Timestamp.fromDate(receivedAt),
      'isRead': isRead,
      'type': type,
    };
  }
}
