// cache_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';

// Import your logger
import '../logger/app_logger.dart';

// Import all models
import '../models/point_transaction_model.dart';
import '../models/question_model.dart';
import '../models/slider_model.dart';
import '../models/subscription_model.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';
import '../models/notification_model.dart';

// Import auth provider
import 'view_model_providers.dart';

// ============ CACHE CONFIGURATION ============

class CacheConfig {
  static const Duration questionCacheValidity = Duration(hours: 2);
  static const Duration userCacheValidity = Duration(hours: 1);
  static const Duration transactionCacheValidity = Duration(hours: 4);
  static const Duration sliderCacheValidity = Duration(hours: 6);
  static const Duration subscriptionCacheValidity = Duration(hours: 12);
  static const Duration notificationCacheValidity = Duration(hours: 1);
  static const Duration taskCacheValidity = Duration(hours: 3);

  static const int maxQuestionCacheSize = 500;
  static const int maxUserCacheSize = 100;
  static const int maxTransactionCacheSize = 1000;
  static const int maxSliderCacheSize = 50;
  static const int maxNotificationHistorySize = 200;
}

// ============ ENHANCED CACHE MANAGER ============

class CacheManager {
  final Box metaBox;

  static const String _tag = 'CACHE_MANAGER';

  CacheManager(this.metaBox);

  Future<DateTime?> getLastSyncTime(String cacheKey) async {
    try {
      final syncTimeString = metaBox.get(cacheKey) as String?;
      return syncTimeString != null ? DateTime.parse(syncTimeString) : null;
    } catch (e) {
      AppLogger.warning(
        'Error reading sync time for $cacheKey',
        tag: _tag,
        error: e,
      );
      return null;
    }
  }

  Future<void> setLastSyncTime(String cacheKey, DateTime time) async {
    try {
      await metaBox.put(cacheKey, time.toIso8601String());
    } catch (e) {
      AppLogger.error(
        'Error setting sync time for $cacheKey',
        tag: _tag,
        error: e,
      );
    }
  }

  Future<bool> isCacheValid(String cacheKey, Duration validity) async {
    final lastSync = await getLastSyncTime(cacheKey);
    if (lastSync == null) return false;

    final isValid = DateTime.now().difference(lastSync) < validity;
    AppLogger.debug(
      'Cache $cacheKey valid: $isValid (last sync: $lastSync)',
      tag: _tag,
    );
    return isValid;
  }

  Future<void> clearCache(String cacheKey) async {
    try {
      await metaBox.delete(cacheKey);
    } catch (e) {
      AppLogger.error('Error clearing cache $cacheKey', tag: _tag, error: e);
    }
  }

  Future<void> clearAllCache(List<String> cacheKeys) async {
    for (final key in cacheKeys) {
      await clearCache(key);
    }
  }
}

// ============ CORE BOX PROVIDERS ============

const String _providerTag = 'CACHE_PROVIDERS';

final cacheManagerProvider = Provider<CacheManager>((ref) {
  final metaBox = ref.watch(metaBoxProvider);
  return CacheManager(metaBox);
});

// Enhanced box providers with better error handling
final questionBoxProvider = Provider<Box<Question>>((ref) {
  try {
    final box = Hive.box<Question>('questions_v3');
    AppLogger.debug(
      'questionBoxProvider: ${box.keys.length} items',
      tag: _providerTag,
    );
    return box;
  } catch (e, st) {
    AppLogger.error(
      'questionBoxProvider: failed',
      tag: _providerTag,
      error: e,
      stackTrace: st,
    );
    rethrow;
  }
});

final pointTransactionBoxProvider = Provider<Box<PointTransaction>>((ref) {
  try {
    final box = Hive.box<PointTransaction>('point_transactions_v3');
    AppLogger.debug(
      'pointTransactionBoxProvider: ${box.keys.length} items',
      tag: _providerTag,
    );
    return box;
  } catch (e, st) {
    AppLogger.error(
      'pointTransactionBoxProvider: failed',
      tag: _providerTag,
      error: e,
      stackTrace: st,
    );
    rethrow;
  }
});

