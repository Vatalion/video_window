import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/design_system/theme.dart';
import 'package:shared/design_system/tokens.dart';

void main() {
  group('AppTheme - Light Theme', () {
    late ThemeData lightTheme;

    setUp(() {
      lightTheme = AppTheme.lightTheme;
    });

    test('uses Material 3', () {
      expect(lightTheme.useMaterial3, true);
    });

    test('has correct primary color', () {
      expect(lightTheme.colorScheme.primary, AppColors.primary);
      expect(lightTheme.colorScheme.onPrimary, AppColors.onPrimary);
    });

    test('has correct surface colors', () {
      expect(lightTheme.colorScheme.surface, AppColors.surface);
      expect(lightTheme.colorScheme.onSurface, AppColors.neutral900);
      expect(lightTheme.scaffoldBackgroundColor, AppColors.background);
    });

    test('has correct error colors', () {
      expect(lightTheme.colorScheme.error, AppColors.error);
      expect(lightTheme.colorScheme.onError, AppColors.onError);
    });

    test('configures text theme with all required styles', () {
      expect(lightTheme.textTheme.displayLarge, isNotNull);
      expect(lightTheme.textTheme.headlineMedium, isNotNull);
      expect(lightTheme.textTheme.bodyLarge, isNotNull);
      expect(lightTheme.textTheme.labelLarge, isNotNull);
    });

    test('AppBar theme has no elevation at rest', () {
      expect(lightTheme.appBarTheme.elevation, 0);
      expect(lightTheme.appBarTheme.scrolledUnderElevation, AppElevation.sm);
    });

    test('Card theme has proper elevation and shape', () {
      expect(lightTheme.cardTheme.elevation, AppElevation.sm);
      expect(lightTheme.cardTheme.shape, isA<RoundedRectangleBorder>());
    });

    test('Input decoration theme has proper styling', () {
      expect(lightTheme.inputDecorationTheme.filled, true);
      expect(lightTheme.inputDecorationTheme.fillColor, AppColors.neutral50);
      expect(lightTheme.inputDecorationTheme.border, isA<OutlineInputBorder>());
    });

    test('Button themes meet WCAG AA touch target size (44x44)', () {
      final elevatedMinSize = lightTheme.elevatedButtonTheme.style?.minimumSize;
      expect(elevatedMinSize, isNotNull);
      expect(
        elevatedMinSize!.resolve({}),
        const Size(88, 44), // Width can be more, height must be 44
      );

      final textMinSize = lightTheme.textButtonTheme.style?.minimumSize;
      expect(textMinSize, isNotNull);
      expect(
        textMinSize!.resolve({}),
        const Size(88, 44),
      );

      final outlinedMinSize = lightTheme.outlinedButtonTheme.style?.minimumSize;
      expect(outlinedMinSize, isNotNull);
      expect(
        outlinedMinSize!.resolve({}),
        const Size(88, 44),
      );
    });

    test('Icon button meets WCAG AA touch target size (44x44)', () {
      final iconMinSize = lightTheme.iconButtonTheme.style?.minimumSize;
      expect(iconMinSize, isNotNull);
      expect(
        iconMinSize!.resolve({}),
        const Size(44, 44),
      );
    });

    test('Dialog theme has proper elevation', () {
      expect(lightTheme.dialogTheme.elevation, AppElevation.xl);
      expect(lightTheme.dialogTheme.shape, isA<RoundedRectangleBorder>());
    });
  });

  group('AppTheme - Dark Theme', () {
    late ThemeData darkTheme;

    setUp(() {
      darkTheme = AppTheme.darkTheme;
    });

    test('uses Material 3', () {
      expect(darkTheme.useMaterial3, true);
    });

    test('has correct primary color (lighter variant for dark mode)', () {
      expect(darkTheme.colorScheme.primary, AppColors.primaryLight);
      expect(darkTheme.colorScheme.onPrimary, AppColors.neutral900);
    });

    test('has correct dark surface colors', () {
      expect(darkTheme.colorScheme.surface, AppColors.surfaceDark);
      expect(darkTheme.colorScheme.onSurface, AppColors.neutral50);
      expect(darkTheme.scaffoldBackgroundColor, AppColors.backgroundDark);
    });

    test('text theme colors are adjusted for dark mode', () {
      final displayStyle = darkTheme.textTheme.displayLarge;
      expect(displayStyle?.color, AppColors.neutral50);

      final bodyStyle = darkTheme.textTheme.bodyMedium;
      expect(bodyStyle?.color, AppColors.neutral100);
    });

    test('Input decoration theme uses dark colors', () {
      expect(darkTheme.inputDecorationTheme.filled, true);
      expect(darkTheme.inputDecorationTheme.fillColor, AppColors.neutral800);
    });

    test('Dialog theme has dark background', () {
      expect(darkTheme.dialogTheme.backgroundColor, AppColors.surfaceDark);
    });

    test('Button themes meet WCAG AA touch target size in dark mode', () {
      final elevatedMinSize = darkTheme.elevatedButtonTheme.style?.minimumSize;
      expect(elevatedMinSize, isNotNull);
      expect(
        elevatedMinSize!.resolve({}),
        const Size(88, 44),
      );
    });
  });

  group('AppTheme - Light/Dark Parity', () {
    test('both themes use same text sizes', () {
      final lightTheme = AppTheme.lightTheme;
      final darkTheme = AppTheme.darkTheme;

      expect(
        lightTheme.textTheme.displayLarge?.fontSize,
        darkTheme.textTheme.displayLarge?.fontSize,
      );

      expect(
        lightTheme.textTheme.bodyLarge?.fontSize,
        darkTheme.textTheme.bodyLarge?.fontSize,
      );

      expect(
        lightTheme.textTheme.labelLarge?.fontSize,
        darkTheme.textTheme.labelLarge?.fontSize,
      );
    });

    test('both themes have consistent spacing', () {
      final lightTheme = AppTheme.lightTheme;
      final darkTheme = AppTheme.darkTheme;

      expect(
        lightTheme.cardTheme.margin,
        darkTheme.cardTheme.margin,
      );

      expect(
        lightTheme.inputDecorationTheme.contentPadding,
        darkTheme.inputDecorationTheme.contentPadding,
      );
    });

    test('both themes have same elevation values', () {
      final lightTheme = AppTheme.lightTheme;
      final darkTheme = AppTheme.darkTheme;

      expect(
        lightTheme.cardTheme.elevation,
        darkTheme.cardTheme.elevation,
      );

      expect(
        lightTheme.dialogTheme.elevation,
        darkTheme.dialogTheme.elevation,
      );
    });
  });
}
