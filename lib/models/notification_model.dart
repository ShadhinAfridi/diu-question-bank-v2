// models/notification_model.dart
import 'package:hive/hive.dart';
// --- FIX: Standardized import path ---
// (Assuming 'diuquestionbank' is your project name)
import 'package:diuquestionbank/constants/hive_type_ids.dart';

// --- FIX: Added import for cloud_firestore.Timestamp ---
// This is needed for the fromMap parser to recognize the type.
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

part 'notification_model.g.dart';

@HiveType(typeId: kNotificationTypeAdapterId)
enum NotificationType {
  @HiveField(0)
  taskReminder,

  @HiveField(1)
  eventReminder,

  @HiveField(2)
  announcement,

  @HiveField(3)
  appUpdate,

  @HiveField(4)
  newQuestion,

  @HiveField(5)
  examSchedule,

  @HiveField(6)
  result,

  @HiveField(7)
  message,

  @HiveField(8)
  group,

  @HiveField(9)
  general,
}

@HiveType(typeId: kNotificationSettingsTypeId)
class NotificationSettings {
  @HiveField(0)
  final bool taskReminders;

  @HiveField(1)
  final bool eventReminders;

  @HiveField(2)
  final bool announcements;

  @HiveField(3)
  final bool appUpdates;

  @HiveField(4)
  final bool newQuestions;

  @HiveField(5)
  final bool examSchedules;

  @HiveField(6)
  final bool resultNotifications;

  @HiveField(7)
  final bool messageNotifications;

  @HiveField(8)
  final bool groupNotifications;

  @HiveField(9)
  final bool sound;

  @HiveField(10)
  final bool vibration;

  @HiveField(11)
  final bool led;

  @HiveField(12)
  final bool doNotDisturb;

  @HiveField(13)
  final String? doNotDisturbStart;

  @HiveField(14)
  final String? doNotDisturbEnd;

  NotificationSettings({
    required this.taskReminders,
    required this.eventReminders,
    required this.announcements,
    required this.appUpdates,
    required this.newQuestions,
    required this.examSchedules,
    required this.resultNotifications,
    required this.messageNotifications,
    required this.groupNotifications,
    required this.sound,
    required this.vibration,
    required this.led,
    required this.doNotDisturb,
    this.doNotDisturbStart,
    this.doNotDisturbEnd,
  });

  // Factory constructor for default settings
  factory NotificationSettings.defaults() {
    return NotificationSettings(
      taskReminders: true,
      eventReminders: true,
      announcements: true,
      appUpdates: true,
      newQuestions: true,
      examSchedules: true,
      resultNotifications: true,
      messageNotifications: true,
      groupNotifications: true,
      sound: true,
      vibration: true,
      led: true,
      doNotDisturb: false,
      doNotDisturbStart: null,
      doNotDisturbEnd: null,
    );
  }

  // Serializer for Firestore
  Map<String, dynamic> toMap() {
    return {
      'taskReminders': taskReminders,
      'eventReminders': eventReminders,
      'announcements': announcements,
      'appUpdates': appUpdates,
      'newQuestions': newQuestions,
      'examSchedules': examSchedules,
      'resultNotifications': resultNotifications,
      'messageNotifications': messageNotifications,
      'groupNotifications': groupNotifications,
      'sound': sound,
      'vibration': vibration,
      'led': led,
      'doNotDisturb': doNotDisturb,
      'doNotDisturbStart': doNotDisturbStart,
      'doNotDisturbEnd': doNotDisturbEnd,
    };
  }

  // Deserializer from Firestore
  factory NotificationSettings.fromMap(Map<String, dynamic> map) {
    return NotificationSettings(
      taskReminders: map['taskReminders'] ?? true,
      eventReminders: map['eventReminders'] ?? true,
      announcements: map['announcements'] ?? true,
      appUpdates: map['appUpdates'] ?? true,
      newQuestions: map['newQuestions'] ?? true,
      examSchedules: map['examSchedules'] ?? true,
      resultNotifications: map['resultNotifications'] ?? true,
      messageNotifications: map['messageNotifications'] ?? true,
      groupNotifications: map['groupNotifications'] ?? true,
      sound: map['sound'] ?? true,
      vibration: map['vibration'] ?? true,
      led: map['led'] ?? true,
      doNotDisturb: map['doNotDisturb'] ?? false,
      doNotDisturbStart: map['doNotDisturbStart'],
      doNotDisturbEnd: map['doNotDisturbEnd'],
    );
  }

