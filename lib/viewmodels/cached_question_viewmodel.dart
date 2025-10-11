import 'package:flutter/foundation.dart';
import '../models/question_model.dart';
import '../repositories/question_cache_repository.dart';

class CachedQuestionViewModel extends ChangeNotifier {
  final QuestionCacheRepository _repository;

  List<Question> _questions = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String? _currentFilter;

  List<Question> get questions => _questions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  CachedQuestionViewModel({required QuestionCacheRepository repository})
      : _repository = repository {
    _initialize();
  }

  Future<void> _initialize() async {
    await loadQuestions();

    _repository.watchAll().listen((questions) {
      _questions = questions;
      _applyFilters();
      notifyListeners();
    }, onError: (error) {
      _error = 'Failed to watch questions: $error';
      notifyListeners();
    });
  }

  Future<void> loadQuestions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.preloadData();
    } catch (e) {
      _error = 'Failed to load questions: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void searchQuestions(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void filterQuestions(String? examType) {
    _currentFilter = examType;
    _applyFilters();
  }

  void _applyFilters() {
    var filtered = _questions;

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((q) =>
      q.courseName.toLowerCase().contains(query) ||
          q.courseCode.toLowerCase().contains(query)
      ).toList();
    }

    if (_currentFilter != null) {
      filtered = filtered.where((q) => q.examType == _currentFilter).toList();
    }

    _questions = filtered;
    notifyListeners();
  }

  Future<void> refresh() async {
    await _repository.syncWithRemote();
  }

  Future<void> clearCache() async {
    await _repository.clearCache();
    _questions.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }
}