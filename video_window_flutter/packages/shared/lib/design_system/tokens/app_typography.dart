import 'package:flutter/material.dart';

/// Application typography tokens following Material Design 3 type scale.
///
/// Uses the Inter font family for consistency across platforms.
/// All text styles include appropriate line height and letter spacing
/// for optimal readability.
///
/// Type Scale: Display → Headline → Body → Label
class AppTypography {
  AppTypography._(); // Private constructor to prevent instantiation

  /// Font family used throughout the application
  static const String fontFamily = 'Inter';

  // ============================================================================
  // DISPLAY STYLES - Used for large, impactful text
  // ============================================================================

  /// Display Large - 57sp
  /// Use for: Hero headlines, landing page titles
  static const TextStyle displayLarge = TextStyle(
    fontSize: 57,
    fontWeight: FontWeight.w700,
    height: 1.12,
    letterSpacing: -0.25,
    fontFamily: fontFamily,
  );

  /// Display Medium - 45sp
  /// Use for: Section headlines, featured content
  static const TextStyle displayMedium = TextStyle(
    fontSize: 45,
    fontWeight: FontWeight.w700,
    height: 1.16,
    fontFamily: fontFamily,
  );

  /// Display Small - 36sp
  /// Use for: Page titles, primary headlines
  static const TextStyle displaySmall = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 1.22,
    fontFamily: fontFamily,
  );

  // ============================================================================
  // HEADLINE STYLES - Used for section headers and titles
  // ============================================================================

  /// Headline Large - 32sp
  /// Use for: Main section headers
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    height: 1.25,
    fontFamily: fontFamily,
  );

  /// Headline Medium - 28sp
  /// Use for: Subsection headers, dialog titles
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.29,
    fontFamily: fontFamily,
  );

  /// Headline Small - 24sp
  /// Use for: Card titles, list section headers
  static const TextStyle headlineSmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.33,
    fontFamily: fontFamily,
  );

  // ============================================================================
  // TITLE STYLES - Used for emphasized body content
  // ============================================================================

  /// Title Large - 22sp
  /// Use for: Prominent list items, emphasized content
  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w500,
    height: 1.27,
    fontFamily: fontFamily,
  );

  /// Title Medium - 16sp
  /// Use for: List item titles, card headers
  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 0.15,
    fontFamily: fontFamily,
  );

  /// Title Small - 14sp
  /// Use for: Compact list items, secondary titles
  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.43,
    letterSpacing: 0.1,
    fontFamily: fontFamily,
  );

  // ============================================================================
  // BODY STYLES - Used for primary reading content
  // ============================================================================

  /// Body Large - 16sp
  /// Use for: Primary body text, descriptions
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.15,
    fontFamily: fontFamily,
  );

  /// Body Medium - 14sp
  /// Use for: Secondary body text, captions
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.43,
    letterSpacing: 0.25,
    fontFamily: fontFamily,
  );

  /// Body Small - 12sp
  /// Use for: Supporting text, metadata
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.33,
    letterSpacing: 0.4,
    fontFamily: fontFamily,
  );

  // ============================================================================
  // LABEL STYLES - Used for buttons, tabs, and UI elements
  // ============================================================================

  /// Label Large - 14sp
  /// Use for: Button text, tab labels
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.43,
    letterSpacing: 0.1,
    fontFamily: fontFamily,
  );

  /// Label Medium - 12sp
  /// Use for: Small button text, chip labels
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.33,
    letterSpacing: 0.5,
    fontFamily: fontFamily,
  );

  /// Label Small - 11sp
  /// Use for: Smallest UI labels, overlines
  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.45,
    letterSpacing: 0.5,
    fontFamily: fontFamily,
  );
}
