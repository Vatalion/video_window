import 'package:flutter/material.dart';
import 'package:shared/design_system/tokens.dart';

/// Card elevation variants
enum AppCardElevation {
  /// No elevation - flat card
  none,

  /// Small elevation - subtle shadow (default)
  small,

  /// Medium elevation - moderate shadow
  medium,

  /// Large elevation - prominent shadow
  large,
}

/// A customizable card widget that follows the app's design system.
///
/// Provides consistent styling and elevation across the application.
///
/// Example:
/// ```dart
/// AppCard(
///   child: Padding(
///     padding: EdgeInsets.all(AppSpacing.md),
///     child: Text('Card content'),
///   ),
/// )
/// ```
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.elevation = AppCardElevation.small,
    this.onTap,
    this.padding,
    this.margin,
  });

  /// Card content
  final Widget child;

  /// Shadow elevation level
  final AppCardElevation elevation;

  /// Optional tap callback (makes card interactive)
  final VoidCallback? onTap;

  /// Inner padding (null uses default spacing)
  final EdgeInsetsGeometry? padding;

  /// Outer margin (null uses default spacing)
  final EdgeInsetsGeometry? margin;

  double get _elevationValue {
    switch (elevation) {
      case AppCardElevation.none:
        return AppElevation.none;
      case AppCardElevation.small:
        return AppElevation.sm;
      case AppCardElevation.medium:
        return AppElevation.md;
      case AppCardElevation.large:
        return AppElevation.lg;
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = Card(
      elevation: _elevationValue,
      margin: margin ?? const EdgeInsets.all(AppSpacing.xs),
      child: padding != null ? Padding(padding: padding!, child: child) : child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: card,
      );
    }

    return card;
  }
}