final userBoxProvider = Provider<Box<UserModel>>((ref) {
  try {
    final box = Hive.box<UserModel>('users_v3');
    AppLogger.debug(
      'userBoxProvider: ${box.keys.length} items',
      tag: _providerTag,
    );
    return box;
  } catch (e, st) {
    AppLogger.error(
      'userBoxProvider: failed - $e',
      tag: _providerTag,
      error: e,
      stackTrace: st,
    );
    // Return an empty box in case of error to prevent app crash
    return Hive.box<UserModel>('users_v3');
  }
});

final sliderBoxProvider = Provider<Box<SliderItem>>((ref) {
  try {
    final box = Hive.box<SliderItem>('sliders_v3');
    AppLogger.debug(
      'sliderBoxProvider: ${box.keys.length} items',
      tag: _providerTag,
    );
    return box;
  } catch (e, st) {
    AppLogger.error(
      'sliderBoxProvider: failed',
      tag: _providerTag,
      error: e,
      stackTrace: st,
    );
    rethrow;
  }
});

final subscriptionBoxProvider = Provider<Box<Subscription>>((ref) {
  try {
    final box = Hive.box<Subscription>('subscriptions_v3');
    AppLogger.debug(
      'subscriptionBoxProvider: ${box.keys.length} items',
      tag: _providerTag,
    );
    return box;
  } catch (e, st) {
    AppLogger.error(
      'subscriptionBoxProvider: failed',
      tag: _providerTag,
      error: e,
      stackTrace: st,
    );
    rethrow;
  }
});

final tasksBoxProvider = Provider<Box<Task>>((ref) {
  try {
    final box = Hive.box<Task>('tasks_v3');
    AppLogger.debug(
      'tasksBoxProvider: ${box.keys.length} items',
      tag: _providerTag,
    );
    return box;
  } catch (e, st) {
    AppLogger.error(
      'tasksBoxProvider: failed',
      tag: _providerTag,
      error: e,
      stackTrace: st,
    );
    rethrow;
  }
});

final formCacheBoxProvider = Provider<Box>((ref) {
  try {
    final box = Hive.box('form_cache_v3');
    AppLogger.debug(
      'formCacheBoxProvider: ${box.keys.length} items',
      tag: _providerTag,
    );
    return box;
  } catch (e, st) {
    AppLogger.error(
      'formCacheBoxProvider: failed',
      tag: _providerTag,
      error: e,
      stackTrace: st,
    );
    rethrow;
  }
});

final metaBoxProvider = Provider<Box>((ref) {
  try {
    final box = Hive.box('app_meta_v3');
    AppLogger.debug(
      'metaBoxProvider: ${box.keys.length} items',
      tag: _providerTag,
    );
    return box;
  } catch (e, st) {
    AppLogger.error(
      'metaBoxProvider: failed',
      tag: _providerTag,
      error: e,
      stackTrace: st,
    );
    rethrow;
  }
});

final notificationSettingsBoxProvider = Provider<Box<NotificationSettings>>((
  ref,
) {
  try {
    final box = Hive.box<NotificationSettings>('notification_settings_v3');
    AppLogger.debug(
      'notificationSettingsBoxProvider: ${box.keys.length} items',
      tag: _providerTag,
    );
    return box;
  } catch (e, st) {
    AppLogger.error(
      'notificationSettingsBoxProvider: failed',
      tag: _providerTag,
      error: e,
      stackTrace: st,
    );
    rethrow;
  }
});

final notificationHistoryBoxProvider = Provider<Box<AppNotification>>((ref) {
  try {
    final box = Hive.box<AppNotification>('notification_history_v3');
    AppLogger.debug(
      'notificationHistoryBoxProvider: ${box.keys.length} items',
      tag: _providerTag,
    );
    return box;
  } catch (e, st) {
    AppLogger.error(
      'notificationHistoryBoxProvider: failed',
      tag: _providerTag,
      error: e,
      stackTrace: st,
    );
    rethrow;
  }
});

// ============ CACHE STATE PROVIDERS ============

final authStateProvider = Provider<AsyncValue<UserModel?>>((ref) {
  return ref.watch(authViewModelProvider);
});

// Enhanced userIdProvider with better error handling
final userIdProvider = Provider<String>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      final userId = user?.id ?? '';
      debugPrint('userIdProvider updated: $userId');
      return userId;
    },
    loading: () {
      debugPrint('userIdProvider: Loading...');
      return '';
    },
    error: (error, stack) {
      debugPrint('userIdProvider: Error - $error');
      return '';
    },
  );
});

final cacheValidityProvider = Provider<Duration>((ref) {
  return const Duration(hours: 1);
});

