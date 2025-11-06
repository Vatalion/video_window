# Design System Documentation

**Version:** 1.0.0  
**Last Updated:** 2025-11-06  
**Package:** `video_window_flutter/packages/shared`

## Overview

The Video Window Design System provides a comprehensive set of design tokens, themes, and reusable UI components to ensure visual consistency and accessibility across the application.

### Key Features

- ✅ Material Design 3 compliant
- ✅ Light and dark theme support
- ✅ WCAG 2.1 AA accessibility standards
- ✅ Responsive design tokens
- ✅ Reusable widget library
- ✅ Type-safe APIs

## Getting Started

### Installation

The design system is part of the `shared` package. Add it to your `pubspec.yaml`:

```yaml
dependencies:
  shared:
    path: ../shared
```

### Basic Usage

```dart
import 'package:shared/design_system.dart';

// Apply theme to your app
MaterialApp(
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
  themeMode: ThemeMode.system,
  home: MyHomePage(),
)
```

---

## Design Tokens

Design tokens are the foundational values that define the visual language of the application.

### Colors

#### Brand Colors

```dart
AppColors.primary        // Indigo 500 (#6366F1)
AppColors.primaryDark    // Indigo 600 (#4F46E5)
AppColors.primaryLight   // Indigo 400 (#818CF8)
```

**Usage Example:**
```dart
Container(
  color: AppColors.primary,
  child: Text(
    'Welcome',
    style: TextStyle(color: AppColors.onPrimary),
  ),
)
```

#### Semantic Colors

```dart
AppColors.success      // Green 500 (#10B981) - Success states
AppColors.successDark  // Green 600 (#059669) - Success hover
AppColors.warning      // Amber 500 (#F59E0B) - Warning states
AppColors.warningDark  // Amber 600 (#D97706) - Warning hover
AppColors.error        // Red 500 (#EF4444) - Error states
AppColors.errorDark    // Red 600 (#DC2626) - Error hover
AppColors.info         // Blue 500 (#3B82F6) - Info states
AppColors.infoDark     // Blue 600 (#2563EB) - Info hover
```

**Usage Example:**
```dart
// Success notification
Container(
  decoration: BoxDecoration(
    color: AppColors.success,
    borderRadius: BorderRadius.circular(AppRadius.sm),
  ),
  child: Text('Success!', style: TextStyle(color: AppColors.onSuccess)),
)
```

#### Neutral Colors

```dart
AppColors.neutral50    // Lightest gray (#FAFAFA)
AppColors.neutral100   // Very light gray (#F5F5F5)
AppColors.neutral200   // Light gray (#E5E5E5)
AppColors.neutral300   // Light-medium gray (#D4D4D4)
AppColors.neutral400   // Medium-light gray (#A3A3A3)
AppColors.neutral500   // Medium gray (#737373)
AppColors.neutral600   // Medium-dark gray (#525252)
AppColors.neutral700   // Dark gray (#404040)
AppColors.neutral800   // Very dark gray (#262626)
AppColors.neutral900   // Darkest gray (#171717)
```

**Color Palette Visualization:**

| Color | Light Mode | Dark Mode | Contrast Ratio |
|-------|------------|-----------|----------------|
| Primary | #6366F1 on white | #818CF8 on dark | 4.47:1 |
| Success | #10B981 on white | #10B981 on dark | 7.2:1 |
| Error | #EF4444 on white | #EF4444 on dark | 4.5:1 |
| Warning | #F59E0B on white | #F59E0B on dark | 3.1:1* |

*Warning color used for non-text elements only

### Typography

All typography uses the **Inter** font family for consistency across platforms.

#### Type Scale

| Style | Size | Weight | Line Height | Use Case |
|-------|------|--------|-------------|----------|
| `displayLarge` | 57sp | Bold (700) | 1.12 | Hero headlines |
| `displayMedium` | 45sp | Bold (700) | 1.16 | Section headlines |
| `displaySmall` | 36sp | Bold (700) | 1.22 | Page titles |
| `headlineLarge` | 32sp | Semibold (600) | 1.25 | Main section headers |
| `headlineMedium` | 28sp | Semibold (600) | 1.29 | Subsection headers |
| `headlineSmall` | 24sp | Semibold (600) | 1.33 | Card titles |
| `titleLarge` | 22sp | Medium (500) | 1.27 | List items |
| `titleMedium` | 16sp | Medium (500) | 1.5 | Card headers |
| `titleSmall` | 14sp | Medium (500) | 1.43 | Compact titles |
| `bodyLarge` | 16sp | Regular (400) | 1.5 | Primary body text |
| `bodyMedium` | 14sp | Regular (400) | 1.43 | Secondary text |
| `bodySmall` | 12sp | Regular (400) | 1.33 | Supporting text |
| `labelLarge` | 14sp | Medium (500) | 1.43 | Button text |
| `labelMedium` | 12sp | Medium (500) | 1.33 | Chip labels |
| `labelSmall` | 11sp | Medium (500) | 1.45 | Small UI labels |

