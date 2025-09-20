import 'package:flutter/material.dart';
import '../models/notification_preference_model.dart';

class NotificationService {
  final String _apiBaseUrl;

  NotificationService({required String apiBaseUrl}) : _apiBaseUrl = apiBaseUrl;

  Future<NotificationSettings> getNotificationSettings(String userId) async {
    // Mock implementation - get all notification preferences
    final preferences = await _getAllNotificationPreferences(userId);

    return NotificationSettings(
      preferences: preferences,
      globalEnabled: true,
      soundEnabled: true,
      vibrationEnabled: true,
      ledEnabled: true,
      badgeEnabled: true,
    );
  }

  Future<NotificationPreferenceModel> getNotificationPreference({
    required String userId,
    required NotificationType type,
  }) async {
    // Mock implementation
    debugPrint('Getting notification preference for user $userId, type: ${type.name}');

    return NotificationPreferenceModel(
      id: 'pref_${userId}_${type.name}',
      userId: userId,
      type: type,
      enabled: _getDefaultEnabledStatus(type),
      deliveryMethod: _getDefaultDeliveryMethod(type),
      quietHoursEnabled: false,
      frequency: 1,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    );
  }

  Future<NotificationPreferenceModel> updateNotificationPreference({
    required String userId,
    required NotificationType type,
    bool? enabled,
    DeliveryMethod? deliveryMethod,
    bool? quietHoursEnabled,
    DateTime? quietHoursStart,
    DateTime? quietHoursEnd,
    int? frequency,
  }) async {
    // Get current preference
    final current = await getNotificationPreference(userId: userId, type: type);

    // Update with new values
    final updated = NotificationPreferenceModel(
      id: current.id,
      userId: userId,
      type: type,
      enabled: enabled ?? current.enabled,
      deliveryMethod: deliveryMethod ?? current.deliveryMethod,
      quietHoursEnabled: quietHoursEnabled ?? current.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? current.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? current.quietHoursEnd,
      frequency: frequency ?? current.frequency,
      createdAt: current.createdAt,
      updatedAt: DateTime.now(),
    );

    debugPrint('Updating notification preference: ${updated.toJson()}');
    return updated;
  }

  Future<bool> enableNotificationType({
    required String userId,
    required NotificationType type,
    required DeliveryMethod deliveryMethod,
  }) async {
    await updateNotificationPreference(
      userId: userId,
      type: type,
      enabled: true,
      deliveryMethod: deliveryMethod,
    );
    return true;
  }

  Future<bool> disableNotificationType({
    required String userId,
    required NotificationType type,
  }) async {
    await updateNotificationPreference(
      userId: userId,
      type: type,
      enabled: false,
    );
    return true;
  }

  Future<bool> updateGlobalNotificationSettings({
    required String userId,
    bool? globalEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? ledEnabled,
    bool? badgeEnabled,
  }) async {
    debugPrint('Updating global notification settings for user $userId');

    // In real implementation, this would update user preferences in database
    return true;
  }

  Future<bool> setupQuietHours({
    required String userId,
    required DateTime startTime,
    required DateTime endTime,
    bool enabled = true,
  }) async {
    debugPrint('Setting up quiet hours for user $userId: $startTime - $endTime');

    // Update all notification preferences with quiet hours
    final preferences = await _getAllNotificationPreferences(userId);
    for (final pref in preferences) {
      await updateNotificationPreference(
        userId: userId,
        type: pref.type,
        quietHoursEnabled: enabled,
        quietHoursStart: startTime,
        quietHoursEnd: endTime,
      );
    }

    return true;
  }

  Future<bool> disableQuietHours(String userId) async {
    debugPrint('Disabling quiet hours for user $userId');

    final preferences = await _getAllNotificationPreferences(userId);
    for (final pref in preferences) {
      await updateNotificationPreference(
        userId: userId,
        type: pref.type,
        quietHoursEnabled: false,
      );
    }

    return true;
  }