final cacheSyncStatusProvider = StateProvider<Map<String, bool>>((ref) {
  return {};
});

// ============ ENHANCED CACHE PROVIDERS ============

final questionCacheProvider = Provider<QuestionRepositoryCache>((ref) {
  final questionBox = ref.watch(questionBoxProvider);
  final metaBox = ref.watch(metaBoxProvider);
  final cacheManager = ref.watch(cacheManagerProvider);
  return QuestionRepositoryCache(questionBox, metaBox, cacheManager);
});

final userCacheProvider = Provider<UserRepositoryCache>((ref) {
  final userBox = ref.watch(userBoxProvider);
  final metaBox = ref.watch(metaBoxProvider);
  final cacheManager = ref.watch(cacheManagerProvider);
  return UserRepositoryCache(userBox, metaBox, cacheManager);
});

final pointTransactionCacheProvider = Provider<PointTransactionCache>((ref) {
  final transactionBox = ref.watch(pointTransactionBoxProvider);
  final metaBox = ref.watch(metaBoxProvider);
  final cacheManager = ref.watch(cacheManagerProvider);
  return PointTransactionCache(transactionBox, metaBox, cacheManager);
});

final sliderCacheProvider = Provider<SliderRepositoryCache>((ref) {
  final sliderBox = ref.watch(sliderBoxProvider);
  final metaBox = ref.watch(metaBoxProvider);
  final cacheManager = ref.watch(cacheManagerProvider);
  return SliderRepositoryCache(sliderBox, metaBox, cacheManager);
});

final subscriptionCacheProvider = Provider<SubscriptionRepositoryCache>((ref) {
  final subscriptionBox = ref.watch(subscriptionBoxProvider);
  final metaBox = ref.watch(metaBoxProvider);
  final cacheManager = ref.watch(cacheManagerProvider);
  return SubscriptionRepositoryCache(subscriptionBox, metaBox, cacheManager);
});

final notificationCacheProvider = Provider<NotificationRepositoryCache>((ref) {
  final settingsBox = ref.watch(notificationSettingsBoxProvider);
  final historyBox = ref.watch(notificationHistoryBoxProvider);
  final metaBox = ref.watch(metaBoxProvider);
  final cacheManager = ref.watch(cacheManagerProvider);
  return NotificationRepositoryCache(
    settingsBox,
    historyBox,
    metaBox,
    cacheManager,
  );
});

final taskCacheProvider = Provider<TaskRepositoryCache>((ref) {
  final taskBox = ref.watch(tasksBoxProvider);
  final metaBox = ref.watch(metaBoxProvider);
  final cacheManager = ref.watch(cacheManagerProvider);
  return TaskRepositoryCache(taskBox, metaBox, cacheManager);
});

// ============ ENHANCED CACHE MANAGER CLASSES ============

abstract class BaseRepositoryCache {
  final CacheManager cacheManager;
  final String cacheKey;
  final Duration cacheValidity;

  BaseRepositoryCache({
    required this.cacheManager,
    required this.cacheKey,
    required this.cacheValidity,
  });

  Future<DateTime?> getLastSyncTime() => cacheManager.getLastSyncTime(cacheKey);

  Future<void> setLastSyncTime(DateTime time) =>
      cacheManager.setLastSyncTime(cacheKey, time);

  Future<bool> isCacheValid() =>
      cacheManager.isCacheValid(cacheKey, cacheValidity);

  Future<void> clearCache() => cacheManager.clearCache(cacheKey);
}

// In the QuestionRepositoryCache class, replace the updateQuestionAccess method:

class QuestionRepositoryCache extends BaseRepositoryCache {
  final Box<Question> questionBox;
  final Box metaBox;
  static const String _tag = 'QuestionCache';

  QuestionRepositoryCache(
    this.questionBox,
    this.metaBox,
    CacheManager cacheManager,
  ) : super(
        cacheManager: cacheManager,
        cacheKey: 'questions_sync',
        cacheValidity: CacheConfig.questionCacheValidity,
      );

  Future<void> cleanupOldQuestions() async {
    try {
      // Since Question doesn't have lastAccessed, sort by updatedAt instead
      final questions = questionBox.values.toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      if (questions.length > CacheConfig.maxQuestionCacheSize) {
        final toRemove = questions.sublist(CacheConfig.maxQuestionCacheSize);
        for (final question in toRemove) {
          await questionBox.delete(question.id);
        }
        AppLogger.debug('Removed ${toRemove.length} old questions', tag: _tag);
      }
    } catch (e) {
      AppLogger.error('Error cleaning up questions', tag: _tag, error: e);
    }
  }

