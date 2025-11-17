// repositories/interfaces/base_cache_repository.dart
import 'dart:async';
import 'package:hive/hive.dart';

abstract class IBaseCacheRepository<T> {
  final String boxName;
  final Duration cacheValidity;

  IBaseCacheRepository({
    required this.boxName,
    this.cacheValidity = const Duration(hours: 1),
  });

  Future<Box<T>> get box;
  Future<void> preloadData();
  Stream<Map<String, T>> watchAllAsMap();
  Future<void> syncWithRemote();
  Future<DateTime?> getLastSyncTime();
  Future<void> setLastSyncTime(DateTime time);
  Future<bool> isCacheValid();
  Future<void> clearCache();
}

class CacheConfig {
  final String boxName;
  final Duration validity;
  final bool enableBackgroundSync;
  final bool preloadOnStartup;

  const CacheConfig({
    required this.boxName,
    this.validity = const Duration(hours: 1),
    this.enableBackgroundSync = true,
    this.preloadOnStartup = true,
  });
}