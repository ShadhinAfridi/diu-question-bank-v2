// lib/src/ui/screens/email_verification_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../widgets/auth_background.dart';
import '../widgets/auth_header.dart';
import '../utils/responsive.dart';
import '../theme/app_theme.dart';
import '../utils/ui_helpers.dart';
import '../../main_screen.dart'; // Assuming this is your main app screen

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({Key? key}) : super(key: key);

  @override
  _EmailVerificationScreenState createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  late Timer _timer;
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    // We don't need to send the email immediately if we expect a code.
    // The user can press the resend button.
    // authViewModel.sendVerificationEmail();
    authViewModel.startResendTimer();

    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await authViewModel.checkEmailVerification();
      if (authViewModel.user?.emailVerified == true && mounted) {
        _timer.cancel();
        _navigateToMainScreen();
      }
    });
  }

  void _navigateToMainScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainScreen()),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _resendEmail() async {
    final authViewModel = context.read<AuthViewModel>();
    await authViewModel.sendVerificationEmail();
    if (mounted) {
      showAppSnackBar(context, 'Verification email sent!');
    }
  }

  Future<void> _verifyEmail() async {
    // This is a mock verification. In a real app, you would use the code from _codeController
    // and send it to your backend or Firebase.
    final authViewModel = context.read<AuthViewModel>();
    await authViewModel.checkEmailVerification();
    if (authViewModel.user?.emailVerified == true && mounted) {
      _navigateToMainScreen();
    } else if (mounted) {
      showAppSnackBar(context, 'Email not verified yet. Please check your inbox or the code.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final theme = Theme.of(context);

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
                AuthHeader(
                  icon: Icons.mark_email_read_outlined,
                  title: 'Verify Your Email',
                  subtitle: 'A verification link has been sent to ${authViewModel.user?.email ?? 'your email'}. You can also enter the code below.',
                ),
                const SizedBox(height: AppSpacing.s48),

                Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(letterSpacing: 8),
                    decoration: const InputDecoration(
                      labelText: 'Verification Code',
                      hintText: '- - - - - -',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the verification code';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.s32),

                ElevatedButton(
                  onPressed: authViewModel.isLoading ? null : _verifyEmail,
                  child: authViewModel.isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('VERIFY EMAIL'),
                ),
                const SizedBox(height: AppSpacing.s24),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.secondary,
                    foregroundColor: theme.colorScheme.onSecondary,
                  ),
                  onPressed: authViewModel.isResendDisabled ? null : _resendEmail,
                  child: Text(
                    authViewModel.isResendDisabled
                        ? 'RESEND IN ${authViewModel.resendTimer}s'
                        : 'RESEND EMAIL',
                  ),
                ),
                const SizedBox(height: AppSpacing.s24),
                TextButton(
                  onPressed: () => authViewModel.signOut(context),
                  child: Text(
                    'Back to Sign In',
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
