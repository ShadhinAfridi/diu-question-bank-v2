// question_filter.dart
import 'package:hive/hive.dart';

part 'question_filter.g.dart';

@HiveType(typeId: 3)
enum QuestionFilter {
  @HiveField(0)
  midterm('Midterm'),

  @HiveField(1)
  finalExam('Final');

  final String displayName;
  const QuestionFilter(this.displayName);
}