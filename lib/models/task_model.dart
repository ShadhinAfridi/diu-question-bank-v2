// task_model.dart
import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';

part 'task_model.g.dart';

extension EnumDisplay on Enum {
  String get displayName => name[0].toUpperCase() + name.substring(1);
}

@HiveType(typeId: 6)
enum Priority {
  @HiveField(0)
  low,
  @HiveField(1)
  medium,
  @HiveField(2)
  high,
}

@HiveType(typeId: 7)
enum Recurrence {
  @HiveField(0)
  none,
  @HiveField(1)
  daily,
  @HiveField(2)
  weekly,
  @HiveField(3)
  monthly,
}

@HiveType(typeId: 8)
enum TaskStatus {
  @HiveField(0)
  upcoming,
  @HiveField(1)
  ongoing,
  @HiveField(2)
  completed,
}

@HiveType(typeId: 9)
@immutable
class Task extends HiveObject {
  @HiveField(0)
  final int? id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final DateTime dueDate;

  @HiveField(4)
  final Priority priority;

  @HiveField(5)
  final DateTime? time;

  @HiveField(6)
  final List<String> labels;

  @HiveField(7)
  final Recurrence? recurrence;

  @HiveField(8)
  final Duration? estimatedDuration;

  @HiveField(9)
  final List<String> attachments;

  @HiveField(10)
  final bool addToCalendar;

  @HiveField(11)
  final TaskStatus status;

  @HiveField(12)
  final bool isCompleted;

  Task({
    this.id,
    required this.title,
    this.description = '',
    required this.dueDate,
    this.priority = Priority.medium,
    this.time,
    this.labels = const [],
    this.recurrence = Recurrence.none,
    this.estimatedDuration,
    this.attachments = const [],
    this.addToCalendar = false,
    this.status = TaskStatus.upcoming,
    this.isCompleted = false,
  });

  bool get isRecurring => recurrence != null && recurrence != Recurrence.none;

  Task copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? dueDate,
    Priority? priority,
    ValueGetter<DateTime?>? time,
    List<String>? labels,
    ValueGetter<Recurrence?>? recurrence,
    ValueGetter<Duration?>? estimatedDuration,
    List<String>? attachments,
    bool? addToCalendar,
    TaskStatus? status,
    bool? isCompleted,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      time: time != null ? time() : this.time,
      labels: labels ?? this.labels,
      recurrence: recurrence != null ? recurrence() : this.recurrence,
      estimatedDuration: estimatedDuration != null
          ? estimatedDuration()
          : this.estimatedDuration,
      attachments: attachments ?? this.attachments,
      addToCalendar: addToCalendar ?? this.addToCalendar,
      status: status ?? this.status,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
