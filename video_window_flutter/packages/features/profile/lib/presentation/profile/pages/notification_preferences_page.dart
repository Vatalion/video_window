import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:convert';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import '../bloc/profile_state.dart';
import '../widgets/notification_channel_row.dart';

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
                  // AC1: Matrix of notification types (offers, bids, orders, maker activity, security alerts)
                  _buildSectionHeader('Notification Types'),
                  _buildNotificationTypeRow(
                    notificationType: 'offers',
                    title: 'Offers',
                    description: 'Get notified when you receive new offers',
                    isCritical: false,
                  ),
                  const SizedBox(height: 8),
                  _buildNotificationTypeRow(
                    notificationType: 'bids',
                    title: 'Bids',
                    description: 'Get notified about bid activity',
                    isCritical: false,
                  ),
                  const SizedBox(height: 8),
                  _buildNotificationTypeRow(
                    notificationType: 'orders',
                    title: 'Orders',
                    description: 'Get notified about order status changes',
                    isCritical: false,
                  ),
                  const SizedBox(height: 8),
                  _buildNotificationTypeRow(
                    notificationType: 'maker_activity',
                    title: 'Maker Activity',
                    description: 'Get notified about maker activity',
                    isCritical: false,
                  ),
                  const SizedBox(height: 8),
                  _buildNotificationTypeRow(
                    notificationType: 'security_alert',
                    title: 'Security Alerts',
                    description: 'Critical security and account notifications',
                    isCritical: true, // AC4: Critical alerts cannot be disabled
                  ),
                  const SizedBox(height: 24),

                  // Quiet Hours Section
                  // AC2: Quiet hours editor with modal
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

  Widget _buildNotificationTypeRow({
    required String notificationType,
    required String title,
    required String description,
    required bool isCritical,
  }) {
    final typeSettings =
        _settings[notificationType] as Map<String, dynamic>? ?? {};
    final channels = typeSettings['channels'] as List<dynamic>? ??
        ['email', 'push', 'inApp'];
    final emailEnabled = channels.contains('email');
    final pushEnabled = channels.contains('push');
    final inAppEnabled = channels.contains('inApp');

    return NotificationChannelRow(
      notificationType: notificationType,
      title: title,
      description: description,
      emailEnabled: emailEnabled,
      pushEnabled: pushEnabled,
      inAppEnabled: inAppEnabled,
      emailGlobalEnabled: _emailNotifications ?? true,
      pushGlobalEnabled: _pushNotifications ?? true,
      inAppGlobalEnabled: _inAppNotifications ?? true,
      isCritical: isCritical,
      onChannelsChanged: (channels) {
        setState(() {
          final enabledChannels = <String>[];
          if (channels['email'] == true) enabledChannels.add('email');
          if (channels['push'] == true) enabledChannels.add('push');
          if (channels['inApp'] == true) enabledChannels.add('inApp');

          _settings[notificationType] = {
            'enabled': enabledChannels.isNotEmpty,
            'channels': enabledChannels,
          };
          _hasChanges = true;
        });
      },
    );
  }

  Widget _buildQuietHoursCard() {
    // AC2: Parse quiet hours from format { start: "22:00", end: "07:00" }
    final startTime = _quietHours['start'] as String? ?? '22:00';
    final endTime = _quietHours['end'] as String? ?? '07:00';
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
                'Disable push and email notifications during specified hours (local timezone)',
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
                        InkWell(
                          onTap: () => _showQuietHoursTimePicker(true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  startTime,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                const Icon(Icons.access_time),
                              ],
                            ),
                          ),
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
                        InkWell(
                          onTap: () => _showQuietHoursTimePicker(false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  endTime,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                const Icon(Icons.access_time),
                              ],
                            ),
                          ),
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

  // AC2: Quiet hours modal for time selection
  void _showQuietHoursTimePicker(bool isStartTime) {
    final currentTime = isStartTime
        ? (_quietHours['start'] as String? ?? '22:00')
        : (_quietHours['end'] as String? ?? '07:00');
    final parts = currentTime.split(':');
    final currentHour = int.parse(parts[0]);
    final currentMinute = int.parse(parts[1]);

    showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: currentHour,
        minute: currentMinute,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    ).then((selectedTime) {
      if (selectedTime != null) {
        setState(() {
          final timeString =
              '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
          if (isStartTime) {
            _quietHours['start'] = timeString;
          } else {
            _quietHours['end'] = timeString;
          }
          _hasChanges = true;
        });
      }
    });
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

    // AC2: Format quiet hours as { start: "22:00", end: "07:00" }
    final formattedQuietHours = {
      'enabled': _quietHours['enabled'] ?? false,
      'start': _quietHours['start'] ?? '22:00',
      'end': _quietHours['end'] ?? '07:00',
    };

    // AC5: Prepare analytics metadata with channel + frequency info
    final channelMetadata = <String, dynamic>{};
    for (final entry in _settings.entries) {
      final typeSettings = entry.value as Map<String, dynamic>? ?? {};
      final channels = typeSettings['channels'] as List<dynamic>? ?? [];
      channelMetadata[entry.key] = {
        'channels': channels,
        'enabled': typeSettings['enabled'] ?? true,
      };
    }

    context.read<ProfileBloc>().add(
          NotificationPreferencesUpdateRequested(
            widget.userId,
            {
              'emailNotifications': _emailNotifications!,
              'pushNotifications': _pushNotifications!,
              'inAppNotifications': _inAppNotifications!,
              'settings': jsonEncode(_settings),
              'quietHours': jsonEncode(formattedQuietHours),
              // AC5: Include channel metadata for analytics
              'channelMetadata': channelMetadata,
            },
          ),
        );
  }
}
