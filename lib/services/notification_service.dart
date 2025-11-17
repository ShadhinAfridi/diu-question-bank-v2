// services/notification_service.dart
import 'dart:async';
import 'dart:convert'; // For utf8
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
as fln;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../logger/app_logger.dart';
import '../models/notification_model.dart';
// --- FIX: Added placeholder import for missing model ---
// This model is required by scheduleTaskNotification
// Please ensure this path is correct in your project.
import '../models/task_model.dart';

/// Enum for notification permission status.
enum NotificationPermissionStatus {
  granted,
  denied,
  unknown,
}

/// Service to manage local notifications using [FlutterLocalNotificationsPlugin].
///
/// Handles initialization, permission requests, and scheduling/showing notifications.
class NotificationService {
  // Constants
  static const String _channelId = 'study_reminder_channel';
  static const String _channelName = 'Study Reminders';
  static const String _channelDescription =
      'Notifications for study tasks, exams, and announcements';
  static const String _logTag = 'NOTIFICATIONS';

  // Dependencies
  final fln.FlutterLocalNotificationsPlugin _notificationsPlugin;

  // State
  bool _isInitialized = false;
  bool _isInitializing = false;
  NotificationSettings? _cachedSettings;

  // Stream controllers
  final StreamController<AppNotification> _notificationStreamController =
  StreamController<AppNotification>.broadcast();
  final StreamController<String> _notificationTapStreamController =
  StreamController<String>.broadcast();

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isInitializing => _isInitializing;
  NotificationSettings? get currentSettings => _cachedSettings;

  // Streams
  /// Stream for notifications as they are shown (e.g., to update a UI list).
  Stream<AppNotification> get notificationStream =>
      _notificationStreamController.stream;

  /// Stream for notification tap events, emitting the payload.
  Stream<String> get notificationTapStream =>
      _notificationTapStreamController.stream;

  NotificationService(this._notificationsPlugin);

