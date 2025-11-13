import 'package:flutter/material.dart';
import 'package:shared/design_system.dart';

/// Design Catalog - Visual demonstration of all design system components.
///
/// This page showcases:
/// - All design tokens (colors, typography, spacing)
/// - All common widgets with interactive examples
/// - Light/Dark theme switching
class DesignCatalogPage extends StatefulWidget {
  const DesignCatalogPage({super.key});

  @override
  State<DesignCatalogPage> createState() => _DesignCatalogPageState();
}

class _DesignCatalogPageState extends State<DesignCatalogPage> {
  int _selectedIndex = 0;

  final List<_CatalogSection> _sections = [
    _CatalogSection(
      title: 'Colors',
      icon: Icons.palette,
      builder: (context) => const _ColorsSection(),
    ),
    _CatalogSection(
      title: 'Typography',
      icon: Icons.text_fields,
      builder: (context) => const _TypographySection(),
    ),
    _CatalogSection(
      title: 'Spacing & Layout',
      icon: Icons.space_bar,
      builder: (context) => const _SpacingSection(),
    ),
    _CatalogSection(
      title: 'Buttons',
      icon: Icons.smart_button,
      builder: (context) => const _ButtonsSection(),
    ),
    _CatalogSection(
      title: 'Text Fields',
      icon: Icons.input,
      builder: (context) => const _TextFieldsSection(),
    ),
    _CatalogSection(
      title: 'Cards & Dialogs',
      icon: Icons.card_membership,
      builder: (context) => const _CardsDialogsSection(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Design System Catalog'),
        actions: [
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            tooltip: 'Toggle theme',
            onPressed: () {
              // Theme switching will be implemented via app-level state
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Theme switching requires app-level implementation',
                  ),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // Navigation Rail
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: _sections
                .map(
                  (section) => NavigationRailDestination(
                    icon: Icon(section.icon),
                    label: Text(section.title),
                  ),
                )
                .toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // Content
          Expanded(
            child: _sections[_selectedIndex].builder(context),
          ),
        ],
      ),
    );
  }
}

class _CatalogSection {
  final String title;
  final IconData icon;
  final Widget Function(BuildContext) builder;

  _CatalogSection({
    required this.title,
    required this.icon,
    required this.builder,
  });
}

// ============================================================================
// COLORS SECTION
// ============================================================================

