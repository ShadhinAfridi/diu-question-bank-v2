import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/view_model_providers.dart';

// No more GoRouter or provider imports needed here!

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Add more detailed debug logging
    final authState = ref.watch(authViewModelProvider);
    final authInitState = ref.watch(authInitializationProvider);

    debugPrint('''
SplashScreen Debug:
- Auth State: ${authState.isLoading ? 'Loading' : authState.hasError ? 'Error: ${authState.error}' : 'Ready - User: ${authState.value != null}'}
- Auth Init: ${authInitState.isLoading ? 'Loading' : authInitState.hasError ? 'Error' : 'Ready'}
- User: ${authState.value?.email ?? 'None'}
- Verified: ${authState.value?.isEmailVerified ?? false}
- Has Value: ${authState.hasValue}
- Has Error: ${authState.hasError}
''');

    // Listen for completion
    ref.listen(authInitializationProvider, (previous, next) {
      next.when(
        data: (data) => debugPrint('SplashScreen: Auth initialization complete'),
        loading: () => debugPrint('SplashScreen: Auth initialization loading'),
        error: (error, stack) => debugPrint('SplashScreen: Auth initialization error: $error'),
      );
    });

    ref.listen(authViewModelProvider, (previous, next) {
      next.when(
        data: (user) => debugPrint('SplashScreen: Auth state - User: ${user != null}'),
        loading: () => debugPrint('SplashScreen: Auth state loading'),
        error: (error, stack) => debugPrint('SplashScreen: Auth state error: $error'),
      );
    });

    debugPrint('SplashScreen: Building splash screen');

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.school_rounded,
                size: 40,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'DIU Question Bank',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}