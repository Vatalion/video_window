/// Design System for the Video Window app.
///
/// This library provides the complete design system including:
/// - Design tokens (colors, typography, spacing, etc.)
/// - Theme configuration (light and dark modes)
/// - Common widgets (buttons, text fields, cards, dialogs)
///
/// ## Usage
///
/// Import the design system in your app:
/// ```dart
/// import 'package:shared/design_system.dart';
/// ```
///
/// Apply theme to MaterialApp:
/// ```dart
/// MaterialApp(
///   theme: AppTheme.lightTheme,
///   darkTheme: AppTheme.darkTheme,
///   themeMode: ThemeMode.system,
/// )
/// ```
///
/// Use design tokens:
/// ```dart
/// Container(
///   padding: EdgeInsets.all(AppSpacing.md),
///   decoration: BoxDecoration(
///     color: AppColors.primary,
///     borderRadius: BorderRadius.circular(AppRadius.md),
///   ),
/// )
/// ```
///
/// Use common widgets:
/// ```dart
/// AppButton(
///   label: 'Submit',
///   onPressed: () => print('Submitted'),
/// )
/// ```
library;

export 'design_system/theme.dart';
export 'design_system/tokens.dart';
export 'design_system/widgets.dart';