  Future<void> preloadPopularQuestions(List<Question> questions) async {
    try {
      final questionsMap = {for (var q in questions) q.id: q};
      await questionBox.putAll(questionsMap);
      await setLastSyncTime(DateTime.now());
      AppLogger.debug('Preloaded ${questions.length} questions', tag: _tag);
    } catch (e) {
      AppLogger.error('Error preloading questions', tag: _tag, error: e);
    }
  }

  Future<List<Question>> getCachedQuestionsByDepartment(
    String department,
  ) async {
    try {
      final questions =
          questionBox.values.where((q) => q.department == department).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return questions;
    } catch (e) {
      AppLogger.error('Error getting cached questions', tag: _tag, error: e);
      return [];
    }
  }

  Future<Question?> getQuestionById(String questionId) async {
    try {
      return questionBox.get(questionId);
    } catch (e) {
      AppLogger.error('Error getting question by ID', tag: _tag, error: e);
      return null;
    }
  }

  // FIXED: Use viewCount instead of accessCount and lastAccessed
  Future<void> updateQuestionAccess(String questionId) async {
    try {
      final question = questionBox.get(questionId);
      if (question != null) {
        final updatedQuestion = question.copyWith(
          viewCount: question.viewCount + 1,
          updatedAt: DateTime.now(),
        );
        await questionBox.put(questionId, updatedQuestion);
        AppLogger.debug('Updated question access: $questionId', tag: _tag);
      }
    } catch (e) {
      AppLogger.error('Error updating question access', tag: _tag, error: e);
    }
  }

  // Additional utility methods for Question cache
  Future<void> incrementQuestionDownload(String questionId) async {
    try {
      final question = questionBox.get(questionId);
      if (question != null) {
        final updatedQuestion = question.copyWith(
          downloadCount: question.downloadCount + 1,
          updatedAt: DateTime.now(),
        );
        await questionBox.put(questionId, updatedQuestion);
        AppLogger.debug('Incremented download count: $questionId', tag: _tag);
      }
    } catch (e) {
      AppLogger.error('Error incrementing download count', tag: _tag, error: e);
    }
  }

  Future<List<Question>> getPopularQuestions({int limit = 10}) async {
    try {
      final questions = questionBox.values.toList()
        ..sort((a, b) => b.viewCount.compareTo(a.viewCount));
      return questions.take(limit).toList();
    } catch (e) {
      AppLogger.error('Error getting popular questions', tag: _tag, error: e);
      return [];
    }
  }

  Future<List<Question>> getRecentQuestions({int limit = 10}) async {
    try {
      final questions = questionBox.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return questions.take(limit).toList();
    } catch (e) {
      AppLogger.error('Error getting recent questions', tag: _tag, error: e);
      return [];
    }
  }

  Future<List<Question>> searchQuestions(String query) async {
    try {
      final lowerQuery = query.toLowerCase();
      return questionBox.values
          .where(
            (question) =>
                question.courseName.toLowerCase().contains(lowerQuery) ||
                question.courseCode.toLowerCase().contains(lowerQuery) ||
                question.teacherName.toLowerCase().contains(lowerQuery) ||
                question.examType.toLowerCase().contains(lowerQuery),
          )
          .toList();
    } catch (e) {
      AppLogger.error('Error searching questions', tag: _tag, error: e);
      return [];
    }
  }
}

class UserRepositoryCache extends BaseRepositoryCache {
  final Box<UserModel> userBox;
  final Box metaBox;
  static const String _tag = 'UserCache';

  UserRepositoryCache(this.userBox, this.metaBox, CacheManager cacheManager)
    : super(
        cacheManager: cacheManager,
        cacheKey: 'users_sync',
        cacheValidity: CacheConfig.userCacheValidity,
      );

  Future<void> updateUserInCache(UserModel user) async {
    try {
      // Update last accessed time and version
      final updatedUser = user.copyWith(
        updatedAt: DateTime.now(),
        version: user.version + 1,
      );
      await userBox.put(user.id, updatedUser);
      AppLogger.debug('Updated user in cache: ${user.id}', tag: _tag);
    } catch (e) {
      AppLogger.error('Error updating user in cache', tag: _tag, error: e);
    }
  }

