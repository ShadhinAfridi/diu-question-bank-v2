// question_filter.dart - Updated
import 'package:hive/hive.dart';
// --- FIX: Standardized import path ---
import 'package:diuquestionbank/constants/hive_type_ids.dart';

part 'question_filter.g.dart';

@HiveType(typeId: kQuestionFilterTypeId)
enum QuestionFilter {
  @HiveField(0)
  midterm('Midterm'),

  @HiveField(1)
  finalExam('Final');

  final String displayName;
  const QuestionFilter(this.displayName);
}