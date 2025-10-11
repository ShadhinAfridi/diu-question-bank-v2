import 'dart:async';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

/// A data model class to hold the ad unit IDs fetched from Firebase.
class AdIds {
  final String bannerAdId;
  final String interstitialAdId;
  final String openAppAdId;

  AdIds({
    required this.bannerAdId,
    required this.interstitialAdId,
    required this.openAppAdId,
  });

  /// A factory constructor to create an instance of AdIds from a map.
  factory AdIds.fromMap(Map<String, dynamic> map) {
    return AdIds(
      bannerAdId: map['banner']?.toString() ?? '',
      interstitialAdId: map['interstitial']?.toString() ?? '',
      openAppAdId: map['openapp']?.toString() ?? '',
    );
  }

  bool get hasValidBannerId => bannerAdId.isNotEmpty;
  bool get hasValidInterstitialId => interstitialAdId.isNotEmpty;
  bool get hasValidOpenAppId => openAppAdId.isNotEmpty;
}

/// A service class to handle fetching and managing ad data from Firebase.
class AdsModel {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final Random _random = Random();

  // --- Caching Properties ---
  AdIds? _cachedAdIds;
  DateTime? _lastFetchTime;
  final Duration _cacheDuration = const Duration(hours: 1);

  // --- Interstitial Ad Frequency Capping Properties ---
  DateTime? _lastInterstitialShowTime;
  final Duration _interstitialInterval = const Duration(seconds: 90);

  /// Fetches ad IDs, utilizing an in-memory cache to avoid excessive network requests.
  Future<AdIds?> getAdIds() async {
    // 1. Check if a valid cache exists.
    if (_cachedAdIds != null &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheDuration) {
      if (kDebugMode) {
        print("Returning Ad IDs from cache.");
      }
      return _cachedAdIds;
    }

    if (kDebugMode) {
      print("Cache is stale or empty. Fetching new Ad IDs from Firebase...");
    }

    // 2. Fetch new IDs from Firebase.
    AdIds? newAdIds = await _fetchRandomAdIdsFromFirebase();

    // 3. If the primary fetch fails, try the fallback mechanism.
    newAdIds ??= await _getFallbackAdIds();

    // 4. If successful, update the cache.
    if (newAdIds != null) {
      _cachedAdIds = newAdIds;
      _lastFetchTime = DateTime.now();
      if (kDebugMode) {
        print("Ad IDs cached successfully.");
      }
    }

    return newAdIds;
  }

  /// The core logic to fetch ad IDs from a random path in Firebase.
  Future<AdIds?> _fetchRandomAdIdsFromFirebase() async {
    try {
      int randomIndex = _random.nextInt(101);

      final results = await Future.wait([
        _dbRef.child('banner/$randomIndex').get(),
        _dbRef.child('interstitial/$randomIndex').get(),
        _dbRef.child('openapp/$randomIndex').get(),
      ]);

      final bannerSnapshot = results[0];
      final interstitialSnapshot = results[1];
      final openAppSnapshot = results[2];

      if (bannerSnapshot.exists && interstitialSnapshot.exists && openAppSnapshot.exists) {
        return AdIds.fromMap({
          'banner': bannerSnapshot.value.toString(),
          'interstitial': interstitialSnapshot.value.toString(),
          'openapp': openAppSnapshot.value.toString(),
        });
      } else {
        if (kDebugMode) {
          print("Ad ID snapshots do not exist for random index $randomIndex.");
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching random ad IDs: $e");
      }
      return null;
    }
  }

  /// Fetches a default set of ad IDs from a predefined path
  Future<AdIds?> _getFallbackAdIds() async {
    if (kDebugMode) {
      print("Attempting to fetch fallback Ad IDs...");
    }
    try {
      final snapshot = await _dbRef.child('defaults/ads').get();
      if (snapshot.exists && snapshot.value is Map) {
        if (kDebugMode) {
          print("Fallback Ad IDs fetched successfully.");
        }
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return AdIds.fromMap(data);
      } else {
        if (kDebugMode) {
          print("Fallback Ad IDs do not exist or are not in the correct format.");
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching fallback ad IDs: $e");
      }
      return null;
    }
  }

  /// Checks if enough time has passed to show another interstitial ad.
  bool canShowInterstitialAd() {
    if (_lastInterstitialShowTime == null) {
      return true;
    }
    final timeSinceLastAd = DateTime.now().difference(_lastInterstitialShowTime!);
    return timeSinceLastAd > _interstitialInterval;
  }

  /// Records the timestamp when an interstitial ad is successfully shown.
  void recordInterstitialAdShown() {
    _lastInterstitialShowTime = DateTime.now();
    if (kDebugMode) {
      print("Interstitial ad show time recorded.");
    }
  }

  /// Clears the cache to force a fresh fetch on next call
  void clearCache() {
    _cachedAdIds = null;
    _lastFetchTime = null;
    if (kDebugMode) {
      print("Ad IDs cache cleared.");
    }
  }

  /// Gets the time remaining until next interstitial can be shown
  Duration? getTimeUntilNextInterstitial() {
    if (_lastInterstitialShowTime == null) return null;

    final timeSinceLastAd = DateTime.now().difference(_lastInterstitialShowTime!);
    if (timeSinceLastAd > _interstitialInterval) return Duration.zero;

    return _interstitialInterval - timeSinceLastAd;
  }
}