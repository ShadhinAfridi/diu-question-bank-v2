// hive_adapters.dart
import 'package:hive/hive.dart';
import 'package:diuquestionbank/models/base_model.dart';
import 'package:diuquestionbank/models/course_model.dart';
import 'package:diuquestionbank/models/daily_tip_model.dart';
import 'package:diuquestionbank/models/department_model.dart';
import 'package:diuquestionbank/models/notification_model.dart';
import 'package:diuquestionbank/models/point_transaction_model.dart';
import 'package:diuquestionbank/models/question_access.dart';
import 'package:diuquestionbank/models/question_filter.dart';
import 'package:diuquestionbank/models/question_model.dart';
import 'package:diuquestionbank/models/question_status.dart';
import 'package:diuquestionbank/models/slider_model.dart';
import 'package:diuquestionbank/models/subscription_model.dart';
import 'package:diuquestionbank/models/task_model.dart';
import 'package:diuquestionbank/models/timestamp_adapter.dart';
import 'package:diuquestionbank/models/user_model.dart';
import 'package:diuquestionbank/constants/hive_type_ids.dart';

/// Custom TypeAdapter for SyncStatus enum - ADD THIS
class SyncStatusAdapter extends TypeAdapter<SyncStatus> {
  @override
  final int typeId = kSyncStatusTypeId;

  @override
  SyncStatus read(BinaryReader reader) {
    final index = reader.readInt();
    return SyncStatus.values[index];
  }

  @override
  void write(BinaryWriter writer, SyncStatus obj) {
    writer.writeInt(obj.index);
  }
}

/// Custom TypeAdapter for the Duration class.
class DurationAdapter extends TypeAdapter<Duration> {
  @override
  final int typeId = kDurationAdapterId;

  @override
  Duration read(BinaryReader reader) {
    final microseconds = reader.readInt();
    return Duration(microseconds: microseconds);
  }

  @override
  void write(BinaryWriter writer, Duration obj) {
    writer.writeInt(obj.inMicroseconds);
  }
}

/// Custom TypeAdapter for NotificationType enum
class NotificationTypeAdapter extends TypeAdapter<NotificationType> {
  @override
  final int typeId = kNotificationTypeAdapterId;

  @override
  NotificationType read(BinaryReader reader) {
    final index = reader.readInt();
    return NotificationType.values[index];
  }

  @override
  void write(BinaryWriter writer, NotificationType obj) {
    writer.writeInt(obj.index);
  }
}

/// Custom TypeAdapter for SliderType enum
class SliderTypeAdapter extends TypeAdapter<SliderType> {
  @override
  final int typeId = kSliderTypeTypeId;

  @override
  SliderType read(BinaryReader reader) {
    final index = reader.readInt();
    return SliderType.values[index];
  }

  @override
  void write(BinaryWriter writer, SliderType obj) {
    writer.writeInt(obj.index);
  }
}

/// Custom TypeAdapter for SliderActionType enum
class SliderActionTypeAdapter extends TypeAdapter<SliderActionType> {
  @override
  final int typeId = kSliderActionTypeTypeId;

  @override
  SliderActionType read(BinaryReader reader) {
    final index = reader.readInt();
    return SliderActionType.values[index];
  }

  @override
  void write(BinaryWriter writer, SliderActionType obj) {
    writer.writeInt(obj.index);
  }
}

/// Registers all the necessary Hive TypeAdapters for the application.
void registerHiveAdapters() {
  // Base Models & Core Types
  if (!Hive.isAdapterRegistered(TimestampAdapter().typeId)) {
    Hive.registerAdapter(TimestampAdapter());
  }
  if (!Hive.isAdapterRegistered(DurationAdapter().typeId)) {
    Hive.registerAdapter(DurationAdapter());
  }

  // ADD THIS - Register SyncStatus adapter
  if (!Hive.isAdapterRegistered(SyncStatusAdapter().typeId)) {
    Hive.registerAdapter(SyncStatusAdapter());
  }

  // Question & Course Related
  if (!Hive.isAdapterRegistered(CourseAdapter().typeId)) {
    Hive.registerAdapter(CourseAdapter());
  }
  if (!Hive.isAdapterRegistered(DepartmentAdapter().typeId)) {
    Hive.registerAdapter(DepartmentAdapter());
  }
  if (!Hive.isAdapterRegistered(QuestionFilterAdapter().typeId)) {
    Hive.registerAdapter(QuestionFilterAdapter());
  }
  if (!Hive.isAdapterRegistered(QuestionAdapter().typeId)) {
    Hive.registerAdapter(QuestionAdapter());
  }
  if (!Hive.isAdapterRegistered(QuestionAccessAdapter().typeId)) {
    Hive.registerAdapter(QuestionAccessAdapter());
  }
  if (!Hive.isAdapterRegistered(QuestionStatusAdapter().typeId)) {
    Hive.registerAdapter(QuestionStatusAdapter());
  }

  // User & Monetization
  if (!Hive.isAdapterRegistered(UserModelAdapter().typeId)) {
    Hive.registerAdapter(UserModelAdapter());
  }
  if (!Hive.isAdapterRegistered(SubscriptionAdapter().typeId)) {
    Hive.registerAdapter(SubscriptionAdapter());
  }
  if (!Hive.isAdapterRegistered(PointTransactionAdapter().typeId)) {
    Hive.registerAdapter(PointTransactionAdapter());
  }

  // UI & Content
  if (!Hive.isAdapterRegistered(DailyTipAdapter().typeId)) {
    Hive.registerAdapter(DailyTipAdapter());
  }
  if (!Hive.isAdapterRegistered(SliderItemAdapter().typeId)) {
    Hive.registerAdapter(SliderItemAdapter());
  }

  // Register new SliderModel adapters
  if (!Hive.isAdapterRegistered(SliderTypeAdapter().typeId)) {
    Hive.registerAdapter(SliderTypeAdapter());
  }
  if (!Hive.isAdapterRegistered(SliderActionTypeAdapter().typeId)) {
    Hive.registerAdapter(SliderActionTypeAdapter());
  }

  // Task Management
  if (!Hive.isAdapterRegistered(TaskAdapter().typeId)) {
    Hive.registerAdapter(TaskAdapter());
  }
  if (!Hive.isAdapterRegistered(PriorityAdapter().typeId)) {
    Hive.registerAdapter(PriorityAdapter());
  }
  if (!Hive.isAdapterRegistered(RecurrenceAdapter().typeId)) {
    Hive.registerAdapter(RecurrenceAdapter());
  }
  if (!Hive.isAdapterRegistered(TaskStatusAdapter().typeId)) {
    Hive.registerAdapter(TaskStatusAdapter());
  }

  // Notifications
  if (!Hive.isAdapterRegistered(NotificationSettingsAdapter().typeId)) {
    Hive.registerAdapter(NotificationSettingsAdapter());
  }
  if (!Hive.isAdapterRegistered(AppNotificationAdapter().typeId)) {
    Hive.registerAdapter(AppNotificationAdapter());
  }
  if (!Hive.isAdapterRegistered(NotificationTypeAdapter().typeId)) {
    Hive.registerAdapter(NotificationTypeAdapter());
  }
}