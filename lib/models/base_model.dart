// base_model.dart - Enhanced for notifications
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
// --- FIX: Standardized import path ---
import 'package:diuquestionbank/constants/hive_type_ids.dart';

part 'base_model.g.dart';

@HiveType(typeId: kSyncStatusTypeId)
enum SyncStatus {
  @HiveField(0)
  synced,
  @HiveField(1)
  pending,
  @HiveField(2)
  error,

  // --- FIX: Added the missing 'pendingDelete' state ---
  @HiveField(3)
  pendingDelete,
}

/// A professional, refactored base model that extends HiveObject.
///
/// Any model that needs to be synced with Firestore AND cached locally
/// should extend this class.
///
/// NOTE: This class is abstract and does NOT have a @HiveType annotation.
/// This is intentional. Its fields will be included in the adapters
/// of its concrete subclasses.
abstract class BaseModel extends HiveObject with EquatableMixin {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime createdAt;

  @HiveField(2)
  final DateTime updatedAt;

  @HiveField(3)
  final SyncStatus syncStatus;

  @HiveField(4)
  final int version; // For optimistic locking

  BaseModel({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = SyncStatus.synced,
    this.version = 0,
  });

  /// Serializes the model to a Map for Firestore.
  Map<String, dynamic> toFirestore();

  @override
  List<Object?> get props => [id, version];

  /// Checks if the cached item is old and should be refreshed.
  bool get shouldRefreshCache {
    final now = DateTime.now();
    // Refresh if older than 1 hour
    return now.difference(updatedAt).inHours > 1;
  }

  /// Creates a copy of the model with an updated version.
  BaseModel copyWithVersion(int newVersion);

  /// Helper method to create timestamp for Firestore
  static Object? dateTimeToFirestore(DateTime? dateTime) {
    if (dateTime == null) return null;
    return dateTime;
  }

  /// Helper method to parse timestamp from Firestore
  static DateTime? dateTimeFromFirestore(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is DateTime) return timestamp;
    if (timestamp is String) return DateTime.tryParse(timestamp);
    return null;
  }
}