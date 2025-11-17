import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ========== Material 3 Color System ==========
class _AppColors {
  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color secondary;
  final Color onSecondary;
  final Color secondaryContainer;
  final Color onSecondaryContainer;
  final Color tertiary;
  final Color onTertiary;
  final Color tertiaryContainer;
  final Color onTertiaryContainer;
  final Color error;
  final Color onError;
  final Color errorContainer;
  final Color onErrorContainer;
  final Color background;
  final Color onBackground;
  final Color surface;
  final Color onSurface;
  final Color surfaceVariant;
  final Color onSurfaceVariant;
  final Color outline;
  final Color outlineVariant;
  final Color shadow;
  final Color scrim;
  final Color inverseSurface;
  final Color onInverseSurface;
  final Color inversePrimary;
  final Color surfaceTint;

  const _AppColors({
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.tertiary,
    required this.onTertiary,
    required this.tertiaryContainer,
    required this.onTertiaryContainer,
    required this.error,
    required this.onError,
    required this.errorContainer,
    required this.onErrorContainer,
    required this.background,
    required this.onBackground,
    required this.surface,
    required this.onSurface,
    required this.surfaceVariant,
    required this.onSurfaceVariant,
    required this.outline,
    required this.outlineVariant,
    required this.shadow,
    required this.scrim,
    required this.inverseSurface,
    required this.onInverseSurface,
    required this.inversePrimary,
    required this.surfaceTint,
  });
}

/// A comprehensive Material 3 theme system
class AppTheme {
  AppTheme._();

