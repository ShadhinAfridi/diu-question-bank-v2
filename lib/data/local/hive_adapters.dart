import 'package:diuquestionbank/models/notification_model.dart';
import 'package:hive/hive.dart';

import '../../models/course_model.dart';
import '../../models/daily_tip_model.dart';
import '../../models/department_model.dart';
import '../../models/question_filter.dart';
import '../../models/question_model.dart';
import '../../models/slider_model.dart';
import '../../models/task_model.dart';
import '../../models/timestamp_adapter.dart';

// FIX: Added the custom DurationAdapter to handle the 'Duration' type.
/// Custom TypeAdapter for the Duration class.
/// Hive does not support Duration out of the box, so we convert it
/// to an integer (microseconds) for storage and back.
class DurationAdapter extends TypeAdapter<Duration> {
  @override
  final int typeId = 100; // Using a unique, unused typeId for this adapter

  @override
  Duration read(BinaryReader reader) {
    // When reading from the database, convert the integer back to a Duration.
    final microseconds = reader.readInt();
    return Duration(microseconds: microseconds);
  }

  @override
  void write(BinaryWriter writer, Duration obj) {
    // When writing to the database, store the Duration as an integer.
    writer.writeInt(obj.inMicroseconds);
  }
}


/// Registers all the necessary Hive TypeAdapters for the application.
///
/// It's crucial that every custom object stored in a Hive box has a
/// corresponding adapter registered here before any boxes are opened.
void registerHiveAdapters() {
  // It's good practice to check if an adapter is already registered
  // to prevent errors during hot reloads.
  if (!Hive.isAdapterRegistered(CourseAdapter().typeId)) {
    Hive.registerAdapter(CourseAdapter());
  }
  if (!Hive.isAdapterRegistered(DailyTipAdapter().typeId)) {
    Hive.registerAdapter(DailyTipAdapter());
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
  if (!Hive.isAdapterRegistered(SliderItemAdapter().typeId)) {
    Hive.registerAdapter(SliderItemAdapter());
  }
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
  if (!Hive.isAdapterRegistered(NotificationSettingsAdapter().typeId)) {
    Hive.registerAdapter(NotificationSettingsAdapter());
  }
  if (!Hive.isAdapterRegistered(TimestampAdapter().typeId)) {
    Hive.registerAdapter(TimestampAdapter());
  }
  if (!Hive.isAdapterRegistered(DurationAdapter().typeId)) {
    Hive.registerAdapter(DurationAdapter());
  }
  if (!Hive.isAdapterRegistered(AppNotificationAdapter().typeId)) {
    Hive.registerAdapter(AppNotificationAdapter());
  }
}
