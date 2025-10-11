import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// A styled card widget designed to load and display a banner ad.
class BannerAdItem extends StatefulWidget {
  final String adUnitId;

  const BannerAdItem({
    super.key,
    required this.adUnitId,
  });

  @override
  State<BannerAdItem> createState() => _BannerAdItemState();
}

class _BannerAdItemState extends State<BannerAdItem> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _isAdInitialized = false;
  int _retryAttempt = 0;
  static const int _maxRetryAttempts = 5;
  bool _hasError = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isAdInitialized) {
      _isAdInitialized = true;
      _loadAd();
    }
  }

  @override
  void didUpdateWidget(covariant BannerAdItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.adUnitId != oldWidget.adUnitId && widget.adUnitId.isNotEmpty) {
      _bannerAd?.dispose();
      _retryAttempt = 0;
      if (mounted) {
        setState(() {
          _bannerAd = null;
          _isAdLoaded = false;
          _hasError = false;
        });
      }
      _loadAd();
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  /// Checks if device has network connectivity
  Future<bool> _hasNetworkConnection() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  /// Loads a banner ad using the provided ad unit ID.
  void _loadAd() async {
    debugPrint("Ads: Attempting to load ad with unit ID: ${widget.adUnitId}");

    if (widget.adUnitId.isEmpty) {
      debugPrint("Ads: Ad unit ID is empty, aborting load.");
      return;
    }

    if (!await _hasNetworkConnection()) {
      debugPrint("Ads: No network connection, skipping ad load");
      if (mounted) setState(() => _hasError = true);
      return;
    }

    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      MediaQuery.sizeOf(context).width.truncate(),
    );

    if (size == null) {
      debugPrint("Ads: Unable to get anchored banner size.");
      if (mounted) setState(() => _hasError = true);
      return;
    }

    BannerAd(
      adUnitId: widget.adUnitId,
      request: const AdRequest(),
      size: size,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint("Ads: Ad was loaded successfully.");
          _retryAttempt = 0;
          if (mounted) {
            setState(() {
              _bannerAd = ad as BannerAd;
              _isAdLoaded = true;
              _hasError = false;
            });
          }
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint("Ads: Ad failed to load with error: $err");
          ad.dispose();

          if (err.code == 3 && _retryAttempt < _maxRetryAttempts) {
            _retryAttempt++;
            int retryDelay = 5 * _retryAttempt;
            debugPrint("Ads: Retrying ad load in $retryDelay seconds (Attempt $_retryAttempt)...");
            Future.delayed(Duration(seconds: retryDelay), () {
              if (mounted) _loadAd();
            });
          } else if (mounted) {
            setState(() => _hasError = true);
          }
        },
      ),
    ).load();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      shadowColor: Theme.of(context).shadowColor.withOpacity(0.1),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}