  // ========== Material 3 Color Schemes ==========
  static const _AppColors _lightColors = _AppColors(
    primary: Color(0xFF006A67),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFF70F7F1),
    onPrimaryContainer: Color(0xFF00201F),
    secondary: Color(0xFF4A6361),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFCCE8E5),
    onSecondaryContainer: Color(0xFF05201F),
    tertiary: Color(0xFF4B5F7D),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFD3E4FF),
    onTertiaryContainer: Color(0xFF041C35),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    background: Color(0xFFFAFDFB),
    onBackground: Color(0xFF191C1C),
    surface: Color(0xFFFAFDFB),
    onSurface: Color(0xFF191C1C),
    surfaceVariant: Color(0xFFDAE5E3),
    onSurfaceVariant: Color(0xFF3F4948),
    outline: Color(0xFF6F7978),
    outlineVariant: Color(0xFFBEC9C7),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF2D3131),
    onInverseSurface: Color(0xFFEFF1F0),
    inversePrimary: Color(0xFF4FDAD4),
    surfaceTint: Color(0xFF006A67),
  );

  static const _AppColors _darkColors = _AppColors(
    primary: Color(0xFF4FDAD4),
    onPrimary: Color(0xFF003735),
    primaryContainer: Color(0xFF00504D),
    onPrimaryContainer: Color(0xFF70F7F1),
    secondary: Color(0xFFB1CCC9),
    onSecondary: Color(0xFF1C3533),
    secondaryContainer: Color(0xFF324B49),
    onSecondaryContainer: Color(0xFFCCE8E5),
    tertiary: Color(0xFFB3C8E9),
    onTertiary: Color(0xFF1C314B),
    tertiaryContainer: Color(0xFF334863),
    onTertiaryContainer: Color(0xFFD3E4FF),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    background: Color(0xFF191C1C),
    onBackground: Color(0xFFE0E3E2),
    surface: Color(0xFF191C1C),
    onSurface: Color(0xFFE0E3E2),
    surfaceVariant: Color(0xFF3F4948),
    onSurfaceVariant: Color(0xFFBEC9C7),
    outline: Color(0xFF889392),
    outlineVariant: Color(0xFF3F4948),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFE0E3E2),
    onInverseSurface: Color(0xFF2D3131),
    inversePrimary: Color(0xFF006A67),
    surfaceTint: Color(0xFF4FDAD4),
  );

  // ========== Theme Data ==========
  static ThemeData get light => _buildTheme(_lightColors, Brightness.light);

  static ThemeData get dark => _buildTheme(_darkColors, Brightness.dark);

  // ========== Core Theme Builder ==========
  static ThemeData _buildTheme(_AppColors colors, Brightness brightness) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: colors.primary,
      onPrimary: colors.onPrimary,
      primaryContainer: colors.primaryContainer,
      onPrimaryContainer: colors.onPrimaryContainer,
      secondary: colors.secondary,
      onSecondary: colors.onSecondary,
      secondaryContainer: colors.secondaryContainer,
      onSecondaryContainer: colors.onSecondaryContainer,
      tertiary: colors.tertiary,
      onTertiary: colors.onTertiary,
      tertiaryContainer: colors.tertiaryContainer,
      onTertiaryContainer: colors.onTertiaryContainer,
      error: colors.error,
      onError: colors.onError,
      errorContainer: colors.errorContainer,
      onErrorContainer: colors.onErrorContainer,
      background: colors.background,
      onBackground: colors.onBackground,
      surface: colors.surface,
      onSurface: colors.onSurface,
      surfaceVariant: colors.surfaceVariant,
      onSurfaceVariant: colors.onSurfaceVariant,
      outline: colors.outline,
      outlineVariant: colors.outlineVariant,
      shadow: colors.shadow,
      scrim: colors.scrim,
      inverseSurface: colors.inverseSurface,
      onInverseSurface: colors.onInverseSurface,
      inversePrimary: colors.inversePrimary,
      surfaceTint: colors.surfaceTint,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: brightness,

      // Text Theme
      textTheme: _buildTextTheme(colors, brightness),
      iconTheme: _iconTheme(colors),

      // App Bar
      appBarTheme: _appBarTheme(colors, brightness, colorScheme),

      // Cards
      cardTheme: _cardTheme(colors),

      // Buttons
      elevatedButtonTheme: _elevatedButtonTheme(colors),
      outlinedButtonTheme: _outlinedButtonTheme(colors),
      textButtonTheme: _textButtonTheme(colors),
      filledButtonTheme: _filledButtonTheme(colors),

      // Inputs
      inputDecorationTheme: _inputDecorationTheme(colors),

      // Navigation
      navigationBarTheme: _navigationBarTheme(colors),
      navigationRailTheme: _navigationRailTheme(colors),
      bottomNavigationBarTheme: _bottomNavBarTheme(colors),

      // Dialogs & Sheets
      dialogTheme: _dialogTheme(colors),
      bottomSheetTheme: _bottomSheetTheme(colors),

      // Other Components
      chipTheme: _chipTheme(colors, brightness),
      dividerTheme: _dividerTheme(colors),
      snackBarTheme: _snackBarTheme(colors),
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
      scrollbarTheme: _scrollbarTheme(colors),
      badgeTheme: _badgeTheme(colors),

      // Material 3 specific
      searchBarTheme: _searchBarTheme(colors),
      searchViewTheme: _searchViewTheme(colors),
    );
  }

  // ========== Component Themes ==========
  static TextTheme _buildTextTheme(_AppColors colors, Brightness brightness) {
    return TextTheme(
      displayLarge: GoogleFonts.robotoFlex(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        height: 1.12,
        letterSpacing: -0.25,
        color: colors.onBackground,
      ),
      displayMedium: GoogleFonts.robotoFlex(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        height: 1.16,
        color: colors.onBackground,
      ),
      displaySmall: GoogleFonts.robotoFlex(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        height: 1.22,
        letterSpacing: 0,
        color: colors.onBackground,
      ),
      headlineLarge: GoogleFonts.robotoFlex(
        fontSize: 32,
        fontWeight: FontWeight.w400,
        height: 1.25,
        color: colors.onBackground,
      ),
      headlineMedium: GoogleFonts.robotoFlex(
        fontSize: 28,
        fontWeight: FontWeight.w400,
        height: 1.29,
        color: colors.onBackground,
      ),
      headlineSmall: GoogleFonts.robotoFlex(
        fontSize: 24,
        fontWeight: FontWeight.w400,
        height: 1.33,
        color: colors.onBackground,
      ),
      titleLarge: GoogleFonts.robotoFlex(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        height: 1.27,
        color: colors.onBackground,
      ),
      titleMedium: GoogleFonts.robotoFlex(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.5,
        letterSpacing: 0.15,
        color: colors.onSurface,
      ),
      titleSmall: GoogleFonts.robotoFlex(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.43,
        letterSpacing: 0.1,
        color: colors.onSurfaceVariant,
      ),
      bodyLarge: GoogleFonts.robotoFlex(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        letterSpacing: 0.5,
        color: colors.onSurface,
      ),
      bodyMedium: GoogleFonts.robotoFlex(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.43,
        letterSpacing: 0.25,
        color: colors.onSurfaceVariant,
      ),
      bodySmall: GoogleFonts.robotoFlex(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.33,
        letterSpacing: 0.4,
        color: colors.onSurfaceVariant,
      ),
      labelLarge: GoogleFonts.robotoFlex(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.43,
        letterSpacing: 0.1,
        color: colors.onSurface,
      ),
      labelMedium: GoogleFonts.robotoFlex(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.33,
        letterSpacing: 0.5,
        color: colors.onSurface,
      ),
      labelSmall: GoogleFonts.robotoFlex(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.45,
        letterSpacing: 0.5,
        color: colors.onSurfaceVariant,
      ),
    );
  }

  static IconThemeData _iconTheme(_AppColors colors) {
    return IconThemeData(color: colors.onSurfaceVariant, size: 24);
  }

  static AppBarTheme _appBarTheme(
      _AppColors colors,
      Brightness brightness,
      ColorScheme colorScheme,
      ) {
    return AppBarTheme(
      systemOverlayStyle: brightness == Brightness.light
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      backgroundColor: colorScheme.surface,
      foregroundColor: colors.onSurface,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.robotoFlex(
        color: colors.onSurface,
        fontSize: 22,
        fontWeight: FontWeight.w500,
      ),
      scrolledUnderElevation: 3,
      surfaceTintColor: colors.surfaceTint,
    );
  }

  static CardThemeData _cardTheme(_AppColors colors) {
    return CardThemeData(
      color: colors.surface,
      shadowColor: colors.shadow,
      surfaceTintColor: colors.surfaceTint,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme(_AppColors colors) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        disabledBackgroundColor: colors.onSurface.withOpacity(0.12),
        disabledForegroundColor: colors.onSurface.withOpacity(0.38),
        elevation: 1,
        shadowColor: colors.shadow,
        textStyle: GoogleFonts.robotoFlex(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        enableFeedback: true,
      ),
    );
  }

  static FilledButtonThemeData _filledButtonTheme(_AppColors colors) {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        textStyle: GoogleFonts.robotoFlex(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  static OutlinedButtonThemeData _outlinedButtonTheme(_AppColors colors) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.primary,
        side: BorderSide(color: colors.outline),
        textStyle: GoogleFonts.robotoFlex(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  static TextButtonThemeData _textButtonTheme(_AppColors colors) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colors.primary,
        textStyle: GoogleFonts.robotoFlex(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  static InputDecorationTheme _inputDecorationTheme(_AppColors colors) {
    return InputDecorationTheme(
      filled: true,
      fillColor: colors.surfaceVariant.withOpacity(0.4),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colors.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colors.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colors.error, width: 2),
      ),
      labelStyle: GoogleFonts.robotoFlex(
        color: colors.onSurfaceVariant,
        fontSize: 14,
      ),
      hintStyle: GoogleFonts.robotoFlex(
        color: colors.onSurfaceVariant,
        fontSize: 14,
      ),
    );
  }

  static NavigationBarThemeData _navigationBarTheme(_AppColors colors) {
    return NavigationBarThemeData(
      backgroundColor: colors.surface,
      elevation: 0,
      indicatorColor: colors.secondaryContainer,
      labelTextStyle: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return GoogleFonts.robotoFlex(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colors.onSecondaryContainer,
          );
        }
        return GoogleFonts.robotoFlex(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: colors.onSurfaceVariant,
        );
      }),
    );
  }

  static NavigationRailThemeData _navigationRailTheme(_AppColors colors) {
    return NavigationRailThemeData(
      backgroundColor: colors.surface,
      elevation: 2,
      unselectedLabelTextStyle: GoogleFonts.robotoFlex(
        color: colors.onSurfaceVariant,
        fontSize: 14,
      ),
      selectedLabelTextStyle: GoogleFonts.robotoFlex(
        color: colors.primary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      labelType: NavigationRailLabelType.all,
      groupAlignment: -0.5,
      useIndicator: true,
      indicatorColor: colors.primary.withOpacity(0.12),
      minWidth: 72,
      minExtendedWidth: 200,
    );
  }

  static BottomNavigationBarThemeData _bottomNavBarTheme(_AppColors colors) {
    return BottomNavigationBarThemeData(
      backgroundColor: colors.surface,
      selectedItemColor: colors.primary,
      unselectedItemColor: colors.onSurfaceVariant,
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
      elevation: 1,
      selectedLabelStyle: GoogleFonts.robotoFlex(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: GoogleFonts.robotoFlex(fontSize: 12),
      showSelectedLabels: true,
    );
  }

  static DialogThemeData _dialogTheme(_AppColors colors) {
    return DialogThemeData(
      backgroundColor: colors.surface,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      titleTextStyle: GoogleFonts.robotoFlex(
        color: colors.onSurface,
        fontSize: 24,
        fontWeight: FontWeight.w500,
      ),
      contentTextStyle: GoogleFonts.robotoFlex(
        color: colors.onSurfaceVariant,
        fontSize: 16,
      ),
      alignment: Alignment.center,
      actionsPadding: const EdgeInsets.all(16),
      insetPadding: const EdgeInsets.all(24),
    );
  }

  static BottomSheetThemeData _bottomSheetTheme(_AppColors colors) {
    return BottomSheetThemeData(
      backgroundColor: colors.surface,
      elevation: 3,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      modalBackgroundColor: colors.surface,
      modalElevation: 3,
      constraints: const BoxConstraints(maxWidth: 640),
      clipBehavior: Clip.antiAlias,
      showDragHandle: true,
    );
  }

  static ChipThemeData _chipTheme(_AppColors colors, Brightness brightness) {
    return ChipThemeData(
      backgroundColor: colors.surfaceVariant,
      selectedColor: colors.primaryContainer,
      secondarySelectedColor: colors.primaryContainer,
      labelStyle: GoogleFonts.robotoFlex(
        color: colors.onSurfaceVariant,
        fontSize: 14,
      ),
      secondaryLabelStyle: GoogleFonts.robotoFlex(
        color: colors.onPrimaryContainer,
        fontSize: 14,
      ),
      shape: StadiumBorder(side: BorderSide(color: colors.outline)),
    );
  }

  static DividerThemeData _dividerTheme(_AppColors colors) {
    return DividerThemeData(
      color: colors.outlineVariant,
      thickness: 1,
      space: 16,
    );
  }

  static SnackBarThemeData _snackBarTheme(_AppColors colors) {
    return SnackBarThemeData(
      backgroundColor: colors.inverseSurface,
      contentTextStyle: GoogleFonts.robotoFlex(color: colors.onInverseSurface),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 6,
    );
  }

  static FloatingActionButtonThemeData _fabTheme(_AppColors colors) {
    return FloatingActionButtonThemeData(
      backgroundColor: colors.primaryContainer,
      foregroundColor: colors.onPrimaryContainer,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  static CheckboxThemeData _checkboxTheme(_AppColors colors) {
    return CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return colors.primary;
        }
        return null;
      }),
      checkColor: MaterialStateProperty.all(colors.onPrimary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    );
  }

  static RadioThemeData _radioTheme(_AppColors colors) {
    return RadioThemeData(
      fillColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return colors.primary;
        }
        return colors.onSurfaceVariant;
      }),
    );
  }

  static SwitchThemeData _switchTheme(_AppColors colors) {
    return SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return colors.onPrimary;
        }
        return colors.outlineVariant;
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return colors.primary;
        }
        return colors.surfaceVariant;
      }),
      trackOutlineColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return Colors.transparent;
        }
        return null; // Use default
      }),
    );
  }

  static TabBarThemeData _tabBarTheme(_AppColors colors) {
    return TabBarThemeData(
      labelColor: colors.primary,
      unselectedLabelColor: colors.onSurfaceVariant,
      labelStyle: GoogleFonts.robotoFlex(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: GoogleFonts.robotoFlex(fontSize: 14),
      indicator: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.primary, width: 2)),
      ),
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: colors.outline,
      overlayColor: MaterialStateProperty.resolveWith<Color?>((states) {
        if (states.contains(MaterialState.pressed)) {
          return colors.primary.withOpacity(0.12);
        }
        if (states.contains(MaterialState.hovered)) {
          return colors.primary.withOpacity(0.08);
        }
        return null;
      }),
    );
  }

  static TooltipThemeData _tooltipTheme(_AppColors colors) {
    return TooltipThemeData(
      decoration: BoxDecoration(
        color: colors.inverseSurface,
        borderRadius: BorderRadius.circular(4),
      ),
      textStyle: GoogleFonts.robotoFlex(
        color: colors.onInverseSurface,
        fontSize: 12,
      ),
    );
  }

  static PopupMenuThemeData _popupMenuTheme(_AppColors colors) {
    return PopupMenuThemeData(
      color: colors.surface,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: GoogleFonts.robotoFlex(color: colors.onSurface, fontSize: 14),
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
      titleTextStyle: GoogleFonts.robotoFlex(
        color: colors.onSurface,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      subtitleTextStyle: GoogleFonts.robotoFlex(
        color: colors.onSurfaceVariant,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      tileColor: Colors.transparent,
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
    );
  }

  static DataTableThemeData _dataTableTheme(_AppColors colors) {
    return DataTableThemeData(
      dataRowColor: MaterialStateProperty.resolveWith<Color?>((states) {
        if (states.contains(MaterialState.selected)) {
          return colors.primary.withOpacity(0.12);
        }
        if (states.contains(MaterialState.hovered)) {
          return colors.surfaceVariant;
        }
        return null;
      }),
      dataRowMinHeight: 48,
      headingRowColor: MaterialStateProperty.all(colors.surfaceVariant),
      headingRowHeight: 56,
      horizontalMargin: 16,
      columnSpacing: 24,
      dividerThickness: 1,
      dataTextStyle: GoogleFonts.robotoFlex(
        color: colors.onSurface,
        fontSize: 14,
      ),
      headingTextStyle: GoogleFonts.robotoFlex(
        color: colors.onSurface,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  static ScrollbarThemeData _scrollbarTheme(_AppColors colors) {
    return ScrollbarThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.pressed)) {
          return colors.onSurfaceVariant.withOpacity(0.8);
        }
        if (states.contains(MaterialState.hovered)) {
          return colors.onSurfaceVariant.withOpacity(0.6);
        }
        return colors.onSurfaceVariant.withOpacity(0.4);
      }),
    );
  }

  static BadgeThemeData _badgeTheme(_AppColors colors) {
    return BadgeThemeData(
      backgroundColor: colors.error,
      textColor: colors.onError,
      alignment: Alignment.topRight,
    );
  }

  // Material 3 specific components
  static SearchBarThemeData _searchBarTheme(_AppColors colors) {
    return SearchBarThemeData(
      backgroundColor: MaterialStateProperty.all(
        colors.surfaceVariant.withOpacity(0.4),
      ),
      elevation: MaterialStateProperty.all(0),
      textStyle: MaterialStateProperty.all(
        GoogleFonts.robotoFlex(color: colors.onSurface, fontSize: 16),
      ),
      hintStyle: MaterialStateProperty.all(
        GoogleFonts.robotoFlex(color: colors.onSurfaceVariant, fontSize: 16),
      ),
    );
  }

  static SearchViewThemeData _searchViewTheme(_AppColors colors) {
    return SearchViewThemeData(backgroundColor: colors.surface, elevation: 2);
  }
}

