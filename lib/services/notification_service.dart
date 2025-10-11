// notification_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task_model.dart';
import '../models/notification_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String _channelId = 'task_reminder_channel';
  static const String _channelName = 'Task Reminders';
  static const String _channelDescription = 'Notifications for task reminders';

  final fln.FlutterLocalNotificationsPlugin _notificationsPlugin = fln.FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz_data.initializeTimeZones();

    const fln.AndroidInitializationSettings initializationSettingsAndroid =
    fln.AndroidInitializationSettings('@mipmap/ic_launcher');

    const fln.DarwinInitializationSettings initializationSettingsIOS = fln.DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const fln.InitializationSettings initializationSettings = fln.InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
      macOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (fln.NotificationResponse response) {
        // Handle notification tap
      },
    );

    await _createNotificationChannel();
  }

  Future<void> _createNotificationChannel() async {
    final fln.AndroidFlutterLocalNotificationsPlugin? androidImplementation =
    _notificationsPlugin.resolvePlatformSpecificImplementation<fln.AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      const fln.AndroidNotificationChannel channel = fln.AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: fln.Importance.max,
        playSound: true,
      );
      await androidImplementation.createNotificationChannel(channel);
    }
  }

  Future<void> requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidImplementation = _notificationsPlugin.resolvePlatformSpecificImplementation<fln.AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<fln.IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  Future<NotificationSettings> _getSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return NotificationSettings.defaults();

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('notifications')
          .get();
      if (doc.exists && doc.data() != null) {
        return NotificationSettings.fromMap(doc.data()!);
      }
    } catch (e) {
      debugPrint("Could not get notification settings: $e. Using defaults.");
    }
    return NotificationSettings.defaults();
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String category = 'taskReminder',
  }) async {
    final settings = await _getSettings();

    if (settings.doNotDisturb) return;

    bool canShow;
    switch (category) {
      case 'appUpdates':
        canShow = settings.appUpdates;
        break;
      case 'announcements':
        canShow = settings.announcements;
        break;
      case 'taskReminder':
        canShow = settings.taskReminders;
        break;
      case 'eventReminder':
        canShow = settings.eventReminders;
        break;
      default:
        canShow = true;
    }

    if (!canShow) return;

    final bool playSound = settings.sound;
    final String soundFile = settings.notificationSound;

    final androidDetails = fln.AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: fln.Importance.max,
      priority: fln.Priority.high,
      playSound: playSound,
      sound: playSound ? fln.RawResourceAndroidNotificationSound(soundFile) : null,
      enableVibration: settings.vibration,
    );

    final iOSDetails = fln.DarwinNotificationDetails(
      presentSound: playSound,
      sound: playSound ? '$soundFile.aiff' : null,
    );

    final details = fln.NotificationDetails(android: androidDetails, iOS: iOSDetails, macOS: iOSDetails);

    await _notificationsPlugin.show(id, title, body, details);
  }

  Future<void> scheduleTaskNotification(Task task) async {
    if (task.id == null || task.time == null) return;

    final scheduledDate = tz.TZDateTime.from(task.time!, tz.local);
    if (scheduledDate.isBefore(DateTime.now())) return;

    final settings = await _getSettings();
    if (!settings.taskReminders || settings.doNotDisturb) return;

    final bool playSound = settings.sound;
    final String soundFile = settings.notificationSound;

    await _notificationsPlugin.zonedSchedule(
      task.id!,
      'Task Reminder: ${task.title}',
      task.description.isNotEmpty ? task.description : 'This task is due now!',
      scheduledDate,
      fln.NotificationDetails(
        android: fln.AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: fln.Importance.max,
          priority: fln.Priority.high,
          playSound: playSound,
          sound: playSound ? fln.RawResourceAndroidNotificationSound(soundFile) : null,
          enableVibration: settings.vibration,
        ),
        iOS: fln.DarwinNotificationDetails(
          presentSound: playSound,
          sound: playSound ? '$soundFile.aiff' : null,
        ),
      ),
      androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelTaskNotification(int notificationId) async {
    await _notificationsPlugin.cancel(notificationId);
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
    debugPrint("All flutter_local_notifications have been cancelled.");
  }
}