  Future<bool> isQuietHoursActive(String userId) async {
    // Mock implementation - check if current time is within quiet hours
    final now = DateTime.now();
    final preferences = await getNotificationPreference(
      userId: userId,
      type: NotificationType.system,
    );

    if (!preferences.quietHoursEnabled) return false;

    final start = preferences.quietHoursStart;
    final end = preferences.quietHoursEnd;

    if (start == null || end == null) return false;

    // Simple time comparison (ignoring date)
    final currentTime = TimeOfDay.fromDateTime(now);
    final startTime = TimeOfDay.fromDateTime(start);
    final endTime = TimeOfDay.fromDateTime(end);

    if (startTime.hour < endTime.hour ||
        (startTime.hour == endTime.hour && startTime.minute < endTime.minute)) {
      // Normal case: e.g., 22:00 to 06:00 next day
      return (currentTime.hour > startTime.hour ||
              (currentTime.hour == startTime.hour && currentTime.minute >= startTime.minute)) &&
          (currentTime.hour < endTime.hour ||
              (currentTime.hour == endTime.hour && currentTime.minute < endTime.minute));
    } else {
      // Cross-midnight case: e.g., 22:00 to 06:00
      return (currentTime.hour > startTime.hour ||
              (currentTime.hour == startTime.hour && currentTime.minute >= startTime.minute)) ||
          (currentTime.hour < endTime.hour ||
              (currentTime.hour == endTime.hour && currentTime.minute < endTime.minute));
    }
  }

  Future<Map<String, dynamic>> getNotificationStats(String userId) async {
    // Mock implementation
    debugPrint('Getting notification stats for user: $userId');

    return {
      'total_notifications_last_30_days': 125,
      'unread_notifications': 8,
      'push_notifications_sent': 98,
      'email_notifications_sent': 27,
      'notification_types_enabled': {
        'system': true,
        'messages': true,
        'friend_requests': true,
        'comments': false,
        'likes': true,
        'mentions': true,
        'follows': false,
        'commerce': true,
        'security': true,
        'marketing': false,
        'updates': true,
      },
      'quiet_hours_enabled': false,
      'last_notification_received': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
    };
  }

  Future<bool> testNotification({
    required String userId,
    required NotificationType type,
    required DeliveryMethod method,
  }) async {
    debugPrint('Testing $method notification for user $userId, type: ${type.name}');

    // In real implementation, this would send a test notification
    // and verify delivery

    return true;
  }

  Future<bool> markNotificationAsRead({
    required String userId,
    required String notificationId,
  }) async {
    debugPrint('Marking notification $notificationId as read for user $userId');
    return true;
  }

  Future<bool> markAllNotificationsAsRead(String userId) async {
    debugPrint('Marking all notifications as read for user $userId');
    return true;
  }

  Future<bool> deleteNotification({
    required String userId,
    required String notificationId,
  }) async {
    debugPrint('Deleting notification $notificationId for user $userId');
    return true;
  }

  // Helper methods
  Future<List<NotificationPreferenceModel>> _getAllNotificationPreferences(String userId) async {
    // Mock implementation - get all notification types for user
    final List<NotificationPreferenceModel> preferences = [];

    for (final type in NotificationType.values) {
      preferences.add(await getNotificationPreference(userId: userId, type: type));
    }

    return preferences;
  }

  bool _getDefaultEnabledStatus(NotificationType type) {
    // Enable most notifications by default, disable marketing
    return type != NotificationType.marketing;
  }

  DeliveryMethod _getDefaultDeliveryMethod(NotificationType type) {
    switch (type) {
      case NotificationType.security:
      case NotificationType.system:
        return DeliveryMethod.push;
      case NotificationType.messages:
      case NotificationType.friendRequests:
        return DeliveryMethod.push;
      case NotificationType.marketing:
        return DeliveryMethod.email;
      default:
        return DeliveryMethod.push;
    }
  }

  bool shouldSendNotification({
    required NotificationPreferenceModel preference,
    required NotificationSettings globalSettings,
  }) {
    if (!globalSettings.globalEnabled || !preference.enabled) {
      return false;
    }

    // Check quiet hours
    if (preference.quietHoursEnabled) {
      // In real implementation, check if current time is within quiet hours
      return false;
    }

    return true;
  }
}