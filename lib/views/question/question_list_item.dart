// question_list_item.dart
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';

import '../../models/question_model.dart';
import '../ads/ads_model.dart';
import '../pdf/pdf_viewer.dart';

class QuestionListItem extends StatefulWidget {
  final Question question;

  const QuestionListItem({super.key, required this.question});

  @override
  State<QuestionListItem> createState() => _QuestionListItemState();
}

class _QuestionListItemState extends State<QuestionListItem> {
  final AdsModel _adsModel = AdsModel();
  InterstitialAd? _interstitialAd;
  bool _isAdLoading = false;
  bool _isMounted = false;

  @override
  void initState() {
    super.initState();
    _isMounted = true;
  }

  @override
  void dispose() {
    _isMounted = false;
    _interstitialAd?.dispose();
    super.dispose();
  }

  /// Safe state update helper
  void _safeSetState(VoidCallback fn) {
    if (_isMounted) {
      setState(fn);
    }
  }

  /// Loads an interstitial ad and executes a callback when complete.
  void _loadInterstitialAd(VoidCallback onAdHandled) {
    if (_isAdLoading) return;

    _safeSetState(() => _isAdLoading = true);

    _adsModel.getAdIds().then((adIds) {
      if (adIds == null || !adIds.hasValidInterstitialId) {
        debugPrint("Interstitial ad ID not available. Skipping ad.");
        _safeSetState(() => _isAdLoading = false);
        onAdHandled();
        return;
      }

      InterstitialAd.load(
        adUnitId: adIds.interstitialAdId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _safeSetState(() => _isAdLoading = false);
            debugPrint("Interstitial ad loaded successfully.");
            onAdHandled();
          },
          onAdFailedToLoad: (error) {
            debugPrint('InterstitialAd failed to load: $error');
            _safeSetState(() => _isAdLoading = false);
            onAdHandled();
          },
        ),
      );
    }).catchError((error) {
      debugPrint('Error getting ad IDs: $error');
      _safeSetState(() => _isAdLoading = false);
      onAdHandled();
    });
  }

  /// Shows the loaded interstitial ad or navigates directly if it's not ready.
  void _showAdAndNavigate() {
    if (_interstitialAd == null) {
      _navigateToPdf();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _navigateToPdf();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        debugPrint('InterstitialAd failed to show: $error');
        _navigateToPdf();
      },
    );

    _interstitialAd!.show();
    _adsModel.recordInterstitialAdShown();
  }

  /// Navigates to the PDF viewer screen.
  void _navigateToPdf() {
    if (!_isMounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfessionalPdfViewerScreen(
          pdfUrl: widget.question.pdfUrl,
          isAsset: false,
          title: widget.question.courseName,
        ),
      ),
    );
  }

  /// Handles the tap event on the list item.
  void _handleItemTap() {
    if (_adsModel.canShowInterstitialAd()) {
      _loadInterstitialAd(_showAdAndNavigate);
    } else {
      _navigateToPdf();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _isAdLoading ? null : _handleItemTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.question.courseName,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${widget.question.department} • ${widget.question.courseCode}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getExamTypeColor(context, widget.question.examType),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.question.examType.toUpperCase(),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: _getExamTypeTextColor(
                                  context, widget.question.examType),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildInfoChip(
                          context,
                          icon: Icons.calendar_month_outlined,
                          label: widget.question.examYear,
                        ),
                        const SizedBox(width: 8),
                        _buildInfoChip(
                          context,
                          icon: Icons.school_outlined,
                          label: widget.question.semester,
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.picture_as_pdf_outlined,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'View PDF',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(
                      height: 1,
                      color: Theme.of(context).dividerColor.withOpacity(0.1),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.4),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Uploaded ${DateFormat.yMMMd().format(widget.question.processedAt.toDate())}',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_isAdLoading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.black.withOpacity(0.3),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context,
      {required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant
                .withOpacity(0.8),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Color _getExamTypeColor(BuildContext context, String examType) {
    switch (examType.toLowerCase()) {
      case 'midterm':
        return Theme.of(context).colorScheme.tertiaryContainer;
      case 'final':
        return Theme.of(context).colorScheme.secondaryContainer;
      default:
        return Theme.of(context).colorScheme.primaryContainer;
    }
  }

  Color _getExamTypeTextColor(BuildContext context, String examType) {
    switch (examType.toLowerCase()) {
      case 'midterm':
        return Theme.of(context).colorScheme.onTertiaryContainer;
      case 'final':
        return Theme.of(context).colorScheme.onSecondaryContainer;
      default:
        return Theme.of(context).colorScheme.onPrimaryContainer;
    }
  }
}
