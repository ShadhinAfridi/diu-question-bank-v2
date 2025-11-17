// repositories/interfaces/question_repository.dart
import '../../models/question_model.dart';
import 'base_repository.dart';

abstract class IQuestionRepository implements IBaseRepository<Question> {
  // Cache-specific methods
  @override
  Stream<List<Question>> watchAll();
  Stream<List<Question>> watchFiltered({
    String? searchQuery,
    String? examType,
    String? courseCode,
  });
  Stream<Map<String, Question>> watchAllAsMap();
  Future<void> preloadData();
  Future<DateTime?> getLastSyncTime();
  Future<void> setLastSyncTime(DateTime time);
  Future<bool> isCacheValid();

  // Question-specific methods
  Future<List<Question>> getByDepartment(String department);
  Future<List<Question>> searchQuestions({
    required String query,
    String? department,
    String? examType,
    String? semester,
    int limit = 20,
  });
  Future<List<Question>> getQuestionsByCourse(String courseCode);
  Future<void> incrementViewCount(String questionId);
  Future<void> incrementDownloadCount(String questionId);
  Future<List<Question>> getPopularQuestions({int limit = 10});
  Future<List<Question>> getRecentQuestions({int limit = 10});
  Future<List<Question>> getQuestions({
    int limit = 20,
    int offset = 0,
  });
  void dispose();
}