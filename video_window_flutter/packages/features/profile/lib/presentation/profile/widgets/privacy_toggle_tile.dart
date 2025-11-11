import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Reusable privacy toggle tile widget with compliance copy
/// AC1: Privacy settings page surfaces toggles with descriptive helper text
/// AC1: WCAG-compliant contrast
class PrivacyToggleTile extends StatelessWidget {
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? learnMoreUrl;
  final String? learnMoreText;

  const PrivacyToggleTile({
    super.key,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
    this.learnMoreUrl,
    this.learnMoreText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: SwitchListTile(
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface, // WCAG contrast compliance
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface
                    .withValues(alpha: 0.7), // WCAG contrast compliance
              ),
            ),
            if (learnMoreUrl != null && learnMoreText != null) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _launchLearnMore(learnMoreUrl!),
                child: Text(
                  learnMoreText!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ],
        ),
        value: value,
        onChanged: onChanged,
        activeThumbColor: colorScheme.primary,
      ),
    );
  }

  Future<void> _launchLearnMore(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
