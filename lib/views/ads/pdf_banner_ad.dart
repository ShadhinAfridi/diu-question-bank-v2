import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'ads_model.dart';

/// A premium adaptive banner ad widget with enhanced UX for PDF viewer
class PdfBannerAd extends StatefulWidget {
  final VoidCallback? onAdLoaded;
  final VoidCallback? onAdFailed;

  const PdfBannerAd({
    super.key,
    this.onAdLoaded,
    this.onAdFailed,
  });

  @override
  State<PdfBannerAd> createState() => _PdfBannerAdState();
}

class _PdfBannerAdState extends State<PdfBannerAd> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _isAdLoading = false;
  bool _isAdInitialized = false;
  bool _hasError = false;
  String _adUnitId = '';
  final AdsModel _adsModel = AdsModel();
  int _retryAttempt = 0;
  static const int _maxRetryAttempts = 3;
  AdSize? _adSize;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isAdInitialized) {
      _isAdInitialized = true;
      _initializeAd();
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  /// Initialize ad with proper sizing
  Future<void> _initializeAd() async {
    // Determine ad size first
    _adSize = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      MediaQuery.sizeOf(context).width.truncate(),
    );

    if (_adSize == null) {
      debugPrint("PDF Ad: Unable to get anchored banner size.");
      _handleAdLoadError('Unable to get anchored banner size');
      return;
    }

    _loadAd();
  }

  /// Checks if device has network connectivity
  Future<bool> _hasNetworkConnection() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  /// Loads an adaptive banner ad
  Future<void> _loadAd() async {
    if (_isAdLoading || _isAdLoaded) return;

    // Check network connectivity first
    if (!await _hasNetworkConnection()) {
      debugPrint("PDF Ad: No network connection, skipping ad load");
      if (mounted) {
        setState(() {
          _hasError = true;
          _isAdLoading = false;
        });
      }
      widget.onAdFailed?.call();
      return;
    }

    setState(() {
      _isAdLoading = true;
      _hasError = false;
    });

    try {
      final adIds = await _adsModel.getAdIds();
      if (adIds != null && adIds.bannerAdId.isNotEmpty) {
        _adUnitId = adIds.bannerAdId;
        _createAndLoadBannerAd();
      } else {
        _handleAdLoadError('No ad unit ID available');
      }
    } catch (e) {
      _handleAdLoadError('Failed to fetch ad ID: $e');
    }
  }

  /// Creates and loads the BannerAd instance
  void _createAndLoadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      size: _adSize!,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _bannerAd = ad as BannerAd;
              _isAdLoaded = true;
              _isAdLoading = false;
              _hasError = false;
              _retryAttempt = 0;
            });
          }
          widget.onAdLoaded?.call();
          debugPrint('PDF Ad: Banner ad loaded successfully');
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _handleAdLoadError('BannerAd failed to load: $error');
        },
        onAdOpened: (ad) => debugPrint('Banner ad opened'),
        onAdClosed: (ad) => debugPrint('Banner ad closed'),
        onAdImpression: (ad) => debugPrint('Banner ad impression recorded'),
      ),
    )..load();
  }

  /// Handles errors during the ad loading process and schedules a retry
  void _handleAdLoadError(String error) {
    debugPrint(error);

    if (mounted) {
      setState(() {
        _isAdLoading = false;
        _isAdLoaded = false;
        _hasError = true;
      });
    }

    widget.onAdFailed?.call();

    // Retry logic with exponential backoff
    if (_retryAttempt < _maxRetryAttempts) {
      _retryAttempt++;
      int retryDelay = 2 * _retryAttempt; // Exponential backoff: 2, 4, 6 seconds
      debugPrint("PDF Ad: Retrying in $retryDelay seconds (Attempt $_retryAttempt)...");

      Future.delayed(Duration(seconds: retryDelay), () {
        if (mounted && !_isAdLoaded) {
          _loadAd();
        }
      });
    }
  }

  /// Builds a loading placeholder
  Widget _buildLoadingPlaceholder() {
    return Container(
      width: double.infinity,
      height: _adSize?.height.toDouble() ?? 50,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(
          top: BorderSide(
            color: Colors.grey[800]!,
            width: 1,
          ),
        ),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
          ),
        ),
      ),
    );
  }

  /// Builds an error state widget
  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      height: _adSize?.height.toDouble() ?? 50,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(
          top: BorderSide(
            color: Colors.grey[800]!,
            width: 1,
          ),
        ),
      ),
      child: Center(
        child: Icon(
          Icons.error_outline,
          color: Colors.grey[600],
          size: 24,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state
    if (_isAdLoading) {
      return _buildLoadingPlaceholder();
    }

    // Show error state
    if (_hasError) {
      return _buildErrorState();
    }

    // Show ad when loaded
    if (_isAdLoaded && _bannerAd != null) {
      final adHeight = _bannerAd!.size.height.toDouble();

      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          border: Border(
            top: BorderSide(
              color: Colors.grey[800]!,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: adHeight,
            child: AdWidget(ad: _bannerAd!),
          ),
        ),
      );
    }

    // Default empty state
    return const SizedBox.shrink();
  }
}