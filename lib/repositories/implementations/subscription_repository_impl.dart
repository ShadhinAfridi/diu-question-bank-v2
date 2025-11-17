// repositories/implementations/subscription_repository_impl.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/subscription_model.dart';
import '../../providers/cache_providers.dart';
import '../interfaces/subscription_repository.dart';

class SubscriptionRepositoryImpl implements ISubscriptionRepository {
  final FirebaseFirestore _firestore;
  final SubscriptionRepositoryCache _cache;

  @override
  final String userId;

  SubscriptionRepositoryImpl({
    required FirebaseFirestore firestore,
    required SubscriptionRepositoryCache cache,
    required this.userId,
  }) : _firestore = firestore,
       _cache = cache;

  @override
  Future<Subscription?> get(String id) async {
    try {
      final cached = _cache.subscriptionBox.get(id);
      if (cached != null && await _cache.isCacheValid()) {
        return cached;
      }

      final doc = await _firestore.collection('subscriptions').doc(id).get();

      if (doc.exists && doc.data() != null) {
        final subscription = Subscription.fromMap(doc.data()!);
        await _cache.subscriptionBox.put(id, subscription);
        await _cache.setLastSyncTime(DateTime.now());
        return subscription;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting subscription $id: $e');
      return _cache.subscriptionBox.get(id);
    }
  }

  @override
  Future<List<Subscription>> getAll() async {
    try {
      final cachedSubscriptions = _cache.subscriptionBox.values.toList();
      if (cachedSubscriptions.isNotEmpty && await _cache.isCacheValid()) {
        return cachedSubscriptions;
      }

      return await _loadSubscriptionsFromFirestore();
    } catch (e) {
      debugPrint('Error getting all subscriptions: $e');
      return _cache.subscriptionBox.values.toList();
    }
  }

  @override
  Future<void> save(Subscription item) async {
    try {
      await _firestore
          .collection('subscriptions')
          .doc(userId)
          .set(item.toMap());
      await _cache.subscriptionBox.put(userId, item);
      await _cache.setLastSyncTime(DateTime.now());
    } catch (e) {
      debugPrint('Error saving subscription: $e');
      rethrow;
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _firestore.collection('subscriptions').doc(id).delete();
      await _cache.subscriptionBox.delete(id);
      await _cache.setLastSyncTime(DateTime.now());
    } catch (e) {
      debugPrint('Error deleting subscription: $e');
      rethrow;
    }
  }

  @override
  Stream<List<Subscription>> watchAll() {
    return _cache.subscriptionBox.watch().map(
      (event) => _cache.subscriptionBox.values.toList(),
    );
  }

  @override
  Future<void> syncWithRemote() async {
    try {
      await _loadSubscriptionsFromFirestore();
    } catch (e) {
      debugPrint('Error syncing subscriptions: $e');
      rethrow;
    }
  }

  @override
  Future<void> clearCache() async {
    await _cache.subscriptionBox.clear();
    await _cache.clearCache();
  }

  @override
  Future<Subscription?> getCurrentSubscription() async {
    // Create the future first
    Future<Subscription?> fetchSubscription() async {
      final doc = await _firestore
          .collection('subscriptions')
          .doc(userId)
          .get();

      if (doc.exists && doc.data() != null) {
        final subscription = Subscription.fromMap(doc.data()!);
        await _cache.subscriptionBox.put(userId, subscription);
        return subscription;
      }

      // Return free subscription if none exists
      return Subscription.free();
    }

    // Execute the future and pass the result
    final subscriptionFuture = fetchSubscription();
    return await _cache.getCurrentSubscriptionWithFallback(
      userId,
      subscriptionFuture,
    );
  }

  @override
  Future<void> activateSubscription(Subscription subscription) async {
    try {
      final activeSubscription = Subscription(
        isActive: true,
        planType: subscription.planType,
        expiryDate: subscription.expiryDate,
        purchaseDate: subscription.purchaseDate,
        transactionId: subscription.transactionId,
        originalTransactionId: subscription.originalTransactionId,
        paymentProvider: subscription.paymentProvider,
        entitlements: subscription.entitlements,
      );
      await save(activeSubscription);
    } catch (e) {
      debugPrint('Error activating subscription: $e');
      rethrow;
    }
  }

  @override
  Future<void> cancelSubscription() async {
    try {
      final current = await getCurrentSubscription();
      if (current != null) {
        final cancelled = Subscription(
          isActive: false,
          planType: current.planType,
          expiryDate: current.expiryDate,
          purchaseDate: current.purchaseDate,
          transactionId: current.transactionId,
          originalTransactionId: current.originalTransactionId,
          paymentProvider: current.paymentProvider,
          entitlements: current.entitlements,
        );
        await save(cancelled);
      }
    } catch (e) {
      debugPrint('Error cancelling subscription: $e');
      rethrow;
    }
  }

  @override
  Future<bool> hasActiveSubscription() async {
    // Create the future first
    Future<bool> checkActiveSubscription() async {
      final subscription = await getCurrentSubscription();
      return subscription?.isValid ?? false;
    }

    // Execute the future and pass the result
    final checkFuture = checkActiveSubscription();
    return await _cache.hasActiveSubscriptionWithFallback(userId, checkFuture);
  }

  @override
  Future<bool> isPremiumUser() async {
    return await hasActiveSubscription();
  }

  @override
  Future<int> getDaysRemaining() async {
    final subscription = await getCurrentSubscription();
    return subscription?.daysRemaining ?? 0;
  }

  @override
  void dispose() {
    _cache.subscriptionBox.close();
  }

  // ============ PRIVATE METHODS ============

  Future<List<Subscription>> _loadSubscriptionsFromFirestore() async {
    final querySnapshot = await _firestore
        .collection('subscriptions')
        .where('userId', isEqualTo: userId)
        .get();

    final subscriptions = querySnapshot.docs
        .map((doc) => Subscription.fromMap(doc.data()))
        .toList();

    final subscriptionsMap = {
      for (var s in subscriptions)
        s.transactionId ?? s.purchaseDate.millisecondsSinceEpoch.toString(): s,
    };
    await _cache.subscriptionBox.putAll(subscriptionsMap);
    await _cache.setLastSyncTime(DateTime.now());

    return subscriptions;
  }
}
