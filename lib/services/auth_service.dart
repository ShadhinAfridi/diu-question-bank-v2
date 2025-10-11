import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../views/auth/signin_screen.dart';

/// A custom exception class for handling authentication-related errors.
class AuthServiceException implements Exception {
  final String message;
  AuthServiceException(this.message);

  @override
  String toString() => message;
}

/// A service class that encapsulates Firebase Authentication logic.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// A stream that notifies listeners about changes in the user's authentication state.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Signs in a user with the given email and password.
  /// Throws [AuthServiceException] on failure.
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthService Sign-in error: ${e.code} - ${e.message}');
      throw AuthServiceException(_mapAuthErrorCodeToMessage(e.code));
    } catch (e) {
      throw AuthServiceException('An unexpected error occurred.');
    }
  }

  /// Creates a new user account with the given email and password.
  /// Throws [AuthServiceException] on failure.
  Future<User?> createUserWithEmailAndPassword(String email, String password) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthService Sign-up error: ${e.code} - ${e.message}');
      throw AuthServiceException(_mapAuthErrorCodeToMessage(e.code));
    } catch (e) {
      throw AuthServiceException('An unexpected error occurred.');
    }
  }

  /// Sends a password reset email to the specified email address.
  /// Throws [AuthServiceException] on failure.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      debugPrint('AuthService Password reset error: ${e.code} - ${e.message}');
      throw AuthServiceException(_mapAuthErrorCodeToMessage(e.code));
    } catch (e) {
      throw AuthServiceException('An unexpected error occurred.');
    }
  }

  /// Signs out the current user.
  /// [context] parameter is required for navigation
  Future<void> signOut(BuildContext context) async {
    await Hive.deleteFromDisk();
    await _auth.signOut();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const SignInScreen()),
          (Route<dynamic> route) => false,
    );
  }

  /// Alternative signOut method without navigation for use in non-UI contexts
  Future<void> signOutWithoutNavigation() async {
    await Hive.deleteFromDisk();
    await _auth.signOut();
  }

  /// Maps Firebase authentication error codes to user-friendly messages.
  String _mapAuthErrorCodeToMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided for that user.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'The password provided is too weak.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}