// ========== Material 3 Spacing System ==========
class AppSpacingSystem {
  static const double s4 = 4.0;
  static const double s8 = 8.0;
  static const double s12 = 12.0;
  static const double s16 = 16.0;
  static const double s20 = 20.0;
  static const double s24 = 24.0;
  static const double s32 = 32.0;
  static const double s40 = 40.0;
  static const double s48 = 48.0;

  static EdgeInsets get none => EdgeInsets.zero;

  static EdgeInsets get xs => const EdgeInsets.all(s4);

  static EdgeInsets get sm => const EdgeInsets.all(s8);

  static EdgeInsets get md => const EdgeInsets.all(s12);

  static EdgeInsets get lg => const EdgeInsets.all(s16);

  static EdgeInsets get xl => const EdgeInsets.all(s24);

  static EdgeInsets get xxl => const EdgeInsets.all(s32);

  static EdgeInsets get horizontalSm =>
      const EdgeInsets.symmetric(horizontal: s8);

  static EdgeInsets get horizontalMd =>
      const EdgeInsets.symmetric(horizontal: s16);

  static EdgeInsets get horizontalLg =>
      const EdgeInsets.symmetric(horizontal: s24);

  static EdgeInsets get verticalSm => const EdgeInsets.symmetric(vertical: s8);

