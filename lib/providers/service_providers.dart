import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';

// REFACTORED: Import repository providers
// --- NOTE: Assuming this file exists in your project ---
import '../providers/repository_providers.dart';

import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/background_sync_service.dart';
import '../services/connectivity_service.dart';
import '../services/notification_service.dart';

// --- NOTE: This file now provides the core cache boxes ---
import 'cache_providers.dart';


// ===== Third Party Services Providers =====

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final connectivityProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});

final flutterLocalNotificationsPluginProvider = Provider<fln.FlutterLocalNotificationsPlugin>((ref) {
  return fln.FlutterLocalNotificationsPlugin();
});

final workmanagerProvider = Provider<Workmanager>((ref) {
  return Workmanager();
});

// ===== Core Services Providers =====

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

final authServiceProvider = Provider<AuthService>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  return AuthService(firebaseAuth);
});

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  final service = ConnectivityService(connectivity);
  // Auto-initialize
  service.initialize();
  ref.onDispose(() => service.dispose());
  return service;
});

// REFACTORED: Removed old cacheManagerProvider

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final notificationsPlugin = ref.watch(flutterLocalNotificationsPluginProvider);
  final service = NotificationService(notificationsPlugin);
  // Auto-initialize
  service.initialize();
  ref.onDispose(() => service.dispose());
  return service;
});

final backgroundSyncServiceProvider = Provider<BackgroundSyncService>((ref) {
  final analyticsService = ref.watch(analyticsServiceProvider);
  final connectivity = ref.watch(connectivityProvider);
  final workmanager = ref.watch(workmanagerProvider);
  final service = BackgroundSyncService(analyticsService, connectivity, workmanager);
  // Auto-initialize
  service.initialize();
  return service;
});

// ===== Service Status Providers =====

final connectivityStatusProvider = StreamProvider<bool>((ref) {
  final connectivityService = ref.watch(connectivityServiceProvider);
  return connectivityService.connectionStream;
});

// REFACTORED: Removed cacheStatusProvider

final notificationPermissionProvider = FutureProvider<NotificationPermissionStatus>((ref) async {
  final notificationService = ref.watch(notificationServiceProvider);
  // --- FIX: Wait for initialization before requesting permissions ---
  await notificationService.initialize();
  return await notificationService.requestPermissions();
});

final backgroundSyncHealthProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final backgroundSyncService = ref.watch(backgroundSyncServiceProvider);
  return await backgroundSyncService.getHealthStatus();
});

// ===== Service Combination Providers =====

// REFACTORED: Simplified networkCacheStatusProvider
final networkStatusProvider = Provider<Map<String, dynamic>>((ref) {
  final connectivityState = ref.watch(connectivityStatusProvider);

  final isConnected = connectivityState.when(
    data: (connected) => connected,
    loading: () => false,
    error: (error, stack) => false,
  );

  return {
    'isConnected': isConnected,
  };
});

final servicesHealthCheckProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final connectivityStatus = await ref.watch(connectivityStatusProvider.future);
  final backgroundSyncHealth = await ref.watch(backgroundSyncHealthProvider.future);
  final notificationPermission = await ref.watch(notificationPermissionProvider.future);

  // REFACTORED: Get cache status directly from repository
  bool isQuestionCacheValid = false;
  try {
    // --- NOTE: This relies on repository_providers.dart ---
    isQuestionCacheValid = await ref.read(questionRepositoryProvider).isCacheValid();
  } catch (e) {
    // Ignore errors (e.g., user not auth'd)
  }

  return {
    'connectivity': {
      'status': connectivityStatus ? 'connected' : 'disconnected',
      'healthy': connectivityStatus,
    },
    'cache': { // REFACTORED: Updated cache health check
      'status': isQuestionCacheValid ? 'valid' : 'stale',
      'healthy': isQuestionCacheValid,
    },
    'backgroundSync': backgroundSyncHealth,
    'notifications': {
      'status': notificationPermission.toString(),
      'healthy': notificationPermission == NotificationPermissionStatus.granted,
    },
    'overallHealthy': connectivityStatus &&
        backgroundSyncHealth['service_status'] == 'active' &&
        notificationPermission == NotificationPermissionStatus.granted,
    'timestamp': DateTime.now().toIso8601String(),
  };
});

// ===== Service Action Providers =====

final triggerBackgroundSyncProvider = FutureProvider.family<void, bool>((ref, manual) async {
  final backgroundSyncService = ref.watch(backgroundSyncServiceProvider);
  final analyticsService = ref.read(analyticsServiceProvider);

  try {
    if (manual) {
      await backgroundSyncService.triggerSync();
      await analyticsService.trackEvent('manual_background_sync_triggered');
    } else {
      await analyticsService.trackEvent('auto_background_sync_triggered');
    }
  } catch (e, stackTrace) {
    await analyticsService.trackError(
      'background_sync_trigger_failed',
      error: e,
      stackTrace: stackTrace,
    );
    rethrow;
  }
});

// REFACTORED: This provider now clears repository caches
final clearCacheProvider = FutureProvider<void>((ref) async {
  final analyticsService = ref.read(analyticsServiceProvider);

  try {
    // REFACTORED: Clear caches at the repository level
    // --- NOTE: This relies on repository_providers.dart ---
    await ref.read(questionRepositoryProvider).clearCache();
    // await ref.read(userRepositoryProvider).clearCache(); // Add for other repos
    // etc.

    // REFACTORED: Also clear the meta box
    await ref.read(metaBoxProvider).clear();

    await analyticsService.trackEvent('cache_cleared');
  } catch (e, stackTrace) {
    await analyticsService.trackError(
      'cache_clear_failed',
      error: e,
      stackTrace: stackTrace,
    );
    rethrow;
  }
});

final cancelAllNotificationsProvider = FutureProvider<void>((ref) async {
  final notificationService = ref.watch(notificationServiceProvider);
  final analyticsService = ref.read(analyticsServiceProvider);

  try {
    await notificationService.cancelAllNotifications();
    await analyticsService.trackEvent('all_notifications_cancelled');
  } catch (e, stackTrace) {
    await analyticsService.trackError(
      'notifications_cancel_failed',
      error: e,
      stackTrace: stackTrace,
    );
    rethrow;
  }
});

// ===== Service Initialization Provider =====

final servicesInitializationProvider = FutureProvider<void>((ref) async {
  // Access services to trigger their initialization
  ref.watch(connectivityServiceProvider);
  ref.watch(notificationServiceProvider);
  ref.watch(backgroundSyncServiceProvider);

  // Wait a moment for services to initialize
  await Future.delayed(const Duration(milliseconds: 100));
});