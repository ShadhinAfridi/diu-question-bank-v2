// viewmodels/notifications_viewmodel.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logger/app_logger.dart';
import '../models/notification_model.dart';
import '../models/task_model.dart';
import '../repositories/interfaces/notification_repository.dart';
import '../repositories/interfaces/user_repository.dart';
import '../services/notification_service.dart';
import '../utils/view_status.dart';
import 'base_viewmodel.dart';
import '../providers/repository_providers.dart';
import '../providers/service_providers.dart';

class NotificationsViewModel extends BaseViewModel {
  final NotificationService _notificationService;
  final IUserRepository _userRepository;
  final INotificationRepository _notificationRepository;

  ViewStatus _notificationStatus = ViewStatus.loading;
  ViewStatus _settingsStatus = ViewStatus.loading;
  String _notificationError = '';
  String _settingsError = '';
  bool _isSavingSettings = false;
  bool _isTestingNotification = false;
  bool _isLoadingHistory = false;
  NotificationSettings _settings = NotificationSettings.defaults();
  List<AppNotification> _notificationHistory = [];
  int _unreadCount = 0;

  // Getters
  ViewStatus get notificationStatus => _notificationStatus;
  ViewStatus get settingsStatus => _settingsStatus;
  String get notificationError => _notificationError;
  String get settingsError => _settingsError;
  bool get isSavingSettings => _isSavingSettings;
  bool get isTestingNotification => _isTestingNotification;
  bool get isLoadingHistory => _isLoadingHistory;
  NotificationSettings get settings => _settings;
  List<AppNotification> get notificationHistory => _notificationHistory;
  int get unreadCount => _unreadCount;

  NotificationsViewModel(Ref ref)
      : _notificationService = ref.read(notificationServiceProvider),
        _userRepository = ref.read(userRepositoryProvider),
        _notificationRepository = ref.read(notificationRepositoryProvider) {
    _initialize();
  }

  Future<void> _initialize() async {
    _setNotificationStatus(ViewStatus.loading);
    AppLogger.debug(
      'Initializing NotificationsViewModel',
      tag: 'NOTIFICATIONS_VIEWMODEL',
    );

    try {
      await _notificationService.initialize();
      await _loadSettings();
      await _loadNotificationHistory();
      await _loadUnreadCount();
      _setNotificationStatus(ViewStatus.success);
      AppLogger.debug(
        'NotificationsViewModel initialized successfully',
        tag: 'NOTIFICATIONS_VIEWMODEL',
      );
    } catch (e) {
      _notificationError = "Failed to initialize notifications: $e";
      _setNotificationStatus(ViewStatus.error);
      AppLogger.error(
        'Failed to initialize NotificationsViewModel',
        tag: 'NOTIFICATIONS_VIEWMODEL',
        error: e,
      );
    }
  }

  Future<void> _loadSettings() async {
    _setSettingsStatus(ViewStatus.loading);
    _settingsError = '';
    try {
      _settings = await _notificationRepository.loadUserSettings();
      _setSettingsStatus(ViewStatus.success);
    } catch (e) {
      _settingsError = "Could not load notification settings: $e";
      _setSettingsStatus(ViewStatus.error);
    }
  }

  Future<void> _loadNotificationHistory() async {
    _isLoadingHistory = true;
    notifyListeners();
    try {
      _notificationHistory = await _notificationRepository.getNotificationHistory();
    } catch (e) {
      AppLogger.error('Error loading notification history', error: e);
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      _unreadCount = await _notificationRepository.getUnreadNotificationCount();
      notifyListeners();
    } catch (e) {
      AppLogger.error('Error loading unread count', error: e);
    }
  }

  Future<void> updateSettings(NotificationSettings newSettings) async {
    _isSavingSettings = true;
    notifyListeners();
    try {
      _settings = newSettings;
      await _notificationService.updateSettings(newSettings);
      _setSettingsStatus(ViewStatus.success);
    } catch (e) {
      _settingsError = "Failed to update settings: $e";
      _setSettingsStatus(ViewStatus.error);
    } finally {
      _isSavingSettings = false;
      notifyListeners();
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final index = _notificationHistory.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notificationHistory[index] = _notificationHistory[index].copyWith(isRead: true);
        await _notificationRepository.markNotificationAsRead(notificationId);
        await _loadUnreadCount();
        notifyListeners();
      }
    } catch (e) {
      AppLogger.error('Error marking notification as read', error: e);
    }
  }

  void _setNotificationStatus(ViewStatus status) {
    _notificationStatus = status;
    notifyListeners();
  }

  void _setSettingsStatus(ViewStatus status) {
    _settingsStatus = status;
    notifyListeners();
  }

  @override
  void dispose() {
    _notificationService.dispose();
    super.dispose();
  }
}