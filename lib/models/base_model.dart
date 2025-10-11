// models/base_model.dart
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

@HiveType(typeId: 1000) // Use a high typeId to avoid conflicts
abstract class BaseModel extends HiveObject with EquatableMixin {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime createdAt;

  @HiveField(2)
  final DateTime updatedAt;

  @HiveField(3)
  final String? syncStatus; // 'synced', 'pending', 'error'

  BaseModel({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = 'synced',
  });

  Map<String, dynamic> toFirestore();

  @override
  List<Object?> get props => [id];
}