  Future<UserModel?> getUserWithFallback(
    String userId,
    Future<UserModel?> remoteFetch,
  ) async {
    try {
      final cached = userBox.get(userId);
      if (cached != null && await isCacheValid()) {
        AppLogger.debug('Using cached user for $userId', tag: _tag);
        // Update access time on cache hit
        await updateUserInCache(cached);
        return cached;
      }

      AppLogger.debug('Fetching remote user for $userId', tag: _tag);
      final remoteUser = await remoteFetch;
      if (remoteUser != null) {
        await userBox.put(userId, remoteUser);
        await setLastSyncTime(DateTime.now());
        AppLogger.debug('Saved remote user to cache: $userId', tag: _tag);
      } else {
        AppLogger.debug('No remote user found for: $userId', tag: _tag);
      }
      return remoteUser;
    } catch (e) {
      AppLogger.error(
        'Error in user fallback for $userId',
        tag: _tag,
        error: e,
      );
      // Return stale cache on error
      final cached = userBox.get(userId);
      if (cached != null) {
        AppLogger.debug('Returning stale cache for $userId', tag: _tag);
      }
      return cached;
    }
  }

  Future<void> clearUserCache() async {
    try {
      await userBox.clear();
      await clearCache();
      AppLogger.debug('Cleared user cache', tag: _tag);
    } catch (e) {
      AppLogger.error('Error clearing user cache', tag: _tag, error: e);
    }
  }

  Future<List<UserModel>> getAllCachedUsers() async {
    try {
      return userBox.values.toList();
    } catch (e) {
      AppLogger.error('Error getting all cached users', tag: _tag, error: e);
      return [];
    }
  }
}

class PointTransactionCache extends BaseRepositoryCache {
  final Box<PointTransaction> transactionBox;
  final Box metaBox;
  static const String _tag = 'PointTransactionCache';

  PointTransactionCache(
    this.transactionBox,
    this.metaBox,
    CacheManager cacheManager,
  ) : super(
        cacheManager: cacheManager,
        cacheKey: 'point_transactions_sync',
        cacheValidity: CacheConfig.transactionCacheValidity,
      );

  Future<void> addTransactionWithCacheUpdate(
    PointTransaction transaction,
  ) async {
    try {
      await transactionBox.put(transaction.id, transaction);

      final transactions = transactionBox.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (transactions.length > CacheConfig.maxTransactionCacheSize) {
        final toRemove = transactions.sublist(
          CacheConfig.maxTransactionCacheSize,
        );
        for (final transaction in toRemove) {
          await transactionBox.delete(transaction.id);
        }
        AppLogger.debug(
          'Cleaned up ${toRemove.length} old transactions',
          tag: _tag,
        );
      }
    } catch (e) {
      AppLogger.error('Error adding transaction', tag: _tag, error: e);
    }
  }

  Future<int> getCachedBalance(String userId) async {
    try {
      final transactions = transactionBox.values
          .where((t) => t.userId == userId)
          .toList();
      final earned = transactions
          .where((t) => t.isEarned)
          .fold<int>(0, (sum, t) => sum + t.points);
      final spent = transactions
          .where((t) => t.isSpent)
          .fold<int>(0, (sum, t) => sum + t.points);
      return earned - spent;
    } catch (e) {
      AppLogger.error('Error calculating balance', tag: _tag, error: e);
      return 0;
    }
  }

  Future<List<PointTransaction>> getRecentUserTransactions(
    String userId, {
    int limit = 10,
  }) async {
    try {
      final transactions =
          transactionBox.values.where((t) => t.userId == userId).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return transactions.take(limit).toList();
    } catch (e) {
      AppLogger.error('Error getting recent transactions', tag: _tag, error: e);
      return [];
    }
  }

  Future<List<PointTransaction>> getAllUserTransactions(String userId) async {
    try {
      return transactionBox.values.where((t) => t.userId == userId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      AppLogger.error('Error getting all transactions', tag: _tag, error: e);
      return [];
    }
  }
}

class SliderRepositoryCache extends BaseRepositoryCache {
  final Box<SliderItem> sliderBox;
  final Box metaBox;
  static const String _tag = 'SliderCache';

