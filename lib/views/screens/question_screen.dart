import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/question_model.dart';
import '../../providers/view_model_providers.dart';
import '../../viewmodels/question_viewmodel.dart';



/// A professional, state-managed screen to display and filter questions.
///
/// This screen connects to the [questionViewModelProvider] to display a list
/// of questions. It supports searching, filtering, pull-to-refresh,
/// and handles loading, error, and empty states.
class QuestionScreen extends ConsumerStatefulWidget {
  const QuestionScreen({super.key});

  @override
  ConsumerState<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends ConsumerState<QuestionScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Add a listener to the search controller for debouncing
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  /// Debounces search input to avoid excessive calls to the viewmodel.
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      // Use ref.read for actions inside callbacks
      ref.read(questionViewModelProvider).searchQuestions(_searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch the viewmodel provider. This will rebuild the widget
    // when the viewmodel calls notifyListeners().
    final viewModel = ref.watch(questionViewModelProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Questions'),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      backgroundColor: colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: () => ref.read(questionViewModelProvider).refreshQuestions(),
        child: Column(
          children: [
            // --- Search Bar ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search courses or codes...',
                  prefixIcon: Icon(Icons.search, color: colorScheme.onSurfaceVariant),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28.0),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            // --- Filter Chips ---
            _FilterChips(viewModel: viewModel),

            // --- Body Content (Loading, Error, List) ---
            Expanded(
              child: _buildBody(viewModel, colorScheme, textTheme),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the main body, handling loading, error, empty, and data states.
  Widget _buildBody(
      QuestionViewModel viewModel,
      ColorScheme colorScheme,
      TextTheme textTheme,
      ) {
    // Initial loading state
    if (viewModel.isLoading && viewModel.filteredQuestions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error state
    if (viewModel.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                viewModel.errorMessage!,
                style: textTheme.bodyLarge?.copyWith(color: colorScheme.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.read(questionViewModelProvider).refreshQuestions(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Empty state
    if (viewModel.filteredQuestions.isEmpty) {
      return Center(
        child: Text(
          'No questions found.',
          style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      );
    }

    // Data state
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: viewModel.filteredQuestions.length,
      itemBuilder: (context, index) {
        final question = viewModel.filteredQuestions[index];
        return _QuestionCard(question: question);
      },
    );
  }
}

/// A horizontal list of [ChoiceChip] widgets for filtering.
class _FilterChips extends ConsumerWidget {
  const _FilterChips({required this.viewModel});

  final QuestionViewModel viewModel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    // Create a list of all filter options, starting with "All"
    final allFilters = ['All', ...viewModel.examTypes];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        children: allFilters.map((type) {
          bool isSelected;

          // Logic to determine if the chip is selected
          if (type == 'All') {
            isSelected = viewModel.currentExamTypeFilter == null;
          } else {
            isSelected = viewModel.currentExamTypeFilter == type;
          }

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(type),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  // Use ref.read for actions
                  ref.read(questionViewModelProvider).filterCachedQuestions(
                    type == 'All' ? null : type,
                  );
                }
              },
              backgroundColor: colorScheme.surfaceContainer,
              selectedColor: colorScheme.secondaryContainer,
              labelStyle: TextStyle(
                  color: isSelected ? colorScheme.onSecondaryContainer : colorScheme.onSurfaceVariant
              ),
              side: BorderSide(
                color: isSelected ? Colors.transparent : colorScheme.outlineVariant,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// A Material 3 Card to display a single [Question] item.
class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.question});

  final Question question;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      color: colorScheme.surfaceContainerHighest,
      child: ListTile(
        leading: Icon(
          Icons.description_outlined,
          color: colorScheme.primary,
        ),
        title: Text(
          question.courseName,
          style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${question.courseCode} • ${question.examType} ${question.examYear}',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: colorScheme.onSurfaceVariant,
        ),
        onTap: () {
          // TODO: Implement navigation to question detail screen
          // Example: context.push('/question/${question.id}');
          debugPrint('Tapped on question: ${question.id}');
        },
      ),
    );
  }
}