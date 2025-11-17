// repositories/implementations/slider_repository_impl.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import '../../models/slider_model.dart';
import '../interfaces/slider_repository.dart';
import '../../providers/cache_providers.dart';

class SliderRepositoryImpl implements ISliderRepository {
  final FirebaseFirestore _firestore;
  final SliderRepositoryCache _cache;

  SliderRepositoryImpl({
    required FirebaseFirestore firestore,
    required SliderRepositoryCache cache,
  }) : _firestore = firestore,
       _cache = cache;

  @override
  Future<List<SliderItem>> getAll() async {
    try {
      debugPrint('SliderRepository: Getting all sliders');

      // Create the future first, then pass it to the cache
      Future<List<SliderItem>> loadFromFirestore() async {
        debugPrint('SliderRepository: Loading sliders from Firestore');
        return await _loadSlidersFromFirestore();
      }

      // Execute the future and pass the result
      final firestoreFuture = loadFromFirestore();
      return await _cache.getActiveSlidersWithFallback(firestoreFuture);
    } catch (e) {
      debugPrint('Error getting all sliders: $e');
      final cachedSliders = _cache.sliderBox.values.toList();
      return _sortAndFilterSliders(cachedSliders);
    }
  }

  @override
  Future<void> save(SliderItem item) async {
    try {
      debugPrint('SliderRepository: Saving slider ${item.id}');

      await _firestore
          .collection('sliders')
          .doc(item.id)
          .set(item.toFirestore());
      await _cache.sliderBox.put(item.id, item);
      await _cache.setLastSyncTime(DateTime.now());

      debugPrint('SliderRepository: Slider saved successfully: ${item.title}');
    } catch (e) {
      debugPrint('Error saving slider: $e');
      rethrow;
    }
  }

  @override
  Stream<List<SliderItem>> watchAll() {
    debugPrint('SliderRepository: Watching all sliders');

    return _cache.sliderBox.watch().map((event) {
      return _sortAndFilterSliders(_cache.sliderBox.values.toList());
    });
  }

  @override
  Future<void> syncWithRemote() async {
    try {
      debugPrint('SliderRepository: Starting sync with remote');
      await _loadSlidersFromFirestore();
      debugPrint('SliderRepository: Sync completed successfully');
    } catch (e) {
      debugPrint('Error syncing sliders: $e');
      rethrow;
    }
  }

  @override
  Future<void> clearCache() async {
    debugPrint('SliderRepository: Clearing slider cache');
    await _cache.sliderBox.clear();
    await _cache.clearCache();
    debugPrint('SliderRepository: Cache cleared successfully');
  }

  @override
  void dispose() {
    debugPrint('SliderRepository: Disposing repository');
    _cache.sliderBox.close();
  }

  // ============ ENHANCED METHODS ============

  @override
  Future<bool> isCacheValid() async {
    return await _cache.isCacheValid();
  }

  @override
  Future<void> refreshCache() async {
    debugPrint('SliderRepository: Refreshing cache from Firestore');
    await _loadSlidersFromFirestore();
  }

  @override
  Future<List<SliderItem>> getActiveSliders() async {
    try {
      debugPrint('SliderRepository: Getting active sliders');

      final allSliders = await getAll();
      final activeSliders = allSliders
          .where((slider) => slider.isValid)
          .toList();

      debugPrint(
        'SliderRepository: Found ${activeSliders.length} active sliders',
      );
      return activeSliders;
    } catch (e) {
      debugPrint('Error getting active sliders: $e');
      rethrow;
    }
  }

  @override
  Future<List<SliderItem>> getSlidersByType(SliderType type) async {
    try {
      debugPrint('SliderRepository: Getting sliders by type: $type');

      final allSliders = await getAll();
      final typedSliders = allSliders
          .where((slider) => slider.type == type && slider.isValid)
          .toList();

      debugPrint(
        'SliderRepository: Found ${typedSliders.length} sliders of type $type',
      );
      return typedSliders;
    } catch (e) {
      debugPrint('Error getting sliders by type: $e');
      rethrow;
    }
  }

  // ============ NEW UTILITY METHODS ============

  Future<List<SliderItem>> getValidSliders() async {
    try {
      debugPrint('SliderRepository: Getting valid sliders');

      final allSliders = await getAll();
      final validSliders = allSliders
          .where((slider) => slider.isValid)
          .toList();

      debugPrint(
        'SliderRepository: Found ${validSliders.length} valid sliders',
      );
      return validSliders;
    } catch (e) {
      debugPrint('Error getting valid sliders: $e');
      rethrow;
    }
  }

  Future<List<SliderItem>> getSlidersByActionType(
    SliderActionType actionType,
  ) async {
    try {
      debugPrint(
        'SliderRepository: Getting sliders by action type: $actionType',
      );

      final allSliders = await getAll();
      final actionSliders = allSliders
          .where((slider) => slider.actionType == actionType && slider.isValid)
          .toList();

      debugPrint(
        'SliderRepository: Found ${actionSliders.length} sliders with action type $actionType',
      );
      return actionSliders;
    } catch (e) {
      debugPrint('Error getting sliders by action type: $e');
      rethrow;
    }
  }

  // ============ PRIVATE METHODS ============

  Future<List<SliderItem>> _loadSlidersFromFirestore() async {
    debugPrint('SliderRepository: Loading sliders from Firestore');

    final querySnapshot = await _firestore
        .collection('sliders')
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .get();

    final sliders = querySnapshot.docs
        .map((doc) => SliderItem.fromFirestore(doc))
        .toList();

    await _cache.updateSliderCache(sliders);

    debugPrint(
      'SliderRepository: Loaded ${sliders.length} sliders from Firestore',
    );
    return _sortAndFilterSliders(sliders);
  }

  List<SliderItem> _sortAndFilterSliders(List<SliderItem> sliders) {
    return sliders.where((slider) => slider.isValid).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }
}
