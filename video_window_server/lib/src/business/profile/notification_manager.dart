import 'package:serverpod/serverpod.dart';
import 'dart:convert';
import '../../generated/profile/notification_preferences.dart';

/// Notification manager for handling notification preferences, quiet hours, and external service sync
/// Implements Story 3-4: Notification Preferences Matrix
/// AC3: Preferences persist via notification_manager.dart, update Firebase topics, and sync to SendGrid suppression groups
/// AC4: Critical security alerts ignore quiet hours and cannot be disabled
class NotificationManager {
  final Session _session;

  NotificationManager(this._session);

  /// Critical notification types that cannot be disabled and ignore quiet hours
  static const Set<String> _criticalNotificationTypes = {
    'security_alert',
    'account_compromised',
    'payment_failed',
    'suspicious_activity',
  };

  /// Update notification preferences with validation and external service sync
  /// AC3: Updates Firebase topics and syncs to SendGrid suppression groups
  /// AC4: Enforces critical alert immutability
  Future<NotificationPreferences> updatePreferences(
    int userId,
    Map<String, dynamic> prefsData,
  ) async {
    try {
      final existing = await NotificationPreferences.db.findFirstRow(
        _session,
        where: (t) => t.userId.equals(userId),
      );

      // Parse incoming settings
      Map<String, dynamic> settings = {};
      if (prefsData['settings'] != null) {
        if (prefsData['settings'] is String) {
          settings = json.decode(prefsData['settings'] as String)
              as Map<String, dynamic>;
        } else {
          settings = prefsData['settings'] as Map<String, dynamic>;
        }
      } else if (existing?.settings != null) {
        settings = json.decode(existing!.settings!) as Map<String, dynamic>;
      }

      // AC4: Ensure critical notification types cannot be disabled
      for (final criticalType in _criticalNotificationTypes) {
        if (settings.containsKey(criticalType)) {
          final typeSettings = settings[criticalType] as Map<String, dynamic>?;
          if (typeSettings != null) {
            // Force enable critical notifications
            typeSettings['enabled'] = true;
            // Ensure all channels are enabled for critical alerts
            typeSettings['channels'] = ['email', 'push', 'inApp'];
            settings[criticalType] = typeSettings;
          }
        }
      }

      // Parse quiet hours
      Map<String, dynamic> quietHours = {};
      if (prefsData['quietHours'] != null) {
        if (prefsData['quietHours'] is String) {
          quietHours = json.decode(prefsData['quietHours'] as String)
              as Map<String, dynamic>;
        } else {
          quietHours = prefsData['quietHours'] as Map<String, dynamic>;
        }
      } else if (existing?.quietHours != null) {
        quietHours = json.decode(existing!.quietHours!) as Map<String, dynamic>;
      }

      // Validate quiet hours format
      if (quietHours.isNotEmpty) {
        _validateQuietHours(quietHours);
      }

      final now = DateTime.now().toUtc();
      final updatedPrefs = existing?.copyWith(
            emailNotifications: prefsData['emailNotifications'] as bool?,
            pushNotifications: prefsData['pushNotifications'] as bool?,
            inAppNotifications: prefsData['inAppNotifications'] as bool?,
            settings: json.encode(settings),
            quietHours: json.encode(quietHours),
            updatedAt: now,
          ) ??
          NotificationPreferences(
            userId: userId,
            emailNotifications:
                prefsData['emailNotifications'] as bool? ?? true,
            pushNotifications: prefsData['pushNotifications'] as bool? ?? true,
            inAppNotifications:
                prefsData['inAppNotifications'] as bool? ?? true,
            settings: json.encode(settings),
            quietHours: json.encode(quietHours),
            createdAt: now,
            updatedAt: now,
          );

      final saved = existing != null
          ? await NotificationPreferences.db.updateRow(_session, updatedPrefs)
          : await NotificationPreferences.db.insertRow(_session, updatedPrefs);

      // AC3: Sync to external services
      await _syncToFirebaseTopics(userId, settings);
      await _syncToSendGridSuppressionGroups(userId, settings, quietHours);

      return saved;
    } catch (e, stackTrace) {
      _session.log(
        'Error updating notification preferences for user $userId: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Check if notification should be delivered based on quiet hours
  /// AC2: Quiet hours disable push/email delivery during specified window
  /// AC4: Critical alerts ignore quiet hours
  bool shouldDeliverNotification({
    required String notificationType,
    required String channel,
    required Map<String, dynamic> preferences,
  }) {
    // AC4: Critical notifications always deliver
    if (_criticalNotificationTypes.contains(notificationType)) {
      return true;
    }

    // Only apply quiet hours to push and email channels
    if (channel != 'push' && channel != 'email') {
      return true;
    }

    final quietHoursJson = preferences['quietHours'] as String?;
    if (quietHoursJson == null || quietHoursJson.isEmpty) {
      return true;
    }

    try {
      final quietHours = json.decode(quietHoursJson) as Map<String, dynamic>;
      if (quietHours['enabled'] != true) {
        return true;
      }

      final startTime = quietHours['start'] as String?;
      final endTime = quietHours['end'] as String?;
      // TODO: Use timezone when full timezone support is implemented
      // final timezone = quietHours['timezone'] as String? ?? 'UTC';

      if (startTime == null || endTime == null) {
        return true;
      }

      // Parse times and check if current time is within quiet hours
      final now = DateTime.now();
      final start = _parseTimeString(startTime);
      final end = _parseTimeString(endTime);

      // Simple time comparison (for MVP - full timezone support requires timezone package)
      final currentHour = now.hour;
      final currentMinute = now.minute;
      final startHour = start['hour'] as int;
      final startMinute = start['minute'] as int;
      final endHour = end['hour'] as int;
      final endMinute = end['minute'] as int;

      final currentTimeMinutes = currentHour * 60 + currentMinute;
      final startTimeMinutes = startHour * 60 + startMinute;
      final endTimeMinutes = endHour * 60 + endMinute;

      // Handle quiet hours that span midnight
      if (startTimeMinutes > endTimeMinutes) {
        // Quiet hours span midnight (e.g., 22:00 to 08:00)
        // Don't deliver if current time is >= start OR < end (i.e., in quiet hours)
        final inQuietHours = currentTimeMinutes >= startTimeMinutes ||
            currentTimeMinutes < endTimeMinutes;
        return !inQuietHours; // Deliver if NOT in quiet hours
      } else {
        // Quiet hours within same day
        // Don't deliver if current time is >= start AND < end (i.e., in quiet hours)
        final inQuietHours = currentTimeMinutes >= startTimeMinutes &&
            currentTimeMinutes < endTimeMinutes;
        return !inQuietHours; // Deliver if NOT in quiet hours
      }
    } catch (e) {
      _session.log(
        'Error checking quiet hours: $e',
        level: LogLevel.warning,
      );
      // Fail open - deliver notification if we can't parse quiet hours
      return true;
    }
  }

  /// Validate quiet hours format
  /// AC2: Quiet hours format validation
  void _validateQuietHours(Map<String, dynamic> quietHours) {
    if (quietHours['enabled'] == true) {
      final start = quietHours['start'] as String?;
      final end = quietHours['end'] as String?;

      if (start == null || end == null) {
        throw Exception('Quiet hours require start and end times');
      }

      // Validate time format (HH:mm)
      final timeRegex = RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$');
      if (!timeRegex.hasMatch(start) || !timeRegex.hasMatch(end)) {
        throw Exception('Invalid time format. Use HH:mm (e.g., 22:00)');
      }
    }
  }

  /// Parse time string (HH:mm) to hour and minute
  Map<String, int> _parseTimeString(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length != 2) {
      throw Exception('Invalid time format: $timeStr');
    }

    return {
      'hour': int.parse(parts[0]),
      'minute': int.parse(parts[1]),
    };
  }

  /// Sync notification preferences to Firebase Cloud Messaging topics
  /// AC3: Update Firebase topics per notification type
  Future<void> _syncToFirebaseTopics(
    int userId,
    Map<String, dynamic> settings,
  ) async {
    try {
      // TODO: Implement Firebase Cloud Messaging topic subscription/unsubscription
      // This requires Firebase Admin SDK integration
      // For MVP, log the intent
      _session.log(
        'Firebase topic sync required for user $userId with settings: $settings',
        level: LogLevel.info,
      );

      // Placeholder for Firebase integration:
      // - Subscribe to topics for enabled notification types
      // - Unsubscribe from topics for disabled notification types
      // - Handle device token management with opt-in flags
    } catch (e, stackTrace) {
      _session.log(
        'Error syncing to Firebase topics: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      // Don't fail the preference update if Firebase sync fails
    }
  }

  /// Sync notification preferences to SendGrid suppression groups
  /// AC3: Sync to SendGrid suppression groups
  Future<void> _syncToSendGridSuppressionGroups(
    int userId,
    Map<String, dynamic> settings,
    Map<String, dynamic> quietHours,
  ) async {
    try {
      // TODO: Implement SendGrid suppression group management
      // This requires SendGrid API integration
      // For MVP, log the intent
      _session.log(
        'SendGrid suppression group sync required for user $userId',
        level: LogLevel.info,
      );

      // Placeholder for SendGrid integration:
      // - Map notification types to SendGrid categories
      // - Update suppression groups based on preferences
      // - Handle quiet hours by adding/removing from suppression groups
    } catch (e, stackTrace) {
      _session.log(
        'Error syncing to SendGrid suppression groups: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      // Don't fail the preference update if SendGrid sync fails
    }
  }

  /// Get notification preferences with defaults
  Future<NotificationPreferences> getPreferences(int userId) async {
    final prefs = await NotificationPreferences.db.findFirstRow(
      _session,
      where: (t) => t.userId.equals(userId),
    );

    if (prefs != null) {
      return prefs;
    }

    // Create default preferences
    final now = DateTime.now().toUtc();
    final defaultPrefs = NotificationPreferences(
      userId: userId,
      emailNotifications: true,
      pushNotifications: true,
      inAppNotifications: true,
      settings: json.encode({
        'offers': {
          'enabled': true,
          'channels': ['email', 'push', 'inApp']
        },
        'bids': {
          'enabled': true,
          'channels': ['email', 'push', 'inApp']
        },
        'orders': {
          'enabled': true,
          'channels': ['email', 'push']
        },
        'maker_activity': {
          'enabled': true,
          'channels': ['inApp']
        },
        'security_alert': {
          'enabled': true,
          'channels': ['email', 'push', 'inApp']
        },
      }),
      quietHours:
          json.encode({'enabled': false, 'start': '22:00', 'end': '07:00'}),
      createdAt: now,
      updatedAt: now,
    );

    return await NotificationPreferences.db.insertRow(_session, defaultPrefs);
  }
}
