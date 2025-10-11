// question_list_viewmodel.dart
import 'package:flutter/foundation.dart';
import '../models/question_filter.dart';
import '../models/question_model.dart';

class QuestionListViewModel extends ChangeNotifier {
  final List<Question> _questions;
  List<Question> _filteredQuestions = [];
  String _searchQuery = '';
  QuestionFilter? _currentFilter;

  List<Question> get filteredQuestions => _filteredQuestions;
  QuestionFilter? get currentFilter => _currentFilter;

  QuestionListViewModel({required List<Question> questions}) : _questions = questions {
    _applyFilters();
  }

  void filterQuestions(QuestionFilter? filter) {
    _currentFilter = filter;
    _applyFilters();
    notifyListeners();
  }

  void searchQuestions(String query) {
    _searchQuery = query.toLowerCase().trim();
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    List<Question> tempQuestions = List.from(_questions);

    if (_currentFilter != null) {
      tempQuestions = tempQuestions
          .where((q) =>
      q.examType.toLowerCase() ==
          _currentFilter!.displayName.toLowerCase())
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      tempQuestions = tempQuestions.where((q) =>
      q.courseName.toLowerCase().contains(_searchQuery) ||
          q.courseCode.toLowerCase().contains(_searchQuery)).toList();
    }

    _filteredQuestions = tempQuestions;
  }
}