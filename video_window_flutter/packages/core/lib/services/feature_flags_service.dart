import 'package:shared_preferences/shared_preferences.dart';

/// Feature flag keys used throughout the app
class FeatureFlags {
  // Authentication features
  static const String socialLoginEnabled = 'social_login_enabled';
  static const String biometricAuthEnabled = 'biometric_auth_enabled';

  // Video features
  static const String videoEditingEnabled = 'video_editing_enabled';
  static const String advancedFiltersEnabled = 'advanced_filters_enabled';

  // Commerce features
  static const String auctionEnabled = 'auction_enabled';
  static const String instantBuyEnabled = 'instant_buy_enabled';

  // Platform features
  static const String pushNotificationsEnabled = 'push_notifications_enabled';
  static const String analyticsEnabled = 'analytics_enabled';
  static const String crashReportingEnabled = 'crash_reporting_enabled';

  // Feed performance features
  static const String feedPerformanceMonitoring = 'feed_performance_monitoring';

  /// All available feature flags with their default values
  static const Map<String, bool> defaults = {
    socialLoginEnabled: false,
    biometricAuthEnabled: false,
    videoEditingEnabled: true,
    advancedFiltersEnabled: false,
    auctionEnabled: true,
    instantBuyEnabled: false,
    pushNotificationsEnabled: true,
    analyticsEnabled: true,
    crashReportingEnabled: true,
    feedPerformanceMonitoring:
        false, // AC1: Disabled by default, enable via feature flag
  };
}

/// Service for managing feature flags
abstract class FeatureFlagsService {
  /// Check if a feature flag is enabled
  Future<bool> isEnabled(String flagKey);

  /// Get all feature flags
  Future<Map<String, bool>> getAllFlags();

  /// Set local override for a feature flag (for testing)
  Future<void> setOverride(String flagKey, bool value);

  /// Clear local override for a feature flag
  Future<void> clearOverride(String flagKey);

  /// Clear all local overrides
  Future<void> clearAllOverrides();

  /// Refresh flags from remote source
  Future<void> fetch();

  /// Initialize the service
  Future<void> initialize();
}

/// Local implementation of feature flags using SharedPreferences
class LocalFeatureFlagsService implements FeatureFlagsService {
  static const String overridePrefix = 'feature_flag_override_';
  static const String flagPrefix = 'feature_flag_';

  SharedPreferences? prefs;
  Map<String, bool> cachedFlags = {};

  @override
  Future<void> initialize() async {
    prefs = await SharedPreferences.getInstance();
    await loadCachedFlags();
  }

  /// Load cached flags from SharedPreferences
  Future<void> loadCachedFlags() async {
    cachedFlags = Map.from(FeatureFlags.defaults);

    // Load any stored flags
    final keys = prefs?.getKeys() ?? {};
    for (final key in keys) {
      if (key.startsWith(flagPrefix) && !key.startsWith(overridePrefix)) {
        final flagKey = key.replaceFirst(flagPrefix, '');
        final value = prefs?.getBool(key);
        if (value != null) {
          cachedFlags[flagKey] = value;
        }
      }
    }
  }

  @override
  Future<bool> isEnabled(String flagKey) async {
    await ensureInitialized();

    // Check for override first
    final overrideKey = '$overridePrefix$flagKey';
    final override = prefs?.getBool(overrideKey);
    if (override != null) {
      return override;
    }

    // Return cached value or default
    return cachedFlags[flagKey] ?? FeatureFlags.defaults[flagKey] ?? false;
  }

  @override
  Future<Map<String, bool>> getAllFlags() async {
    await ensureInitialized();

    final result = <String, bool>{};
    for (final entry in FeatureFlags.defaults.entries) {
      result[entry.key] = await isEnabled(entry.key);
    }
    return result;
  }

  @override
  Future<void> setOverride(String flagKey, bool value) async {
    await ensureInitialized();
    await prefs?.setBool('$overridePrefix$flagKey', value);
  }

  @override
  Future<void> clearOverride(String flagKey) async {
    await ensureInitialized();
    await prefs?.remove('$overridePrefix$flagKey');
  }

  @override
  Future<void> clearAllOverrides() async {
    await ensureInitialized();
    final keys = prefs?.getKeys() ?? {};
    for (final key in keys) {
      if (key.startsWith(overridePrefix)) {
        await prefs?.remove(key);
      }
    }
  }

  @override
  Future<void> fetch() async {
    // Local implementation doesn't fetch from remote
    // This will be overridden by RemoteFeatureFlagsService
    await loadCachedFlags();
  }

  /// Update a flag value in cache and storage
  Future<void> updateFlag(String flagKey, bool value) async {
    await ensureInitialized();
    cachedFlags[flagKey] = value;
    await prefs?.setBool('$flagPrefix$flagKey', value);
  }

  Future<void> ensureInitialized() async {
    if (prefs == null) {
      await initialize();
    }
  }
}
