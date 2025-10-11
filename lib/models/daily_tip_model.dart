// daily_tip_model.dart
import 'package:hive/hive.dart';

part 'daily_tip_model.g.dart';

@HiveType(typeId: 1)
class DailyTip {
  @HiveField(0)
  final String text;

  DailyTip({required this.text});

  factory DailyTip.fromRealtimeDatabase(Map<String, dynamic> data) {
    return DailyTip(text: data['text'] ?? 'Stay focused and keep learning!');
  }

  Map<String, dynamic> toJson() => {'text': text};
}