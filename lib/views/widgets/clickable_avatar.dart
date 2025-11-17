// views/widgets/clickable_avatar.dart
import 'package:flutter/material.dart';

class ClickableAvatar extends StatelessWidget {
  final String? imageUrl;
  final String userName;
  final VoidCallback onTap;
  final double size;
  final bool showBorder;

  const ClickableAvatar({
    super.key,
    this.imageUrl,
    required this.userName,
    required this.onTap,
    this.size = 40,
    this.showBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size),
      child: Container(
        width: size,
        height: size,
        decoration: showBorder
            ? BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: theme.colorScheme.primary,
            width: 2,
          ),
        )
            : null,
        child: imageUrl != null
            ? CircleAvatar(
          backgroundImage: NetworkImage(imageUrl!),
          onBackgroundImageError: (exception, stackTrace) {},
        )
            : CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            _getInitials(userName),
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
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
      return '${nameParts[0][0]}${nameParts.last[0]}'.toUpperCase();
    }
  }
}