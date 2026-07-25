import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_theme_extension.dart';

export 'app_colors.dart';
export 'app_spacing.dart';
export 'app_theme_extension.dart';

/// Central theme configuration for EuroWander.
///
/// Usage:
///   - Access Material tokens: `Theme.of(context).colorScheme.primary`
///   - Access custom tokens: `context.ew.textPrimary` or
///     `Theme.of(context).extension<EuroWanderTheme>()!`
///   - Spacing: `AppSpacing.md`, `AppRadius.lg`, `AppShadows.md(...)`
class AppTheme {
  AppTheme._();

  // ──────────────────────────────────────────────
  // Legacy accessors (for incremental migration)
  // ──────────────────────────────────────────────
  static const Color primaryColor = AppColors.brandPrimary;
  static const Color secondaryColor = AppColors.brandSecondary;
  static const Color accentColor = AppColors.brandAccent;
  static const Color backgroundColor = AppColors.lightBackground;
  static const Color surfaceColor = AppColors.lightSurface;
  static const Color textPrimary = AppColors.lightTextPrimary;
  static const Color textSecondary = AppColors.lightTextSecondary;

  // ──────────────────────────────────────────────
  // Typography
  // ──────────────────────────────────────────────
  static TextTheme _buildTextTheme(Color primary, Color secondary) {
    return TextTheme(
      // Display
      displayLarge: GoogleFonts.poppins(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.5,
        color: primary,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.25,
        color: primary,
      ),
      displaySmall: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: primary,
      ),
      // Headline
      headlineLarge: GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: primary,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: primary,
      ),
      headlineSmall: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: primary,
      ),
      // Title
      titleLarge: GoogleFonts.poppins(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 0.1,
        color: primary,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        height: 1.45,
        letterSpacing: 0.1,
        color: primary,
      ),
      titleSmall: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.45,
        letterSpacing: 0.15,
        color: primary,
      ),
      // Body
      bodyLarge: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: primary,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: secondary,
      ),
      bodySmall: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.5,
        letterSpacing: 0.2,
        color: secondary,
      ),
      // Label
      labelLarge: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 0.1,
        color: primary,
      ),
      labelMedium: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.3,
        color: secondary,
      ),
      labelSmall: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.4,
        letterSpacing: 0.4,
        color: secondary,
      ),
    );
  }

  // ──────────────────────────────────────────────
  // LIGHT THEME
  // ──────────────────────────────────────────────
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.brandPrimary,
      brightness: Brightness.light,
      primary: AppColors.brandPrimary,
      secondary: AppColors.brandSecondary,
      tertiary: AppColors.brandAccent,
      surface: AppColors.lightSurface,
      error: AppColors.error,
    );

    final textTheme = _buildTextTheme(
      AppColors.lightTextPrimary,
      AppColors.lightTextSecondary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.lightBackground,
      textTheme: textTheme,
      extensions: const [EuroWanderTheme.light],

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.lightTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          height: 1.4,
          color: AppColors.lightTextPrimary,
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.lightCard,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderLg,
        ),
        margin: EdgeInsets.zero,
      ),

      // Elevated Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.borderMd,
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
      ),

      // Outlined Buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brandPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.borderMd,
          ),
          side: BorderSide(
            color: AppColors.brandPrimary.withOpacity(0.3),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
      ),

      // Text Buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brandPrimary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.borderMd,
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // FAB
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderLg,
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightInputFill,
        border: OutlineInputBorder(
          borderRadius: AppRadius.borderMd,
          borderSide: BorderSide(color: AppColors.lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderMd,
          borderSide: BorderSide(color: AppColors.lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderMd,
          borderSide: const BorderSide(color: AppColors.brandPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderMd,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + AppSpacing.xxs,
        ),
        hintStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: AppColors.lightTextTertiary,
        ),
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightSurfaceVariant,
        selectedColor: AppColors.brandPrimary.withOpacity(0.12),
        labelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderPill,
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
      ),

      // Bottom Navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedItemColor: AppColors.brandPrimary,
        unselectedItemColor: AppColors.lightTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // Bottom Sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppRadius.xxl),
            topRight: Radius.circular(AppRadius.xxl),
          ),
        ),
        elevation: 0,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderXl,
        ),
        elevation: 0,
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorderSubtle,
        thickness: 1,
        space: 0,
      ),

      // Tab Bar
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.brandPrimary,
        unselectedLabelColor: AppColors.lightTextSecondary,
        indicatorColor: AppColors.brandPrimary,
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // DARK THEME
  // ──────────────────────────────────────────────
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.brandPrimary,
      brightness: Brightness.dark,
      primary: AppColors.brandPrimary,
      secondary: AppColors.brandSecondary,
      tertiary: AppColors.brandAccent,
      surface: AppColors.darkSurface,
      error: AppColors.error,
    );

    final textTheme = _buildTextTheme(
      AppColors.darkTextPrimary,
      AppColors.darkTextSecondary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
      textTheme: textTheme,
      extensions: const [EuroWanderTheme.dark],

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          height: 1.4,
          color: AppColors.darkTextPrimary,
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.darkCard,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderLg,
        ),
        margin: EdgeInsets.zero,
      ),

      // Elevated Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.borderMd,
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
      ),

      // Outlined Buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brandPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.borderMd,
          ),
          side: BorderSide(
            color: AppColors.brandPrimary.withOpacity(0.4),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
      ),

      // Text Buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brandPrimary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.borderMd,
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // FAB
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderLg,
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkInputFill,
        border: OutlineInputBorder(
          borderRadius: AppRadius.borderMd,
          borderSide: BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderMd,
          borderSide: BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderMd,
          borderSide: const BorderSide(color: AppColors.brandPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderMd,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + AppSpacing.xxs,
        ),
        hintStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: AppColors.darkTextTertiary,
        ),
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurfaceVariant,
        selectedColor: AppColors.brandPrimary.withOpacity(0.2),
        labelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderPill,
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
      ),

      // Bottom Navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.brandPrimary,
        unselectedItemColor: AppColors.darkTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // Bottom Sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppRadius.xxl),
            topRight: Radius.circular(AppRadius.xxl),
          ),
        ),
        elevation: 0,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderXl,
        ),
        elevation: 0,
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorderSubtle,
        thickness: 1,
        space: 0,
      ),

      // Tab Bar
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.brandPrimary,
        unselectedLabelColor: AppColors.darkTextSecondary,
        indicatorColor: AppColors.brandPrimary,
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
