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

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isSubmitting = false;
  bool _agreeToTerms = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill for development
    if (!kReleaseMode) {
      _nameController.text = 'Test User';
      _emailController.text = 'test@diu.edu.bd';
      _passwordController.text = 'password123';
      _confirmPasswordController.text = 'password123';
      _agreeToTerms = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeToTerms) {
      showAppSnackBar(context, 'Please agree to the terms and conditions', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ref.read(authViewModelProvider.notifier).signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
      );
      // Router will automatically navigate to /email-verification on success
    } catch (error) {
      // Error is handled by the listener
    }
  }

  void _navigateToSignIn() => context.go('/login');

  @override
  Widget build(BuildContext context) {
    // Listen for auth errors
    ref.listen<AsyncValue<UserModel?>>(authViewModelProvider, (previous, next) {
      next.whenOrNull(
          error: (error, stackTrace) {
            if (mounted && _isSubmitting) {
              showAppSnackBar(context, error.toString(), isError: true);
              setState(() => _isSubmitting = false);
            }
          },
          data: (user) {
            if (mounted && _isSubmitting) {
              // Router will navigate away
              setState(() => _isSubmitting = false);
            }
          }
      );
    });

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
                    const AuthHeader(
                      icon: Icons.person_add_alt_1_rounded,
                      title: 'Create Account',
                      subtitle: 'Join DIU Question Bank to access thousands of questions',
                    ),
                    const SizedBox(height: AppSpacingSystem.s48),

                    // Sign Up Form
                    _buildSignUpForm(),
                    const SizedBox(height: AppSpacingSystem.s32),

                    // Terms and Conditions
                    _buildTermsAgreement(),
                    const SizedBox(height: AppSpacingSystem.s24),

                    // Sign Up Button
                    _buildSignUpButton(),
                    const SizedBox(height: AppSpacingSystem.s32),

                    // Sign In Redirect
                    _buildSignInRedirect(),
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

  Widget _buildSignUpForm() {
    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Full Name
            TextFormField(
              controller: _nameController,
              autofillHints: const [AutofillHints.name],
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your full name';
                }
                if (value.trim().split(' ').length < 2) {
                  return 'Please enter your full name (first and last)';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacingSystem.s20),

            // Email
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
                  return 'Only DIU email addresses (@diu.edu.bd) are allowed';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacingSystem.s20),

            // Password
            TextFormField(
              controller: _passwordController,
              autofillHints: const [AutofillHints.newPassword],
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(_isPasswordVisible
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded),
                  onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacingSystem.s20),

            // Confirm Password
            TextFormField(
              controller: _confirmPasswordController,
              autofillHints: const [AutofillHints.newPassword],
              obscureText: !_isConfirmPasswordVisible,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(_isConfirmPasswordVisible
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded),
                  onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsAgreement() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _agreeToTerms,
          onChanged: (value) => setState(() => _agreeToTerms = value ?? false),
          shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.sm),
        ),
        const SizedBox(width: AppSpacingSystem.s8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              children: [
                const TextSpan(text: 'I agree to the '),
                TextSpan(
                  text: 'Terms of Service',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  // Add onTap for terms
                ),
                const TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  // Add onTap for privacy policy
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpButton() {
    return FilledButton(
      onPressed: _isSubmitting ? null : _signUp,
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
        'CREATE ACCOUNT',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildSignInRedirect() {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Already have an account? ",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        TextButton(
          onPressed: _navigateToSignIn,
          child: Text(
            'Sign In',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
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