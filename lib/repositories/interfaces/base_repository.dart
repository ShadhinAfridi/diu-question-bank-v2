// repositories/interfaces/base_repository.dart
import '../../models/base_model.dart';

abstract class IBaseRepository<T extends BaseModel> {
  Future<T?> get(String id);
  Future<List<T>> getAll();
  Future<void> save(T item);
  Future<void> delete(String id);
  Stream<List<T>> watchAll();
  Future<void> syncWithRemote();
  Future<void> clearCache();
  void dispose();
}