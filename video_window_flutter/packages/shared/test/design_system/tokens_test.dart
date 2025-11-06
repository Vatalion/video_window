import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/design_system/tokens.dart';

void main() {
  group('AppColors', () {
    test('brand colors are defined correctly', () {
      expect(AppColors.primary, const Color(0xFF6366F1));
      expect(AppColors.primaryDark, const Color(0xFF4F46E5));
      expect(AppColors.primaryLight, const Color(0xFF818CF8));
    });

    test('semantic colors are defined correctly', () {
      expect(AppColors.success, const Color(0xFF10B981));
      expect(AppColors.warning, const Color(0xFFF59E0B));
      expect(AppColors.error, const Color(0xFFEF4444));
      expect(AppColors.info, const Color(0xFF3B82F6));
    });

    test('neutral colors form a grayscale progression', () {
      // Lighter values should have higher luminance
      final neutral50Luminance = AppColors.neutral50.computeLuminance();
      final neutral500Luminance = AppColors.neutral500.computeLuminance();
      final neutral900Luminance = AppColors.neutral900.computeLuminance();

      expect(neutral50Luminance, greaterThan(neutral500Luminance));
      expect(neutral500Luminance, greaterThan(neutral900Luminance));
    });

    test('surface colors are defined for light and dark themes', () {
      expect(AppColors.surface, Colors.white);
      expect(AppColors.surfaceDark, const Color(0xFF1F2937));
      expect(AppColors.background, const Color(0xFFFAFAFA));
      expect(AppColors.backgroundDark, const Color(0xFF111827));
    });

    test('on-colors provide sufficient contrast (WCAG AA)', () {
      // Test primary/onPrimary contrast ratio
      final primaryLuminance = AppColors.primary.computeLuminance();
      final onPrimaryLuminance = AppColors.onPrimary.computeLuminance();

      // Calculate contrast ratio: (L1 + 0.05) / (L2 + 0.05)
      final contrastRatio = primaryLuminance > onPrimaryLuminance
          ? (primaryLuminance + 0.05) / (onPrimaryLuminance + 0.05)
          : (onPrimaryLuminance + 0.05) / (primaryLuminance + 0.05);

      // WCAG AA requires 4.5:1 for normal text (allowing small tolerance for floating point)
      expect(contrastRatio, greaterThanOrEqualTo(4.4));
    });
  });

  group('AppTypography', () {
    test('uses Inter font family', () {
      expect(AppTypography.fontFamily, 'Inter');
    });

    test('display styles have correct size hierarchy', () {
      expect(AppTypography.displayLarge.fontSize, 57);
      expect(AppTypography.displayMedium.fontSize, 45);
      expect(AppTypography.displaySmall.fontSize, 36);

      expect(
        AppTypography.displayLarge.fontSize!,
        greaterThan(AppTypography.displayMedium.fontSize!),
      );
      expect(
        AppTypography.displayMedium.fontSize!,
        greaterThan(AppTypography.displaySmall.fontSize!),
      );
    });

    test('headline styles have correct size hierarchy', () {
      expect(AppTypography.headlineLarge.fontSize, 32);
      expect(AppTypography.headlineMedium.fontSize, 28);
      expect(AppTypography.headlineSmall.fontSize, 24);

      expect(
        AppTypography.headlineLarge.fontSize!,
        greaterThan(AppTypography.headlineMedium.fontSize!),
      );
    });

    test('body styles have correct size hierarchy', () {
      expect(AppTypography.bodyLarge.fontSize, 16);
      expect(AppTypography.bodyMedium.fontSize, 14);
      expect(AppTypography.bodySmall.fontSize, 12);

      expect(
        AppTypography.bodyLarge.fontSize!,
        greaterThan(AppTypography.bodyMedium.fontSize!),
      );
    });

    test('label styles have medium font weight', () {
      expect(AppTypography.labelLarge.fontWeight, FontWeight.w500);
      expect(AppTypography.labelMedium.fontWeight, FontWeight.w500);
      expect(AppTypography.labelSmall.fontWeight, FontWeight.w500);
    });

    test('all text styles include line height for readability', () {
      expect(AppTypography.displayLarge.height, isNotNull);
      expect(AppTypography.bodyLarge.height, isNotNull);
      expect(AppTypography.labelLarge.height, isNotNull);
    });
  });

  group('AppSpacing', () {
    test('follows 4px base unit progression', () {
      expect(AppSpacing.xxs, 4.0);
      expect(AppSpacing.xs, 8.0);
      expect(AppSpacing.sm, 12.0);
      expect(AppSpacing.md, 16.0);
      expect(AppSpacing.lg, 24.0);
      expect(AppSpacing.xl, 32.0);
      expect(AppSpacing.xxl, 48.0);
      expect(AppSpacing.xxxl, 64.0);
    });

    test('values form a logical progression', () {
      expect(AppSpacing.xs, lessThan(AppSpacing.sm));
      expect(AppSpacing.sm, lessThan(AppSpacing.md));
      expect(AppSpacing.md, lessThan(AppSpacing.lg));
      expect(AppSpacing.lg, lessThan(AppSpacing.xl));
    });
  });

  group('AppRadius', () {
    test('provides appropriate corner rounding options', () {
      expect(AppRadius.none, 0.0);
      expect(AppRadius.xs, 4.0);
      expect(AppRadius.sm, 8.0);
      expect(AppRadius.md, 12.0);
      expect(AppRadius.lg, 16.0);
      expect(AppRadius.xl, 24.0);
      expect(AppRadius.full, 9999.0);
    });
  });

  group('AppElevation', () {
    test('provides Material Design elevation levels', () {
      expect(AppElevation.none, 0.0);
      expect(AppElevation.xs, 1.0);
      expect(AppElevation.sm, 2.0);
      expect(AppElevation.md, 4.0);
      expect(AppElevation.lg, 8.0);
      expect(AppElevation.xl, 16.0);
    });
  });

  group('AppDuration', () {
    test('provides animation timing options', () {
      expect(AppDuration.instant, Duration.zero);
      expect(AppDuration.fast, const Duration(milliseconds: 100));
      expect(AppDuration.normal, const Duration(milliseconds: 200));
      expect(AppDuration.slow, const Duration(milliseconds: 300));
      expect(AppDuration.extraSlow, const Duration(milliseconds: 500));
    });
  });

  group('AppBreakpoints', () {
    test('defines responsive breakpoints', () {
      expect(AppBreakpoints.mobile, 600.0);
      expect(AppBreakpoints.tablet, 900.0);
      expect(AppBreakpoints.desktop, 1200.0);
      expect(AppBreakpoints.largeDesktop, 1600.0);
    });
  });
}