  SliderRepositoryCache(this.sliderBox, this.metaBox, CacheManager cacheManager)
    : super(
        cacheManager: cacheManager,
        cacheKey: 'sliders_sync',
        cacheValidity: CacheConfig.sliderCacheValidity,
      );

  Future<List<SliderItem>> getActiveSlidersWithFallback(
    Future<List<SliderItem>> remoteFetch,
  ) async {
    try {
      final cachedSliders = sliderBox.values.toList();
      final activeCached = cachedSliders
          .where((slider) => slider.isValid)
          .toList();

      if (activeCached.isNotEmpty && await isCacheValid()) {
        AppLogger.debug(
          'Using ${activeCached.length} cached sliders',
          tag: _tag,
        );
        return activeCached..sort((a, b) => a.order.compareTo(b.order));
      }

      AppLogger.debug('Fetching remote sliders', tag: _tag);
      final remoteSliders = await remoteFetch;
      await updateSliderCache(remoteSliders);
      return remoteSliders;
    } catch (e) {
      AppLogger.error('Error in slider fallback', tag: _tag, error: e);
      final cachedSliders = sliderBox.values.toList();
      return cachedSliders.where((slider) => slider.isValid).toList()
        ..sort((a, b) => a.order.compareTo(b.order));
    }
  }

  Future<void> updateSliderCache(List<SliderItem> sliders) async {
    try {
      final slidersMap = {for (var slider in sliders) slider.id: slider};
      await sliderBox.clear();
      await sliderBox.putAll(slidersMap);
      await setLastSyncTime(DateTime.now());

      // Cleanup logic (max size)
      if (sliderBox.values.length > CacheConfig.maxSliderCacheSize) {
        final allSliders = sliderBox.values.toList()
          ..sort((a, b) => b.order.compareTo(a.order));
        final toRemove = allSliders.sublist(CacheConfig.maxSliderCacheSize);
        for (final slider in toRemove) {
          await sliderBox.delete(slider.id);
        }
      }

      AppLogger.debug(
        'Updated cache with ${sliders.length} sliders',
        tag: _tag,
      );
    } catch (e) {
      AppLogger.error('Error updating slider cache', tag: _tag, error: e);
    }
  }

  Future<SliderItem?> getSliderById(String sliderId) async {
    try {
      return sliderBox.get(sliderId);
    } catch (e) {
      AppLogger.error('Error getting slider by ID', tag: _tag, error: e);
      return null;
    }
  }
}

class SubscriptionRepositoryCache extends BaseRepositoryCache {
  final Box<Subscription> subscriptionBox;
  final Box metaBox;
  static const String _tag = 'SubscriptionCache';

  SubscriptionRepositoryCache(
    this.subscriptionBox,
    this.metaBox,
    CacheManager cacheManager,
  ) : super(
        cacheManager: cacheManager,
        cacheKey: 'subscriptions_sync',
        cacheValidity: CacheConfig.subscriptionCacheValidity,
      );

  Future<Subscription?> getCurrentSubscriptionWithFallback(
    String userId,
    Future<Subscription?> remoteFetch,
  ) async {
    try {
      final cached = subscriptionBox.get(userId);
      if (cached != null && await isCacheValid()) {
        AppLogger.debug('Using cached subscription for $userId', tag: _tag);
        return cached;
      }

      AppLogger.debug('Fetching remote subscription for $userId', tag: _tag);
      final remoteSubscription = await remoteFetch;
      if (remoteSubscription != null) {
        await subscriptionBox.put(userId, remoteSubscription);
      } else {
        await subscriptionBox.delete(userId);
      }
      await setLastSyncTime(DateTime.now());
      return remoteSubscription;
    } catch (e) {
      AppLogger.error('Error in subscription fallback', tag: _tag, error: e);
      return subscriptionBox.get(userId);
    }
  }

  Future<bool> hasActiveSubscriptionWithFallback(
    String userId,
    Future<bool> remoteCheck,
  ) async {
    try {
      final cached = subscriptionBox.get(userId);
      if (cached != null && await isCacheValid()) {
        AppLogger.debug(
          'Using cached subscription status for $userId',
          tag: _tag,
        );
        return cached.isValid;
      }

      AppLogger.debug(
        'Fetching remote subscription status for $userId',
        tag: _tag,
      );
      final remoteResult = await remoteCheck;
      await setLastSyncTime(DateTime.now());
      return remoteResult;
    } catch (e) {
      AppLogger.error('Error checking subscription', tag: _tag, error: e);
      final cached = subscriptionBox.get(userId);
      return cached?.isValid ?? false;
    }
  }

