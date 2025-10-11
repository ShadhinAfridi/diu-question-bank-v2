// question_list_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../viewmodels/question_list_viewmodel.dart';
import '../../models/question_filter.dart';
import '../../models/question_model.dart';
import '../ads/ads_model.dart';
import '../ads/banner_ad_item.dart';
import 'question_list_item.dart';

class QuestionListScreen extends StatefulWidget {
  final String courseName;
  final List<Question> questions;

  const QuestionListScreen({
    super.key,
    required this.courseName,
    required this.questions,
  });

  @override
  State<QuestionListScreen> createState() => _QuestionListScreenState();
}

class _QuestionListScreenState extends State<QuestionListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  bool _showSearchBar = false;
  Timer? _searchDebounce;
  double _elevation = 0;
  late final QuestionListViewModel _viewModel;

  // --- Ad Implementation Start ---
  String? _bannerAdId;
  bool _isAdLoaded = false;
  // --- Ad Implementation End ---

  @override
  void initState() {
    super.initState();
    _viewModel = QuestionListViewModel(questions: widget.questions);
    _scrollController.addListener(_scrollListener);
    // Delay ad loading to avoid build conflicts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAdId();
    });
  }

  // --- Ad Implementation Start ---
  /// Fetches the banner ad ID from the AdsModel.
  void _loadAdId() async {
    try {
      final adsModel = AdsModel();
      final adIds = await adsModel.getAdIds();
      if (adIds != null && mounted) {
        setState(() {
          _bannerAdId = adIds.bannerAdId;
          _isAdLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Failed to load ad ID: $e');
      if (mounted) {
        setState(() {
          _isAdLoaded = true;
        });
      }
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
    final newElevation = _scrollController.offset > 10 ? 1.0 : 0.0;
    if (newElevation != _elevation && mounted) {
      setState(() => _elevation = newElevation);
    }
  }

  void _toggleSearch() {
    if (mounted) {
      setState(() {
        _showSearchBar = !_showSearchBar;
        if (!_showSearchBar) {
          _searchController.clear();
          _viewModel.searchQuestions('');
        }
      });
    }
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        _viewModel.searchQuestions(query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<QuestionListViewModel>(
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
                              : Text(
                            widget.courseName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          pinned: true,
                          floating: true,
                          elevation: _elevation,
                          forceElevated: innerBoxIsScrolled,
                          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                          surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
                          actions: [
                            IconButton(
                              icon: Icon(
                                _showSearchBar ? Icons.close : Icons.search,
                                color: Theme.of(context).colorScheme.onBackground,
                              ),
                              onPressed: _toggleSearch,
                            ),
                          ],
                          bottom: _showSearchBar
                              ? null
                              : PreferredSize(
                            preferredSize: const Size.fromHeight(42),
                            child: _buildFilterSection(viewModel),
                          ),
                        ),
                      ],
                      body: _buildBody(viewModel),
                    ),
                  ),
                  // Fixed banner ad at bottom - only show after ad is loaded
                  if (_isAdLoaded && _bannerAdId != null)
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
      hintText: 'Search within course...',
      border: InputBorder.none,
      hintStyle: TextStyle(
        color: Theme.of(context).hintColor,
      ),
    ),
    style: TextStyle(
      color: Theme.of(context).colorScheme.onBackground,
    ),
  );

  Widget _buildFilterSection(QuestionListViewModel viewModel) {
    final filteredExamTypes = [QuestionFilter.midterm, QuestionFilter.finalExam];

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SizedBox(
        height: 42,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            FilterChip(
              label: const Text('All'),
              selected: viewModel.currentFilter == null,
              onSelected: (_) => viewModel.filterQuestions(null),
            ),
            ...filteredExamTypes.map((filter) => Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: FilterChip(
                label: Text(filter.displayName),
                selected: viewModel.currentFilter == filter,
                onSelected: (_) => viewModel.filterQuestions(filter),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(QuestionListViewModel viewModel) {
    if (viewModel.filteredQuestions.isEmpty) {
      return _buildEmptyState();
    }

    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: viewModel.filteredQuestions.length,
        itemBuilder: (context, index) {
          final question = viewModel.filteredQuestions[index];

          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: QuestionListItem(question: question),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'No questions available'
                  : 'No questions found for "${_searchController.text}"',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            if (_searchController.text.isNotEmpty) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  _searchController.clear();
                  _viewModel.searchQuestions('');
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