  /// Initializes the notification service, timezones, and platform settings.
  Future<void> initialize() async {
    if (_isInitialized || _isInitializing) return;

    _isInitializing = true;

    try {
      AppLogger.debug('Initializing notification service...', tag: _logTag);
      tz_data.initializeTimeZones();
      AppLogger.debug('Timezone data initialized', tag: _logTag);

      const fln.AndroidInitializationSettings androidSettings =
      fln.AndroidInitializationSettings('@mipmap/ic_launcher');

      const fln.DarwinInitializationSettings iosSettings =
      fln.DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        requestCriticalPermission: true, // For critical alerts
      );

      const fln.InitializationSettings initializationSettings =
      fln.InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
        macOS: iosSettings, // Use same settings for macOS
      );

      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _handleNotificationResponse,
        onDidReceiveBackgroundNotificationResponse:
        _handleBackgroundNotificationResponse,
      );

      await _createNotificationChannel();
      _cachedSettings = NotificationSettings.defaults();

      _isInitialized = true;
      AppLogger.info('Notification service initialized successfully',
          tag: _logTag);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to initialize notification service',
        tag: _logTag,
        error: error,
        stackTrace: stackTrace,
      );
      _isInitialized = false;
      rethrow; // Rethrow to let the app handle initialization failure
    } finally {
      _isInitializing = false;
    }
  }

  /// Creates the notification channel for Android.
  Future<void> _createNotificationChannel() async {
    try {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
          fln.AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        final fln.AndroidNotificationChannel channel =
        fln.AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: fln.Importance.high,
          playSound: true,
          sound: const fln.RawResourceAndroidNotificationSound('notification'),
          enableVibration: true,
          vibrationPattern: Int64List.fromList(const [0, 500, 200, 500]),
          showBadge: true,
        );
        await androidPlugin.createNotificationChannel(channel);
        AppLogger.debug('Notification channel created: $_channelName',
            tag: _logTag);
      }
    } catch (error) {
      AppLogger.error(
        'Error creating notification channel',
        tag: _logTag,
        error: error,
      );
    }
  }

  /// Handles notification taps when the app is in the foreground or background (but not terminated).
  void _handleNotificationResponse(fln.NotificationResponse response) {
    AppLogger.debug('Notification tapped: ${response.payload}', tag: _logTag);

    if (response.payload != null) {
      // Emit to stream for UI listeners (e.g., in-app navigation)
      _notificationTapStreamController.add(response.payload!);
    }
    // Also process the payload for any immediate logic
    _processNotificationPayload(response.payload);
  }

  /// Handles notification taps when the app is launched from a terminated state.
  @pragma('vm:entry-point')
  static void _handleBackgroundNotificationResponse(
      fln.NotificationResponse response) {
    AppLogger.debug('Background notification tapped: ${response.payload}',
        tag: _logTag);
    // This is a static method. Be careful with what you do here.
    // You might need to use a plugin like `shared_preferences`
    // to store the payload and process it when the app fully starts.
  }

  /// Processes the payload to determine navigation or other actions.
  void _processNotificationPayload(String? payload) {
    if (payload == null) return;
    try {
      // Simple prefix-based routing
      if (payload.startsWith('task_')) {
        _navigateToTask(payload.replaceFirst('task_', ''));
      } else if (payload.startsWith('question_')) {
        _navigateToQuestion(payload.replaceFirst('question_', ''));
      } else if (payload.startsWith('exam_')) {
        _navigateToExam(payload.replaceFirst('exam_', ''));
      }
    } catch (error) {
      AppLogger.error('Error processing notification payload',
          tag: _logTag, error: error);
    }
  }

  // --- Placeholder navigation methods ---
  // Replace these with your app's actual navigation logic (e.g., using GoRouter)

  void _navigateToTask(String taskId) {
    AppLogger.debug('Navigating to task: $taskId', tag: _logTag);
  }

  void _navigateToQuestion(String questionId) {
    AppLogger.debug('Navigating to question: $questionId', tag: _logTag);
  }

  void _navigateToExam(String examId) {
    AppLogger.debug('Navigating to exam: $examId', tag: _logTag);
  }

  /// Requests notification permissions for the platform.
  Future<NotificationPermissionStatus> requestPermissions() async {
    try {
      bool? granted = false;
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidPlugin = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
            fln.AndroidFlutterLocalNotificationsPlugin>();
        granted = await androidPlugin?.requestNotificationsPermission();
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosPlugin = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
            fln.IOSFlutterLocalNotificationsPlugin>();
        granted = await iosPlugin
            ?.requestPermissions(alert: true, badge: true, sound: true);
      } else if (defaultTargetPlatform == TargetPlatform.macOS) {
        final macOSPlugin = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
            fln.MacOSFlutterLocalNotificationsPlugin>();
        granted = await macOSPlugin
            ?.requestPermissions(alert: true, badge: true, sound: true);
      }

      final status = granted == true
          ? NotificationPermissionStatus.granted
          : NotificationPermissionStatus.denied;
      AppLogger.debug('Notification permission status: $status', tag: _logTag);
      return status;
    } catch (error) {
      AppLogger.error('Error requesting notification permissions',
          tag: _logTag, error: error);
      return NotificationPermissionStatus.unknown;
    }
  }

  /// Updates the cached notification settings.
  Future<void> updateSettings(NotificationSettings newSettings) async {
    AppLogger.debug('Updating notification settings', tag: _logTag);
    try {
      _cachedSettings = newSettings;
      AppLogger.debug('Notification settings updated successfully',
          tag: _logTag);
    } catch (error) {
      AppLogger.error('Error updating notification settings',
          tag: _logTag, error: error);
      rethrow;
    }
  }

  /// Shows an immediate notification.
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    NotificationType type = NotificationType.general,
    String? imageUrl, // Note: imageUrl display requires platform-specific setup
    String? actionUrl,
    fln.NotificationDetails? customDetails,
    bool saveToHistory = true, // This param is not used here, but in the caller
  }) async {
    if (!_isInitialized) await initialize();
    if (!_isCategoryEnabled(type)) {
      AppLogger.debug('Notification type $type is disabled', tag: _logTag);
      return;
    }
    try {
      final details = customDetails ?? await _buildNotificationDetails(type);
      await _notificationsPlugin.show(id, title, body, details, payload: payload);

      final notification = AppNotification(
        id: id.toString(),
        title: title,
        body: body,
        receivedAt: DateTime.now(),
        type: type,
        payload: payload,
        imageUrl: imageUrl,
        actionUrl: actionUrl,
      );

      // Add to the stream for any active UI listeners
      _notificationStreamController.add(notification);
      AppLogger.debug('Notification shown: $title', tag: _logTag);
    } catch (error) {
      AppLogger.error('Error showing notification', tag: _logTag, error: error);
      rethrow;
    }
  }

  /// Schedules a notification for a specific [Task].
  Future<void> scheduleTaskNotification(Task task) async {
    // --- CRITICAL FIX: The `id` on `Task` is non-nullable, so `task.id == null`
    // --- is an invalid check. Only check for `task.time`.
    if (task.time == null) {
      AppLogger.warning(
          'Cannot schedule notification: Task time is null. Task ID: ${task.id}',
          tag: _logTag);
      return;
    }
    if (!_isInitialized) await initialize();
    if (!_isCategoryEnabled(NotificationType.taskReminder)) {
      AppLogger.debug('Task reminders are disabled', tag: _logTag);
      return;
    }
    try {
      // Assuming task.time! is already a local DateTime:
      final scheduledDate = tz.TZDateTime.from(task.time!, tz.local);

      if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
        AppLogger.warning(
            'Cannot schedule notification: Task time is in the past',
            tag: _logTag);
        return;
      }
      final details =
      await _buildNotificationDetails(NotificationType.taskReminder);

      // --- FIX: Use a stable numeric ID generator ---
      // --- FIX: Remove unnecessary null-check operator `!` ---
      final notificationId = _generateNumericIdFromString(task.id);

      await _notificationsPlugin.zonedSchedule(
        notificationId,
        '📚 Task Reminder: ${task.title}',
        task.description.isNotEmpty
            ? task.description
            : 'This task is due soon!',
        scheduledDate,
        details,
        androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
        // --- FIX: Removed deprecated parameter ---
        // uiLocalNotificationDateInterpretation:
        //     fln.UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'task_${task.id}',
      );
      AppLogger.debug(
          'Task notification scheduled: ${task.title} at $scheduledDate',
          tag: _logTag);
    } catch (error) {
      AppLogger.error('Error scheduling task notification',
          tag: _logTag, error: error);
      rethrow;
    }
  }

  /// Schedules a repeating study reminder.
  Future<void> scheduleStudyReminder({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime firstDate, // This should be the *first* occurrence
    required fln.RepeatInterval interval,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();
    if (!_isCategoryEnabled(NotificationType.taskReminder)) {
      AppLogger.debug('Study reminders are disabled', tag: _logTag);
      return;
    }
    try {
      final details =
      await _buildNotificationDetails(NotificationType.taskReminder);
      await _notificationsPlugin.periodicallyShow(
        id,
        title,
        body,
        interval,
        details,
        payload: payload,
        androidScheduleMode: fln.AndroidScheduleMode.alarmClock,
      );
      AppLogger.debug('Repeating study reminder scheduled: $title',
          tag: _logTag);
    } catch (error) {
      AppLogger.error('Error scheduling repeating notification',
          tag: _logTag, error: error);
      rethrow;
    }
  }

  /// Schedules a reminder for an exam.
  Future<void> scheduleExamNotification({
    required String examId,
    required String examTitle,
    required DateTime examDate,
    required String location,
  }) async {
    if (!_isInitialized) await initialize();
    if (!_isCategoryEnabled(NotificationType.examSchedule)) {
      AppLogger.debug('Exam notifications are disabled', tag: _logTag);
      return;
    }
    try {
      // Schedule reminder 1 hour before the exam
      final scheduledDate = tz.TZDateTime.from(
          examDate.subtract(const Duration(hours: 1)), tz.local);

      if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
        AppLogger.debug('Exam notification not scheduled: time is in the past',
            tag: _logTag);
        return;
      }
      final details =
      await _buildNotificationDetails(NotificationType.examSchedule);

      // --- FIX 1: Added missing notificationId variable definition ---
      final notificationId = _generateNumericIdFromString(examId);

      await _notificationsPlugin.zonedSchedule(
        notificationId,
        '📝 Exam Reminder: $examTitle',
        'Location: $location\nStarts in 1 hour',
        scheduledDate,
        details,
        androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
        // --- FIX: Removed deprecated parameter ---
        // uiLocalNotificationDateInterpretation:
        //     fln.UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'exam_$examId',
      );
      AppLogger.debug('Exam notification scheduled: $examTitle', tag: _logTag);
    } catch (error) {
      AppLogger.error('Error scheduling exam notification',
          tag: _logTag, error: error);
      rethrow;
    }
  }

  /// Cancels a specific notification by its ID.
  Future<void> cancelNotification(int notificationId) async {
    try {
      await _notificationsPlugin.cancel(notificationId);
      AppLogger.debug('Notification cancelled: $notificationId', tag: _logTag);
    } catch (error) {
      AppLogger.error('Error cancelling notification',
          tag: _logTag, error: error);
    }
  }

  /// Cancels all scheduled notifications.
  Future<void> cancelAllNotifications() async {
    try {
      await _notificationsPlugin.cancelAll();
      AppLogger.debug('All notifications cancelled', tag: _logTag);
    } catch (error) {
      AppLogger.error('Error cancelling all notifications',
          tag: _logTag, error: error);
    }
  }

  /// Retrieves a list of all pending (scheduled) notifications.
  Future<List<fln.PendingNotificationRequest>> getPendingNotifications() async {
    try {
      final pending = await _notificationsPlugin.pendingNotificationRequests();
      AppLogger.debug('Retrieved ${pending.length} pending notifications',
          tag: _logTag);
      return pending;
    } catch (error) {
      AppLogger.error('Error getting pending notifications',
          tag: _logTag, error: error);
      return [];
    }
  }

  /// Checks if notifications are enabled at the system level (Android only).
  Future<bool> areSystemNotificationsEnabled() async {
    if (!_isInitialized) await initialize();
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidPlugin = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
            fln.AndroidFlutterLocalNotificationsPlugin>();
        final enabled = await androidPlugin?.areNotificationsEnabled() ?? false;
        AppLogger.debug('System notifications enabled (Android): $enabled',
            tag: _logTag);
        return enabled;
      }

      AppLogger.debug('System notifications enabled: true (iOS/macOS assumption)',
          tag: _logTag);
      return true;
    } catch (error) {
      AppLogger.error('Error checking system notification status',
          tag: _logTag, error: error);
      return false; // Default to false on error
    }
  }

  // --- Helper methods ---

  /// Checks if a specific notification type is enabled in user settings.
  bool _isCategoryEnabled(NotificationType type) {
    final settings = _cachedSettings ?? NotificationSettings.defaults();

    if (settings.doNotDisturb) {
      AppLogger.debug('DND is active, suppressing notification', tag: _logTag);
      return false;
    }

    switch (type) {
      case NotificationType.taskReminder:
        return settings.taskReminders;
      case NotificationType.eventReminder:
        return settings.eventReminders;
      case NotificationType.announcement:
        return settings.announcements;
      case NotificationType.appUpdate:
        return settings.appUpdates;
      case NotificationType.newQuestion:
        return settings.newQuestions;
      case NotificationType.examSchedule:
        return settings.examSchedules;
      case NotificationType.result:
        return settings.resultNotifications;
      case NotificationType.message:
        return settings.messageNotifications;
      case NotificationType.group:
        return settings.groupNotifications;
      case NotificationType.general:
        return true;
    }
  }

  /// Creates a stable 32-bit signed integer ID from a string.
  int _generateNumericIdFromString(String id) {
    try {
      final bytes = utf8.encode(id);
      int hash = 0;

      for (final byte in bytes) {
        hash = (31 * hash + byte) & 0xFFFFFFFF;
      }

      if (hash > 0x7FFFFFFF) {
        hash = hash - 0x100000000;
      }
      return hash;
    } catch (e) {
      // Fallback for any error
      return DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF;
    }
  }

  /// (Original) Generates an ID for a task notification.
  /// Kept for reference, but `_generateNumericIdFromString` is preferred.
  int _generateNotificationId(Task task) {
    // task.id?.hashCode is not guaranteed to be stable.
    return task.id.hashCode;
  }

  /// Builds platform-specific notification details based on user settings.
  Future<fln.NotificationDetails> _buildNotificationDetails(
      NotificationType type) async {
    final settings = _cachedSettings ?? NotificationSettings.defaults();

    final androidDetails = fln.AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: fln.Importance.high,
      priority: fln.Priority.high,
      playSound: settings.sound,
      sound: settings.sound
          ? const fln.RawResourceAndroidNotificationSound('notification')
          : null,
      enableVibration: settings.vibration,
      enableLights: settings.led,
      styleInformation:
      const fln.BigTextStyleInformation(''), // Allows multi-line text
      autoCancel: true,
      ongoing: false,
      colorized: true, // Tints the notification with app color
    );

    final iosDetails = fln.DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: settings.sound,
      sound: settings.sound ? 'notification.aiff' : null,
      // You can add attachments or category identifiers here
    );

    return fln.NotificationDetails(
        android: androidDetails, iOS: iosDetails, macOS: iosDetails);
  }

  /// Disposes of stream controllers.
  void dispose() {
    _notificationStreamController.close();
    _notificationTapStreamController.close();
    AppLogger.debug('Notification service disposed', tag: _logTag);
  }
}