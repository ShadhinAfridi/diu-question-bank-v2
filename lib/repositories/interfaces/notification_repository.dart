// repositories/interfaces/notification_repository.dart
import '../../models/notification_model.dart';

/// Abstract repository for managing notification settings and history.
///
/// This interface defines the contract for loading/saving user-specific
/// notification preferences and handling the notification history log.
abstract class INotificationRepository {
  /// Loads the user's current notification settings.
  ///
  /// Tries to fetch from cache first, then falls back to remote source (e.g., Firestore).
  /// Returns default settings if no settings are found.
  Future<NotificationSettings> loadUserSettings();

  /// Saves the user's notification settings to both cache and remote source.
  Future<void> saveUserSettings(NotificationSettings settings);

  /// Saves a received notification to the user's history
  /// in both cache and remote source.
  Future<void> saveNotificationHistory(AppNotification notification);

  /// Retrieves the user's notification history, sorted by most recent.
  ///
  /// Tries to fetch from cache first, then falls back to remote source.
  Future<List<AppNotification>> getNotificationHistory();

  /// Marks a specific notification as read in cache and remote source.
  Future<void> markNotificationAsRead(String notificationId);

  /// Clears the entire notification history from cache and remote source.
  Future<void> clearNotificationHistory();

  /// Gets a count of unread notifications.
  ///
  /// Tries to get this value from cache for performance.
  Future<int> getUnreadNotificationCount();
}