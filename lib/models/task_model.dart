// task_model.dart - Updated
import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
// --- FIX: Standardized import path ---
import 'package:diuquestionbank/constants/hive_type_ids.dart';

import 'base_model.dart';

part 'task_model.g.dart';

extension EnumDisplay on Enum {
  String get displayName => name[0].toUpperCase() + name.substring(1);
}

@HiveType(typeId: kPriorityTypeId)
enum Priority {
  @HiveField(0)
  low,
  @HiveField(1)
  medium,
  @HiveField(2)
  high,
}

@HiveType(typeId: kRecurrenceTypeId)
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

@HiveType(typeId: kTaskStatusTypeId)
enum TaskStatus {
  @HiveField(0)
  upcoming,
  @HiveField(1)
  ongoing,
  @HiveField(2)
  completed,
}


@HiveType(typeId: kTaskTypeId)
@immutable
class Task extends HiveObject {
  @HiveField(0)
  final String id;

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
  final Recurrence recurrence;

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

  @HiveField(13)
  final DateTime createdAt;

  @HiveField(14)
  final DateTime updatedAt;

  // ADD THIS: Sync status field
  @HiveField(15)
  final SyncStatus syncStatus;

  // ADD THIS: Version field for conflict resolution
  @HiveField(16)
  final int version;

  Task({
    required this.id,
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
    DateTime? createdAt,
    DateTime? updatedAt,
    this.syncStatus = SyncStatus.synced, // ADD THIS: Default sync status
    this.version = 0, // ADD THIS: Default version
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isRecurring => recurrence != Recurrence.none;

  bool get isOverdue => !isCompleted && dueDate.isBefore(DateTime.now());

  bool get hasTime => time != null;

  String get priorityDisplay => priority.displayName;

  String get statusDisplay => status.displayName;

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    Priority? priority,
    DateTime? time,
    List<String>? labels,
    Recurrence? recurrence,
    Duration? estimatedDuration,
    List<String>? attachments,
    bool? addToCalendar,
    TaskStatus? status,
    bool? isCompleted,
    DateTime? updatedAt,
    SyncStatus? syncStatus, // ADD THIS: syncStatus parameter
    int? version, // ADD THIS: version parameter
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      time: time ?? this.time,
      labels: labels ?? this.labels,
      recurrence: recurrence ?? this.recurrence,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      attachments: attachments ?? this.attachments,
      addToCalendar: addToCalendar ?? this.addToCalendar,
      status: status ?? this.status,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt, // Keep original creation date
      updatedAt: updatedAt ?? DateTime.now(),
      syncStatus: syncStatus ?? this.syncStatus, // ADD THIS: Copy syncStatus
      version: version ?? this.version, // ADD THIS: Copy version
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate.millisecondsSinceEpoch,
      'priority': priority.index,
      'time': time?.millisecondsSinceEpoch,
      'labels': labels,
      'recurrence': recurrence.index,
      'estimatedDuration': estimatedDuration?.inMinutes,
      'attachments': attachments,
      'addToCalendar': addToCalendar,
      'status': status.index,
      'isCompleted': isCompleted,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'syncStatus': syncStatus.index, // ADD THIS: Include syncStatus in map
      'version': version, // ADD THIS: Include version in map
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      dueDate: DateTime.fromMillisecondsSinceEpoch(map['dueDate'] as int),
      priority: Priority.values[map['priority'] as int],
      time: map['time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['time'] as int)
          : null,
      labels: List<String>.from(map['labels'] as List),
      recurrence: Recurrence.values[map['recurrence'] as int],
      estimatedDuration: map['estimatedDuration'] != null
          ? Duration(minutes: map['estimatedDuration'] as int)
          : null,
      attachments: List<String>.from(map['attachments'] as List),
      addToCalendar: map['addToCalendar'] as bool,
      status: TaskStatus.values[map['status'] as int],
      isCompleted: map['isCompleted'] as bool,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int),
      syncStatus: SyncStatus.values[map['syncStatus'] as int], // ADD THIS: Parse syncStatus
      version: map['version'] as int, // ADD THIS: Parse version
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Task && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Task(id: $id, title: $title, dueDate: $dueDate, status: $status, isCompleted: $isCompleted, syncStatus: $syncStatus)';
  }
}