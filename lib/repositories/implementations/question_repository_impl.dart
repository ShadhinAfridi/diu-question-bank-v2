// repositories/implementations/question_repository_impl.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import '../../models/base_model.dart';
import '../../models/question_model.dart';
import '../interfaces/question_repository.dart';
import '../../providers/cache_providers.dart';

class QuestionRepositoryImpl implements IQuestionRepository {
  final FirebaseFirestore _firestore;
  final String? userDepartmentId;
  final QuestionRepositoryCache _cache;

  StreamSubscription<QuerySnapshot>? _firestoreSubscription;
  bool _isRealTimeListening = false;

  QuestionRepositoryImpl({
    required this.userDepartmentId,
    required FirebaseFirestore firestore,
    required QuestionRepositoryCache cache,
  })  : _firestore = firestore,
        _cache = cache;

  @override
  Future<Question?> get(String id) async {
    try {
      debugPrint('QuestionRepository: Getting question $id');

      // Cache-first strategy
      final cached = _cache.questionBox.get(id);
      if (cached != null && await _cache.isCacheValid()) {
        debugPrint('QuestionRepository: Cache hit for question $id');

        // --- FIX 1: .touch() is a void method ---
        cached.touch(); // 1. Call the void method to update lastAccessed
        await _cache.questionBox.put(id, cached); // 2. Save the modified object
        return cached; // 3. Return the modified object
        // --- END FIX 1 ---
      }

      debugPrint(
          'QuestionRepository: Cache miss for question $id, fetching from Firestore');
      final doc = await _firestore.collection('question-info').doc(id).get();
      if (doc.exists) {
        final question = Question.fromFirestore(doc);
        await _cache.questionBox.put(id, question);
        await _cache.setLastSyncTime(DateTime.now());
        return question;
      }

      debugPrint('QuestionRepository: Question $id not found in Firestore');
      return null;
    } catch (e) {
      debugPrint('Error getting question $id: $e');
      // Fallback to stale cache
      final cached = _cache.questionBox.get(id);
      if (cached != null) {
        debugPrint('QuestionRepository: Using stale cache as fallback for $id');
      }
      return cached;
    }
  }

  @override
  Future<List<Question>> getAll() async {
    try {
      debugPrint('QuestionRepository: Getting all questions');

      final cachedQuestions = _cache.questionBox.values.toList();

      if (cachedQuestions.isNotEmpty && await _cache.isCacheValid()) {
        debugPrint(
            'QuestionRepository: Using ${cachedQuestions.length} cached questions');
        return _sortQuestions(cachedQuestions);
      }

      debugPrint(
          'QuestionRepository: Cache invalid or empty, loading from Firestore');
      return await _loadQuestionsFromFirestore();
    } catch (e) {
      debugPrint('Error getting all questions: $e');
      final cachedQuestions = _cache.questionBox.values.toList();
      debugPrint(
          'QuestionRepository: Using ${cachedQuestions.length} stale cached questions as fallback');
      return _sortQuestions(cachedQuestions);
    }
  }

  @override
  Future<void> save(Question item) async {
    try {
      debugPrint('QuestionRepository: Saving question ${item.id}');

      final updatedQuestion = item.copyWith(
        updatedAt: DateTime.now(),
        version: item.version + 1,
        syncStatus: SyncStatus.pending,
      );

      // Write to Firestore
      await _firestore
          .collection('question-info')
          .doc(item.id)
          .set(updatedQuestion.toFirestore());

      // Update cache with synced status
      final cachedQuestion =
      updatedQuestion.copyWith(syncStatus: SyncStatus.synced);
      await _cache.questionBox.put(item.id, cachedQuestion);
      await _cache.setLastSyncTime(DateTime.now());

      debugPrint('QuestionRepository: Question saved successfully: ${item.id}');
    } catch (e) {
      debugPrint('Error saving question: $e');

      // Save to cache with pending status for offline support
      final offlineQuestion = item.copyWith(
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.pending,
      );
      await _cache.questionBox.put(item.id, offlineQuestion);

      rethrow;
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      debugPrint('QuestionRepository: Deleting question $id');

      await _firestore.collection('question-info').doc(id).delete();
      await _cache.questionBox.delete(id);
      await _cache.setLastSyncTime(DateTime.now());

      debugPrint('QuestionRepository: Question deleted successfully: $id');
    } catch (e) {
      debugPrint('Error deleting question: $e');

      // Mark as deleted in cache for offline support
      final cached = _cache.questionBox.get(id);
      if (cached != null) {
        // --- FIX 2: Use the 'pendingDelete' state from base_model.dart ---
        final deletedQuestion = cached.copyWith(
          syncStatus: SyncStatus.pendingDelete,
          updatedAt: DateTime.now(),
        );
        // --- END FIX 2 ---
        await _cache.questionBox.put(id, deletedQuestion);
      }

      rethrow;
    }
  }

