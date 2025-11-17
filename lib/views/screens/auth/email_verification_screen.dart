import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/view_model_providers.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../theme/app_theme.dart';
import '../../utils/ui_helpers.dart';
// import '../../widgets/auth_background.dart'; // Removing this
import '../../widgets/auth_header.dart';
import '../../widgets/loading_overlay.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends ConsumerState<EmailVerificationScreen> {
  late Timer _verificationTimer;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _startVerificationTimer();
  }

  @override
  void dispose() {
    _verificationTimer.cancel();
    super.dispose();
  }

  void _startVerificationTimer() {
    // Check every 3 seconds for email verification
    _verificationTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted) return;
      await _checkEmailVerification(isAuto: true);
    });
  }

  Future<void> _checkEmailVerification({bool isAuto = false}) async {
    if (_isChecking) return;

    if (!isAuto) {
      setState(() => _isChecking = true);
    }

    try {
      await ref.read(authViewModelProvider.notifier).checkEmailVerification();
      // The router will automatically navigate if verification is successful
      // because the auth state will change (isEmailVerified) and the
      // router's redirect logic will run.
    } catch (error) {
      if (mounted && !isAuto) {
        showAppSnackBar(context, error.toString(), isError: true);
      }
    } finally {
      if (mounted && !isAuto) {
        setState(() => _isChecking = false);
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    final authNotifier = ref.read(authViewModelProvider.notifier);
    if (authNotifier.isResendDisabled.value) return;

    try {
      await authNotifier.sendVerificationEmail();
      if (mounted) {
        showAppSnackBar(context, 'Verification email sent!', isError: false);
      }
    } catch (error) {
      if (mounted) {
        showAppSnackBar(context, error.toString(), isError: true);
      }
    }
  }

  void _navigateToSignIn() {
    _verificationTimer.cancel();
    // Log out the user so they land on /login cleanly
    ref.read(authViewModelProvider.notifier).signOut();
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final authNotifier = ref.read(authViewModelProvider.notifier);
    final userEmail = authState.value?.email ?? 'your email';

    final isResending = authState.isLoading && _isChecking; // More precise loading

    return LoadingOverlay(
      isLoading: _isChecking || isResending,
      // Removing AuthBackground
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: AppSpacingSystem.pagePadding.copyWith(
              top: AppSpacingSystem.s32,
              bottom: AppSpacingSystem.s48,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AuthHeader(
                      icon: Icons.mark_email_read_rounded,
                      title: 'Verify Your Email',
                      subtitle: 'We sent a verification link to your email address',
                    ),
                    const SizedBox(height: AppSpacingSystem.s48),

                    // Email Address
                    _buildEmailCard(userEmail),
                    const SizedBox(height: AppSpacingSystem.s32),

                    // Instructions
                    _buildInstructions(),
                    const SizedBox(height: AppSpacingSystem.s32),

                    // Action Buttons
                    _buildActionButtons(authNotifier, isResending),
                    const SizedBox(height: AppSpacingSystem.s24),

                    // Back to Sign In
                    _buildBackToSignIn(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ... (All other _build methods are unchanged) ...

  Widget _buildEmailCard(String userEmail) {
    return Container(
      padding: const EdgeInsets.all(AppSpacingSystem.s16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: AppBorderRadius.lg,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.email_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: AppSpacingSystem.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verification sent to:',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  userEmail,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInstructionStep(
          number: 1,
          text: 'Check your email inbox (and spam folder)',
        ),
        const SizedBox(height: AppSpacingSystem.s16),
        _buildInstructionStep(
          number: 2,
          text: 'Click the verification link in the email',
        ),
        const SizedBox(height: AppSpacingSystem.s16),
        _buildInstructionStep(
          number: 3,
          text: 'Return to this screen - we\'ll automatically detect verification',
        ),
      ],
    );
  }

  Widget _buildInstructionStep({required int number, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number.toString(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacingSystem.s12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(AuthViewModel authNotifier, bool isResending) {
    return Column(
      children: [
        FilledButton(
          onPressed: _isChecking ? null : () => _checkEmailVerification(isAuto: false),
          child: _isChecking
              ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          )
              : const Text('I\'VE VERIFIED MY EMAIL'),
        ),
        const SizedBox(height: AppSpacingSystem.s16),
        ValueListenableBuilder<bool>(
          valueListenable: authNotifier.isResendDisabled,
          builder: (context, isResendDisabled, child) {
            return OutlinedButton(
              onPressed: isResendDisabled || isResending ? null : _resendVerificationEmail,
              child: isResendDisabled
                  ? ValueListenableBuilder<int>(
                valueListenable: authNotifier.resendTimer,
                builder: (context, timerValue, child) {
                  return Text('RESEND IN ${timerValue}s');
                },
              )
                  : const Text('RESEND VERIFICATION EMAIL'),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBackToSignIn() {
    return TextButton(
      onPressed: _navigateToSignIn,
      child: Text(
        'Back to Sign In',
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}