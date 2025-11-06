import 'package:firebase_remote_config/firebase_remote_config.dart';

import 'feature_flags_service.dart';

/// Remote feature flags service using Firebase Remote Config
class RemoteFeatureFlagsService extends LocalFeatureFlagsService {
  final FirebaseRemoteConfig _remoteConfig;
  DateTime? _lastFetchTime;
  static const Duration _fetchInterval = Duration(hours: 1);

  RemoteFeatureFlagsService({
    FirebaseRemoteConfig? remoteConfig,
  }) : _remoteConfig = remoteConfig ?? FirebaseRemoteConfig.instance;

  /// Initialize Remote Config with defaults
  @override
  Future<void> initialize() async {
    await super.initialize();

    try {
      // Set config settings
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: _fetchInterval,
        ),
      );

      // Set default values
      await _remoteConfig.setDefaults(
        FeatureFlags.defaults.map((key, value) => MapEntry(key, value)),
      );

      // Attempt initial fetch without blocking
      fetch().catchError((error) {
        // Log error but don't throw - app should work with defaults
        return;
      });
    } catch (e) {
      // If Firebase isn't configured, fall back to local-only mode
      // This allows the app to work without Firebase
    }
  }

  @override
  Future<void> fetch() async {
    // Check if we need to fetch (respect rate limiting)
    if (_lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _fetchInterval) {
      return;
    }

    try {
      // Fetch and activate in one call
      await _remoteConfig.fetchAndActivate();
      _lastFetchTime = DateTime.now();

      // Update local cache with remote values
      for (final flagKey in FeatureFlags.defaults.keys) {
        final value = _remoteConfig.getBool(flagKey);
        await updateFlag(flagKey, value);
      }

      // Reload cached flags
      await loadCachedFlags();
    } catch (e) {
      // If fetch fails, continue with cached/default values
      // This ensures offline functionality
      await super.fetch();
    }
  }

  @override
  Future<bool> isEnabled(String flagKey) async {
    await ensureInitialized();

    // Check for local override first (highest priority)
    final overrideKey = '${LocalFeatureFlagsService.overridePrefix}$flagKey';
    final override = prefs?.getBool(overrideKey);
    if (override != null) {
      return override;
    }

    // Try to get from remote config (if available)
    try {
      final remoteValue = _remoteConfig.getBool(flagKey);
      return remoteValue;
    } catch (e) {
      // Fall back to cached/default value
      return super.isEnabled(flagKey);
    }
  }

  /// Get the source of a flag value (for debugging)
  Future<String> getFlagSource(String flagKey) async {
    await ensureInitialized();

    // Check override
    final overrideKey = '${LocalFeatureFlagsService.overridePrefix}$flagKey';
    if (prefs?.containsKey(overrideKey) == true) {
      return 'override';
    }

    // Check remote config
    try {
      final source = _remoteConfig.getValue(flagKey).source;
      switch (source) {
        case ValueSource.valueRemote:
          return 'remote';
        case ValueSource.valueStatic:
          return 'default';
        case ValueSource.valueDefault:
          return 'default';
      }
    } catch (e) {
      // Fall through to cached check
    }

    // Check cached
    if (cachedFlags.containsKey(flagKey)) {
      return 'cached';
    }

    return 'default';
  }
}
