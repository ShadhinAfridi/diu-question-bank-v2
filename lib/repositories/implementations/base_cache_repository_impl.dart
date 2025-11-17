// repositories/implementations/base_cache_repository_impl.dart
import 'dart:async';
import 'package:hive/hive.dart';
import '../interfaces/base_cache_repository.dart';

abstract class BaseCacheRepositoryImpl<T> implements IBaseCacheRepository<T> {
  @override
  final String boxName;

  @override
  final Duration cacheValidity;

  BaseCacheRepositoryImpl({
    required this.boxName,
    this.cacheValidity = const Duration(hours: 1),
  });

  // Helper method to open Hive box with proper error handling
  Future<Box<T>> openBox<T>() async {
    try {
      return await Hive.openBox<T>(boxName);
    } catch (e) {
      throw Exception('Failed to open box $boxName: $e');
    }
  }
}