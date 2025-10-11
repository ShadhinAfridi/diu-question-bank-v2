import 'package:flutter/material.dart';

class Responsive {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
          MediaQuery.of(context).size.width < 1200;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1200;

  static double responsiveValue(BuildContext context,
      {double? mobile, double? tablet, double? desktop}) {
    if (isMobile(context)) return mobile ?? tablet ?? desktop ?? 0;
    if (isTablet(context)) return tablet ?? mobile ?? desktop ?? 0;
    return desktop ?? tablet ?? mobile ?? 0;
  }
}