import 'package:test/test.dart';
import 'package:video_window_server/src/services/auth/account_lockout_service.dart';
import 'package:redis/redis.dart';

import '../../integration/test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Account Lockout Service Tests', (sessionBuilder, endpoints) {
    setUpAll(() async {
      try {
        final conn = RedisConnection();
        final redis = await conn.connect('localhost', 8091);
        await redis.send_object(['AUTH', 'JLLDNS1puOSFsmtR7AePtBQt9huXBltb']);
        await redis.send_object(['FLUSHDB']);
        await conn.close();
      } catch (e) {
        print('Warning: Could not flush Redis: $e');
      }
    });

    group('Lockout Thresholds', () {
      test('no lock before threshold', () async {
        final session = await sessionBuilder.build();
        final lockoutService = AccountLockoutService(session);

        const identifier = 'test1@example.com';
        const action = 'otp_verify';

        // 2 failed attempts (below 3 threshold)
        await lockoutService.recordFailedAttempt(
            identifier: identifier, action: action);
        await lockoutService.recordFailedAttempt(
            identifier: identifier, action: action);

        final status = await lockoutService.checkLockStatus(
            identifier: identifier, action: action);
        expect(status.isLocked, isFalse);
        expect(status.failedAttempts, equals(2));
      });

      test('3 failures trigger 5-minute lock', () async {
        final session = await sessionBuilder.build();
        final lockoutService = AccountLockoutService(session);

        const identifier = 'test2@example.com';
        const action = 'otp_verify';

        for (var i = 0; i < 3; i++) {
          await lockoutService.recordFailedAttempt(
              identifier: identifier, action: action);
        }

        final status = await lockoutService.checkLockStatus(
            identifier: identifier, action: action);
        expect(status.isLocked, isTrue);
        expect(status.remainingDuration, isNotNull);
        expect(status.remainingDuration!.inMinutes, lessThanOrEqualTo(5));
      });

      test('5 failures trigger 30-minute lock', () async {
        final session = await sessionBuilder.build();
        final lockoutService = AccountLockoutService(session);

        const identifier = 'test3@example.com';
        const action = 'otp_verify';

        for (var i = 0; i < 5; i++) {
          await lockoutService.recordFailedAttempt(
              identifier: identifier, action: action);
        }

        final status = await lockoutService.checkLockStatus(
            identifier: identifier, action: action);
        expect(status.isLocked, isTrue);
        expect(status.remainingDuration!.inMinutes, greaterThan(5));
        expect(status.remainingDuration!.inMinutes, lessThanOrEqualTo(30));
      });

      test('10 failures trigger 1-hour lock', () async {
        final session = await sessionBuilder.build();
        final lockoutService = AccountLockoutService(session);

        const identifier = 'test4@example.com';
        const action = 'otp_verify';

        for (var i = 0; i < 10; i++) {
          await lockoutService.recordFailedAttempt(
              identifier: identifier, action: action);
        }

        final status = await lockoutService.checkLockStatus(
            identifier: identifier, action: action);
        expect(status.isLocked, isTrue);
        expect(status.remainingDuration!.inMinutes, greaterThan(30));
        expect(status.remainingDuration!.inMinutes, lessThanOrEqualTo(60));
      });

      test('15 failures trigger 24-hour lock', () async {
        final session = await sessionBuilder.build();
        final lockoutService = AccountLockoutService(session);

        const identifier = 'test5@example.com';
        const action = 'otp_verify';

        for (var i = 0; i < 15; i++) {
          await lockoutService.recordFailedAttempt(
              identifier: identifier, action: action);
        }

        final status = await lockoutService.checkLockStatus(
            identifier: identifier, action: action);
        expect(status.isLocked, isTrue);
        expect(status.remainingDuration!.inHours, greaterThan(1));
        expect(status.remainingDuration!.inHours, lessThanOrEqualTo(24));
      });
    });

    group('Lock Management', () {
      test('clearFailedAttempts resets counter and removes lock', () async {
        final session = await sessionBuilder.build();
        final lockoutService = AccountLockoutService(session);

        const identifier = 'test6@example.com';
        const action = 'otp_verify';

        // Trigger lock
        for (var i = 0; i < 3; i++) {
          await lockoutService.recordFailedAttempt(
              identifier: identifier, action: action);
        }

        var status = await lockoutService.checkLockStatus(
            identifier: identifier, action: action);
        expect(status.isLocked, isTrue);

        // Clear attempts
        await lockoutService.clearFailedAttempts(
            identifier: identifier, action: action);

        status = await lockoutService.checkLockStatus(
            identifier: identifier, action: action);
        expect(status.isLocked, isFalse);
        expect(status.failedAttempts, equals(0));
      });

      test('unlockAccount removes lock manually', () async {
        final session = await sessionBuilder.build();
        final lockoutService = AccountLockoutService(session);

        const identifier = 'test7@example.com';
        const action = 'otp_verify';

        // Trigger lock
        for (var i = 0; i < 3; i++) {
          await lockoutService.recordFailedAttempt(
              identifier: identifier, action: action);
        }

        var status = await lockoutService.checkLockStatus(
            identifier: identifier, action: action);
        expect(status.isLocked, isTrue);

        // Manual unlock
        await lockoutService.unlockAccount(
            identifier: identifier, action: action);

        status = await lockoutService.checkLockStatus(
            identifier: identifier, action: action);
        expect(status.isLocked, isFalse);
      });
    });

    group('Lockout Statistics', () {
      test('getLockoutStats returns correct information', () async {
        final session = await sessionBuilder.build();
        final lockoutService = AccountLockoutService(session);

        const identifier = 'test8@example.com';
        const action = 'otp_verify';

        // 2 failures
        await lockoutService.recordFailedAttempt(
            identifier: identifier, action: action);
        await lockoutService.recordFailedAttempt(
            identifier: identifier, action: action);

        final stats = await lockoutService.getLockoutStats(
            identifier: identifier, action: action);

        expect(stats['failedAttempts'], equals(2));
        expect(stats['isLocked'], isFalse);
        expect(stats['nextThreshold'], equals(3));
        expect(stats['nextLockDuration'], equals(5)); // 5 minutes
      });

      test('stats show locked status when account is locked', () async {
        final session = await sessionBuilder.build();
        final lockoutService = AccountLockoutService(session);

        const identifier = 'test9@example.com';
        const action = 'otp_verify';

        // Trigger lock
        for (var i = 0; i < 3; i++) {
          await lockoutService.recordFailedAttempt(
              identifier: identifier, action: action);
        }

        final stats = await lockoutService.getLockoutStats(
            identifier: identifier, action: action);

        expect(stats['isLocked'], isTrue);
        expect(stats['remainingLockSeconds'], isNotNull);
        expect(stats['remainingLockSeconds'], greaterThan(0));
      });
    });

    group('Edge Cases', () {
      test('different identifiers have independent lockouts', () async {
        final session = await sessionBuilder.build();
        final lockoutService = AccountLockoutService(session);

        const id1 = 'user1@example.com';
        const id2 = 'user2@example.com';
        const action = 'otp_verify';

        // Lock user1
        for (var i = 0; i < 3; i++) {
          await lockoutService.recordFailedAttempt(
              identifier: id1, action: action);
        }

        final status1 = await lockoutService.checkLockStatus(
            identifier: id1, action: action);
        final status2 = await lockoutService.checkLockStatus(
            identifier: id2, action: action);

        expect(status1.isLocked, isTrue);
        expect(status2.isLocked, isFalse);
      });

      test('different actions have independent lockouts', () async {
        final session = await sessionBuilder.build();
        final lockoutService = AccountLockoutService(session);

        const identifier = 'test10@example.com';

        // Lock for otp_verify
        for (var i = 0; i < 3; i++) {
          await lockoutService.recordFailedAttempt(
              identifier: identifier, action: 'otp_verify');
        }

        final statusVerify = await lockoutService.checkLockStatus(
            identifier: identifier, action: 'otp_verify');
        final statusRequest = await lockoutService.checkLockStatus(
            identifier: identifier, action: 'otp_request');

        expect(statusVerify.isLocked, isTrue);
        expect(statusRequest.isLocked, isFalse);
      });

      test('identifiers are case-insensitive', () async {
        final session = await sessionBuilder.build();
        final lockoutService = AccountLockoutService(session);

        const action = 'otp_verify';

        // Record with uppercase
        for (var i = 0; i < 3; i++) {
          await lockoutService.recordFailedAttempt(
              identifier: 'Test@Example.COM', action: action);
        }

        // Check with lowercase
        final status = await lockoutService.checkLockStatus(
            identifier: 'test@example.com', action: action);
        expect(status.isLocked, isTrue);
      });

      test('getMessage returns human-readable lock message', () async {
        final session = await sessionBuilder.build();
        final lockoutService = AccountLockoutService(session);

        const identifier = 'test11@example.com';
        const action = 'otp_verify';

        // Trigger lock
        for (var i = 0; i < 3; i++) {
          await lockoutService.recordFailedAttempt(
              identifier: identifier, action: action);
        }

        final status = await lockoutService.checkLockStatus(
            identifier: identifier, action: action);
        final message = status.getMessage();

        expect(message, contains('locked'));
        expect(message, contains('Try again'));
      });
    });
  });
}
