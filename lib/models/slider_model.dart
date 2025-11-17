// slider_model.dart - Fixed and Enhanced
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// --- FIX: Standardized import path ---
import 'package:diuquestionbank/constants/hive_type_ids.dart';

part 'slider_model.g.dart';

// --- FIX: Changed typeId to `kSliderTypeTypeId` ---
@HiveType(typeId: kSliderTypeTypeId)
enum SliderType {
  @HiveField(0)
  banner,

  @HiveField(1)
  promotion,

  @HiveField(2)
  announcement,

  @HiveField(3)
  featured,
}

// --- FIX: Changed typeId to `kSliderActionTypeTypeId` ---
@HiveType(typeId: kSliderActionTypeTypeId)
enum SliderActionType {
  @HiveField(0)
  none,

  @HiveField(1)
  link,

  @HiveField(2)
  course,

  @HiveField(3)
  question,

  @HiveField(4)
  category,

  @HiveField(5)
  internal,
}

// This ID (`kSliderItemTypeId`) is correct for the class
@HiveType(typeId: kSliderItemTypeId)
class SliderItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String? subtitle;

  @HiveField(3)
  final String imageUrl;

  @HiveField(4)
  final String? thumbnailUrl;

  @HiveField(5)
  final int order;

  @HiveField(6)
  final SliderType type;

  @HiveField(7)
  final SliderActionType actionType;

  @HiveField(8)
  final String? actionValue;

  @HiveField(9)
  final String? buttonText;

  @HiveField(10)
  final bool isActive;

  @HiveField(11)
  final DateTime createdAt;

  @HiveField(12)
  final DateTime updatedAt;

  @HiveField(13)
  final DateTime? expiresAt;

  SliderItem({
    required this.id,
    required this.title,
    this.subtitle,
    required this.imageUrl,
    this.thumbnailUrl,
    required this.order,
    this.type = SliderType.banner,
    this.actionType = SliderActionType.none,
    this.actionValue,
    this.buttonText,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.expiresAt,
  });

  // Factory constructor from Firestore DocumentSnapshot
  factory SliderItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return SliderItem(
      id: doc.id,
      title: data['title'] ?? 'Untitled',
      subtitle: data['subtitle'],
      imageUrl: data['imageUrl'] ?? '',
      thumbnailUrl: data['thumbnailUrl'],
      order: (data['order'] ?? 0).toInt(),
      type: _parseSliderType(data['type']),
      actionType: _parseActionType(data['actionType']),
      actionValue: data['actionValue'],
      buttonText: data['buttonText'],
      isActive: data['isActive'] ?? true,
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestamp(data['updatedAt']),
      expiresAt:
      data['expiresAt'] != null ? _parseTimestamp(data['expiresAt']) : null,
    );
  }

  // Factory constructor from JSON Map
  factory SliderItem.fromJson(Map<String, dynamic> json) {
    return SliderItem(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Untitled',
      subtitle: json['subtitle'],
      imageUrl: json['imageUrl'] ?? '',
      thumbnailUrl: json['thumbnailUrl'],
      order: json['order'] ?? 0,
      type: _parseSliderType(json['type']),
      actionType: _parseActionType(json['actionType']),
      actionValue: json['actionValue'],
      buttonText: json['buttonText'],
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      expiresAt:
      json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
    );
  }

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'imageUrl': imageUrl,
      'thumbnailUrl': thumbnailUrl,
      'order': order,
      'type': _sliderTypeToString(type),
      'actionType': _actionTypeToString(actionType),
      'actionValue': actionValue,
      'buttonText': buttonText,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
    };
  }

  // Convert to Firestore-compatible map
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'subtitle': subtitle,
      'imageUrl': imageUrl,
      'thumbnailUrl': thumbnailUrl,
      'order': order,
      'type': _sliderTypeToString(type),
      'actionType': _actionTypeToString(actionType),
      'actionValue': actionValue,
      'buttonText': buttonText,
      'isActive': isActive,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt!),
    };
  }

  // Copy with method for immutability
  SliderItem copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? imageUrl,
    String? thumbnailUrl,
    int? order,
    SliderType? type,
    SliderActionType? actionType,
    String? actionValue,
    String? buttonText,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiresAt,
  }) {
    return SliderItem(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      imageUrl: imageUrl ?? this.imageUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      order: order ?? this.order,
      type: type ?? this.type,
      actionType: actionType ?? this.actionType,
      actionValue: actionValue ?? this.actionValue,
      buttonText: buttonText ?? this.buttonText,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  // Utility methods
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool get isValid => isActive && !isExpired;

  bool get hasAction =>
      actionType != SliderActionType.none && actionValue != null;

  String get displayTitle => title;

  // Helper methods for parsing
  static SliderType _parseSliderType(dynamic type) {
    if (type == null) return SliderType.banner;

    final typeString = type.toString().toLowerCase();
    switch (typeString) {
      case 'promotion':
        return SliderType.promotion;
      case 'announcement':
        return SliderType.announcement;
      case 'featured':
        return SliderType.featured;
      case 'banner':
      default:
        return SliderType.banner;
    }
  }

  static SliderActionType _parseActionType(dynamic actionType) {
    if (actionType == null) return SliderActionType.none;

    final actionString = actionType.toString().toLowerCase();
    switch (actionString) {
      case 'link':
        return SliderActionType.link;
      case 'course':
        return SliderActionType.course;
      case 'question':
        return SliderActionType.question;
      case 'category':
        return SliderActionType.category;
      case 'internal':
        return SliderActionType.internal;
      case 'none':
      default:
        return SliderActionType.none;
    }
  }

  static String _sliderTypeToString(SliderType type) {
    switch (type) {
      case SliderType.promotion:
        return 'promotion';
      case SliderType.announcement:
        return 'announcement';
      case SliderType.featured:
        return 'featured';
      case SliderType.banner:
      default:
        return 'banner';
    }
  }

  static String _actionTypeToString(SliderActionType actionType) {
    switch (actionType) {
      case SliderActionType.link:
        return 'link';
      case SliderActionType.course:
        return 'course';
      case SliderActionType.question:
        return 'question';
      case SliderActionType.category:
        return 'category';
      case SliderActionType.internal:
        return 'internal';
      case SliderActionType.none:
      default:
        return 'none';
    }
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is DateTime) {
      return timestamp;
    } else if (timestamp is String) {
      return DateTime.parse(timestamp);
    } else {
      return DateTime.now();
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is SliderItem &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'SliderItem(id: $id, title: $title, type: $type, isActive: $isActive, isValid: $isValid)';
  }
}