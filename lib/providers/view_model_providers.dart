// view_model_providers.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/user_model.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/course_viewmodel.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../viewmodels/notifications_viewmodel.dart';
import '../viewmodels/points_viewmodel.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../viewmodels/question_viewmodel.dart';
import '../viewmodels/subscription_viewmodel.dart';
import '../viewmodels/task_manager_viewmodel.dart';
import 'cache_providers.dart';

// --- Auth Providers ---
// Auth ViewModel Provider
final authViewModelProvider = AsyncNotifierProvider<AuthViewModel, UserModel?>(
  AuthViewModel.new,
);

// FIXED: Simplified Auth Initialization Provider
final authInitializationProvider = FutureProvider<bool>((ref) async {
  debugPrint('AuthInitialization: Starting auth initialization...');

  try {
    // Wait for auth state to settle
    final authState = await ref.watch(authViewModelProvider.future);

    debugPrint('AuthInitialization: Auth state settled - User: ${authState != null}');

    // Give it a small delay to ensure everything is settled
    await Future.delayed(const Duration(milliseconds: 200));

    debugPrint('AuthInitialization: Auth initialization complete');
    return true;
  } catch (e, s) {
    debugPrint('AuthInitialization: Auth initialization error: $e');
    // Even if there's an error, we should continue so the app doesn't get stuck
    return true;
  }
});

// FIXED: Safe user context providers that handle null/loading states
final userDepartmentIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authViewModelProvider);

  // Handle loading and error states gracefully
  return authState.when(
    data: (user) => user?.department ?? 'cse', // Default to 'cse'
    loading: () => 'cse', // Default during loading
    error: (error, stack) => 'cse', // Default on error
  );
});


// FIXED: Add a provider to check if auth is ready
final isAuthReadyProvider = Provider<bool>((ref) {
  final authState = ref.watch(authViewModelProvider);
  return !authState.isLoading && !authState.hasError;
});

// --- ViewModel Providers (Refactored) ---

// Dashboard ViewModel Provider with auth guard
final dashboardViewModelProvider = ChangeNotifierProvider<DashboardViewModel>((ref) {
  debugPrint('Creating DashboardViewModel...');
  // Only create when auth is ready
  ref.watch(isAuthReadyProvider);
  return DashboardViewModel(ref);
});

// Profile ViewModel Provider
final profileViewModelProvider = ChangeNotifierProvider<ProfileViewModel>((ref) {
  ref.watch(isAuthReadyProvider);
  return ProfileViewModel(ref);
});

// Question ViewModel Provider
final questionViewModelProvider = ChangeNotifierProvider<QuestionViewModel>((ref) {
  ref.watch(isAuthReadyProvider);
  return QuestionViewModel(ref);
});

// Course ViewModel Provider
final courseViewModelProvider = ChangeNotifierProvider<CourseViewModel>((ref) {
  ref.watch(isAuthReadyProvider);
  return CourseViewModel(ref);
});

// FIXED: Points ViewModel Provider - Use the actual constructor from your ViewModel
final pointsViewModelProvider = ChangeNotifierProvider<PointsViewModel>((ref) {
  final userId = ref.watch(userIdProvider);
  debugPrint('Creating PointsViewModel - User ID: $userId');

  // Just create the ViewModel normally - it will handle empty userId internally
  return PointsViewModel(ref);
});

// FIXED: Subscription ViewModel Provider - Use the actual constructor from your ViewModel
final subscriptionViewModelProvider = ChangeNotifierProvider<SubscriptionViewModel>((ref) {
  final userId = ref.watch(userIdProvider);
  debugPrint('Creating SubscriptionViewModel - User ID: $userId');

  // Just create the ViewModel normally - it will handle empty userId internally
  return SubscriptionViewModel(ref);
});

// Task Manager ViewModel Provider
final taskManagerViewModelProvider = ChangeNotifierProvider<TaskManagerViewModel>((ref) {
  return TaskManagerViewModel(ref);
});

// Notifications ViewModel Provider
final notificationsViewModelProvider = ChangeNotifierProvider<NotificationsViewModel>((ref) {
  return NotificationsViewModel(ref);
});

// --- Helper Providers ---

final refreshProvider = StateProvider<int>((ref) => 0);

void refreshAllViewModels(Ref ref) {
  ref.read(refreshProvider.notifier).state++;

  // Invalidate specific providers that need refresh
  ref.invalidate(questionViewModelProvider);
  ref.invalidate(courseViewModelProvider);
  ref.invalidate(dashboardViewModelProvider);
  ref.invalidate(pointsViewModelProvider);
  ref.invalidate(subscriptionViewModelProvider);
}

// Provider for checking if any view model is loading
final isLoadingProvider = Provider<bool>((ref) {
  final authState = ref.watch(authViewModelProvider);
  final dashboardState = ref.watch(dashboardViewModelProvider);
  final questionState = ref.watch(questionViewModelProvider);
  final courseState = ref.watch(courseViewModelProvider);
  final pointsState = ref.watch(pointsViewModelProvider);
  final subscriptionState = ref.watch(subscriptionViewModelProvider);

  return authState.isLoading ||
      dashboardState.isLoading ||
      questionState.isLoading ||
      courseState.isLoading ||
      pointsState.isLoading ||
      subscriptionState.isLoading;
});

// Provider for global error state
final globalErrorProvider = StateProvider<String?>((ref) => null);

// Individual loading state providers for more granular control
final authLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authViewModelProvider).isLoading;
});

final dashboardLoadingProvider = Provider<bool>((ref) {
  return ref.watch(dashboardViewModelProvider).isLoading;
});

final questionLoadingProvider = Provider<bool>((ref) {
  return ref.watch(questionViewModelProvider).isLoading;
});

final courseLoadingProvider = Provider<bool>((ref) {
  return ref.watch(courseViewModelProvider).isLoading;
});

final pointsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(pointsViewModelProvider).isLoading;
});

final subscriptionLoadingProvider = Provider<bool>((ref) {
  return ref.watch(subscriptionViewModelProvider).isLoading;
});

// Provider for checking if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authViewModelProvider);
  return authState.value != null;
});

// Provider for current user
final currentUserProvider = Provider<UserModel?>((ref) {
  final authState = ref.watch(authViewModelProvider);
  return authState.value;
});