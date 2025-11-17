import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/user_model.dart';
import '../../../providers/view_model_providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/ui_helpers.dart';
// import '../../widgets/auth_background.dart'; // Removing this
import '../../widgets/auth_header.dart';
import '../../widgets/loading_overlay.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isSubmitting = false;
  bool _resetSent = false;

  @override
  void initState() {
    super.initState();
    if (!kReleaseMode) {
      _emailController.text = 'test@diu.edu.bd';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await ref.read(authViewModelProvider.notifier).resetPassword(
        _emailController.text.trim(),
      );

      if (mounted) {
        setState(() => _resetSent = true);
        showAppSnackBar(
            context,
            'Password reset link sent to your email!',
            isError: false
        );

        // Auto-navigate back after success
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) context.pop();
        });
      }
    } catch (error) {
      if (mounted) {
        showAppSnackBar(context, error.toString(), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _navigateBack() => context.pop();

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isSubmitting,
      // Removing AuthBackground
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
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
                    AuthHeader(
                      icon: _resetSent
                          ? Icons.mark_email_read_rounded
                          : Icons.lock_reset_rounded,
                      title: _resetSent ? 'Check Your Email' : 'Reset Password',
                      subtitle: _resetSent
                          ? 'We\'ve sent a password reset link to ${_emailController.text}. Please check your inbox.'
                          : 'Enter your DIU email to receive a password reset link',
                    ),
                    const SizedBox(height: AppSpacingSystem.s40),

                    if (!_resetSent) _buildResetForm(),
                    if (_resetSent) _buildSuccessState(),

                    const SizedBox(height: AppSpacingSystem.s16),
                    _buildBackButton(),
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

  Widget _buildResetForm() {
    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _emailController,
              autofillHints: const [AutofillHints.email],
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'DIU Email Address',
                prefixIcon: Icon(Icons.email_outlined),
                hintText: 'student@diu.edu.bd',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!_isValidDiuEmail(value)) {
                  return 'Please enter a valid DIU email address';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacingSystem.s24),
            FilledButton(
              onPressed: _isSubmitting ? null : _sendResetLink,
              child: _isSubmitting
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              )
                  : const Text(
                'SEND RESET LINK',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessState() {
    return Column(
      children: [
        Icon(
          Icons.check_circle_rounded,
          size: 80,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: AppSpacingSystem.s24),
        Text(
          'Reset Link Sent!',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacingSystem.s16),
        Text(
          'Please check your email and follow the instructions to reset your password.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildBackButton() {
    return TextButton(
      onPressed: _navigateBack,
      child: Text(
        'Back to Sign In',
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  bool _isValidDiuEmail(String email) {
    final trimmedEmail = email.trim().toLowerCase();
    final diuPatterns = [
      RegExp(r'^[a-zA-Z0-9._%+-]+@diu\.edu\.bd$'),
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.diu\.edu\.bd$'),
    ];

    return diuPatterns.any((pattern) => pattern.hasMatch(trimmedEmail));
  }
}