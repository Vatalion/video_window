import 'dart:async';

import 'package:test/test.dart';
import 'package:video_window_server/src/services/logger.dart';

void main() {
  group('AppLogger', () {
    test('creates logger with correct name and service', () {
      final logger = AppLogger(name: 'TestLogger', service: 'test_service');
      expect(logger, isNotNull);
    });

    test('generates unique correlation IDs', () {
      final id1 = AppLogger.generateCorrelationId();
      final id2 = AppLogger.generateCorrelationId();

      expect(id1, isNot(equals(id2)));
      expect(id1, isA<String>());
      expect(id1.length, greaterThan(0));
    });

    test('correlation ID propagates through Zone', () async {
      final customId = 'custom-correlation-id-123';

      await AppLogger.withCorrelationId(customId, () async {
        expect(Zone.current[#correlationId], customId);
      });
    });

    test('sanitizes PAN (card numbers)', () {
      final sanitized =
          AppLogger.sanitizePII('Card number is 4532015112830366');
      expect(sanitized, isNot(contains('4532015112830366')));
      expect(sanitized, contains('***REDACTED***'));
    });

    test('sanitizes email addresses', () {
      final sanitized = AppLogger.sanitizePII('User email: user@example.com');
      expect(sanitized, contains('***REDACTED***'));
      expect(sanitized, isNot(contains('user@example.com')));
    });

    test('sanitizes passwords', () {
      final sanitized = AppLogger.sanitizePII('password=secret123');
      expect(sanitized, contains('***REDACTED***'));
      expect(sanitized, isNot(contains('secret123')));
    });

    test('sanitizes API keys', () {
      final sanitized = AppLogger.sanitizePII('api_key=sk_test_12345');
      expect(sanitized, contains('***REDACTED***'));
      expect(sanitized, isNot(contains('sk_test_12345')));
    });

    test('sanitizes tokens', () {
      final sanitized =
          AppLogger.sanitizePII('token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9');
      expect(sanitized, contains('***REDACTED***'));
      expect(
          sanitized, isNot(contains('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9')));
    });

    test('PII sanitization handles multiple patterns', () {
      final message =
          'User user@example.com with card 4532015112830366 and password=secret123';
      final sanitized = AppLogger.sanitizePII(message);

      expect(sanitized, isNot(contains('user@example.com')));
      expect(sanitized, isNot(contains('4532015112830366')));
      expect(sanitized, isNot(contains('secret123')));
    });

    test('sanitization preserves non-PII content', () {
      final message = 'User logged in successfully';
      final sanitized = AppLogger.sanitizePII(message);
      expect(sanitized, equals(message));
    });

    test('sanitization handles empty string', () {
      final sanitized = AppLogger.sanitizePII('');
      expect(sanitized, isEmpty);
    });
  });
}