  Future<void> updateSubscription(
    String userId,
    Subscription subscription,
  ) async {
    try {
      await subscriptionBox.put(userId, subscription);
      await setLastSyncTime(DateTime.now());
      AppLogger.debug('Updated subscription for $userId', tag: _tag);
    } catch (e) {
      AppLogger.error('Error updating subscription', tag: _tag, error: e);
    }
  }
}

class NotificationRepositoryCache extends BaseRepositoryCache {
  final Box<NotificationSettings> settingsBox;
  final Box<AppNotification> historyBox;
  final Box metaBox;
  static const String _tag = 'NotificationCache';

  NotificationRepositoryCache(
    this.settingsBox,
    this.historyBox,
    this.metaBox,
    CacheManager cacheManager,
  ) : super(
        cacheManager: cacheManager,
        cacheKey: 'notifications_sync',
        cacheValidity: CacheConfig.notificationCacheValidity,
      );

  Future<NotificationSettings> getSettingsWithFallback(
    Future<NotificationSettings> remoteFetch,
  ) async {
    try {
      final cached = settingsBox.get('current_user_settings');
      if (cached != null && await isCacheValid()) {
        AppLogger.debug('Using cached settings', tag: _tag);
        return cached;
      }

      AppLogger.debug('Fetching remote settings', tag: _tag);
      final remoteSettings = await remoteFetch;
      await settingsBox.put('current_user_settings', remoteSettings);
      await setLastSyncTime(DateTime.now());
      return remoteSettings;
    } catch (e) {
      AppLogger.error('Error in settings fallback', tag: _tag, error: e);
      return settingsBox.get('current_user_settings') ??
          NotificationSettings.defaults();
    }
  }

  Future<void> addNotificationToHistory(AppNotification notification) async {
    try {
      await historyBox.put(notification.id, notification);

      final notifications = historyBox.values.toList()
        ..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));

      if (notifications.length > CacheConfig.maxNotificationHistorySize) {
        final toRemove = notifications.sublist(
          CacheConfig.maxNotificationHistorySize,
        );
        for (final notif in toRemove) {
          await historyBox.delete(notif.id);
        }
      }
      AppLogger.debug(
        'Added notification to history: ${notification.id}',
        tag: _tag,
      );
    } catch (e) {
      AppLogger.error('Error adding notification', tag: _tag, error: e);
    }
  }

  Future<List<AppNotification>> getNotificationHistoryWithFallback(
    Future<List<AppNotification>> remoteFetch,
  ) async {
    try {
      final cachedHistory = historyBox.values.toList()
        ..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));

      if (cachedHistory.isNotEmpty && await isCacheValid()) {
        AppLogger.debug(
          'Using ${cachedHistory.length} cached notifications',
          tag: _tag,
        );
        return cachedHistory;
      }

      AppLogger.debug('Fetching remote notification history', tag: _tag);
      final remoteHistory = await remoteFetch;
      final historyMap = {for (var notif in remoteHistory) notif.id: notif};
      await historyBox.clear();
      await historyBox.putAll(historyMap);
      await setLastSyncTime(DateTime.now());
      return remoteHistory;
    } catch (e) {
      AppLogger.error('Error getting history', tag: _tag, error: e);
      return historyBox.values.toList()
        ..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
    }
  }

  Future<void> updateNotificationSettings(NotificationSettings settings) async {
    try {
      await settingsBox.put('current_user_settings', settings);
      await setLastSyncTime(DateTime.now());
      AppLogger.debug('Updated notification settings', tag: _tag);
    } catch (e) {
      AppLogger.error(
        'Error updating notification settings',
        tag: _tag,
        error: e,
      );
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final notification = historyBox.get(notificationId);
      if (notification != null) {
        final updatedNotification = notification.copyWith(isRead: true);
        await historyBox.put(notificationId, updatedNotification);
        AppLogger.debug(
          'Marked notification as read: $notificationId',
          tag: _tag,
        );
      }
    } catch (e) {
      AppLogger.error(
        'Error marking notification as read',
        tag: _tag,
        error: e,
      );
    }
  }
}