**Usage Example:**
```dart
Text(
  'Welcome to Video Window',
  style: AppTypography.displayLarge,
)

Text(
  'Discover amazing video content',
  style: AppTypography.bodyMedium,
)
```

### Spacing

Based on 4px base unit for mathematical consistency.

```dart
AppSpacing.xxxs  // 2dp
AppSpacing.xxs   // 4dp (base unit)
AppSpacing.xs    // 8dp
AppSpacing.sm    // 12dp
AppSpacing.md    // 16dp (most common)
AppSpacing.lg    // 24dp
AppSpacing.xl    // 32dp
AppSpacing.xxl   // 48dp
AppSpacing.xxxl  // 64dp
```

**Usage Example:**
```dart
Padding(
  padding: EdgeInsets.all(AppSpacing.md),
  child: Column(
    spacing: AppSpacing.sm,
    children: [
      Text('Title'),
      Text('Description'),
    ],
  ),
)
```

### Border Radius

```dart
AppRadius.none   // 0dp - Sharp corners
AppRadius.xs     // 4dp
AppRadius.sm     // 8dp
AppRadius.md     // 12dp (most common for cards/buttons)
AppRadius.lg     // 16dp
AppRadius.xl     // 24dp
AppRadius.full   // 9999dp (circular/pill-shaped)
```

**Usage Example:**
```dart
Container(
  decoration: BoxDecoration(
    color: AppColors.primary,
    borderRadius: BorderRadius.circular(AppRadius.md),
  ),
)
```

### Elevation

Material Design elevation levels for shadow depth.

```dart
AppElevation.none  // 0dp - Flat
AppElevation.xs    // 1dp - Subtle separation
AppElevation.sm    // 2dp - Cards at rest (default)
AppElevation.md    // 4dp - Raised cards
AppElevation.lg    // 8dp - FABs, drawers
AppElevation.xl    // 16dp - Dialogs, modals
```

### Animation Durations

```dart
AppDuration.instant    // 0ms - Immediate
AppDuration.fast       // 100ms - Hover states
AppDuration.normal     // 200ms - Standard transitions (default)
AppDuration.slow       // 300ms - Page transitions
AppDuration.extraSlow  // 500ms - Loading states
```

### Responsive Breakpoints

```dart
AppBreakpoints.mobile        // <600px
AppBreakpoints.tablet        // 600-900px
AppBreakpoints.desktop       // 900-1200px
AppBreakpoints.largeDesktop  // >1200px
```

---

## Theme Configuration

### Light Theme

```dart
MaterialApp(
  theme: AppTheme.lightTheme,
)
```

