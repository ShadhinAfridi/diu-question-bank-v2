import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ========== Color System (Moved to top for better organization) ==========
class _AppColors {
  final Color primary;
  final Color primaryContainer;
  final Color secondary;
  final Color secondaryContainer;
  final Color tertiary;
  final Color tertiaryContainer;
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color inverseSurface;
  final Color onPrimary;
  final Color onSecondary;
  final Color onTertiary;
  final Color onBackground;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color onInverseSurface;
  final Color outline;
  final Color outlineVariant;
  final Color error;
  final Color onError;
  final Color success;
  final Color warning;
  final Color scrim;

  const _AppColors({
    required this.primary,
    required this.primaryContainer,
    required this.secondary,
    required this.secondaryContainer,
    required this.tertiary,
    required this.tertiaryContainer,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.inverseSurface,
    required this.onPrimary,
    required this.onSecondary,
    required this.onTertiary,
    required this.onBackground,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.onInverseSurface,
    required this.outline,
    required this.outlineVariant,
    required this.error,
    required this.onError,
    required this.success,
    required this.warning,
    required this.scrim,
  });
}

/// A comprehensive theme system for the application
class AppTheme {
  AppTheme._();

  // ========== Color System ==========
  static const _AppColors _lightColors = _AppColors(
    primary: Color(0xFF3F51B5),
    primaryContainer: Color(0xFF5C6BC0),
    secondary: Color(0xFF0091EA),
    secondaryContainer: Color(0xFF40C4FF),
    tertiary: Color(0xFF4CAF50),
    tertiaryContainer: Color(0xFF81C784),
    background: Color(0xFFF7F9FC),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFEEEEEE),
    inverseSurface: Color(0xFF121212),
    onPrimary: Color(0xFFFFFFFF),
    onSecondary: Color(0xFFFFFFFF),
    onTertiary: Color(0xFFFFFFFF),
    onBackground: Color(0xFF1A1A1A),
    onSurface: Color(0xFF1A1A1A),
    onSurfaceVariant: Color(0xFF666666),
    onInverseSurface: Color(0xFFFFFFFF),
    outline: Color(0xFFE0E0E0),
    outlineVariant: Color(0xFFCCCCCC),
    error: Color(0xFFD32F2F),
    onError: Color(0xFFFFFFFF),
    success: Color(0xFF388E3C),
    warning: Color(0xFFFFA000),
    scrim: Color(0x99000000),
  );

  static const _AppColors _darkColors = _AppColors(
    primary: Color(0xFF7986CB),
    primaryContainer: Color(0xFF5C6BC0),
    secondary: Color(0xFF40C4FF),
    secondaryContainer: Color(0xFF00B0FF),
    tertiary: Color(0xFF81C784),
    tertiaryContainer: Color(0xFF4CAF50),
    background: Color(0xFF121212),
    surface: Color(0xFF1E1E1E),
    surfaceVariant: Color(0xFF2D2D2D),
    inverseSurface: Color(0xFFF7F9FC),
    onPrimary: Color(0xFFFFFFFF),
    onSecondary: Color(0xFFFFFFFF),
    onTertiary: Color(0xFFFFFFFF),
    onBackground: Color(0xFFFFFFFF),
    onSurface: Color(0xFFFFFFFF),
    onSurfaceVariant: Color(0xB3FFFFFF),
    onInverseSurface: Color(0xFF1A1A1A),
    outline: Color(0xFF444444),
    outlineVariant: Color(0xFF666666),
    error: Color(0xFFF44336),
    onError: Color(0xFFFFFFFF),
    success: Color(0xFF4CAF50),
    warning: Color(0xFFFFC107),
    scrim: Color(0x99000000),
  );

  // ========== Theme Data ==========
  static ThemeData get light => _buildTheme(_lightColors, Brightness.light);
  static ThemeData get dark => _buildTheme(_darkColors, Brightness.dark);

  // ========== Core Theme Builder ==========
  static ThemeData _buildTheme(_AppColors colors, Brightness brightness) {
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: colors.primary,
        onPrimary: colors.onPrimary,
        primaryContainer: colors.primaryContainer,
        secondary: colors.secondary,
        onSecondary: colors.onSecondary,
        secondaryContainer: colors.secondaryContainer,
        tertiary: colors.tertiary,
        onTertiary: colors.onTertiary,
        tertiaryContainer: colors.tertiaryContainer,
        error: colors.error,
        onError: colors.onError,
        surface: colors.surface,
        onSurface: colors.onSurface,
        surfaceContainerHighest: colors.surfaceVariant,
        onSurfaceVariant: colors.onSurfaceVariant,
        inverseSurface: colors.inverseSurface,
        onInverseSurface: colors.onInverseSurface,
        outline: colors.outline,
        outlineVariant: colors.outlineVariant,
        scrim: colors.scrim,
      ),
    );

    return baseTheme.copyWith(
      textTheme: _buildTextTheme(colors, brightness),
      iconTheme: _iconTheme(colors),
      appBarTheme: _appBarTheme(colors, brightness),
      cardTheme: _cardTheme(colors),
      elevatedButtonTheme: _elevatedButtonTheme(colors),
      outlinedButtonTheme: _outlinedButtonTheme(colors),
      textButtonTheme: _textButtonTheme(colors),
      inputDecorationTheme: _inputDecorationTheme(colors),
      chipTheme: _chipTheme(colors, brightness),
      dividerTheme: _dividerTheme(colors),
      snackBarTheme: _snackBarTheme(colors),
      bottomNavigationBarTheme: _bottomNavBarTheme(colors),
      bottomSheetTheme: _bottomSheetTheme(colors),
      dialogTheme: _dialogTheme(colors),
      floatingActionButtonTheme: _fabTheme(colors),
      checkboxTheme: _checkboxTheme(colors),
      radioTheme: _radioTheme(colors),
      switchTheme: _switchTheme(colors),
      tabBarTheme: _tabBarTheme(colors),
      tooltipTheme: _tooltipTheme(colors),
      popupMenuTheme: _popupMenuTheme(colors),
      listTileTheme: _listTileTheme(colors),
      progressIndicatorTheme: _progressIndicatorTheme(colors),
      dataTableTheme: _dataTableTheme(colors),
      navigationRailTheme: _navigationRailTheme(colors),
      scrollbarTheme: _scrollbarTheme(colors),
    );
  }

  // ========== Component Themes ==========
  static TextTheme _buildTextTheme(_AppColors colors, Brightness brightness) {
    final baseTextTheme = brightness == Brightness.light
        ? Typography.blackMountainView
        : Typography.whiteMountainView;

    return GoogleFonts.latoTextTheme(baseTextTheme).copyWith(
      displayLarge: GoogleFonts.lato(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        color: colors.onBackground,
      ),
      displayMedium: GoogleFonts.lato(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        color: colors.onBackground,
      ),
      displaySmall: GoogleFonts.lato(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: colors.onBackground,
      ),
      headlineLarge: GoogleFonts.lato(
        fontSize: 32,
        fontWeight: FontWeight.w400,
        color: colors.onBackground,
      ),
      headlineMedium: GoogleFonts.lato(
        fontSize: 28,
        fontWeight: FontWeight.w400,
        color: colors.onBackground,
      ),
      headlineSmall: GoogleFonts.lato(
        fontSize: 24,
        fontWeight: FontWeight.w400,
        color: colors.onBackground,
      ),
      titleLarge: GoogleFonts.lato(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: colors.onBackground,
      ),
      titleMedium: GoogleFonts.lato(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        color: colors.onSurface,
      ),
      titleSmall: GoogleFonts.lato(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: colors.onSurfaceVariant,
      ),
      bodyLarge: GoogleFonts.lato(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: colors.onSurface,
      ),
      bodyMedium: GoogleFonts.lato(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: colors.onSurfaceVariant,
      ),
      bodySmall: GoogleFonts.lato(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: colors.onSurfaceVariant,
      ),
      labelLarge: GoogleFonts.lato(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: colors.onSurface,
      ),
      labelMedium: GoogleFonts.lato(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: colors.onSurface,
      ),
      labelSmall: GoogleFonts.lato(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: colors.onSurfaceVariant,
      ),
    );
  }

  static IconThemeData _iconTheme(_AppColors colors) {
    return IconThemeData(
      color: colors.onSurfaceVariant,
      size: 24,
    );
  }

  static AppBarTheme _appBarTheme(_AppColors colors, Brightness brightness) {
    return AppBarTheme(
      systemOverlayStyle: brightness == Brightness.light
          ? const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      )
          : const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.lato(
        color: colors.onBackground,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: colors.onBackground),
      actionsIconTheme: IconThemeData(color: colors.onBackground),
      toolbarTextStyle: GoogleFonts.latoTextTheme()
          .bodyMedium
          ?.copyWith(color: colors.onBackground),
      scrolledUnderElevation: 1,
      surfaceTintColor: Colors.transparent,
    );
  }

  static CardThemeData _cardTheme(_AppColors colors) {
    return CardThemeData(
      color: colors.surface,
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.outline, width: 1),
      ),
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme(_AppColors colors) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        // FIX: Replaced non-existent .withValues() with .withOpacity()
        disabledBackgroundColor: colors.primary.withOpacity(0.38),
        disabledForegroundColor: colors.onPrimary.withOpacity(0.38),
        elevation: 0,
        shadowColor: colors.primary.withOpacity(0.4),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: GoogleFonts.lato(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        surfaceTintColor: Colors.transparent,
        enableFeedback: true,
      ),
    );
  }

  static OutlinedButtonThemeData _outlinedButtonTheme(_AppColors colors) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.primary,
        // FIX: Replaced non-existent .withValues() with .withOpacity()
        disabledForegroundColor: colors.primary.withOpacity(0.38),
        side: BorderSide(color: colors.primary),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: GoogleFonts.lato(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        enableFeedback: true,
      ),
    );
  }

  static TextButtonThemeData _textButtonTheme(_AppColors colors) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colors.primary,
        // FIX: Replaced non-existent .withValues() with .withOpacity()
        disabledForegroundColor: colors.primary.withOpacity(0.38),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: GoogleFonts.lato(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        enableFeedback: true,
      ),
    );
  }

  static InputDecorationTheme _inputDecorationTheme(_AppColors colors) {
    return InputDecorationTheme(
      filled: true,
      fillColor: colors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: GoogleFonts.lato(color: colors.onSurfaceVariant),
      hintStyle: GoogleFonts.lato(color: colors.onSurfaceVariant),
      helperStyle: GoogleFonts.lato(color: colors.onSurfaceVariant),
      errorStyle: GoogleFonts.lato(color: colors.error),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colors.error, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        // FIX: Replaced non-existent .withValues() with .withOpacity()
        borderSide: BorderSide(color: colors.outline.withOpacity(0.5)),
      ),
      isDense: true,
      alignLabelWithHint: true,
    );
  }

  static ChipThemeData _chipTheme(_AppColors colors, Brightness brightness) {
    return ChipThemeData(
      backgroundColor: colors.surfaceVariant,
      // FIX: Replaced non-existent .withValues() with .withOpacity()
      disabledColor: colors.surfaceVariant.withOpacity(0.38),
      selectedColor: colors.primary,
      secondarySelectedColor: colors.primary,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      labelStyle: GoogleFonts.lato(
        color: colors.onSurface,
        fontSize: 14,
      ),
      secondaryLabelStyle: GoogleFonts.lato(
        color: colors.onPrimary,
        fontSize: 14,
      ),
      brightness: brightness,
      shape: StadiumBorder(
        side: BorderSide(color: colors.outline, width: 1),
      ),
      elevation: 0,
      pressElevation: 1,
    );
  }

  static DividerThemeData _dividerTheme(_AppColors colors) {
    return DividerThemeData(
      color: colors.outline,
      thickness: 1,
      space: 16,
      indent: 16,
      endIndent: 16,
    );
  }

  static SnackBarThemeData _snackBarTheme(_AppColors colors) {
    return SnackBarThemeData(
      backgroundColor: colors.surface,
      contentTextStyle: GoogleFonts.lato(color: colors.onSurface),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 6,
      actionTextColor: colors.primary,
      showCloseIcon: true,
      closeIconColor: colors.onSurfaceVariant,
    );
  }

  static BottomNavigationBarThemeData _bottomNavBarTheme(_AppColors colors) {
    return BottomNavigationBarThemeData(
      backgroundColor: colors.surface,
      selectedItemColor: colors.primary,
      unselectedItemColor: colors.onSurfaceVariant,
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
      elevation: 8,
      selectedLabelStyle: GoogleFonts.lato(
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
      unselectedLabelStyle: GoogleFonts.lato(fontSize: 12),
      showSelectedLabels: true,
    );
  }

  static BottomSheetThemeData _bottomSheetTheme(_AppColors colors) {
    return BottomSheetThemeData(
      backgroundColor: colors.surface,
      elevation: 8,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      modalBackgroundColor: colors.surface,
      modalElevation: 16,
      constraints: const BoxConstraints(maxWidth: 640),
      clipBehavior: Clip.antiAlias,
    );
  }

  static DialogThemeData _dialogTheme(_AppColors colors) {
    return DialogThemeData(
      backgroundColor: colors.surface,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      titleTextStyle: GoogleFonts.lato(
        color: colors.onSurface,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: GoogleFonts.lato(
        color: colors.onSurfaceVariant,
        fontSize: 16,
      ),
      alignment: Alignment.center,
      actionsPadding: const EdgeInsets.all(16),
      insetPadding: const EdgeInsets.all(24),
    );
  }

  static FloatingActionButtonThemeData _fabTheme(_AppColors colors) {
    return FloatingActionButtonThemeData(
      backgroundColor: colors.primary,
      foregroundColor: colors.onPrimary,
      elevation: 6,
      highlightElevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      extendedSizeConstraints: const BoxConstraints(
        minHeight: 48,
        minWidth: 48,
      ),
      extendedPadding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }

  static CheckboxThemeData _checkboxTheme(_AppColors colors) {
    return CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) {
          // FIX: Replaced non-existent .withValues() with .withOpacity()
          return colors.onSurface.withOpacity(0.38);
        }
        if (states.contains(WidgetState.selected)) {
          return colors.primary;
        }
        // FIX: Replaced non-existent .withValues() with .withOpacity()
        return colors.onSurface.withOpacity(0.54);
      }),
      checkColor: WidgetStateProperty.all(colors.onPrimary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      side: BorderSide(
        // FIX: Replaced non-existent .withValues() with .withOpacity()
        color: colors.onSurface.withOpacity(0.54),
        width: 2,
      ),
      splashRadius: 16,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  static RadioThemeData _radioTheme(_AppColors colors) {
    return RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) {
          // FIX: Replaced non-existent .withValues() with .withOpacity()
          return colors.onSurface.withOpacity(0.38);
        }
        if (states.contains(WidgetState.selected)) {
          return colors.primary;
        }
        // FIX: Replaced non-existent .withValues() with .withOpacity()
        return colors.onSurface.withOpacity(0.54);
      }),
      splashRadius: 16,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  static SwitchThemeData _switchTheme(_AppColors colors) {
    return SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) {
          return colors.surface;
        }
        if (states.contains(WidgetState.selected)) {
          return colors.primary;
        }
        return colors.surface;
      }),
      trackColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) {
          // FIX: Replaced non-existent .withValues() with .withOpacity()
          return colors.onSurface.withOpacity(0.12);
        }
        if (states.contains(WidgetState.selected)) {
          // FIX: Replaced non-existent .withValues() with .withOpacity()
          return colors.primary.withOpacity(0.54);
        }
        // FIX: Replaced non-existent .withValues() with .withOpacity()
        return colors.onSurface.withOpacity(0.54);
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.disabled)) {
          // FIX: Replaced non-existent .withValues() with .withOpacity()
          return colors.onSurface.withOpacity(0.12);
        }
        if (states.contains(WidgetState.selected)) {
          // FIX: Replaced non-existent .withValues() with .withOpacity()
          return colors.primary.withOpacity(0.54);
        }
        // FIX: Replaced non-existent .withValues() with .withOpacity()
        return colors.onSurface.withOpacity(0.54);
      }),
      splashRadius: 16,
      thumbIcon: WidgetStateProperty.resolveWith<Icon?>((states) {
        if (states.contains(WidgetState.selected)) {
          return const Icon(Icons.check, size: 18);
        }
        return null;
      }),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  static TabBarThemeData _tabBarTheme(_AppColors colors) {
    return TabBarThemeData(
      labelColor: colors.primary,
      unselectedLabelColor: colors.onSurfaceVariant,
      labelStyle: GoogleFonts.lato(
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
      unselectedLabelStyle: GoogleFonts.lato(
        fontSize: 14,
      ),
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(
          color: colors.primary,
          width: 2,
        ),
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: colors.outline,
      overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.pressed)) {
          // FIX: Replaced non-existent .withValues() with .withOpacity()
          return colors.primary.withOpacity(0.12);
        }
        if (states.contains(WidgetState.hovered)) {
          // FIX: Replaced non-existent .withValues() with .withOpacity()
          return colors.primary.withOpacity(0.08);
        }
        return null;
      }),
    );
  }

  static TooltipThemeData _tooltipTheme(_AppColors colors) {
    return TooltipThemeData(
      constraints: const BoxConstraints(minHeight: 32),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      textStyle: GoogleFonts.lato(
        color: colors.onSurface,
        fontSize: 12,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: colors.scrim,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      waitDuration: const Duration(milliseconds: 500),
      showDuration: const Duration(seconds: 2),
    );
  }

  static PopupMenuThemeData _popupMenuTheme(_AppColors colors) {
    return PopupMenuThemeData(
      color: colors.surface,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: GoogleFonts.lato(
        color: colors.onSurface,
        fontSize: 14,
      ),
      enableFeedback: true,
    );
  }

  static ListTileThemeData _listTileTheme(_AppColors colors) {
    return ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      minLeadingWidth: 24,
      minVerticalPadding: 12,
      iconColor: colors.onSurfaceVariant,
      textColor: colors.onSurface,
      titleTextStyle: GoogleFonts.lato(
        color: colors.onSurface,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      subtitleTextStyle: GoogleFonts.lato(
        color: colors.onSurfaceVariant,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      tileColor: Colors.transparent,
      // FIX: Replaced non-existent .withValues() with .withOpacity()
      selectedColor: colors.primary.withOpacity(0.12),
      selectedTileColor: colors.primary.withOpacity(0.08),
      horizontalTitleGap: 16,
      dense: false,
      enableFeedback: true,
      style: ListTileStyle.list,
    );
  }

  static ProgressIndicatorThemeData _progressIndicatorTheme(_AppColors colors) {
    return ProgressIndicatorThemeData(
      color: colors.primary,
      linearTrackColor: colors.surfaceVariant,
      circularTrackColor: colors.surfaceVariant,
      refreshBackgroundColor: colors.surfaceVariant,
      linearMinHeight: 4,
    );
  }

  static DataTableThemeData _dataTableTheme(_AppColors colors) {
    return DataTableThemeData(
      dataRowColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.selected)) {
          // FIX: Replaced non-existent .withValues() with .withOpacity()
          return colors.primary.withOpacity(0.12);
        }
        if (states.contains(WidgetState.hovered)) {
          return colors.surfaceVariant;
        }
        return null;
      }),
      dataRowMinHeight: 48,
      // FIX: Removed dataRowMaxHeight to prevent content overflow.
      // dataRowMaxHeight: 72,
      headingRowColor: WidgetStateProperty.all(colors.surfaceVariant),
      headingRowHeight: 56,
      horizontalMargin: 16,
      columnSpacing: 24,
      dividerThickness: 1,
      // FIX: Removed decoration. The dividerThickness property correctly
      // handles row dividers. This decoration was adding a single border
      // to the bottom of the entire table, which is likely unintended.
      // decoration: BoxDecoration(
      //   border: Border(
      //     bottom: BorderSide(color: colors.outline),
      //   ),
      // ),
      dataTextStyle: GoogleFonts.lato(
        color: colors.onSurface,
        fontSize: 14,
      ),
      headingTextStyle: GoogleFonts.lato(
        color: colors.onSurface,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  static NavigationRailThemeData _navigationRailTheme(_AppColors colors) {
    return NavigationRailThemeData(
      backgroundColor: colors.surface,
      elevation: 2,
      unselectedLabelTextStyle: GoogleFonts.lato(
        color: colors.onSurfaceVariant,
        fontSize: 14,
      ),
      selectedLabelTextStyle: GoogleFonts.lato(
        color: colors.primary,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
      labelType: NavigationRailLabelType.all,
      groupAlignment: -0.5,
      useIndicator: true,
      // FIX: Replaced non-existent .withValues() with .withOpacity()
      indicatorColor: colors.primary.withOpacity(0.12),
      minWidth: 72,
      minExtendedWidth: 200,
    );
  }

  static ScrollbarThemeData _scrollbarTheme(_AppColors colors) {
    return ScrollbarThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.hovered)) {
          // FIX: Replaced non-existent .withValues() with .withOpacity()
          return colors.onSurfaceVariant.withOpacity(0.5);
        }
        // FIX: Replaced non-existent .withValues() with .withOpacity()
        return colors.onSurfaceVariant.withOpacity(0.3);
      }),
      trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.hovered)) {
          return colors.surfaceVariant;
        }
        return null;
      }),
      thickness: WidgetStateProperty.resolveWith<double>((states) {
        if (states.contains(WidgetState.hovered)) {
          return 8;
        }
        return 4;
      }),
      radius: const Radius.circular(4),
      crossAxisMargin: 2,
      mainAxisMargin: 4,
      interactive: true,
    );
  }
}