  // copyWith method for immutability
  NotificationSettings copyWith({
    bool? taskReminders,
    bool? eventReminders,
    bool? announcements,
    bool? appUpdates,
    bool? newQuestions,
    bool? examSchedules,
    bool? resultNotifications,
    bool? messageNotifications,
    bool? groupNotifications,
    bool? sound,
    bool? vibration,
    bool? led,
    bool? doNotDisturb,
    String? doNotDisturbStart,
    String? doNotDisturbEnd,
  }) {
    return NotificationSettings(
      taskReminders: taskReminders ?? this.taskReminders,
      eventReminders: eventReminders ?? this.eventReminders,
      announcements: announcements ?? this.announcements,
      appUpdates: appUpdates ?? this.appUpdates,
      newQuestions: newQuestions ?? this.newQuestions,
      examSchedules: examSchedules ?? this.examSchedules,
      resultNotifications: resultNotifications ?? this.resultNotifications,
      messageNotifications: messageNotifications ?? this.messageNotifications,
      groupNotifications: groupNotifications ?? this.groupNotifications,
      sound: sound ?? this.sound,
      vibration: vibration ?? this.vibration,
      led: led ?? this.led,
      doNotDisturb: doNotDisturb ?? this.doNotDisturb,
      doNotDisturbStart: doNotDisturbStart ?? this.doNotDisturbStart,
      doNotDisturbEnd: doNotDisturbEnd ?? this.doNotDisturbEnd,
    );
  }
}

@HiveType(typeId: kAppNotificationTypeId)
class AppNotification {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String body;

  @HiveField(3)
  final DateTime receivedAt;

  @HiveField(4)
  final NotificationType type;

  @HiveField(5)
  final String? payload;

  @HiveField(6)
  final String? imageUrl;

  @HiveField(7)
  final String? actionUrl;

  @HiveField(8)
  final bool isRead;

  // --- FIX: Added 'updatedAt' field ---
  // This field was being written in NotificationRepositoryImpl
  // but was missing from the model, causing data loss.
  @HiveField(9)
  final DateTime? updatedAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.receivedAt,
    required this.type,
    this.payload,
    this.imageUrl,
    this.actionUrl,
    this.isRead = false,
    this.updatedAt, // Added to constructor
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? receivedAt,
    NotificationType? type,
    String? payload,
    String? imageUrl,
    String? actionUrl,
    bool? isRead,
    DateTime? updatedAt, // Added to copyWith
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      receivedAt: receivedAt ?? this.receivedAt,
      type: type ?? this.type,
      payload: payload ?? this.payload,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
      isRead: isRead ?? this.isRead,
      updatedAt: updatedAt ?? this.updatedAt, // Added to copyWith
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      // --- FIX: Store as Milliseconds for JSON, convert to Timestamp in Repo ---
      'receivedAt': receivedAt.millisecondsSinceEpoch,
      'type': type.index,
      'payload': payload,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
      'isRead': isRead,
      'updatedAt': updatedAt?.millisecondsSinceEpoch, // Added to toMap
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    // --- FIX: Handle both Timestamp (from Firestore) and int (from toMap) ---
    DateTime _parseDateTime(dynamic timestamp) {
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      }
      if (timestamp is int) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      // Fallback for null or unexpected type
      return DateTime.now();
    }

    return AppNotification(
      id: map['id'],
      title: map['title'],
      body: map['body'],
      receivedAt: _parseDateTime(map['receivedAt']),
      type: NotificationType.values[map['type'] ?? 0], // Added default
      payload: map['payload'],
      imageUrl: map['imageUrl'],
      actionUrl: map['actionUrl'],
      isRead: map['isRead'] ?? false,
      // Added to fromMap, checking for null
      updatedAt:
      map['updatedAt'] != null ? _parseDateTime(map['updatedAt']) : null,
    );
  }
}

// --- FIX: Removed extra trailing '}' ---
// The original file had a syntax error here (an extra closing brace).