import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

// The AuthState enum is now simplified to only two possible states.
enum AuthState { authenticated, unauthenticated }

class AuthViewModel extends ChangeNotifier {
  // --- Dependencies ---
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Constants ---
  static const String _userCollection = 'users';
  static const int _kResendEmailCooldown = 120; // 2 minutes in seconds

  // --- Private State ---
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isResendDisabled = false;
  int _resendTimer = _kResendEmailCooldown;
  Timer? _resendCooldownTimer;
  // The initial state is now determined directly by the stream.
  AuthState? _authState;

  // --- Public Getters ---
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isResendDisabled => _isResendDisabled;
  int get resendTimer => _resendTimer;
  // The UI will now primarily listen to this state.
  AuthState? get authState => _authState;
  // The raw stream is still available if needed elsewhere.
  Stream<User?> get authStateChanges => _authService.authStateChanges;

  AuthViewModel() {
    // The view model now directly listens to the auth state stream from Firebase.
    // This is the single source of truth for the user's authentication status.
    _authService.authStateChanges.listen((user) {
      _user = user;
      // If the user object is null, they are unauthenticated, otherwise authenticated.
      _authState = user == null ? AuthState.unauthenticated : AuthState.authenticated;
      // Notify listeners (like the AuthWrapper) to rebuild with the new state.
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _resendCooldownTimer?.cancel();
    super.dispose();
  }

  // --- State Mutators (for UI feedback like loading spinners) ---
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setErrorMessage(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  void startResendTimer() {
    _isResendDisabled = true;
    _resendTimer = _kResendEmailCooldown;
    notifyListeners();

    _resendCooldownTimer?.cancel();
    _resendCooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        _resendTimer--;
      } else {
        _isResendDisabled = false;
        timer.cancel();
      }
      notifyListeners();
    });
  }

  // --- Authentication Logic ---
  // These methods now primarily handle the business logic and UI feedback (loading/errors),
  // while the stream listener above handles the actual state change.

  Future<void> signIn(String email, String password) async {
    _clearError();
    _setLoading(true);
    try {
      await _authService.signInWithEmailAndPassword(email, password);
    } on AuthServiceException catch (e) {
      _setErrorMessage(e.message);
    } catch (e) {
      _setErrorMessage('An unexpected error occurred. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signUp(String email, String password, String name) async {
    _clearError();
    _setLoading(true);
    try {
      final User? newUser = await _authService.createUserWithEmailAndPassword(email, password);
      if (newUser != null) {
        await _firestore.collection(_userCollection).doc(newUser.uid).set({
          'name': name,
          'email': email,
          'isVerified': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
        await newUser.sendEmailVerification();
        startResendTimer();
      }
    } on AuthServiceException catch (e) {
      _setErrorMessage(e.message);
    } catch (e) {
      _setErrorMessage('An unexpected error occurred. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  // Updated signOut method to accept a BuildContext parameter
  Future<void> signOut(BuildContext context) async {
    await _authService.signOut(context);
  }

  // Alternative signOut method without navigation
  Future<void> signOutWithoutNavigation() async {
    await _authService.signOutWithoutNavigation();
  }

  Future<void> resetPassword(String email) async {
    _clearError();
    _setLoading(true);
    try {
      await _authService.sendPasswordResetEmail(email);
    } on AuthServiceException catch (e) {
      _setErrorMessage(e.message);
    } catch (e) {
      _setErrorMessage('An unexpected error occurred. Please try again.');
    }
    finally {
      _setLoading(false);
    }
  }

  Future<void> checkEmailVerification() async {
    if (_user == null) return;
    await _user!.reload();
    _user = FirebaseAuth.instance.currentUser;
    if (_user!.emailVerified) {
      await _firestore.collection(_userCollection).doc(_user!.uid).update({'isVerified': true});
      notifyListeners();
    }
  }

  Future<void> sendVerificationEmail() async {
    if (_user == null || _isResendDisabled) return;
    _clearError();
    _setLoading(true);
    try {
      await _user!.sendEmailVerification();
      startResendTimer();
    } on FirebaseAuthException catch (e) {
      _setErrorMessage(e.message);
    } finally {
      _setLoading(false);
    }
  }
}