// ========== Spacing System ==========
class AppSpacing {
  static const double s2 = 2.0;
  static const double s4 = 4.0;
  static const double s8 = 8.0;
  static const double s12 = 12.0;
  static const double s16 = 16.0;
  static const double s20 = 20.0;
  static const double s24 = 24.0;
  static const double s32 = 32.0;
  static const double s40 = 40.0;
  static const double s48 = 48.0;
  static const double s56 = 56.0;
  static const double s64 = 64.0;
  static const double s72 = 72.0;
  static const double s80 = 80.0;

  // Padding shortcuts
  static EdgeInsets get none => EdgeInsets.zero;
  static EdgeInsets get xxxs => const EdgeInsets.all(s2);
  static EdgeInsets get xxs => const EdgeInsets.all(s4);
  static EdgeInsets get xs => const EdgeInsets.all(s8);
  static EdgeInsets get sm => const EdgeInsets.all(s12);
  static EdgeInsets get md => const EdgeInsets.all(s16);
  static EdgeInsets get lg => const EdgeInsets.all(s24);
  static EdgeInsets get xl => const EdgeInsets.all(s32);
  static EdgeInsets get xxl => const EdgeInsets.all(s48);

  static EdgeInsets get horizontalXs =>
      const EdgeInsets.symmetric(horizontal: s8);
  static EdgeInsets get horizontalSm =>
      const EdgeInsets.symmetric(horizontal: s12);
  static EdgeInsets get horizontalMd =>
      const EdgeInsets.symmetric(horizontal: s16);
  static EdgeInsets get horizontalLg =>
      const EdgeInsets.symmetric(horizontal: s24);
  static EdgeInsets get horizontalXl =>
      const EdgeInsets.symmetric(horizontal: s32);

