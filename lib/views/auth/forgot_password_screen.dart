// lib/src/ui/screens/forgot_password_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../widgets/auth_background.dart';
import '../widgets/auth_header.dart';
import '../utils/responsive.dart';
import '../theme/app_theme.dart';
import '../utils/ui_helpers.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;

    final authViewModel = context.read<AuthViewModel>();
    await authViewModel.resetPassword(_emailController.text.trim());

    if (mounted) {
      showAppSnackBar(context, 'Password reset email sent! Check your inbox.');
      Navigator.pop(context);
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
                  icon: Icons.lock_reset,
                  title: 'Reset Password',
                  subtitle: 'Enter your email to receive a password reset link',
                ),
                const SizedBox(height: AppSpacing.s48),
                _buildResetForm(authViewModel),
                const SizedBox(height: AppSpacing.s32),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Back to Sign In',
                    style: TextStyle(color: Theme.of(context).colorScheme.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResetForm(AuthViewModel authViewModel) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter your email';
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.s32),
          ElevatedButton(
            onPressed: authViewModel.isLoading ? null : _sendResetLink,
            child: authViewModel.isLoading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Text('SEND RESET LINK'),
          ),
        ],
      ),
    );
  }
}
