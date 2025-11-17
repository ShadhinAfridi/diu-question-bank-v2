// repositories/implementations/notification_repository_impl.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../logger/app_logger.dart';
import '../../models/notification_model.dart';
import '../interfaces/notification_repository.dart';
import '../../providers/cache_providers.dart';

class NotificationRepositoryImpl implements INotificationRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final NotificationRepositoryCache _cache;
  static const String _logTag = 'NOTIFICATION_REPO';

  NotificationRepositoryImpl({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    required NotificationRepositoryCache cache,
  }) : _firestore = firestore,
       _auth = auth,
       _cache = cache;

  String _getUserId() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return user.uid;
  }

  DocumentReference<Map<String, dynamic>> _getSettingsDocRef(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('settings')
        .doc('notifications');
  }

  CollectionReference<Map<String, dynamic>> _getHistoryCollectionRef(
    String userId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications');
  }

  @override
  Future<NotificationSettings> loadUserSettings() async {
    // Create the future first, then pass it
    Future<NotificationSettings> fetchSettings() async {
      try {
        final userId = _getUserId();
        final doc = await _getSettingsDocRef(userId).get();

        if (doc.exists && doc.data() != null) {
          return NotificationSettings.fromMap(doc.data()!);
        } else {
          final defaultSettings = NotificationSettings.defaults();
          await saveUserSettings(defaultSettings);
          return defaultSettings;
        }
      } catch (error) {
        AppLogger.error('Error loading notification settings', error: error);
        return NotificationSettings.defaults();
      }
    }

    return await _cache.getSettingsWithFallback(fetchSettings());
  }

  @override
  Future<void> saveUserSettings(NotificationSettings settings) async {
    try {
      final userId = _getUserId();
      await _getSettingsDocRef(userId).set(settings.toMap());
      await _cache.settingsBox.put('current_user_settings', settings);
      await _cache.setLastSyncTime(DateTime.now());
    } catch (error) {
      AppLogger.error('Error saving notification settings', error: error);
      rethrow;
    }
  }

  @override
  Future<void> saveNotificationHistory(AppNotification notification) async {
    try {
      final userId = _getUserId();
      final data = notification.toMap();

      data['receivedAt'] = Timestamp.fromMillisecondsSinceEpoch(
        data['receivedAt'],
      );
      if (data['updatedAt'] != null) {
        data['updatedAt'] = Timestamp.fromMillisecondsSinceEpoch(
          data['updatedAt'],
        );
      }

      await _getHistoryCollectionRef(userId).doc(notification.id).set(data);
      await _cache.addNotificationToHistory(notification);
    } catch (error) {
      AppLogger.error('Error saving notification history', error: error);
    }
  }

  @override
  Future<List<AppNotification>> getNotificationHistory() async {
    // Create the future first, then pass it to the cache
    Future<List<AppNotification>> fetchNotificationHistory() async {
      try {
        final userId = _getUserId();
        final snapshot = await _getHistoryCollectionRef(
          userId,
        ).orderBy('receivedAt', descending: true).limit(50).get();

        return snapshot.docs.map((doc) {
          final data = doc.data();
          return AppNotification(
            id: doc.id,
            title: data['title'] ?? '',
            body: data['body'] ?? '',
            receivedAt: (data['receivedAt'] as Timestamp).toDate(),
            type: NotificationType.values[data['type'] ?? 0],
            payload: data['payload'],
            imageUrl: data['imageUrl'],
            actionUrl: data['actionUrl'],
            isRead: data['isRead'] ?? false,
            updatedAt:
                data.containsKey('updatedAt') && data['updatedAt'] != null
                ? (data['updatedAt'] as Timestamp).toDate()
                : null,
          );
        }).toList();
      } catch (error) {
        AppLogger.error('Error getting notification history', error: error);
        return [];
      }
    }

    // Execute the future and pass the result
    final historyFuture = fetchNotificationHistory();
    return await _cache.getNotificationHistoryWithFallback(historyFuture);
  }

  @override
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final userId = _getUserId();
      final updateTime = Timestamp.now();

      await _getHistoryCollectionRef(
        userId,
      ).doc(notificationId).update({'isRead': true, 'updatedAt': updateTime});

      final cachedNotification = _cache.historyBox.get(notificationId);
      if (cachedNotification != null) {
        final updatedNotification = cachedNotification.copyWith(
          isRead: true,
          updatedAt: updateTime.toDate(),
        );
        await _cache.historyBox.put(notificationId, updatedNotification);
      }
    } catch (error) {
      AppLogger.error('Error marking notification as read', error: error);
    }
  }

  @override
  Future<void> clearNotificationHistory() async {
    try {
      final userId = _getUserId();
      final collectionRef = _getHistoryCollectionRef(userId);
      final snapshot = await collectionRef.limit(500).get();

      if (snapshot.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      await _cache.historyBox.clear();
      await _cache.setLastSyncTime(DateTime.now());
    } catch (error) {
      AppLogger.error('Error clearing notification history', error: error);
    }
  }

  @override
  Future<int> getUnreadNotificationCount() async {
    try {
      if (await _cache.isCacheValid()) {
        final cachedHistory = _cache.historyBox.values.toList();
        return cachedHistory.where((notif) => !notif.isRead).length;
      }

      final userId = _getUserId();
      final snapshot = await _getHistoryCollectionRef(
        userId,
      ).where('isRead', isEqualTo: false).count().get();

      return snapshot.count ?? 0;
    } catch (error) {
      AppLogger.error('Error getting unread notification count', error: error);
      return 0;
    }
  }
}
