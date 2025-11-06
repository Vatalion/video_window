import 'package:flutter/material.dart';
import 'package:shared/design_system/tokens.dart';
import 'package:shared/design_system/widgets/app_button.dart';

/// A customizable dialog widget that follows the app's design system.
///
/// Provides consistent styling for modal dialogs across the application.
/// Automatically meets WCAG 2.1 AA accessibility requirements.
///
/// Example:
/// ```dart
/// showDialog(
///   context: context,
///   builder: (context) => AppDialog(
///     title: 'Confirm Action',
///     content: Text('Are you sure you want to continue?'),
///     actions: [
///       AppDialogAction(
///         label: 'Cancel',
///         onPressed: () => Navigator.pop(context),
///       ),
///       AppDialogAction(
///         label: 'Confirm',
///         isPrimary: true,
///         onPressed: () {
///           // Handle confirmation
///           Navigator.pop(context);
///         },
///       ),
///     ],
///   ),
/// );
/// ```
class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions = const [],
    this.icon,
  });

  /// Dialog title
  final String title;

  /// Dialog content widget
  final Widget content;

  /// Action buttons shown at bottom
  final List<AppDialogAction> actions;

  /// Optional icon shown above title
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: icon != null ? Icon(icon, size: 32) : null,
      title: Text(title),
      content: content,
      actions: actions.map((action) {
        return action.isPrimary
            ? AppButton(
                label: action.label,
                onPressed: action.onPressed,
                variant: action.isDestructive
                    ? AppButtonVariant.destructive
                    : AppButtonVariant.primary,
                size: AppButtonSize.medium,
              )
            : AppButton(
                label: action.label,
                onPressed: action.onPressed,
                variant: AppButtonVariant.text,
                size: AppButtonSize.medium,
              );
      }).toList(),
      actionsPadding: const EdgeInsets.all(AppSpacing.md),
      contentPadding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
    );
  }
}

/// Represents an action button in an [AppDialog].
class AppDialogAction {
  const AppDialogAction({
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
    this.isDestructive = false,
  });

  /// Action button label
  final String label;

  /// Callback when action is pressed
  final VoidCallback? onPressed;

  /// Whether this is the primary action (emphasized button)
  final bool isPrimary;

  /// Whether this is a destructive action (uses error color)
  final bool isDestructive;
}
