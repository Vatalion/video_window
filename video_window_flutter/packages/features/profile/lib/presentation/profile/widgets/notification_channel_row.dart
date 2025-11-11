import 'package:flutter/material.dart';

/// Widget for rendering per-notification-type channel toggles
/// AC1: Renders per-type channel toggles (email, push, in-app) in a row format
/// Implements Story 3-4: Notification Preferences Matrix
class NotificationChannelRow extends StatelessWidget {
  final String notificationType;
  final String title;
  final String description;
  final bool emailEnabled;
  final bool pushEnabled;
  final bool inAppEnabled;
  final bool emailGlobalEnabled;
  final bool pushGlobalEnabled;
  final bool inAppGlobalEnabled;
  final bool isCritical; // AC4: Critical alerts cannot be disabled
  final ValueChanged<Map<String, bool>> onChannelsChanged;

  const NotificationChannelRow({
    super.key,
    required this.notificationType,
    required this.title,
    required this.description,
    required this.emailEnabled,
    required this.pushEnabled,
    required this.inAppEnabled,
    required this.emailGlobalEnabled,
    required this.pushGlobalEnabled,
    required this.inAppGlobalEnabled,
    this.isCritical = false,
    required this.onChannelsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          if (isCritical) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.security,
                              size: 16,
                              color: Colors.orange.shade700,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Channel toggles in a row
            Row(
              children: [
                Expanded(
                  child: _buildChannelToggle(
                    context,
                    label: 'Email',
                    value: emailEnabled && emailGlobalEnabled,
                    enabled: emailGlobalEnabled && !isCritical,
                    onChanged: (value) {
                      if (!isCritical) {
                        onChannelsChanged({
                          'email': value ?? false,
                          'push': pushEnabled,
                          'inApp': inAppEnabled,
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildChannelToggle(
                    context,
                    label: 'Push',
                    value: pushEnabled && pushGlobalEnabled,
                    enabled: pushGlobalEnabled && !isCritical,
                    onChanged: (value) {
                      if (!isCritical) {
                        onChannelsChanged({
                          'email': emailEnabled,
                          'push': value ?? false,
                          'inApp': inAppEnabled,
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildChannelToggle(
                    context,
                    label: 'In-App',
                    value: inAppEnabled && inAppGlobalEnabled,
                    enabled: inAppGlobalEnabled && !isCritical,
                    onChanged: (value) {
                      if (!isCritical) {
                        onChannelsChanged({
                          'email': emailEnabled,
                          'push': pushEnabled,
                          'inApp': value ?? false,
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            if (isCritical) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Critical security alerts cannot be disabled',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.orange.shade700,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChannelToggle(
    BuildContext context, {
    required String label,
    required bool value,
    required bool enabled,
    required ValueChanged<bool?> onChanged,
  }) {
    return CheckboxListTile(
      title: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: enabled ? null : Colors.grey,
        ),
      ),
      value: value,
      onChanged: enabled ? onChanged : null,
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }
}
