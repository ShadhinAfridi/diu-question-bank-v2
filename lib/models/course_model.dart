// course_model.dart
import 'package:hive/hive.dart';

part 'course_model.g.dart';

@HiveType(typeId: 0)
class Course {
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