import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod

import '../data/departments.dart';
import '../models/question_model.dart';
import '../providers/repository_providers.dart';
import '../providers/service_providers.dart';
import '../providers/view_model_providers.dart';
import '../repositories/interfaces/question_repository.dart';
// REFACTORED: Removed CacheManager
// import '../services/cache_manager.dart';
import 'base_viewmodel.dart';

class CourseViewModel extends BaseViewModel {
  final IQuestionRepository _questionRepository;
  // REFACTORED: Removed CacheManager
  // final CacheManager _cacheManager;
  final String? _userDepartmentId;

  bool _isLoading = false;
  String? _errorMessage;
  Map<String, List<Question>> _courses = {};
  Map<String, List<Question>> _filteredCourses = {};
  String _searchQuery = '';
  StreamSubscription<List<Question>>? _questionsSubscription;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, List<Question>> get courses => _courses;
  Map<String, List<Question>> get filteredCourses => _filteredCourses;

  // Constructor now accepts Ref and uses it to get dependencies
  CourseViewModel(Ref ref)
      : _questionRepository = ref.watch(questionRepositoryProvider),
  // REFACTORED: Removed CacheManager
  // _cacheManager = ref.watch(cacheManagerProvider), // Assumes cacheManagerProvider exists
        _userDepartmentId = ref.watch(userDepartmentIdProvider) {
    if (_userDepartmentId == null || _userDepartmentId!.isEmpty) {
      _errorMessage =
      "Please set your department in your profile to view questions.";
      _isLoading = false;
      return;
    }
    _listenToCourses();
  }

  @override
  void dispose() {
    _questionsSubscription?.cancel();
    super.dispose();
  }

  void _listenToCourses() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _loadCoursesFromCache();

    _questionsSubscription = _questionRepository.watchAll().listen(
          (questions) {
        _processQuestions(questions);
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = "Error listening to questions: ${error.toString()}";
        _isLoading = false;
        notifyListeners();
      },
    );
    addSubscription(_questionsSubscription!);
  }

  void _loadCoursesFromCache() async {
    try {
      // This will now return from cache if available
      final questions = await _questionRepository.getAll();
      _processQuestions(questions);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // Continue
    }
  }

  void _processQuestions(List<Question> questions) {
    final departmentName = getDepartmentNameById(_userDepartmentId);
    final departmentQuestions = questions
        .where((q) => q.department == departmentName)
        .toList();
    _groupQuestionsByCourse(departmentQuestions);
  }

  Future<void> refreshCourses() async {
    try {
      // REFACTORED: Repository now handles its own sync time.
      await _questionRepository.syncWithRemote();
      // REFACTORED: Removed cache manager logic
      // final cacheKey = 'courses_${getDepartmentNameById(_userDepartmentId)}';
      // await _cacheManager.setLastSyncTime(cacheKey, DateTime.now());
    } catch (e) {
      _errorMessage = "Failed to refresh courses: ${e.toString()}";
      notifyListeners();
    }
  }

  void _groupQuestionsByCourse(List<Question> questions) {
    final tempGroupedCourses = <String, List<Question>>{};
    for (var question in questions) {
      tempGroupedCourses
          .putIfAbsent(question.courseName, () => [])
          .add(question);
    }

    final sortedCourseNames = tempGroupedCourses.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    _courses = {
      for (var courseName in sortedCourseNames)
        courseName: tempGroupedCourses[courseName]!,
    };

    _applySearchFilter();
  }

  void searchCourses(String query) {
    _searchQuery = query.toLowerCase().trim();
    _applySearchFilter();
    notifyListeners();
  }

  void _applySearchFilter() {
    if (_searchQuery.isEmpty) {
      _filteredCourses = Map.from(_courses);
    } else {
      _filteredCourses = {};
      _courses.forEach((courseName, questions) {
        if (courseName.toLowerCase().contains(_searchQuery) ||
            questions.any(
                  (q) => q.courseCode.toLowerCase().contains(_searchQuery),
            )) {
          _filteredCourses[courseName] = questions;
        }
      });
    }
  }

  Future<void> incrementViewCount(String questionId) async {
    try {
      await _questionRepository.incrementViewCount(questionId);
    } catch (e) {
      debugPrint('Error incrementing view count: $e');
    }
  }
}