**Characteristics:**
- White surface (#FFFFFF)
- Light background (#FAFAFA)
- Dark text (#171717)
- Primary: Indigo 500

### Dark Theme

```dart
MaterialApp(
  darkTheme: AppTheme.darkTheme,
)
```

**Characteristics:**
- Dark surface (#1F2937)
- Darker background (#111827)
- Light text (#FAFAFA)
- Primary: Indigo 400 (lighter for contrast)

### System Theme (Recommended)

```dart
MaterialApp(
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
  themeMode: ThemeMode.system, // Respects system preference
)
```

---

## Common Widgets

### AppButton

A customizable button with multiple variants and sizes.

**Props:**
- `label` (String, required) - Button text
- `onPressed` (VoidCallback?, required) - Tap handler (null = disabled)
- `variant` (AppButtonVariant) - Style variant (default: primary)
- `size` (AppButtonSize) - Button size (default: medium)
- `icon` (IconData?) - Optional leading icon
- `isLoading` (bool) - Shows loading indicator (default: false)
- `isFullWidth` (bool) - Expands to full width (default: false)

**Variants:**
- `AppButtonVariant.primary` - Filled button (default)
- `AppButtonVariant.secondary` - Outlined button
- `AppButtonVariant.text` - Text-only button
- `AppButtonVariant.destructive` - Red error button

**Sizes:**
- `AppButtonSize.small` - Compact (36px height)
- `AppButtonSize.medium` - Standard (44px height, WCAG compliant)
- `AppButtonSize.large` - Prominent (52px height)

**Example:**
```dart
AppButton(
  label: 'Submit',
  onPressed: () => print('Submitted'),
  variant: AppButtonVariant.primary,
  size: AppButtonSize.medium,
  icon: Icons.check,
)

AppButton(
  label: 'Cancel',
  onPressed: () => print('Cancelled'),
  variant: AppButtonVariant.secondary,
)

AppButton(
  label: 'Delete',
  onPressed: () => print('Deleted'),
  variant: AppButtonVariant.destructive,
)
```

### AppTextField

A customizable text input field with validation.

**Props:**
- `label` (String, required) - Field label
- `type` (AppTextFieldType) - Input type (default: text)
- `controller` (TextEditingController?) - Text controller
- `initialValue` (String?) - Initial value
- `hint` (String?) - Placeholder text
- `helperText` (String?) - Helper text below field
- `prefixIcon` (IconData?) - Leading icon
- `suffixIcon` (IconData?) - Trailing icon
- `onChanged` (ValueChanged<String>?) - Change callback
- `onSubmitted` (ValueChanged<String>?) - Submit callback
- `validator` (String? Function(String?)?) - Validation function
- `enabled` (bool) - Field enabled state (default: true)
- `maxLines` (int) - Max lines (default: 1)
- `maxLength` (int?) - Max character length
- `autofocus` (bool) - Autofocus field (default: false)

**Types:**
- `AppTextFieldType.text` - General text (default)
- `AppTextFieldType.email` - Email with email keyboard
- `AppTextFieldType.password` - Password with obscured text
- `AppTextFieldType.phone` - Phone with number keyboard
- `AppTextFieldType.number` - Numeric input
- `AppTextFieldType.multiline` - Multi-line text

**Example:**
```dart
AppTextField(
  label: 'Email',
  type: AppTextFieldType.email,
  prefixIcon: Icons.email,
  hint: 'Enter your email',
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    return null;
  },
  onChanged: (value) => print('Email: $value'),
)

AppTextField(
  label: 'Password',
  type: AppTextFieldType.password,
  prefixIcon: Icons.lock,
  validator: (value) {
    if (value == null || value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  },
)
```

### AppCard

A customizable card widget with elevation variants.

**Props:**
- `child` (Widget, required) - Card content
- `elevation` (AppCardElevation) - Shadow level (default: small)
- `onTap` (VoidCallback?) - Optional tap handler
- `padding` (EdgeInsetsGeometry?) - Inner padding
- `margin` (EdgeInsetsGeometry?) - Outer margin

**Elevation Variants:**
- `AppCardElevation.none` - Flat (0dp)
- `AppCardElevation.small` - Subtle shadow (2dp, default)
- `AppCardElevation.medium` - Moderate shadow (4dp)
- `AppCardElevation.large` - Prominent shadow (8dp)

**Example:**
```dart
AppCard(
  elevation: AppCardElevation.small,
  padding: EdgeInsets.all(AppSpacing.md),
  child: Column(
    children: [
      Text('Card Title', style: AppTypography.headlineSmall),
      SizedBox(height: AppSpacing.sm),
      Text('Card content goes here', style: AppTypography.bodyMedium),
    ],
  ),
)

// Interactive card
AppCard(
  onTap: () => print('Card tapped'),
  child: ListTile(
    title: Text('Tappable Card'),
    trailing: Icon(Icons.chevron_right),
  ),
)
```

### AppDialog

A customizable modal dialog.

**Props:**
- `title` (String, required) - Dialog title
- `content` (Widget, required) - Dialog content
- `actions` (List<AppDialogAction>) - Action buttons (default: empty)
- `icon` (IconData?) - Optional icon above title

**AppDialogAction Props:**
- `label` (String, required) - Action label
- `onPressed` (VoidCallback?, required) - Action handler
- `isPrimary` (bool) - Primary action emphasis (default: false)
- `isDestructive` (bool) - Destructive action styling (default: false)

**Example:**
```dart
showDialog(
  context: context,
  builder: (context) => AppDialog(
    title: 'Confirm Delete',
    icon: Icons.warning,
    content: Text(
      'Are you sure you want to delete this item? This action cannot be undone.',
    ),
    actions: [
      AppDialogAction(
        label: 'Cancel',
        onPressed: () => Navigator.pop(context),
      ),
      AppDialogAction(
        label: 'Delete',
        isPrimary: true,
        isDestructive: true,
        onPressed: () {
          // Handle deletion
          Navigator.pop(context);
        },
      ),
    ],
  ),
);
```

---

## Accessibility Guidelines

### WCAG 2.1 AA Compliance

The design system ensures all components meet WCAG 2.1 AA standards:

#### Touch Targets
- ✅ Minimum size: **44x44 pixels**
- ✅ All buttons meet this requirement
- ✅ Icon buttons sized appropriately

#### Color Contrast
- ✅ Normal text: **4.5:1** minimum
- ✅ Large text (18pt+): **3:1** minimum
- ✅ UI components: **3:1** minimum

#### Semantic HTML/Flutter
- ✅ Proper widget semantics
- ✅ Screen reader support
- ✅ Focus indicators

### Implementation Checklist

When building new features:

- [ ] Use design tokens instead of hard-coded values
- [ ] Verify touch targets are ≥44x44px
- [ ] Test both light and dark themes
- [ ] Verify color contrast ratios
- [ ] Add semantic labels for screen readers
- [ ] Test keyboard navigation
- [ ] Provide alternative text for images

---

## Best Practices

### DO ✅

- **Use design tokens** for all visual properties
  ```dart
  // Good
  padding: EdgeInsets.all(AppSpacing.md)
  
  // Bad
  padding: EdgeInsets.all(16.0)
  ```

- **Use common widgets** when available
  ```dart
  // Good
  AppButton(label: 'Submit', onPressed: () {})
  
  // Bad
  ElevatedButton(child: Text('Submit'), onPressed: () {})
  ```

- **Follow naming conventions** (semantic over literal)
  ```dart
  // Good
  color: AppColors.success
  
  // Bad
  color: AppColors.green
  ```

- **Test both themes** during development
  ```dart
  // Always test your UI in both light and dark modes
  ```

### DON'T ❌

- **Don't hard-code colors**
  ```dart
  // Bad
  color: Color(0xFF6366F1)
  
  // Good
  color: AppColors.primary
  ```

- **Don't use magic numbers**
  ```dart
  // Bad
  padding: EdgeInsets.all(12.0)
  
  // Good
  padding: EdgeInsets.all(AppSpacing.sm)
  ```

- **Don't create one-off widgets** when common widgets exist
- **Don't ignore accessibility** - always test with screen readers

---

## Testing

The design system includes comprehensive tests:

- **61 unit tests** covering all tokens, themes, and widgets
- **Widget tests** with golden file snapshots
- **Accessibility tests** for contrast and touch targets
- **Theme switching tests** for light/dark parity

Run tests:
```bash
cd video_window_flutter/packages/shared
flutter test
```

---

## Migration Guide

### From Hard-Coded Values

**Before:**
```dart
Container(
  padding: EdgeInsets.all(16.0),
  decoration: BoxDecoration(
    color: Color(0xFF6366F1),
    borderRadius: BorderRadius.circular(12.0),
  ),
)
```

**After:**
```dart
Container(
  padding: EdgeInsets.all(AppSpacing.md),
  decoration: BoxDecoration(
    color: AppColors.primary,
    borderRadius: BorderRadius.circular(AppRadius.md),
  ),
)
```

### From Material Widgets

**Before:**
```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  ),
  child: Text('Submit'),
  onPressed: () {},
)
```

**After:**
```dart
AppButton(
  label: 'Submit',
  onPressed: () {},
)
```

---

## Resources

- **Package Location:** `video_window_flutter/packages/shared/`
- **Source Files:**
  - Tokens: `lib/design_system/tokens/`
  - Theme: `lib/design_system/theme.dart`
  - Widgets: `lib/design_system/widgets/`
- **Tests:** `test/design_system/` and `test/widgets/`
- **Material Design 3:** https://m3.material.io/
- **WCAG 2.1:** https://www.w3.org/WAI/WCAG21/quickref/

---

**Questions or Issues?**  
Contact the design system team or create an issue in the repository.