class TaskRepositoryCache extends BaseRepositoryCache {
  final Box<Task> taskBox;
  final Box metaBox;
  static const String _tag = 'TaskCache';

  TaskRepositoryCache(this.taskBox, this.metaBox, CacheManager cacheManager)
    : super(
        cacheManager: cacheManager,
        cacheKey: 'tasks_sync',
        cacheValidity: CacheConfig.taskCacheValidity,
      );

  Future<List<Task>> getTasksWithFallback(
    Future<List<Task>> remoteFetch,
  ) async {
    try {
      final cachedTasks = taskBox.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (cachedTasks.isNotEmpty && await isCacheValid()) {
        AppLogger.debug('Using ${cachedTasks.length} cached tasks', tag: _tag);
        return cachedTasks;
      }

      AppLogger.debug('Fetching remote tasks', tag: _tag);
      final remoteTasks = await remoteFetch;
      final tasksMap = {for (var task in remoteTasks) task.id: task};
      await taskBox.clear();
      await taskBox.putAll(tasksMap);
      await setLastSyncTime(DateTime.now());
      return remoteTasks;
    } catch (e) {
      AppLogger.error('Error in task fallback', tag: _tag, error: e);
      return taskBox.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
  }

  Future<void> updateTaskInCache(Task task) async {
    try {
      final updatedTask = task.copyWith(updatedAt: DateTime.now());
      await taskBox.put(task.id, updatedTask);
      AppLogger.debug('Updated task in cache: ${task.id}', tag: _tag);
    } catch (e) {
      AppLogger.error('Error updating task', tag: _tag, error: e);
    }
  }

  Future<Task?> getTaskById(String taskId) async {
    try {
      return taskBox.get(taskId);
    } catch (e) {
      AppLogger.error('Error getting task by ID', tag: _tag, error: e);
      return null;
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await taskBox.delete(taskId);
      AppLogger.debug('Deleted task from cache: $taskId', tag: _tag);
    } catch (e) {
      AppLogger.error('Error deleting task', tag: _tag, error: e);
    }
  }

  Future<List<Task>> getTasksByStatus(TaskStatus status) async {
    try {
      return taskBox.values.where((task) => task.status == status).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      AppLogger.error('Error getting tasks by status', tag: _tag, error: e);
      return [];
    }
  }
}

// ============ CACHE UTILITY PROVIDERS ============

final cacheHealthProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final questionBox = ref.read(questionBoxProvider);
    final userBox = ref.read(userBoxProvider);
    final transactionBox = ref.read(pointTransactionBoxProvider);
    final taskBox = ref.read(tasksBoxProvider);
    final metaBox = ref.read(metaBoxProvider);

    final questionCache = ref.read(questionCacheProvider);
    final userCache = ref.read(userCacheProvider);

    return {
      'question_cache': {
        'items': questionBox.keys.length,
        'valid': await questionCache.isCacheValid(),
        'last_sync': await questionCache.getLastSyncTime(),
      },
      'user_cache': {
        'items': userBox.keys.length,
        'valid': await userCache.isCacheValid(),
        'last_sync': await userCache.getLastSyncTime(),
      },
      'transaction_cache': {'items': transactionBox.keys.length},
      'task_cache': {'items': taskBox.keys.length},
      'meta_cache': {'items': metaBox.keys.length},
      'overall_healthy': true,
      'timestamp': DateTime.now().toIso8601String(),
    };
  } catch (e) {
    return {
      'overall_healthy': false,
      'error': e.toString(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
});

final clearAllCacheProvider = FutureProvider<void>((ref) async {
  try {
    final boxes = [
      ref.read(questionBoxProvider),
      ref.read(userBoxProvider),
      ref.read(pointTransactionBoxProvider),
      ref.read(sliderBoxProvider),
      ref.read(subscriptionBoxProvider),
      ref.read(tasksBoxProvider),
      ref.read(notificationSettingsBoxProvider),
      ref.read(notificationHistoryBoxProvider),
      ref.read(formCacheBoxProvider),
      ref.read(metaBoxProvider),
    ];

    for (final box in boxes) {
      await box.clear();
    }

    AppLogger.debug('Cleared all cache boxes', tag: 'CACHE_PROVIDERS');
  } catch (e, st) {
    AppLogger.error(
      'Error clearing all cache',
      tag: 'CACHE_PROVIDERS',
      error: e,
      stackTrace: st,
    );
    rethrow;
  }
});
