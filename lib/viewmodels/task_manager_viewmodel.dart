import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:hive/hive.dart'; // No longer needed

import '../models/task_model.dart';
// import '../providers/cache_providers.dart'; // No longer needed
import '../providers/repository_providers.dart'; // --- FIX: Import Repository Provider ---
import '../providers/service_providers.dart';
import '../repositories/interfaces/task_repository.dart'; // --- FIX: Import Repository Interface ---
import '../services/notification_service.dart';
import '../utils/view_status.dart';
import 'base_viewmodel.dart';

@immutable
class TaskFilters {
  final Set<Priority> priorities;
  final Set<String> labels;
  final bool showCompleted;
  final bool showOverdue;

  const TaskFilters({
    this.priorities = const {},
    this.labels = const {},
    this.showCompleted = true,
    this.showOverdue = true,
  });

  static const TaskFilters empty = TaskFilters();
  bool get hasFilters =>
      priorities.isNotEmpty ||
          labels.isNotEmpty ||
          !showCompleted ||
          !showOverdue;

  TaskFilters copyWith({
    Set<Priority>? priorities,
    Set<String>? labels,
    bool? showCompleted,
    bool? showOverdue,
  }) {
    return TaskFilters(
      priorities: priorities ?? this.priorities,
      labels: labels ?? this.labels,
      showCompleted: showCompleted ?? this.showCompleted,
      showOverdue: showOverdue ?? this.showOverdue,
    );
  }
}

class TaskManagerViewModel extends BaseViewModel {
  final NotificationService _notificationService;
  // --- FIX: Use ITaskRepository instead of Box<Task> ---
  final ITaskRepository _taskRepository;

  List<Task> _allTasks = [];
  ViewStatus _status = ViewStatus.loading;
  String _errorMessage = '';
  TaskFilters _activeFilters = TaskFilters.empty;
  // --- FIX: Use StreamSubscription<List<Task>> ---
  StreamSubscription<List<Task>>? _taskSubscription;
  Timer? _statusTimer;
  bool _isLoading = false;

  ViewStatus get status => _status;
  String get errorMessage => _errorMessage;
  TaskFilters get activeFilters => _activeFilters;
  bool get isLoading => _isLoading;
  Set<String> get allLabels => _allTasks.expand((task) => task.labels).toSet();
  int get totalTasks => _allTasks.length;
  int get completedTasksCount =>
      _allTasks.where((task) => task.isCompleted).length;
  int get overdueTasksCount => _allTasks.where((task) => task.isOverdue).length;

  List<Task> get upcomingTasks => _getFilteredTasksByStatus(TaskStatus.upcoming);
  List<Task> get ongoingTasks => _getFilteredTasksByStatus(TaskStatus.ongoing);
  List<Task> get completedTasks =>
      _getFilteredTasksByStatus(TaskStatus.completed);
  List<Task> get overdueTasks =>
      _allTasks.where((task) => task.isOverdue).toList();

  // Constructor now accepts Ref and uses it to get dependencies
  TaskManagerViewModel(Ref ref)
      : _notificationService = ref.watch(notificationServiceProvider),
  // --- FIX: Watch the repository provider ---
        _taskRepository = ref.watch(taskRepositoryProvider) {
    _init();
  }

