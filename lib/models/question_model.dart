// question_model.dart - Refactored
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
// --- FIX: Standardized import path ---
import 'package:diuquestionbank/constants/hive_type_ids.dart';
import 'base_model.dart';
import 'cache_mixin.dart'; // Use the mixin
import 'question_access.dart';
import 'question_status.dart';
import 'user_model.dart';

part 'question_model.g.dart';

@HiveType(typeId: kQuestionTypeId)
class Question extends BaseModel with CacheMixin {
  // BaseModel fields (0-4): id, createdAt, updatedAt, syncStatus, version
  // CacheMixin fields (100-102): cacheExpiry, lastAccessed, cacheKey

  @HiveField(5)
  final String courseCode;
  @HiveField(6)
  final String courseName;
  @HiveField(7)
  final String department;
  @HiveField(8)
  final String examType;
  @HiveField(9)
  final String examYear;
  @HiveField(10)
  final String pdfUrl;
  @HiveField(11)
  final String semester;
  @HiveField(12)
  final String teacherName;
  @HiveField(13)
  final QuestionAccess access;
  @HiveField(14)
  final int pointsRequired;
  @HiveField(15)
  final String uploadedBy;
  @HiveField(16)
  final QuestionStatus status;
  @HiveField(17)
  final double rating;
  @HiveField(18)
  final int totalRatings;
  @HiveField(19)
  final int downloadCount;
  @HiveField(20)
  final int viewCount;
  @HiveField(21)
  final String? thumbnailUrl;
  @HiveField(22)
  final String? fileHash;

  Question({
    required String id,
    required this.courseCode,
    required this.courseName,
    required this.department,
    required this.examType,
    required this.examYear,
    required this.pdfUrl,
    required this.semester,
    required this.teacherName,
    required this.uploadedBy,
    this.access = QuestionAccess.free,
    this.pointsRequired = 0,
    this.status = QuestionStatus.unapproved,
    this.rating = 0.0,
    this.totalRatings = 0,
    this.downloadCount = 0,
    this.viewCount = 0,
    this.thumbnailUrl,
    this.fileHash,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncStatus syncStatus = SyncStatus.synced,
    int version = 0,
  }) : super(
    id: id,
    createdAt: createdAt ?? DateTime.now(),
    updatedAt: updatedAt ?? DateTime.now(),
    syncStatus: syncStatus,
    version: version,
  ) {
    // Initialize the cache mixin
    initializeCache(cacheDuration: const Duration(hours: 24));
  }

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
      teacherName: data['teacherName'] ?? '',
      uploadedBy: data['uploadedBy'] ?? '',
      access: QuestionAccess.fromValue(data['access'] ?? 'free'),
      pointsRequired: (data['pointsRequired'] ?? 0).toInt(),
      status: QuestionStatus.fromValue(data['status'] ?? 'unapproved'),
      rating: (data['rating'] ?? 0.0).toDouble(),
      totalRatings: (data['totalRatings'] ?? 0).toInt(),
      downloadCount: (data['downloadCount'] ?? 0).toInt(),
      viewCount: (data['viewCount'] ?? 0).toInt(),
      thumbnailUrl: data['thumbnailUrl'],
      fileHash: data['fileHash'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      version: (data['_version'] ?? 0).toInt(),
      // REFACTORED: Assume synced from Firestore
      syncStatus: SyncStatus.synced,
    );
  }

  @override
  Map<String, dynamic> toFirestore() {
    return {
      'courseCode': courseCode,
      'courseName': courseName,
      'department': department,
      'examType': examType,
      'examYear': examYear,
      'pdfUrl': pdfUrl,
      'semester': semester,
      'teacherName': teacherName,
      'access': access.value,
      'pointsRequired': pointsRequired,
      'uploadedBy': uploadedBy,
      'status': status.value,
      'rating': rating,
      'totalRatings': totalRatings,
      'downloadCount': downloadCount,
      'viewCount': viewCount,
      'thumbnailUrl': thumbnailUrl,
      'fileHash': fileHash,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      '_version': version,
      // Note: We don't save syncStatus or cache mixin fields to Firestore
    };
  }

  bool canAccess(UserModel user) {
    if (user.id == uploadedBy) return true; // Owner can always access
    if (user.isPremium) return true; // Premium users bypass most checks

    switch (access) {
      case QuestionAccess.free:
        return true;
      case QuestionAccess.points:
        return user.hasAccessedQuestion(id) ||
            user.hasEnoughPoints(pointsRequired);
      case QuestionAccess.premium:
        return user.isPremium; // Redundant but explicit
      case QuestionAccess.adRequired:
        return true; // Handled by UI, not by data model
    }
  }

  bool get isPopular => downloadCount > 100 || viewCount > 500;
  bool get isRecent => DateTime.now().difference(createdAt).inDays < 30;

  @override
  Question copyWithVersion(int newVersion) {
    return copyWith(version: newVersion, updatedAt: DateTime.now());
  }

  // REFACTORED: Added copyWithSyncStatus
  Question copyWithSyncStatus(SyncStatus newStatus) {
    return copyWith(syncStatus: newStatus);
  }

  Question incrementView() =>
      copyWith(viewCount: viewCount + 1, syncStatus: SyncStatus.pending);
  Question incrementDownload() =>
      copyWith(downloadCount: downloadCount + 1, syncStatus: SyncStatus.pending);

  // REFACTORED: Was private (_copyWith), now public (copyWith) for use in Impl
  Question copyWith({
    String? courseCode,
    String? courseName,
    String? department,
    String? examType,
    String? examYear,
    String? pdfUrl,
    String? semester,
    String? teacherName,
    QuestionAccess? access,
    int? pointsRequired,
    String? uploadedBy,
    QuestionStatus? status,
    double? rating,
    int? totalRatings,
    int? downloadCount,
    int? viewCount,
    String? thumbnailUrl,
    String? fileHash,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
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
      teacherName: teacherName ?? this.teacherName,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      access: access ?? this.access,
      pointsRequired: pointsRequired ?? this.pointsRequired,
      status: status ?? this.status,
      rating: rating ?? this.rating,
      totalRatings: totalRatings ?? this.totalRatings,
      downloadCount: downloadCount ?? this.downloadCount,
      viewCount: viewCount ?? this.viewCount,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      fileHash: fileHash ?? this.fileHash,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt, // Don't default to DateTime.now()
      version: version ?? this.version,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}