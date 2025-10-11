import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import '../models/question_model.dart';

class QuestionCacheRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? userDepartmentId;
  final String boxName = 'questions_v2';

  StreamSubscription<QuerySnapshot>? _firestoreSubscription;

  QuestionCacheRepository({required this.userDepartmentId});

  Future<Box<Question>> get box => Hive.openBox<Question>(boxName);

  Future<void> preloadData() async {
    if (userDepartmentId == null) {
      throw Exception('User department ID is required for question preloading');
    }

    try {
      final questionsBox = await box;
      await _performFullSync(questionsBox);
      await _startRealTimeListener();
    } catch (e) {
      debugPrint('Question preload error: $e');
      rethrow;
    }
  }

  Future<void> _performFullSync(Box<Question> questionsBox) async {
    debugPrint('Performing full sync for questions');

    final departmentName = _getDepartmentNameById(userDepartmentId);
    final querySnapshot = await _firestore
        .collection('question-info')
        .where('department', isEqualTo: departmentName)
        .orderBy('processedAt', descending: true)
        .limit(100)
        .get();

    final questionsMap = <String, Question>{};
    for (final doc in querySnapshot.docs) {
      final question = Question.fromFirestore(doc);
      questionsMap[question.id] = question;
    }

    await questionsBox.clear();
    await questionsBox.putAll(questionsMap);

    debugPrint('Full sync completed: ${questionsMap.length} questions');
  }

  Future<void> _startRealTimeListener() async {
    _firestoreSubscription?.cancel();

    final departmentName = _getDepartmentNameById(userDepartmentId);

    _firestoreSubscription = _firestore
        .collection('question-info')
        .where('department', isEqualTo: departmentName)
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.docChanges.isEmpty) return;

      final questionsBox = await box;

      for (final change in snapshot.docChanges) {
        final question = Question.fromFirestore(change.doc);

        switch (change.type) {
          case DocumentChangeType.added:
          case DocumentChangeType.modified:
            await questionsBox.put(question.id, question);
            break;
          case DocumentChangeType.removed:
            await questionsBox.delete(question.id);
            break;
        }
      }
    }, onError: (error) {
      debugPrint('Real-time listener error: $error');
    });
  }

  Stream<List<Question>> watchAll() async* {
    final questionsBox = await box;

    yield questionsBox.values.toList()
      ..sort((a, b) => b.processedAt.compareTo(a.processedAt));

    yield* questionsBox.watch().map((event) {
      return questionsBox.values.toList()
        ..sort((a, b) => b.processedAt.compareTo(a.processedAt));
    });
  }

  Stream<List<Question>> watchFiltered({
    String? searchQuery,
    String? examType,
  }) async* {
    final allStream = watchAll();

    await for (final questions in allStream) {
      var filtered = questions;

      if (searchQuery?.isNotEmpty == true) {
        final query = searchQuery!.toLowerCase();
        filtered = filtered.where((q) =>
        q.courseName.toLowerCase().contains(query) ||
            q.courseCode.toLowerCase().contains(query)
        ).toList();
      }

      if (examType?.isNotEmpty == true) {
        filtered = filtered.where((q) => q.examType == examType).toList();
      }

      yield filtered;
    }
  }

  Future<List<Question>> getQuestions({
    int limit = 20,
    int offset = 0,
  }) async {
    final questionsBox = await box;
    final questions = questionsBox.values.toList()
      ..sort((a, b) => b.processedAt.compareTo(a.processedAt));

    return questions.skip(offset).take(limit).toList();
  }

  Future<void> syncWithRemote() async {
    await preloadData();
  }

  Future<void> clearCache() async {
    final questionsBox = await box;
    await questionsBox.clear();
  }

  String _getDepartmentNameById(String? departmentId) {
    // Implement your department lookup logic here
    return departmentId ?? 'default';
  }

  void dispose() {
    _firestoreSubscription?.cancel();
  }
}