  static EdgeInsets get verticalXs => const EdgeInsets.symmetric(vertical: s8);
  static EdgeInsets get verticalSm => const EdgeInsets.symmetric(vertical: s12);
  static EdgeInsets get verticalMd => const EdgeInsets.symmetric(vertical: s16);
  static EdgeInsets get verticalLg => const EdgeInsets.symmetric(vertical: s24);
  static EdgeInsets get verticalXl => const EdgeInsets.symmetric(vertical: s32);

  static EdgeInsets get pagePadding => const EdgeInsets.symmetric(
    horizontal: s24,
    vertical: s16,
  );

  static EdgeInsets get cardPadding => const EdgeInsets.all(s16);
  static EdgeInsets get buttonPadding => const EdgeInsets.symmetric(
    horizontal: s24,
    vertical: s12,
  );
  static EdgeInsets get inputPadding => const EdgeInsets.symmetric(
    horizontal: s16,
    vertical: s12,
  );
}

// ========== Border Radius System ==========
class AppBorderRadius {
  static const BorderRadius none = BorderRadius.zero;
  static const BorderRadius xxs = BorderRadius.all(Radius.circular(2.0));
  static const BorderRadius xs = BorderRadius.all(Radius.circular(4.0));
  static const BorderRadius sm = BorderRadius.all(Radius.circular(8.0));
  static const BorderRadius md = BorderRadius.all(Radius.circular(12.0));
  static const BorderRadius lg = BorderRadius.all(Radius.circular(16.0));
  static const BorderRadius xl = BorderRadius.all(Radius.circular(24.0));
  static const BorderRadius xxl = BorderRadius.all(Radius.circular(32.0));
  static const BorderRadius full = BorderRadius.all(Radius.circular(999.0));

