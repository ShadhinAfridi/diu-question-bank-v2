import '../../models/task_model.dart';

abstract class ITaskRepository {
  Future<Task?> get(String id);
  Future<List<Task>> getAll();
  Stream<List<Task>> watchAll();
  Future<void> save(Task task);
  Future<void> delete(String id);
  Future<void> syncWithRemote();
  Future<void> clearCache();

  Future<List<Task>> getTasksByStatus(TaskStatus status);
  Future<void> updateTaskStatus(String taskId, TaskStatus newStatus);
  Future<void> updateTaskCompletion(String taskId, bool isCompleted);
}