class _ColorsSection extends StatelessWidget {
  const _ColorsSection();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: const [
        Text('Brand Colors', style: AppTypography.headlineMedium),
        SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            _ColorSwatch(
              color: AppColors.primary,
              name: 'Primary',
              hex: '#6366F1',
            ),
            _ColorSwatch(
              color: AppColors.primaryDark,
              name: 'Primary Dark',
              hex: '#4F46E5',
            ),
            _ColorSwatch(
              color: AppColors.primaryLight,
              name: 'Primary Light',
              hex: '#818CF8',
            ),
          ],
        ),
        SizedBox(height: AppSpacing.xl),
        Text('Semantic Colors', style: AppTypography.headlineMedium),
        SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            _ColorSwatch(
              color: AppColors.success,
              name: 'Success',
              hex: '#10B981',
            ),
            _ColorSwatch(
              color: AppColors.warning,
              name: 'Warning',
              hex: '#F59E0B',
            ),
            _ColorSwatch(
              color: AppColors.error,
              name: 'Error',
              hex: '#EF4444',
            ),
            _ColorSwatch(
              color: AppColors.info,
              name: 'Info',
              hex: '#3B82F6',
            ),
          ],
        ),
        SizedBox(height: AppSpacing.xl),
        Text('Neutral Colors', style: AppTypography.headlineMedium),
        SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            _ColorSwatch(
              color: AppColors.neutral50,
              name: 'Neutral 50',
              hex: '#FAFAFA',
            ),
            _ColorSwatch(
              color: AppColors.neutral100,
              name: 'Neutral 100',
              hex: '#F5F5F5',
            ),
            _ColorSwatch(
              color: AppColors.neutral200,
              name: 'Neutral 200',
              hex: '#E5E5E5',
            ),
            _ColorSwatch(
              color: AppColors.neutral300,
              name: 'Neutral 300',
              hex: '#D4D4D4',
            ),
            _ColorSwatch(
              color: AppColors.neutral400,
              name: 'Neutral 400',
              hex: '#A3A3A3',
            ),
            _ColorSwatch(
              color: AppColors.neutral500,
              name: 'Neutral 500',
              hex: '#737373',
            ),
            _ColorSwatch(
              color: AppColors.neutral600,
              name: 'Neutral 600',
              hex: '#525252',
            ),
            _ColorSwatch(
              color: AppColors.neutral700,
              name: 'Neutral 700',
              hex: '#404040',
            ),
            _ColorSwatch(
              color: AppColors.neutral800,
              name: 'Neutral 800',
              hex: '#262626',
            ),
            _ColorSwatch(
              color: AppColors.neutral900,
              name: 'Neutral 900',
              hex: '#171717',
            ),
          ],
        ),
      ],
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final Color color;
  final String name;
  final String hex;

  const _ColorSwatch({
    required this.color,
    required this.name,
    required this.hex,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 120,
            height: 80,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.neutral200),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(name, style: AppTypography.labelMedium),
          Text(
            hex,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.neutral500,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// TYPOGRAPHY SECTION
// ============================================================================

class _TypographySection extends StatelessWidget {
  const _TypographySection();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: const [
        Text('Display Styles', style: AppTypography.headlineMedium),
        SizedBox(height: AppSpacing.md),
        _TypeSample(
          style: AppTypography.displayLarge,
          label: 'Display Large',
          description: '57sp · Bold',
        ),
        _TypeSample(
          style: AppTypography.displayMedium,
          label: 'Display Medium',
          description: '45sp · Bold',
        ),
        _TypeSample(
          style: AppTypography.displaySmall,
          label: 'Display Small',
          description: '36sp · Bold',
        ),
        SizedBox(height: AppSpacing.xl),
        Text('Headline Styles', style: AppTypography.headlineMedium),
        SizedBox(height: AppSpacing.md),
        _TypeSample(
          style: AppTypography.headlineLarge,
          label: 'Headline Large',
          description: '32sp · Semibold',
        ),
        _TypeSample(
          style: AppTypography.headlineMedium,
          label: 'Headline Medium',
          description: '28sp · Semibold',
        ),
        _TypeSample(
          style: AppTypography.headlineSmall,
          label: 'Headline Small',
          description: '24sp · Semibold',
        ),
        SizedBox(height: AppSpacing.xl),
        Text('Body Styles', style: AppTypography.headlineMedium),
        SizedBox(height: AppSpacing.md),
        _TypeSample(
          style: AppTypography.bodyLarge,
          label: 'Body Large',
          description: '16sp · Regular',
        ),
        _TypeSample(
          style: AppTypography.bodyMedium,
          label: 'Body Medium',
          description: '14sp · Regular',
        ),
        _TypeSample(
          style: AppTypography.bodySmall,
          label: 'Body Small',
          description: '12sp · Regular',
        ),
        SizedBox(height: AppSpacing.xl),
        Text('Label Styles', style: AppTypography.headlineMedium),
        SizedBox(height: AppSpacing.md),
        _TypeSample(
          style: AppTypography.labelLarge,
          label: 'Label Large',
          description: '14sp · Medium',
        ),
        _TypeSample(
          style: AppTypography.labelMedium,
          label: 'Label Medium',
          description: '12sp · Medium',
        ),
        _TypeSample(
          style: AppTypography.labelSmall,
          label: 'Label Small',
          description: '11sp · Medium',
        ),
      ],
    );
  }
}

class _TypeSample extends StatelessWidget {
  final TextStyle style;
  final String label;
  final String description;

