// course_viewmodel.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../data/departments.dart';
import '../models/question_model.dart';

class CourseViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? _userDepartmentId;
  final Box<Question> _questionsBox = Hive.box<Question>('questions');
  StreamSubscription? _questionSubscription;

  bool _isLoading = false;
  String? _errorMessage;
  Map<String, List<Question>> _courses = {};
  Map<String, List<Question>> _filteredCourses = {};
  String _searchQuery = '';

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, List<Question>> get courses => _courses;
  Map<String, List<Question>> get filteredCourses => _filteredCourses;

  CourseViewModel({required String? userDepartmentId}) : _userDepartmentId = userDepartmentId {
    if (_userDepartmentId == null || _userDepartmentId!.isEmpty) {
      _errorMessage = "Please set your department in your profile to view questions.";
      _isLoading = false;
      return;
    }
    _listenToCourses();
  }

  @override
  void dispose() {
    _questionSubscription?.cancel();
    super.dispose();
  }

  void _listenToCourses() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // 1. Load from cache immediately for a fast UI response
    final departmentName = getDepartmentNameById(_userDepartmentId);
    final cachedQuestions = _questionsBox.values.where((q) => q.department == departmentName).toList();
    if (cachedQuestions.isNotEmpty) {
      _groupQuestionsByCourse(cachedQuestions);
      _isLoading = false; // We have data, so we can stop showing the main loading indicator
      notifyListeners();
    }

    // 2. Set up Firestore listener for real-time updates
    final query = _firestore
        .collection('question-info')
        .where('department', isEqualTo: departmentName)
        .orderBy('processedAt', descending: true);

    _questionSubscription?.cancel(); // Cancel any existing listener
    _questionSubscription = query.snapshots().listen((snapshot) async {
      final fetchedQuestions = snapshot.docs.map((doc) => Question.fromFirestore(doc)).toList();

      // 3. Update cache and UI
      await _cacheQuestions(fetchedQuestions);
      _groupQuestionsByCourse(fetchedQuestions);

      if (_isLoading) _isLoading = false;
      _errorMessage = null;
      notifyListeners();

    }, onError: (error) {
      _errorMessage = "Error listening to questions: ${error.toString()}";
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> refreshCourses() async {
    try {
      final querySnapshot = await _firestore
          .collection('question-info')
          .where('department', isEqualTo: getDepartmentNameById(_userDepartmentId))
          .orderBy('processedAt', descending: true)
          .get();

      final fetchedQuestions = querySnapshot.docs.map((doc) => Question.fromFirestore(doc)).toList();

      await _cacheQuestions(fetchedQuestions);
      _groupQuestionsByCourse(fetchedQuestions);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = "Failed to refresh courses: ${e.toString()}";
    } finally {
      notifyListeners(); // Update UI after manual refresh
    }
  }

  Future<void> _cacheQuestions(List<Question> questionsToCache) async {
    try {
      final departmentName = getDepartmentNameById(_userDepartmentId);

      // Find all keys for the current department and delete them before adding new ones
      final Map<dynamic, Question> allBoxData = _questionsBox.toMap();
      final List<dynamic> keysToDelete = [];
      allBoxData.forEach((key, value) {
        if (value.department == departmentName) {
          keysToDelete.add(key);
        }
      });

      if (keysToDelete.isNotEmpty) {
        await _questionsBox.deleteAll(keysToDelete);
      }

      final newQuestionMap = {for (var q in questionsToCache) q.id: q};
      await _questionsBox.putAll(newQuestionMap);
    } catch (e) {
      // Continue even if caching fails, so the app remains functional
      if (kDebugMode) {
        print('Error caching questions: $e');
      }
    }
  }

  void _groupQuestionsByCourse(List<Question> questions) {
    // Group all questions by course name into a temporary map
    final tempGroupedCourses = <String, List<Question>>{};
    for (var question in questions) {
      tempGroupedCourses.putIfAbsent(question.courseName, () => []).add(question);
    }

    // Get the list of course names and sort them alphabetically (case-insensitive)
    final sortedCourseNames = tempGroupedCourses.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    // Create the final, sorted map of courses
    _courses = {
      for (var courseName in sortedCourseNames) courseName: tempGroupedCourses[courseName]!
    };

    // After sorting, re-apply the current search filter
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
            questions.any((q) => q.courseCode.toLowerCase().contains(_searchQuery))) {
          _filteredCourses[courseName] = questions;
        }
      });
    }
    notifyListeners();
  }
}