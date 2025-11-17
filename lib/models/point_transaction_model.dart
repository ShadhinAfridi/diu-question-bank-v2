// point_transaction_model.dart - Updated
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// --- FIX: Standardized import path ---
import 'package:diuquestionbank/constants/hive_type_ids.dart';
import 'base_model.dart';

part 'point_transaction_model.g.dart';

@HiveType(typeId: kPointTransactionTypeId)
class PointTransaction extends BaseModel {
  // BaseModel fields (0-4): id, createdAt, updatedAt, syncStatus, version

  @HiveField(5)
  final String userId;
  @HiveField(6)
  final int points;
  @HiveField(7)
  final String type; // 'earn', 'spend', 'refund'
  @HiveField(8)
  final String description;
  @HiveField(9)
  final String? referenceId;
  @HiveField(10)
  final String category; // 'question', 'ad', 'referral', 'purchase'
  @HiveField(11)
  final int balanceAfter; // For immediate UI updates

  PointTransaction({
    required String id,
    required this.userId,
    required this.points,
    required this.type,
    required this.description,
    this.referenceId,
    this.category = 'general',
    this.balanceAfter = 0,
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
  );

  // ADDED: CopyWith method for immutable updates
  PointTransaction copyWith({
    String? id,
    String? userId,
    int? points,
    String? type,
    String? description,
    String? referenceId,
    String? category,
    int? balanceAfter,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
    int? version,
  }) {
    return PointTransaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      points: points ?? this.points,
      type: type ?? this.type,
      description: description ?? this.description,
      referenceId: referenceId ?? this.referenceId,
      category: category ?? this.category,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      version: version ?? this.version,
    );
  }

  factory PointTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return PointTransaction(
      id: doc.id,
      userId: data['userId'] ?? '',
      points: (data['points'] ?? 0).toInt(),
      type: data['type'] ?? 'earn',
      description: data['description'] ?? '',
      referenceId: data['referenceId'],
      category: data['category'] ?? 'general',
      balanceAfter: (data['balanceAfter'] ?? 0).toInt(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      syncStatus: SyncStatus.values[data['syncStatus'] ?? 0], // FIXED: Added syncStatus
      version: (data['_version'] ?? 0).toInt(),
    );
  }

  @override
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'points': points,
      'type': type,
      'description': description,
      'referenceId': referenceId,
      'category': category,
      'balanceAfter': balanceAfter,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'syncStatus': syncStatus.index, // FIXED: Added syncStatus to Firestore
      '_version': version,
      // 'id' is not typically stored in Firestore as it's the document ID
    };
  }

  // ADDED: Convert to Map for Hive and other uses
  @override
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'points': points,
      'type': type,
      'description': description,
      'referenceId': referenceId,
      'category': category,
      'balanceAfter': balanceAfter,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'syncStatus': syncStatus.index,
      'version': version,
    };
  }

  // ADDED: Factory method to create from Map
  factory PointTransaction.fromMap(Map<String, dynamic> map) {
    return PointTransaction(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      points: (map['points'] ?? 0).toInt(),
      type: map['type'] ?? 'earn',
      description: map['description'] ?? '',
      referenceId: map['referenceId'],
      category: map['category'] ?? 'general',
      balanceAfter: (map['balanceAfter'] ?? 0).toInt(),
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
          : null,
      syncStatus: SyncStatus.values[map['syncStatus'] ?? 0],
      version: (map['version'] ?? 0).toInt(),
    );
  }

  @override
  BaseModel copyWithVersion(int newVersion) {
    return PointTransaction(
      id: id,
      userId: userId,
      points: points,
      type: type,
      description: description,
      referenceId: referenceId,
      category: category,
      balanceAfter: balanceAfter,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      syncStatus: syncStatus,
      version: newVersion,
    );
  }

  // ADDED: Touch method to update access time
  @override
  void touch() {
    // This method can be overridden if needed
    // For PointTransaction, we might not need to track lastAccessed
  }

  // Optimized validation
  bool get isValid {
    return id.isNotEmpty &&
        userId.isNotEmpty &&
        points != 0 && // Allow negative for spends
        ['earn', 'spend', 'refund'].contains(type) &&
        description.isNotEmpty;
  }

  // Performance helpers
  bool get isEarned => type == 'earn';
  bool get isSpent => type == 'spend';
  bool get isRefund => type == 'refund';

  int get signedPoints => isEarned ? points.abs() : -points.abs();

  // ADDED: Equality and hash code for better performance
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PointTransaction &&
        other.id == id &&
        other.userId == userId &&
        other.points == points &&
        other.type == type &&
        other.description == description &&
        other.referenceId == referenceId &&
        other.category == category &&
        other.balanceAfter == balanceAfter &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.syncStatus == syncStatus &&
        other.version == version;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      points,
      type,
      description,
      referenceId,
      category,
      balanceAfter,
      createdAt,
      updatedAt,
      syncStatus,
      version,
    );
  }

  // ADDED: toString for debugging
  @override
  String toString() {
    return 'PointTransaction(id: $id, userId: $userId, points: $points, type: $type, '
        'description: $description, balanceAfter: $balanceAfter, '
        'syncStatus: $syncStatus, version: $version)';
  }

  // ADDED: Helper method to create common transaction types
  factory PointTransaction.earn({
    required String id,
    required String userId,
    required int points,
    required String description,
    String? referenceId,
    String category = 'general',
    int currentBalance = 0,
  }) {
    return PointTransaction(
      id: id,
      userId: userId,
      points: points,
      type: 'earn',
      description: description,
      referenceId: referenceId,
      category: category,
      balanceAfter: currentBalance + points,
    );
  }

  // ADDED: Helper method to create spend transactions
  factory PointTransaction.spend({
    required String id,
    required String userId,
    required int points,
    required String description,
    required String referenceId,
    String category = 'general',
    int currentBalance = 0,
  }) {
    return PointTransaction(
      id: id,
      userId: userId,
      points: points,
      type: 'spend',
      description: description,
      referenceId: referenceId,
      category: category,
      balanceAfter: currentBalance - points,
    );
  }

  // ADDED: Helper method to create refund transactions
  factory PointTransaction.refund({
    required String id,
    required String userId,
    required int points,
    required String description,
    required String referenceId,
    String category = 'general',
    int currentBalance = 0,
  }) {
    return PointTransaction(
      id: id,
      userId: userId,
      points: points,
      type: 'refund',
      description: description,
      referenceId: referenceId,
      category: category,
      balanceAfter: currentBalance + points,
    );
  }
}