// department_model.dart - Updated
import 'package:hive/hive.dart';
// --- FIX: Standardized import path ---
import 'package:diuquestionbank/constants/hive_type_ids.dart';

part 'department_model.g.dart';

@HiveType(typeId: kDepartmentTypeId)
class Department extends HiveObject {
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