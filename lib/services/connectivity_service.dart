import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService with ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  List<ConnectivityResult> _currentStatus = [ConnectivityResult.none];
  bool _isConnected = false;

  List<ConnectivityResult> get currentStatus => _currentStatus;
  bool get isConnected => _isConnected;

  ConnectivityService() {
    _init();
  }

  Future<void> _init() async {
    try {
      _currentStatus = await _connectivity.checkConnectivity();
      _updateConnectionStatus();

      _subscription = _connectivity.onConnectivityChanged.listen((results) {
        _currentStatus = results;
        _updateConnectionStatus();
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Connectivity service error: $e');
    }
  }

  void _updateConnectionStatus() {
    final wasConnected = _isConnected;
    _isConnected = _currentStatus.any((result) =>
    result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.ethernet ||
        result == ConnectivityResult.vpn);

    if (wasConnected != _isConnected) {
      debugPrint('Connection status changed: $_isConnected');
    }
  }

  bool hasConnectionType(ConnectivityResult type) {
    return _currentStatus.contains(type);
  }

  String get connectionDescription {
    if (_currentStatus.isEmpty) return 'No connection';

    final types = _currentStatus.map((result) {
      switch (result) {
        case ConnectivityResult.wifi: return 'WiFi';
        case ConnectivityResult.mobile: return 'Mobile';
        case ConnectivityResult.ethernet: return 'Ethernet';
        case ConnectivityResult.vpn: return 'VPN';
        case ConnectivityResult.bluetooth: return 'Bluetooth';
        case ConnectivityResult.other: return 'Other';
        default: return 'None';
      }
    }).toList();

    return types.join(', ');
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}