// providers/notification_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification_model.dart';
import '../utils/view_status.dart';
import '../viewmodels/notifications_viewmodel.dart';
import 'view_model_providers.dart'; // Import the main view model providers

// Real-time notification list provider
final notificationHistoryProvider = Provider<List<AppNotification>>((ref) {
  // Use .select to only rebuild when this specific list changes
  return ref.watch(notificationsViewModelProvider.select(
        (vm) => vm.notificationHistory,
  ));
});

// Unread count provider
final unreadNotificationsCountProvider = Provider<int>((ref) {
  // Use .select to only rebuild when the unread count changes
  return ref.watch(notificationsViewModelProvider.select(
        (vm) => vm.unreadCount,
  ));
});

// Notification settings provider
final notificationSettingsProvider = Provider<NotificationSettings>((ref) {
  // Use .select to only rebuild when the settings object changes
  return ref.watch(notificationsViewModelProvider.select(
        (vm) => vm.settings,
  ));
});

// Loading states
final notificationsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(notificationsViewModelProvider.select(
        (vm) => vm.notificationStatus == ViewStatus.loading,
  ));
});

// Settings loading state
final notificationSettingsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(notificationsViewModelProvider.select(
        (vm) => vm.settingsStatus == ViewStatus.loading,
  ));
});