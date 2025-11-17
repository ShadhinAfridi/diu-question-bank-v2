import 'package:diuquestionbank/views/utils/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A collection of professional UI helper functions following Material 3 design
/// principles and optimized for use with Riverpod.

/// Shows a Material 3 styled snackbar with proper theming
void showAppSnackBar(
    BuildContext context,
    String message, {
      bool isError = false,
      Duration duration = const Duration(seconds: 4),
      String? actionLabel,
      VoidCallback? onAction,
    }) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
      ),
      duration: duration,
      showCloseIcon: true,
      closeIconColor: colorScheme.onInverseSurface,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      backgroundColor: isError
          ? colorScheme.error
          : colorScheme.inverseSurface,
      action: actionLabel != null && onAction != null
          ? SnackBarAction(
        label: actionLabel,
        onPressed: onAction,
        textColor: colorScheme.inversePrimary,
      )
          : null,
      margin: Responsive.isMobile(context)
          ? const EdgeInsets.all(16)
          : const EdgeInsets.all(24),
    ),
  );
}

/// Shows a Material 3 confirmation dialog
Future<bool?> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required String content,
  String confirmText = 'Confirm',
  String cancelText = 'Cancel',
  bool isDestructive = false,
}) async {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog.adaptive(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelText),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: isDestructive
              ? FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
          )
              : null,
          child: Text(confirmText),
        ),
      ],
    ),
  );
}

/// Shows a Material 3 bottom sheet with proper theming
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool useSafeArea = true,
  bool showDragHandle = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    builder: builder,
    isScrollControlled: isScrollControlled,
    useSafeArea: useSafeArea,
    showDragHandle: showDragHandle,
    backgroundColor: Theme.of(context).colorScheme.surface,
    elevation: 4,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(16),
      ),
    ),
    constraints: BoxConstraints(
      maxWidth: Responsive.maxContentWidth(context),
    ),
  );
}

/// Creates a loading overlay that can be shown during async operations
OverlayEntry createLoadingOverlay(BuildContext context) {
  return OverlayEntry(
    builder: (context) => Stack(
      children: [
        // Semi-transparent background
        Container(
          color: Theme.of(context).colorScheme.scrim.withOpacity(0.4),
        ),
        // Loading indicator
        Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const CircularProgressIndicator(),
          ),
        ),
      ],
    ),
  );
}

/// Extension methods for BuildContext to easily access UI helpers
extension UIHelpersExtension on BuildContext {
  /// Shows a snackbar with the given message
  void showSnackBar(
      String message, {
        bool isError = false,
        Duration duration = const Duration(seconds: 4),
        String? actionLabel,
        VoidCallback? onAction,
      }) {
    showAppSnackBar(
      this,
      message,
      isError: isError,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Shows a confirmation dialog
  Future<bool?> showConfirmDialog({
    required String title,
    required String content,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
  }) {
    return showConfirmationDialog(
      context: this,
      title: title,
      content: content,
      confirmText: confirmText,
      cancelText: cancelText,
      isDestructive: isDestructive,
    );
  }

  /// Shows a bottom sheet
  Future<T?> showBottomSheet<T>({
    required WidgetBuilder builder,
    bool isScrollControlled = false,
    bool useSafeArea = true,
    bool showDragHandle = true,
  }) {
    return showAppBottomSheet(
      context: this,
      builder: builder,
      isScrollControlled: isScrollControlled,
      useSafeArea: useSafeArea,
      showDragHandle: showDragHandle,
    );
  }
}

/// Extension methods for WidgetRef to easily show loading states
extension LoadingExtension on WidgetRef {
  /// Shows a loading overlay and returns a function to hide it
  ({void Function() hide, OverlayEntry entry}) showLoadingOverlay(BuildContext context) {
    final overlay = Overlay.of(context);
    final entry = createLoadingOverlay(context);
    overlay.insert(entry);

    return (
    hide: () => entry.remove(),
    entry: entry,
    );
  }
}

/// Helper class for creating consistent animations
class AnimationHelpers {
  /// Standard curve for most animations
  static const Curve standardCurve = Curves.easeInOutCubic;

  /// Fast curve for quick interactions
  static const Curve fastCurve = Curves.easeInOut;

  /// Standard duration for most animations
  static const Duration standardDuration = Duration(milliseconds: 300);

  /// Fast duration for quick interactions
  static const Duration fastDuration = Duration(milliseconds: 150);

  /// Long duration for prominent animations
  static const Duration longDuration = Duration(milliseconds: 500);
}

/// Helper for creating consistent dividers
class AppDividers {
  static Divider standard(BuildContext context) => Divider(
    color: Theme.of(context).colorScheme.outlineVariant,
    height: 1,
    thickness: 1,
  );

  static Divider thick(BuildContext context) => Divider(
    color: Theme.of(context).colorScheme.outlineVariant,
    height: 2,
    thickness: 2,
  );

  static VerticalDivider vertical(BuildContext context) => VerticalDivider(
    color: Theme.of(context).colorScheme.outlineVariant,
    width: 1,
    thickness: 1,
  );
}

