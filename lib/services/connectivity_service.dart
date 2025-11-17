import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService with ChangeNotifier {
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  List<ConnectivityResult> _currentStatus = [ConnectivityResult.none];
  bool _isInitialized = false;

  ConnectivityService(this._connectivity);

  List<ConnectivityResult> get currentStatus => _currentStatus;
  bool get isInitialized => _isInitialized;

  bool get isConnected {
    return _currentStatus.any((status) =>
    status == ConnectivityResult.wifi ||
        status == ConnectivityResult.mobile ||
        status == ConnectivityResult.ethernet);
  }

  Stream<bool> get connectionStream {
    return _connectivity.onConnectivityChanged.map((results) {
      return results.any((status) =>
      status == ConnectivityResult.wifi ||
          status == ConnectivityResult.mobile ||
          status == ConnectivityResult.ethernet);
    });
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Get initial status
    _currentStatus = await _connectivity.checkConnectivity();

    // Listen for changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
      _currentStatus = results;
      notifyListeners();
      debugPrint('Connectivity changed: $results');
    });

    _isInitialized = true;
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}