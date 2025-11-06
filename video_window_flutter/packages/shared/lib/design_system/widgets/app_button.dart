import 'package:flutter/material.dart';
import 'package:shared/design_system/tokens.dart';

/// Button style variants
enum AppButtonVariant {
  /// Filled button with primary color (default)
  primary,

  /// Outlined button with transparent background
  secondary,

  /// Text-only button with no background
  text,

  /// Destructive action button with error color
  destructive,
}

/// Button size variants
enum AppButtonSize {
  /// Small button - compact spacing
  small,

  /// Medium button - standard size (default)
  medium,

  /// Large button - prominent size
  large,
}

/// A customizable button widget that follows the app's design system.
///
/// Provides consistent styling, sizing, and behavior across the application.
/// Automatically meets WCAG 2.1 AA accessibility requirements.
///
/// Example:
/// ```dart
/// AppButton(
///   label: 'Submit',
///   onPressed: () => print('Submitted'),
///   variant: AppButtonVariant.primary,
/// )
/// ```
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
  });

  /// Button label text
  final String label;

  /// Callback when button is pressed. Set to null to disable button.
  final VoidCallback? onPressed;

  /// Visual style variant
  final AppButtonVariant variant;

  /// Button size
  final AppButtonSize size;

  /// Optional leading icon
  final IconData? icon;

  /// Shows loading indicator when true
  final bool isLoading;

  /// Expands button to full width of parent
  final bool isFullWidth;

  EdgeInsets get _padding {
    switch (size) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        );
      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        );
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        );
    }
  }

  Size get _minimumSize {
    switch (size) {
      case AppButtonSize.small:
        return const Size(64, 36);
      case AppButtonSize.medium:
        return const Size(88, 44); // WCAG 2.1 AA minimum
      case AppButtonSize.large:
        return const Size(120, 52);
    }
  }

  TextStyle get _textStyle {
    switch (size) {
      case AppButtonSize.small:
        return AppTypography.labelMedium;
      case AppButtonSize.medium:
        return AppTypography.labelLarge;
      case AppButtonSize.large:
        return AppTypography.titleMedium;
    }
  }

  Widget _buildContent(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        height: _textStyle.fontSize,
        width: _textStyle.fontSize,
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: _textStyle.fontSize! * 1.2),
          const SizedBox(width: AppSpacing.xs),
          Text(label),
        ],
      );
    }

    return Text(label);
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);
    final isDisabled = onPressed == null || isLoading;

    Widget button;

    switch (variant) {
      case AppButtonVariant.primary:
        button = ElevatedButton(
          onPressed: isDisabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            padding: _padding,
            minimumSize: _minimumSize,
            textStyle: _textStyle,
          ),
          child: content,
        );
        break;

      case AppButtonVariant.secondary:
        button = OutlinedButton(
          onPressed: isDisabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            padding: _padding,
            minimumSize: _minimumSize,
            textStyle: _textStyle,
          ),
          child: content,
        );
        break;

      case AppButtonVariant.text:
        button = TextButton(
          onPressed: isDisabled ? null : onPressed,
          style: TextButton.styleFrom(
            padding: _padding,
            minimumSize: _minimumSize,
            textStyle: _textStyle,
          ),
          child: content,
        );
        break;

      case AppButtonVariant.destructive:
        button = ElevatedButton(
          onPressed: isDisabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            padding: _padding,
            minimumSize: _minimumSize,
            textStyle: _textStyle,
            backgroundColor: AppColors.error,
            foregroundColor: AppColors.onError,
          ),
          child: content,
        );
        break;
    }

    if (isFullWidth) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }
}
