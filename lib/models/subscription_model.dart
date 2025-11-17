// subscription_model.dart - Updated
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// --- FIX: Standardized import path ---
import 'package:diuquestionbank/constants/hive_type_ids.dart';

part 'subscription_model.g.dart';

@HiveType(typeId: kSubscriptionTypeId)
class Subscription extends HiveObject {
  @HiveField(0)
  final bool isActive;
  @HiveField(1)
  final String planType; // 'free', 'monthly', 'yearly', 'lifetime'
  @HiveField(2)
  final DateTime expiryDate;
  @HiveField(3)
  final DateTime purchaseDate;
  @HiveField(4)
  final String? transactionId;
  @HiveField(5)
  final String? originalTransactionId; // For App Store/Play Store
  @HiveField(6)
  final String paymentProvider; // 'app_store', 'play_store', 'stripe', 'free'
  @HiveField(7)
  final Map<String, dynamic> entitlements; // Additional features

  Subscription({
    required this.isActive,
    required this.planType,
    required this.expiryDate,
    required this.purchaseDate,
    this.transactionId,
    this.originalTransactionId,
    this.paymentProvider = 'free',
    this.entitlements = const {},
  });

  factory Subscription.free() {
    final now = DateTime.now();
    return Subscription(
      isActive: false,
      planType: 'free',
      expiryDate: now,
      purchaseDate: now,
      paymentProvider: 'free',
    );
  }

  factory Subscription.fromMap(Map<String, dynamic> map) {
    // Handle null or missing timestamps gracefully
    final expiry = (map['expiryDate'] as Timestamp?)?.toDate() ?? DateTime.now();
    final purchase =
        (map['purchaseDate'] as Timestamp?)?.toDate() ?? DateTime.now();

    return Subscription(
      isActive: map['isActive'] ?? false,
      planType: map['planType'] ?? 'free',
      expiryDate: expiry,
      purchaseDate: purchase,
      transactionId: map['transactionId'],
      originalTransactionId: map['originalTransactionId'],
      paymentProvider: map['paymentProvider'] ?? 'free',
      entitlements: Map<String, dynamic>.from(map['entitlements'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isActive': isActive,
      'planType': planType,
      'expiryDate': Timestamp.fromDate(expiryDate),
      'purchaseDate': Timestamp.fromDate(purchaseDate),
      'transactionId': transactionId,
      'originalTransactionId': originalTransactionId,
      'paymentProvider': paymentProvider,
      'entitlements': entitlements,
    };
  }

  bool get isExpired =>
      planType != 'lifetime' && expiryDate.isBefore(DateTime.now());
  bool get isValid => isActive && !isExpired;

  int get daysRemaining {
    if (planType == 'lifetime') return 9999;
    if (isExpired) return 0;
    return expiryDate.difference(DateTime.now()).inDays;
  }

  bool hasEntitlement(String entitlement) => entitlements[entitlement] == true;
}