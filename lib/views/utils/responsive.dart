// views/utils/responsive.dart
import 'package:flutter/material.dart';

/// A utility class for responsive design that follows Material 3 breakpoints
/// and provides adaptive layout helpers for different screen sizes.
class Responsive {
  // Material 3 breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 840;
  static const double desktopBreakpoint = 1200;

  /// Returns true if the screen width is less than 600 (mobile)
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  /// Returns true if the screen width is between 600 and 839 (small tablet)
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
          MediaQuery.of(context).size.width < tabletBreakpoint;

  /// Returns true if the screen width is between 840 and 1199 (large tablet)
  static bool isLargeTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint &&
          MediaQuery.of(context).size.width < desktopBreakpoint;

  /// Returns true if the screen width is 1200 or greater (desktop)
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktopBreakpoint;

  /// Returns the appropriate value based on screen size with Material 3 breakpoints
  static T responsiveValue<T>(BuildContext context, {
    required T mobile,
    required T tablet,
    required T desktop,
    T? largeTablet,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    if (isLargeTablet(context)) return largeTablet ?? tablet;
    return desktop;
  }

  /// Returns the appropriate number of columns based on screen size
  static int gridColumns(BuildContext context) => responsiveValue(
    context,
    mobile: 1,
    tablet: 2,
    desktop: 4,
    largeTablet: 3,
  );

  /// Returns appropriate padding based on screen size
  static EdgeInsets screenPadding(BuildContext context) => responsiveValue(
    context,
    mobile: const EdgeInsets.all(16),
    tablet: const EdgeInsets.all(24),
    desktop: const EdgeInsets.all(32),
    largeTablet: const EdgeInsets.all(24),
  );

  /// Returns appropriate horizontal padding for content containers
  static EdgeInsets contentPadding(BuildContext context) => responsiveValue(
    context,
    mobile: const EdgeInsets.symmetric(horizontal: 16),
    tablet: const EdgeInsets.symmetric(horizontal: 24),
    desktop: const EdgeInsets.symmetric(horizontal: 32),
    largeTablet: const EdgeInsets.symmetric(horizontal: 24),
  );

  /// Returns appropriate margin for cards and containers
  static EdgeInsets cardMargin(BuildContext context) => responsiveValue(
    context,
    mobile: const EdgeInsets.all(8),
    tablet: const EdgeInsets.all(12),
    desktop: const EdgeInsets.all(16),
    largeTablet: const EdgeInsets.all(12),
  );

  /// Returns appropriate spacing between items
  static double itemSpacing(BuildContext context) => responsiveValue(
    context,
    mobile: 12,
    tablet: 16,
    desktop: 20,
    largeTablet: 16,
  );

  /// Returns appropriate icon size based on screen size
  static double iconSize(BuildContext context) => responsiveValue(
    context,
    mobile: 20,
    tablet: 24,
    desktop: 28,
    largeTablet: 24,
  );

  /// Returns appropriate button height based on screen size
  static double buttonHeight(BuildContext context) => responsiveValue(
    context,
    mobile: 40,
    tablet: 48,
    desktop: 52,
    largeTablet: 48,
  );

  /// Returns appropriate border radius based on screen size
  static double borderRadius(BuildContext context) => responsiveValue(
    context,
    mobile: 12,
    tablet: 16,
    desktop: 20,
    largeTablet: 16,
  );

  /// Returns appropriate font scale factor based on screen size
  static double fontScale(BuildContext context) => responsiveValue(
    context,
    mobile: 1.0,
    tablet: 1.1,
    desktop: 1.2,
    largeTablet: 1.1,
  );

  /// Returns the maximum content width for the current screen size
  static double maxContentWidth(BuildContext context) => responsiveValue(
    context,
    mobile: 600,
    tablet: 800,
    desktop: 1200,
    largeTablet: 1000,
  );

  /// Wraps a widget with constrained width based on screen size
  static Widget constrainedWidth(BuildContext context, Widget child) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxContentWidth(context),
        ),
        child: child,
      ),
    );
  }

  /// Returns appropriate dialog constraints based on screen size
  static BoxConstraints dialogConstraints(BuildContext context) => responsiveValue(
    context,
    mobile: const BoxConstraints(maxWidth: 400),
    tablet: const BoxConstraints(maxWidth: 500),
    desktop: const BoxConstraints(maxWidth: 600),
    largeTablet: const BoxConstraints(maxWidth: 500),
  );
}