  const _TypeSample({
    required this.style,
    required this.label,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: style),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            description,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.neutral500,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SPACING SECTION
// ============================================================================

class _SpacingSection extends StatelessWidget {
  const _SpacingSection();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: const [
        Text('Spacing Scale', style: AppTypography.headlineMedium),
        SizedBox(height: AppSpacing.md),
        _SpacingSample(size: AppSpacing.xxxs, label: 'xxxs', value: '2dp'),
        _SpacingSample(size: AppSpacing.xxs, label: 'xxs', value: '4dp'),
        _SpacingSample(size: AppSpacing.xs, label: 'xs', value: '8dp'),
        _SpacingSample(size: AppSpacing.sm, label: 'sm', value: '12dp'),
        _SpacingSample(size: AppSpacing.md, label: 'md', value: '16dp'),
        _SpacingSample(size: AppSpacing.lg, label: 'lg', value: '24dp'),
        _SpacingSample(size: AppSpacing.xl, label: 'xl', value: '32dp'),
        _SpacingSample(size: AppSpacing.xxl, label: 'xxl', value: '48dp'),
        _SpacingSample(size: AppSpacing.xxxl, label: 'xxxl', value: '64dp'),
        SizedBox(height: AppSpacing.xl),
        Text('Border Radius', style: AppTypography.headlineMedium),
        SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            _RadiusSample(radius: AppRadius.none, label: 'none (0dp)'),
            _RadiusSample(radius: AppRadius.xs, label: 'xs (4dp)'),
            _RadiusSample(radius: AppRadius.sm, label: 'sm (8dp)'),
            _RadiusSample(radius: AppRadius.md, label: 'md (12dp)'),
            _RadiusSample(radius: AppRadius.lg, label: 'lg (16dp)'),
            _RadiusSample(radius: AppRadius.xl, label: 'xl (24dp)'),
          ],
        ),
        SizedBox(height: AppSpacing.xl),
        Text('Elevation', style: AppTypography.headlineMedium),
        SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            _ElevationSample(elevation: AppElevation.none, label: 'none (0dp)'),
            _ElevationSample(elevation: AppElevation.xs, label: 'xs (1dp)'),
            _ElevationSample(elevation: AppElevation.sm, label: 'sm (2dp)'),
            _ElevationSample(elevation: AppElevation.md, label: 'md (4dp)'),
            _ElevationSample(elevation: AppElevation.lg, label: 'lg (8dp)'),
            _ElevationSample(elevation: AppElevation.xl, label: 'xl (16dp)'),
          ],
        ),
      ],
    );
  }
}

class _SpacingSample extends StatelessWidget {
  final double size;
  final String label;
  final String value;

  const _SpacingSample({
    required this.size,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text('$label ($value)', style: AppTypography.bodyMedium),
          ),
          Container(
            width: size,
            height: 24,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _RadiusSample extends StatelessWidget {
  final double radius;
  final String label;

  const _RadiusSample({
    required this.radius,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(label, style: AppTypography.labelSmall),
      ],
    );
  }
}

class _ElevationSample extends StatelessWidget {
  final double elevation;
  final String label;

  const _ElevationSample({
    required this.elevation,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          elevation: elevation,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(label, style: AppTypography.labelSmall),
      ],
    );
  }
}

// ============================================================================
// BUTTONS SECTION
// ============================================================================

class _ButtonsSection extends StatefulWidget {
  const _ButtonsSection();

  @override
  State<_ButtonsSection> createState() => _ButtonsSectionState();
}

class _ButtonsSectionState extends State<_ButtonsSection> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const Text('Button Variants', style: AppTypography.headlineMedium),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            AppButton(
              label: 'Primary',
              onPressed: () {},
              variant: AppButtonVariant.primary,
            ),
            AppButton(
              label: 'Secondary',
              onPressed: () {},
              variant: AppButtonVariant.secondary,
            ),
            AppButton(
              label: 'Text',
              onPressed: () {},
              variant: AppButtonVariant.text,
            ),
            AppButton(
              label: 'Destructive',
              onPressed: () {},
              variant: AppButtonVariant.destructive,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        const Text('Button Sizes', style: AppTypography.headlineMedium),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AppButton(
              label: 'Small',
              onPressed: () {},
              size: AppButtonSize.small,
            ),
            AppButton(
              label: 'Medium',
              onPressed: () {},
              size: AppButtonSize.medium,
            ),
            AppButton(
              label: 'Large',
              onPressed: () {},
              size: AppButtonSize.large,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        const Text('Button States', style: AppTypography.headlineMedium),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            AppButton(
              label: 'With Icon',
              onPressed: () {},
              icon: Icons.add,
            ),
            AppButton(
              label: 'Loading',
              onPressed: () {},
              isLoading: _isLoading,
            ),
            const AppButton(
              label: 'Disabled',
              onPressed: null,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: 'Full Width',
          onPressed: () {
            setState(() {
              _isLoading = !_isLoading;
            });
          },
          isFullWidth: true,
        ),
      ],
    );
  }
}

