import 'package:diuquestionbank/viewmodels/home_viewmodel.dart';
import 'package:flutter/material.dart';

class ClickableAvatar extends StatelessWidget {
  final HomeViewModel viewModel;
  final VoidCallback onTap;
  final double radius;
  final bool showBorder;

  const ClickableAvatar({
    super.key,
    required this.viewModel,
    required this.onTap,
    this.radius = 25,
    this.showBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      splashColor: theme.colorScheme.primary.withOpacity(0.2),
      highlightColor: theme.colorScheme.primary.withOpacity(0.1),
      child: Container(
        decoration: showBorder
            ? BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: theme.colorScheme.primary,
            width: 2,
          ),
        )
            : null,
        child: viewModel.profilePictureUrl != null
            ? CircleAvatar(
          radius: radius,
          backgroundColor: theme.colorScheme.secondaryContainer,
          child: ClipOval(
            child: FadeInImage.assetNetwork(
              placeholder: 'assets/images/avatar_placeholder.png',
              image: viewModel.profilePictureUrl!,
              fit: BoxFit.cover,
              width: radius * 2,
              height: radius * 2,
              imageErrorBuilder: (context, error, stackTrace) {
                return _buildFallbackAvatar(theme);
              },
            ),
          ),
        )
            : _buildFallbackAvatar(theme),
      ),
    );
  }

  Widget _buildFallbackAvatar(ThemeData theme) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: theme.colorScheme.secondaryContainer,
      child: Text(
        _getInitials(viewModel.userName),
        style: theme.textTheme.titleLarge?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getInitials(String userName) {
    if (userName.isEmpty) return '?';

    final nameParts = userName.trim().split(' ');
    if (nameParts.length == 1) {
      return nameParts[0][0].toUpperCase();
    } else {
      return '${nameParts[0][0]}${nameParts[nameParts.length - 1][0]}'.toUpperCase();
    }
  }
}