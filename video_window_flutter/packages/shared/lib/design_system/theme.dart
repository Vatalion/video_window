import 'package:flutter/material.dart';
import 'package:shared/design_system/tokens.dart';

/// Application theme configuration.
///
/// Provides Material 3 theming with light and dark mode support.
/// All themes use design tokens from [tokens.dart] for consistency.
///
/// Usage:
/// ```dart
/// MaterialApp(
///   theme: AppTheme.lightTheme,
///   darkTheme: AppTheme.darkTheme,
///   themeMode: ThemeMode.system, // or ThemeMode.light/dark
/// )
/// ```
class AppTheme {
  AppTheme._(); // Private constructor to prevent instantiation

  /// Light theme configuration
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryLight,
      onPrimaryContainer: AppColors.neutral900,
      secondary: AppColors.primaryLight,
      onSecondary: AppColors.onPrimary,
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.error.withValues(alpha: 0.1),
      onErrorContainer: AppColors.errorDark,
      surface: AppColors.surface,
      onSurface: AppColors.neutral900,
      surfaceContainerHighest: AppColors.neutral100,
      onSurfaceVariant: AppColors.neutral600,
      outline: AppColors.neutral300,
      outlineVariant: AppColors.neutral200,
      shadow: AppColors.neutral900.withValues(alpha: 0.1),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,

      // Typography
      textTheme: const TextTheme(
        displayLarge: AppTypography.displayLarge,
        displayMedium: AppTypography.displayMedium,
        displaySmall: AppTypography.displaySmall,
        headlineLarge: AppTypography.headlineLarge,
        headlineMedium: AppTypography.headlineMedium,
        headlineSmall: AppTypography.headlineSmall,
        titleLarge: AppTypography.titleLarge,
        titleMedium: AppTypography.titleMedium,
        titleSmall: AppTypography.titleSmall,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        bodySmall: AppTypography.bodySmall,
        labelLarge: AppTypography.labelLarge,
        labelMedium: AppTypography.labelMedium,
        labelSmall: AppTypography.labelSmall,
      ),

      // Scaffold
      scaffoldBackgroundColor: AppColors.background,

      // AppBar
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: AppElevation.sm,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.neutral900,
        centerTitle: true,
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: AppColors.neutral900,
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        elevation: AppElevation.sm,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        margin: const EdgeInsets.all(AppSpacing.xs),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.neutral50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.neutral300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.neutral300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.neutral600,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.neutral400,
        ),
        errorStyle: AppTypography.bodySmall.copyWith(
          color: AppColors.error,
        ),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: AppElevation.sm,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          textStyle: AppTypography.labelLarge,
          minimumSize: const Size(88, 44), // WCAG 2.1 AA touch target
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          textStyle: AppTypography.labelLarge,
          minimumSize: const Size(88, 44), // WCAG 2.1 AA touch target
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          side: const BorderSide(color: AppColors.primary),
          textStyle: AppTypography.labelLarge,
          minimumSize: const Size(88, 44), // WCAG 2.1 AA touch target
        ),
      ),

      // Icon Button
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(44, 44), // WCAG 2.1 AA touch target
        ),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        elevation: AppElevation.xl,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        titleTextStyle: AppTypography.headlineSmall.copyWith(
          color: AppColors.neutral900,
        ),
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.neutral700,
        ),
      ),

      // Bottom Sheet
      bottomSheetTheme: const BottomSheetThemeData(
        elevation: AppElevation.xl,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: Colors.white,
        ),
      ),

      // Chip
      chipTheme: ChipThemeData(
        elevation: 0,
        pressElevation: AppElevation.xs,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        labelStyle: AppTypography.labelMedium,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.neutral200,
        thickness: 1,
        space: 1,
      ),
    );
  }

  /// Dark theme configuration
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.dark(
      primary: AppColors.primaryLight,
      onPrimary: AppColors.neutral900,
      primaryContainer: AppColors.primaryDark,
      onPrimaryContainer: AppColors.neutral50,
      secondary: AppColors.primaryLight,
      onSecondary: AppColors.neutral900,
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorDark,
      onErrorContainer: AppColors.neutral50,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.neutral50,
      surfaceContainerHighest: AppColors.neutral800,
      onSurfaceVariant: AppColors.neutral400,
      outline: AppColors.neutral600,
      outlineVariant: AppColors.neutral700,
      shadow: Colors.black.withValues(alpha: 0.3),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,

      // Typography (with dark theme colors)
      textTheme: TextTheme(
        displayLarge:
            AppTypography.displayLarge.copyWith(color: AppColors.neutral50),
        displayMedium:
            AppTypography.displayMedium.copyWith(color: AppColors.neutral50),
        displaySmall:
            AppTypography.displaySmall.copyWith(color: AppColors.neutral50),
        headlineLarge:
            AppTypography.headlineLarge.copyWith(color: AppColors.neutral50),
        headlineMedium:
            AppTypography.headlineMedium.copyWith(color: AppColors.neutral50),
        headlineSmall:
            AppTypography.headlineSmall.copyWith(color: AppColors.neutral50),
        titleLarge:
            AppTypography.titleLarge.copyWith(color: AppColors.neutral100),
        titleMedium:
            AppTypography.titleMedium.copyWith(color: AppColors.neutral100),
        titleSmall:
            AppTypography.titleSmall.copyWith(color: AppColors.neutral100),
        bodyLarge:
            AppTypography.bodyLarge.copyWith(color: AppColors.neutral100),
        bodyMedium:
            AppTypography.bodyMedium.copyWith(color: AppColors.neutral100),
        bodySmall:
            AppTypography.bodySmall.copyWith(color: AppColors.neutral200),
        labelLarge:
            AppTypography.labelLarge.copyWith(color: AppColors.neutral100),
        labelMedium:
            AppTypography.labelMedium.copyWith(color: AppColors.neutral100),
        labelSmall:
            AppTypography.labelSmall.copyWith(color: AppColors.neutral200),
      ),

      // Scaffold
      scaffoldBackgroundColor: AppColors.backgroundDark,

      // AppBar
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: AppElevation.sm,
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.neutral50,
        centerTitle: true,
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: AppColors.neutral50,
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        elevation: AppElevation.sm,
        color: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        margin: const EdgeInsets.all(AppSpacing.xs),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.neutral800,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.neutral600),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.neutral600),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.neutral400,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.neutral500,
        ),
        errorStyle: AppTypography.bodySmall.copyWith(
          color: AppColors.error,
        ),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: AppElevation.sm,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          textStyle: AppTypography.labelLarge,
          minimumSize: const Size(88, 44), // WCAG 2.1 AA touch target
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          textStyle: AppTypography.labelLarge,
          minimumSize: const Size(88, 44), // WCAG 2.1 AA touch target
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          side: const BorderSide(color: AppColors.primaryLight),
          textStyle: AppTypography.labelLarge,
          minimumSize: const Size(88, 44), // WCAG 2.1 AA touch target
        ),
      ),

      // Icon Button
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(44, 44), // WCAG 2.1 AA touch target
        ),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        elevation: AppElevation.xl,
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        titleTextStyle: AppTypography.headlineSmall.copyWith(
          color: AppColors.neutral50,
        ),
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.neutral200,
        ),
      ),

      // Bottom Sheet
      bottomSheetTheme: const BottomSheetThemeData(
        elevation: AppElevation.xl,
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.neutral800,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.neutral50,
        ),
      ),

      // Chip
      chipTheme: ChipThemeData(
        elevation: 0,
        pressElevation: AppElevation.xs,
        backgroundColor: AppColors.neutral800,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        labelStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.neutral100,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColors.neutral700,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
