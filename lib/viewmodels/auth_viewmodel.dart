import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../models/base_model.dart';
import '../models/point_transaction_model.dart';
import '../models/question_model.dart';
import '../models/subscription_model.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';
import '../providers/repository_providers.dart';
import '../providers/service_providers.dart';
import '../repositories/interfaces/user_repository.dart';
import '../services/auth_service.dart';

class AuthViewModel extends AsyncNotifier<UserModel?> {
  late final AuthService _authService;
  late final IUserRepository _userRepository;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<UserModel?>? _userSubscription;

  static const int _kResendEmailCooldown = 120;
  Timer? _resendCooldownTimer;

  final ValueNotifier<bool> isResendDisabled = ValueNotifier(false);
  final ValueNotifier<int> resendTimer = ValueNotifier(_kResendEmailCooldown);

  @override
  Future<UserModel?> build() async {
    debugPrint('AuthViewModel: Building...');

    // Initialize services
    _authService = ref.watch(authServiceProvider);
    _userRepository = ref.watch(userRepositoryProvider);

    // Set up cleanup on provider disposal
    ref.onDispose(() {
      _cleanup();
    });

    // Set up auth state listener FIRST
    _authSubscription = _authService.authStateChanges.listen(_handleAuthStateChange);

    // Return initial user if available - FIXED VERSION
    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        debugPrint('AuthViewModel: Found current user: ${currentUser.uid}');
        final userModel = await _loadUserData(currentUser.uid);
        debugPrint('AuthViewModel: Initial user data loaded: ${userModel?.email}');
        return userModel;
      } else {
        debugPrint('AuthViewModel: No current user found');
        return null;
      }
    } catch (e, s) {
      debugPrint('AuthViewModel: Error in build: $e, $s');
      // Return null instead of throwing to allow app to continue
      return null;
    }
  }

  Future<UserModel?> _loadUserData(String userId) async {
    try {
      debugPrint('AuthViewModel: Loading user data for $userId');

      // Try to get user data from cache first, then network
      final userModel = await _userRepository.get(userId);

      if (userModel != null) {
        // Update last login and sync with current Firebase user data
        await _userRepository.updateLastLogin(userId);

        // Sync email verification status from Firebase
        final firebaseUser = _authService.currentUser;
        if (firebaseUser != null) {
          await firebaseUser.reload();
          final updatedFirebaseUser = _authService.currentUser;

          // If email verification status changed, update the cached user
          if (userModel.isEmailVerified != (updatedFirebaseUser?.emailVerified ?? false)) {
            final updatedUser = userModel.copyWith(
              isEmailVerified: updatedFirebaseUser?.emailVerified ?? false,
              updatedAt: DateTime.now(),
              version: userModel.version + 1,
            );

            await _userRepository.save(updatedUser);
            debugPrint('AuthViewModel: Updated email verification status in cache: ${updatedUser.isEmailVerified}');
            return updatedUser;
          }
        }

        debugPrint('AuthViewModel: User data loaded successfully: ${userModel.email}');
      } else {
        debugPrint('AuthViewModel: No user data found for ID: $userId');
      }
      return userModel;
    } catch (e) {
      debugPrint('AuthViewModel: Error loading user data: $e');
      // Don't throw here - return null to allow retry
      return null;
    }
  }

  void _handleAuthStateChange(User? firebaseUser) async {
    try {
      if (firebaseUser == null) {
        debugPrint('AuthViewModel: User signed out - clearing cache');
        state = const AsyncValue.data(null);
      } else {
        debugPrint('AuthViewModel: User signed in, fetching profile: ${firebaseUser.uid}');
        state = const AsyncValue.loading();
        final userModel = await _loadUserData(firebaseUser.uid);
        state = AsyncValue.data(userModel);

        if (userModel != null) {
          debugPrint('AuthViewModel: Auth state updated - User: ${userModel.email}, Verified: ${userModel.isEmailVerified}');
        } else {
          debugPrint('AuthViewModel: Auth state updated - No user data available');
        }
      }
    } catch (e, s) {
      debugPrint('AuthViewModel: Error in auth state change: $e');
      // Don't set error state here as it breaks the app
      // Instead, set to data null to allow app to continue
      state = const AsyncValue.data(null);
    }
  }

  Future<void> signIn(String email, String password) async {
    debugPrint('AuthViewModel: Signing in with: $email');
    state = const AsyncValue.loading();
    try {
      await _authService.signInWithEmailAndPassword(email, password);
      debugPrint('AuthViewModel: Sign in successful');
      // Auth state listener will handle success and navigation
    } catch (e, s) {
      debugPrint('AuthViewModel: Sign in error: $e');
      state = AsyncValue.error(e, s);
      rethrow;
    }
  }

  Future<void> signUp(String email, String password, String name) async {
    debugPrint('AuthViewModel: Signing up: $email');
    state = const AsyncValue.loading();
    try {
      final User? newUser = await _authService.createUserWithEmailAndPassword(
        email,
        password,
      );
      if (newUser != null) {
        debugPrint('AuthViewModel: User created: ${newUser.uid}');
        final userModel = UserModel(
          id: newUser.uid,
          email: email,
          name: name,
          department: 'cse', // Default department
          points: 0,
          uploadedQuestions: [],
          accessedQuestions: [],
          preferences: {},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          syncStatus: SyncStatus.synced,
          version: 0,
          subscription: Subscription.free(),
          isEmailVerified: false, // Explicitly set verification status
        );

        // Save user to cache and Firestore
        await _userRepository.save(userModel);
        await newUser.sendEmailVerification();
        _startResendTimer();

        debugPrint('AuthViewModel: User saved to cache and verification email sent');
      }
    } catch (e, s) {
      debugPrint('AuthViewModel: Sign up error: $e');
      state = AsyncValue.error(e, s);
      rethrow;
    }
  }

  Future<void> signOut() async {
    debugPrint('AuthViewModel: Signing out...');
    try {
      // Clear Hive cache for user-specific data
      await Hive.box<Question>('questions_v3').clear();
      await Hive.box<PointTransaction>('point_transactions_v3').clear();
      await Hive.box<Subscription>('subscriptions_v3').clear();
      await Hive.box<Task>('tasks_v3').clear();

      debugPrint('AuthViewModel: User-specific cache cleared');
    } catch (e) {
      debugPrint('AuthViewModel: Could not clear user cache: $e');
    }

    await _authService.signOut();
    debugPrint('AuthViewModel: Signed out from Firebase');
  }

  Future<void> resetPassword(String email) async {
    debugPrint('AuthViewModel: Resetting password for: $email');
    try {
      await _authService.sendPasswordResetEmail(email);
      debugPrint('AuthViewModel: Password reset email sent');
    } catch (e, s) {
      debugPrint('AuthViewModel: Reset password error: $e');
      rethrow;
    }
  }

  Future<void> checkEmailVerification() async {
    final user = _authService.currentUser;
    if (user == null) {
      debugPrint('AuthViewModel: No user for email verification check');
      return;
    }

    debugPrint('AuthViewModel: Checking email verification...');
    await user.reload();
    final currentUserModel = state.value;

    // Enhanced verification check with cache update
    if (user.emailVerified == true && currentUserModel != null) {
      debugPrint('AuthViewModel: Email verified! Updating cache...');
      final updatedUser = currentUserModel.copyWith(
        isEmailVerified: true,
        updatedAt: DateTime.now(),
        version: currentUserModel.version + 1,
      );

      state = const AsyncValue.loading();
      try {
        await _userRepository.save(updatedUser);
        state = AsyncValue.data(updatedUser);
        debugPrint('AuthViewModel: User cache updated with verified email');
      } catch (e, s) {
        debugPrint('AuthViewModel: Error updating verified user in cache: $e');
        state = AsyncValue.error(e, s);
      }
    } else {
      debugPrint('AuthViewModel: Email not verified yet - current status: ${user.emailVerified}');
    }
  }

  Future<void> sendVerificationEmail() async {
    final user = _authService.currentUser;
    if (user == null || isResendDisabled.value) return;

    debugPrint('AuthViewModel: Sending verification email...');
    try {
      await user.sendEmailVerification();
      _startResendTimer();
      debugPrint('AuthViewModel: Verification email sent');
    } on FirebaseAuthException catch (e, s) {
      debugPrint('AuthViewModel: Send verification email error: $e');
      rethrow;
    }
  }

  void _startResendTimer() {
    isResendDisabled.value = true;
    resendTimer.value = _kResendEmailCooldown;

    _resendCooldownTimer?.cancel();
    _resendCooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendTimer.value > 0) {
        resendTimer.value--;
      } else {
        isResendDisabled.value = false;
        timer.cancel();
      }
    });
  }

  void _cleanup() {
    debugPrint('AuthViewModel: Cleaning up...');
    _authSubscription?.cancel();
    _userSubscription?.cancel();
    _resendCooldownTimer?.cancel();
    isResendDisabled.dispose();
    resendTimer.dispose();
  }

  // Enhanced cache management methods
  Future<void> clearUserCache() async {
    try {
      await _userRepository.clearCache();
      debugPrint('AuthViewModel: User cache cleared');
    } catch (e) {
      debugPrint('AuthViewModel: Error clearing user cache: $e');
    }
  }

  Future<void> refreshUserData() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    debugPrint('AuthViewModel: Refreshing user data from network...');
    state = const AsyncValue.loading();
    try {
      final freshUserData = await _loadUserData(currentUser.uid);
      state = AsyncValue.data(freshUserData);
      debugPrint('AuthViewModel: User data refreshed successfully');
    } catch (e, s) {
      debugPrint('AuthViewModel: Error refreshing user data: $e');
      state = AsyncValue.error(e, s);
    }
  }

  // Helper method to check if user is verified
  bool get isUserVerified {
    final user = state.value;
    return user?.isEmailVerified ?? false;
  }

  // Helper method to get current user email
  String? get currentUserEmail {
    final user = state.value;
    return user?.email;
  }
}