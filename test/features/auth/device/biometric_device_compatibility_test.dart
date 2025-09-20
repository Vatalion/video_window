import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:video_window/features/auth/data/services/biometric_auth_service.dart';
import 'package:video_window/features/auth/domain/models/biometric_models.dart';
import 'package:local_auth/local_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';

class MockLocalAuthentication extends Mock implements LocalAuthentication {}

class MockDeviceInfoPlugin extends Mock implements DeviceInfoPlugin {}

void main() {
  group('Biometric Device Compatibility Tests', () {
    late BiometricAuthService biometricAuthService;
    late MockLocalAuthentication mockLocalAuth;
    late MockDeviceInfoPlugin mockDeviceInfo;

    setUp(() {
      mockLocalAuth = MockLocalAuthentication();
      mockDeviceInfo = MockDeviceInfoPlugin();
      biometricAuthService = BiometricAuthService();
    });

    group('iOS Device Compatibility Tests', () {
      test('Should detect Face ID on iPhone X and later', () async {
        // Arrange
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(() => mockLocalAuth.getAvailableBiometrics())
            .thenAnswer((_) async => [BiometricType.face]);

        when(() => mockDeviceInfo.iosInfo).thenAnswer((_) async => IosDeviceInfo(
              name: 'iPhone 13 Pro',
              model: 'iPhone',
              systemName: 'iOS',
              systemVersion: '15.0',
              isPhysicalDevice: true,
              utsname: Utsname(
                sysname: 'Darwin',
                nodename: 'iPhone',
                release: '20.0.0',
                version: 'Darwin Kernel Version 20.0.0',
                machine: 'iPhone14,3',
              ),
              localizedModel: 'iPhone 13 Pro',
              identifierForVendor: '12345678-1234-1234-1234-123456789012',
            ));

        // Act
        final capability = await biometricAuthService.checkBiometricCapability();

        // Assert
        expect(capability.isAvailable, isTrue);
        expect(capability.type, equals(BiometricType.faceId));
        expect(capability.status, equals(BiometricAuthStatus.available));
      });

      test('Should detect Touch ID on iPhone 8 and earlier', () async {
        // Arrange
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(() => mockLocalAuth.getAvailableBiometrics())
            .thenAnswer((_) async => [BiometricType.fingerprint]);

        when(() => mockDeviceInfo.iosInfo).thenAnswer((_) async => IosDeviceInfo(
              name: 'iPhone 8',
              model: 'iPhone',
              systemName: 'iOS',
              systemVersion: '15.0',
              isPhysicalDevice: true,
              utsname: Utsname(
                sysname: 'Darwin',
                nodename: 'iPhone',
                release: '20.0.0',
                version: 'Darwin Kernel Version 20.0.0',
                machine: 'iPhone10,4',
              ),
              localizedModel: 'iPhone 8',
              identifierForVendor: '12345678-1234-1234-1234-123456789012',
            ));

        // Act
        final capability = await biometricAuthService.checkBiometricCapability();

        // Assert
        expect(capability.isAvailable, isTrue);
        expect(capability.type, equals(BiometricType.touchId));
        expect(capability.status, equals(BiometricAuthStatus.available));
      });

      test('Should detect Face ID on iPad Pro with Face ID', () async {
        // Arrange
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(() => mockLocalAuth.getAvailableBiometrics())
            .thenAnswer((_) async => [BiometricType.face]);

        when(() => mockDeviceInfo.iosInfo).thenAnswer((_) async => IosDeviceInfo(
              name: 'iPad Pro',
              model: 'iPad',
              systemName: 'iOS',
              systemVersion: '15.0',
              isPhysicalDevice: true,
              utsname: Utsname(
                sysname: 'Darwin',
                nodename: 'iPad',
                release: '20.0.0',
                version: 'Darwin Kernel Version 20.0.0',
                machine: 'iPad8,11',
              ),
              localizedModel: 'iPad Pro',
              identifierForVendor: '12345678-1234-1234-1234-123456789012',
            ));

        // Act
        final capability = await biometricAuthService.checkBiometricCapability();

        // Assert
        expect(capability.isAvailable, isTrue);
        expect(capability.type, equals(BiometricType.faceId));
        expect(capability.status, equals(BiometricAuthStatus.available));
      });

      test('Should handle iOS simulator without biometrics', () async {
        // Arrange
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => false);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => false);

        when(() => mockDeviceInfo.iosInfo).thenAnswer((_) async => IosDeviceInfo(
              name: 'Simulator',
              model: 'iPhone',
              systemName: 'iOS',
              systemVersion: '15.0',
              isPhysicalDevice: false,
              utsname: Utsname(
                sysname: 'Darwin',
                nodename: 'iPhone',
                release: '20.0.0',
                version: 'Darwin Kernel Version 20.0.0',
                machine: 'x86_64',
              ),
              localizedModel: 'Simulator',
              identifierForVendor: '12345678-1234-1234-1234-123456789012',
            ));

        // Act
        final capability = await biometricAuthService.checkBiometricCapability();

        // Assert
        expect(capability.isAvailable, isFalse);
        expect(capability.type, equals(BiometricType.none));
        expect(capability.status, equals(BiometricAuthStatus.notAvailable));
      });
    });

    group('Android Device Compatibility Tests', () {
      test('Should detect fingerprint on Android devices with fingerprint sensor', () async {
        // Arrange
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(() => mockLocalAuth.getAvailableBiometrics())
            .thenAnswer((_) async => [BiometricType.fingerprint]);

        when(() => mockDeviceInfo.androidInfo).thenAnswer((_) async => AndroidDeviceInfo(
              version: AndroidBuildVersion(
                sdkInt: 30,
                release: '11.0',
              ),
              board: 'board',
              bootloader: 'bootloader',
              brand: 'Google',
              device: 'device',
              display: 'display',
              fingerprint: 'fingerprint',
              hardware: 'hardware',
              host: 'host',
              id: 'id',
              manufacturer: 'Google',
              model: 'Pixel 5',
              product: 'product',
              supported32BitAbis: ['arm64-v8a'],
              supported64BitAbis: ['arm64-v8a'],
              supportedAbis: ['arm64-v8a'],
              tags: 'tags',
              type: 'type',
              isPhysicalDevice: true,
              androidId: 'android_id',
              systemFeatures: ['android.hardware.fingerprint'],
            ));

        // Act
        final capability = await biometricAuthService.checkBiometricCapability();

        // Assert
        expect(capability.isAvailable, isTrue);
        expect(capability.type, equals(BiometricType.fingerprint));
        expect(capability.status, equals(BiometricAuthStatus.available));
      });

      test('Should detect face unlock on Android devices with face sensor', () async {
        // Arrange
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(() => mockLocalAuth.getAvailableBiometrics())
            .thenAnswer((_) async => [BiometricType.face, BiometricType.fingerprint]);

        when(() => mockDeviceInfo.androidInfo).thenAnswer((_) async => AndroidDeviceInfo(
              version: AndroidBuildVersion(
                sdkInt: 30,
                release: '11.0',
              ),
              board: 'board',
              bootloader: 'bootloader',
              brand: 'Google',
              device: 'device',
              display: 'display',
              fingerprint: 'fingerprint',
              hardware: 'hardware',
              host: 'host',
              id: 'id',
              manufacturer: 'Google',
              model: 'Pixel 4 XL',
              product: 'product',
              supported32BitAbis: ['arm64-v8a'],
              supported64BitAbis: ['arm64-v8a'],
              supportedAbis: ['arm64-v8a'],
              tags: 'tags',
              type: 'type',
              isPhysicalDevice: true,
              androidId: 'android_id',
              systemFeatures: ['android.hardware.biometrics.face', 'android.hardware.fingerprint'],
            ));

        // Act
        final capability = await biometricAuthService.checkBiometricCapability();

        // Assert
        expect(capability.isAvailable, isTrue);
        // Face ID takes precedence over fingerprint
        expect(capability.type, equals(BiometricType.faceId));
        expect(capability.status, equals(BiometricAuthStatus.available));
      });

      test('Should handle Android devices without biometric support', () async {
        // Arrange
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => false);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => false);

        when(() => mockDeviceInfo.androidInfo).thenAnswer((_) async => AndroidDeviceInfo(
              version: AndroidBuildVersion(
                sdkInt: 21,
                release: '5.0',
              ),
              board: 'board',
              bootloader: 'bootloader',
              brand: 'Old Device',
              device: 'device',
              display: 'display',
              fingerprint: 'fingerprint',
              hardware: 'hardware',
              host: 'host',
              id: 'id',
              manufacturer: 'Old Device Co',
              model: 'Old Phone',
              product: 'product',
              supported32BitAbis: ['armeabi-v7a'],
              supported64BitAbis: [],
              supportedAbis: ['armeabi-v7a'],
              tags: 'tags',
              type: 'type',
              isPhysicalDevice: true,
              androidId: 'android_id',
              systemFeatures: [],
            ));

        // Act
        final capability = await biometricAuthService.checkBiometricCapability();

        // Assert
        expect(capability.isAvailable, isFalse);
        expect(capability.type, equals(BiometricType.none));
        expect(capability.status, equals(BiometricAuthStatus.notAvailable));
      });

      test('Should handle Android emulator without biometrics', () async {
        // Arrange
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => false);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => false);

        when(() => mockDeviceInfo.androidInfo).thenAnswer((_) async => AndroidDeviceInfo(
              version: AndroidBuildVersion(
                sdkInt: 30,
                release: '11.0',
              ),
              board: 'board',
              bootloader: 'bootloader',
              brand: 'Google',
              device: 'device',
              display: 'display',
              fingerprint: 'fingerprint',
              hardware: 'hardware',
              host: 'host',
              id: 'id',
              manufacturer: 'Google',
              model: 'Android SDK built for x86',
              product: 'product',
              supported32BitAbis: ['x86'],
              supported64BitAbis: ['x86_64'],
              supportedAbis: ['x86', 'x86_64'],
              tags: 'tags',
              type: 'userdebug',
              isPhysicalDevice: false,
              androidId: 'android_id',
              systemFeatures: [],
            ));

        // Act
        final capability = await biometricAuthService.checkBiometricCapability();

        // Assert
        expect(capability.isAvailable, isFalse);
        expect(capability.type, equals(BiometricType.none));
        expect(capability.status, equals(BiometricAuthStatus.notAvailable));
      });
    });

    group('Cross-Platform Compatibility Tests', () {
      test('Should handle devices with multiple biometric types', () async {
        // Arrange
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(() => mockLocalAuth.getAvailableBiometrics())
            .thenAnswer((_) async => [BiometricType.face, BiometricType.fingerprint, BiometricType.iris]);

        // Act
        final capability = await biometricAuthService.checkBiometricCapability();

        // Assert
        expect(capability.isAvailable, isTrue);
        // Face ID takes precedence
        expect(capability.type, equals(BiometricType.faceId));
        expect(capability.status, equals(BiometricAuthStatus.available));
      });

      test('Should handle biometric not enrolled scenario', () async {
        // Arrange
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(() => mockLocalAuth.getAvailableBiometrics())
            .thenAnswer((_) async => [BiometricType.face]);

        // Simulate biometric not enrolled
        when(() => mockLocalAuth.authenticate(
              localizedReason: any(named: 'localizedReason'),
              options: any(named: 'options'),
            )).thenThrow(PlatformException(
              code: 'NotEnrolled',
              message: 'No biometrics enrolled',
            ));

        // Act
        final capability = await biometricAuthService.checkBiometricCapability();

        // Assert
        // Device capability should still be detected
        expect(capability.isAvailable, isTrue);
        expect(capability.type, equals(BiometricType.faceId));
        expect(capability.status, equals(BiometricAuthStatus.available));
      });

      test('Should handle biometric permanently locked out', () async {
        // Arrange
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(() => mockLocalAuth.getAvailableBiometrics())
            .thenAnswer((_) async => [BiometricType.face]);

        when(() => mockLocalAuth.authenticate(
              localizedReason: any(named: 'localizedReason'),
              options: any(named: 'options'),
            )).thenThrow(PlatformException(
              code: 'PermanentlyLockedOut',
              message: 'Biometric authentication permanently locked out',
            ));

        // Act
        final capability = await biometricAuthService.checkBiometricCapability();

        // Assert
        // Device capability should still be detected
        expect(capability.isAvailable, isTrue);
        expect(capability.type, equals(BiometricType.faceId));
        expect(capability.status, equals(BiometricAuthStatus.available));
      });
    });

    group('Device Info Error Handling Tests', () {
      test('Should handle device info service errors gracefully', () async {
        // Arrange
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(() => mockLocalAuth.getAvailableBiometrics())
            .thenAnswer((_) async => [BiometricType.face]);

        when(() => mockDeviceInfo.iosInfo).thenThrow(Exception('Device info service unavailable'));

        // Act
        final capability = await biometricAuthService.checkBiometricCapability();

        // Assert
        // Should still work without device info
        expect(capability.isAvailable, isTrue);
        expect(capability.type, equals(BiometricType.faceId));
        expect(capability.status, equals(BiometricAuthStatus.available));
      });

      test('Should handle null device info', () async {
        // Arrange
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(() => mockLocalAuth.getAvailableBiometrics())
            .thenAnswer((_) async => [BiometricType.face]);

        when(() => mockDeviceInfo.iosInfo).thenAnswer((_) async => IosDeviceInfo(
              name: null,
              model: null,
              systemName: null,
              systemVersion: null,
              isPhysicalDevice: null,
              utsname: Utsname(
                sysname: null,
                nodename: null,
                release: null,
                version: null,
                machine: null,
              ),
              localizedModel: null,
              identifierForVendor: null,
            ));

        // Act
        final capability = await biometricAuthService.checkBiometricCapability();

        // Assert
        // Should still work with null device info
        expect(capability.isAvailable, isTrue);
        expect(capability.type, equals(BiometricType.faceId));
        expect(capability.status, equals(BiometricAuthStatus.available));
      });
    });

    group('Performance Tests', () {
      test('Should complete biometric capability check within 1 second', () async {
        // Arrange
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(() => mockLocalAuth.getAvailableBiometrics())
            .thenAnswer((_) async => [BiometricType.face]);

        final stopwatch = Stopwatch()..start();

        // Act
        await biometricAuthService.checkBiometricCapability();

        stopwatch.stop();

        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });

      test('Should handle slow biometric authentication gracefully', () async {
        // Arrange
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(() => mockLocalAuth.getAvailableBiometrics())
            .thenAnswer((_) async => [BiometricType.face]);

        when(() => mockLocalAuth.authenticate(
              localizedReason: any(named: 'localizedReason'),
              options: any(named: 'options'),
            )).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 800));
          return true;
        });

        final stopwatch = Stopwatch()..start();

        // Act
        final result = await biometricAuthService.authenticate();

        stopwatch.stop();

        // Assert
        expect(result.success, isTrue);
        expect(stopwatch.elapsedMilliseconds, lessThan(2000)); // Allow some buffer
      });
    });
  });
}