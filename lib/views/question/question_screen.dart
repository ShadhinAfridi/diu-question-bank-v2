// question_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../viewmodels/course_viewmodel.dart';
import '../../models/question_model.dart';
import '../ads/ads_model.dart';
import '../ads/banner_ad_item.dart';
import 'course_folder_item.dart';

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

  // --- Ad Implementation Start ---
  String? _bannerAdId;
  // --- Ad Implementation End ---

  @override
  void initState() {
    super.initState();
    final userDepartmentId = context.read<HomeViewModel>().userDepartmentId;
    _viewModel = CourseViewModel(userDepartmentId: userDepartmentId);
    _scrollController.addListener(_scrollListener);
    _loadAdId(); // Load the ad ID
  }

  // --- Ad Implementation Start ---
  /// Fetches the banner ad ID from the AdsModel.
  void _loadAdId() async {
    final adsModel = AdsModel();
    final adIds = await adsModel.getAdIds();
    if (adIds != null && mounted) {
      setState(() {
        _bannerAdId = adIds.bannerAdId;
      });
    }
  }
  // --- Ad Implementation End ---

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    _scrollController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset > 10 && _elevation == 0) {
      setState(() => _elevation = 1);
    } else if (_scrollController.offset <= 10 && _elevation == 1) {
      setState(() => _elevation = 0);
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
      _viewModel.searchCourses(query);
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
                          title: _showSearchBar ? _buildSearchField() : const Text('Question Bank'),
                          pinned: true,
                          floating: true,
                          elevation: _elevation,
                          forceElevated: innerBoxIsScrolled,
                          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                          surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
                          actions: [
                            IconButton(
                              icon: Icon(_showSearchBar ? Icons.close : Icons.search),
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
    decoration: const InputDecoration(
      hintText: 'Search courses...',
      border: InputBorder.none,
    ),
  );

  Widget _buildBody(CourseViewModel viewModel) {
    if (viewModel.isLoading && viewModel.filteredCourses.isEmpty) {
      return _buildShimmerLoading();
    }
    if (viewModel.errorMessage != null) {
      return Center(child: Text(viewModel.errorMessage!));
    }
    if (viewModel.filteredCourses.isEmpty) {
      return const Center(child: Text('No courses found.'));
    }

    final courses = viewModel.filteredCourses.entries.toList();

    return RefreshIndicator(
      onRefresh: viewModel.refreshCourses,
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
          height: 150, // Increased height to match CourseFolderItem
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20), // Match border radius
          ),
        ),
      ),
    );
  }
}
