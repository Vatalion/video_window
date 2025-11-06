import 'package:core/config/app_config.dart';
import 'package:core/config/environment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Environment', () {
    test('isDev returns true for dev environment', () {
      const env = Environment.dev;
      expect(env.isDev, isTrue);
      expect(env.isStaging, isFalse);
      expect(env.isProd, isFalse);
    });

    test('isStaging returns true for staging environment', () {
      const env = Environment.staging;
      expect(env.isStaging, isTrue);
      expect(env.isDev, isFalse);
      expect(env.isProd, isFalse);
    });

    test('isProd returns true for prod environment', () {
      const env = Environment.prod;
      expect(env.isProd, isTrue);
      expect(env.isDev, isFalse);
      expect(env.isStaging, isFalse);
    });

    test('displayName returns correct name for each environment', () {
      expect(Environment.dev.displayName, equals('Development'));
      expect(Environment.staging.displayName, equals('Staging'));
      expect(Environment.prod.displayName, equals('Production'));
    });
  });

  group('AppConfig', () {
    test('dev config has correct values', () {
      const config = AppConfig(
        environment: Environment.dev,
        apiBaseUrl: 'http://localhost:8080',
        serverpodHost: 'localhost',
        serverpodPort: 8080,
        useHttps: false,
        firebaseProjectId: 'video-window-dev',
        enableAnalytics: false,
        enableCrashReporting: false,
        debugMode: true,
      );

      expect(config.environment, equals(Environment.dev));
      expect(config.apiBaseUrl, equals('http://localhost:8080'));
      expect(config.serverpodHost, equals('localhost'));
      expect(config.serverpodPort, equals(8080));
      expect(config.useHttps, isFalse);
      expect(config.debugMode, isTrue);
      expect(config.enableAnalytics, isFalse);
    });

    test('staging config has correct values', () {
      const config = AppConfig(
        environment: Environment.staging,
        apiBaseUrl: 'https://staging-api.videowindow.app',
        serverpodHost: 'staging-api.videowindow.app',
        serverpodPort: 443,
        useHttps: true,
        firebaseProjectId: 'video-window-staging',
        enableAnalytics: true,
        enableCrashReporting: true,
        debugMode: true,
      );

      expect(config.environment, equals(Environment.staging));
      expect(config.apiBaseUrl, equals('https://staging-api.videowindow.app'));
      expect(config.serverpodHost, equals('staging-api.videowindow.app'));
      expect(config.serverpodPort, equals(443));
      expect(config.useHttps, isTrue);
      expect(config.debugMode, isTrue);
      expect(config.enableAnalytics, isTrue);
    });

    test('prod config has correct values', () {
      const config = AppConfig(
        environment: Environment.prod,
        apiBaseUrl: 'https://api.videowindow.app',
        serverpodHost: 'api.videowindow.app',
        serverpodPort: 443,
        useHttps: true,
        firebaseProjectId: 'video-window-prod',
        enableAnalytics: true,
        enableCrashReporting: true,
        debugMode: false,
      );

      expect(config.environment, equals(Environment.prod));
      expect(config.apiBaseUrl, equals('https://api.videowindow.app'));
      expect(config.serverpodHost, equals('api.videowindow.app'));
      expect(config.serverpodPort, equals(443));
      expect(config.useHttps, isTrue);
      expect(config.debugMode, isFalse);
      expect(config.enableCrashReporting, isTrue);
    });

    test('fromJson creates correct config', () {
      final json = {
        'apiBaseUrl': 'https://test.example.com',
        'serverpodHost': 'test.example.com',
        'serverpodPort': 8443,
        'useHttps': true,
        'firebaseProjectId': 'test-project',
        'enableAnalytics': false,
        'enableCrashReporting': false,
        'debugMode': true,
      };

      final config = AppConfig.fromJson(json, Environment.dev);

      expect(config.apiBaseUrl, equals('https://test.example.com'));
      expect(config.serverpodHost, equals('test.example.com'));
      expect(config.serverpodPort, equals(8443));
      expect(config.useHttps, isTrue);
      expect(config.firebaseProjectId, equals('test-project'));
      expect(config.enableAnalytics, isFalse);
      expect(config.debugMode, isTrue);
    });

    test('toJson serializes config correctly', () {
      const config = AppConfig(
        environment: Environment.dev,
        apiBaseUrl: 'https://test.com',
        serverpodHost: 'test.com',
        serverpodPort: 443,
        useHttps: true,
        firebaseProjectId: 'test-proj',
        enableAnalytics: true,
        enableCrashReporting: false,
        debugMode: false,
      );

      final json = config.toJson();

      expect(json['environment'], equals('dev'));
      expect(json['apiBaseUrl'], equals('https://test.com'));
      expect(json['serverpodHost'], equals('test.com'));
      expect(json['serverpodPort'], equals(443));
      expect(json['useHttps'], isTrue);
      expect(json['firebaseProjectId'], equals('test-proj'));
    });
  });
}