  @override
  Stream<List<Question>> watchAll() async* {
    debugPrint('QuestionRepository: Watching all questions');

    // Yield current cached data immediately
    final initialQuestions = _cache.questionBox.values.toList();
    yield _sortQuestions(initialQuestions);

    // Yield updates from cache changes
    yield* _cache.questionBox.watch().map((event) {
      return _sortQuestions(_cache.questionBox.values.toList());
    });
  }

  @override
  Stream<List<Question>> watchFiltered({
    String? searchQuery,
    String? examType,
    String? courseCode,
  }) async* {
    final allStream = watchAll();

    await for (final questions in allStream) {
      var filtered = questions;

      if (searchQuery?.isNotEmpty == true) {
        final query = searchQuery!.toLowerCase();
        filtered = filtered
            .where((q) =>
        q.courseName.toLowerCase().contains(query) ||
            q.courseCode.toLowerCase().contains(query) ||
            q.teacherName.toLowerCase().contains(query))
            .toList();
      }

      if (examType?.isNotEmpty == true) {
        filtered = filtered.where((q) => q.examType == examType).toList();
      }

      if (courseCode?.isNotEmpty == true) {
        filtered = filtered.where((q) => q.courseCode == courseCode).toList();
      }

      yield filtered;
    }
  }

  @override
  Future<List<Question>> getQuestions({int limit = 20, int offset = 0}) async {
    final questions = await getAll();
    return questions.skip(offset).take(limit).toList();
  }

  @override
  Future<void> syncWithRemote() async {
    try {
      debugPrint('QuestionRepository: Starting sync with remote');

      if (userDepartmentId == null) {
        throw Exception('User department ID is required for question sync');
      }

      await _performFullSync();
      if (!_isRealTimeListening) {
        await _startRealTimeListener();
      }

      debugPrint('QuestionRepository: Sync completed successfully');
    } catch (e) {
      debugPrint('Error syncing questions: $e');
      rethrow;
    }
  }

  @override
  Future<void> clearCache() async {
    debugPrint('QuestionRepository: Clearing cache');
    await _cache.questionBox.clear();
    await _cache.clearCache();
    debugPrint('QuestionRepository: Cache cleared successfully');
  }

  @override
  Future<void> preloadData() async {
    try {
      if (userDepartmentId == null) {
        throw Exception('User department ID is required for question preloading');
      }

      debugPrint(
          'QuestionRepository: Preloading data for department $userDepartmentId');

      await _performFullSync();
      if (!_isRealTimeListening) {
        await _startRealTimeListener();
      }

      debugPrint('QuestionRepository: Data preloaded successfully');
    } catch (e) {
      debugPrint('Error preloading data: $e');
      rethrow;
    }
  }

  @override
  Future<DateTime?> getLastSyncTime() => _cache.getLastSyncTime();

  @override
  Future<void> setLastSyncTime(DateTime time) => _cache.setLastSyncTime(time);

  @override
  Future<bool> isCacheValid() => _cache.isCacheValid();

  @override
  Stream<Map<String, Question>> watchAllAsMap() async* {
    yield {for (var q in _cache.questionBox.values) q.id: q};

    yield* _cache.questionBox.watch().map((event) {
      return {for (var q in _cache.questionBox.values) q.id: q};
    });
  }

  @override
  Future<List<Question>> getByDepartment(String department) async {
    try {
      debugPrint(
          'QuestionRepository: Getting questions by department: $department');

      // Try cache first
      final cachedQuestions =
      await _cache.getCachedQuestionsByDepartment(department);
      if (cachedQuestions.isNotEmpty && await _cache.isCacheValid()) {
        debugPrint(
            'QuestionRepository: Using ${cachedQuestions.length} cached department questions');
        return cachedQuestions;
      }

      // Fetch from Firestore
      final querySnapshot = await _firestore
          .collection('question-info')
          .where('department', isEqualTo: department)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      final questions =
      querySnapshot.docs.map((doc) => Question.fromFirestore(doc)).toList();

      // Update cache
      final questionsMap = {for (var q in questions) q.id: q};
      await _cache.questionBox.putAll(questionsMap);
      await _cache.setLastSyncTime(DateTime.now());
      await _cache.cleanupOldQuestions();

      debugPrint(
          'QuestionRepository: Fetched ${questions.length} questions for department $department');
      return questions;
    } catch (e) {
      debugPrint('Error getting questions by department: $e');
      return await _cache.getCachedQuestionsByDepartment(department);
    }
  }

