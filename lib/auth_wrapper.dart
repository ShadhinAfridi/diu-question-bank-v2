import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'main_screen.dart'; // Assuming this is your main app screen
import 'viewmodels/auth_viewmodel.dart';
import 'views/auth/signin_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Consumer widget rebuilds its child when the AuthViewModel notifies listeners.
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, _) {
        // PageTransitionSwitcher animates between different screens.
        return PageTransitionSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
            // Use a FadeThroughTransition for a smooth cross-fade effect.
            return FadeThroughTransition(
              animation: primaryAnimation,
              secondaryAnimation: secondaryAnimation,
              child: child,
            );
          },
          child: _buildScreen(context, authViewModel),
        );
      },
    );
  }

  /// Selects the appropriate screen based on the current AuthState.
  Widget _buildScreen(BuildContext context, AuthViewModel authViewModel) {
    switch (authViewModel.authState) {
      case AuthState.unauthenticated:
        return const SignInScreen(key: ValueKey('SignIn'));
      case AuthState.authenticated:
        return const MainScreen(key: ValueKey('Main'));
      case null:
        return const SignInScreen(key: ValueKey('SignIn'));
    }
  }
}

