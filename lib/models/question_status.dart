// models/question_status.dart - Updated
import 'package:hive/hive.dart';
// --- FIX: Standardized import path ---
import 'package:diuquestionbank/constants/hive_type_ids.dart';

part 'question_status.g.dart';

@HiveType(typeId: kQuestionStatusTypeId)
enum QuestionStatus {
  @HiveField(0)
  unapproved('unapproved'),

  @HiveField(1)
  approved('approved'),

  @HiveField(2)
  rejected('rejected');

  final String value;
  const QuestionStatus(this.value);

  static QuestionStatus fromValue(String value) {
    return QuestionStatus.values.firstWhere((e) => e.value == value,
        orElse: () => QuestionStatus.unapproved);
  }

  bool get isApproved => this == QuestionStatus.approved;
  bool get isUnapproved => this == QuestionStatus.unapproved;
  bool get isRejected => this == QuestionStatus.rejected;
}