// ============================================================================
// TEXT FIELDS SECTION
// ============================================================================

class _TextFieldsSection extends StatelessWidget {
  const _TextFieldsSection();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const Text('Text Field Types', style: AppTypography.headlineMedium),
        const SizedBox(height: AppSpacing.md),
        const AppTextField(
          label: 'Text Input',
          type: AppTextFieldType.text,
          hint: 'Enter text here',
        ),
        const SizedBox(height: AppSpacing.md),
        const AppTextField(
          label: 'Email',
          type: AppTextFieldType.email,
          prefixIcon: Icons.email,
          hint: 'email@example.com',
        ),
        const SizedBox(height: AppSpacing.md),
        const AppTextField(
          label: 'Password',
          type: AppTextFieldType.password,
          prefixIcon: Icons.lock,
        ),
        const SizedBox(height: AppSpacing.md),
        const AppTextField(
          label: 'Phone',
          type: AppTextFieldType.phone,
          prefixIcon: Icons.phone,
          hint: '(555) 123-4567',
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          label: 'With Validation',
          hint: 'This field is required',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'This field cannot be empty';
            }
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.md),
        const AppTextField(
          label: 'Multiline',
          type: AppTextFieldType.multiline,
          maxLines: 4,
          hint: 'Enter multiple lines of text...',
        ),
        const SizedBox(height: AppSpacing.md),
        const AppTextField(
          label: 'Disabled',
          enabled: false,
          initialValue: 'This field is disabled',
        ),
      ],
    );
  }
}

// ============================================================================
// CARDS & DIALOGS SECTION
// ============================================================================

class _CardsDialogsSection extends StatelessWidget {
  const _CardsDialogsSection();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const Text('Card Elevations', style: AppTypography.headlineMedium),
        const SizedBox(height: AppSpacing.md),
        const AppCard(
          elevation: AppCardElevation.none,
          padding: EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('None Elevation', style: AppTypography.titleMedium),
              SizedBox(height: AppSpacing.xs),
              Text(
                'Flat card with no shadow',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const AppCard(
          elevation: AppCardElevation.small,
          padding: EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Small Elevation', style: AppTypography.titleMedium),
              SizedBox(height: AppSpacing.xs),
              Text(
                'Subtle shadow (default)',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const AppCard(
          elevation: AppCardElevation.medium,
          padding: EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Medium Elevation', style: AppTypography.titleMedium),
              SizedBox(height: AppSpacing.xs),
              Text(
                'Moderate shadow for raised cards',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const AppCard(
          elevation: AppCardElevation.large,
          padding: EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Large Elevation', style: AppTypography.titleMedium),
              SizedBox(height: AppSpacing.xs),
              Text(
                'Prominent shadow for emphasis',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          elevation: AppCardElevation.small,
          padding: const EdgeInsets.all(AppSpacing.md),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Interactive card tapped!')),
            );
          },
          child: const Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Interactive Card', style: AppTypography.titleMedium),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      'Tap me to see interaction',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(Icons.touch_app),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const Text('Dialogs', style: AppTypography.headlineMedium),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: 'Show Confirmation Dialog',
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AppDialog(
                title: 'Confirm Action',
                icon: Icons.warning,
                content: const Text(
                  'Are you sure you want to perform this action? This cannot be undone.',
                ),
                actions: [
                  AppDialogAction(
                    label: 'Cancel',
                    onPressed: () => Navigator.pop(context),
                  ),
                  AppDialogAction(
                    label: 'Confirm',
                    isPrimary: true,
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Action confirmed!')),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: 'Show Destructive Dialog',
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AppDialog(
                title: 'Delete Item',
                icon: Icons.delete,
                content: const Text(
                  'This will permanently delete the item. Are you sure?',
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
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Item deleted!')),
                      );
                    },
                  ),
                ],
              ),
            );
          },
          variant: AppButtonVariant.destructive,
        ),
      ],
    );
  }
}
