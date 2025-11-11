import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:convert';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';

/// Notification preferences page
/// AC7: Notification preference matrix with granular controls for email, push, and in-app notifications
class NotificationPreferencesPage extends StatefulWidget {
  final int userId;

  const NotificationPreferencesPage({
    super.key,
    required this.userId,
  });

  @override
  State<NotificationPreferencesPage> createState() =>
      _NotificationPreferencesPageState();
}

class _NotificationPreferencesPageState
    extends State<NotificationPreferencesPage> {
  bool? _emailNotifications;
  bool? _pushNotifications;
  bool? _inAppNotifications;
  Map<String, dynamic> _settings = {};
  Map<String, dynamic> _quietHours = {};
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(
          NotificationPreferencesLoadRequested(widget.userId),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences'),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _savePreferences,
              child: const Text('Save'),
            ),
        ],
      ),
      body: BlocListener<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is NotificationPreferencesUpdated) {
            setState(() {
              _hasChanges = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Notification preferences saved successfully'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            if (state is NotificationPreferencesUpdated) {
              final prefs = state.preferences;
              // Initialize local state from loaded preferences
              if (_emailNotifications == null) {
                _emailNotifications =
                    prefs['emailNotifications'] as bool? ?? true;
                _pushNotifications =
                    prefs['pushNotifications'] as bool? ?? true;
                _inAppNotifications =
                    prefs['inAppNotifications'] as bool? ?? true;
                _settings = prefs['settings'] as Map<String, dynamic>? ?? {};
                _quietHours =
                    prefs['quietHours'] as Map<String, dynamic>? ?? {};
              }
            }

            if (state is ProfileLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ProfileError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${state.message}'),
                    ElevatedButton(
                      onPressed: () {
                        context.read<ProfileBloc>().add(
                              NotificationPreferencesLoadRequested(
                                widget.userId,
                              ),
                            );
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Global Channel Toggles
                  _buildSectionHeader('Notification Channels'),
                  _buildSwitchTile(
                    title: 'Email Notifications',
                    value: _emailNotifications ?? true,
                    onChanged: (value) {
                      setState(() {
                        _emailNotifications = value;
                        _hasChanges = true;
                      });
                    },
                    description: 'Receive notifications via email',
                  ),
                  _buildSwitchTile(
                    title: 'Push Notifications',
                    value: _pushNotifications ?? true,
                    onChanged: (value) {
                      setState(() {
                        _pushNotifications = value;
                        _hasChanges = true;
                      });
                    },
                    description: 'Receive push notifications on your device',
                  ),
                  _buildSwitchTile(
                    title: 'In-App Notifications',
                    value: _inAppNotifications ?? true,
                    onChanged: (value) {
                      setState(() {
                        _inAppNotifications = value;
                        _hasChanges = true;
                      });
                    },
                    description: 'Show notifications within the app',
                  ),
                  const SizedBox(height: 24),

                  // Notification Types Matrix
                  _buildSectionHeader('Notification Types'),
                  _buildNotificationTypeCard(
                    'New Offers',
                    'Get notified when you receive new offers',
                    'new_offers',
                  ),
                  _buildNotificationTypeCard(
                    'Outbid Alerts',
                    'Get notified when you are outbid',
                    'outbid_alerts',
                  ),
                  _buildNotificationTypeCard(
                    'Auction Ending Reminders',
                    'Get reminded when auctions are ending',
                    'auction_ending',
                  ),
                  _buildNotificationTypeCard(
                    'Order Updates',
                    'Get notified about order status changes',
                    'order_updates',
                  ),
                  _buildNotificationTypeCard(
                    'Maker Activity',
                    'Get notified about maker activity',
                    'maker_activity',
                  ),
                  const SizedBox(height: 24),

                  // Quiet Hours Section
                  _buildSectionHeader('Quiet Hours'),
                  _buildQuietHoursCard(),
                  const SizedBox(height: 32),

                  // Critical Notifications Note
                  _buildCriticalNote(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required String description,
  }) {
    return Card(
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(description),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildNotificationTypeCard(
    String title,
    String description,
    String typeKey,
  ) {
    final typeSettings = _settings[typeKey] as Map<String, dynamic>? ?? {};
    final emailEnabled = typeSettings['email'] as bool? ?? true;
    final pushEnabled = typeSettings['push'] as bool? ?? true;
    final inAppEnabled = typeSettings['inApp'] as bool? ?? true;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Email'),
                    value: emailEnabled && (_emailNotifications ?? true),
                    onChanged: (_emailNotifications ?? true)
                        ? (value) {
                            setState(() {
                              _settings[typeKey] = {
                                ...typeSettings,
                                'email': value ?? false,
                              };
                              _hasChanges = true;
                            });
                          }
                        : null,
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  ),
                ),
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Push'),
                    value: pushEnabled && (_pushNotifications ?? true),
                    onChanged: (_pushNotifications ?? true)
                        ? (value) {
                            setState(() {
                              _settings[typeKey] = {
                                ...typeSettings,
                                'push': value ?? false,
                              };
                              _hasChanges = true;
                            });
                          }
                        : null,
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  ),
                ),
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('In-App'),
                    value: inAppEnabled && (_inAppNotifications ?? true),
                    onChanged: (_inAppNotifications ?? true)
                        ? (value) {
                            setState(() {
                              _settings[typeKey] = {
                                ...typeSettings,
                                'inApp': value ?? false,
                              };
                              _hasChanges = true;
                            });
                          }
                        : null,
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuietHoursCard() {
    final startHour = _quietHours['startHour'] as int? ?? 22;
    final endHour = _quietHours['endHour'] as int? ?? 8;
    final enabled = _quietHours['enabled'] as bool? ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text('Enable Quiet Hours'),
              subtitle: const Text(
                'Disable push and email notifications during specified hours',
              ),
              value: enabled,
              onChanged: (value) {
                setState(() {
                  _quietHours['enabled'] = value;
                  _hasChanges = true;
                });
              },
            ),
            if (enabled) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Start Time'),
                        const SizedBox(height: 8),
                        DropdownButton<int>(
                          value: startHour,
                          isExpanded: true,
                          items: List.generate(24, (i) => i)
                              .map((hour) => DropdownMenuItem(
                                    value: hour,
                                    child: Text(
                                        '${hour.toString().padLeft(2, '0')}:00'),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _quietHours['startHour'] = value;
                                _hasChanges = true;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('End Time'),
                        const SizedBox(height: 8),
                        DropdownButton<int>(
                          value: endHour,
                          isExpanded: true,
                          items: List.generate(24, (i) => i)
                              .map((hour) => DropdownMenuItem(
                                    value: hour,
                                    child: Text(
                                        '${hour.toString().padLeft(2, '0')}:00'),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _quietHours['endHour'] = value;
                                _hasChanges = true;
                              });
                            }
                          },
                        ),
                      ],
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

  Widget _buildCriticalNote() {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Critical Notifications',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Security alerts and critical account notifications will always be delivered, '
                    'even during quiet hours. These cannot be disabled.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _savePreferences() {
    if (_emailNotifications == null ||
        _pushNotifications == null ||
        _inAppNotifications == null) {
      return;
    }

    context.read<ProfileBloc>().add(
          NotificationPreferencesUpdateRequested(
            widget.userId,
            {
              'emailNotifications': _emailNotifications!,
              'pushNotifications': _pushNotifications!,
              'inAppNotifications': _inAppNotifications!,
              'settings': jsonEncode(_settings),
              'quietHours': jsonEncode(_quietHours),
            },
          ),
        );
  }
}
