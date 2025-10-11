// question_viewmodel.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/departments.dart';
import '../models/question_model.dart';
import '../models/question_filter.dart';

class QuestionViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? _userDepartmentId;
  final Box<Question> _questionsBox = Hive.box<Question>('questions');

  bool _isLoading = false;
  String? _errorMessage;
  List<Question> _allQuestions = [];
  List<Question> _filteredQuestions = [];
  String _searchQuery = '';
  QuestionFilter? _currentFilter;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Question> get filteredQuestions => _filteredQuestions;
  QuestionFilter? get currentFilter => _currentFilter;

  QuestionViewModel({required String? userDepartmentId}) : _userDepartmentId = userDepartmentId {
    if (_userDepartmentId == null || _userDepartmentId!.isEmpty) {
      _errorMessage = "Please set your department in your profile to view questions.";
      _isLoading = false;
      notifyListeners();
      return;
    }
    loadQuestions();
  }

  Future<void> loadQuestions({bool forceRefresh = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final cachedQuestions = _questionsBox.values.where((q) => q.department == getDepartmentNameById(_userDepartmentId)).toList();
      if (cachedQuestions.isNotEmpty && !forceRefresh) {
        _allQuestions = cachedQuestions;
        _applyFilters();
      } else {
        await _fetchQuestionsFromFirestore();
      }
    } catch (e) {
      _errorMessage = "Failed to load questions: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchQuestionsFromFirestore() async {
    final querySnapshot = await _firestore
        .collection('question-info')
        .where('department', isEqualTo: getDepartmentNameById(_userDepartmentId))
        .orderBy('processedAt', descending: true)
        .get();
    final fetchedQuestions = querySnapshot.docs.map((doc) => Question.fromFirestore(doc)).toList();
    await _cacheQuestions(fetchedQuestions);
    _allQuestions = fetchedQuestions;
    _applyFilters();
  }

  Future<void> _cacheQuestions(List<Question> questionsToCache) async {
    final relevantKeys = _questionsBox.keys.where((key) {
      final question = _questionsBox.get(key);
      return question?.department == getDepartmentNameById(_userDepartmentId);
    });
    await _questionsBox.deleteAll(relevantKeys);
    final newQuestionMap = {for (var q in questionsToCache) q.id: q};
    await _questionsBox.putAll(newQuestionMap);
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
    List<Question> tempQuestions = List.from(_allQuestions);

    if (_currentFilter != null) {
      tempQuestions = tempQuestions
          .where((q) => q.examType.toLowerCase() == _currentFilter!.displayName.toLowerCase())
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      tempQuestions = tempQuestions.where((q) =>
      q.courseName.toLowerCase().contains(_searchQuery) ||
          q.courseCode.toLowerCase().contains(_searchQuery))
          .toList();
    }

    _filteredQuestions = tempQuestions;
  }
}