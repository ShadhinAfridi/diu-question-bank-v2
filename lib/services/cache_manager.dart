import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class CacheManager with ChangeNotifier {
  final Map<String, DateTime> _lastSyncTimes = {};
  final Map<String, bool> _isSyncing = {};
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _backgroundSyncTimer;

  static const Duration backgroundSyncInterval = Duration(minutes: 15);
  static const Duration cacheValidity = Duration(hours: 1);

  Future<void> initialize() async {
    await _loadSyncTimes();

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _handleConnectivityChange,
    );

    _startBackgroundSync();
  }

  void _startBackgroundSync() {
    _backgroundSyncTimer = Timer.periodic(
      backgroundSyncInterval,
          (_) => _performBackgroundSync(),
    );
  }

  Future<void> _performBackgroundSync() async {
    final connectivity = await _connectivity.checkConnectivity();
    if (!_hasNetworkConnection(connectivity)) {
      debugPrint('No network connection for background sync');
      return;
    }

    debugPrint('Performing background cache sync');
    notifyListeners();
  }

  Future<void> _handleConnectivityChange(List<ConnectivityResult> results) async {
    if (_hasNetworkConnection(results)) {
      debugPrint('Network connectivity restored - triggering cache sync');
      _performBackgroundSync();
    } else {
      debugPrint('Network connectivity lost');
    }
    notifyListeners();
  }

  bool _hasNetworkConnection(List<ConnectivityResult> results) {
    return results.any((result) =>
    result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.ethernet ||
        result == ConnectivityResult.vpn);
  }

  bool isCacheValid(String cacheKey) {
    final lastSync = _lastSyncTimes[cacheKey];
    if (lastSync == null) return false;
    return DateTime.now().difference(lastSync) < cacheValidity;
  }

  bool shouldRefreshCache(String cacheKey) {
    return !isCacheValid(cacheKey);
  }

  Future<void> setLastSyncTime(String cacheKey, DateTime time) async {
    _lastSyncTimes[cacheKey] = time;
    final syncBox = await Hive.openBox('sync_times');
    await syncBox.put(cacheKey, time.millisecondsSinceEpoch);
  }

  Future<void> _loadSyncTimes() async {
    try {
      final syncBox = await Hive.openBox('sync_times');
      final keys = syncBox.keys;

      for (final key in keys) {
        final timestamp = syncBox.get(key) as int?;
        if (timestamp != null) {
          _lastSyncTimes[key.toString()] = DateTime.fromMillisecondsSinceEpoch(timestamp);
        }
      }
    } catch (e) {
      debugPrint('Error loading sync times: $e');
    }
  }

  bool isSyncing(String cacheKey) => _isSyncing[cacheKey] ?? false;

  Future<void> setSyncing(String cacheKey, bool syncing) async {
    _isSyncing[cacheKey] = syncing;
    notifyListeners();
  }

  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return _hasNetworkConnection(results);
  }

  Map<String, dynamic> get cacheStatus {
    return {
      'lastSyncTimes': _lastSyncTimes,
      'isSyncing': _isSyncing,
      'cacheValidityHours': cacheValidity.inHours,
    };
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _backgroundSyncTimer?.cancel();
    super.dispose();
  }
}