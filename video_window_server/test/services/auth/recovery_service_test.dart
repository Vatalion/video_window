import 'package:test/test.dart';
import 'package:video_window_server/src/services/auth/recovery_service.dart';
import 'package:video_window_server/src/generated/auth/recovery_token.dart';
import 'package:video_window_server/src/generated/auth/user.dart';
import 'package:video_window_server/src/generated/auth/session.dart';

import '../../integration/test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Recovery Service Tests', (sessionBuilder, endpoints) {
    group('Recovery Token Generation Tests - AC1', () {
      test('generateSecureToken creates 32-character token', () async {
        final session = await sessionBuilder.build();
        final recoveryService = RecoveryService(session);

        final token = recoveryService.generateSecureToken();
        expect(token.length, equals(64),
            reason: 'Token should be 64 hex characters (32 bytes)');
        expect(RegExp(r'^[a-f0-9]{64}$').hasMatch(token), isTrue,
            reason: 'Token should be lowercase hex');
      });

      test('generateSecureToken creates unique tokens', () async {
        final session = await sessionBuilder.build();
        final recoveryService = RecoveryService(session);

        final tokens = <String>{};
        for (var i = 0; i < 100; i++) {
          tokens.add(recoveryService.generateSecureToken());
        }
        expect(tokens.length, equals(100),
            reason: 'Should generate 100 unique tokens');
      });

      test('hashToken produces consistent hashes', () async {
        final session = await sessionBuilder.build();
        final recoveryService = RecoveryService(session);

        const token = 'test-token-12345';
        const salt = 'test-salt-12345';

        final hash1 = recoveryService.hashToken(token, salt);
        final hash2 = recoveryService.hashToken(token, salt);

        expect(hash1, equals(hash2),
            reason: 'Same token and salt should produce same hash');
      });

      test('hashToken produces different hashes with different salts',
          () async {
        final session = await sessionBuilder.build();
        final recoveryService = RecoveryService(session);

        const token = 'test-token';
        const salt1 = 'salt1';
        const salt2 = 'salt2';

        final hash1 = recoveryService.hashToken(token, salt1);
        final hash2 = recoveryService.hashToken(token, salt2);

        expect(hash1, isNot(equals(hash2)),
            reason: 'Different salts should produce different hashes');
      });
    });

    group('Recovery Token Creation Tests - AC1, AC2, AC4', () {
      test('createRecoveryToken succeeds for existing user', () async {
        final session = await sessionBuilder.build();
        final recoveryService = RecoveryService(session);

        // Create test user with unique email to avoid rate limiting
        final testEmail =
            'test-create-success-${DateTime.now().microsecondsSinceEpoch}@example.com';
        final testIp = '192.168.8.${DateTime.now().millisecond % 255}';
        final user = User(
          email: testEmail,
          role: 'viewer',
          authProvider: 'email',
          isEmailVerified: true,
          isPhoneVerified: false,
          isActive: true,
          failedAttempts: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await User.db.insertRow(session, user);

        final result = await recoveryService.createRecoveryToken(
          email: testEmail,
          deviceInfo: 'Test Device',
          ipAddress: testIp,
          userAgent: 'Test Agent',
          location: 'Test Location',
        );

        expect(result.success, isTrue,
            reason: 'Token creation failed: ${result.error}');
        expect(result.userExists, isTrue);
        expect(result.token, isNotNull);
        expect(result.token!.length, equals(64));
        expect(result.userId, equals(savedUser.id));

        // Verify token was stored in database
        final tokens = await RecoveryToken.db.find(
          session,
          where: (t) => t.userId.equals(savedUser.id!),
        );
        expect(tokens.length, equals(1));
        expect(tokens.first.email, equals(testEmail));
        expect(tokens.first.deviceInfo, equals('Test Device'));
        expect(tokens.first.ipAddress, equals(testIp));
        expect(tokens.first.used, isFalse);
        expect(tokens.first.revoked, isFalse);
        expect(tokens.first.attempts, equals(0));
      });

      test(
          'createRecoveryToken returns success but no token for non-existent user',
          () async {
        final session = await sessionBuilder.build();
        final recoveryService = RecoveryService(session);

        // Use unique email to avoid rate limiting
        final testEmail =
            'nonexistent-${DateTime.now().microsecondsSinceEpoch}@example.com';
        final testIp = '192.168.9.${DateTime.now().millisecond % 255}';

        final result = await recoveryService.createRecoveryToken(
          email: testEmail,
          deviceInfo: 'Test Device',
          ipAddress: testIp,
        );

        expect(result.success, isTrue,
            reason:
                'Should return success for security (dont reveal user existence). Error: ${result.error}');
        expect(result.userExists, isFalse);
        expect(result.token, isEmpty);
      });

      test('createRecoveryToken invalidates previous tokens', () async {
        final session = await sessionBuilder.build();
        final recoveryService = RecoveryService(session);

        // Create test user with unique email to avoid rate limiting
        final testEmail =
            'test-invalidate-${DateTime.now().microsecondsSinceEpoch}@example.com';
        final user = User(
          email: testEmail,
          role: 'viewer',
          authProvider: 'email',
          isEmailVerified: true,
          isPhoneVerified: false,
          isActive: true,
          failedAttempts: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await User.db.insertRow(session, user);

        // Create first token
        final result1 = await recoveryService.createRecoveryToken(
          email: testEmail,
          deviceInfo: 'Device 1',
          ipAddress: '192.168.10.1',
        );
        expect(result1.success, isTrue,
            reason: 'First token creation failed: ${result1.error}');

        // Wait a tiny bit to ensure distinct timestamps
        await Future.delayed(Duration(milliseconds: 10));

        // Create second token - should invalidate first
        final result2 = await recoveryService.createRecoveryToken(
          email: testEmail,
          deviceInfo: 'Device 2',
          ipAddress: '192.168.10.2',
        );
        expect(result2.success, isTrue,
            reason: 'Second token creation failed: ${result2.error}');

        // Should only have 1 unused token (previous ones invalidated via revoked=true)
        final activeTokens = await RecoveryToken.db.find(
          session,
          where: (t) =>
              t.userId.equals(savedUser.id!) &
              t.used.equals(false) &
              t.revoked.equals(false),
        );
        expect(activeTokens.length, equals(1),
            reason:
                'Should have exactly 1 active (not used, not revoked) token');
        expect(activeTokens.first.deviceInfo, equals('Device 2'));
      });

      test('createRecoveryToken enforces 15-minute expiry - AC1', () async {
        final session = await sessionBuilder.build();
        final recoveryService = RecoveryService(session);

        // Create test user with unique email to avoid rate limiting
        final testEmail =
            'test-expiry-${DateTime.now().millisecondsSinceEpoch}@example.com';
        final user = User(
          email: testEmail,
          role: 'viewer',
          authProvider: 'email',
          isEmailVerified: true,
          isPhoneVerified: false,
          isActive: true,
          failedAttempts: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await User.db.insertRow(session, user);

        final before = DateTime.now();
        final createResult = await recoveryService.createRecoveryToken(
          email: testEmail,
          deviceInfo: 'Test Device',
          ipAddress: '192.168.1.${DateTime.now().millisecond}', // Unique IP
        );
        final after = DateTime.now();

        // Verify token was created
        expect(createResult.success, isTrue,
            reason: 'Token creation failed: ${createResult.error}');
        expect(createResult.userExists, isTrue);
        expect(createResult.token, isNotEmpty);

        final tokens = await RecoveryToken.db.find(
          session,
          where: (t) => t.userId.equals(savedUser.id!),
        );
        expect(tokens.length, greaterThanOrEqualTo(1));

        final token = tokens.first;
        final expectedExpiry = before.add(Duration(minutes: 15));
        final maxExpiry = after.add(Duration(minutes: 15, seconds: 1));

        expect(
            token.expiresAt
                .isAfter(expectedExpiry.subtract(Duration(seconds: 1))),
            isTrue);
        expect(token.expiresAt.isBefore(maxExpiry), isTrue);
      });
    });

    group('Recovery Token Verification Tests - AC3, AC4', () {
      test('verifyRecoveryToken succeeds with valid token', () async {
        final session = await sessionBuilder.build();
        final recoveryService = RecoveryService(session);

        // Create test user with unique email to avoid rate limiting
        final testEmail =
            'test-verify-success-${DateTime.now().microsecondsSinceEpoch}@example.com';
        final testIp = '192.168.2.${DateTime.now().millisecond % 255}';
        final user = User(
          email: testEmail,
          role: 'viewer',
          authProvider: 'email',
          isEmailVerified: true,
          isPhoneVerified: false,
          isActive: true,
          failedAttempts: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await User.db.insertRow(session, user);

        // Create recovery token
        final createResult = await recoveryService.createRecoveryToken(
          email: testEmail,
          deviceInfo: 'Test Device',
          ipAddress: testIp,
        );

        // Verify token was created successfully
        expect(createResult.success, isTrue,
            reason:
                'Token creation should succeed. Error: ${createResult.error}');
        expect(createResult.userExists, isTrue, reason: 'User should exist');
        expect(createResult.token, isNotNull,
            reason: 'Token should not be null');
        expect(createResult.token, isNotEmpty,
            reason: 'Token should not be empty');

        final token = createResult.token!;

        // Verify token
        final verifyResult = await recoveryService.verifyRecoveryToken(
          email: testEmail,
          token: token,
          ipAddress: testIp,
        );

        expect(verifyResult.success, isTrue);
        expect(verifyResult.userId, isNotNull);
        expect(verifyResult.email, equals(testEmail));

        // Token should be marked as used (one-time use - AC1)
        final tokens = await RecoveryToken.db.find(
          session,
          where: (t) => t.email.equals(testEmail),
        );
        expect(tokens.first.used, isTrue);
        expect(tokens.first.usedAt, isNotNull);
      });

      test('verifyRecoveryToken fails with invalid token', () async {
        final session = await sessionBuilder.build();
        final recoveryService = RecoveryService(session);

        // Create test user with unique email to avoid rate limiting
        final testEmail =
            'test-verify-invalid-${DateTime.now().microsecondsSinceEpoch}@example.com';
        final testIp = '192.168.3.${DateTime.now().millisecond % 255}';
        final user = User(
          email: testEmail,
          role: 'viewer',
          authProvider: 'email',
          isEmailVerified: true,
          isPhoneVerified: false,
          isActive: true,
          failedAttempts: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await User.db.insertRow(session, user);

        // Create recovery token
        final createResult = await recoveryService.createRecoveryToken(
          email: testEmail,
          deviceInfo: 'Test Device',
          ipAddress: testIp,
        );

        // Verify token was created
        expect(createResult.success, isTrue,
            reason: 'Token creation failed: ${createResult.error}');
        expect(createResult.userExists, isTrue);

        // Try to verify with wrong token
        final verifyResult = await recoveryService.verifyRecoveryToken(
          email: testEmail,
          token: 'invalid-token-12345',
          ipAddress: testIp,
        );

        expect(verifyResult.success, isFalse);
        expect(verifyResult.error, equals('INVALID_TOKEN'));
        expect(verifyResult.attemptsRemaining, isNotNull,
            reason: 'Should have attempts remaining info');
        expect(verifyResult.attemptsRemaining, equals(2),
            reason: 'Should have 2 attempts remaining after first failure');
      });

      test('verifyRecoveryToken fails with expired token', () async {
        final session = await sessionBuilder.build();
        final recoveryService = RecoveryService(session);

        // Create test user with unique email to avoid rate limiting
        final testEmail =
            'test-verify-expired-${DateTime.now().microsecondsSinceEpoch}@example.com';
        final testIp = '192.168.4.${DateTime.now().millisecond % 255}';
        final user = User(
          email: testEmail,
          role: 'viewer',
          authProvider: 'email',
          isEmailVerified: true,
          isPhoneVerified: false,
          isActive: true,
          failedAttempts: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await User.db.insertRow(session, user);

        // Create recovery token
        final createResult = await recoveryService.createRecoveryToken(
          email: testEmail,
          deviceInfo: 'Test Device',
          ipAddress: testIp,
        );

        // Verify token was created
        expect(createResult.success, isTrue,
            reason: 'Token creation failed: ${createResult.error}');
        expect(createResult.userExists, isTrue);
        expect(createResult.token, isNotNull);
        expect(createResult.token, isNotEmpty);

        final token = createResult.token!;

        // Manually expire the token
        final tokens = await RecoveryToken.db.find(
          session,
          where: (t) => t.email.equals(testEmail),
        );
        tokens.first.expiresAt = DateTime.now().subtract(Duration(minutes: 1));
        await RecoveryToken.db.updateRow(session, tokens.first);

        // Try to verify expired token
        final verifyResult = await recoveryService.verifyRecoveryToken(
          email: testEmail,
          token: token,
          ipAddress: testIp,
        );

        expect(verifyResult.success, isFalse);
        expect(verifyResult.error, equals('TOKEN_EXPIRED'));
      });

      test('verifyRecoveryToken enforces one-time use - AC1', () async {
        final session = await sessionBuilder.build();
        final recoveryService = RecoveryService(session);

        // Create test user with unique email to avoid rate limiting
        final testEmail =
            'test-onetime-${DateTime.now().microsecondsSinceEpoch}@example.com';
        final testIp = '192.168.5.${DateTime.now().millisecond % 255}';
        final user = User(
          email: testEmail,
          role: 'viewer',
          authProvider: 'email',
          isEmailVerified: true,
          isPhoneVerified: false,
          isActive: true,
          failedAttempts: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await User.db.insertRow(session, user);

        // Create recovery token
        final createResult = await recoveryService.createRecoveryToken(
          email: testEmail,
          deviceInfo: 'Test Device',
          ipAddress: testIp,
        );

        // Verify token was created
        expect(createResult.success, isTrue,
            reason: 'Token creation failed: ${createResult.error}');
        expect(createResult.userExists, isTrue);
        expect(createResult.token, isNotNull);
        expect(createResult.token, isNotEmpty);

        final token = createResult.token!;

        // Verify token first time (should succeed)
        final firstVerify = await recoveryService.verifyRecoveryToken(
          email: testEmail,
          token: token,
          ipAddress: testIp,
        );
        expect(firstVerify.success, isTrue);

        // Try to verify same token again (should fail - AC1: one-time use)
        final secondVerify = await recoveryService.verifyRecoveryToken(
          email: testEmail,
          token: token,
          ipAddress: testIp,
        );
        expect(secondVerify.success, isFalse);
        expect(secondVerify.error, equals('TOKEN_NOT_FOUND'),
            reason: 'Used tokens should not be found');
      });

      test('verifyRecoveryToken locks account after 3 failed attempts - AC4',
          () async {
        final session = await sessionBuilder.build();
        final recoveryService = RecoveryService(session);

        // Create test user with unique email to avoid rate limiting
        final testEmail =
            'test-lockout-${DateTime.now().microsecondsSinceEpoch}@example.com';
        final testIp = '192.168.6.${DateTime.now().millisecond % 255}';
        final user = User(
          email: testEmail,
          role: 'viewer',
          authProvider: 'email',
          isEmailVerified: true,
          isPhoneVerified: false,
          isActive: true,
          failedAttempts: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await User.db.insertRow(session, user);

        // Create recovery token
        final createResult = await recoveryService.createRecoveryToken(
          email: testEmail,
          deviceInfo: 'Test Device',
          ipAddress: testIp,
        );

        // Verify token was created
        expect(createResult.success, isTrue,
            reason: 'Token creation failed: ${createResult.error}');
        expect(createResult.userExists, isTrue);

        // Attempt 1 (2 remaining)
        final attempt1 = await recoveryService.verifyRecoveryToken(
          email: testEmail,
          token: 'wrong-token-1',
          ipAddress: testIp,
        );
        expect(attempt1.success, isFalse);
        expect(attempt1.attemptsRemaining, isNotNull,
            reason: 'Should have attempts remaining info after first failure');
        expect(attempt1.attemptsRemaining, equals(2));

        // Attempt 2 (1 remaining)
        final attempt2 = await recoveryService.verifyRecoveryToken(
          email: testEmail,
          token: 'wrong-token-2',
          ipAddress: testIp,
        );
        expect(attempt2.success, isFalse);
        expect(attempt2.attemptsRemaining, equals(1));

        // Attempt 3 (0 remaining after this)
        final attempt3 = await recoveryService.verifyRecoveryToken(
          email: testEmail,
          token: 'wrong-token-3',
          ipAddress: testIp,
        );
        expect(attempt3.success, isFalse);
        expect(attempt3.attemptsRemaining, equals(0));
        expect(attempt3.error, equals('INVALID_TOKEN'),
            reason: '3rd attempt returns INVALID_TOKEN with 0 remaining');

        // Attempt 4 should be blocked by account lockout
        final attempt4 = await recoveryService.verifyRecoveryToken(
          email: testEmail,
          token: 'wrong-token-4',
          ipAddress: testIp,
        );
        expect(attempt4.success, isFalse);
        expect(attempt4.error, equals('ACCOUNT_LOCKED'),
            reason:
                '4th attempt should be blocked - account locked after 3 failures');

        // Account should be locked for 30 minutes (via AccountLockoutService)
      });
    });

    group('Recovery Token Revocation Tests - AC2', () {
      test('revokeRecoveryToken marks token as revoked', () async {
        final session = await sessionBuilder.build();
        final recoveryService = RecoveryService(session);

        // Create test user with unique email to avoid rate limiting
        final testEmail =
            'test-revoke-${DateTime.now().microsecondsSinceEpoch}@example.com';
        final testIp = '192.168.7.${DateTime.now().millisecond % 255}';
        final user = User(
          email: testEmail,
          role: 'viewer',
          authProvider: 'email',
          isEmailVerified: true,
          isPhoneVerified: false,
          isActive: true,
          failedAttempts: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await User.db.insertRow(session, user);

        // Create recovery token
        final createResult = await recoveryService.createRecoveryToken(
          email: testEmail,
          deviceInfo: 'Test Device',
          ipAddress: testIp,
        );

        // Verify token was created
        expect(createResult.success, isTrue,
            reason: 'Token creation failed: ${createResult.error}');
        expect(createResult.userExists, isTrue);
        expect(createResult.token, isNotNull);
        expect(createResult.token, isNotEmpty);

        final token = createResult.token!;

        // Revoke token (AC2: "Not You?" link)
        final revoked = await recoveryService.revokeRecoveryToken(
          email: testEmail,
          token: token,
        );
        expect(revoked, isTrue);

        // Verify token is marked as revoked
        final tokens = await RecoveryToken.db.find(
          session,
          where: (t) => t.email.equals(testEmail),
        );
        expect(tokens.first.revoked, isTrue);
        expect(tokens.first.revokedAt, isNotNull);

        // Try to verify revoked token (should fail)
        final verifyResult = await recoveryService.verifyRecoveryToken(
          email: testEmail,
          token: token,
          ipAddress: testIp,
        );
        expect(verifyResult.success, isFalse);
      });
    });

    group('Session Invalidation Tests - AC5', () {
      test('invalidateAllSessions revokes all user sessions', () async {
        final session = await sessionBuilder.build();
        final recoveryService = RecoveryService(session);

        // Create test user
        final user = User(
          email: 'test@example.com',
          role: 'viewer',
          authProvider: 'email',
          isEmailVerified: true,
          isPhoneVerified: false,
          isActive: true,
          failedAttempts: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await User.db.insertRow(session, user);

        // Create multiple active sessions
        final session1 = UserSession(
          userId: savedUser.id!,
          accessToken: 'access1',
          refreshToken: 'refresh1',
          deviceId: 'device1',
          ipAddress: '127.0.0.1',
          accessTokenExpiry: DateTime.now().add(Duration(minutes: 15)),
          refreshTokenExpiry: DateTime.now().add(Duration(days: 30)),
          isRevoked: false,
          createdAt: DateTime.now(),
          lastUsedAt: DateTime.now(),
        );
        final session2 = UserSession(
          userId: savedUser.id!,
          accessToken: 'access2',
          refreshToken: 'refresh2',
          deviceId: 'device2',
          ipAddress: '127.0.0.2',
          accessTokenExpiry: DateTime.now().add(Duration(minutes: 15)),
          refreshTokenExpiry: DateTime.now().add(Duration(days: 30)),
          isRevoked: false,
          createdAt: DateTime.now(),
          lastUsedAt: DateTime.now(),
        );

        await UserSession.db.insertRow(session, session1);
        await UserSession.db.insertRow(session, session2);

        // Invalidate all sessions (AC5)
        await recoveryService.invalidateAllSessions(savedUser.id!);

        // Verify all sessions are revoked
        final sessions = await UserSession.db.find(
          session,
          where: (t) => t.userId.equals(savedUser.id!),
        );
        expect(sessions.length, equals(2));
        expect(sessions.every((s) => s.isRevoked), isTrue,
            reason: 'All sessions should be revoked');
      });
    });
  });
}
