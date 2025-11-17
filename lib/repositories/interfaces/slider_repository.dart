// repositories/interfaces/slider_repository.dart
import '../../models/slider_model.dart';

abstract class ISliderRepository {
  Future<List<SliderItem>> getAll();
  Future<void> save(SliderItem item);
  Stream<List<SliderItem>> watchAll();
  Future<void> syncWithRemote();
  Future<void> clearCache();
  void dispose();

  // Enhanced cache management methods
  Future<bool> isCacheValid();
  Future<void> refreshCache();

  // Additional utility methods
  Future<List<SliderItem>> getActiveSliders();
  Future<List<SliderItem>> getSlidersByType(SliderType type);
}