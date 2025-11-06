import '../config/app_config.dart';
import '../config/environment.dart';
import 'feature_flags_service.dart';

/// Unified configuration service providing access to
/// environment config and feature flags
class ConfigService {
  final AppConfig appConfig;
  final FeatureFlagsService featureFlagsService;

  ConfigService({
    required this.appConfig,
    required this.featureFlagsService,
  });

  /// Create and initialize config service
  static Future<ConfigService> initialize({
    Environment? environment,
    FeatureFlagsService? featureFlagsService,
  }) async {
    // Load app config
    final appConfig = await AppConfig.load(environment);

    // Initialize feature flags service
    final flagsService = featureFlagsService ?? LocalFeatureFlagsService();
    await flagsService.initialize();

    return ConfigService(
      appConfig: appConfig,
      featureFlagsService: flagsService,
    );
  }

  // Environment accessors
  Environment get environment => appConfig.environment;
  bool get isDev => appConfig.environment.isDev;
  bool get isStaging => appConfig.environment.isStaging;
  bool get isProd => appConfig.environment.isProd;

  // App config accessors
  String get apiBaseUrl => appConfig.apiBaseUrl;
  String get serverpodHost => appConfig.serverpodHost;
  int get serverpodPort => appConfig.serverpodPort;
  bool get useHttps => appConfig.useHttps;
  String get firebaseProjectId => appConfig.firebaseProjectId;
  bool get enableAnalytics => appConfig.enableAnalytics;
  bool get enableCrashReporting => appConfig.enableCrashReporting;
  bool get debugMode => appConfig.debugMode;

  // Feature flag accessors
  Future<bool> isFeatureEnabled(String flagKey) =>
      featureFlagsService.isEnabled(flagKey);

  Future<Map<String, bool>> getAllFeatureFlags() =>
      featureFlagsService.getAllFlags();

  // Convenience methods for common feature flags
  Future<bool> get isSocialLoginEnabled =>
      isFeatureEnabled(FeatureFlags.socialLoginEnabled);

  Future<bool> get isBiometricAuthEnabled =>
      isFeatureEnabled(FeatureFlags.biometricAuthEnabled);

  Future<bool> get isVideoEditingEnabled =>
      isFeatureEnabled(FeatureFlags.videoEditingEnabled);

  Future<bool> get isAdvancedFiltersEnabled =>
      isFeatureEnabled(FeatureFlags.advancedFiltersEnabled);

  Future<bool> get isAuctionEnabled =>
      isFeatureEnabled(FeatureFlags.auctionEnabled);

  Future<bool> get isInstantBuyEnabled =>
      isFeatureEnabled(FeatureFlags.instantBuyEnabled);

  Future<bool> get isPushNotificationsEnabled =>
      isFeatureEnabled(FeatureFlags.pushNotificationsEnabled);

  Future<bool> get isAnalyticsEnabled =>
      isFeatureEnabled(FeatureFlags.analyticsEnabled);

  Future<bool> get isCrashReportingEnabled =>
      isFeatureEnabled(FeatureFlags.crashReportingEnabled);

  /// Refresh feature flags from remote source
  Future<void> refreshFeatureFlags() => featureFlagsService.fetch();

  /// Set local override for a feature flag (testing only)
  Future<void> setFeatureFlagOverride(String flagKey, bool value) =>
      featureFlagsService.setOverride(flagKey, value);

  /// Clear all feature flag overrides (testing only)
  Future<void> clearAllOverrides() => featureFlagsService.clearAllOverrides();
}