  static EdgeInsets get verticalMd => const EdgeInsets.symmetric(vertical: s16);

  static EdgeInsets get verticalLg => const EdgeInsets.symmetric(vertical: s24);

  static EdgeInsets get pagePadding =>
      const EdgeInsets.symmetric(horizontal: s24, vertical: s16);
}

// ========== Material 3 Border Radius System ==========
class AppBorderRadius {
  static const BorderRadius none = BorderRadius.zero;
  static const BorderRadius xs = BorderRadius.all(Radius.circular(4.0));
  static const BorderRadius sm = BorderRadius.all(Radius.circular(8.0));
  static const BorderRadius md = BorderRadius.all(Radius.circular(12.0));
  static const BorderRadius lg = BorderRadius.all(Radius.circular(16.0));
  static const BorderRadius xl = BorderRadius.all(Radius.circular(20.0));
  static const BorderRadius xxl = BorderRadius.all(Radius.circular(28.0));
  static const BorderRadius full = BorderRadius.all(Radius.circular(999.0));
}

// ========== Material 3 Gradient Text Widget ==========
class GradientText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Gradient gradient;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const GradientText(
      this.text, {
        super.key,
        required this.gradient,
        this.style,
        this.textAlign,
        this.maxLines,
        this.overflow,
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
      ),
    );
  }
}