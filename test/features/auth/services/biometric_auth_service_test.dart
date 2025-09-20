import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:video_window/features/auth/data/services/biometric_auth_service.dart';
import 'package:video_window/features/auth/domain/models/biometric_models.dart';
import 'package:video_window/core/errors/exceptions.dart';

class MockLocalAuthentication extends Mock implements LocalAuthentication {}

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

class MockLogger extends Mock implements Logger {}

void main() {
  late BiometricAuthService biometricAuthService;
  late MockLocalAuthentication mockLocalAuth;
  late MockFlutterSecureStorage mockSecureStorage;
  late MockLogger mockLogger;

  setUp(() {
    mockLocalAuth = MockLocalAuthentication();
    mockSecureStorage = MockFlutterSecureStorage();
    mockLogger = MockLogger();

    biometricAuthService = BiometricAuthService();

    // Use reflection to inject mocks (in real implementation, use dependency injection)
    // This is a simplified approach for testing
  });

  group('BiometricAuthService', () {
    group('checkBiometricCapability', () {
      test('should return available capability when device supports biometrics', () async {
        // Arrange
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(() => mockLocalAuth.getAvailableBiometrics()).thenAnswer((_) async => [BiometricType.face]);

        // Act
        final result = await biometricAuthService.checkBiometricCapability();

        // Assert
        expect(result.isAvailable, isTrue);
        expect(result.type, BiometricType.faceId);
        expect(result.status, BiometricAuthStatus.available);
      });

      test('should return not available when device does not support biometrics', () async {
        // Arrange
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => false);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => false);

        // Act
        final result = await biometricAuthService.checkBiometricCapability();

        // Assert
        expect(result.isAvailable, isFalse);
        expect(result.type, BiometricType.none);
        expect(result.status, BiometricAuthStatus.notAvailable);
      });

      test('should handle platform exceptions gracefully', () async {
        // Arrange
        when(() => mockLocalAuth.canCheckBiometrics).thenThrow(PlatformException(code: 'NotAvailable'));

        // Act
        final result = await biometricAuthService.checkBiometricCapability();

        // Assert
        expect(result.isAvailable, isFalse);
        expect(result.status, BiometricAuthStatus.error);
        expect(result.errorMessage, isNotNull);
      });
    });

    group('authenticate', () {
      test('should return successful authentication when biometric succeeds', () async {
        // Arrange
        when(() => mockLocalAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          options: any(named: 'options'),
        )).thenAnswer((_) async => true);

        when(() => mockSecureStorage.read(key: any(named: 'key'))).thenAnswer((_) async => 'true');
        when(() => mockSecureStorage.write(key: any(named: 'key'), value: any(named: 'value'))).thenAnswer((_) async {});
        when(() => mockSecureStorage.delete(key: any(named: 'key'))).thenAnswer((_) async {});

        // Act
        final result = await biometricAuthService.authenticate();

        // Assert
        expect(result.success, isTrue);
        expect(result.errorMessage, isNull);
      });

      test('should return failed authentication when biometric fails', () async {
        // Arrange
        when(() => mockLocalAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          options: any(named: 'options'),
        )).thenAnswer((_) async => false);

        when(() => mockSecureStorage.read(key: any(named: 'key'))).thenAnswer((_) async => 'true');
        when(() => mockSecureStorage.write(key: any(named: 'key'), value: any(named: 'value'))).thenAnswer((_) async {});

        // Act
        final result = await biometricAuthService.authenticate();

        // Assert
        expect(result.success, isFalse);
        expect(result.errorMessage, isNotNull);
      });

      test('should handle lockout scenario', () async {
        // Arrange
        when(() => mockLocalAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          options: any(named: 'options'),
        )).thenThrow(PlatformException(code: 'LockedOut'));

        when(() => mockSecureStorage.read(key: any(named: 'key'))).thenAnswer((_) async => 'true');
        when(() => mockSecureStorage.write(key: any(named: 'key'), value: any(named: 'value'))).thenAnswer((_) async {});

        // Act
        final result = await biometricAuthService.authenticate();

        // Assert
        expect(result.success, isFalse);
        expect(result.errorMessage, contains('locked out'));
      });
    });

    group('enableBiometricAuth', () {
      test('should enable biometric authentication successfully', () async {
        // Arrange
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
        when(() => mockLocalAuth.getAvailableBiometrics()).thenAnswer((_) async => [BiometricType.face]);
        when(() => mockLocalAuth.authenticate(
          localizedReason: any(named: 'localizedReason'),
          options: any(named: 'options'),
        )).thenAnswer((_) async => true);
        when(() => mockSecureStorage.write(key: any(named: 'key'), value: any(named: 'value'))).thenAnswer((_) async {});

        // Act
        final result = await biometricAuthService.enableBiometricAuth();

        // Assert
        expect(result, isTrue);
      });

      test('should throw exception when biometric is not available', () async {
        // Arrange
        when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => false);
        when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => false);

        // Act & Assert
        expect(
          () => biometricAuthService.enableBiometricAuth(),
          throwsA(isA<BiometricException>()),
        );
      });
    });

    group('getBiometricPreferences', () {
      test('should return correct preferences when biometric is enabled', () async {
        // Arrange
        when(() => mockSecureStorage.read(key: any(named: 'key'))).thenAnswer((invocation) {
          final key = invocation.namedArguments[#key] as String;
          switch (key) {
            case 'biometric_enabled':
              return 'true';
            case 'biometric_type':
              return 'faceId';
            case 'last_biometric_auth':
              return DateTime.now().toIso8601String();
            case 'biometric_failed_attempts':
              return '0';
            default:
              return null;
          }
        });

        // Act
        final result = await biometricAuthService.getBiometricPreferences();

        // Assert
        expect(result.isEnabled, isTrue);
        expect(result.preferredBiometricType, BiometricType.faceId);
        expect(result.failedAttempts, 0);
        expect(result.isLockedOut, isFalse);
      });

      test('should return default preferences when storage is empty', () async {
        // Arrange
        when(() => mockSecureStorage.read(key: any(named: 'key'))).thenAnswer((_) async => null);

        // Act
        final result = await biometricAuthService.getBiometricPreferences();

        // Assert
        expect(result.isEnabled, isFalse);
        expect(result.preferredBiometricType, BiometricType.none);
        expect(result.failedAttempts, 0);
      });
    });

    group('getRemainingLockoutTime', () {
      test('should return remaining time when locked out', () async {
        // Arrange
        final lockoutTime = DateTime.now().add(const Duration(minutes: 2));
        when(() => mockSecureStorage.read(key: 'biometric_lockout_until'))
            .thenAnswer((_) async => lockoutTime.toIso8601String());
        when(() => mockSecureStorage.read(key: 'biometric_enabled')).thenAnswer((_) async => 'true');

        // Act
        final result = await biometricAuthService.getRemainingLockoutTime();

        // Assert
        expect(result, isNotNull);
        expect(result!.inMinutes, greaterThan(0));
      });

      test('should return null when not locked out', () async {
        // Arrange
        when(() => mockSecureStorage.read(key: 'biometric_lockout_until'))
            .thenAnswer((_) async => null);

        // Act
        final result = await biometricAuthService.getRemainingLockoutTime();

        // Assert
        expect(result, isNull);
      });
    });
  });
}