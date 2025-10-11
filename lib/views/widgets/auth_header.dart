import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import '../theme/app_theme.dart';

class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const AuthHeader({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Column(
      children: [
        Icon(
          icon,
          color: colors.onPrimary,
          size: isDesktop ? 100 : 80,
        ),
        const SizedBox(height: AppSpacing.s24),
        Text(
          title,
          textAlign: TextAlign.center,
          style: (isDesktop
              ? textTheme.displaySmall
              : textTheme.headlineMedium)
              ?.copyWith(
            color: colors.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style:
          (isDesktop ? textTheme.titleMedium : textTheme.bodyLarge)
              ?.copyWith(
            color: colors.onPrimary.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}