  @override
  Future<List<Question>> searchQuestions({
    required String query,
    String? department,
    String? examType,
    String? semester,
    int limit = 20,
  }) async {
    try {
      debugPrint('QuestionRepository: Searching questions with query: $query');

      // Cache-first search
      final cachedQuestions = _cache.questionBox.values.toList();
      final searchQuery = query.toLowerCase();

      var results = cachedQuestions
          .where((question) =>
      question.courseName.toLowerCase().contains(searchQuery) ||
          question.courseCode.toLowerCase().contains(searchQuery) ||
          question.teacherName.toLowerCase().contains(searchQuery))
          .toList();

      // Apply filters
      if (department != null && department.isNotEmpty) {
        results = results.where((q) => q.department == department).toList();
      }
      if (examType != null && examType.isNotEmpty) {
        results = results.where((q) => q.examType == examType).toList();
      }
      if (semester != null && semester.isNotEmpty) {
        results = results.where((q) => q.semester == semester).toList();
      }

      if (results.isNotEmpty && await _cache.isCacheValid()) {
        debugPrint(
            'QuestionRepository: Found ${results.length} cached search results');
        return _sortQuestions(results).take(limit).toList();
      }

      // Firestore search
      Query firestoreQuery = _firestore
          .collection('question-info')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (department != null && department.isNotEmpty) {
        firestoreQuery =
            firestoreQuery.where('department', isEqualTo: department);
      }
      if (examType != null && examType.isNotEmpty) {
        firestoreQuery = firestoreQuery.where('examType', isEqualTo: examType);
      }
      if (semester != null && semester.isNotEmpty) {
        firestoreQuery = firestoreQuery.where('semester', isEqualTo: semester);
      }

      final querySnapshot = await firestoreQuery.get();

      results = querySnapshot.docs
          .map((doc) => Question.fromFirestore(doc))
          .where((question) =>
      question.courseName.toLowerCase().contains(searchQuery) ||
          question.courseCode.toLowerCase().contains(searchQuery) ||
          question.teacherName.toLowerCase().contains(searchQuery))
          .toList();

      // Update cache with search results
      final resultsMap = {for (var q in results) q.id: q};
      await _cache.questionBox.putAll(resultsMap);

      debugPrint(
          'QuestionRepository: Found ${results.length} search results from Firestore');
      return _sortQuestions(results);
    } catch (e) {
      debugPrint('Error searching questions: $e');

      // Fallback to cached search
      final cachedQuestions = _cache.questionBox.values.toList();
      final searchQuery = query.toLowerCase();
      final results = cachedQuestions
          .where((question) =>
      question.courseName.toLowerCase().contains(searchQuery) ||
          question.courseCode.toLowerCase().contains(searchQuery) ||
          question.teacherName.toLowerCase().contains(searchQuery))
          .toList();

      return _sortQuestions(results).take(limit).toList();
    }
  }

