// models/question_access.dart - Updated
import 'package:hive/hive.dart';
// --- FIX: Standardized import path ---
import 'package:diuquestionbank/constants/hive_type_ids.dart';

part 'question_access.g.dart';

@HiveType(typeId: kQuestionAccessTypeId)
enum QuestionAccess {
  @HiveField(0)
  free('free'),

  @HiveField(1)
  points('points'),

  @HiveField(2)
  premium('premium'),

  @HiveField(3)
  adRequired('adRequired');

  final String value;
  const QuestionAccess(this.value);

  static QuestionAccess fromValue(String value) {
    return QuestionAccess.values
        .firstWhere((e) => e.value == value, orElse: () => QuestionAccess.free);
  }

  bool get isFree => this == QuestionAccess.free;
  bool get isPoints => this == QuestionAccess.points;
  bool get isPremium => this == QuestionAccess.premium;
  bool get isAdRequired => this == QuestionAccess.adRequired;
}