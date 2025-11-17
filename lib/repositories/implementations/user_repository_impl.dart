// repositories/implementations/user_repository_impl.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diuquestionbank/logger/app_logger.dart';
import 'package:diuquestionbank/models/base_model.dart';
import 'package:diuquestionbank/models/subscription_model.dart';
import 'package:diuquestionbank/models/user_model.dart';
import 'package:diuquestionbank/providers/cache_providers.dart';

import '../interfaces/user_repository.dart';

class UserRepositoryImpl implements IUserRepository {
  final FirebaseFirestore _firestore;
  final UserRepositoryCache _cache;

  static const String _logTag = 'USER_REPOSITORY';
  StreamSubscription<QuerySnapshot>? _firestoreSubscription;

  UserRepositoryImpl({
    required FirebaseFirestore firestore,
    required UserRepositoryCache cache,
  }) : _firestore = firestore,
       _cache = cache;

  @override
  Future<UserModel?> get(String id) async {
    try {
      AppLogger.debug('Getting user $id', tag: _logTag);

      // Create the future first
      Future<UserModel?> fetchUser() async {
        final doc = await _firestore.collection('users').doc(id).get();
        if (doc.exists) {
          final user = UserModel.fromFirestore(doc);
          await _cache.userBox.put(id, user);
          await _cache.setLastSyncTime(DateTime.now());
          AppLogger.debug('Fetched user $id from Firestore', tag: _logTag);
          return user;
        }
        AppLogger.debug('User $id not found in Firestore', tag: _logTag);
        return null;
      }

      // Execute the future and pass the result
      final userFuture = fetchUser();
      return await _cache.getUserWithFallback(id, userFuture);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error getting user $id',
        tag: _logTag,
        error: e,
        stackTrace: stackTrace,
      );

      // Fallback to cache
      final cached = _cache.userBox.get(id);
      if (cached != null) {
        AppLogger.debug('Using cached fallback for user $id', tag: _logTag);
      }
      return cached;
    }
  }

  @override
  Future<List<UserModel>> getAll() async {
    try {
      AppLogger.debug('Getting all users', tag: _logTag);

      final cachedUsers = _cache.userBox.values.toList();
      if (cachedUsers.isNotEmpty && await _cache.isCacheValid()) {
        AppLogger.debug(
          'Using ${cachedUsers.length} cached users',
          tag: _logTag,
        );
        return cachedUsers;
      }

      AppLogger.debug('Cache invalid, loading from Firestore', tag: _logTag);
      return await _loadUsersFromFirestore();
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error getting all users',
        tag: _logTag,
        error: e,
        stackTrace: stackTrace,
      );

      final cachedUsers = _cache.userBox.values.toList();
      AppLogger.debug(
        'Using ${cachedUsers.length} cached users as fallback',
        tag: _logTag,
      );
      return cachedUsers;
    }
  }

  @override
  Future<void> save(UserModel user) async {
    try {
      AppLogger.debug('Saving user ${user.id}', tag: _logTag);

      final updatedUser = user.copyWith(
        updatedAt: DateTime.now(),
        version: user.version + 1,
        syncStatus: SyncStatus.pending,
      );

      // Save to Firestore
      await _firestore
          .collection('users')
          .doc(user.id)
          .set(updatedUser.toFirestore());

      // Update cache with synced status
      final syncedUser = updatedUser.copyWith(syncStatus: SyncStatus.synced);
      await _cache.userBox.put(user.id, syncedUser);
      await _cache.setLastSyncTime(DateTime.now());

      AppLogger.debug('User saved successfully: ${user.email}', tag: _logTag);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error saving user',
        tag: _logTag,
        error: e,
        stackTrace: stackTrace,
      );

      // Save to cache with pending status for offline support
      final offlineUser = user.copyWith(
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.pending,
      );
      await _cache.userBox.put(user.id, offlineUser);

      rethrow;
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      AppLogger.debug('Deleting user $id', tag: _logTag);

      await _firestore.collection('users').doc(id).delete();
      await _cache.userBox.delete(id);
      await _cache.setLastSyncTime(DateTime.now());

      AppLogger.debug('User deleted successfully: $id', tag: _logTag);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error deleting user',
        tag: _logTag,
        error: e,
        stackTrace: stackTrace,
      );

      // Mark as pending delete in cache
      final cachedUser = _cache.userBox.get(id);
      if (cachedUser != null) {
        final deletedUser = cachedUser.copyWith(
          syncStatus: SyncStatus.pendingDelete,
          updatedAt: DateTime.now(),
        );
        await _cache.userBox.put(id, deletedUser);
      }

      rethrow;
    }
  }

  @override
  Stream<List<UserModel>> watchAll() {
    return _cache.userBox.watch().map(
      (event) => _cache.userBox.values.toList(),
    );
  }

  @override
  Future<void> syncWithRemote() async {
    try {
      AppLogger.debug('Starting user sync with remote', tag: _logTag);
      await _loadUsersFromFirestore();

      // Start real-time listener if not already started
      if (_firestoreSubscription == null) {
        await _startRealTimeListener();
      }

      AppLogger.debug('User sync completed successfully', tag: _logTag);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error syncing users',
        tag: _logTag,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await _cache.userBox.clear();
      await _cache.clearCache();
      AppLogger.debug('User cache cleared successfully', tag: _logTag);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error clearing user cache',
        tag: _logTag,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // ============ EFFICIENT UPDATE METHODS ============

  @override
  Future<void> updateUserPoints(String userId, int newPoints) async {
    try {
      AppLogger.debug(
        'Updating points for $userId to $newPoints',
        tag: _logTag,
      );

      // Update Firestore
      await _firestore.collection('users').doc(userId).update({
        'points': newPoints,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update cache
      final cachedUser = _cache.userBox.get(userId);
      if (cachedUser != null) {
        final updatedUser = cachedUser.copyWith(points: newPoints);
        await _cache.updateUserInCache(updatedUser);
      }

      AppLogger.debug('Points updated successfully', tag: _logTag);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error updating user points for $userId',
        tag: _logTag,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> addPoints(String userId, int pointsToAdd) async {
    try {
      AppLogger.debug('Adding $pointsToAdd points to $userId', tag: _logTag);

      // Update Firestore
      await _firestore.collection('users').doc(userId).update({
        'points': FieldValue.increment(pointsToAdd),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update cache
      final cachedUser = _cache.userBox.get(userId);
      if (cachedUser != null) {
        final updatedUser = cachedUser.addPoints(pointsToAdd);
        await _cache.updateUserInCache(updatedUser);
      }

      AppLogger.debug('Points added successfully', tag: _logTag);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error adding user points for $userId',
        tag: _logTag,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> addUploadedQuestion(String userId, String questionId) async {
    try {
      AppLogger.debug(
        'Adding uploaded question $questionId to $userId',
        tag: _logTag,
      );

      // Check cache first to avoid unnecessary writes
      final cachedUser = _cache.userBox.get(userId);
      if (cachedUser != null && cachedUser.hasUploadedQuestion(questionId)) {
        AppLogger.debug('Question already uploaded, skipping', tag: _logTag);
        return;
      }

      // Update Firestore
      await _firestore.collection('users').doc(userId).update({
        'uploadedQuestions': FieldValue.arrayUnion([questionId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update cache
      if (cachedUser != null) {
        final updatedUser = cachedUser.addUploadedQuestion(questionId);
        await _cache.updateUserInCache(updatedUser);
      }

      AppLogger.debug('Uploaded question added successfully', tag: _logTag);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error adding uploaded question for $userId',
        tag: _logTag,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> addAccessedQuestion(String userId, String questionId) async {
    try {
      AppLogger.debug(
        'Adding accessed question $questionId to $userId',
        tag: _logTag,
      );

      // Check cache first
      final cachedUser = _cache.userBox.get(userId);
      if (cachedUser != null && cachedUser.hasAccessedQuestion(questionId)) {
        AppLogger.debug('Question already accessed, skipping', tag: _logTag);
        return;
      }

      // Update Firestore
      await _firestore.collection('users').doc(userId).update({
        'accessedQuestions': FieldValue.arrayUnion([questionId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update cache
      if (cachedUser != null) {
        final updatedUser = cachedUser.addAccessedQuestion(questionId);
        await _cache.updateUserInCache(updatedUser);
      }

      AppLogger.debug('Accessed question added successfully', tag: _logTag);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error adding accessed question for $userId',
        tag: _logTag,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> incrementAdsWatched(String userId) async {
    try {
      AppLogger.debug('Incrementing ads watched for $userId', tag: _logTag);

      // Update Firestore
      await _firestore.collection('users').doc(userId).update({
        'totalAdsWatched': FieldValue.increment(1),
        'points': FieldValue.increment(5),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update cache
      final cachedUser = _cache.userBox.get(userId);
      if (cachedUser != null) {
        final updatedUser = cachedUser
            .copyWith(totalAdsWatched: cachedUser.totalAdsWatched + 1)
            .addPoints(5);
        await _cache.updateUserInCache(updatedUser);
      }

      AppLogger.debug('Ads watched incremented successfully', tag: _logTag);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error incrementing ads watched for $userId',
        tag: _logTag,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> updateSubscription(
    String userId,
    Subscription subscription,
  ) async {
    try {
      AppLogger.debug('Updating subscription for $userId', tag: _logTag);

      // Update Firestore
      await _firestore.collection('users').doc(userId).update({
        'subscription': subscription.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update cache
      final cachedUser = _cache.userBox.get(userId);
      if (cachedUser != null) {
        final updatedUser = cachedUser.updateSubscription(subscription);
        await _cache.updateUserInCache(updatedUser);
      }

      AppLogger.debug('Subscription updated successfully', tag: _logTag);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error updating subscription for $userId',
        tag: _logTag,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> updatePreferences(
    String userId,
    Map<String, dynamic> preferences,
  ) async {
    try {
      AppLogger.debug('Updating preferences for $userId', tag: _logTag);

      // Update Firestore
      await _firestore.collection('users').doc(userId).update({
        'preferences': preferences,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update cache
      final cachedUser = _cache.userBox.get(userId);
      if (cachedUser != null) {
        final updatedUser = cachedUser.updatePreferences(preferences);
        await _cache.updateUserInCache(updatedUser);
      }

      AppLogger.debug('Preferences updated successfully', tag: _logTag);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error updating preferences for $userId',
        tag: _logTag,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> updateLastLogin(String userId) async {
    try {
      AppLogger.debug('Updating last login for $userId', tag: _logTag);

      final loginTime = DateTime.now();
      // Update Firestore
      await _firestore.collection('users').doc(userId).update({
        'lastLogin': Timestamp.fromDate(loginTime),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update cache
      final cachedUser = _cache.userBox.get(userId);
      if (cachedUser != null) {
        final updatedUser = cachedUser.copyWith(
          lastLogin: loginTime,
          updatedAt: loginTime,
        );
        await _cache.updateUserInCache(updatedUser);
      }

      AppLogger.debug('Last login updated successfully', tag: _logTag);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error updating last login for $userId',
        tag: _logTag,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> updateFcmToken(String userId, String? fcmToken) async {
    try {
      AppLogger.debug('Updating FCM token for $userId', tag: _logTag);

      // Update Firestore
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': fcmToken,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update cache
      final cachedUser = _cache.userBox.get(userId);
      if (cachedUser != null) {
        final updatedUser = cachedUser.copyWith(fcmToken: fcmToken);
        await _cache.updateUserInCache(updatedUser);
      }

      AppLogger.debug('FCM token updated successfully', tag: _logTag);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error updating FCM token for $userId',
        tag: _logTag,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> levelUpUser(String userId) async {
    try {
      AppLogger.debug('Leveling up user $userId', tag: _logTag);

      // Update Firestore
      await _firestore.collection('users').doc(userId).update({
        'level': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update cache
      final cachedUser = _cache.userBox.get(userId);
      if (cachedUser != null) {
        final updatedUser = cachedUser.levelUp();
        await _cache.updateUserInCache(updatedUser);
      }

      AppLogger.debug('User leveled up successfully', tag: _logTag);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error leveling up user $userId',
        tag: _logTag,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  void dispose() {
    AppLogger.debug('Disposing user repository', tag: _logTag);
    _firestoreSubscription?.cancel();
    _firestoreSubscription = null;
  }

  // ============ CACHE MANAGEMENT ============

  Future<bool> isCacheValid() => _cache.isCacheValid();

  Future<void> refreshCache() async {
    AppLogger.debug('Refreshing user cache from Firestore', tag: _logTag);
    await _loadUsersFromFirestore();
  }

  // ============ PRIVATE METHODS ============

  Future<List<UserModel>> _loadUsersFromFirestore() async {
    try {
      AppLogger.debug('Loading users from Firestore', tag: _logTag);

      final querySnapshot = await _firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      final users = querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();

      // Batch update cache
      final usersMap = {for (var user in users) user.id: user};
      await _cache.userBox.putAll(usersMap);
      await _cache.setLastSyncTime(DateTime.now());

      AppLogger.debug(
        'Loaded ${users.length} users from Firestore',
        tag: _logTag,
      );
      return users;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error loading users from Firestore',
        tag: _logTag,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> _startRealTimeListener() async {
    _firestoreSubscription?.cancel();

    _firestoreSubscription = _firestore
        .collection('users')
        .snapshots()
        .listen(
          (snapshot) async {
            if (snapshot.docChanges.isEmpty) return;

            AppLogger.debug(
              'Real-time user update with ${snapshot.docChanges.length} changes',
              tag: _logTag,
            );

            for (final change in snapshot.docChanges) {
              final user = UserModel.fromFirestore(change.doc);

              switch (change.type) {
                case DocumentChangeType.added:
                case DocumentChangeType.modified:
                  await _cache.userBox.put(user.id, user);
                  break;
                case DocumentChangeType.removed:
                  await _cache.userBox.delete(user.id);
                  break;
              }
            }

            await _cache.setLastSyncTime(DateTime.now());
          },
          onError: (error, stackTrace) {
            AppLogger.error(
              'Real-time user listener error',
              tag: _logTag,
              error: error,
              stackTrace: stackTrace,
            );
          },
        );
  }
}
