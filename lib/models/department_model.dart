// department_model.dart
import 'package:hive/hive.dart';

part 'department_model.g.dart';

@HiveType(typeId: 2)
class Department {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  Department({required this.id, required this.name});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Department && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}