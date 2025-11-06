# Configuration Management & Feature Flags

## Overview

The Video Window app uses a multi-tier configuration system supporting environment-specific configs and runtime feature flags.

## Environment Configuration

### Environments

Three environments supported:
- **dev**: Local development
- **staging**: Pre-production testing  
- **prod**: Production

### Usage

```dart
import 'package:core/config/environment.dart';

final env = Environment.current;
if (env.isDev) {
  // Development-specific code
}
```

### Configuration Files

Located in `assets/config/{environment}.json`:
- `dev.json` - Development settings
- `staging.json` - Staging settings
- `prod.json` - Production settings

### App Config

```dart
import 'package:core/config/app_config.dart';

final config = await AppConfig.load();
print(config.apiBaseUrl);
print(config.serverpodHost);
```

## Feature Flags

### Available Flags

Defined in `FeatureFlags` class:
- `social_login_enabled` - Social authentication
- `biometric_auth_enabled` - Biometric unlock
- `video_editing_enabled` - In-app video editing
- `auction_enabled` - Auction functionality
- `push_notifications_enabled` - Push notifications

### Usage

```dart
import 'package:core/services/feature_flags_service.dart';

// Check if feature is enabled
final service = LocalFeatureFlagsService();
await service.initialize();

if (await service.isEnabled(FeatureFlags.socialLoginEnabled)) {
  // Show social login options
}
```

### Testing with Overrides

```dart
// Override flag for testing
await service.setOverride(FeatureFlags.socialLoginEnabled, true);

// Clear override
await service.clearOverride(FeatureFlags.socialLoginEnabled);

// Clear all overrides
await service.clearAllOverrides();
```

### Remote Config (Firebase)

```dart
import 'package:core/services/remote_config_service.dart';

// Use remote config service
final service = RemoteFeatureFlagsService();
await service.initialize();

// Flags automatically fetched from Firebase
// Falls back to defaults if fetch fails
```

## ConfigService

Unified service combining environment config and feature flags:

```dart
import 'package:core/services/config_service.dart';

final config = await ConfigService.initialize();

// Environment info
print(config.environment);
print(config.apiBaseUrl);

// Feature flags
if (await config.isAuctionEnabled) {
  // Show auction features
}

// Refresh flags
await config.refreshFeatureFlags();
```

## Adding New Flags

1. Add flag constant to `FeatureFlags` class:
```dart
static const String myNewFeature = 'my_new_feature_enabled';
```

2. Add default value:
```dart
static const Map<String, bool> defaults = {
  // ...
  myNewFeature: false,
};
```

3. Add convenience getter to `ConfigService` (optional):
```dart
Future<bool> get isMyNewFeatureEnabled =>
    isFeatureEnabled(FeatureFlags.myNewFeature);
```

4. Configure in Firebase Remote Config console

## Best Practices

1. **Always provide defaults** - App must work offline
2. **Use const for flag keys** - Prevent typos
3. **Document flag purpose** - Add comments explaining each flag
4. **Test both states** - Verify behavior when flag is on/off
5. **Gradual rollouts** - Use remote config percentages for new features

## Architecture

```
ConfigService (unified interface)
├── AppConfig (environment configuration)
│   ├── Load from JSON files
│   └── Fallback to defaults
└── FeatureFlagsService (feature flags)
    ├── LocalFeatureFlagsService (shared_preferences)
    └── RemoteFeatureFlagsService (Firebase Remote Config)
        ├── Fetch from Firebase
        ├── Cache locally
        └── Fallback to defaults
```

## Priority Order

Feature flag resolution order (highest to lowest):
1. Local override (testing)
2. Firebase Remote Config (if available)
3. Cached value
4. Default value

