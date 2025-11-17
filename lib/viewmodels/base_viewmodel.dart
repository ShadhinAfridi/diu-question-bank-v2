import 'dart:async';
import 'package:flutter/foundation.dart';

/// Base class for all ViewModels providing common functionality
abstract class BaseViewModel extends ChangeNotifier {
  final List<StreamSubscription> _subscriptions = [];
  final List<Timer> _timers = [];
  bool _isDisposed = false;

  /// Add a subscription that will be automatically disposed
  @protected
  void addSubscription(StreamSubscription subscription) {
    if (_isDisposed) {
      subscription.cancel();
      return;
    }
    _subscriptions.add(subscription);
  }

  /// Add a timer that will be automatically cancelled
  @protected
  void addTimer(Timer timer) {
    if (_isDisposed) {
      timer.cancel();
      return;
    }
    _timers.add(timer);
  }

  /// Safe version of notifyListeners that checks if disposed
  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  /// Dispose all resources
  @override
  void dispose() {
    _isDisposed = true;

    for (final subscription in _subscriptions) {
      subscription.cancel();
    }

    for (final timer in _timers) {
      timer.cancel();
    }

    _subscriptions.clear();
    _timers.clear();
    super.dispose();
  }
}

/// Standardized state management for ViewModels
enum ViewModelState { initial, loading, loaded, refreshing, error }

/// Standardized error handling
class ViewModelError {
  final String message;
  final dynamic error;
  final StackTrace? stackTrace;
  final DateTime timestamp;

  ViewModelError({
    required this.message,
    this.error,
    this.stackTrace,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => 'ViewModelError: $message';
}