  @override
  Future<List<Question>> getQuestionsByCourse(String courseCode) async {
    try {
      final querySnapshot = await _firestore
          .collection('question-info')
          .where('courseCode', isEqualTo: courseCode)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return querySnapshot.docs
          .map((doc) => Question.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting questions by course: $e');
      rethrow;
    }
  }

  @override
  Future<void> incrementViewCount(String questionId) async {
    try {
      final question = await get(questionId);
      if (question != null) {
        final updatedQuestion = question.incrementView();
        await save(updatedQuestion);
      }
    } catch (e) {
      debugPrint('Error incrementing view count: $e');
      rethrow;
    }
  }

  @override
  Future<void> incrementDownloadCount(String questionId) async {
    try {
      final question = await get(questionId);
      if (question != null) {
        final updatedQuestion = question.incrementDownload();
        await save(updatedQuestion);
      }
    } catch (e) {
      debugPrint('Error incrementing download count: $e');
      rethrow;
    }
  }

  @override
  Future<List<Question>> getPopularQuestions({int limit = 10}) async {
    try {
      final allQuestions = await getAll();
      return allQuestions.where((q) => q.isPopular).take(limit).toList();
    } catch (e) {
      debugPrint('Error getting popular questions: $e');
      rethrow;
    }
  }

  @override
  Future<List<Question>> getRecentQuestions({int limit = 10}) async {
    try {
      final allQuestions = await getAll();
      return allQuestions.where((q) => q.isRecent).take(limit).toList();
    } catch (e) {
      debugPrint('Error getting recent questions: $e');
      rethrow;
    }
  }

  // ============ PRIVATE METHODS ============

  Future<void> _performFullSync() async {
    debugPrint('QuestionRepository: Performing full sync');

    if (userDepartmentId == null) {
      debugPrint('QuestionRepository: Cannot sync, userDepartmentId is null');
      return;
    }

    final departmentName = _getDepartmentNameById(userDepartmentId);
    final querySnapshot = await _firestore
        .collection('question-info')
        .where('department', isEqualTo: departmentName)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get();

    final questionsMap = <String, Question>{};
    for (final doc in querySnapshot.docs) {
      final question = Question.fromFirestore(doc);
      questionsMap[question.id] = question;
    }

    // Batch update cache
    await _cache.questionBox.clear();
    await _cache.questionBox.putAll(questionsMap);
    await _cache.setLastSyncTime(DateTime.now());
    await _cache.cleanupOldQuestions();

    debugPrint(
        'QuestionRepository: Full sync completed: ${questionsMap.length} questions');
  }

  Future<void> _startRealTimeListener() async {
    _firestoreSubscription?.cancel();

    if (userDepartmentId == null) {
      debugPrint(
          'QuestionRepository: Cannot start listener, userDepartmentId is null');
      return;
    }

    final departmentName = _getDepartmentNameById(userDepartmentId);

    _firestoreSubscription = _firestore
        .collection('question-info')
        .where('department', isEqualTo: departmentName)
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.docChanges.isEmpty) return;

      debugPrint(
          'QuestionRepository: Real-time update with ${snapshot.docChanges.length} changes');

      for (final change in snapshot.docChanges) {
        final question = Question.fromFirestore(change.doc);

        switch (change.type) {
          case DocumentChangeType.added:
          case DocumentChangeType.modified:
            await _cache.questionBox.put(question.id, question);
            break;
          case DocumentChangeType.removed:
            await _cache.questionBox.delete(question.id);
            break;
        }
      }

      await _cache.setLastSyncTime(DateTime.now());
      _isRealTimeListening = true;
    }, onError: (error) {
      debugPrint('QuestionRepository: Real-time listener error: $error');
      _isRealTimeListening = false;
    });
  }

  Future<List<Question>> _loadQuestionsFromFirestore() async {
    debugPrint('QuestionRepository: Loading questions from Firestore');

    Query query = _firestore
        .collection('question-info')
        .orderBy('createdAt', descending: true)
        .limit(100);

    if (userDepartmentId != null) {
      final departmentName = _getDepartmentNameById(userDepartmentId);
      query = query.where('department', isEqualTo: departmentName);
    }

    final querySnapshot = await query.get();
    final questions =
    querySnapshot.docs.map((doc) => Question.fromFirestore(doc)).toList();

    // Batch update cache
    final questionsMap = {for (var q in questions) q.id: q};
    await _cache.questionBox.putAll(questionsMap);
    await _cache.setLastSyncTime(DateTime.now());
    await _cache.cleanupOldQuestions();

    debugPrint(
        'QuestionRepository: Loaded ${questions.length} questions from Firestore');
    return _sortQuestions(questions);
  }

  List<Question> _sortQuestions(List<Question> questions) {
    return questions..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  String _getDepartmentNameById(String? departmentId) {
    final departmentMap = {
      'cse': 'Computer Science and Engineering',
      'eee': 'Electrical and Electronic Engineering',
      'bba': 'Business Administration',
      'eng': 'English',
      'mba': 'Business Administration',
    };
    return departmentMap[departmentId] ?? departmentId ?? 'default';
  }

  @override
  void dispose() {
    _firestoreSubscription?.cancel();
    _isRealTimeListening = false;
    debugPrint('QuestionRepository: Disposed');
  }
}