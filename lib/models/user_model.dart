// models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

// --- FIX: Standardized import path ---
import 'package:diuquestionbank/constants/hive_type_ids.dart';
import 'base_model.dart';
import 'cache_mixin.dart';
import 'subscription_model.dart';

part 'user_model.g.dart';

@HiveType(typeId: kUserModelTypeId)
class UserModel extends BaseModel with CacheMixin {
  // BaseModel fields (0-4): id, createdAt, updatedAt, syncStatus, version
  // CacheMixin fields (100-102): cacheExpiry, lastAccessed, cacheKey

  @HiveField(5)
  final String name;

  @HiveField(6)
  final String email;

  @HiveField(7)
  final String? phone;

  @HiveField(8)
  final String? profilePictureUrl;

  @HiveField(9)
  final String? department;

  @HiveField(10)
  final int points;

  @HiveField(11)
  final int level;

  @HiveField(12)
  final int totalAdsWatched;

  @HiveField(13)
  final List<String> uploadedQuestions;

  @HiveField(14)
  final List<String> accessedQuestions;

  @HiveField(15)
  final Subscription? subscription;

  @HiveField(16)
  final Map<String, dynamic> preferences;

  @HiveField(17)
  final DateTime? lastLogin;

  @HiveField(18)
  final bool isEmailVerified;

  @HiveField(19)
  final String? fcmToken;

  UserModel({
    required String id,
    required this.name,
    required this.email,
    this.phone,
    this.profilePictureUrl,
    this.department,
    this.points = 0,
    this.level = 1,
    this.totalAdsWatched = 0,
    this.uploadedQuestions = const [],
    this.accessedQuestions = const [],
    this.subscription,
    this.preferences = const {},
    this.lastLogin,
    this.isEmailVerified = false,
    this.fcmToken,
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
    initializeCache(cacheDuration: const Duration(hours: 12));
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserModel(
      id: doc.id,
      name: data['name'] ?? 'Unknown User',
      email: data['email'] ?? '',
      phone: data['phone'],
      profilePictureUrl: data['profilePictureUrl'],
      department: data['department'],
      points: (data['points'] ?? 0).toInt(),
      level: (data['level'] ?? 1).toInt(),
      totalAdsWatched: (data['totalAdsWatched'] ?? 0).toInt(),
      uploadedQuestions: List<String>.from(data['uploadedQuestions'] ?? []),
      accessedQuestions: List<String>.from(data['accessedQuestions'] ?? []),
      subscription: data['subscription'] != null
          ? Subscription.fromMap(Map<String, dynamic>.from(data['subscription']))
          : null,
      preferences: Map<String, dynamic>.from(data['preferences'] ?? {}),
      lastLogin: (data['lastLogin'] as Timestamp?)?.toDate(),
      isEmailVerified: data['isEmailVerified'] ?? false,
      fcmToken: data['fcmToken'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      version: (data['_version'] ?? 0).toInt(),
    );
  }

  @override
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'profilePictureUrl': profilePictureUrl,
      'department': department,
      'points': points,
      'level': level,
      'totalAdsWatched': totalAdsWatched,
      'uploadedQuestions': uploadedQuestions,
      'accessedQuestions': accessedQuestions,
      'subscription': subscription?.toMap(),
      'preferences': preferences,
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      'isEmailVerified': isEmailVerified,
      'fcmToken': fcmToken,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      '_version': version,
    };
  }

  // Computed properties
  bool get isPremium => subscription?.isValid ?? false;

  double get levelProgress {
    const pointsPerLevel = 1000;
    final currentLevelPoints = points % pointsPerLevel;
    return currentLevelPoints / pointsPerLevel;
  }

  bool hasEnoughPoints(int requiredPoints) => points >= requiredPoints;

  bool hasUploadedQuestion(String questionId) =>
      uploadedQuestions.contains(questionId);

  bool hasAccessedQuestion(String questionId) =>
      accessedQuestions.contains(questionId);

  int get totalUploads => uploadedQuestions.length;

  int get totalAccesses => accessedQuestions.length;

  // Copy with method
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? profilePictureUrl,
    String? department,
    int? points,
    int? level,
    int? totalAdsWatched,
    List<String>? uploadedQuestions,
    List<String>? accessedQuestions,
    Subscription? subscription,
    Map<String, dynamic>? preferences,
    DateTime? lastLogin,
    bool? isEmailVerified,
    String? fcmToken,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
    int? version,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      department: department ?? this.department,
      points: points ?? this.points,
      level: level ?? this.level,
      totalAdsWatched: totalAdsWatched ?? this.totalAdsWatched,
      uploadedQuestions: uploadedQuestions ?? this.uploadedQuestions,
      accessedQuestions: accessedQuestions ?? this.accessedQuestions,
      subscription: subscription ?? this.subscription,
      preferences: preferences ?? this.preferences,
      lastLogin: lastLogin ?? this.lastLogin,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      version: version ?? this.version,
    );
  }

  @override
  UserModel copyWithVersion(int newVersion) {
    return copyWith(
      version: newVersion,
      updatedAt: DateTime.now(),
    );
  }

  // Utility methods
  UserModel addPoints(int pointsToAdd) {
    return copyWith(points: points + pointsToAdd);
  }

  UserModel levelUp() {
    return copyWith(level: level + 1);
  }

  UserModel addUploadedQuestion(String questionId) {
    final newUploadedQuestions = List<String>.from(uploadedQuestions)
      ..add(questionId);
    return copyWith(uploadedQuestions: newUploadedQuestions);
  }

  UserModel addAccessedQuestion(String questionId) {
    final newAccessedQuestions = List<String>.from(accessedQuestions)
      ..add(questionId);
    return copyWith(accessedQuestions: newAccessedQuestions);
  }

  UserModel updatePreferences(Map<String, dynamic> newPreferences) {
    final mergedPreferences = Map<String, dynamic>.from(preferences)
      ..addAll(newPreferences);
    return copyWith(preferences: mergedPreferences);
  }

  UserModel updateSubscription(Subscription newSubscription) {
    return copyWith(subscription: newSubscription);
  }

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, points: $points, level: $level, isPremium: $isPremium)';
  }
}