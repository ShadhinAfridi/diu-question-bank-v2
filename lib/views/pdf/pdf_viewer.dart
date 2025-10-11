import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfx/pdfx.dart';
import 'package:http/http.dart' as http;
import '../ads/pdf_banner_ad.dart';

/// A professional PDF viewer screen with premium ad integration
class ProfessionalPdfViewerScreen extends StatefulWidget {
  final String pdfUrl;
  final bool isAsset;
  final String? title;

  const ProfessionalPdfViewerScreen({
    super.key,
    required this.pdfUrl,
    this.isAsset = false,
    this.title,
  });

  @override
  State<ProfessionalPdfViewerScreen> createState() =>
      _ProfessionalPdfViewerScreenState();
}

class _ProfessionalPdfViewerScreenState
    extends State<ProfessionalPdfViewerScreen> {
  // --- State Variables ---
  late PdfControllerPinch _pdfController;
  final TextEditingController _pageNumberController = TextEditingController();

  bool _isLoading = true;
  String? _error;
  int _totalPages = 0;
  int _currentPage = 1;
  bool _isFullScreen = false;
  bool _showControls = true;
  Timer? _controlsTimer;
  Uint8List? _pdfData;
  bool _showAd = true;
  bool _isAdLoading = false;

  // --- Constants for UI ---
  static const Duration _animationDuration = Duration(milliseconds: 300);
  static const Duration _controlsFadeDuration = Duration(seconds: 4);

  // --- Lifecycle Methods ---
  @override
  void initState() {
    super.initState();
    _loadPdf();
    _startControlsTimer();
    // Set initial system UI mode for an edge-to-edge experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _pdfController.dispose();
    _pageNumberController.dispose();
    // Restore default system UI when leaving the screen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
    super.dispose();
  }

  // --- Core Logic Methods ---
  Future<void> _loadPdf() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (widget.isAsset) {
        final assetData = await rootBundle.load(widget.pdfUrl);
        _pdfData = assetData.buffer.asUint8List();
      } else {
        final response = await http.get(Uri.parse(widget.pdfUrl));
        if (response.statusCode == 200) {
          _pdfData = response.bodyBytes;
        } else {
          throw 'Failed to load PDF. Status code: ${response.statusCode}';
        }
      }

      if (_pdfData == null) throw 'Could not load PDF data.';

      _pdfController = PdfControllerPinch(
        document: PdfDocument.openData(_pdfData!),
      );
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to load PDF: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- UI Control Methods ---
  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(_controlsFadeDuration, () {
      if (mounted && !_isFullScreen) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControlsVisibility() {
    setState(() {
      _showControls = !_showControls;
      if (_showControls) _startControlsTimer();
    });
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
      _showControls = !_isFullScreen;

      if (_isFullScreen) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    });
  }

  // --- Ad Management Methods ---
  void _handleAdLoaded() {
    if (mounted) {
      setState(() {
        _isAdLoading = false;
      });
    }
  }

  void _handleAdFailed() {
    if (mounted) {
      setState(() {
        _isAdLoading = false;
      });
    }
  }

  void _toggleAdVisibility() {
    if (mounted) {
      setState(() {
        _showAd = !_showAd;
      });
    }
  }

  // --- Action Methods ---
  void _jumpToPage(int page) {
    if (page >= 1 && page <= _totalPages) {
      _pdfController.jumpToPage(page);
    }
  }

  Future<void> _showPageJumpDialog() async {
    _pageNumberController.text = _currentPage.toString();
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Jump to Page'),
          content: TextField(
            controller: _pageNumberController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(labelText: 'Page (1 - $_totalPages)'),
            autofocus: true,
            onSubmitted: (value) {
              final page = int.tryParse(value);
              if (page != null) _jumpToPage(page);
              Navigator.of(context).pop();
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Jump'),
              onPressed: () {
                final page = int.tryParse(_pageNumberController.text);
                if (page != null) _jumpToPage(page);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // --- Build Methods ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _toggleControlsVisibility,
              child: Stack(
                children: [
                  _buildPdfView(),
                  if (_isLoading) _buildLoadingIndicator(),
                  if (_error != null) _buildErrorWidget(),
                  if (!_isLoading && _error == null && _totalPages > 0)
                    _buildControlsOverlay(),
                ],
              ),
            ),
          ),
          // Premium full-width ad display
          if (_showAd && !_isFullScreen)
            PdfBannerAd(
              onAdLoaded: _handleAdLoaded,
              onAdFailed: _handleAdFailed,
            ),
        ],
      ),
      // Floating action button to toggle ad visibility
      floatingActionButton: !_isFullScreen ? _buildAdToggleButton() : null,
    );
  }

  Widget _buildAdToggleButton() {
    return FloatingActionButton.small(
      onPressed: _toggleAdVisibility,
      backgroundColor: Colors.black54,
      child: Icon(
        _showAd ? Icons.visibility_off : Icons.visibility,
        color: Colors.white,
        size: 20,
      ),
      tooltip: _showAd ? 'Hide Ads' : 'Show Ads',
    );
  }

  Widget _buildPdfView() {
    if (_isLoading || _error != null) {
      return const SizedBox.shrink();
    }
    return PdfViewPinch(
      controller: _pdfController,
      onDocumentLoaded: (doc) {
        if (mounted) {
          setState(() {
            _totalPages = doc.pagesCount;
            _currentPage = _pdfController.page;
          });
        }
      },
      onDocumentError: (error) {
        if (mounted) setState(() => _error = error.toString());
      },
      onPageChanged: (page) {
        if (mounted) setState(() => _currentPage = page);
      },
    );
  }

  Widget _buildControlsOverlay() {
    return AnimatedOpacity(
      opacity: _showControls ? 1.0 : 0.0,
      duration: _animationDuration,
      child: IgnorePointer(
        ignoring: !_showControls,
        child: Stack(
          children: [
            Positioned(top: 0, left: 0, right: 0, child: _buildTopBar()),
            Positioned(
                bottom: 0, left: 0, right: 0, child: _buildBottomNavBar()),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 10,
        right: 10,
        bottom: 10,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withOpacity(0.8), Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Back',
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.title ?? 'Document',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: _showPageJumpDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$_currentPage / $_totalPages',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 5),
          IconButton(
            icon: Icon(
              _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
              color: Colors.white,
            ),
            onPressed: _toggleFullScreen,
            tooltip: 'Toggle Fullscreen',
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      padding:
      const EdgeInsets.only(bottom: 15, left: 20, right: 20, top: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withOpacity(0.8), Colors.transparent],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavButton(Icons.first_page, 'First Page', _currentPage > 1,
                  () => _jumpToPage(1)),
          _buildNavButton(
            Icons.chevron_left,
            'Previous',
            _currentPage > 1,
                () => _pdfController.previousPage(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
            ),
          ),
          _buildNavButton(
            Icons.chevron_right,
            'Next',
            _currentPage < _totalPages,
                () => _pdfController.nextPage(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
            ),
          ),
          _buildNavButton(Icons.last_page, 'Last Page',
              _currentPage < _totalPages, () => _jumpToPage(_totalPages)),
        ],
      ),
    );
  }

  Widget _buildNavButton(
      IconData icon, String tooltip, bool isEnabled, VoidCallback? onPressed) {
    return IconButton(
      icon:
      Icon(icon, color: isEnabled ? Colors.white : Colors.white30, size: 28),
      tooltip: tooltip,
      onPressed: isEnabled ? onPressed : null,
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: const Center(
        child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded,
                size: 64, color: Colors.amber),
            const SizedBox(height: 16),
            const Text(
              'Failed to load PDF',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(fontSize: 16, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: _loadPdf,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}