// task_manager_viewmodel.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task_model.dart';
import '../services/notification_service.dart';

/// Enum to represent the current state of the view.
/// This is cleaner than using multiple boolean flags (e.g., `isLoading`, `hasError`).
enum ViewStatus { loading, success, error }

/// A data class for filtering tasks.
/// Using `@immutable` makes instances of this class unchangeable, which is a good practice.
@immutable
class TaskFilters {
  final Set<Priority> priorities;
  final Set<String> labels;

  const TaskFilters({
    this.priorities = const {},
    this.labels = const {},
  });

  static const TaskFilters empty = TaskFilters();
  bool get hasFilters => priorities.isNotEmpty || labels.isNotEmpty;

  TaskFilters copyWith({
    Set<Priority>? priorities,
    Set<String>? labels,
  }) {
    return TaskFilters(
      priorities: priorities ?? this.priorities,
      labels: labels ?? this.labels,
    );
  }
}

/// Manages the state and business logic for the Task Manager feature.
///
/// This ViewModel handles:
/// - Loading, adding, updating, and deleting tasks from the Hive database.
/// - Managing the view's current state (loading, success, error).
/// - Applying filters to the task list.
/// - Scheduling and canceling task-related notifications.
class TaskManagerViewModel extends ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  late final Box<Task> _tasksBox;

  // --- Private State ---
  List<Task> _allTasks = [];
  ViewStatus _status = ViewStatus.loading;
  String _errorMessage = '';
  TaskFilters _activeFilters = TaskFilters.empty;
  StreamSubscription<BoxEvent>? _boxSubscription;
  Timer? _statusTimer;

  // --- Public Getters ---
  ViewStatus get status => _status;
  String get errorMessage => _errorMessage;
  TaskFilters get activeFilters => _activeFilters;
  Set<String> get allLabels => _allTasks.expand((task) => task.labels).toSet();

  List<Task> get upcomingTasks => _getFilteredTasksByStatus(TaskStatus.upcoming);
  List<Task> get ongoingTasks => _getFilteredTasksByStatus(TaskStatus.ongoing);
  List<Task> get completedTasks => _getFilteredTasksByStatus(TaskStatus.completed);

  TaskManagerViewModel() {
    _init();
  }

  @override
  void dispose() {
    _boxSubscription?.cancel();
    _statusTimer?.cancel();
    super.dispose();
  }

  /// Initializes the ViewModel, opens the Hive box, and sets up listeners.
  Future<void> _init() async {
    try {
      _tasksBox = await Hive.openBox<Task>('tasks');
      _loadTasksFromBox();

      // Listen for any changes in the Hive box and reload the task list.
      _boxSubscription = _tasksBox.watch().listen((_) => _loadTasksFromBox());

      // Periodically check and update the status of ongoing/upcoming tasks.
      _statusTimer = Timer.periodic(
        const Duration(seconds: 10), // Check frequently for responsiveness
            (_) => _updateTaskStatuses(),
      );

      _setStatus(ViewStatus.success);
    } catch (e) {
      _errorMessage = "Failed to initialize the task database. Please restart the app.";
      _setStatus(ViewStatus.error);
      debugPrint("Hive initialization error: $e");
    }
  }

  void _loadTasksFromBox() {
    _allTasks = _tasksBox.values.toList();
    // Sort tasks by due date, then by priority.
    _allTasks.sort((a, b) {
      int dateComp = a.dueDate.compareTo(b.dueDate);
      if (dateComp != 0) return dateComp;
      return b.priority.index.compareTo(a.priority.index); // Higher priority first
    });
    notifyListeners();
  }

  /// Refreshes the task list from the Hive box.
  Future<void> refreshTasks() async {
    try {
      _setStatus(ViewStatus.loading);
      _loadTasksFromBox();
      _setStatus(ViewStatus.success);
    } catch(e) {
      _errorMessage = "Could not refresh tasks.";
      _setStatus(ViewStatus.error);
    }
  }

  /// Adds a new task to the database and schedules notifications.
  Future<void> addTask(Task task) async {
    try {
      final initialStatus = _determineStatusFor(task);
      final int newKey = await _tasksBox.add(task.copyWith(status: initialStatus));
      final newTask = task.copyWith(id: newKey, status: initialStatus);
      await _tasksBox.put(newKey, newTask);
      await _scheduleNotifications(newTask);
    } catch (e) {
      _handleError("Failed to add task.", e);
    }
  }

  /// Updates an existing task in the database and reschedules its notifications.
  Future<void> updateTask(Task task) async {
    try {
      final newStatus = _determineStatusFor(task);
      final updatedTask = task.copyWith(status: newStatus);
      await _tasksBox.put(task.id, updatedTask);
      await _scheduleNotifications(updatedTask);
    } catch (e) {
      _handleError("Failed to update task.", e);
    }
  }

  /// Deletes a task from the database and cancels its notifications.
  Future<void> deleteTask(int taskId) async {
    try {
      await _tasksBox.delete(taskId);
      await _notificationService.cancelTaskNotification(taskId);
      await _notificationService.cancelTaskNotification(_getReminderId(taskId));
    } catch (e) {
      _handleError("Failed to delete task.", e);
    }
  }

  /// Toggles the completion status of a task.
  Future<void> toggleTaskCompletion(Task task) async {
    final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
    await updateTask(updatedTask);
  }

  /// Applies filters and updates the UI.
  void applyFilters(TaskFilters filters) {
    _activeFilters = filters;
    notifyListeners();
  }

  List<Task> getTasksByStatus(TaskStatus status) {
    switch (status) {
      case TaskStatus.upcoming: return upcomingTasks;
      case TaskStatus.ongoing: return ongoingTasks;
      case TaskStatus.completed: return completedTasks;
    }
  }

  // --- Private Helper Methods ---

  List<Task> _getFilteredTasksByStatus(TaskStatus status) {
    final statusFiltered = _allTasks.where((t) => t.status == status).toList();
    if (!_activeFilters.hasFilters) {
      return statusFiltered;
    }
    return statusFiltered.where((task) {
      final priorityMatch = _activeFilters.priorities.isEmpty ||
          _activeFilters.priorities.contains(task.priority);
      final labelMatch = _activeFilters.labels.isEmpty ||
          task.labels.any((label) => _activeFilters.labels.contains(label));
      return priorityMatch && labelMatch;
    }).toList();
  }

  /// Determines a task's status based on its completion state and due date.
  TaskStatus _determineStatusFor(Task task) {
    if (task.isCompleted) {
      return TaskStatus.completed;
    }

    final now = DateTime.now();

    // Logic for tasks with a specific time
    if (task.time != null) {
      final scheduleTime = task.time!;
      if (now.isBefore(scheduleTime)) {
        return TaskStatus.upcoming;
      } else {
        // If the specific time has passed, the task is considered completed.
        return TaskStatus.completed;
      }
    }
    // Logic for all-day tasks (no specific time)
    else {
      final startOfDay = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
      final endOfDay = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day, 23, 59, 59);

      if (now.isBefore(startOfDay)) {
        return TaskStatus.upcoming;
      } else if (now.isAfter(endOfDay)) {
        return TaskStatus.completed;
      } else {
        return TaskStatus.ongoing;
      }
    }
  }

  /// Periodically updates the statuses of tasks (e.g., from 'upcoming' to 'ongoing').
  void _updateTaskStatuses() {
    final Map<dynamic, Task> tasksToUpdate = {};
    for (var task in _allTasks) {
      // Re-evaluate the status of all non-completed tasks.
      if (!task.isCompleted) {
        final newStatus = _determineStatusFor(task);
        if (newStatus != task.status) {
          // If a task's status changes to 'completed' automatically,
          // also update its 'isCompleted' flag.
          if (newStatus == TaskStatus.completed) {
            tasksToUpdate[task.id] = task.copyWith(status: newStatus, isCompleted: true);
          } else {
            tasksToUpdate[task.id] = task.copyWith(status: newStatus);
          }
        }
      }
    }
    if (tasksToUpdate.isNotEmpty) {
      _tasksBox.putAll(tasksToUpdate);
    }
  }

  /// Schedules the main notification and a 15-minute reminder for a task.
  Future<void> _scheduleNotifications(Task task) async {
    if (task.id == null) return;
    await _notificationService.cancelTaskNotification(task.id!);
    await _notificationService.cancelTaskNotification(_getReminderId(task.id!));

    if (!task.isCompleted && task.time != null && task.time!.isAfter(DateTime.now())) {
      await _notificationService.scheduleTaskNotification(task);

      final reminderTime = task.time!.subtract(const Duration(minutes: 15));
      if (reminderTime.isAfter(DateTime.now())) {
        await _notificationService.scheduleTaskNotification(
            task.copyWith(
              id: _getReminderId(task.id!),
              time: () => reminderTime,
              title: 'Reminder: ${task.title}',
            )
        );
      }
    }
  }

  int _getReminderId(int taskId) => taskId + 1000000;

  void _setStatus(ViewStatus newStatus) {
    _status = newStatus;
    notifyListeners();
  }

  void _handleError(String message, Object error) {
    _errorMessage = message;
    _status = ViewStatus.error;
    debugPrint("$message Error: $error");
    notifyListeners();
    // Reset to success to allow user interaction again
    Timer(const Duration(seconds: 2), () => _setStatus(ViewStatus.success));
  }
}

