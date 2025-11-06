/// Application spacing tokens for consistent layout spacing.
///
/// Based on 4px base unit for mathematical consistency.
/// Use these constants for padding, margins, and gaps throughout the app.
class AppSpacing {
  AppSpacing._(); // Private constructor to prevent instantiation

  /// Extra extra extra small - 2dp
  static const double xxxs = 2.0;

  /// Extra extra small - 4dp (base unit)
  static const double xxs = 4.0;

  /// Extra small - 8dp
  static const double xs = 8.0;

  /// Small - 12dp
  static const double sm = 12.0;

  /// Medium - 16dp (most common spacing)
  static const double md = 16.0;

  /// Large - 24dp
  static const double lg = 24.0;

  /// Extra large - 32dp
  static const double xl = 32.0;

  /// Extra extra large - 48dp
  static const double xxl = 48.0;

  /// Extra extra extra large - 64dp
  static const double xxxl = 64.0;
}

/// Application border radius tokens for consistent corner rounding.
///
/// Provides a scale from sharp corners to fully rounded.
class AppRadius {
  AppRadius._(); // Private constructor to prevent instantiation

  /// No border radius - 0dp
  static const double none = 0.0;

  /// Extra small radius - 4dp
  static const double xs = 4.0;

  /// Small radius - 8dp
  static const double sm = 8.0;

  /// Medium radius - 12dp (most common for cards/buttons)
  static const double md = 12.0;

  /// Large radius - 16dp
  static const double lg = 16.0;

  /// Extra large radius - 24dp
  static const double xl = 24.0;

  /// Fully rounded - 9999dp
  /// Use for circular elements (avatars, pills)
  static const double full = 9999.0;
}

/// Application elevation tokens for consistent shadow depth.
///
/// Based on Material Design elevation scale.
/// Higher elevations create stronger shadows and visual hierarchy.
class AppElevation {
  AppElevation._(); // Private constructor to prevent instantiation

  /// No elevation - 0dp
  static const double none = 0.0;

  /// Extra small elevation - 1dp
  /// Use for: Subtle separation
  static const double xs = 1.0;

  /// Small elevation - 2dp
  /// Use for: Cards at rest, input fields
  static const double sm = 2.0;

  /// Medium elevation - 4dp
  /// Use for: Raised cards, hovering elements
  static const double md = 4.0;

  /// Large elevation - 8dp
  /// Use for: Floating action buttons, drawers
  static const double lg = 8.0;

  /// Extra large elevation - 16dp
  /// Use for: Dialogs, modals
  static const double xl = 16.0;
}

/// Application duration tokens for consistent animations.
///
/// Based on Material Design motion guidelines.
class AppDuration {
  AppDuration._(); // Private constructor to prevent instantiation

  /// Instant - 0ms
  /// Use for: Immediate state changes
  static const Duration instant = Duration.zero;

  /// Fast - 100ms
  /// Use for: Simple transitions, hover states
  static const Duration fast = Duration(milliseconds: 100);

  /// Normal - 200ms
  /// Use for: Most transitions and animations
  static const Duration normal = Duration(milliseconds: 200);

  /// Slow - 300ms
  /// Use for: Complex animations, page transitions
  static const Duration slow = Duration(milliseconds: 300);

  /// Extra slow - 500ms
  /// Use for: Emphasized transitions, loading states
  static const Duration extraSlow = Duration(milliseconds: 500);
}

/// Application breakpoint tokens for responsive design.
///
/// Based on common device sizes.
class AppBreakpoints {
  AppBreakpoints._(); // Private constructor to prevent instantiation

  /// Mobile portrait - <600px
  static const double mobile = 600.0;

  /// Tablet portrait - 600px-900px
  static const double tablet = 900.0;

  /// Desktop - >900px
  static const double desktop = 1200.0;

  /// Large desktop - >1200px
  static const double largeDesktop = 1600.0;
}