  @override
  void dispose() {
    _taskSubscription?.cancel();
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      // --- FIX: Load from repository and set up repository listener ---
      await _loadTasksFromRepository();
      _setupRepositoryListener();
      _startStatusUpdater();
      _updateViewStatus();
    } catch (e) {
      _handleError("Failed to initialize the task database.", e);
    }
  }

  // --- FIX: Listen to the repository stream ---
  void _setupRepositoryListener() {
    _taskSubscription = _taskRepository.watchAll().listen((tasks) {
      // This stream provides the full list from the cache
      _allTasks = tasks;
      _sortTasks();
      _updateViewStatus();
      notifyListeners();
    }, onError: (e) {
      _handleError("Failed to listen to task updates.", e);
    });
    // Add subscription to BaseViewModel for automatic disposal
    addSubscription(_taskSubscription!);
  }

  void _startStatusUpdater() {
    _statusTimer = Timer.periodic(
      const Duration(minutes: 1), // Check every minute
          (_) => _updateTaskStatuses(),
    );
    // Add timer to BaseViewModel for automatic disposal
    addTimer(_statusTimer!);
  }

  // --- FIX: Load from repository ---
  Future<void> _loadTasksFromRepository() async {
    try {
      _allTasks = await _taskRepository.getAll(); // This will hit cache or remote
      _sortTasks();
      _updateViewStatus();
      notifyListeners();
    } catch (e) {
      _handleError("Failed to load tasks from repository.", e);
    }
  }

  void _sortTasks() {
    _allTasks.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      int dateComp = a.dueDate.compareTo(b.dueDate);
      if (dateComp != 0) return dateComp;
      return b.priority.index.compareTo(a.priority.index);
    });
  }

  void _updateViewStatus() {
    if (_allTasks.isEmpty) {
      _setStatus(ViewStatus.empty);
    } else {
      _setStatus(ViewStatus.success);
    }
  }

  Future<void> refreshTasks() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      // --- FIX: Call syncWithRemote ---
      await _taskRepository.syncWithRemote();
      // The watcher will update the list, but we'll force a load
      // to ensure UI updates if the watcher is slow.
      await _loadTasksFromRepository();
      _setStatus(ViewStatus.success);
    } catch (e) {
      _handleError("Could not refresh tasks.", e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTask(Task task) async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      final initialStatus = _determineStatusFor(task);
      final taskWithStatus = task.copyWith(status: initialStatus);
      final String taskId = task.id.isEmpty
          ? DateTime.now().millisecondsSinceEpoch.toString()
          : task.id;
      final taskWithId = taskWithStatus.copyWith(id: taskId);
      // --- FIX: Use repository ---
      await _taskRepository.save(taskWithId);
      await _scheduleNotifications(taskWithId);
      debugPrint('✅ Task added: ${taskWithId.title}');
    } catch (e) {
      _handleError("Failed to add task.", e);
    } finally {
      _isLoading = false;
      // No need to notify, watcher will catch the change
    }
  }

  Future<void> updateTask(Task task) async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      final newStatus = _determineStatusFor(task);
      final updatedTask = task.copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
      );
      // --- FIX: Use repository ---
      await _taskRepository.save(updatedTask);
      await _scheduleNotifications(updatedTask);
      debugPrint('✅ Task updated: ${updatedTask.title}');
    } catch (e) {
      _handleError("Failed to update task.", e);
    } finally {
      _isLoading = false;
      // No need to notify, watcher will catch the change
    }
  }

  Future<void> deleteTask(String taskId) async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      // --- FIX: Use repository ---
      await _taskRepository.delete(taskId);
      await _cancelTaskNotifications(taskId);
      debugPrint('🗑️ Task deleted: $taskId');
    } catch (e) {
      _handleError("Failed to delete task.", e);
    } finally {
      _isLoading = false;
      // No need to notify, watcher will catch the change
    }
  }

  Future<void> toggleTaskCompletion(Task task) async {
    final updatedTask = task.copyWith(
      isCompleted: !task.isCompleted,
      status: !task.isCompleted
          ? TaskStatus.completed
          : _determineStatusFor(task),
      updatedAt: DateTime.now(),
    );
    await updateTask(updatedTask);
  }

  Future<void> completeTask(Task task) async {
    final updatedTask = task.copyWith(
      isCompleted: true,
      status: TaskStatus.completed,
      updatedAt: DateTime.now(),
    );
    await updateTask(updatedTask);
  }

  Future<void> uncompleteTask(Task task) async {
    final newStatus = _determineStatusFor(task);
    final updatedTask = task.copyWith(
      isCompleted: false,
      status: newStatus,
      updatedAt: DateTime.now(),
    );
    await updateTask(updatedTask);
  }

  void applyFilters(TaskFilters filters) {
    _activeFilters = filters;
    notifyListeners();
  }

  void clearFilters() {
    _activeFilters = TaskFilters.empty;
    notifyListeners();
  }

  List<Task> getTasksByStatus(TaskStatus status) {
    switch (status) {
      case TaskStatus.upcoming:
        return upcomingTasks;
      case TaskStatus.ongoing:
        return ongoingTasks;
      case TaskStatus.completed:
        return completedTasks;
    }
  }

  List<Task> searchTasks(String query) {
    if (query.isEmpty) return _allTasks;
    final lowercaseQuery = query.toLowerCase();
    return _allTasks.where((task) {
      return task.title.toLowerCase().contains(lowercaseQuery) ||
          task.description.toLowerCase().contains(lowercaseQuery) ||
          task.labels
              .any((label) => label.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  List<Task> _getFilteredTasksByStatus(TaskStatus status) {
    var filteredTasks =
    _allTasks.where((task) => task.status == status).toList();
    if (!_activeFilters.hasFilters) {
      return filteredTasks;
    }
    return filteredTasks.where((task) {
      final priorityMatch = _activeFilters.priorities.isEmpty ||
          _activeFilters.priorities.contains(task.priority);
      final labelMatch = _activeFilters.labels.isEmpty ||
          task.labels.any((label) => _activeFilters.labels.contains(label));
      final completedMatch = _activeFilters.showCompleted || !task.isCompleted;
      final overdueMatch = _activeFilters.showOverdue || !task.isOverdue;
      return priorityMatch && labelMatch && completedMatch && overdueMatch;
    }).toList();
  }

  TaskStatus _determineStatusFor(Task task) {
    if (task.isCompleted) {
      return TaskStatus.completed;
    }
    final now = DateTime.now();
    final taskDateTime = task.time ?? task.dueDate;
    if (now.isBefore(taskDateTime)) {
      return TaskStatus.upcoming;
    } else {
      final endOfDay = DateTime(
          task.dueDate.year, task.dueDate.month, task.dueDate.day, 23, 59, 59);
      if (now.isAfter(endOfDay)) {
        // --- FIX: If it's after end of due day and not complete, it's still ongoing/overdue
        // Let's call it ongoing, and let `isOverdue` handle the visual state.
        return TaskStatus.ongoing;
      } else {
        return TaskStatus.ongoing;
      }
    }
  }

  void _updateTaskStatuses() async {
    final Map<String, Task> tasksToUpdate = {};
    for (var task in _allTasks) {
      if (!task.isCompleted) {
        final newStatus = _determineStatusFor(task);
        if (newStatus != task.status) {
          tasksToUpdate[task.id] = task.copyWith(
            status: newStatus,
            updatedAt: DateTime.now(),
          );
        }
      }
    }
    if (tasksToUpdate.isNotEmpty) {
      // --- FIX: Save all updated tasks via the repository ---
      try {
        final List<Future<void>> updateFutures = [];
        for (final task in tasksToUpdate.values) {
          updateFutures.add(_taskRepository.save(task));
        }
        await Future.wait(updateFutures);
        debugPrint('🔄 Updated statuses for ${tasksToUpdate.length} tasks');
      } catch (e) {
        _handleError("Failed to update task statuses.", e);
      }
      // The watcher will handle notifying listeners
    }
  }

  Future<void> _scheduleNotifications(Task task) async {
    if (task.isCompleted) {
      await _cancelTaskNotifications(task.id);
      return;
    }
    try {
      await _cancelTaskNotifications(task.id);
      if (task.time != null && task.time!.isAfter(DateTime.now())) {
        await _notificationService.scheduleTaskNotification(task);
        final reminderTime = task.time!.subtract(const Duration(minutes: 15));
        if (reminderTime.isAfter(DateTime.now())) {
          final reminderTask = task.copyWith(
            time: reminderTime,
            title: 'Reminder: ${task.title}',
            // --- FIX: Use a different ID for the reminder notification ---
            id: 'reminder_${task.id}',
          );
          await _notificationService.scheduleTaskNotification(reminderTask);
        }
      }
    } catch (e) {
      debugPrint('❌ Error scheduling notifications for task ${task.id}: $e');
    }
  }

  Future<void> _cancelTaskNotifications(String taskId) async {
    try {
      // --- FIX: Use the same logic as _generateNumericIdFromString ---
      // We must cancel both the main task ID and the reminder ID
      final mainNotificationId = _generateNumericIdFromString(taskId);
      final reminderNotificationId = _generateNumericIdFromString('reminder_$taskId');

      await _notificationService.cancelNotification(mainNotificationId);
      await _notificationService.cancelNotification(reminderNotificationId);
    } catch (e) {
      debugPrint('❌ Error cancelling notifications for task $taskId: $e');
    }
  }

  // --- FIX: Need to import the ID generator from notification_service ---
  // This is a stand-in. Ideally, this logic would be shared.
  int _generateNumericIdFromString(String id) {
    try {
      final bytes = utf8.encode(id);
      int hash = 0;
      for (final byte in bytes) {
        hash = (31 * hash + byte) & 0xFFFFFFFF;
      }
      if (hash > 0x7FFFFFFF) {
        hash = hash - 0x100000000;
      }
      return hash;
    } catch (e) {
      return id.hashCode & 0x7FFFFFFF;
    }
  }
  // --- End ID generator ---

  void _setStatus(ViewStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      notifyListeners();
    }
  }

  void _handleError(String message, Object error) {
    _errorMessage = '$message ${error.toString()}';
    _status = ViewStatus.error;
    _isLoading = false;
    debugPrint("❌ $message Error: $error");
    notifyListeners();
    Timer(const Duration(seconds: 5), () {
      if (_status == ViewStatus.error) {
        _setStatus(_allTasks.isEmpty ? ViewStatus.empty : ViewStatus.success);
        _errorMessage = '';
      }
    });
  }

  void clearError() {
    if (_status == ViewStatus.error) {
      _errorMessage = '';
      _setStatus(_allTasks.isEmpty ? ViewStatus.empty : ViewStatus.success);
    }
  }
}