import 'package:flutter_test/flutter_test.dart';
import 'package:core/services/feature_flags_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FeatureFlags', () {
    test('has expected default values', () {
      expect(FeatureFlags.defaults[FeatureFlags.socialLoginEnabled], isFalse);
      expect(FeatureFlags.defaults[FeatureFlags.videoEditingEnabled], isTrue);
      expect(FeatureFlags.defaults[FeatureFlags.auctionEnabled], isTrue);
      expect(FeatureFlags.defaults[FeatureFlags.analyticsEnabled], isTrue);
    });

    test('all flags have default values', () {
      const expectedFlags = [
        'social_login_enabled',
        'biometric_auth_enabled',
        'video_editing_enabled',
        'advanced_filters_enabled',
        'auction_enabled',
        'instant_buy_enabled',
        'push_notifications_enabled',
        'analytics_enabled',
        'crash_reporting_enabled',
      ];

      for (final flag in expectedFlags) {
        expect(FeatureFlags.defaults.containsKey(flag), isTrue,
            reason: 'Flag $flag should have a default value');
      }
    });
  });

  group('LocalFeatureFlagsService', () {
    late LocalFeatureFlagsService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      service = LocalFeatureFlagsService();
      await service.initialize();
    });

    test('isEnabled returns default value for new flag', () async {
      final enabled = await service.isEnabled(FeatureFlags.socialLoginEnabled);
      expect(enabled, equals(FeatureFlags.defaults[FeatureFlags.socialLoginEnabled]));
    });

    test('setOverride changes flag value', () async {
      // Default is false
      expect(await service.isEnabled(FeatureFlags.socialLoginEnabled), isFalse);

      // Set override to true
      await service.setOverride(FeatureFlags.socialLoginEnabled, true);
      expect(await service.isEnabled(FeatureFlags.socialLoginEnabled), isTrue);
    });

    test('clearOverride restores default value', () async {
      // Set override
      await service.setOverride(FeatureFlags.socialLoginEnabled, true);
      expect(await service.isEnabled(FeatureFlags.socialLoginEnabled), isTrue);

      // Clear override
      await service.clearOverride(FeatureFlags.socialLoginEnabled);
      expect(await service.isEnabled(FeatureFlags.socialLoginEnabled), isFalse);
    });

    test('clearAllOverrides clears all overrides', () async {
      // Set multiple overrides
      await service.setOverride(FeatureFlags.socialLoginEnabled, true);
      await service.setOverride(FeatureFlags.auctionEnabled, false);

      // Clear all
      await service.clearAllOverrides();

      // Should return to defaults
      expect(await service.isEnabled(FeatureFlags.socialLoginEnabled), isFalse);
      expect(await service.isEnabled(FeatureFlags.auctionEnabled), isTrue);
    });

    test('getAllFlags returns all flags', () async {
      final flags = await service.getAllFlags();
      
      expect(flags.length, equals(FeatureFlags.defaults.length));
      expect(flags, containsPair(FeatureFlags.socialLoginEnabled, isFalse));
      expect(flags, containsPair(FeatureFlags.videoEditingEnabled, isTrue));
    });

    test('fetch reloads cached flags', () async {
      await service.fetch();
      final enabled = await service.isEnabled(FeatureFlags.videoEditingEnabled);
      expect(enabled, isTrue);
    });
  });
}
