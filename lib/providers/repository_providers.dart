import 'package:diuquestionbank/providers/view_model_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/implementations/notification_repository_impl.dart';
import '../repositories/implementations/point_transaction_repository_impl.dart';
import '../repositories/implementations/question_repository_impl.dart';
import '../repositories/implementations/slider_repository_impl.dart';
import '../repositories/implementations/subscription_repository_impl.dart';
import '../repositories/implementations/task_repository_impl.dart';
import '../repositories/implementations/user_repository_impl.dart';
import '../repositories/interfaces/notification_repository.dart';
import '../repositories/interfaces/point_transaction_repository.dart';
import '../repositories/interfaces/question_repository.dart';
import '../repositories/interfaces/slider_repository.dart';
import '../repositories/interfaces/subscription_repository.dart';
import '../repositories/interfaces/task_repository.dart';
import '../repositories/interfaces/user_repository.dart';
import 'cache_providers.dart';
import 'service_providers.dart';

// Repository Providers
final questionRepositoryProvider = Provider<IQuestionRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final departmentId = ref.watch(userDepartmentIdProvider) ?? 'cse';
  final cache = ref.watch(questionCacheProvider);

  return QuestionRepositoryImpl(
    userDepartmentId: departmentId,
    firestore: firestore,
    cache: cache,
  );
});

final userRepositoryProvider = Provider<IUserRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final cache = ref.watch(userCacheProvider);
  return UserRepositoryImpl(firestore: firestore, cache: cache);
});

final notificationRepositoryProvider = Provider<INotificationRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final auth = ref.watch(firebaseAuthProvider);
  final cache = ref.watch(notificationCacheProvider);
  return NotificationRepositoryImpl(
    firestore: firestore,
    auth: auth,
    cache: cache,
  );
});

final sliderRepositoryProvider = Provider<ISliderRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final cache = ref.watch(sliderCacheProvider);
  return SliderRepositoryImpl(firestore: firestore, cache: cache);
});

final taskRepositoryProvider = Provider<ITaskRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final cache = ref.watch(taskCacheProvider);
  final userId = ref.watch(userIdProvider);
  return TaskRepositoryImpl(
    firestore: firestore,
    cache: cache,
    userId: userId,
  );
});

final pointTransactionRepositoryProvider = Provider<IPointTransactionRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final userId = ref.watch(userIdProvider);
  final cache = ref.watch(pointTransactionCacheProvider);
  return PointTransactionRepositoryImpl(
    firestore: firestore,
    cache: cache,
    userId: userId,
  );
});

final subscriptionRepositoryProvider = Provider<ISubscriptionRepository>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final userId = ref.watch(userIdProvider);
  final cache = ref.watch(subscriptionCacheProvider);
  return SubscriptionRepositoryImpl(
    firestore: firestore,
    cache: cache,
    userId: userId,
  );
});


final canAccessPremiumProvider = FutureProvider<bool>((ref) async {
  final userId = ref.watch(userIdProvider);
  if (userId.isEmpty) return false;

  try {
    final subscriptionRepo = ref.read(subscriptionRepositoryProvider);
    return await subscriptionRepo.isPremiumUser();
  } catch (e) {
    return false;
  }
});

final userPointsBalanceProvider = FutureProvider<int>((ref) async {
  final userId = ref.watch(userIdProvider);
  if (userId.isEmpty) return 0;

  try {
    final pointTransactionRepo = ref.read(pointTransactionRepositoryProvider);
    return await pointTransactionRepo.getCurrentBalance();
  } catch (e) {
    return 0;
  }
});