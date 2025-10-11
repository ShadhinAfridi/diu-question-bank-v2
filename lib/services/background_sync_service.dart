// services/background_sync_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class BackgroundSyncService {
  static const String syncTask = "backgroundSync";

  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );

    // Register periodic background task
    await Workmanager().registerPeriodicTask(
      syncTask,
      syncTask,
      frequency: const Duration(hours: 1),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  @pragma('vm:entry-point')
  static void callbackDispatcher() {
    Workmanager().executeTask((task, inputData) async {
      final connectivity = Connectivity();
      final results = await connectivity.checkConnectivity();

      final hasConnection = results.any((result) =>
      result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.ethernet ||
          result == ConnectivityResult.vpn);

      if (!hasConnection) return false;

      try {
        debugPrint('Background sync started for task: $task');

        // Perform your background sync operations here
        // Example: await QuestionCacheRepository().syncWithRemote();

        debugPrint('Background sync completed successfully');
        return true;
      } catch (e) {
        debugPrint('Background sync failed: $e');
        return false;
      }
    });
  }

  // Manual trigger for background sync
  static Future<void> triggerSync() async {
    await Workmanager().registerOneOffTask(
      "manualSync",
      syncTask,
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }
}