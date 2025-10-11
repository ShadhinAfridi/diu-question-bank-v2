// lib/src/ui/screens/signin_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../widgets/auth_background.dart';
import '../widgets/auth_header.dart';
import 'email_verification_screen.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';
import '../utils/responsive.dart';
import '../theme/app_theme.dart';
import '../utils/ui_helpers.dart';
import '../../main_screen.dart'; // Assuming this is your main app screen

class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    final authViewModel = context.read<AuthViewModel>();
    await authViewModel.signIn(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;

    if (authViewModel.errorMessage != null) {
      showAppSnackBar(context, authViewModel.errorMessage!, isError: true);
    } else {
      final user = authViewModel.user;
      // Navigate based on email verification status
      if (user != null) {
        if (user.emailVerified) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const EmailVerificationScreen()),
          );
        }
      }
      // If user is null, the error message will be shown.
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final authViewModel = context.watch<AuthViewModel>();

    return AuthBackground(
      showBackButton: false,
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
                  icon: Icons.school,
                  title: 'Welcome Back',
                  subtitle: 'Sign in to continue to DIU Question Bank',
                ),
                const SizedBox(height: AppSpacing.s48),
                _buildLoginForm(authViewModel, isDesktop),
                const SizedBox(height: AppSpacing.s32),
                _buildSignUpRedirect(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(AuthViewModel authViewModel, bool isDesktop) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: const Icon(Icons.email_outlined),
              floatingLabelStyle: TextStyle(color: colors.primary),
            ),
            validator: (value) =>
            (value == null || value.isEmpty) ? 'Please enter your email' : null,
          ),
          const SizedBox(height: AppSpacing.s24),
          TextFormField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              floatingLabelStyle: TextStyle(color: colors.primary),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),
            ),
            validator: (value) =>
            (value == null || value.isEmpty) ? 'Please enter your password' : null,
          ),
          const SizedBox(height: AppSpacing.s8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
              ),
              child: const Text('Forgot Password?'),
            ),
          ),
          const SizedBox(height: AppSpacing.s24),
          ElevatedButton(
            onPressed: authViewModel.isLoading ? null : _signIn,
            child: authViewModel.isLoading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Text('LOG IN'),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpRedirect() {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: textTheme.bodyMedium?.copyWith(color: colors.onSurface.withOpacity(0.8)),
        ),
        TextButton(
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SignUpScreen()),
          ),
          child: Text(
            'Sign Up',
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
