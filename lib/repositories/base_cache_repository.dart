// repositories/base_cache_repository.dart
import 'dart:async';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

abstract class BaseCacheRepository<T> {
  final String boxName;
  final Duration cacheValidity;

  BaseCacheRepository({
    required this.boxName,
    this.cacheValidity = const Duration(hours: 1),
  });

  // Abstract methods to be implemented by concrete repositories
  Future<Box<T>> get box;
  Future<void> preloadData();
  Stream<Map<String, T>> watchAll();
  Future<void> syncWithRemote();
  Future<DateTime?> getLastSyncTime();
  Future<void> setLastSyncTime(DateTime time);
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