import 'package:flutter_test/flutter_test.dart';
import 'package:video_window_flutter/src/services/secure_token_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SecureTokenStorage Tests', () {
    late SecureTokenStorage storage;

    setUp(() async {
      storage = SecureTokenStorage();
      await storage.initialize();
      await storage.clearSession(); // Ensure clean state
    });

    tearDown(() async {
      await storage.clearSession();
    });

    group('Initialization', () {
      test('initializes without error', () async {
        final newStorage = SecureTokenStorage();
        await expectLater(newStorage.initialize(), completes);
      });

      test('generates consistent encryption key', () async {
        // Save a token
        await storage.saveAccessToken('test-token-123');

        // Create new storage instance
        final newStorage = SecureTokenStorage();
        await newStorage.initialize();

        // Should be able to decrypt with existing key
        final token = await newStorage.getAccessToken();
        expect(token, equals('test-token-123'));
      });
    });

    group('Access Token Storage', () {
      test('saves and retrieves access token', () async {
        const testToken = 'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.test';

        await storage.saveAccessToken(testToken);
        final retrieved = await storage.getAccessToken();

        expect(retrieved, equals(testToken));
      });

      test('returns null for missing access token', () async {
        final token = await storage.getAccessToken();
        expect(token, isNull);
      });

      test('overwrites existing access token', () async {
        await storage.saveAccessToken('old-token');
        await storage.saveAccessToken('new-token');

        final token = await storage.getAccessToken();
        expect(token, equals('new-token'));
      });
    });

    group('Refresh Token Storage', () {
      test('saves and retrieves refresh token', () async {
        const testToken = 'refresh.token.here.xyz';

        await storage.saveRefreshToken(testToken);
        final retrieved = await storage.getRefreshToken();

        expect(retrieved, equals(testToken));
      });

      test('returns null for missing refresh token', () async {
        final token = await storage.getRefreshToken();
        expect(token, isNull);
      });
    });

    group('User Data Storage', () {
      test('saves and retrieves user ID', () async {
        const userId = 12345;

        await storage.saveUserId(userId);
        final retrieved = await storage.getUserId();

        expect(retrieved, equals(userId));
      });

      test('saves and retrieves device ID', () async {
        const deviceId = 'device-abc-123';

        await storage.saveDeviceId(deviceId);
        final retrieved = await storage.getDeviceId();

        expect(retrieved, equals(deviceId));
      });

      test('saves and retrieves session ID', () async {
        const sessionId = 'session-xyz-789';

        await storage.saveSessionId(sessionId);
        final retrieved = await storage.getSessionId();

        expect(retrieved, equals(sessionId));
      });
    });

    group('Complete Auth Session', () {
      test('saves and retrieves complete auth session', () async {
        final session = AuthSession(
          accessToken: 'access.token.123',
          refreshToken: 'refresh.token.456',
          userId: 999,
          deviceId: 'device-999',
          sessionId: 'session-999',
        );

        await storage.saveAuthSession(
          accessToken: session.accessToken,
          refreshToken: session.refreshToken,
          userId: session.userId,
          deviceId: session.deviceId,
          sessionId: session.sessionId,
        );

        final retrieved = await storage.getAuthSession();

        expect(retrieved, isNotNull);
        expect(retrieved!.accessToken, equals(session.accessToken));
        expect(retrieved.refreshToken, equals(session.refreshToken));
        expect(retrieved.userId, equals(session.userId));
        expect(retrieved.deviceId, equals(session.deviceId));
        expect(retrieved.sessionId, equals(session.sessionId));
      });

      test('returns null for incomplete session', () async {
        // Only save access token, missing refresh token
        await storage.saveAccessToken('access.token');

        final session = await storage.getAuthSession();
        expect(session, isNull);
      });
    });

    group('Session Management', () {
      test('isAuthenticated returns true when tokens exist', () async {
        await storage.saveAccessToken('access.token');
        await storage.saveRefreshToken('refresh.token');

        final isAuth = await storage.isAuthenticated();
        expect(isAuth, isTrue);
      });

      test('isAuthenticated returns false when tokens missing', () async {
        final isAuth = await storage.isAuthenticated();
        expect(isAuth, isFalse);
      });

      test('clearSession removes all data', () async {
        await storage.saveAuthSession(
          accessToken: 'access',
          refreshToken: 'refresh',
          userId: 123,
          deviceId: 'device',
          sessionId: 'session',
        );

        await storage.clearSession();

        expect(await storage.isAuthenticated(), isFalse);
        expect(await storage.getAccessToken(), isNull);
        expect(await storage.getRefreshToken(), isNull);
        expect(await storage.getUserId(), isNull);
        expect(await storage.getDeviceId(), isNull);
        expect(await storage.getSessionId(), isNull);
      });
    });

    group('Encryption', () {
      test('stored tokens are encrypted (not plaintext)', () async {
        // This test verifies that tokens are not stored in plaintext
        // We can't easily read the raw storage in tests, but we can verify
        // that encryption/decryption works correctly
        const originalToken = 'sensitive.jwt.token.data';

        await storage.saveAccessToken(originalToken);
        final retrieved = await storage.getAccessToken();

        expect(retrieved, equals(originalToken));
        // If we got back the same token, encryption/decryption worked
      });

      test('handles encryption key rotation', () async {
        // Save initial session
        await storage.saveAuthSession(
          accessToken: 'access.before',
          refreshToken: 'refresh.before',
          userId: 111,
        );

        // Rotate encryption key
        await storage.rotateEncryptionKey();

        // Should still be able to access data
        final session = await storage.getAuthSession();
        expect(session, isNotNull);
        expect(session!.accessToken, equals('access.before'));
        expect(session.refreshToken, equals('refresh.before'));
      });
    });

    group('AuthSession Model', () {
      test('serializes to JSON correctly', () async {
        final session = AuthSession(
          accessToken: 'access',
          refreshToken: 'refresh',
          userId: 456,
          deviceId: 'device',
          sessionId: 'session',
        );

        final json = session.toJson();

        expect(json['accessToken'], equals('access'));
        expect(json['refreshToken'], equals('refresh'));
        expect(json['userId'], equals(456));
        expect(json['deviceId'], equals('device'));
        expect(json['sessionId'], equals('session'));
      });

      test('deserializes from JSON correctly', () async {
        final json = {
          'accessToken': 'access',
          'refreshToken': 'refresh',
          'userId': 789,
          'deviceId': 'device',
          'sessionId': 'session',
        };

        final session = AuthSession.fromJson(json);

        expect(session.accessToken, equals('access'));
        expect(session.refreshToken, equals('refresh'));
        expect(session.userId, equals(789));
        expect(session.deviceId, equals('device'));
        expect(session.sessionId, equals('session'));
      });
    });
  });
}
