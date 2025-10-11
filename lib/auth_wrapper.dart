import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'main_screen.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'views/auth/signin_screen.dart';
import 'services/connectivity_service.dart';
import 'repositories/question_cache_repository.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isPreloading = false;
  AuthState? _previousAuthState;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get the view model, and listen for changes.
    final authViewModel = context.watch<AuthViewModel>();

    // Check if the authentication state has changed to authenticated.
    if (_previousAuthState != authViewModel.authState &&
        authViewModel.authState == AuthState.authenticated) {
      // Trigger the preload logic only once when the user logs in.
      _preloadUserData();
    }

    // Update the previous state for the next check.
    _previousAuthState = authViewModel.authState;
  }

  void _preloadUserData() {
    // Prevent multiple preload calls if didChangeDependencies is called again.
    if (_isPreloading) return;

    setState(() {
      _isPreloading = true;
    });

    // Run the async preload logic after the current build cycle is complete.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final connectivityService = context.read<ConnectivityService>();

        if (connectivityService.isConnected) {
          final questionRepo = context.read<QuestionCacheRepository>();
          await questionRepo.preloadData();
          debugPrint('User data preloaded successfully');
        } else {
          debugPrint('Offline mode: Using cached data');
        }
      } catch (e) {
        debugPrint('Error preloading user data: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isPreloading = false;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, _) {
        // The Consumer is now only responsible for switching the UI.
        // The preload logic has been moved to didChangeDependencies.
        return PageTransitionSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
            return FadeThroughTransition(
              animation: primaryAnimation,
              secondaryAnimation: secondaryAnimation,
              child: child,
            );
          },
          child: _buildScreen(authViewModel),
        );
      },
    );
  }

  Widget _buildScreen(AuthViewModel authViewModel) {
    switch (authViewModel.authState) {
      case AuthState.authenticated:
        return const MainScreen(key: ValueKey('Main'));
      case AuthState.unauthenticated:
        return const SignInScreen(key: ValueKey('SignIn'));
      default: // Covers null and any other initial state.
      // Show a loading screen while the auth state is being determined.
        return const Scaffold(
          key: ValueKey('Loading'),
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
    }
  }
}

