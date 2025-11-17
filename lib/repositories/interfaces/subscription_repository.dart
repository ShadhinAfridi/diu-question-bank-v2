// repositories/interfaces/subscription_repository.dart
import '../../models/subscription_model.dart';

abstract class ISubscriptionRepository {
  // Add userId getter to the interface
  String get userId;

  Future<Subscription?> get(String id);
  Future<List<Subscription>> getAll();
  Future<void> save(Subscription item);
  Future<void> delete(String id);
  Stream<List<Subscription>> watchAll();
  Future<void> syncWithRemote();
  Future<void> clearCache();

  Future<Subscription?> getCurrentSubscription();
  Future<void> activateSubscription(Subscription subscription);
  Future<void> cancelSubscription();
  Future<bool> hasActiveSubscription();
  Future<bool> isPremiumUser();
  Future<int> getDaysRemaining();
  void dispose();
}