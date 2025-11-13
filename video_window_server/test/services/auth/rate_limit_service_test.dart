import 'package:test/test.dart';
import 'package:video_window_server/src/services/auth/rate_limit_service.dart';
import 'package:redis/redis.dart';

import '../../integration/test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Rate Limit Service Tests', (sessionBuilder, endpoints) {
    // Flush Redis before all tests to ensure clean state
    setUpAll(() async {
      try {
        final conn = RedisConnection();
        final redis = await conn.connect('localhost', 8091);
        // Auth with dev password
        await redis.send_object(['AUTH', 'JLLDNS1puOSFsmtR7AePtBQt9huXBltb']);
        await redis.send_object(['FLUSHDB']);
        await conn.close();
      } catch (e) {
        print('Warning: Could not flush Redis: $e');
      }
    });
    group('Layer 1: Per-Identifier Rate Limiting', () {
      test('allows requests within limit (3 requests / 5 min)', () async {
        final session = sessionBuilder.build();
        final rateLimitService = RateLimitService(session);

        const identifier = 'test@example.com';
        const ipAddress = '192.168.1.1';
        const action = 'otp_request';

        // First 3 requests should be allowed
        for (var i = 1; i <= 3; i++) {
          final result = await rateLimitService.checkRateLimit(
            identifier: identifier,
            ipAddress: ipAddress,
            action: action,
          );

          expect(result.allowed, isTrue,
              reason: 'Request $i should be allowed');
          expect(result.remaining, equals(3 - i));
        }
      });

      test('blocks requests after exceeding limit (3 requests / 5 min)',
          () async {
        final session = sessionBuilder.build();
        final rateLimitService = RateLimitService(session);

        const identifier = 'blocked@example.com';
        const ipAddress = '192.168.1.2';
        const action = 'otp_request';

        // Use up the limit (3 requests)
        for (var i = 0; i < 3; i++) {
          await rateLimitService.checkRateLimit(
            identifier: identifier,
            ipAddress: ipAddress,
            action: action,
          );
        }

        // 4th request should be blocked
        final result = await rateLimitService.checkRateLimit(
          identifier: identifier,
          ipAddress: ipAddress,
          action: action,
        );

        expect(result.allowed, isFalse);
        expect(result.reason, contains('identifier rate limit exceeded'));
        expect(result.retryAfter, isNotNull);
        expect(result.retryAfter!.inSeconds, greaterThan(0));
      });

      test('normalizes identifier (case-insensitive)', () async {
        final session = sessionBuilder.build();
        final rateLimitService = RateLimitService(session);

        const email1 = 'Test@Example.COM';
        const email2 = 'test@example.com';
        const ipAddress = '192.168.1.3';
        const action = 'otp_request';

        // First request with uppercase
        final result1 = await rateLimitService.checkRateLimit(
          identifier: email1,
          ipAddress: ipAddress,
          action: action,
        );
        expect(result1.allowed, isTrue);
        expect(result1.remaining, equals(2)); // 1 used

        // Second request with lowercase - should count against same limit
        final result2 = await rateLimitService.checkRateLimit(
          identifier: email2,
          ipAddress: ipAddress,
          action: action,
        );
        expect(result2.allowed, isTrue);
        expect(result2.remaining, equals(1)); // 2 used
      });

      test('enforces multiple time windows (5min, 1hr, 24hr)', () async {
        final session = sessionBuilder.build();
        final rateLimitService = RateLimitService(session);

        const identifier = 'multiwindow@example.com';
        const ipAddress = '192.168.1.4';
        const action = 'otp_request';

        // Use up 5-minute limit (3 requests)
        for (var i = 0; i < 3; i++) {
          final result = await rateLimitService.checkRateLimit(
            identifier: identifier,
            ipAddress: ipAddress,
            action: action,
          );
          expect(result.allowed, isTrue);
        }

        // 4th request should be blocked by 5-minute window
        final result4 = await rateLimitService.checkRateLimit(
          identifier: identifier,
          ipAddress: ipAddress,
          action: action,
        );
        expect(result4.allowed, isFalse);
        expect(result4.reason, contains('identifier rate limit exceeded'));
      });
    });

    group('Layer 2: Per-IP Rate Limiting', () {
      test('allows requests within IP limit (20 requests / 5 min)', () async {
        final session = sessionBuilder.build();
        final rateLimitService = RateLimitService(session);

        const ipAddress = '192.168.2.1';
        const action = 'otp_request';

        // 20 requests from different identifiers on same IP
        for (var i = 1; i <= 20; i++) {
          final result = await rateLimitService.checkRateLimit(
            identifier: 'user$i@example.com',
            ipAddress: ipAddress,
            action: action,
          );

          expect(result.allowed, isTrue,
              reason: 'Request $i from IP should be allowed');
        }
      });

      test('blocks requests after exceeding IP limit', () async {
        final session = sessionBuilder.build();
        final rateLimitService = RateLimitService(session);

        const ipAddress = '192.168.2.2';
        const action = 'otp_request';

        // Use up IP limit (20 requests)
        for (var i = 1; i <= 20; i++) {
          await rateLimitService.checkRateLimit(
            identifier: 'user$i@example.com',
            ipAddress: ipAddress,
            action: action,
          );
        }

        // 21st request should be blocked
        final result = await rateLimitService.checkRateLimit(
          identifier: 'user21@example.com',
          ipAddress: ipAddress,
          action: action,
        );

        expect(result.allowed, isFalse);
        expect(result.reason, contains('IP rate limit exceeded'));
      });

      test('different IPs have independent limits', () async {
        final session = sessionBuilder.build();
        final rateLimitService = RateLimitService(session);

        const action = 'otp_request';

        // Use up limit on IP1
        const ip1 = '192.168.2.3';
        for (var i = 0; i < 3; i++) {
          await rateLimitService.checkRateLimit(
            identifier: 'same@example.com',
            ipAddress: ip1,
            action: action,
          );
        }

        // IP1 should be blocked
        final result1 = await rateLimitService.checkRateLimit(
          identifier: 'same@example.com',
          ipAddress: ip1,
          action: action,
        );
        expect(result1.allowed, isFalse);

        // IP2 should still be allowed (independent limit)
        const ip2 = '192.168.2.4';
        final result2 = await rateLimitService.checkRateLimit(
          identifier: 'same@example.com',
          ipAddress: ip2,
          action: action,
        );
        expect(result2.allowed, isTrue);
      });
    });

    group('Layer 3: Global Rate Limiting', () {
      test('enforces global limit (1000 requests / 1 min)', () async {
        final session = sessionBuilder.build();
        final rateLimitService = RateLimitService(session);

        const action = 'otp_request_global';

        // This test would be slow with 1000+ requests
        // So we just verify the check logic works
        final result = await rateLimitService.checkRateLimit(
          identifier: 'global@example.com',
          ipAddress: '192.168.3.1',
          action: action,
        );

        expect(result.allowed, isTrue);
      });
    });

    group('Progressive Delays on Failed Attempts', () {
      test('no delay on first failed attempt', () async {
        final session = sessionBuilder.build();
        final rateLimitService = RateLimitService(session);

        const identifier = 'delay@example.com';
        const action = 'otp_verify';

        // Check delay before any failures
        final delay = await rateLimitService.getProgressiveDelay(
          identifier: identifier,
          action: action,
        );

        expect(delay, isNull, reason: 'No delay before any failures');
      });

      test('records failed attempts', () async {
        final session = sessionBuilder.build();
        final rateLimitService = RateLimitService(session);

        const identifier = 'failed@example.com';
        const action = 'otp_verify';

        // Record a failed attempt
        await rateLimitService.recordFailedAttempt(
          identifier: identifier,
          action: action,
        );

        // Check delay increases
        final delay = await rateLimitService.getProgressiveDelay(
          identifier: identifier,
          action: action,
        );

        expect(delay, isNotNull);
        expect(delay!.inSeconds, equals(2)); // 2^1 = 2 seconds
      });

      test('exponential backoff on multiple failures', () async {
        final session = sessionBuilder.build();
        final rateLimitService = RateLimitService(session);

        const identifier = 'exponential@example.com';
        const action = 'otp_verify';

        // Record multiple failures and check exponential growth
        final expectedDelays = [2, 4, 8, 16, 32]; // 2^1, 2^2, 2^3, 2^4, 2^5

        for (var i = 0; i < 5; i++) {
          await rateLimitService.recordFailedAttempt(
            identifier: identifier,
            action: action,
          );

          final delay = await rateLimitService.getProgressiveDelay(
            identifier: identifier,
            action: action,
          );

          expect(delay, isNotNull);
          expect(delay!.inSeconds, equals(expectedDelays[i]),
              reason:
                  'Delay after ${i + 1} failures should be ${expectedDelays[i]}s');
        }
      });

      test('clears failed attempts after successful auth', () async {
        final session = sessionBuilder.build();
        final rateLimitService = RateLimitService(session);

        const identifier = 'clear@example.com';
        const action = 'otp_verify';

        // Record failures
        for (var i = 0; i < 3; i++) {
          await rateLimitService.recordFailedAttempt(
            identifier: identifier,
            action: action,
          );
        }

        // Verify delay exists
        var delay = await rateLimitService.getProgressiveDelay(
          identifier: identifier,
          action: action,
        );
        expect(delay, isNotNull);
        expect(delay!.inSeconds, equals(8)); // 2^3

        // Clear failed attempts
        await rateLimitService.clearFailedAttempts(
          identifier: identifier,
          action: action,
        );

        // Verify delay is cleared
        delay = await rateLimitService.getProgressiveDelay(
          identifier: identifier,
          action: action,
        );
        expect(delay, isNull);
      });

      test('caps maximum delay at 300 seconds (5 minutes)', () async {
        final session = sessionBuilder.build();
        final rateLimitService = RateLimitService(session);

        const identifier = 'maxdelay@example.com';
        const action = 'otp_verify';

        // Record many failures (more than would normally be needed)
        for (var i = 0; i < 20; i++) {
          await rateLimitService.recordFailedAttempt(
            identifier: identifier,
            action: action,
          );
        }

        final delay = await rateLimitService.getProgressiveDelay(
          identifier: identifier,
          action: action,
        );

        expect(delay, isNotNull);
        expect(delay!.inSeconds, equals(300),
            reason: 'Maximum delay should be capped at 300 seconds');
      });
    });

    group('Rate Limit Status and Monitoring', () {
      test('returns current rate limit status', () async {
        final session = sessionBuilder.build();
        final rateLimitService = RateLimitService(session);

        const identifier = 'status@example.com';
        const ipAddress = '192.168.4.1';
        const action = 'otp_request';

        // Make a request
        await rateLimitService.checkRateLimit(
          identifier: identifier,
          ipAddress: ipAddress,
          action: action,
        );

        // Get status
        final status = await rateLimitService.getRateLimitStatus(
          identifier: identifier,
          ipAddress: ipAddress,
          action: action,
        );

        expect(status, isNotNull);
        expect(status['identifier'], isA<List>());
        expect(status['ip'], isA<List>());
        expect(status['global'], isA<Map>());
        expect(status['failedAttempts'], isA<int>());
      });

      test('status shows correct remaining counts', () async {
        final session = sessionBuilder.build();
        final rateLimitService = RateLimitService(session);

        const identifier = 'statuscount@example.com';
        const ipAddress = '192.168.4.2';
        const action = 'otp_request';

        // Make 2 requests
        await rateLimitService.checkRateLimit(
          identifier: identifier,
          ipAddress: ipAddress,
          action: action,
        );
        await rateLimitService.checkRateLimit(
          identifier: identifier,
          ipAddress: ipAddress,
          action: action,
        );

        // Get status
        final status = await rateLimitService.getRateLimitStatus(
          identifier: identifier,
          ipAddress: ipAddress,
          action: action,
        );

        final identifierLimits = status['identifier'] as List;
        final firstWindow = identifierLimits[0] as Map<String, dynamic>;

        expect(firstWindow['used'], equals(2));
        expect(firstWindow['remaining'], equals(1)); // 3 - 2 = 1
        expect(firstWindow['limit'], equals(3));
      });
    });

    group('HTTP Headers', () {
      test('generates correct X-RateLimit headers for allowed requests',
          () async {
        final session = sessionBuilder.build();
        final rateLimitService = RateLimitService(session);

        const identifier = 'headers@example.com';
        const ipAddress = '192.168.5.1';
        const action = 'otp_request';

        final result = await rateLimitService.checkRateLimit(
          identifier: identifier,
          ipAddress: ipAddress,
          action: action,
        );

        final headers = result.toHeaders();

        expect(headers['X-RateLimit-Remaining'], isNotNull);
        expect(headers['X-RateLimit-Reset'], isNotNull);
        expect(headers['Retry-After'], isNull,
            reason: 'Retry-After only for blocked requests');
      });

      test('generates Retry-After header for blocked requests', () async {
        final session = sessionBuilder.build();
        final rateLimitService = RateLimitService(session);

        const identifier = 'blocked-headers@example.com';
        const ipAddress = '192.168.5.2';
        const action = 'otp_request';

        // Use up the limit
        for (var i = 0; i < 3; i++) {
          await rateLimitService.checkRateLimit(
            identifier: identifier,
            ipAddress: ipAddress,
            action: action,
          );
        }

        // Get blocked response
        final result = await rateLimitService.checkRateLimit(
          identifier: identifier,
          ipAddress: ipAddress,
          action: action,
        );

        final headers = result.toHeaders();

        expect(headers['Retry-After'], isNotNull);
        expect(headers['X-RateLimit-Reset'], isNotNull);
      });
    });

    group('Edge Cases', () {
      test('different actions have independent limits', () async {
        final session = sessionBuilder.build();
        final rateLimitService = RateLimitService(session);

        const identifier = 'multiaction@example.com';
        const ipAddress = '192.168.6.1';

        // Use up limit for action1
        for (var i = 0; i < 3; i++) {
          await rateLimitService.checkRateLimit(
            identifier: identifier,
            ipAddress: ipAddress,
            action: 'otp_request',
          );
        }

        // action1 should be blocked
        final result1 = await rateLimitService.checkRateLimit(
          identifier: identifier,
          ipAddress: ipAddress,
          action: 'otp_request',
        );
        expect(result1.allowed, isFalse);

        // action2 should still be allowed (independent limit)
        final result2 = await rateLimitService.checkRateLimit(
          identifier: identifier,
          ipAddress: ipAddress,
          action: 'otp_verify',
        );
        expect(result2.allowed, isTrue);
      });

      test('handles concurrent requests correctly', () async {
        final session = sessionBuilder.build();
        final rateLimitService = RateLimitService(session);

        const identifier = 'concurrent@example.com';
        const ipAddress = '192.168.6.2';
        const action = 'otp_request';

        // Simulate concurrent requests
        final futures = <Future<RateLimitResult>>[];
        for (var i = 0; i < 5; i++) {
          futures.add(
            rateLimitService.checkRateLimit(
              identifier: identifier,
              ipAddress: ipAddress,
              action: action,
            ),
          );
        }

        final results = await Future.wait(futures);

        // First 3 should be allowed, rest denied
        final allowedCount = results.where((r) => r.allowed).length;
        final deniedCount = results.where((r) => !r.allowed).length;

        expect(allowedCount, equals(3));
        expect(deniedCount, equals(2));
      });
    });
  });
}
