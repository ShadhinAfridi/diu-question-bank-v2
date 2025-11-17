import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/user_model.dart';
import '../../../providers/view_model_providers.dart';
import '../../theme/app_theme.dart'; // Assuming this has AppSpacingSystem
import '../../utils/responsive.dart'; // Assuming this has Responsive class
import '../../utils/ui_helpers.dart'; // Assuming this has showAppSnackBar

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (!const bool.fromEnvironment('dart.vm.product')) {
      _emailController.text = 'shadhinafridi@gmail.com';
      _passwordController.text = '123123';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    debugPrint('SignInScreen: Starting sign in process...');
    setState(() => _isSubmitting = true);

    try {
      await ref.read(authViewModelProvider.notifier).signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      // The router provider will handle navigation on success.
      // We just need to handle errors here.

    } catch (error) {
      // This catch is for sync errors in the signIn call itself,
      // but the listener below is better for state-based errors
      debugPrint('SignInScreen: Sign in error: $error');
    }
  }

  void _navigateToSignUp() => context.push('/signup');
  void _navigateToForgotPassword() => context.push('/forgot-password');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Listen for auth state changes - FIXED VERSION
    ref.listen<AsyncValue<UserModel?>>(authViewModelProvider, (previous, next) {
      next.whenOrNull(
        data: (user) {
          if (user != null && _isSubmitting) {
            debugPrint('SignInScreen: Sign in successful, user: ${user.email}');
            setState(() => _isSubmitting = false);
            // DO NOT navigate here - let router handle it
          }
        },
        error: (error, stackTrace) {
          if (mounted && _isSubmitting) {
            debugPrint('SignInScreen: Sign in error: $error');
            showAppSnackBar(context, error.toString(), isError: true);
            setState(() => _isSubmitting = false);
          }
        },
      );
    });

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: Responsive.constrainedWidth(
            context,
            SingleChildScrollView(
              padding: Responsive.screenPadding(context).copyWith(
                top: AppSpacingSystem.s32,
                bottom: AppSpacingSystem.s48,
              ),
              child: Form(
                key: _formKey,
                child: AutofillGroup(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(theme),
                      const SizedBox(height: AppSpacingSystem.s48),
                      _buildEmailField(colors),
                      const SizedBox(height: AppSpacingSystem.s16),
                      _buildPasswordField(colors),
                      const SizedBox(height: AppSpacingSystem.s8),
                      _buildForgotPasswordLink(textTheme, colors),
                      const SizedBox(height: AppSpacingSystem.s32),
                      _buildSignInButton(colors),
                      const SizedBox(height: AppSpacingSystem.s32),
                      _buildSignUpRedirect(textTheme, colors),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- UI Builder Methods (Meta-style) ---

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.school_rounded,
            size: 40,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: AppSpacingSystem.s24),
        Text(
          'Welcome Back',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onBackground,
          ),
        ),
        const SizedBox(height: AppSpacingSystem.s8),
        Text(
          'Sign in to access your question bank',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField(ColorScheme colors) {
    return TextFormField(
      controller: _emailController,
      autofillHints: const [AutofillHints.email],
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: 'DIU Email Address',
        prefixIcon: Icon(Icons.email_outlined, color: colors.onSurfaceVariant),
        hintText: 'student@diu.edu.bd',
        // Using theme's InputDecoration
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your email';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField(ColorScheme colors) {
    return TextFormField(
      controller: _passwordController,
      autofillHints: const [AutofillHints.password],
      obscureText: !_isPasswordVisible,
      textInputAction: TextInputAction.done,
      onEditingComplete: _signIn,
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: Icon(Icons.lock_outline, color: colors.onSurfaceVariant),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: colors.onSurfaceVariant,
          ),
          onPressed: () {
            setState(() => _isPasswordVisible = !_isPasswordVisible);
          },
        ),
        // Using theme's InputDecoration
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your password';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }

  Widget _buildForgotPasswordLink(TextTheme textTheme, ColorScheme colors) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _navigateToForgotPassword,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          'Forgot Password?',
          style: textTheme.bodyMedium?.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSignInButton(ColorScheme colors) {
    return FilledButton(
      onPressed: _isSubmitting ? null : _signIn,
      child: _isSubmitting
          ? SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: colors.onPrimary,
        ),
      )
          : Text(
        'Sign In',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSignUpRedirect(TextTheme textTheme, ColorScheme colors) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account?",
          style: textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: AppSpacingSystem.s4),
        TextButton(
          onPressed: _navigateToSignUp,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacingSystem.s8),
          ),
          child: Text(
            'Sign Up',
            style: textTheme.bodyMedium?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}