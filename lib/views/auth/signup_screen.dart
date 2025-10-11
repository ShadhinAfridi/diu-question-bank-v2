// lib/src/ui/screens/signup_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../widgets/auth_background.dart';
import '../widgets/auth_header.dart';
import 'email_verification_screen.dart';
import 'signin_screen.dart';
import '../utils/responsive.dart';
import '../theme/app_theme.dart';
import '../utils/ui_helpers.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

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

    final authViewModel = context.read<AuthViewModel>();
    await authViewModel.signUp(
      _emailController.text.trim(),
      _passwordController.text.trim(),
      _nameController.text.trim(),
    );

    if (!mounted) return;

    if (authViewModel.errorMessage != null) {
      showAppSnackBar(context, authViewModel.errorMessage!, isError: true);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const EmailVerificationScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final authViewModel = context.watch<AuthViewModel>();

    return AuthBackground(
      child: SingleChildScrollView(
        padding: AppSpacing.pagePadding,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AuthHeader(
                  icon: Icons.person_add_alt_1,
                  title: 'Create Account',
                  subtitle: 'Join us to access the question bank',
                ),
                const SizedBox(height: AppSpacing.s48),
                _buildSignUpForm(authViewModel, isDesktop),
                const SizedBox(height: AppSpacing.s32),
                _buildSignInRedirect(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpForm(AuthViewModel authViewModel, bool isDesktop) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (value) =>
            (value == null || value.isEmpty) ? 'Please enter your full name' : null,
          ),
          const SizedBox(height: AppSpacing.s24),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
              hintText: 'example@diu.edu.bd',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter your email';

              final email = value.trim().toLowerCase();

              // Pattern 1: exact @diu.edu.bd
              // Pattern 2: @something.diu.edu.bd (subdomains)
              final diuPatterns = [
                RegExp(r'^[a-zA-Z0-9._%+-]+@diu\.edu\.bd$'), // student@diu.edu.bd
                RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+diu\.edu\.bd$'), // student@cse.diu.edu.bd
              ];

              bool isValidDiuEmail = false;
              for (final pattern in diuPatterns) {
                if (pattern.hasMatch(email)) {
                  isValidDiuEmail = true;
                  break;
                }
              }

              if (!isValidDiuEmail) {
                return 'Only DIU email addresses (@diu.edu.bd) are allowed';
              }

              return null;
            },
          ),
          const SizedBox(height: AppSpacing.s24),
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter a password';
              if (value.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.s24),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: !_isConfirmPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please confirm your password';
              if (value != _passwordController.text) return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.s24),
          ElevatedButton(
            onPressed: authViewModel.isLoading ? null : _signUp,
            child: authViewModel.isLoading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Text('SIGN UP'),
          ),
        ],
      ),
    );
  }

  Widget _buildSignInRedirect() {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Already have an account? ",
          style: textTheme.bodyMedium?.copyWith(color: colors.onSurface.withOpacity(0.8)),
        ),
        TextButton(
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SignInScreen()),
          ),
          child: Text(
            'Sign In',
            style: textTheme.bodyMedium?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}