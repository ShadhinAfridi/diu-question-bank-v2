// subscription_viewmodel.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/repository_providers.dart';
import '../repositories/interfaces/subscription_repository.dart';
import '../models/subscription_model.dart';
import 'base_viewmodel.dart';

class SubscriptionViewModel extends BaseViewModel {
  final ISubscriptionRepository _subscriptionRepository;

  Subscription? _currentSubscription;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isProcessing = false;

  Subscription? get currentSubscription => _currentSubscription;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isProcessing => _isProcessing;
  bool get hasActiveSubscription => _currentSubscription?.isValid ?? false;
  int get daysRemaining => _currentSubscription?.daysRemaining ?? 0;

  // Public constructor for Provider
  SubscriptionViewModel(Ref ref)
      : _subscriptionRepository = ref.watch(subscriptionRepositoryProvider) {
    debugPrint('SubscriptionViewModel: Public constructor called');
    _initialize();
  }

  // Internal constructor for dependency injection
  SubscriptionViewModel._internal(Ref ref, this._subscriptionRepository) {
    debugPrint('SubscriptionViewModel: Internal constructor called');
    _initialize();
  }

  void _initialize() {
    if (_subscriptionRepository.userId.isNotEmpty) {
      loadSubscription();
    } else {
      _setErrorState('Please sign in to view subscriptions');
    }
  }

  // FIXED: Define the _setErrorState method
  void _setErrorState(String message) {
    _errorMessage = message;
    _isLoading = false;
    _currentSubscription = Subscription.free();
    notifyListeners();
  }

  Future<void> loadSubscription() async {
    // Don't load if we're already in an error state for unauthenticated user
    if (_errorMessage?.contains('Please sign in') == true) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentSubscription = await _subscriptionRepository.getCurrentSubscription();
      debugPrint('SubscriptionViewModel: Loaded subscription - isValid: ${_currentSubscription?.isValid}');
    } catch (e) {
      _errorMessage = "Failed to load subscription: ${e.toString()}";
      debugPrint('SubscriptionViewModel: Error loading subscription: $e');
      // Set to free subscription on error
      _currentSubscription = Subscription.free();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> activateSubscription(Subscription subscription) async {
    if (_subscriptionRepository.userId.isEmpty) {
      _setErrorState('Please sign in to activate subscription');
      return;
    }

    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _subscriptionRepository.activateSubscription(subscription);
      await loadSubscription(); // Reload
    } catch (e) {
      _errorMessage = "Failed to activate subscription: ${e.toString()}";
      debugPrint('SubscriptionViewModel: Error activating subscription: $e');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<void> cancelSubscription() async {
    if (_subscriptionRepository.userId.isEmpty) {
      _setErrorState('Please sign in to cancel subscription');
      return;
    }

    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _subscriptionRepository.cancelSubscription();
      await loadSubscription(); // Reload
    } catch (e) {
      _errorMessage = "Failed to cancel subscription: ${e.toString()}";
      debugPrint('SubscriptionViewModel: Error cancelling subscription: $e');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<bool> isPremiumUser() async {
    if (_subscriptionRepository.userId.isEmpty) {
      return false;
    }

    return await _subscriptionRepository.isPremiumUser();
  }

  Future<void> refreshSubscription() async {
    if (_subscriptionRepository.userId.isEmpty) {
      _setErrorState('Please sign in to refresh subscription');
      return;
    }

    try {
      await _subscriptionRepository.syncWithRemote();
      await loadSubscription();
    } catch (e) {
      _errorMessage = "Failed to refresh subscription: ${e.toString()}";
      notifyListeners();
      rethrow;
    }
  }

  // Clear error state
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}