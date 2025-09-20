import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:encrypt/encrypt.dart';
import 'package:video_window/features/checkout/data/datasources/checkout_local_data_source.dart';
import 'package:video_window/features/checkout/domain/models/checkout_session_model.dart';
import 'package:video_window/features/checkout/domain/models/checkout_security_model.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}
class MockEncrypter extends Mock implements Encrypter {}

void main() {
  late CheckoutLocalDataSourceImpl dataSource;
  late MockSharedPreferences mockSharedPreferences;
  late MockEncrypter mockEncrypter;

  setUp(() {
    mockSharedPreferences = MockSharedPreferences();
    mockEncrypter = MockEncrypter();
    dataSource = CheckoutLocalDataSourceImpl(
      sharedPreferences: mockSharedPreferences,
      encrypter: mockEncrypter,
    );
  });

  group('CheckoutLocalDataSourceImpl', () {
    group('saveSession', () {
      test('should save session successfully', () async {
        // Arrange
        final session = CheckoutSessionModel(
          sessionId: 'test-session-id',
          userId: 'user123',
          currentStep: CheckoutStepType.shipping,
          stepData: {},
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(hours: 24)),
        );

        final sessionJson = session.toJson();
        final encryptedData = Encrypted('encrypted-data');

        when(() => mockEncrypter.encrypt(any()))
            .thenReturn(encryptedData);
        when(() => mockSharedPreferences.setString(any(), any()))
            .thenAnswer((_) async => true);

        // Act
        final result = await dataSource.saveSession(session);

        // Assert
        expect(result, isTrue);
        verify(() => mockEncrypter.encrypt(any())).called(1);
        verify(() => mockSharedPreferences.setString(
          'checkout_session_test-session-id',
          'encrypted-data',
        )).called(1);
      });

      test('should return false when encryption fails', () async {
        // Arrange
        final session = CheckoutSessionModel(
          sessionId: 'test-session-id',
          userId: 'user123',
          currentStep: CheckoutStepType.shipping,
          stepData: {},
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(hours: 24)),
        );

        when(() => mockEncrypter.encrypt(any()))
            .thenThrow(Exception('Encryption failed'));

        // Act
        final result = await dataSource.saveSession(session);

        // Assert
        expect(result, isFalse);
      });
    });

    group('getSession', () {
      test('should return session when found', () async {
        // Arrange
        final sessionId = 'test-session-id';
        final encryptedData = 'encrypted-data';
        final decryptedData = '{"sessionId":"test-session-id","userId":"user123"}';
        final expectedSession = CheckoutSessionModel(
          sessionId: sessionId,
          userId: 'user123',
          currentStep: CheckoutStepType.shipping,
          stepData: {},
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(hours: 24)),
        );

        when(() => mockSharedPreferences.getString('checkout_session_$sessionId'))
            .thenReturn(encryptedData);
        when(() => mockEncrypter.decrypt64(encryptedData))
            .thenReturn(decryptedData);

        // Act
        final result = await dataSource.getSession(sessionId);

        // Assert
        expect(result?.sessionId, equals(expectedSession.sessionId));
        expect(result?.userId, equals(expectedSession.userId));
        verify(() => mockSharedPreferences.getString('checkout_session_$sessionId')).called(1);
        verify(() => mockEncrypter.decrypt64(encryptedData)).called(1);
      });

      test('should return null when session not found', () async {
        // Arrange
        final sessionId = 'non-existent-session';

        when(() => mockSharedPreferences.getString('checkout_session_$sessionId'))
            .thenReturn(null);

        // Act
        final result = await dataSource.getSession(sessionId);

        // Assert
        expect(result, isNull);
      });
    });

    group('removeSession', () {
      test('should remove session and associated data', () async {
        // Arrange
        final sessionId = 'test-session-id';

        when(() => mockSharedPreferences.remove(any()))
            .thenAnswer((_) async => true);

        // Act
        final result = await dataSource.removeSession(sessionId);

        // Assert
        expect(result, isTrue);
        verify(() => mockSharedPreferences.remove('checkout_session_$sessionId')).called(1);
        verify(() => mockSharedPreferences.remove('checkout_security_$sessionId')).called(1);
        verify(() => mockSharedPreferences.remove('checkout_token_$sessionId')).called(1);
        verify(() => mockSharedPreferences.remove('checkout_summary_$sessionId')).called(1);
      });
    });

    group('getAllSessions', () {
      test('should return all valid sessions', () async {
        // Arrange
        final validSession = CheckoutSessionModel(
          sessionId: 'valid-session',
          userId: 'user123',
          currentStep: CheckoutStepType.shipping,
          stepData: {},
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(hours: 24)),
        );

        final expiredSession = CheckoutSessionModel(
          sessionId: 'expired-session',
          userId: 'user123',
          currentStep: CheckoutStepType.shipping,
          stepData: {},
          createdAt: DateTime.now().subtract(const Duration(hours: 25)),
          expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        );

        when(() => mockSharedPreferences.getKeys())
            .thenReturn(['checkout_session_valid-session', 'checkout_session_expired-session']);
        when(() => dataSource.getSession('valid-session'))
            .thenAnswer((_) async => validSession);
        when(() => dataSource.getSession('expired-session'))
            .thenAnswer((_) async => expiredSession);
        when(() => mockSharedPreferences.remove(any()))
            .thenAnswer((_) async => true);

        // Act
        final result = await dataSource.getAllSessions();

        // Assert
        expect(result.length, equals(1));
        expect(result.first.sessionId, equals('valid-session'));
        verify(() => mockSharedPreferences.remove('checkout_session_expired-session')).called(1);
      });
    });

    group('saveSecurityContext', () {
      test('should save security context successfully', () async {
        // Arrange
        final context = SecurityContextModel(
          sessionId: 'test-session-id',
          userId: 'user123',
          ipAddress: '192.168.1.1',
          userAgent: 'Test Browser',
          deviceFingerprint: 'test-fingerprint',
          riskLevel: RiskLevel.low,
          validationTimestamp: DateTime.now(),
        );

        final encryptedData = Encrypted('encrypted-context');

        when(() => mockEncrypter.encrypt(any()))
            .thenReturn(encryptedData);
        when(() => mockSharedPreferences.setString(any(), any()))
            .thenAnswer((_) async => true);

        // Act
        final result = await dataSource.saveSecurityContext(context);

        // Assert
        expect(result, isTrue);
        verify(() => mockEncrypter.encrypt(any())).called(1);
        verify(() => mockSharedPreferences.setString(
          'checkout_security_test-session-id',
          'encrypted-context',
        )).called(1);
      });
    });

    group('saveSessionToken', () {
      test('should save session token successfully', () async {
        // Arrange
        final sessionId = 'test-session-id';
        final token = 'test-token';
        final encryptedToken = Encrypted('encrypted-token');

        when(() => mockEncrypter.encrypt(token))
            .thenReturn(encryptedToken);
        when(() => mockSharedPreferences.setString(any(), any()))
            .thenAnswer((_) async => true);

        // Act
        final result = await dataSource.saveSessionToken(sessionId, token);

        // Assert
        expect(result, isTrue);
        verify(() => mockEncrypter.encrypt(token)).called(1);
        verify(() => mockSharedPreferences.setString(
          'checkout_token_test-session-id',
          'encrypted-token',
        )).called(1);
      });
    });

    group('getSessionToken', () {
      test('should return session token when found', () async {
        // Arrange
        final sessionId = 'test-session-id';
        final encryptedToken = 'encrypted-token';
        final decryptedToken = 'test-token';

        when(() => mockSharedPreferences.getString('checkout_token_$sessionId'))
            .thenReturn(encryptedToken);
        when(() => mockEncrypter.decrypt64(encryptedToken))
            .thenReturn(decryptedToken);

        // Act
        final result = await dataSource.getSessionToken(sessionId);

        // Assert
        expect(result, equals(decryptedToken));
        verify(() => mockSharedPreferences.getString('checkout_token_$sessionId')).called(1);
        verify(() => mockEncrypter.decrypt64(encryptedToken)).called(1);
      });

      test('should return null when token not found', () async {
        // Arrange
        final sessionId = 'non-existent-session';

        when(() => mockSharedPreferences.getString('checkout_token_$sessionId'))
            .thenReturn(null);

        // Act
        final result = await dataSource.getSessionToken(sessionId);

        // Assert
        expect(result, isNull);
      });
    });
  });
}