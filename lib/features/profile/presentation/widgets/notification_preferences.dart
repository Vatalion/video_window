import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/profile_bloc.dart';
import '../../domain/models/notification_preference_model.dart';

class NotificationPreferences extends StatefulWidget {
  const NotificationPreferences({super.key});

  @override
  State<NotificationPreferences> createState() => _NotificationPreferencesState();
}

class _NotificationPreferencesState extends State<NotificationPreferences> {
  bool _isLoading = false;
  NotificationSettings? _currentSettings;

  // Global settings
  bool _globalEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _ledEnabled = true;
  bool _badgeEnabled = true;

  // Quiet hours settings
  bool _quietHoursEnabled = false;
  TimeOfDay? _quietHoursStart;
  TimeOfDay? _quietHoursEnd;

  // Individual notification preferences
  final Map<NotificationType, bool> _typeEnabled = {};
  final Map<NotificationType, DeliveryMethod> _typeDeliveryMethod = {};

  @override
  void initState() {
    super.initState();
    _loadNotificationPreferences();
  }

  Future<void> _loadNotificationPreferences() async {
    if (_currentUserId != null) {
      context.read<ProfileBloc>().add(LoadNotificationPreferences(userId: _currentUserId!));
    }
  }

  String? get _currentUserId {
    // This should come from user authentication context
    final state = context.read<ProfileBloc>().state;
    if (state is ProfileLoaded) {
      return state.profile.userId;
    }
    return null;
  }

  void _updateSettingsFromModel(NotificationSettings settings) {
    setState(() {
      _currentSettings = settings;
      _globalEnabled = settings.globalEnabled;
      _soundEnabled = settings.soundEnabled;
      _vibrationEnabled = settings.vibrationEnabled;
      _ledEnabled = settings.ledEnabled;
      _badgeEnabled = settings.badgeEnabled;

      // Initialize individual preferences
      for (final pref in settings.preferences) {
        _typeEnabled[pref.type] = pref.enabled;
        _typeDeliveryMethod[pref.type] = pref.deliveryMethod;
        _quietHoursEnabled = pref.quietHoursEnabled;

        if (pref.quietHoursStart != null) {
          _quietHoursStart = TimeOfDay.fromDateTime(pref.quietHoursStart!);
        }
        if (pref.quietHoursEnd != null) {
          _quietHoursEnd = TimeOfDay.fromDateTime(pref.quietHoursEnd!);
        }
      }
    });
  }

