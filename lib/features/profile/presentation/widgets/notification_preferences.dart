import 'package:flutter/material.dart';
import '../../domain/models/notification_preference.dart';
import '../../data/repositories/profile_repository.dart';

class NotificationPreferences extends StatefulWidget {
  final String userId;
  final List<NotificationPreference> initialPreferences;
  final Function(List<NotificationPreference>) onPreferencesUpdated;

  const NotificationPreferences({
    super.key,
    required this.userId,
    required this.initialPreferences,
    required this.onPreferencesUpdated,
  });

  @override
  State<NotificationPreferences> createState() => _NotificationPreferencesState();
}

class _NotificationPreferencesState extends State<NotificationPreferences> {
  final ProfileRepository _repository = ProfileRepository();
  late List<NotificationPreference> _preferences;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _preferences = List.from(widget.initialPreferences);
  }

  Future<void> _updatePreference(NotificationPreference preference) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final updatedPreference = await _repository.updateNotificationPreference(preference);

      setState(() {
        final index = _preferences.indexWhere((p) => p.notificationType == updatedPreference.notificationType);
        if (index != -1) {
          _preferences[index] = updatedPreference;
        }
        _isLoading = false;
      });

      widget.onPreferencesUpdated(_preferences);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update preference: ${e.toString()}')),
        );
      }
    }
  }

  void _toggleDeliveryMethod(NotificationPreference preference, DeliveryMethod method) {
    final updatedMethods = Set<DeliveryMethod>.from(preference.deliveryMethods);

    if (updatedMethods.contains(method)) {
      updatedMethods.remove(method);
      // Ensure at least one delivery method is selected
      if (updatedMethods.isEmpty) {
        updatedMethods.add(DeliveryMethod.inApp);
      }
    } else {
      updatedMethods.add(method);
    }

    final updatedPreference = preference.copyWith(deliveryMethods: updatedMethods);
    _updatePreference(updatedPreference);
  }

  void _togglePreferenceEnabled(NotificationPreference preference) {
    final updatedPreference = preference.copyWith(enabled: !preference.enabled);
    _updatePreference(updatedPreference);
  }

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
                const Text(
                  'Notification Preferences',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ..._preferences.map((preference) => _buildPreferenceTile(preference)),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceTile(NotificationPreference preference) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    preference.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Switch(
                  value: preference.enabled,
                  onChanged: (value) => _togglePreferenceEnabled(preference),
                ),
              ],
            ),
            if (preference.enabled) ...[
              const SizedBox(height: 12),
              const Text(
                'Delivery Methods:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: DeliveryMethod.values.map((method) {
                  final isSelected = preference.deliveryMethods.contains(method);
                  return FilterChip(
                    label: Text(_getDeliveryMethodLabel(method)),
                    selected: isSelected,
                    onSelected: (selected) => _toggleDeliveryMethod(preference, method),
                    avatar: Text(_getDeliveryMethodIcon(method)),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getDeliveryMethodLabel(DeliveryMethod method) {
    switch (method) {
      case DeliveryMethod.push:
        return 'Push';
      case DeliveryMethod.email:
        return 'Email';
      case DeliveryMethod.inApp:
        return 'In-App';
    }
  }

  String _getDeliveryMethodIcon(DeliveryMethod method) {
    switch (method) {
      case DeliveryMethod.push:
        return '📱';
      case DeliveryMethod.email:
        return '📧';
      case DeliveryMethod.inApp:
        return '🔔';
    }
  }
}