  static BorderRadius only({
    double topLeft = 0,
    double topRight = 0,
    double bottomLeft = 0,
    double bottomRight = 0,
  }) =>
      BorderRadius.only(
        topLeft: Radius.circular(topLeft),
        topRight: Radius.circular(topRight),
        bottomLeft: Radius.circular(bottomLeft),
        bottomRight: Radius.circular(bottomRight),
      );

  static BorderRadius top(double radius) => BorderRadius.vertical(
    top: Radius.circular(radius),
  );

  static BorderRadius bottom(double radius) => BorderRadius.vertical(
    bottom: Radius.circular(radius),
  );

  static BorderRadius left(double radius) => BorderRadius.horizontal(
    left: Radius.circular(radius),
  );

  static BorderRadius right(double radius) => BorderRadius.horizontal(
    right: Radius.circular(radius),
  );
}

// ========== Gradient Text Widget ==========
class GradientText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Gradient gradient;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextDirection? textDirection;
  final bool? softWrap;
  final TextScaler? textScaler;
  final StrutStyle? strutStyle;
  final Locale? locale;

  const GradientText(
      this.text, {
        super.key,
        required this.gradient,
        this.style,
        this.textAlign,
        this.maxLines,
        this.overflow,
        this.textDirection,
        this.softWrap,
        this.textScaler,
        this.strutStyle,
        this.locale,
      });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(
        text,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        textDirection: textDirection,
        softWrap: softWrap,
        textScaler: textScaler,
        strutStyle: strutStyle,
        locale: locale,
      ),
    );
  }
}