import 'package:flutter_test/flutter_test.dart';
import 'package:video_window/features/profile/data/services/notification_service.dart';
import 'package:video_window/features/profile/domain/models/notification_preference_model.dart';

class MockNotificationService extends NotificationService {
  MockNotificationService() : super(apiBaseUrl: 'https://api.example.com');
}

void main() {
  group('NotificationService Tests', () {
    late NotificationService notificationService;

    setUp(() {
      notificationService = MockNotificationService();
    });

    group('getNotificationSettings', () {
      test('should return notification settings with all preferences', () async {
        // Act
        final settings = await notificationService.getNotificationSettings('test_user');

        // Assert
        expect(settings, isA<NotificationSettings>());
        expect(settings.globalEnabled, isTrue);
        expect(settings.soundEnabled, isTrue);
        expect(settings.vibrationEnabled, isTrue);
        expect(settings.ledEnabled, isTrue);
        expect(settings.badgeEnabled, isTrue);
        expect(settings.preferences.length, equals(NotificationType.values.length));
      });

      test('should include all notification types in preferences', () async {
        // Act
        final settings = await notificationService.getNotificationSettings('test_user');

        // Assert
        final types = settings.preferences.map((p) => p.type).toList();
        expect(types, containsAll(NotificationType.values));
      });
    });

    group('getNotificationPreference', () {
      test('should return preference for specific notification type', () async {
        // Act
        final preference = await notificationService.getNotificationPreference(
          userId: 'test_user',
          type: NotificationType.messages,
        );

        // Assert
        expect(preference, isA<NotificationPreferenceModel>());
        expect(preference.userId, equals('test_user'));
        expect(preference.type, equals(NotificationType.messages));
        expect(preference.enabled, isTrue);
        expect(preference.deliveryMethod, equals(DeliveryMethod.push));
        expect(preference.quietHoursEnabled, isFalse);
        expect(preference.frequency, equals(1));
        expect(preference.createdAt, isNotNull);
        expect(preference.updatedAt, isNotNull);
      });

      test('should have correct default settings for different types', () async {
        // Act
        final systemPref = await notificationService.getNotificationPreference(
          userId: 'test_user',
          type: NotificationType.system,
        );

        final marketingPref = await notificationService.getNotificationPreference(
          userId: 'test_user',
          type: NotificationType.marketing,
        );

        // Assert
        expect(systemPref.enabled, isTrue);
        expect(systemPref.deliveryMethod, equals(DeliveryMethod.push));
        expect(marketingPref.enabled, isFalse); // Marketing disabled by default
        expect(marketingPref.deliveryMethod, equals(DeliveryMethod.email));
      });
    });

    group('updateNotificationPreference', () {
      test('should update preference with new values', () async {
        // Arrange
        final userId = 'test_user';
        final type = NotificationType.messages;

        // Act
        final updatedPref = await notificationService.updateNotificationPreference(
          userId: userId,
          type: type,
          enabled: false,
          deliveryMethod: DeliveryMethod.email,
          quietHoursEnabled: true,
          frequency: 2,
        );

        // Assert
        expect(updatedPref.userId, equals(userId));
        expect(updatedPref.type, equals(type));
        expect(updatedPref.enabled, isFalse);
        expect(updatedPref.deliveryMethod, equals(DeliveryMethod.email));
        expect(updatedPref.quietHoursEnabled, isTrue);
        expect(updatedPref.frequency, equals(2));
        expect(updatedPref.updatedAt, isNot(equals(updatedPref.createdAt)));
      });

      test('should keep existing values when not provided', () async {
        // Arrange
        final userId = 'test_user';
        final type = NotificationType.messages;
        final originalPref = await notificationService.getNotificationPreference(userId: userId, type: type);

        // Act
        final updatedPref = await notificationService.updateNotificationPreference(
          userId: userId,
          type: type,
          enabled: false,
        );

        // Assert
        expect(updatedPref.enabled, isFalse);
        expect(updatedPref.deliveryMethod, equals(originalPref.deliveryMethod));
        expect(updatedPref.quietHoursEnabled, equals(originalPref.quietHoursEnabled));
        expect(updatedPref.frequency, equals(originalPref.frequency));
      });
    });

    group('enableNotificationType', () {
      test('should enable notification type with specific delivery method', () async {
        // Act
        final result = await notificationService.enableNotificationType(
          userId: 'test_user',
          type: NotificationType.comments,
          deliveryMethod: DeliveryMethod.inApp,
        );

        // Assert
        expect(result, isTrue);
      });
    });

    group('disableNotificationType', () {
      test('should disable notification type', () async {
        // Act
        final result = await notificationService.disableNotificationType(
          userId: 'test_user',
          type: NotificationType.comments,
        );

        // Assert
        expect(result, isTrue);
      });
    });

    group('updateGlobalNotificationSettings', () {
      test('should return true when updating global settings', () async {
        // Act
        final result = await notificationService.updateGlobalNotificationSettings(
          userId: 'test_user',
          globalEnabled: false,
          soundEnabled: false,
          vibrationEnabled: true,
        );

        // Assert
        expect(result, isTrue);
      });
    });

    group('setupQuietHours', () {
      test('should return true when setting up quiet hours', () async {
        // Arrange
        final startTime = DateTime(2023, 1, 1, 22, 0);
        final endTime = DateTime(2023, 1, 1, 8, 0);

        // Act
        final result = await notificationService.setupQuietHours(
          userId: 'test_user',
          startTime: startTime,
          endTime: endTime,
          enabled: true,
        );

        // Assert
        expect(result, isTrue);
      });
    });

    group('disableQuietHours', () {
      test('should return true when disabling quiet hours', () async {
        // Act
        final result = await notificationService.disableQuietHours('test_user');

        // Assert
        expect(result, isTrue);
      });
    });

    group('isQuietHoursActive', () {
      test('should return false when quiet hours are disabled', () async {
        // Act
        final isActive = await notificationService.isQuietHoursActive('test_user');

        // Assert
        expect(isActive, isFalse);
      });
    });

    group('getNotificationStats', () {
      test('should return notification statistics', () async {
        // Act
        final stats = await notificationService.getNotificationStats('test_user');

        // Assert
        expect(stats, isA<Map<String, dynamic>>());
        expect(stats.containsKey('total_notifications_last_30_days'), isTrue);
        expect(stats.containsKey('unread_notifications'), isTrue);
        expect(stats.containsKey('push_notifications_sent'), isTrue);
        expect(stats.containsKey('email_notifications_sent'), isTrue);
        expect(stats.containsKey('notification_types_enabled'), isTrue);
        expect(stats.containsKey('quiet_hours_enabled'), isTrue);
        expect(stats.containsKey('last_notification_received'), isTrue);
      });

      test('should have valid notification types enabled data', () async {
        // Act
        final stats = await notificationService.getNotificationStats('test_user');

        // Assert
        final enabledTypes = stats['notification_types_enabled'] as Map<String, dynamic>;
        expect(enabledTypes, isA<Map<String, dynamic>>());
        expect(enabledTypes.length, equals(NotificationType.values.length));
      });
    });

    group('testNotification', () {
      test('should return true when testing notification', () async {
        // Act
        final result = await notificationService.testNotification(
          userId: 'test_user',
          type: NotificationType.messages,
          method: DeliveryMethod.push,
        );

        // Assert
        expect(result, isTrue);
      });
    });

    group('markNotificationAsRead', () {
      test('should return true when marking notification as read', () async {
        // Act
        final result = await notificationService.markNotificationAsRead(
          userId: 'test_user',
          notificationId: 'notification_123',
        );

        // Assert
        expect(result, isTrue);
      });
    });

    group('markAllNotificationsAsRead', () {
      test('should return true when marking all notifications as read', () async {
        // Act
        final result = await notificationService.markAllNotificationsAsRead('test_user');

        // Assert
        expect(result, isTrue);
      });
    });

    group('deleteNotification', () {
      test('should return true when deleting notification', () async {
        // Act
        final result = await notificationService.deleteNotification(
          userId: 'test_user',
          notificationId: 'notification_123',
        );

        // Assert
        expect(result, isTrue);
      });
    });

    group('shouldSendNotification', () {
      test('should return false when global notifications are disabled', () {
        // Arrange
        final preference = NotificationPreferenceModel(
          id: 'test_pref',
          userId: 'test_user',
          type: NotificationType.messages,
          enabled: true,
          deliveryMethod: DeliveryMethod.push,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final globalSettings = NotificationSettings(
          preferences: [preference],
          globalEnabled: false,
          soundEnabled: true,
          vibrationEnabled: true,
          ledEnabled: true,
          badgeEnabled: true,
        );

        // Act
        final shouldSend = notificationService.shouldSendNotification(
          preference: preference,
          globalSettings: globalSettings,
        );

        // Assert
        expect(shouldSend, isFalse);
      });

      test('should return false when preference is disabled', () {
        // Arrange
        final preference = NotificationPreferenceModel(
          id: 'test_pref',
          userId: 'test_user',
          type: NotificationType.messages,
          enabled: false,
          deliveryMethod: DeliveryMethod.push,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final globalSettings = NotificationSettings(
          preferences: [preference],
          globalEnabled: true,
          soundEnabled: true,
          vibrationEnabled: true,
          ledEnabled: true,
          badgeEnabled: true,
        );

        // Act
        final shouldSend = notificationService.shouldSendNotification(
          preference: preference,
          globalSettings: globalSettings,
        );

        // Assert
        expect(shouldSend, isFalse);
      });

      test('should return true when all conditions are met', () {
        // Arrange
        final preference = NotificationPreferenceModel(
          id: 'test_pref',
          userId: 'test_user',
          type: NotificationType.messages,
          enabled: true,
          deliveryMethod: DeliveryMethod.push,
          quietHoursEnabled: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final globalSettings = NotificationSettings(
          preferences: [preference],
          globalEnabled: true,
          soundEnabled: true,
          vibrationEnabled: true,
          ledEnabled: true,
          badgeEnabled: true,
        );

        // Act
        final shouldSend = notificationService.shouldSendNotification(
          preference: preference,
          globalSettings: globalSettings,
        );

        // Assert
        expect(shouldSend, isTrue);
      });
    });

    group('Notification Settings Helper Methods', () {
      test('should get preference for specific type', () async {
        // Arrange
        final settings = await notificationService.getNotificationSettings('test_user');

        // Act
        final messagesPref = settings.getPreferenceForType(NotificationType.messages);

        // Assert
        expect(messagesPref, isNotNull);
        expect(messagesPref!.type, equals(NotificationType.messages));
      });

      test('should return null for non-existent preference type', () async {
        // Arrange
        final settings = NotificationSettings(
          preferences: [],
          globalEnabled: true,
          soundEnabled: true,
          vibrationEnabled: true,
          ledEnabled: true,
          badgeEnabled: true,
        );

        // Act
        const nonExistentType = NotificationType.messages;
        final pref = settings.getPreferenceForType(nonExistentType);

        // Assert
        expect(pref, isNull);
      });

      test('should check if notification type is enabled', () async {
        // Arrange
        final settings = await notificationService.getNotificationSettings('test_user');

        // Act & Assert
        expect(settings.isTypeEnabled(NotificationType.system), isTrue);
        expect(settings.isTypeEnabled(NotificationType.marketing), isFalse);
      });

      test('should return false when global notifications are disabled for type check', () async {
        // Arrange
        final settings = NotificationSettings(
          preferences: [
            NotificationPreferenceModel(
              id: 'test_pref',
              userId: 'test_user',
              type: NotificationType.messages,
              enabled: true,
              deliveryMethod: DeliveryMethod.push,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ],
          globalEnabled: false,
          soundEnabled: true,
          vibrationEnabled: true,
          ledEnabled: true,
          badgeEnabled: true,
        );

        // Act
        final isEnabled = settings.isTypeEnabled(NotificationType.messages);

        // Assert
        expect(isEnabled, isFalse);
      });
    });
  });
}