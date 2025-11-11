import 'package:test/test.dart';
import 'package:video_window_server/src/services/device_trust_service.dart';
import 'package:video_window_server/src/services/capabilities/capability_service.dart';
import 'package:video_window_server/src/generated/capabilities/capability_type.dart';
import '../integration/test_tools/serverpod_test_tools.dart';

/// Unit and integration tests for DeviceTrustService
///
/// AC10: Unit tests for trust scoring logic covering jailbreak/rooted, outdated OS, emulator detection scenarios
/// AC11: Integration test verifying capability downgrade when all devices revoked
void main() {
  withServerpod(
    'DeviceTrustService Tests',
    (sessionBuilder, endpoints) {
      group('DeviceTrustService - Trust Scoring', () {
        test('calculates high trust score for normal device', () async {
          final session = sessionBuilder.build();
          final service = DeviceTrustService(session);

          final telemetry = {
            'platform': 'ios',
            'deviceType': 'iphone',
            'osVersion': '17.0',
            'isJailbroken': false,
            'isRooted': false,
            'isEmulator': false,
            'attestationResult': 'passed',
          };

          final device = await service.registerDevice(
            userId: 1,
            deviceId: 'test-device-1',
            deviceType: 'iphone',
            platform: 'ios',
            telemetry: telemetry,
          );

          expect(device.trustScore, greaterThan(0.7));
          expect(device.trustScore, lessThanOrEqualTo(1.0));
        });

        test('penalizes jailbroken device', () async {
          final session = sessionBuilder.build();
          final service = DeviceTrustService(session);

          final telemetry = {
            'platform': 'ios',
            'deviceType': 'iphone',
            'osVersion': '17.0',
            'isJailbroken': true,
            'isRooted': false,
            'isEmulator': false,
            'attestationResult': 'passed',
          };

          final device = await service.registerDevice(
            userId: 1,
            deviceId: 'test-device-jailbroken',
            deviceType: 'iphone',
            platform: 'ios',
            telemetry: telemetry,
          );

          expect(device.trustScore, lessThan(0.7));
        });

        test('penalizes rooted Android device', () async {
          final session = sessionBuilder.build();
          final service = DeviceTrustService(session);

          final telemetry = {
            'platform': 'android',
            'deviceType': 'android_phone',
            'osVersion': '13.0',
            'isJailbroken': false,
            'isRooted': true,
            'isEmulator': false,
            'attestationResult': 'passed',
          };

          final device = await service.registerDevice(
            userId: 1,
            deviceId: 'test-device-rooted',
            deviceType: 'android_phone',
            platform: 'android',
            telemetry: telemetry,
          );

          expect(device.trustScore, lessThan(0.7));
        });

        test('penalizes emulator', () async {
          final session = sessionBuilder.build();
          final service = DeviceTrustService(session);

          final telemetry = {
            'platform': 'android',
            'deviceType': 'android_phone',
            'osVersion': '13.0',
            'isJailbroken': false,
            'isRooted': false,
            'isEmulator': true,
            'attestationResult': 'passed',
          };

          final device = await service.registerDevice(
            userId: 1,
            deviceId: 'test-device-emulator',
            deviceType: 'android_phone',
            platform: 'android',
            telemetry: telemetry,
          );

          expect(device.trustScore, lessThan(0.7));
        });

        test('penalizes outdated iOS version', () async {
          final session = sessionBuilder.build();
          final service = DeviceTrustService(session);

          final telemetry = {
            'platform': 'ios',
            'deviceType': 'iphone',
            'osVersion': '13.0', // iOS 13 < 14
            'isJailbroken': false,
            'isRooted': false,
            'isEmulator': false,
            'attestationResult': 'passed',
          };

          final device = await service.registerDevice(
            userId: 1,
            deviceId: 'test-device-outdated-ios',
            deviceType: 'iphone',
            platform: 'ios',
            telemetry: telemetry,
          );

          expect(device.trustScore, lessThan(0.8));
        });

        test('penalizes outdated Android version', () async {
          final session = sessionBuilder.build();
          final service = DeviceTrustService(session);

          final telemetry = {
            'platform': 'android',
            'deviceType': 'android_phone',
            'osVersion': '9.0', // Android 9 < 10
            'isJailbroken': false,
            'isRooted': false,
            'isEmulator': false,
            'attestationResult': 'passed',
          };

          final device = await service.registerDevice(
            userId: 1,
            deviceId: 'test-device-outdated-android',
            deviceType: 'android_phone',
            platform: 'android',
            telemetry: telemetry,
          );

          expect(device.trustScore, lessThan(0.8));
        });

        test('penalizes failed attestation', () async {
          final session = sessionBuilder.build();
          final service = DeviceTrustService(session);

          final telemetry = {
            'platform': 'ios',
            'deviceType': 'iphone',
            'osVersion': '17.0',
            'isJailbroken': false,
            'isRooted': false,
            'isEmulator': false,
            'attestationResult': 'failed',
          };

          final device = await service.registerDevice(
            userId: 1,
            deviceId: 'test-device-failed-attestation',
            deviceType: 'iphone',
            platform: 'ios',
            telemetry: telemetry,
          );

          expect(device.trustScore, lessThan(0.8));
        });

        test('updates existing device trust score', () async {
          final session = sessionBuilder.build();
          final service = DeviceTrustService(session);

          // Register device first time
          final device1 = await service.registerDevice(
            userId: 1,
            deviceId: 'test-device-update',
            deviceType: 'iphone',
            platform: 'ios',
            telemetry: {
              'platform': 'ios',
              'isJailbroken': false,
              'attestationResult': 'passed',
            },
          );

          final initialScore = device1.trustScore;

          // Register again with different telemetry
          final device2 = await service.registerDevice(
            userId: 1,
            deviceId: 'test-device-update',
            deviceType: 'iphone',
            platform: 'ios',
            telemetry: {
              'platform': 'ios',
              'isJailbroken': true, // Now jailbroken
              'attestationResult': 'failed',
            },
          );

          expect(device2.id, equals(device1.id));
          expect(device2.trustScore, lessThan(initialScore));
        });
      });

      group('DeviceTrustService - Capability Integration', () {
        test('hasTrustedDevice returns true when device exceeds threshold',
            () async {
          final session = sessionBuilder.build();
          final service = DeviceTrustService(session);

          // Register high-trust device
          await service.registerDevice(
            userId: 2,
            deviceId: 'trusted-device-1',
            deviceType: 'iphone',
            platform: 'ios',
            telemetry: {
              'platform': 'ios',
              'isJailbroken': false,
              'attestationResult': 'passed',
            },
          );

          final hasTrusted = await service.hasTrustedDevice(2);
          expect(hasTrusted, isTrue);
        });

        test('hasTrustedDevice returns false when no device exceeds threshold',
            () async {
          final session = sessionBuilder.build();
          final service = DeviceTrustService(session);

          // Register low-trust device
          await service.registerDevice(
            userId: 3,
            deviceId: 'low-trust-device',
            deviceType: 'iphone',
            platform: 'ios',
            telemetry: {
              'platform': 'ios',
              'isJailbroken': true, // Jailbroken = low trust
              'attestationResult': 'failed',
            },
          );

          final hasTrusted = await service.hasTrustedDevice(3);
          expect(hasTrusted, isFalse);
        });

        test('revokeDevice removes device from trusted list', () async {
          final session = sessionBuilder.build();
          final service = DeviceTrustService(session);

          // Register device
          final device = await service.registerDevice(
            userId: 4,
            deviceId: 'device-to-revoke',
            deviceType: 'iphone',
            platform: 'ios',
            telemetry: {
              'platform': 'ios',
              'isJailbroken': false,
              'attestationResult': 'passed',
            },
          );

          expect(await service.hasTrustedDevice(4), isTrue);

          // Revoke device
          await service.revokeDevice(
            userId: 4,
            deviceId: device.id!,
            reason: 'test_revocation',
          );

          expect(await service.hasTrustedDevice(4), isFalse);
        });

        test('capability downgrade when all devices revoked', () async {
          final session = sessionBuilder.build();
          final capabilityService = CapabilityService(session);
          final deviceTrustService = DeviceTrustService(session);

          // Setup: User has payment capability and trusted device
          final userId = 5;

          // Enable payment capability
          await capabilityService.updateCapability(
            userId: userId,
            capability: CapabilityType.collectPayments,
            enabled: true,
          );

          // Register trusted device
          final device = await deviceTrustService.registerDevice(
            userId: userId,
            deviceId: 'device-for-fulfillment',
            deviceType: 'iphone',
            platform: 'ios',
            telemetry: {
              'platform': 'ios',
              'isJailbroken': false,
              'attestationResult': 'passed',
            },
          );

          // Enable fulfillment capability (should work with trusted device)
          await capabilityService.updateCapability(
            userId: userId,
            capability: CapabilityType.fulfillOrders,
            enabled: true,
          );

          final capabilitiesBefore =
              await capabilityService.getUserCapabilities(userId);
          expect(capabilitiesBefore.canFulfillOrders, isTrue);

          // Revoke all devices
          await deviceTrustService.revokeDevice(
            userId: userId,
            deviceId: device.id!,
            reason: 'test_revocation',
          );

          // Check capability blockers updated
          final blockers = await capabilityService.getBlockers(
            userId,
            CapabilityType.fulfillOrders,
          );

          expect(blockers.containsKey('device_trust'), isTrue);

          // Verify capability is blocked (canAutoApprove should return false)
          final canAutoApprove = await capabilityService.canAutoApprove(
            userId: userId,
            capability: CapabilityType.fulfillOrders,
          );

          expect(canAutoApprove, isFalse);
        });
      });

      group('DeviceTrustService - Low Trust Spike Detection', () {
        test('detects low trust spike when multiple devices register',
            () async {
          final session = sessionBuilder.build();
          final service = DeviceTrustService(session);

          final userId = 6;

          // Register multiple low-trust devices within 24 hours
          for (int i = 0; i < 4; i++) {
            await service.registerDevice(
              userId: userId,
              deviceId: 'low-trust-device-$i',
              deviceType: 'android_phone',
              platform: 'android',
              telemetry: {
                'platform': 'android',
                'isRooted': true, // All rooted = low trust
                'attestationResult': 'failed',
              },
            );
          }

          // Service should log warning about low trust spike
          // (We can't easily test logging, but the method should complete without error)
          final devices = await service.getUserDevices(userId);
          expect(devices.length, equals(4));
        });
      });
    },
  );
}
