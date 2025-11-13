import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:core/data/services/auth/session_service.dart';
import 'package:core/data/repositories/auth_repository.dart';

// Generate mocks with: flutter pub run build_runner build
@GenerateMocks([AuthRepository, FlutterSecureStorage])
import 'session_service_test.mocks.dart';

void main() {
  late SessionService sessionService;
  late MockAuthRepository mockAuthRepository;
  late MockFlutterSecureStorage mockSecureStorage;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockSecureStorage = MockFlutterSecureStorage();
    sessionService = SessionService(
      authRepository: mockAuthRepository,
      secureStorage: mockSecureStorage,
    );
  });

  tearDown(() {
    sessionService.dispose();
  });

  group('SessionService - Initialization', () {
    test('initialize returns false when no stored session', () async {
      when(mockSecureStorage.read(key: anyNamed('key')))
          .thenAnswer((_) async => null);

      final result = await sessionService.initialize();

      expect(result, false);
    });

    test('initialize returns true with valid stored session', () async {
      final futureExpiry = DateTime.now().add(const Duration(hours: 1));

      when(mockSecureStorage.read(key: 'auth_access_token'))
          .thenAnswer((_) async => 'access_token');
      when(mockSecureStorage.read(key: 'auth_refresh_token'))
          .thenAnswer((_) async => 'refresh_token');
      when(mockSecureStorage.read(key: 'auth_token_expiry'))
          .thenAnswer((_) async => futureExpiry.toIso8601String());
      when(mockSecureStorage.read(key: 'auth_failure_streak'))
          .thenAnswer((_) async => '0');

      final result = await sessionService.initialize();

      expect(result, true);
    });

    test('initialize attempts refresh when token is expired', () async {
      final pastExpiry = DateTime.now().subtract(const Duration(hours: 1));

      when(mockSecureStorage.read(key: 'auth_access_token'))
          .thenAnswer((_) async => 'expired_access_token');
      when(mockSecureStorage.read(key: 'auth_refresh_token'))
          .thenAnswer((_) async => 'refresh_token');
      when(mockSecureStorage.read(key: 'auth_token_expiry'))
          .thenAnswer((_) async => pastExpiry.toIso8601String());
      when(mockSecureStorage.read(key: 'auth_failure_streak'))
          .thenAnswer((_) async => '0');

      // Mock successful refresh
      when(mockAuthRepository.refreshToken('refresh_token')).thenAnswer(
        (_) async => RefreshTokenResult.success(
          tokens: AuthTokens(
            accessToken: 'new_access_token',
            refreshToken: 'new_refresh_token',
            expiresIn: 900,
          ),
        ),
      );

      when(mockSecureStorage.write(
              key: anyNamed('key'), value: anyNamed('value')))
          .thenAnswer((_) async => {});

      final result = await sessionService.initialize();

      expect(result, true);
      verify(mockAuthRepository.refreshToken('refresh_token')).called(1);
    });
  });

  group('SessionService - Token Storage', () {
    test('storeSession saves tokens and schedules refresh', () async {
      when(mockSecureStorage.write(
              key: anyNamed('key'), value: anyNamed('value')))
          .thenAnswer((_) async => {});

      await sessionService.storeSession(
        accessToken: 'access_token',
        refreshToken: 'refresh_token',
        expiresIn: 900, // 15 minutes
      );

      verify(mockSecureStorage.write(
        key: 'auth_access_token',
        value: 'access_token',
      )).called(1);
      verify(mockSecureStorage.write(
        key: 'auth_refresh_token',
        value: 'refresh_token',
      )).called(1);
      verify(mockSecureStorage.write(
        key: 'auth_token_expiry',
        value: anyNamed('value'),
      )).called(1);
      verify(mockSecureStorage.write(
        key: 'auth_failure_streak',
        value: '0',
      )).called(1);
    });

    test('storeSession resets failure streak', () async {
      when(mockSecureStorage.write(
              key: anyNamed('key'), value: anyNamed('value')))
          .thenAnswer((_) async => {});

      await sessionService.storeSession(
        accessToken: 'access_token',
        refreshToken: 'refresh_token',
        expiresIn: 900,
      );

      verify(mockSecureStorage.write(
        key: 'auth_failure_streak',
        value: '0',
      )).called(1);

      expect(sessionService.consecutiveFailures, 0);
    });
  });

  group('SessionService - Token Refresh', () {
    test('manualRefresh succeeds with valid refresh token', () async {
      when(mockSecureStorage.read(key: 'auth_refresh_token'))
          .thenAnswer((_) async => 'refresh_token');

      when(mockAuthRepository.refreshToken('refresh_token')).thenAnswer(
        (_) async => RefreshTokenResult.success(
          tokens: AuthTokens(
            accessToken: 'new_access_token',
            refreshToken: 'new_refresh_token',
            expiresIn: 900,
          ),
        ),
      );

      when(mockSecureStorage.write(
              key: anyNamed('key'), value: anyNamed('value')))
          .thenAnswer((_) async => {});

      final result = await sessionService.manualRefresh();

      expect(result, true);
      verify(mockAuthRepository.refreshToken('refresh_token')).called(1);
    });

    test('manualRefresh fails without refresh token', () async {
      when(mockSecureStorage.read(key: 'auth_refresh_token'))
          .thenAnswer((_) async => null);

      final result = await sessionService.manualRefresh();

      expect(result, false);
      verifyNever(mockAuthRepository.refreshToken(any));
    });

    test('manualRefresh handles backend error', () async {
      when(mockSecureStorage.read(key: 'auth_refresh_token'))
          .thenAnswer((_) async => 'refresh_token');

      when(mockAuthRepository.refreshToken('refresh_token')).thenAnswer(
        (_) async => RefreshTokenResult.failure(
          error: 'INVALID_TOKEN',
          message: 'Token expired',
        ),
      );

      when(mockSecureStorage.write(
              key: anyNamed('key'), value: anyNamed('value')))
          .thenAnswer((_) async => {});

      final result = await sessionService.manualRefresh();

      expect(result, false);
      expect(sessionService.consecutiveFailures, 1);
    });
  });

  group('SessionService - Failure Handling', () {
    test('consecutive failures increment counter', () async {
      when(mockSecureStorage.read(key: 'auth_refresh_token'))
          .thenAnswer((_) async => 'refresh_token');

      when(mockAuthRepository.refreshToken('refresh_token')).thenAnswer(
        (_) async => RefreshTokenResult.failure(
          error: 'NETWORK_ERROR',
          message: 'Network error',
        ),
      );

      when(mockSecureStorage.write(
              key: anyNamed('key'), value: anyNamed('value')))
          .thenAnswer((_) async => {});

      // First failure
      await sessionService.manualRefresh();
      expect(sessionService.consecutiveFailures, 1);

      // Second failure
      await sessionService.manualRefresh();
      expect(sessionService.consecutiveFailures, 2);

      // Third failure should trigger logout
      when(mockSecureStorage.deleteAll()).thenAnswer((_) async => {});

      await sessionService.manualRefresh();
      expect(sessionService.consecutiveFailures, 0); // Reset after logout
      verify(mockSecureStorage.deleteAll()).called(1);
    });
  });

  group('SessionService - Logout', () {
    test('forceLogout clears storage and revokes tokens', () async {
      when(mockSecureStorage.read(key: 'auth_access_token'))
          .thenAnswer((_) async => 'access_token');
      when(mockSecureStorage.read(key: 'auth_refresh_token'))
          .thenAnswer((_) async => 'refresh_token');

      when(mockAuthRepository.logout(
        accessToken: anyNamed('accessToken'),
        refreshToken: anyNamed('refreshToken'),
      )).thenAnswer((_) async => LogoutResult.success());

      when(mockSecureStorage.deleteAll()).thenAnswer((_) async => {});

      await sessionService.forceLogout();

      verify(mockAuthRepository.logout(
        accessToken: 'access_token',
        refreshToken: 'refresh_token',
      )).called(1);
      verify(mockSecureStorage.deleteAll()).called(1);
      expect(sessionService.consecutiveFailures, 0);
    });

    test('forceLogout clears storage even if backend call fails', () async {
      when(mockSecureStorage.read(key: 'auth_access_token'))
          .thenAnswer((_) async => 'access_token');
      when(mockSecureStorage.read(key: 'auth_refresh_token'))
          .thenAnswer((_) async => 'refresh_token');

      when(mockAuthRepository.logout(
        accessToken: anyNamed('accessToken'),
        refreshToken: anyNamed('refreshToken'),
      )).thenThrow(Exception('Network error'));

      when(mockSecureStorage.deleteAll()).thenAnswer((_) async => {});

      await sessionService.forceLogout();

      verify(mockSecureStorage.deleteAll()).called(1);
    });
  });

  group('SessionService - State Queries', () {
    test('getAccessToken returns stored token', () async {
      when(mockSecureStorage.read(key: 'auth_access_token'))
          .thenAnswer((_) async => 'access_token');

      final token = await sessionService.getAccessToken();

      expect(token, 'access_token');
    });

    test('getRefreshToken returns stored token', () async {
      when(mockSecureStorage.read(key: 'auth_refresh_token'))
          .thenAnswer((_) async => 'refresh_token');

      final token = await sessionService.getRefreshToken();

      expect(token, 'refresh_token');
    });
  });
}
