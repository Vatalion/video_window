import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:crypto_market/lib/features/auth/data/services/jwt_token_service.dart';
import 'package:crypto_market/lib/features/auth/domain/models/session_token_model.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late JwtTokenService jwtService;
  late MockFlutterSecureStorage mockStorage;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    jwtService = JwtTokenService(mockStorage, 'test-encryption-key');
  });

  group('JwtTokenService', () {
    const testUserId = 'test-user-id';
    const testDeviceId = 'test-device-id';
    const testAccessToken = 'test-access-token';
    const testRefreshToken = 'test-refresh-token';

    test('generateAccessToken should create a valid JWT token', () async {
      // Arrange
      final now = DateTime.now();
      final expectedExpiry = now.add(const Duration(minutes: 30));

      // Act
      final token = await jwtService.generateAccessToken(
        userId: testUserId,
        deviceId: testDeviceId,
        expiresIn: const Duration(minutes: 30),
      );

      // Assert
      expect(token, isNotEmpty);
      expect(token.split('.'), hasLength(3)); // Header.Payload.Signature

      final payload = Jwt.parseJwt(token);
      expect(payload['sub'], equals(testUserId));
      expect(payload['device_id'], equals(testDeviceId));
      expect(payload['type'], equals('access'));
      expect(payload['iat'], isNotNull);
      expect(payload['exp'], isNotNull);
      expect(payload['jti'], isNotNull);
    });

    test('generateRefreshToken should create a valid JWT token', () async {
      // Arrange
      final now = DateTime.now();
      final expectedExpiry = now.add(const Duration(days: 7));

      // Act
      final token = await jwtService.generateRefreshToken(
        userId: testUserId,
        deviceId: testDeviceId,
        expiresIn: const Duration(days: 7),
      );

      // Assert
      expect(token, isNotEmpty);
      expect(token.split('.'), hasLength(3)); // Header.Payload.Signature

      final payload = Jwt.parseJwt(token);
      expect(payload['sub'], equals(testUserId));
      expect(payload['device_id'], equals(testDeviceId));
      expect(payload['type'], equals('refresh'));
      expect(payload['iat'], isNotNull);
      expect(payload['exp'], isNotNull);
      expect(payload['jti'], isNotNull);
      expect(payload['rotation_count'], equals(0));
    });

    test('validateToken should return true for valid token', () async {
      // Arrange
      final validToken = await jwtService.generateAccessToken(
        userId: testUserId,
        deviceId: testDeviceId,
      );

      when(() => mockStorage.read(key: 'auth_device_id'))
          .thenAnswer((_) async => testDeviceId);

      // Act
      final isValid = await jwtService.validateToken(validToken);

      // Assert
      expect(isValid, isTrue);
    });

    test('validateToken should return false for expired token', () async {
      // Arrange
      final expiredToken = await jwtService.generateAccessToken(
        userId: testUserId,
        deviceId: testDeviceId,
        expiresIn: const Duration(seconds: -1), // Already expired
      );

      when(() => mockStorage.read(key: 'auth_device_id'))
          .thenAnswer((_) async => testDeviceId);

      // Act
      final isValid = await jwtService.validateToken(expiredToken);

      // Assert
      expect(isValid, isFalse);
    });

    test('validateToken should return false for token with wrong device ID', () async {
      // Arrange
      final token = await jwtService.generateAccessToken(
        userId: testUserId,
        deviceId: testDeviceId,
      );

      when(() => mockStorage.read(key: 'auth_device_id'))
          .thenAnswer((_) async => 'wrong-device-id');

      // Act
      final isValid = await jwtService.validateToken(token);

      // Assert
      expect(isValid, isFalse);
    });

    test('decodeToken should return payload for valid token', () async {
      // Arrange
      final token = await jwtService.generateAccessToken(
        userId: testUserId,
        deviceId: testDeviceId,
        payload: {'custom_claim': 'custom_value'},
      );

      // Act
      final payload = await jwtService.decodeToken(token);

      // Assert
      expect(payload['sub'], equals(testUserId));
      expect(payload['device_id'], equals(testDeviceId));
      expect(payload['type'], equals('access'));
      expect(payload['custom_claim'], equals('custom_value'));
    });

    test('decodeToken should throw exception for invalid token', () async {
      // Arrange
      const invalidToken = 'invalid.token.here';

      // Act & Assert
      expect(
        () => jwtService.decodeToken(invalidToken),
        throwsA(isA<Exception>()),
      );
    });

    test('isTokenExpired should return true for expired token', () async {
      // Arrange
      final expiredToken = await jwtService.generateAccessToken(
        userId: testUserId,
        deviceId: testDeviceId,
        expiresIn: const Duration(seconds: -1),
      );

      // Act
      final isExpired = await jwtService.isTokenExpired(expiredToken);

      // Assert
      expect(isExpired, isTrue);
    });

    test('isTokenExpired should return false for valid token', () async {
      // Arrange
      final validToken = await jwtService.generateAccessToken(
        userId: testUserId,
        deviceId: testDeviceId,
      );

      // Act
      final isExpired = await jwtService.isTokenExpired(validToken);

      // Assert
      expect(isExpired, isFalse);
    });

    test('getTokenTimeRemaining should return remaining time for valid token', () async {
      // Arrange
      final validToken = await jwtService.generateAccessToken(
        userId: testUserId,
        deviceId: testDeviceId,
        expiresIn: const Duration(minutes: 5),
      );

      // Act
      final remainingTime = await jwtService.getTokenTimeRemaining(validToken);

      // Assert
      expect(remainingTime.inSeconds, greaterThan(0));
      expect(remainingTime.inSeconds, lessThanOrEqualTo(300)); // 5 minutes
    });

    test('getTokenTimeRemaining should return Duration.zero for expired token', () async {
      // Arrange
      final expiredToken = await jwtService.generateAccessToken(
        userId: testUserId,
        deviceId: testDeviceId,
        expiresIn: const Duration(seconds: -1),
      );

      // Act
      final remainingTime = await jwtService.getTokenTimeRemaining(expiredToken);

      // Assert
      expect(remainingTime, equals(Duration.zero));
    });

    test('storeTokens should store all token data securely', () async {
      // Arrange
      final now = DateTime.now();
      final accessTokenExpiry = now.add(const Duration(minutes: 30));
      final refreshTokenExpiry = now.add(const Duration(days: 7));

      when(() => mockStorage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      )).thenAnswer((_) async {});

      // Act
      await jwtService.storeTokens(
        accessToken: testAccessToken,
        refreshToken: testRefreshToken,
        deviceId: testDeviceId,
        accessTokenExpiry: accessTokenExpiry,
        refreshTokenExpiry: refreshTokenExpiry,
      );

      // Assert
      verify(() => mockStorage.write(key: 'auth_access_token', value: any(named: 'value'))).called(1);
      verify(() => mockStorage.write(key: 'auth_refresh_token', value: any(named: 'value'))).called(1);
      verify(() => mockStorage.write(key: 'auth_token_expiry', value: accessTokenExpiry.toIso8601String())).called(1);
      verify(() => mockStorage.write(key: 'auth_refresh_expiry', value: refreshTokenExpiry.toIso8601String())).called(1);
      verify(() => mockStorage.write(key: 'auth_device_id', value: testDeviceId)).called(1);
    });

    test('getStoredTokens should return SessionTokenModel when all data exists', () async {
      // Arrange
      final now = DateTime.now();
      final accessTokenExpiry = now.add(const Duration(minutes: 30));
      final refreshTokenExpiry = now.add(const Duration(days: 7));

      final mockAccessTokenPayload = {
        'sub': testUserId,
        'device_id': testDeviceId,
        'iat': now.millisecondsSinceEpoch ~/ 1000,
        'exp': accessTokenExpiry.millisecondsSinceEpoch ~/ 1000,
        'jti': 'test-jti',
        'type': 'access',
      };

      final mockRefreshTokenPayload = {
        'sub': testUserId,
        'device_id': testDeviceId,
        'iat': now.millisecondsSinceEpoch ~/ 1000,
        'exp': refreshTokenExpiry.millisecondsSinceEpoch ~/ 1000,
        'jti': 'test-jti-refresh',
        'type': 'refresh',
      };

      when(() => mockStorage.read(key: 'auth_access_token'))
          .thenAnswer((_) async => 'encrypted-access-token');
      when(() => mockStorage.read(key: 'auth_refresh_token'))
          .thenAnswer((_) async => 'encrypted-refresh-token');
      when(() => mockStorage.read(key: 'auth_token_expiry'))
          .thenAnswer((_) async => accessTokenExpiry.toIso8601String());
      when(() => mockStorage.read(key: 'auth_refresh_expiry'))
          .thenAnswer((_) async => refreshTokenExpiry.toIso8601String());
      when(() => mockStorage.read(key: 'auth_device_id'))
          .thenAnswer((_) async => testDeviceId);

      // Mock JWT parsing
      try {
        Jwt.parseJwt = (token) {
          if (token.contains('access')) return mockAccessTokenPayload;
          return mockRefreshTokenPayload;
        };
      } catch (e) {
        // Ignore if JWT.parseJwt can't be mocked
      }

      // Act
      final tokens = await jwtService.getStoredTokens();

      // Assert
      expect(tokens, isNotNull);
      expect(tokens!.userId, equals(testUserId));
      expect(tokens.deviceId, equals(testDeviceId));
      expect(tokens.accessToken, equals('test-access-token')); // After decryption
      expect(tokens.refreshToken, equals('test-refresh-token')); // After decryption
    });

    test('getStoredTokens should return null when any required data is missing', () async {
      // Arrange
      when(() => mockStorage.read(key: 'auth_access_token'))
          .thenAnswer((_) async => null);

      // Act
      final tokens = await jwtService.getStoredTokens();

      // Assert
      expect(tokens, isNull);
    });

    test('clearTokens should remove all token data', () async {
      // Arrange
      when(() => mockStorage.delete(key: any(named: 'key')))
          .thenAnswer((_) async {});

      // Act
      await jwtService.clearTokens();

      // Assert
      verify(() => mockStorage.delete(key: 'auth_access_token')).called(1);
      verify(() => mockStorage.delete(key: 'auth_refresh_token')).called(1);
      verify(() => mockStorage.delete(key: 'auth_token_expiry')).called(1);
      verify(() => mockStorage.delete(key: 'auth_refresh_expiry')).called(1);
      verify(() => mockStorage.delete(key: 'auth_device_id')).called(1);
      verify(() => mockStorage.delete(key: 'auth_session_data')).called(1);
    });

    test('hasValidTokens should return true when tokens are valid', () async {
      // Arrange
      final mockSessionToken = SessionTokenModel(
        id: 'test-token-id',
        userId: testUserId,
        deviceId: testDeviceId,
        accessToken: testAccessToken,
        refreshToken: testRefreshToken,
        accessTokenExpiresAt: DateTime.now().add(const Duration(minutes: 30)),
        refreshTokenExpiresAt: DateTime.now().add(const Duration(days: 7)),
        issuedAt: DateTime.now(),
      );

      // Mock getStoredTokens to return valid tokens
      try {
        // This is a bit tricky to mock, so we'll test the logic indirectly
        when(() => mockStorage.read(key: 'auth_access_token'))
            .thenAnswer((_) async => 'valid-encrypted-token');
        when(() => mockStorage.read(key: 'auth_refresh_token'))
            .thenAnswer((_) async => 'valid-encrypted-token');
        when(() => mockStorage.read(key: 'auth_token_expiry'))
            .thenAnswer((_) async => DateTime.now().add(const Duration(minutes: 30)).toIso8601String());
        when(() => mockStorage.read(key: 'auth_refresh_expiry'))
            .thenAnswer((_) async => DateTime.now().add(const Duration(days: 7)).toIso8601String());
        when(() => mockStorage.read(key: 'auth_device_id'))
            .thenAnswer((_) async => testDeviceId);
      } catch (e) {
        // Handle JWT parsing issues
      }

      // Act
      final hasValidTokens = await jwtService.hasValidTokens();

      // Assert
      expect(hasValidTokens, isTrue);
    });

    test('needsTokenRefresh should return true when token needs refresh', () async {
      // Arrange
      final mockSessionToken = SessionTokenModel(
        id: 'test-token-id',
        userId: testUserId,
        deviceId: testDeviceId,
        accessToken: testAccessToken,
        refreshToken: testRefreshToken,
        accessTokenExpiresAt: DateTime.now().add(const Duration(minutes: 3)), // Expires in 3 minutes
        refreshTokenExpiresAt: DateTime.now().add(const Duration(days: 7)),
        issuedAt: DateTime.now(),
      );

      // Mock getStoredTokens to return tokens that need refresh
      try {
        when(() => mockStorage.read(key: 'auth_access_token'))
            .thenAnswer((_) async => 'encrypted-token');
        when(() => mockStorage.read(key: 'auth_refresh_token'))
            .thenAnswer((_) async => 'encrypted-token');
        when(() => mockStorage.read(key: 'auth_token_expiry'))
            .thenAnswer((_) async => DateTime.now().add(const Duration(minutes: 3)).toIso8601String());
        when(() => mockStorage.read(key: 'auth_refresh_expiry'))
            .thenAnswer((_) async => DateTime.now().add(const Duration(days: 7)).toIso8601String());
        when(() => mockStorage.read(key: 'auth_device_id'))
            .thenAnswer((_) async => testDeviceId);
      } catch (e) {
        // Handle JWT parsing issues
      }

      // Act
      final needsRefresh = await jwtService.needsTokenRefresh();

      // Assert
      expect(needsRefresh, isTrue);
    });

    test('updateAccessToken should update access token and expiry', () async {
      // Arrange
      const newAccessToken = 'new-access-token';
      final newExpiry = DateTime.now().add(const Duration(minutes: 30));

      when(() => mockStorage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      )).thenAnswer((_) async {});

      // Act
      await jwtService.updateAccessToken(newAccessToken, newExpiry);

      // Assert
      verify(() => mockStorage.write(key: 'auth_access_token', value: any(named: 'value'))).called(1);
      verify(() => mockStorage.write(key: 'auth_token_expiry', value: newExpiry.toIso8601String())).called(1);
    });

    test('rotateRefreshToken should update refresh token and expiry', () async {
      // Arrange
      const newRefreshToken = 'new-refresh-token';
      final newExpiry = DateTime.now().add(const Duration(days: 7));

      when(() => mockStorage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      )).thenAnswer((_) async {});

      // Act
      await jwtService.rotateRefreshToken(newRefreshToken, newExpiry);

      // Assert
      verify(() => mockStorage.write(key: 'auth_refresh_token', value: any(named: 'value'))).called(1);
      verify(() => mockStorage.write(key: 'auth_refresh_expiry', value: newExpiry.toIso8601String())).called(1);
    });
  });
}