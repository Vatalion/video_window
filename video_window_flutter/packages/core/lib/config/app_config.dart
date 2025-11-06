import 'dart:convert';

import 'package:flutter/services.dart';

import 'environment.dart';

/// Application configuration for a specific environment
class AppConfig {
  final Environment environment;
  final String apiBaseUrl;
  final String serverpodHost;
  final int serverpodPort;
  final bool useHttps;
  final String firebaseProjectId;
  final bool enableAnalytics;
  final bool enableCrashReporting;
  final bool debugMode;

  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.serverpodHost,
    required this.serverpodPort,
    this.useHttps = true,
    required this.firebaseProjectId,
    this.enableAnalytics = true,
    this.enableCrashReporting = true,
    this.debugMode = false,
  });

  /// Load configuration from JSON asset for the current environment
  static Future<AppConfig> load([Environment? env]) async {
    final environment = env ?? Environment.current;
    final configPath = 'assets/config/${environment.name}.json';

    try {
      final jsonString = await rootBundle.loadString(configPath);
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return AppConfig.fromJson(json, environment);
    } catch (e) {
      // Fall back to default dev config if file not found
      return _defaultConfig(environment);
    }
  }

  /// Create from JSON map
  factory AppConfig.fromJson(
      Map<String, dynamic> json, Environment environment) {
    return AppConfig(
      environment: environment,
      apiBaseUrl: json['apiBaseUrl'] as String,
      serverpodHost: json['serverpodHost'] as String,
      serverpodPort: json['serverpodPort'] as int,
      useHttps: json['useHttps'] as bool? ?? true,
      firebaseProjectId: json['firebaseProjectId'] as String,
      enableAnalytics: json['enableAnalytics'] as bool? ?? true,
      enableCrashReporting: json['enableCrashReporting'] as bool? ?? true,
      debugMode: json['debugMode'] as bool? ?? false,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'environment': environment.name,
      'apiBaseUrl': apiBaseUrl,
      'serverpodHost': serverpodHost,
      'serverpodPort': serverpodPort,
      'useHttps': useHttps,
      'firebaseProjectId': firebaseProjectId,
      'enableAnalytics': enableAnalytics,
      'enableCrashReporting': enableCrashReporting,
      'debugMode': debugMode,
    };
  }

  /// Default configuration for each environment
  static AppConfig _defaultConfig(Environment environment) {
    switch (environment) {
      case Environment.dev:
        return const AppConfig(
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
      case Environment.staging:
        return const AppConfig(
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
      case Environment.prod:
        return const AppConfig(
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
    }
  }
}
