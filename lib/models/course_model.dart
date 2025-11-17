// course_model.dart - Updated
import 'package:hive/hive.dart';
// --- FIX: Standardized import path ---
import 'package:diuquestionbank/constants/hive_type_ids.dart';

part 'course_model.g.dart';

@HiveType(typeId: kCourseTypeId)
class Course extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String code;

  Course({required this.name, required this.code});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Course &&
              runtimeType == other.runtimeType &&
              code == other.code;

  @override
  int get hashCode => code.hashCode;
}