// repositories/interfaces/user_repository.dart
import '../../models/subscription_model.dart';
import '../../models/user_model.dart';
import 'base_repository.dart';

abstract class IUserRepository implements IBaseRepository<UserModel> {
  Future<void> updateUserPoints(String userId, int newPoints);
  Future<void> addPoints(String userId, int pointsToAdd);
  Future<void> addUploadedQuestion(String userId, String questionId);
  Future<void> addAccessedQuestion(String userId, String questionId);
  Future<void> incrementAdsWatched(String userId);
  Future<void> updateSubscription(String userId, Subscription subscription);
  Future<void> updatePreferences(String userId, Map<String, dynamic> preferences);
  Future<void> updateLastLogin(String userId);
  Future<void> updateFcmToken(String userId, String? fcmToken);
  Future<void> levelUpUser(String userId);
  void dispose();
}