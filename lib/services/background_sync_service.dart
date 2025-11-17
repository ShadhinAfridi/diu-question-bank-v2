// background_sync_service.dart
import 'dart:async';
import 'package:workmanager/workmanager.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../logger/app_logger.dart';
import 'analytics_service.dart';

class BackgroundSyncService {
  final String syncTask = "backgroundSync";
  bool _isInitialized = false;

  // Dependencies
  final AnalyticsService _analyticsService;
  final Connectivity _connectivity;
  final Workmanager _workmanager;

  // Retry configuration
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 5);
  static const Duration _backgroundSyncInterval = Duration(hours: 1);

  BackgroundSyncService(
      this._analyticsService,
      this._connectivity,
      this._workmanager,
      );

  Future<void> initialize() async {
    if (_isInitialized) return;

    AppLogger.debug('Initializing background sync service');

    try {
      await _workmanager.initialize(callbackDispatcher, isInDebugMode: false);

      await _workmanager.registerPeriodicTask(
        syncTask,
        syncTask,
        frequency: _backgroundSyncInterval,
        constraints: Constraints(networkType: NetworkType.connected),
      );

      _isInitialized = true;
      AppLogger.info('Background sync service initialized successfully');

      await _analyticsService.trackEvent('background_sync_initialized');
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to initialize background sync service',
        tag: 'BACKGROUND_SYNC',
        error: e,
        stackTrace: stackTrace,
      );
      await _analyticsService.trackError(
        'background_sync_init_failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> triggerSync() async {
    if (!_isInitialized) {
      await initialize();
    }
    AppLogger.debug('Manual background sync triggered', tag: 'BACKGROUND_SYNC');
    await _analyticsService.trackEvent('manual_background_sync_triggered');
    try {
      await _workmanager.registerOneOffTask(
        "manualSync",
        syncTask,
        constraints: Constraints(networkType: NetworkType.connected),
      );
      AppLogger.info(
        'Manual background sync scheduled successfully',
        tag: 'BACKGROUND_SYNC',
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to schedule manual background sync',
        tag: 'BACKGROUND_SYNC',
        error: e,
        stackTrace: stackTrace,
      );
      await _analyticsService.trackError(
        'manual_sync_schedule_failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> cancelAllTasks() async {
    try {
      await _workmanager.cancelAll();
      AppLogger.info('All background tasks cancelled', tag: 'BACKGROUND_SYNC');
      await _analyticsService.trackEvent('background_tasks_cancelled');
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error cancelling background tasks',
        tag: 'BACKGROUND_SYNC',
        error: e,
        stackTrace: stackTrace,
      );
      await _analyticsService.trackError(
        'background_tasks_cancel_failed',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<Map<String, dynamic>> getHealthStatus() async {
    try {
      final isInitialized = _isInitialized;
      final hasNetwork = await _checkConnectivity();
      return {
        'is_initialized': isInitialized,
        'has_network': hasNetwork,
        'service_status': isInitialized ? 'active' : 'inactive',
        'last_sync_attempt': DateTime.now().toIso8601String(),
      };
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error getting background sync health status',
        tag: 'BACKGROUND_SYNC',
        error: e,
        stackTrace: stackTrace,
      );
      return {
        'is_initialized': _isInitialized,
        'has_network': false,
        'service_status': 'error',
        'error': e.toString(),
      };
    }
  }

  Future<bool> _checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.any(
            (result) =>
        result == ConnectivityResult.wifi ||
            result == ConnectivityResult.mobile ||
            result == ConnectivityResult.ethernet ||
            result == ConnectivityResult.vpn,
      );
    } catch (e) {
      AppLogger.error(
        'Error checking connectivity',
        tag: 'BACKGROUND_SYNC',
        error: e,
      );
      return false;
    }
  }

  // --- Static methods for Workmanager callback ---

  @pragma('vm:entry-point')
  static void callbackDispatcher() {
    Workmanager().executeTask((task, inputData) async {
      AppLogger.debug('Background task started: $task', tag: 'BACKGROUND_SYNC');

      // Note: In background isolate, we cannot use Riverpod providers
      // You'll need to initialize dependencies differently for background tasks
      final analyticsService = AnalyticsService();
      final connectivity = Connectivity();

      try {
        final results = await connectivity.checkConnectivity();
        final hasConnection = results.any(
              (result) =>
          result == ConnectivityResult.wifi ||
              result == ConnectivityResult.mobile ||
              result == ConnectivityResult.ethernet ||
              result == ConnectivityResult.vpn,
        );

        if (!hasConnection) {
          AppLogger.warning(
            'No network connection for background sync',
            tag: 'BACKGROUND_SYNC',
          );
          return false;
        }

        final success = await _performBackgroundSyncWithRetry(analyticsService);

        if (success) {
          AppLogger.info(
            'Background sync completed successfully',
            tag: 'BACKGROUND_SYNC',
          );
          await analyticsService.trackEvent('background_sync_completed');
          return true;
        } else {
          AppLogger.error(
            'Background sync failed after retries',
            tag: 'BACKGROUND_SYNC',
          );
          await analyticsService.trackError(
            'background_sync_failed',
            error: 'All retry attempts failed',
            stackTrace: StackTrace.current,
          );
          return false;
        }
      } catch (e, stackTrace) {
        AppLogger.error(
          'Background sync task failed',
          tag: 'BACKGROUND_SYNC',
          error: e,
          stackTrace: stackTrace,
        );
        await analyticsService.trackError(
          'background_sync_task_failed',
          error: e,
          stackTrace: stackTrace,
        );
        return false;
      }
    });
  }

  static Future<bool> _performBackgroundSyncWithRetry(
      AnalyticsService analyticsService,
      ) async {
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        AppLogger.debug(
          'Background sync attempt $attempt/$_maxRetries',
          tag: 'BACKGROUND_SYNC',
        );

        await _performBackgroundSyncOperations(analyticsService);

        AppLogger.debug(
          'Background sync attempt $attempt succeeded',
          tag: 'BACKGROUND_SYNC',
        );
        return true;
      } catch (e, stackTrace) {
        AppLogger.error(
          'Background sync attempt $attempt failed',
          tag: 'BACKGROUND_SYNC',
          error: e,
          stackTrace: stackTrace,
        );
        if (attempt < _maxRetries) {
          AppLogger.debug(
            'Retrying background sync in ${_retryDelay.inSeconds} seconds',
            tag: 'BACKGROUND_SYNC',
          );
          await Future.delayed(_retryDelay * attempt);
        }
      }
    }
    return false;
  }

  static Future<void> _performBackgroundSyncOperations(
      AnalyticsService analyticsService,
      ) async {
    final stopwatch = Stopwatch()..start();
    try {
      AppLogger.debug(
        'Performing background sync operations...',
        tag: 'BACKGROUND_SYNC',
      );

      // Note: In background isolate, repository access is limited
      // You might need to use direct Firestore calls or a different approach
      // For now, we'll simulate sync operations
      await Future.delayed(const Duration(seconds: 2)); // Simulate sync

      AppLogger.performance(
        'Background sync operations completed',
        tag: 'BACKGROUND_SYNC',
        executionTimeMs: stopwatch.elapsedMilliseconds,
      );
      await analyticsService.trackPerformance(
        'background_sync_ops',
        stopwatch.elapsedMilliseconds,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error in background sync operations',
        tag: 'BACKGROUND_SYNC',
        error: e,
        stackTrace: stackTrace,
      );
      await analyticsService.trackError(
        'background_sync_ops_failed',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}

