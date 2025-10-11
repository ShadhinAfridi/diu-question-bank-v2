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
  // --- Ad Implementation End ---

  @override
  void initState() {
    super.initState();
    _viewModel = QuestionListViewModel(questions: widget.questions);
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
        _viewModel.searchQuestions('');
      }
    });
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _viewModel.searchQuestions(query);
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
                          title: _showSearchBar ? _buildSearchField() : Text(widget.courseName),
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
      hintText: 'Search within course...',
      border: InputBorder.none,
    ),
  );

  Widget _buildFilterSection(QuestionListViewModel viewModel) {
    // Only show Midterm and Final options
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
      return const Center(child: Text('No questions found.'));
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
}
