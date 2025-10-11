import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/notification_model.dart';

/// Enum to represent the current state of the view sections.
enum ViewStatus { loading, success, error }

/// A unified ViewModel to manage both notification lists and settings.
///
/// It centralizes all notification-related logic, ensuring a clear separation
/// of concerns and making the UI code cleaner. It follows a cache-first
/// strategy for a fast and responsive user experience.
class UnifiedNotificationViewModel extends ChangeNotifier {
  // --- Services & Configuration ---
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _notificationsBoxName = 'app_notifications_v2';
  final String _settingsBoxName = 'notification_settings_v2';

  // --- Notifications State ---
  List<AppNotification> _notifications = [];
  ViewStatus _notificationStatus = ViewStatus.loading;
  String _notificationError = '';
  StreamSubscription? _notificationSubscription;

  // --- Settings State ---
  NotificationSettings _settings = NotificationSettings.defaults();
  ViewStatus _settingsStatus = ViewStatus.loading;
  String _settingsError = '';
  bool _isSavingSettings = false;

  // --- Public Getters ---
  List<AppNotification> get notifications => _notifications;
  ViewStatus get notificationStatus => _notificationStatus;
  String get notificationError => _notificationError;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationSettings get settings => _settings;
  ViewStatus get settingsStatus => _settingsStatus;
  String get settingsError => _settingsError;
  bool get isSavingSettings => _isSavingSettings;

  // Expose auth for external access
  FirebaseAuth get auth => _auth;

  // --- Initialization & Lifecycle ---
  UnifiedNotificationViewModel() {
    _init();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    // Listen for auth changes to automatically clear data on logout
    // and re-initialize on login.
    _auth.authStateChanges().listen((user) {
      if (user == null) {
        _clearDataOnLogout();
      } else {
        _initializeDataForUser(user.uid);
      }
    });
  }

  /// Initializes data loading for a specific user.
  Future<void> _initializeDataForUser(String userId) async {
    await _loadNotificationsFromCache(userId);
    _listenForRemoteNotifications(userId);
    await loadSettings(userId);
  }

  /// Retries fetching all data (notifications and settings) for the current user.
  Future<void> refreshData() async {
    final user = _auth.currentUser;
    if (user != null) {
      _setNotificationStatus(ViewStatus.loading);
      _setSettingsStatus(ViewStatus.loading);
      await _initializeDataForUser(user.uid);
    }
  }

  // =======================================================================
  // Section: Notification List Management
  // =======================================================================

  Future<void> _loadNotificationsFromCache(String userId) async {
    _setNotificationStatus(ViewStatus.loading);
    try {
      final box = await Hive.openBox<AppNotification>('${_notificationsBoxName}_$userId');
      _notifications = box.values.toList()
        ..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
      _setNotificationStatus(ViewStatus.success);
    } catch (e) {
      _notificationError = "Failed to load notifications from cache";
      _setNotificationStatus(ViewStatus.error);
    }
  }

  void _listenForRemoteNotifications(String userId) {
    _notificationSubscription?.cancel();
    _notificationSubscription = _firestore
        .collection('users').doc(userId).collection('notifications')
        .orderBy('receivedAt', descending: true)
        .snapshots()
        .listen((snapshot) async {
      try {
        final remoteNotifications = snapshot.docs
            .map((doc) => AppNotification.fromMap(doc.id, doc.data()))
            .toList();
        _notifications = remoteNotifications;
        await _updateNotificationsCache(userId, remoteNotifications);
        _setNotificationStatus(ViewStatus.success);
      } catch (error) {
        _notificationError = "Couldn't process notifications from server.";
        _setNotificationStatus(ViewStatus.error);
      }
    }, onError: (error) {
      _notificationError = "Couldn't connect to get new notifications.";
      _setNotificationStatus(ViewStatus.error);
    });
  }

