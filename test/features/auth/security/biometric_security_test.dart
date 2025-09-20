import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:video_window/features/auth/data/services/biometric_auth_service.dart';
import 'package:video_window/features/auth/data/services/biometric_api_service.dart';
import 'package:video_window/features/auth/domain/models/biometric_models.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class MockLocalAuthentication extends Mock implements LocalAuthentication {}

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

class MockBiometricApiService extends Mock implements BiometricApiService {}

void main() {
  group('Biometric Security Tests', () {
    late BiometricAuthService biometricAuthService;
    late MockLocalAuthentication mockLocalAuth;
    late MockFlutterSecureStorage mockSecureStorage;
    late MockBiometricApiService mockApiService;

    setUp(() {
      mockLocalAuth = MockLocalAuthentication();
      mockSecureStorage = MockFlutterSecureStorage();
      mockApiService = MockBiometricApiService();

      biometricAuthService = BiometricAuthService();
    });

    group('Biometric Data Privacy Tests', () {
      test('Should never store actual biometric data locally', () async {
        // Arrange
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(() => mockLocalAuth.getAvailableBiometrics())
            .thenAnswer((_) async => [BiometricType.face]);

        // Act
        final capability = await biometricAuthService.checkBiometricCapability();

        // Assert
        expect(capability.isAvailable, isTrue);
        // Verify that no biometric data is stored in secure storage
        verifyNever(() => mockSecureStorage.write(
              key: any(named: 'key'),
              value: any(named: 'value', that: contains('biometric_data')),
            ));
      });

      test('Should only store biometric preferences, not biometric data', () async {
        // Arrange
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(() => mockLocalAuth.getAvailableBiometrics())
            .thenAnswer((_) async => [BiometricType.face]);

        when(() => mockLocalAuth.authenticate(
              localizedReason: any(named: 'localizedReason'),
              options: any(named: 'options'),
            )).thenAnswer((_) async => true);

        when(() => mockSecureStorage.write(key: any(named: 'key'), value: any(named: 'value')))
            .thenAnswer((_) async {});

        // Act
        final success = await biometricAuthService.enableBiometricAuth();

        // Assert
        expect(success, isTrue);

        // Verify only preference keys are stored, not biometric data
        final captured = verify(() => mockSecureStorage.write(
          key: captureAny(named: 'key'),
          value: captureAny(named: 'value'),
        )).captured;

        final keys = captured[0] as List<String>;
        expect(keys, contains('biometric_enabled'));
        expect(keys, contains('biometric_type'));
        expect(keys, isNot(contains('biometric_data')));
        expect(keys, isNot(contains('face_data')));
        expect(keys, isNot(contains('fingerprint_template')));
      });

      test('Should not transmit biometric data to backend', () async {
        // Arrange
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(() => mockLocalAuth.getAvailableBiometrics())
            .thenAnswer((_) async => [BiometricType.face]);

        when(() => mockLocalAuth.authenticate(
              localizedReason: any(named: 'localizedReason'),
              options: any(named: 'options'),
            )).thenAnswer((_) async => true);

        when(() => mockSecureStorage.read(key: any(named: 'key')))
            .thenAnswer((_) async => 'true');

        when(() => mockSecureStorage.write(key: any(named: 'key'), value: any(named: 'value')))
            .thenAnswer((_) async {});

        // Act
        final result = await biometricAuthService.authenticate();

        // Assert
        expect(result.success, isTrue);

        // Verify API service is not called with biometric data
        verifyNever(() => mockApiService.authenticateWithBiometrics(
              userId: any(named: 'userId'),
              biometricType: any(named: 'biometricType'),
              deviceSignature: any(named: 'deviceSignature', that: contains('biometric_data')),
              biometricChallengeResponse: any(named: 'biometricChallengeResponse', that: contains('biometric_data')),
            ));
      });
    });

    group('Biometric Authentication Security Tests', () {
      test('Should enforce attempt limiting', () async {
        // Arrange
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(() => mockLocalAuth.getAvailableBiometrics())
            .thenAnswer((_) async => [BiometricType.face]);

        when(() => mockLocalAuth.authenticate(
              localizedReason: any(named: 'localizedReason'),
              options: any(named: 'options'),
            )).thenAnswer((_) async => false);

        when(() => mockSecureStorage.read(key: any(named: 'key')))
            .thenAnswer((_) async => 'true');

        when(() => mockSecureStorage.write(key: any(named: 'key'), value: any(named: 'value')))
            .thenAnswer((_) async {});

        // Act - Simulate multiple failed attempts
        for (int i = 0; i < 6; i++) {
          await biometricAuthService.authenticate();
        }

        // Assert
        final preferences = await biometricAuthService.getBiometricPreferences();
        expect(preferences.failedAttempts, greaterThanOrEqualTo(5));
        expect(preferences.isLockedOut, isTrue);
      });

      test('Should implement temporary lockout after max attempts', () async {
        // Arrange
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(() => mockLocalAuth.getAvailableBiometrics())
            .thenAnswer((_) async => [BiometricType.face]);

        when(() => mockLocalAuth.authenticate(
              localizedReason: any(named: 'localizedReason'),
              options: any(named: 'options'),
            )).thenAnswer((_) async => false);

        when(() => mockSecureStorage.read(key: any(named: 'key')))
            .thenAnswer((_) async => 'true');

        when(() => mockSecureStorage.write(key: any(named: 'key'), value: any(named: 'value')))
            .thenAnswer((_) async {});

        // Act - Trigger lockout
        for (int i = 0; i < 5; i++) {
          await biometricAuthService.authenticate();
        }

        // Assert
        final result = await biometricAuthService.authenticate();
        expect(result.success, isFalse);
        expect(result.errorMessage, contains('locked'));

        final lockoutTime = await biometricAuthService.getRemainingLockoutTime();
        expect(lockoutTime, isNotNull);
        expect(lockoutTime!.inMinutes, greaterThan(0));
      });

      test('Should reset failed attempts on successful authentication', () async {
        // Arrange
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(() => mockLocalAuth.getAvailableBiometrics())
            .thenAnswer((_) async => [BiometricType.face]);

        when(() => mockLocalAuth.authenticate(
              localizedReason: any(named: 'localizedReason'),
              options: any(named: 'options'),
            )).thenAnswer((_) async => false);

        when(() => mockSecureStorage.read(key: any(named: 'key')))
            .thenAnswer((_) async => 'true');

        when(() => mockSecureStorage.write(key: any(named: 'key'), value: any(named: 'value')))
            .thenAnswer((_) async {});

        // Act - Accumulate failed attempts
        for (int i = 0; i < 3; i++) {
          await biometricAuthService.authenticate();
        }

        // Now authenticate successfully
        when(() => mockLocalAuth.authenticate(
              localizedReason: any(named: 'localizedReason'),
              options: any(named: 'options'),
            )).thenAnswer((_) async => true);

        final successResult = await biometricAuthService.authenticate();

        // Assert
        expect(successResult.success, isTrue);

        final preferences = await biometricAuthService.getBiometricPreferences();
        expect(preferences.failedAttempts, equals(0));
        expect(preferences.isLockedOut, isFalse);
      });
    });

    group('Biometric Device Compatibility Tests', () {
      test('Should detect Face ID capability correctly', () async {
        // Arrange
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(() => mockLocalAuth.getAvailableBiometrics())
            .thenAnswer((_) async => [BiometricType.face]);

        // Act
        final capability = await biometricAuthService.checkBiometricCapability();

        // Assert
        expect(capability.isAvailable, isTrue);
        expect(capability.type, equals(BiometricType.faceId));
        expect(capability.status, equals(BiometricAuthStatus.available));
      });

      test('Should detect Touch ID capability correctly', () async {
        // Arrange
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(() => mockLocalAuth.getAvailableBiometrics())
            .thenAnswer((_) async => [BiometricType.fingerprint]);

        // Act
        final capability = await biometricAuthService.checkBiometricCapability();

        // Assert
        expect(capability.isAvailable, isTrue);
        expect(capability.type, equals(BiometricType.touchId));
        expect(capability.status, equals(BiometricAuthStatus.available));
      });

      test('Should handle device without biometric support', () async {
        // Arrange
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => false);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => false);

        // Act
        final capability = await biometricAuthService.checkBiometricCapability();

        // Assert
        expect(capability.isAvailable, isFalse);
        expect(capability.type, equals(BiometricType.none));
        expect(capability.status, equals(BiometricAuthStatus.notAvailable));
      });

      test('Should handle biometric not enrolled scenario', () async {
        // Arrange
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(() => mockLocalAuth.getAvailableBiometrics())
            .thenAnswer((_) async => [BiometricType.face]);

        when(() => mockLocalAuth.authenticate(
              localizedReason: any(named: 'localizedReason'),
              options: any(named: 'options'),
            )).thenThrow(PlatformException(
              code: 'NotEnrolled',
              message: 'No biometrics enrolled',
            ));

        // Act
        final result = await biometricAuthService.authenticate();

        // Assert
        expect(result.success, isFalse);
        expect(result.errorMessage, contains('No biometrics enrolled'));
      });
    });

    group('Biometric Secure Storage Tests', () {
      test('Should store preferences securely', () async {
        // Arrange
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(() => mockLocalAuth.getAvailableBiometrics())
            .thenAnswer((_) async => [BiometricType.face]);

        when(() => mockLocalAuth.authenticate(
              localizedReason: any(named: 'localizedReason'),
              options: any(named: 'options'),
            )).thenAnswer((_) async => true);

        when(() => mockSecureStorage.write(key: any(named: 'key'), value: any(named: 'value')))
            .thenAnswer((_) async {});

        // Act
        await biometricAuthService.enableBiometricAuth();

        // Assert
        verify(() => mockSecureStorage.write(
          key: 'biometric_enabled',
          value: 'true',
        )).called(1);

        verify(() => mockSecureStorage.write(
          key: 'biometric_type',
          value: 'faceId',
        )).called(1);
      });

      test('Should clear preferences securely when disabled', () async {
        // Arrange
        when(() => mockSecureStorage.delete(key: any(named: 'key')))
            .thenAnswer((_) async {});

        // Act
        await biometricAuthService.disableBiometricAuth();

        // Assert
        verify(() => mockSecureStorage.delete(key: 'biometric_enabled')).called(1);
        verify(() => mockSecureStorage.delete(key: 'biometric_type')).called(1);
        verify(() => mockSecureStorage.delete(key: 'last_biometric_auth')).called(1);
        verify(() => mockSecureStorage.delete(key: 'biometric_failed_attempts')).called(1);
        verify(() => mockSecureStorage.delete(key: 'biometric_lockout_until')).called(1);
      });
    });

    group('Biometric Error Handling Security Tests', () {
      test('Should handle authentication exceptions securely', () async {
        // Arrange
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(() => mockLocalAuth.getAvailableBiometrics())
            .thenAnswer((_) async => [BiometricType.face]);

        when(() => mockLocalAuth.authenticate(
              localizedReason: any(named: 'localizedReason'),
              options: any(named: 'options'),
            )).thenThrow(PlatformException(
              code: 'LockedOut',
              message: 'Biometric authentication locked out',
            ));

        when(() => mockSecureStorage.read(key: any(named: 'key')))
            .thenAnswer((_) async => 'true');

        when(() => mockSecureStorage.write(key: any(named: 'key'), value: any(named: 'value')))
            .thenAnswer((_) async {});

        // Act
        final result = await biometricAuthService.authenticate();

        // Assert
        expect(result.success, isFalse);
        expect(result.errorMessage, contains('locked out'));

        // Verify failed attempt was recorded
        final preferences = await biometricAuthService.getBiometricPreferences();
        expect(preferences.failedAttempts, greaterThan(0));
      });

      test('Should not expose sensitive information in error messages', () async {
        // Arrange
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(() => mockLocalAuth.getAvailableBiometrics())
            .thenAnswer((_) async => [BiometricType.face]);

        when(() => mockLocalAuth.authenticate(
              localizedReason: any(named: 'localizedReason'),
              options: any(named: 'options'),
            )).thenThrow(Exception('Internal database error: credentials table corrupted'));

        when(() => mockSecureStorage.read(key: any(named: 'key')))
            .thenAnswer((_) async => 'true');

        when(() => mockSecureStorage.write(key: any(named: 'key'), value: any(named: 'value')))
            .thenAnswer((_) async {});

        // Act
        final result = await biometricAuthService.authenticate();

        // Assert
        expect(result.success, isFalse);
        expect(result.errorMessage, isNot(contains('database')));
        expect(result.errorMessage, isNot(contains('table')));
        expect(result.errorMessage, isNot(contains('corrupted')));
        expect(result.errorMessage, contains('Unexpected error'));
      });
    });
  });
}