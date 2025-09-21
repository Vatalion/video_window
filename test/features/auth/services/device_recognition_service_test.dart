import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:ui' as ui;
import 'package:video_window/features/auth/data/services/device_recognition_service.dart';
import 'package:video_window/features/auth/domain/models/device_model.dart';

class MockDeviceInfoPlugin extends Mock implements DeviceInfoPlugin {}

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

class MockPackageInfo extends Mock implements PackageInfo {}

void main() {
  late DeviceRecognitionService deviceService;
  late MockDeviceInfoPlugin mockDeviceInfoPlugin;
  late MockFlutterSecureStorage mockStorage;
  late MockPackageInfo mockPackageInfo;

  setUp(() {
    mockDeviceInfoPlugin = MockDeviceInfoPlugin();
    mockStorage = MockFlutterSecureStorage();
    mockPackageInfo = MockPackageInfo();

    // Setup default package info
    when(() => mockPackageInfo.version).thenReturn('1.0.0');
    when(() => mockPackageInfo.buildNumber).thenReturn('1');

    deviceService = DeviceRecognitionService(
      mockDeviceInfoPlugin,
      mockStorage,
      mockPackageInfo,
    );
  });

  group('DeviceRecognitionService', () {
    test('getCurrentDeviceInfo should create device info for Android device', () async {
      // Arrange
      const testDeviceId = 'test-android-id';
      final androidInfo = AndroidDeviceInfo(
        id: testDeviceId,
        androidId: testDeviceId,
        board: 'test-board',
        bootloader: 'test-bootloader',
        brand: 'test-brand',
        device: 'test-device',
        display: 'test-display',
        fingerprint: 'test-fingerprint',
        hardware: 'test-hardware',
        host: 'test-host',
        isAdbEnabled: true,
        isDebugMode: false,
        isEmulator: false,
        isPhysicalDevice: true,
        manufacturer: 'Test Manufacturer',
        model: 'Test Model',
        product: 'test-product',
        supported32BitAbis: ['arm32'],
        supported64BitAbis: ['arm64'],
        supportedAbis: ['arm32', 'arm64'],
        systemFeatures: ['feature1'],
        tags: 'test-tags',
        type: 'user',
        versionAndroidSdkInt: 31,
        versionBaseOS: 'test-base-os',
        versionCodename: 'test-codename',
        versionIncremental: 'test-incremental',
        versionPreviewSdkInt: 0,
        versionRelease: '12',
        versionSecurityPatch: '2023-01-01',
      );

      when(() => mockDeviceInfoPlugin.deviceInfo)
          .thenAnswer((_) async => androidInfo);
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);
      when(() => mockStorage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      )).thenAnswer((_) async {});

      // Act
      final deviceInfo = await deviceService.getCurrentDeviceInfo();

      // Assert
      expect(deviceInfo.deviceId, equals(testDeviceId));
      expect(deviceInfo.platform, equals('Android'));
      expect(deviceInfo.manufacturer, equals('Test Manufacturer'));
      expect(deviceInfo.model, equals('Test Model'));
      expect(deviceInfo.osVersion, equals('12'));
      expect(deviceInfo.deviceType, equals('Smartphone'));
      expect(deviceInfo.deviceName, equals('Test Manufacturer Test Model'));
      expect(deviceInfo.appVersion, equals('1.0.0'));
      expect(deviceInfo.isActive, isTrue);
      expect(deviceInfo.isTrusted, isFalse);
      expect(deviceInfo.trustScore, equals(50));
    });

    test('getCurrentDeviceInfo should create device info for iOS device', () async {
      // Arrange
      const testDeviceId = 'test-ios-id';
      final iosInfo = IosDeviceInfo(
        identifierForVendor: testDeviceId,
        isPhysicalDevice: true,
        model: 'iPhone 13',
        name: 'Test iPhone',
        systemName: 'iOS',
        systemVersion: '15.0',
        utsname: Utsname(
          sysname: 'Darwin',
          nodename: 'Test-iPhone',
          release: '20.0.0',
          version: 'Darwin Kernel Version 20.0.0',
          machine: 'iPhone13,1',
        ),
        localizedModel: 'iPhone 13',
      );

      when(() => mockDeviceInfoPlugin.deviceInfo)
          .thenAnswer((_) async => iosInfo);
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);
      when(() => mockStorage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      )).thenAnswer((_) async {});

      // Act
      final deviceInfo = await deviceService.getCurrentDeviceInfo();

      // Assert
      expect(deviceInfo.deviceId, equals(testDeviceId));
      expect(deviceInfo.platform, equals('iOS'));
      expect(deviceInfo.manufacturer, equals('Apple'));
      expect(deviceInfo.model, equals('iPhone 13'));
      expect(deviceInfo.osVersion, equals('15.0'));
      expect(deviceInfo.deviceType, equals('Smartphone'));
      expect(deviceInfo.deviceName, equals('Test iPhone'));
      expect(deviceInfo.appVersion, equals('1.0.0'));
      expect(deviceInfo.isActive, isTrue);
      expect(deviceInfo.isTrusted, isFalse);
      expect(deviceInfo.trustScore, equals(50));
    });

    test('getCurrentDeviceInfo should handle device info collection errors', () async {
      // Arrange
      when(() => mockDeviceInfoPlugin.deviceInfo)
          .thenThrow(Exception('Device info not available'));
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);
      when(() => mockStorage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      )).thenAnswer((_) async {});

      // Act
      final deviceInfo = await deviceService.getCurrentDeviceInfo();

      // Assert
      expect(deviceInfo.deviceId, isNotNull);
      expect(deviceInfo.platform, equals('Unknown'));
      expect(deviceInfo.manufacturer, equals('Unknown'));
      expect(deviceInfo.model, equals('Unknown'));
      expect(deviceInfo.deviceType, equals('Unknown'));
      expect(deviceInfo.deviceName, equals('Unknown Device'));
    });

    test('_getOrCreateDeviceId should create new device ID if not exists', () async {
      // Arrange
      when(() => mockStorage.read(key: 'device_id'))
          .thenAnswer((_) async => null);
      when(() => mockStorage.write(
        key: 'device_id',
        value: any(named: 'value'),
      )).thenAnswer((_) async {});

      // Act
      final deviceId = await deviceService.getCurrentDeviceInfo();

      // Assert
      verify(() => mockStorage.write(
        key: 'device_id',
        value: any(named: 'value'),
      )).called(1);
      expect(deviceId.deviceId, isNotNull);
    });

    test('_getOrCreateDeviceId should return existing device ID if exists', () async {
      // Arrange
      const existingDeviceId = 'existing-device-id';
      when(() => mockStorage.read(key: 'device_id'))
          .thenAnswer((_) async => existingDeviceId);

      // Act
      final deviceInfo = await deviceService.getCurrentDeviceInfo();

      // Assert
      verifyNever(() => mockStorage.write(
        key: 'device_id',
        value: any(named: 'value'),
      ));
      expect(deviceInfo.deviceId, equals(existingDeviceId));
    });

    test('markDeviceAsTrusted should mark device as trusted', () async {
      // Arrange
      const testDeviceId = 'test-device-id';
      const trustScore = 85;

      when(() => mockStorage.write(
        key: 'device_trust_$testDeviceId',
        value: any(named: 'value'),
      )).thenAnswer((_) async {});

      // Act
      await deviceService.markDeviceAsTrusted(testDeviceId, trustScore: trustScore);

      // Assert
      verify(() => mockStorage.write(
        key: 'device_trust_$testDeviceId',
        value: any(named: 'value'),
      )).called(1);
    });

    test('updateDeviceTrustScore should update trust score', () async {
      // Arrange
      const testDeviceId = 'test-device-id';
      const newTrustScore = 90;

      when(() => mockStorage.read(key: 'device_trust_$testDeviceId'))
          .thenAnswer((_) async => null);
      when(() => mockStorage.write(
        key: 'device_trust_$testDeviceId',
        value: any(named: 'value'),
      )).thenAnswer((_) async {});

      // Act
      await deviceService.updateDeviceTrustScore(testDeviceId, newTrustScore);

      // Assert
      verify(() => mockStorage.write(
        key: 'device_trust_$testDeviceId',
        value: any(named: 'value'),
      )).called(1);
    });

    test('updateDeviceTrustScore should mark device as trusted when score >= 80', () async {
      // Arrange
      const testDeviceId = 'test-device-id';
      const highTrustScore = 85;

      when(() => mockStorage.read(key: 'device_trust_$testDeviceId'))
          .thenAnswer((_) async => null);
      when(() => mockStorage.write(
        key: 'device_trust_$testDeviceId',
        value: any(named: 'value'),
      )).thenAnswer((_) async {});

      // Act
      await deviceService.updateDeviceTrustScore(testDeviceId, highTrustScore);

      // Assert
      verify(() => mockStorage.write(
        key: 'device_trust_$testDeviceId',
        value: any(named: 'value'),
      )).called(1);
    });

    test('verifyDeviceFingerprint should return true for matching fingerprints', () async {
      // Arrange
      const expectedFingerprint = 'expected-fingerprint';

      // Mock device info to generate matching fingerprint
      const testDeviceId = 'test-device-id';
      final androidInfo = AndroidDeviceInfo(
        id: testDeviceId,
        androidId: testDeviceId,
        board: 'test-board',
        bootloader: 'test-bootloader',
        brand: 'test-brand',
        device: 'test-device',
        display: 'test-display',
        fingerprint: 'test-fingerprint',
        hardware: 'test-hardware',
        host: 'test-host',
        isAdbEnabled: true,
        isDebugMode: false,
        isEmulator: false,
        isPhysicalDevice: true,
        manufacturer: 'Test Manufacturer',
        model: 'Test Model',
        product: 'test-product',
        supported32BitAbis: ['arm32'],
        supported64BitAbis: ['arm64'],
        supportedAbis: ['arm32', 'arm64'],
        systemFeatures: ['feature1'],
        tags: 'test-tags',
        type: 'user',
        versionAndroidSdkInt: 31,
        versionBaseOS: 'test-base-os',
        versionCodename: 'test-codename',
        versionIncremental: 'test-incremental',
        versionRelease: '12',
        versionSecurityPatch: '2023-01-01',
      );

      when(() => mockDeviceInfoPlugin.deviceInfo)
          .thenAnswer((_) async => androidInfo);

      // Act
      final isVerified = await deviceService.verifyDeviceFingerprint(expectedFingerprint);

      // Assert
      expect(isVerified, isTrue);
    });

    test('recordDeviceActivity should record successful authentication', () async {
      // Arrange
      const testDeviceId = 'test-device-id';
      const successfulAuth = true;

      when(() => mockStorage.read(key: 'device_activity_$testDeviceId'))
          .thenAnswer((_) async => null);
      when(() => mockStorage.write(
        key: 'device_activity_$testDeviceId',
        value: any(named: 'value'),
      )).thenAnswer((_) async {});
      when(() => mockStorage.write(
        key: 'device_trust_$testDeviceId',
        value: any(named: 'value'),
      )).thenAnswer((_) async {});

      // Act
      await deviceService.recordDeviceActivity(testDeviceId, successfulAuth);

      // Assert
      verify(() => mockStorage.write(
        key: 'device_activity_$testDeviceId',
        value: any(named: 'value'),
      )).called(1);
    });

    test('getDeviceActivityHistory should return empty list when no activities exist', () async {
      // Arrange
      const testDeviceId = 'test-device-id';

      when(() => mockStorage.read(key: 'device_activity_$testDeviceId'))
          .thenAnswer((_) async => null);

      // Act
      final history = await deviceService.getDeviceActivityHistory(testDeviceId);

      // Assert
      expect(history, isEmpty);
    });

    test('getDeviceActivityHistory should return activities when they exist', () async {
      // Arrange
      const testDeviceId = 'test-device-id';
      final mockActivities = [
        {
          'timestamp': DateTime.now().toIso8601String(),
          'successful': true,
        },
        {
          'timestamp': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
          'successful': false,
        },
      ];

      when(() => mockStorage.read(key: 'device_activity_$testDeviceId'))
          .thenAnswer((_) async => mockActivities.toString());

      // Act
      final history = await deviceService.getDeviceActivityHistory(testDeviceId);

      // Assert
      expect(history.length, equals(2));
      expect(history.first['successful'], isTrue);
      expect(history.last['successful'], isFalse);
    });

    test('getTrustedDevices should return list of trusted device IDs', () async {
      // Arrange
      const trustedDeviceId1 = 'trusted-device-1';
      const trustedDeviceId2 = 'trusted-device-2';
      const untrustedDeviceId = 'untrusted-device';

      final mockTrustData = {
        'device_trust_$trustedDeviceId1': {
          'is_trusted': true,
          'trust_score': 85,
          'trusted_at': DateTime.now().toIso8601String(),
          'last_seen': DateTime.now().toIso8601String(),
        }.toString(),
        'device_trust_$trustedDeviceId2': {
          'is_trusted': true,
          'trust_score': 90,
          'trusted_at': DateTime.now().toIso8601String(),
          'last_seen': DateTime.now().toIso8601String(),
        }.toString(),
        'device_trust_$untrustedDeviceId': {
          'is_trusted': false,
          'trust_score': 30,
          'trusted_at': null,
          'last_seen': DateTime.now().toIso8601String(),
        }.toString(),
      };

      when(() => mockStorage.readAll())
          .thenAnswer((_) async => mockTrustData);

      // Act
      final trustedDevices = await deviceService.getTrustedDevices();

      // Assert
      expect(trustedDevices.length, equals(2));
      expect(trustedDevices, contains(trustedDeviceId1));
      expect(trustedDevices, contains(trustedDeviceId2));
      expect(trustedDevices, isNot(contains(untrustedDeviceId)));
    });

    test('revokeDeviceTrust should mark device as untrusted', () async {
      // Arrange
      const testDeviceId = 'test-device-id';

      when(() => mockStorage.write(
        key: 'device_trust_$testDeviceId',
        value: any(named: 'value'),
      )).thenAnswer((_) async {});

      // Act
      await deviceService.revokeDeviceTrust(testDeviceId);

      // Assert
      verify(() => mockStorage.write(
        key: 'device_trust_$testDeviceId',
        value: any(named: 'value'),
      )).called(1);
    });

    test('isDeviceSuspicious should return false for devices with insufficient history', () async {
      // Arrange
      const testDeviceId = 'test-device-id';
      final mockActivities = [
        {
          'timestamp': DateTime.now().toIso8601String(),
          'successful': true,
        },
        {
          'timestamp': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
          'successful': true,
        },
        {
          'timestamp': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
          'successful': false,
        },
      ];

      when(() => mockStorage.read(key: 'device_activity_$testDeviceId'))
          .thenAnswer((_) async => mockActivities.toString());

      // Act
      final isSuspicious = await deviceService.isDeviceSuspicious(testDeviceId);

      // Assert
      expect(isSuspicious, isFalse);
    });

    test('isDeviceSuspicious should return true for devices with high failure rate', () async {
      // Arrange
      const testDeviceId = 'test-device-id';
      final mockActivities = List.generate(10, (index) => {
        return {
          'timestamp': DateTime.now().subtract(Duration(hours: index)).toIso8601String(),
          'successful': index >= 7, // Only last 3 are successful
        };
      });

      when(() => mockStorage.read(key: 'device_activity_$testDeviceId'))
          .thenAnswer((_) async => mockActivities.toString());

      // Act
      final isSuspicious = await deviceService.isDeviceSuspicious(testDeviceId);

      // Assert
      expect(isSuspicious, isTrue);
    });

    test('clearDeviceData should remove all device-related data', () async {
      // Arrange
      const testDeviceId = 'test-device-id';

      when(() => mockStorage.delete(key: any(named: 'key')))
          .thenAnswer((_) async {});

      // Act
      await deviceService.clearDeviceData(testDeviceId);

      // Assert
      verify(() => mockStorage.delete(key: 'device_trust_$testDeviceId')).called(1);
      verify(() => mockStorage.delete(key: 'device_activity_$testDeviceId')).called(1);
    });

    test('_getAndroidDeviceType should identify tablet devices', () async {
      // Arrange
      final androidInfo = AndroidDeviceInfo(
        id: 'test-id',
        androidId: 'test-id',
        board: 'test-board',
        bootloader: 'test-bootloader',
        brand: 'test-brand',
        device: 'test-device',
        display: 'test-display',
        fingerprint: 'test-fingerprint',
        hardware: 'test-hardware',
        host: 'test-host',
        isAdbEnabled: true,
        isDebugMode: false,
        isEmulator: false,
        isPhysicalDevice: true,
        manufacturer: 'Test Manufacturer',
        model: 'Test Tablet',
        product: 'test-product',
        supported32BitAbis: ['arm32'],
        supported64BitAbis: ['arm64'],
        supportedAbis: ['arm32', 'arm64'],
        systemFeatures: ['feature1'],
        tags: 'test-tags',
        type: 'user',
        versionAndroidSdkInt: 31,
        versionBaseOS: 'test-base-os',
        versionCodename: 'test-codename',
        versionIncremental: 'test-incremental',
        versionRelease: '12',
        versionSecurityPatch: '2023-01-01',
      );

      when(() => mockDeviceInfoPlugin.deviceInfo)
          .thenAnswer((_) async => androidInfo);
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);
      when(() => mockStorage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      )).thenAnswer((_) async {});

      // Act
      final deviceInfo = await deviceService.getCurrentDeviceInfo();

      // Assert
      expect(deviceInfo.deviceType, equals('Tablet'));
    });

    test('_getIOSDeviceType should identify iPad devices', () async {
      // Arrange
      const testDeviceId = 'test-ios-id';
      final iosInfo = IosDeviceInfo(
        identifierForVendor: testDeviceId,
        isPhysicalDevice: true,
        model: 'iPad Pro',
        name: 'Test iPad',
        systemName: 'iOS',
        systemVersion: '15.0',
        utsname: Utsname(
          sysname: 'Darwin',
          nodename: 'Test-iPad',
          release: '20.0.0',
          version: 'Darwin Kernel Version 20.0.0',
          machine: 'iPad13,1',
        ),
        localizedModel: 'iPad Pro',
      );

      when(() => mockDeviceInfoPlugin.deviceInfo)
          .thenAnswer((_) async => iosInfo);
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);
      when(() => mockStorage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      )).thenAnswer((_) async {});

      // Act
      final deviceInfo = await deviceService.getCurrentDeviceInfo();

      // Assert
      expect(deviceInfo.deviceType, equals('Tablet'));
    });
  });
}