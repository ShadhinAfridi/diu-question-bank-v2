// repositories/implementations/task_repository_impl.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:diuquestionbank/models/base_model.dart';
import 'package:diuquestionbank/models/task_model.dart';
import 'package:diuquestionbank/providers/cache_providers.dart';
import 'package:diuquestionbank/logger/app_logger.dart';
import '../interfaces/task_repository.dart';

class TaskRepositoryImpl implements ITaskRepository {
  final FirebaseFirestore _firestore;
  final TaskRepositoryCache _cache;
  final String? _userId;

  static const String _logTag = 'TASK_REPOSITORY';

  TaskRepositoryImpl({
    required FirebaseFirestore firestore,
    required TaskRepositoryCache cache,
    String? userId,
  }) : _firestore = firestore,
       _cache = cache,
       _userId = userId;

  CollectionReference<Map<String, dynamic>> get _tasksCollection => _firestore
      .collection('users')
      .doc(_userId ?? 'default')
      .collection('tasks');

  @override
  Future<Task?> get(String id) async {
    try {
      // Check cache first
      final cached = _cache.taskBox.get(id);
      if (cached != null && await _cache.isCacheValid()) {
        AppLogger.debug('Cache hit for task $id', tag: _logTag);
        return cached;
      }

      // Validate user authentication
      if (_userId == null) {
        throw Exception("User not authenticated");
      }

      // Fetch from Firestore
      final doc = await _tasksCollection.doc(id).get();
      if (doc.exists) {
        final task = Task.fromMap(doc.data()!);
        await _cache.taskBox.put(id, task);
        await _cache.setLastSyncTime(DateTime.now());
        AppLogger.debug('Fetched task $id from Firestore', tag: _logTag);
        return task;
      }

      return null;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error getting task $id',
        tag: _logTag,
        error: e,
        stackTrace: stackTrace,
      );

      // Fallback to cache
      final cached = _cache.taskBox.get(id);
      if (cached != null) {
        AppLogger.debug('Using cached fallback for task $id', tag: _logTag);
      }
      return cached;
    }
  }

  @override
  Future<List<Task>> getAll() async {
    try {
      // Create the future first
      Future<List<Task>> loadTasks() async {
        if (_userId == null) {
          throw Exception("User not authenticated");
        }

        AppLogger.debug('Loading tasks from Firestore', tag: _logTag);
        return await _loadTasksFromFirestore();
      }

      // Execute the future and pass the result
      final tasksFuture = loadTasks();
      return await _cache.getTasksWithFallback(tasksFuture);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error getting all tasks',
        tag: _logTag,
        error: e,
        stackTrace: stackTrace,
      );

      // Return cached tasks as fallback
      final cachedTasks = _cache.taskBox.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      AppLogger.debug(
        'Using ${cachedTasks.length} cached tasks as fallback',
        tag: _logTag,
      );
      return cachedTasks;
    }
  }

  @override
  Stream<List<Task>> watchAll() {
    return _cache.taskBox.watch().map((event) {
      final tasks = _cache.taskBox.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return tasks;
    });
  }

  @override
  Future<void> save(Task task) async {
    try {
      if (_userId == null) {
        throw Exception("User not authenticated");
      }

      final updatedTask = task.copyWith(
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.pending,
      );

      // Save to Firestore
      await _tasksCollection.doc(task.id).set(updatedTask.toMap());

      // Update cache with synced status
      final syncedTask = updatedTask.copyWith(syncStatus: SyncStatus.synced);
      await _cache.updateTaskInCache(syncedTask);
      await _cache.setLastSyncTime(DateTime.now());

      AppLogger.debug('Task saved successfully: ${task.id}', tag: _logTag);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error saving task',
        tag: _logTag,
        error: e,
        stackTrace: stackTrace,
      );

      // Save to cache with pending status for offline support
      final offlineTask = task.copyWith(
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.pending,
      );
      await _cache.updateTaskInCache(offlineTask);

      rethrow;
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      if (_userId == null) {
        throw Exception("User not authenticated");
      }

      await _tasksCollection.doc(id).delete();
      await _cache.taskBox.delete(id);
      await _cache.setLastSyncTime(DateTime.now());

      AppLogger.debug('Task deleted successfully: $id', tag: _logTag);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error deleting task',
        tag: _logTag,
        error: e,
        stackTrace: stackTrace,
      );

      // Mark as pending delete in cache
      final cachedTask = _cache.taskBox.get(id);
      if (cachedTask != null) {
        final deletedTask = cachedTask.copyWith(
          syncStatus: SyncStatus.pendingDelete,
          updatedAt: DateTime.now(),
        );
        await _cache.updateTaskInCache(deletedTask);
      }

      rethrow;
    }
  }

  @override
  Future<void> syncWithRemote() async {
    try {
      if (_userId == null) {
        throw Exception("User not authenticated");
      }

      AppLogger.debug('Starting task sync with remote', tag: _logTag);
      await _loadTasksFromFirestore();
      AppLogger.debug('Task sync completed successfully', tag: _logTag);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error syncing tasks',
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
      await _cache.taskBox.clear();
      await _cache.clearCache();
      AppLogger.debug('Task cache cleared successfully', tag: _logTag);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error clearing task cache',
        tag: _logTag,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<List<Task>> getTasksByStatus(TaskStatus status) async {
    try {
      final allTasks = await getAll();
      final filteredTasks = allTasks
          .where((task) => task.status == status)
          .toList();

      AppLogger.debug(
        'Found ${filteredTasks.length} tasks with status $status',
        tag: _logTag,
      );
      return filteredTasks;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error getting tasks by status',
        tag: _logTag,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> updateTaskStatus(String taskId, TaskStatus newStatus) async {
    try {
      final task = await get(taskId);
      if (task != null) {
        await save(task.copyWith(status: newStatus));
        AppLogger.debug(
          'Updated task $taskId status to $newStatus',
          tag: _logTag,
        );
      } else {
        throw Exception('Task $taskId not found');
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error updating task status',
        tag: _logTag,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> updateTaskCompletion(String taskId, bool isCompleted) async {
    try {
      final task = await get(taskId);
      if (task != null) {
        final newStatus = isCompleted
            ? TaskStatus.completed
            : TaskStatus.ongoing;
        await save(task.copyWith(isCompleted: isCompleted, status: newStatus));
        AppLogger.debug(
          'Updated task $taskId completion to $isCompleted',
          tag: _logTag,
        );
      } else {
        throw Exception('Task $taskId not found');
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error updating task completion',
        tag: _logTag,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  void dispose() {
    AppLogger.debug('Disposing task repository', tag: _logTag);
    // Hive boxes are automatically managed by providers
  }

  // ============ PRIVATE METHODS ============

  Future<List<Task>> _loadTasksFromFirestore() async {
    try {
      final querySnapshot = await _tasksCollection
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();

      final tasks = querySnapshot.docs
          .map((doc) => Task.fromMap(doc.data()))
          .toList();

      // Batch update cache
      final tasksMap = {for (var task in tasks) task.id: task};
      await _cache.taskBox.putAll(tasksMap);
      await _cache.setLastSyncTime(DateTime.now());

      AppLogger.debug(
        'Loaded ${tasks.length} tasks from Firestore',
        tag: _logTag,
      );
      return tasks;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error loading tasks from Firestore',
        tag: _logTag,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