  Future<void> _saveNotificationPreferences() async {
    if (_currentUserId == null) return;

    setState(() => _isLoading = true);

    // Update all notification preferences
    for (final type in NotificationType.values) {
      final enabled = _typeEnabled[type] ?? true;
      final deliveryMethod = _typeDeliveryMethod[type] ?? DeliveryMethod.push;

      context.read<ProfileBloc>().add(
        UpdateNotificationPreference(
          type: type,
          enabled: enabled,
          deliveryMethod: deliveryMethod,
          quietHoursEnabled: _quietHoursEnabled,
          quietHoursStart: _quietHoursStart != null
              ? DateTime(
                  DateTime.now().year,
                  DateTime.now().month,
                  DateTime.now().day,
                  _quietHoursStart!.hour,
                  _quietHoursStart!.minute,
                )
              : null,
          quietHoursEnd: _quietHoursEnd != null
              ? DateTime(
                  DateTime.now().year,
                  DateTime.now().month,
                  DateTime.now().day,
                  _quietHoursEnd!.hour,
                  _quietHoursEnd!.minute,
                )
              : null,
        ),
      );
    }

    // Update global settings
    await context.read<ProfileBloc>().add(UpdateNotificationPreference(
      type: NotificationType.system,
      enabled: _globalEnabled,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is NotificationPreferencesUpdated) {
          setState(() => _isLoading = false);
          _updateSettingsFromModel(state.settings);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification preferences updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is ProfileError) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state is ProfileLoaded && state.notificationSettings != null) {
          _updateSettingsFromModel(state.notificationSettings!);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notification Preferences'),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : _saveNotificationPreferences,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Global Settings Section
              _buildSectionTitle('Global Settings'),
              _buildGlobalSettings(),
              const SizedBox(height: 24),

              // Notification Types Section
              _buildSectionTitle('Notification Types'),
              _buildNotificationTypes(),
              const SizedBox(height: 24),

              // Quiet Hours Section
              _buildSectionTitle('Quiet Hours'),
              _buildQuietHoursSettings(),
              const SizedBox(height: 24),

              // Test Notifications Section
              _buildSectionTitle('Test Notifications'),
              _buildTestNotifications(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildGlobalSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Global Notification Settings',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            _buildSwitchTile(
              title: 'Enable notifications',
              subtitle: 'Turn all notifications on or off',
              value: _globalEnabled,
              onChanged: (value) => setState(() => _globalEnabled = value),
            ),
            _buildSwitchTile(
              title: 'Sound',
              subtitle: 'Play sound for notifications',
              value: _soundEnabled,
              onChanged: (value) => setState(() => _soundEnabled = value),
            ),
            _buildSwitchTile(
              title: 'Vibration',
              subtitle: 'Vibrate for notifications',
              value: _vibrationEnabled,
              onChanged: (value) => setState(() => _vibrationEnabled = value),
            ),
            _buildSwitchTile(
              title: 'LED light',
              subtitle: 'Blink LED light for notifications',
              value: _ledEnabled,
              onChanged: (value) => setState(() => _ledEnabled = value),
            ),
            _buildSwitchTile(
              title: 'Badge count',
              subtitle: 'Show notification badge on app icon',
              value: _badgeEnabled,
              onChanged: (value) => setState(() => _badgeEnabled = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTypes() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose which notifications to receive',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ...NotificationType.values.map((type) {
              return _buildNotificationTypeTile(type);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTypeTile(NotificationType type) {
    final enabled = _typeEnabled[type] ?? true;
    final deliveryMethod = _typeDeliveryMethod[type] ?? DeliveryMethod.push;

    return ExpansionTile(
      title: Text(_getNotificationTypeText(type)),
      subtitle: Text(_getNotificationTypeDescription(type)),
      trailing: Switch(
        value: enabled,
        onChanged: (value) {
          setState(() {
            _typeEnabled[type] = value;
          });
        },
        activeColor: Theme.of(context).primaryColor,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Delivery Method',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...DeliveryMethod.values.map((method) {
                return RadioListTile<DeliveryMethod>(
                  title: Text(_getDeliveryMethodText(method)),
                  subtitle: Text(_getDeliveryMethodDescription(method)),
                  value: method,
                  groupValue: deliveryMethod,
                  onChanged: enabled
                      ? (value) {
                          if (value != null) {
                            setState(() {
                              _typeDeliveryMethod[type] = value;
                            });
                          }
                        }
                      : null,
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuietHoursSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quiet Hours',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Silence notifications during specific hours',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _buildSwitchTile(
              title: 'Enable quiet hours',
              subtitle: 'Silence notifications during specified times',
              value: _quietHoursEnabled,
              onChanged: (value) => setState(() => _quietHoursEnabled = value),
            ),
            if (_quietHoursEnabled) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Start Time'),
                      subtitle: Text(
                        _quietHoursStart?.format(context) ?? 'Not set',
                      ),
                      trailing: const Icon(Icons.access_time),
                      onTap: _pickQuietHoursStart,
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: const Text('End Time'),
                      subtitle: Text(
                        _quietHoursEnd?.format(context) ?? 'Not set',
                      ),
                      trailing: const Icon(Icons.access_time),
                      onTap: _pickQuietHoursEnd,
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

  Widget _buildTestNotifications() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Test Notifications',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: NotificationType.values.map((type) {
                return ElevatedButton.icon(
                  onPressed: _typeEnabled[type] ?? true
                      ? () => _testNotification(type)
                      : null,
                  icon: const Icon(Icons.notifications),
                  label: Text(_getNotificationTypeText(type)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      activeColor: Theme.of(context).primaryColor,
    );
  }

  String _getNotificationTypeText(NotificationType type) {
    switch (type) {
      case NotificationType.system:
        return 'System Updates';
      case NotificationType.messages:
        return 'Messages';
      case NotificationType.friendRequests:
        return 'Friend Requests';
      case NotificationType.comments:
        return 'Comments';
      case NotificationType.likes:
        return 'Likes';
      case NotificationType.mentions:
        return 'Mentions';
      case NotificationType.follows:
        return 'Follows';
      case NotificationType.commerce:
        return 'Commerce';
      case NotificationType.security:
        return 'Security Alerts';
      case NotificationType.marketing:
        return 'Marketing';
      case NotificationType.updates:
        return 'App Updates';
    }
  }

  String _getNotificationTypeDescription(NotificationType type) {
    switch (type) {
      case NotificationType.system:
        return 'Important system and app updates';
      case NotificationType.messages:
        return 'New messages from other users';
      case NotificationType.friendRequests:
        return 'New friend requests and acceptances';
      case NotificationType.comments:
        return 'Comments on your posts';
      case NotificationType.likes:
        return 'Likes on your content';
      case NotificationType.mentions:
        return 'When someone mentions you';
      case NotificationType.follows:
        return 'When someone follows you';
      case NotificationType.commerce:
        return 'Commerce and purchase notifications';
      case NotificationType.security:
        return 'Security alerts and account activity';
      case NotificationType.marketing:
        return 'Promotional content and offers';
      case NotificationType.updates:
        return 'Feature updates and announcements';
    }
  }

  String _getDeliveryMethodText(DeliveryMethod method) {
    switch (method) {
      case DeliveryMethod.push:
        return 'Push Notification';
      case DeliveryMethod.email:
        return 'Email';
      case DeliveryMethod.inApp:
        return 'In-App';
      case DeliveryMethod.sms:
        return 'SMS';
    }
  }

  String _getDeliveryMethodDescription(DeliveryMethod method) {
    switch (method) {
      case DeliveryMethod.push:
        return 'Instant notification on your device';
      case DeliveryMethod.email:
        return 'Send notification via email';
      case DeliveryMethod.inApp:
        return 'Show notification within the app';
      case DeliveryMethod.sms:
        return 'Send notification via text message';
    }
  }

  Future<void> _pickQuietHoursStart() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _quietHoursStart ?? const TimeOfDay(hour: 22, minute: 0),
    );
    if (time != null) {
      setState(() => _quietHoursStart = time);
    }
  }

  Future<void> _pickQuietHoursEnd() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _quietHoursEnd ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (time != null) {
      setState(() => _quietHoursEnd = time);
    }
  }

  Future<void> _testNotification(NotificationType type) async {
    final deliveryMethod = _typeDeliveryMethod[type] ?? DeliveryMethod.push;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sending test ${_getNotificationTypeText(type)} notification via ${_getDeliveryMethodText(deliveryMethod)}...'),
        duration: const Duration(seconds: 2),
      ),
    );

    // Simulate test notification
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test notification sent successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}