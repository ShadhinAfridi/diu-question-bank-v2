// question_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../viewmodels/course_viewmodel.dart';
import 'course_folder_item.dart';
import '../ads/ads_model.dart';
import '../ads/banner_ad_item.dart';

class QuestionScreen extends StatefulWidget {
  const QuestionScreen({super.key});

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  bool _showSearchBar = false;
  Timer? _searchDebounce;
  double _elevation = 0;
  late final CourseViewModel _viewModel;

  // --- Ad Implementation ---
  String? _bannerAdId;

  @override
  void initState() {
    super.initState();

    // Initialize the ViewModel immediately with the required department ID.
    // context.read is used here as it's a one-time read and doesn't set up a listener.
    final userDepartmentId = context.read<HomeViewModel>().userDepartmentId;
    _viewModel = CourseViewModel(userDepartmentId: userDepartmentId);

    _scrollController.addListener(_scrollListener);
    _loadAdId();

    // Defer the initial data fetching until after the first frame is built.
    // This prevents the "setState() called during build" error.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // It's now safe to fetch data, which will trigger notifyListeners.
        _viewModel.refreshCourses();
      }
    });
  }

  /// Fetches the banner ad ID from the AdsModel.
  void _loadAdId() async {
    try {
      final adsModel = AdsModel();
      final adIds = await adsModel.getAdIds();
      if (adIds != null && mounted) {
        setState(() {
          _bannerAdId = adIds.bannerAdId;
        });
      }
    } catch (e) {
      debugPrint('Failed to load ad ID: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    _scrollController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _scrollListener() {
    final newElevation = _scrollController.offset > 10 ? 1.0 : 0.0;
    if (newElevation != _elevation && mounted) {
      setState(() => _elevation = newElevation);
    }
  }

  void _toggleSearch() {
    setState(() {
      _showSearchBar = !_showSearchBar;
      if (!_showSearchBar) {
        _searchController.clear();
        _viewModel.searchCourses('');
      }
    });
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        _viewModel.searchCourses(query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<CourseViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            body: SafeArea(
              top: true,
              bottom: false,
              child: Column(
                children: [
                  Expanded(
                    child: NestedScrollView(
                      controller: _scrollController,
                      headerSliverBuilder: (context, innerBoxIsScrolled) => [
                        SliverAppBar(
                          title: _showSearchBar
                              ? _buildSearchField()
                              : const Text(
                            'Question Bank',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          pinned: true,
                          floating: true,
                          elevation: _elevation,
                          forceElevated: innerBoxIsScrolled,
                          backgroundColor:
                          Theme.of(context).scaffoldBackgroundColor,
                          surfaceTintColor:
                          Theme.of(context).scaffoldBackgroundColor,
                          actions: [
                            IconButton(
                              icon: Icon(
                                _showSearchBar ? Icons.close : Icons.search,
                                color:
                                Theme.of(context).colorScheme.onBackground,
                              ),
                              onPressed: _toggleSearch,
                            ),
                          ],
                        ),
                      ],
                      body: _buildBody(viewModel),
                    ),
                  ),
                  // Fixed banner ad at bottom
                  if (_bannerAdId != null)
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: BannerAdItem(adUnitId: _bannerAdId!),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchField() => TextField(
    controller: _searchController,
    autofocus: true,
    onChanged: _onSearchChanged,
    decoration: InputDecoration(
      hintText: 'Search courses...',
      border: InputBorder.none,
      hintStyle: TextStyle(
        color: Theme.of(context).hintColor,
      ),
    ),
    style: TextStyle(
      color: Theme.of(context).colorScheme.onBackground,
    ),
  );

  Widget _buildBody(CourseViewModel viewModel) {
    if (viewModel.isLoading && viewModel.filteredCourses.isEmpty) {
      return _buildShimmerLoading();
    }

    if (viewModel.errorMessage != null) {
      return _buildErrorState(viewModel);
    }

    if (viewModel.filteredCourses.isEmpty) {
      return _buildEmptyState();
    }

    final courses = viewModel.filteredCourses.entries.toList();

    return RefreshIndicator(
      onRefresh: () => viewModel.refreshCourses(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: courses.length,
        itemBuilder: (context, index) {
          final courseEntry = courses[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CourseFolderItem(
              courseName: courseEntry.key,
              questions: courseEntry.value,
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          height: 150,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(CourseViewModel viewModel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              viewModel.errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: viewModel.refreshCourses,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'No courses available'
                  : 'No courses found for "${_searchController.text}"',
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
            if (_searchController.text.isNotEmpty) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  _searchController.clear();
                  _viewModel.searchCourses('');
                },
                child: const Text('Clear search'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
