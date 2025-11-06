import 'package:core/config/app_config.dart';
import 'package:core/config/environment.dart';
import 'package:core/services/analytics_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AnalyticsService', () {
    late AppConfig enabledConfig;
    late AppConfig disabledConfig;

    setUp(() {
      enabledConfig = AppConfig(
        environment: Environment.dev,
        apiBaseUrl: 'https://api.test.com',
        serverpodHost: 'localhost',
        serverpodPort: 8080,
        useHttps: false,
        firebaseProjectId: 'test-project',
        enableAnalytics: true,
        enableCrashReporting: false,
        debugMode: true,
      );

      disabledConfig = AppConfig(
        environment: Environment.dev,
        apiBaseUrl: 'https://api.test.com',
        serverpodHost: 'localhost',
        serverpodPort: 8080,
        useHttps: false,
        firebaseProjectId: 'test-project',
        enableAnalytics: false,
        enableCrashReporting: false,
        debugMode: true,
      );
    });

    test('tracks events when analytics is enabled', () async {
      final service = AnalyticsService(enabledConfig);

      await service.trackEvent(ScreenViewEvent('home'));

      expect(service.queueSize, 1);
    });

    test('does not track events when analytics is disabled', () async {
      final service = AnalyticsService(disabledConfig);

      await service.trackEvent(ScreenViewEvent('home'));

      expect(service.queueSize, 0);
    });

    test('batches events and flushes at threshold of 10', () async {
      final service = AnalyticsService(enabledConfig);

      // Add 9 events - should not flush
      for (int i = 0; i < 9; i++) {
        await service.trackEvent(ScreenViewEvent('screen_$i'));
      }
      expect(service.queueSize, 9);

      // 10th event should trigger flush
      await service.trackEvent(ScreenViewEvent('screen_9'));
      expect(service.queueSize, 0); // Queue cleared after flush
    });

    test('dispose flushes remaining events', () async {
      final service = AnalyticsService(enabledConfig);

      // Add less than batch threshold
      await service.trackEvent(ScreenViewEvent('home'));
      await service.trackEvent(ScreenViewEvent('profile'));
      expect(service.queueSize, 2);

      // Dispose should flush
      await service.dispose();
      expect(service.queueSize, 0);
    });

    test('throws StateError when tracking after dispose', () async {
      final service = AnalyticsService(enabledConfig);

      await service.dispose();

      expect(
        () => service.trackEvent(ScreenViewEvent('home')),
        throwsStateError,
      );
    });

    test('dispose is idempotent', () async {
      final service = AnalyticsService(enabledConfig);

      await service.trackEvent(ScreenViewEvent('home'));

      await service.dispose();
      await service.dispose(); // Second call should be safe

      expect(service.queueSize, 0);
    });
  });

  group('ScreenViewEvent', () {
    test('has correct name and properties', () {
      final event = ScreenViewEvent('home');

      expect(event.name, 'screen_view');
      expect(event.properties['screen_name'], 'home');
      expect(event.timestamp, isA<DateTime>());
    });

    test('timestamp is captured at creation time', () {
      final before = DateTime.now();
      final event = ScreenViewEvent('home');
      final after = DateTime.now();

      expect(
          event.timestamp.isAfter(before) ||
              event.timestamp.isAtSameMomentAs(before),
          isTrue);
      expect(
          event.timestamp.isBefore(after) ||
              event.timestamp.isAtSameMomentAs(after),
          isTrue);
    });
  });

  group('UserActionEvent', () {
    test('has correct name and properties without context', () {
      final event = UserActionEvent('button_tap');

      expect(event.name, 'user_action');
      expect(event.properties['action'], 'button_tap');
      expect(event.timestamp, isA<DateTime>());
    });

    test('merges context into properties', () {
      final event = UserActionEvent(
        'make_offer',
        context: {
          'story_id': '123',
          'amount': 50.0,
        },
      );

      expect(event.properties['action'], 'make_offer');
      expect(event.properties['story_id'], '123');
      expect(event.properties['amount'], 50.0);
    });

    test('timestamp is captured at creation time', () {
      final before = DateTime.now();
      final event = UserActionEvent('test');
      final after = DateTime.now();

      expect(
          event.timestamp.isAfter(before) ||
              event.timestamp.isAtSameMomentAs(before),
          isTrue);
      expect(
          event.timestamp.isBefore(after) ||
              event.timestamp.isAtSameMomentAs(after),
          isTrue);
    });
  });
}
