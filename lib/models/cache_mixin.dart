// cache_mixin.dart - Verified
import 'package:hive/hive.dart';
import 'base_model.dart'; // Import the new BaseModel

/// This mixin adds cache-specific properties (expiry, last accessed)
/// to a BaseModel.
mixin CacheMixin on BaseModel {
  @HiveField(100)
  late DateTime cacheExpiry;

  @HiveField(101)
  late DateTime lastAccessed;

  @HiveField(102)
  late String cacheKey;

  void initializeCache({Duration cacheDuration = const Duration(hours: 1)}) {
    final now = DateTime.now();
    cacheExpiry = now.add(cacheDuration);
    lastAccessed = now;
    cacheKey = '${runtimeType}_$id';
  }

  bool get isCacheValid => DateTime.now().isBefore(cacheExpiry);

  void touch() {
    lastAccessed = DateTime.now();
  }

  void extendCache({Duration duration = const Duration(hours: 1)}) {
    cacheExpiry = DateTime.now().add(duration);
  }

  /// Checks if cache should be refreshed based on last access
  bool get shouldRefreshFromCache {
    final now = DateTime.now();
    return now.difference(lastAccessed).inMinutes > 30; // Refresh after 30 minutes
  }
}