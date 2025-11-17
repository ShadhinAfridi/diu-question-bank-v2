// repositories/interfaces/point_transaction_repository.dart
import '../../models/point_transaction_model.dart';
import '../interfaces/base_repository.dart';

abstract class IPointTransactionRepository implements IBaseRepository<PointTransaction> {
  // Add userId getter to the interface
  String get userId;

  Future<void> addEarnedPoints({
    required int points,
    required String description,
    String? referenceId,
    String category = 'general',
  });

  Future<void> addSpentPoints({
    required int points,
    required String description,
    required String referenceId,
    String category = 'general',
  });

  Future<List<PointTransaction>> getRecentTransactions({int limit = 10});
  Future<int> getTotalPointsEarned();
  Future<int> getTotalPointsSpent();
  Future<int> getCurrentBalance();
  void dispose();
}