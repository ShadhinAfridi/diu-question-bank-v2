// daily_tip_model.dart - Updated
import 'package:hive/hive.dart';
// --- FIX: Standardized import path ---
import 'package:diuquestionbank/constants/hive_type_ids.dart';

part 'daily_tip_model.g.dart';

@HiveType(typeId: kDailyTipTypeId)
class DailyTip extends HiveObject {
  @HiveField(0)
  final String text;

  DailyTip({required this.text});

  factory DailyTip.fromRealtimeDatabase(Map<String, dynamic> data) {
    return DailyTip(text: data['text'] ?? 'Stay focused and keep learning!');
  }

  Map<String, dynamic> toJson() => {'text': text};
}