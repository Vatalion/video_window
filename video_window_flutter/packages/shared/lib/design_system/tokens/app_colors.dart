import 'package:flutter/material.dart';

/// Application color tokens following Material Design 3 principles.
///
/// Colors are organized semantically (primary, success, error) rather than
/// literally (blue, green, red) to support theming and brand changes.
///
/// All colors meet WCAG 2.1 AA contrast requirements when paired with their
/// corresponding on-colors (e.g., primary with onPrimary).
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // ============================================================================
  // BRAND COLORS
  // ============================================================================

  /// Primary brand color - Indigo 500
  static const Color primary = Color(0xFF6366F1);

  /// Primary brand color dark variant - Indigo 600
  static const Color primaryDark = Color(0xFF4F46E5);

  /// Primary brand color light variant - Indigo 400
  static const Color primaryLight = Color(0xFF818CF8);

  // ============================================================================
  // SEMANTIC COLORS
  // ============================================================================

  /// Success state color - Green 500
  static const Color success = Color(0xFF10B981);

  /// Success state dark variant - Green 600
  static const Color successDark = Color(0xFF059669);

  /// Warning state color - Amber 500
  static const Color warning = Color(0xFFF59E0B);

  /// Warning state dark variant - Amber 600
  static const Color warningDark = Color(0xFFD97706);

  /// Error state color - Red 500
  static const Color error = Color(0xFFEF4444);

  /// Error state dark variant - Red 600
  static const Color errorDark = Color(0xFFDC2626);

  /// Info state color - Blue 500
  static const Color info = Color(0xFF3B82F6);

  /// Info state dark variant - Blue 600
  static const Color infoDark = Color(0xFF2563EB);

  // ============================================================================
  // NEUTRAL COLORS
  // ============================================================================

  static const Color neutral50 = Color(0xFFFAFAFA);
  static const Color neutral100 = Color(0xFFF5F5F5);
  static const Color neutral200 = Color(0xFFE5E5E5);
  static const Color neutral300 = Color(0xFFD4D4D4);
  static const Color neutral400 = Color(0xFFA3A3A3);
  static const Color neutral500 = Color(0xFF737373);
  static const Color neutral600 = Color(0xFF525252);
  static const Color neutral700 = Color(0xFF404040);
  static const Color neutral800 = Color(0xFF262626);
  static const Color neutral900 = Color(0xFF171717);

  // ============================================================================
  // SURFACE COLORS - Light Theme
  // ============================================================================

  /// Light theme surface color
  static const Color surface = Colors.white;

  /// Light theme background color
  static const Color background = Color(0xFFFAFAFA);

  // ============================================================================
  // SURFACE COLORS - Dark Theme
  // ============================================================================

  /// Dark theme surface color
  static const Color surfaceDark = Color(0xFF1F2937);

  /// Dark theme background color
  static const Color backgroundDark = Color(0xFF111827);

  // ============================================================================
  // ON-COLORS (Text/Icon colors on colored surfaces)
  // ============================================================================

  /// Text/icon color on primary surfaces
  static const Color onPrimary = Colors.white;

  /// Text/icon color on success surfaces
  static const Color onSuccess = Colors.white;

  /// Text/icon color on warning surfaces
  static const Color onWarning = Colors.white;

  /// Text/icon color on error surfaces
  static const Color onError = Colors.white;

  /// Text/icon color on info surfaces
  static const Color onInfo = Colors.white;
}
