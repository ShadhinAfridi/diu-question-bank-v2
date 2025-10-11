// search_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../viewmodels/question_viewmodel.dart';
import '../question/question_list_item.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  late QuestionViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    final homeViewModel = Provider.of<HomeViewModel>(context, listen: false);
    _viewModel = QuestionViewModel(userDepartmentId: homeViewModel.userDepartmentId);
    _viewModel.loadQuestions();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _viewModel.searchQuestions(query);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        appBar: AppBar(
          title: TextField(
            controller: _searchController,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Search by course name...'),
            onChanged: _onSearchChanged,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                _viewModel.searchQuestions('');
              },
            ),
          ],
        ),
        body: Consumer<QuestionViewModel>(
          builder: (context, viewModel, child) {
            if (_searchController.text.isEmpty) {
              return const Center(child: Text('Start typing to search for questions.'));
            }
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (viewModel.errorMessage != null) {
              return Center(child: Text(viewModel.errorMessage!));
            }
            if (viewModel.filteredQuestions.isEmpty) {
              return const Center(child: Text('No results found.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: viewModel.filteredQuestions.length,
              itemBuilder: (context, index) {
                final question = viewModel.filteredQuestions[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: QuestionListItem(question: question),
                );
              },
            );
          },
        ),
      ),
    );
  }
}