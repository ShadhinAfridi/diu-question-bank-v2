import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../main_screen.dart';
import '../../providers/view_model_providers.dart';
import '../screens/auth/email_verification_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/signin_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/home_screen.dart';
import '../screens/question_screen.dart';
import '../screens/question_upload_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/task_manager_screen.dart';

// 1. Create a Key for the root navigator
final _rootNavigatorKey = GlobalKey<NavigatorState>();

// 2. Create the GoRouter provider
final appRouterProvider = Provider<GoRouter>((ref) {
  // 3. Watch the authentication state AND initialization state
  final authState = ref.watch(authViewModelProvider);
  final authInitState = ref.watch(authInitializationProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: true,

    // 4. The FIXED redirect logic
    redirect: (BuildContext context, GoRouterState state) {
      final location = state.uri.toString();
      final authState = ref.read(authViewModelProvider);

      debugPrint('''
GoRouter Redirect:
- Location: $location
- Auth Loading: ${authState.isLoading}
- Authenticated: ${authState.hasValue && authState.value != null}
- User: ${authState.value?.email}
- Email Verified: ${authState.value?.isEmailVerified}
''');

      // 1. If auth is still loading, stay where we are
      if (authState.isLoading) {
        debugPrint('GoRouter: Auth loading, no redirect');
        return null;
      }

      final isAuthenticated = authState.hasValue && authState.value != null;
      final user = authState.value;

      // 2. Handle splash screen
      if (location == '/splash') {
        if (isAuthenticated) {
          if (user!.isEmailVerified) {
            debugPrint('GoRouter: Splash -> Home (verified)');
            return '/';
          } else {
            debugPrint('GoRouter: Splash -> Email Verification (not verified)');
            return '/email-verification';
          }
        } else {
          debugPrint('GoRouter: Splash -> Login (not authenticated)');
          return '/login';
        }
      }

      // 3. If authenticated and trying to access auth routes, redirect to home
      if (isAuthenticated) {
        final isAuthRoute = location == '/login' ||
            location == '/signup' ||
            location == '/forgot-password';

        if (isAuthRoute) {
          if (user!.isEmailVerified) {
            debugPrint('GoRouter: Auth route -> Home (verified)');
            return '/';
          } else {
            debugPrint('GoRouter: Auth route -> Email Verification (not verified)');
            return '/email-verification';
          }
        }

        // If not verified and not on email verification, redirect there
        if (!user!.isEmailVerified && location != '/email-verification') {
          debugPrint('GoRouter: Not verified -> Email Verification');
          return '/email-verification';
        }
      }
      // 4. If not authenticated and trying to access protected routes, redirect to login
      else if (!isAuthenticated &&
          location != '/login' &&
          location != '/signup' &&
          location != '/forgot-password' &&
          location != '/splash') {
        debugPrint('GoRouter: Not authenticated -> Login');
        return '/login';
      }

      // 5. No redirect needed
      debugPrint('GoRouter: No redirect needed');
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/email-verification',
        name: 'email-verification',
        builder: (context, state) => const EmailVerificationScreen(),
      ),
      // This ShellRoute defines the UI with the BottomNavigationBar (MainScreen)
      ShellRoute(
        navigatorKey: GlobalKey<NavigatorState>(debugLabel: 'SHELL'),
        builder: (context, state, child) {
          return MainScreen(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            builder: (context, state) =>
            const HomeScreen(key: ValueKey('HomeScreen')),
          ),
          GoRoute(
            path: '/questions',
            name: 'questions',
            builder: (context, state) =>
            const QuestionScreen(key: ValueKey('QuestionScreen')),
          ),
          GoRoute(
            path: '/upload',
            name: 'upload',
            builder: (context, state) => const QuestionUploadScreen(
              key: ValueKey('QuestionUploadScreen'),
            ),
          ),
          GoRoute(
            path: '/tasks',
            name: 'tasks',
            builder: (context, state) =>
            const TaskManagerScreen(key: ValueKey('TaskManagerScreen')),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) {
      debugPrint('Route error: ${state.error}');
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Route error: ${state.error}'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      );
    },
  );
});