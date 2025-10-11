// models/question_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

part 'question_model.g.dart';

@HiveType(typeId: 4)
class Question {
  @HiveField(0)
  String id;

  @HiveField(1)
  final String courseCode;

  @HiveField(2)
  final String courseName;

  @HiveField(3)
  final String department;

  @HiveField(4)
  final String examType;

  @HiveField(5)
  final String examYear;

  @HiveField(6)
  final String pdfUrl;

  @HiveField(7)
  final String semester;

  @HiveField(8)
  final Timestamp processedAt;

  // NEW: Fields for caching support
  @HiveField(9)
  final DateTime? cacheUpdatedAt;

  @HiveField(10)
  final int version; // For conflict resolution

  Question({
    required this.id,
    required this.courseCode,
    required this.courseName,
    required this.department,
    required this.examType,
    required this.examYear,
    required this.pdfUrl,
    required this.semester,
    required this.processedAt,
    this.cacheUpdatedAt,
    this.version = 1,
  });

  factory Question.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Question(
      id: doc.id,
      courseCode: data['courseCode'] ?? '',
      courseName: data['courseName'] ?? '',
      department: data['department'] ?? '',
      examType: data['examType'] ?? '',
      examYear: data['examYear'] ?? '',
      pdfUrl: data['pdfUrl'] ?? '',
      semester: data['semester'] ?? '',
      processedAt: data['processedAt'] ?? Timestamp.now(),
      cacheUpdatedAt: DateTime.now(),
      version: (data['version'] ?? 1) as int,
    );
  }

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      courseCode: json['courseCode'],
      courseName: json['courseName'],
      department: json['department'],
      examType: json['examType'],
      examYear: json['examYear'],
      pdfUrl: json['pdfUrl'],
      semester: json['semester'],
      processedAt: Timestamp.fromMillisecondsSinceEpoch(json['processedAt']),
      cacheUpdatedAt: json['cacheUpdatedAt'] != null
          ? DateTime.parse(json['cacheUpdatedAt'])
          : null,
      version: json['version'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'courseCode': courseCode,
    'courseName': courseName,
    'department': department,
    'examType': examType,
    'examYear': examYear,
    'pdfUrl': pdfUrl,
    'semester': semester,
    'processedAt': processedAt.millisecondsSinceEpoch,
    'cacheUpdatedAt': cacheUpdatedAt?.toIso8601String(),
    'version': version,
  };

  // Copy with method for updates
  Question copyWith({
    String? courseCode,
    String? courseName,
    String? department,
    String? examType,
    String? examYear,
    String? pdfUrl,
    String? semester,
    Timestamp? processedAt,
    int? version,
  }) {
    return Question(
      id: id,
      courseCode: courseCode ?? this.courseCode,
      courseName: courseName ?? this.courseName,
      department: department ?? this.department,
      examType: examType ?? this.examType,
      examYear: examYear ?? this.examYear,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      semester: semester ?? this.semester,
      processedAt: processedAt ?? this.processedAt,
      cacheUpdatedAt: DateTime.now(),
      version: version ?? this.version + 1,
    );
  }

  String get formattedDate {
    return DateFormat('dd MMM, yyyy').format(processedAt.toDate());
  }

  String get examIdentifier => '$examType $examYear';

  // For caching comparison
  bool isNewerThan(Question other) {
    return version > other.version;
  }
}