  Future<void> _updateNotificationsCache(String userId, List<AppNotification> notifications) async {
    try {
      final box = await Hive.openBox<AppNotification>('${_notificationsBoxName}_$userId');
      await box.clear();
      await box.putAll({for (var n in notifications) n.id: n});
    } catch (e) {
      // Cache update failed but we can continue with the data from server
      print("Failed to update notifications cache: $e");
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index].isRead = true;
      notifyListeners(); // Optimistic update
    }

    try {
      await _firestore.collection('users').doc(user.uid).collection('notifications').doc(notificationId).update({'isRead': true});
    } catch (e) {
      // Revert optimistic update on error
      if (index != -1) {
        _notifications[index].isRead = false;
        notifyListeners();
      }
    }
  }

  Future<void> markAllAsRead() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Optimistic update
    for (var n in _notifications) {
      if (!n.isRead) {
        n.isRead = true;
      }
    }
    notifyListeners();

    try {
      final batch = _firestore.batch();
      for (var n in _notifications) {
        if (!n.isRead) {
          final docRef = _firestore.collection('users').doc(user.uid).collection('notifications').doc(n.id);
          batch.update(docRef, {'isRead': true});
        }
      }
      await batch.commit();
    } catch (e) {
      // Revert optimistic update on error
      for (var n in _notifications) {
        n.isRead = false;
      }
      notifyListeners();
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Store the notification in case we need to revert
    final notificationToDelete = _notifications.firstWhere((n) => n.id == notificationId);
    _notifications.removeWhere((n) => n.id == notificationId);
    notifyListeners(); // Optimistic update

    try {
      await _firestore.collection('users').doc(user.uid).collection('notifications').doc(notificationId).delete();
    } catch (e) {
      // Revert optimistic update on error
      _notifications.add(notificationToDelete);
      _notifications.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
      notifyListeners();
    }
  }

  // =======================================================================
  // Section: Notification Settings Management
  // =======================================================================

  Future<void> loadSettings(String userId) async {
    _setSettingsStatus(ViewStatus.loading);

    try {
      // Try to load from cache first
      final box = await Hive.openBox<NotificationSettings>(_settingsBoxName);
      final cachedSettings = box.get(userId);

      if (cachedSettings != null) {
        _settings = cachedSettings;
        _setSettingsStatus(ViewStatus.success);
      }

      // Then try to load from Firestore
      final doc = await _firestore.collection('users').doc(userId).collection('settings').doc('notifications').get();
      if (doc.exists && doc.data() != null) {
        _settings = NotificationSettings.fromMap(doc.data()!);
        await box.put(userId, _settings);
        _setSettingsStatus(ViewStatus.success);
      } else if (cachedSettings == null) {
        // Use defaults if nothing is found
        _settings = NotificationSettings.defaults();
        _setSettingsStatus(ViewStatus.success);
      }
    } catch (e) {
      _settingsError = "Could not fetch settings.";
      _setSettingsStatus(ViewStatus.error);
    } finally {
      notifyListeners();
    }
  }

  Future<void> updateSettingAndSave(void Function(NotificationSettings s) updater) async {
    updater(_settings);
    notifyListeners(); // Immediate UI feedback
    await _saveSettings();
  }

  Future<bool> _saveSettings() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    _isSavingSettings = true;
    notifyListeners();

    try {
      await _firestore.collection('users').doc(user.uid).collection('settings').doc('notifications').set(_settings.toMap());
      final box = await Hive.openBox<NotificationSettings>(_settingsBoxName);
      await box.put(user.uid, _settings);
      return true;
    } catch (e) {
      return false;
    } finally {
      _isSavingSettings = false;
      notifyListeners();
    }
  }

  // =======================================================================
  // Section: User Session & State Management
  // =======================================================================

  Future<void> _clearDataOnLogout() async {
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
    _notifications = [];
    _settings = NotificationSettings.defaults();
    _notificationStatus = ViewStatus.loading;
    _settingsStatus = ViewStatus.loading;
    notifyListeners();
  }

  void _setNotificationStatus(ViewStatus status) {
    _notificationStatus = status;
    notifyListeners();
  }

  void _setSettingsStatus(ViewStatus status) {
    _settingsStatus = status;
    notifyListeners();
  }
}