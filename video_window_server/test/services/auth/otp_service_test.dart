import 'package:test/test.dart';
import 'package:video_window_server/src/services/auth/otp_service.dart';
import 'package:video_window_server/src/generated/auth/otp.dart';

import '../../integration/test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('OTP Service Tests', (sessionBuilder, endpoints) {
    group('OTP Generation Security Tests', () {
      test('generateSecureOTP creates 6-digit code', () async {
        final session = await sessionBuilder.build();
        final otpService = OtpService(session);

        final otp = otpService.generateSecureOTP();
        expect(otp.length, equals(6));
        expect(RegExp(r'^\d{6}$').hasMatch(otp), isTrue,
            reason: 'OTP should be exactly 6 digits');
      });

      test('generateSecureOTP creates unique codes', () async {
        final session = await sessionBuilder.build();
        final otpService = OtpService(session);

        final codes = <String>{};
        for (var i = 0; i < 100; i++) {
          codes.add(otpService.generateSecureOTP());
        }
        // Should have high uniqueness (allow small collision rate)
        expect(codes.length, greaterThan(95),
            reason: 'Should generate mostly unique codes');
      });

      test('hashOTP produces consistent hashes with same input', () async {
        final session = await sessionBuilder.build();
        final otpService = OtpService(session);

        const otp = '123456';
        const salt = 'test-salt-12345';

        final hash1 = otpService.hashOTP(otp, salt);
        final hash2 = otpService.hashOTP(otp, salt);

        expect(hash1, equals(hash2),
            reason: 'Same OTP and salt should produce same hash');
      });

      test('hashOTP produces different hashes with different salts', () async {
        final session = await sessionBuilder.build();
        final otpService = OtpService(session);

        const otp = '123456';
        const salt1 = 'salt1';
        const salt2 = 'salt2';

        final hash1 = otpService.hashOTP(otp, salt1);
        final hash2 = otpService.hashOTP(otp, salt2);

        expect(hash1, isNot(equals(hash2)),
            reason: 'Different salts should produce different hashes');
      });

      test('hashOTP produces different hashes with different OTPs', () async {
        final session = await sessionBuilder.build();
        final otpService = OtpService(session);

        const salt = 'test-salt';
        const otp1 = '123456';
        const otp2 = '654321';

        final hash1 = otpService.hashOTP(otp1, salt);
        final hash2 = otpService.hashOTP(otp2, salt);

        expect(hash1, isNot(equals(hash2)),
            reason: 'Different OTPs should produce different hashes');
      });

      test('OTP hash is cryptographically secure (SHA-256)', () async {
        final session = await sessionBuilder.build();
        final otpService = OtpService(session);

        const otp = '123456';
        const salt = 'test-salt';

        final hash = otpService.hashOTP(otp, salt);

        // SHA-256 produces 64-character hexadecimal string
        expect(hash.length, equals(64));
        expect(RegExp(r'^[a-f0-9]{64}$').hasMatch(hash), isTrue,
            reason: 'Hash should be 64-character hex string (SHA-256)');
      });
    });

    group('OTP Creation and Storage Tests', () {
      test('createOTP stores hashed OTP in database', () async {
        final session = await sessionBuilder.build();
        final otpService = OtpService(session);

        const identifier = 'test@example.com';

        final otp = await otpService.createOTP(identifier);

        // OTP should be 6 digits
        expect(otp.length, equals(6));
        expect(RegExp(r'^\d{6}$').hasMatch(otp), isTrue);

        // Verify OTP record was created in database
        final otpRecords = await Otp.db.find(
          session,
          where: (t) => t.identifier.equals(identifier.toLowerCase()),
        );

        expect(otpRecords, isNotEmpty,
            reason: 'OTP record should be stored in database');

        final otpRecord = otpRecords.first;
        expect(otpRecord.identifier, equals(identifier.toLowerCase()));
        expect(otpRecord.used, isFalse);
        expect(otpRecord.attempts, equals(0));
        expect(otpRecord.expiresAt.isAfter(DateTime.now()), isTrue,
            reason: 'OTP should not be expired immediately');

        // Verify stored hash is not plaintext
        expect(otpRecord.otpHash, isNot(equals(otp)),
            reason: 'Plaintext OTP should never be stored');
        expect(otpRecord.salt.isNotEmpty, isTrue,
            reason: 'User-specific salt should be stored');
      });

      test('createOTP invalidates existing OTPs for same identifier', () async {
        final session = await sessionBuilder.build();
        final otpService = OtpService(session);

        const identifier = 'test@example.com';

        // Create first OTP
        await otpService.createOTP(identifier);

        // Create second OTP (should invalidate first)
        await otpService.createOTP(identifier);

        // Find all OTPs for this identifier
        final otpRecords = await Otp.db.find(
          session,
          where: (t) => t.identifier.equals(identifier.toLowerCase()),
          orderBy: (t) => t.createdAt,
          orderDescending: true,
        );

        expect(otpRecords.length, greaterThanOrEqualTo(2));

        // Most recent should be unused
        expect(otpRecords.first.used, isFalse);

        // Older ones should be marked as used (invalidated)
        for (var i = 1; i < otpRecords.length; i++) {
          expect(otpRecords[i].used, isTrue,
              reason: 'Old OTPs should be invalidated');
        }
      });

      test('createOTP normalizes identifier (case-insensitive)', () async {
        final session = await sessionBuilder.build();
        final otpService = OtpService(session);

        const email1 = 'Test@Example.com';
        const email2 = 'test@example.com';

        await otpService.createOTP(email1);
        await otpService.createOTP(email2);

        // Both should map to same normalized identifier
        final otpRecords = await Otp.db.find(
          session,
          where: (t) => t.identifier.equals(email2),
        );

        expect(otpRecords.length, greaterThanOrEqualTo(2),
            reason: 'Both emails should create records with same identifier');
      });

      test('createOTP sets 5-minute expiry', () async {
        final session = await sessionBuilder.build();
        final otpService = OtpService(session);

        const identifier = 'test@example.com';
        final now = DateTime.now();

        await otpService.createOTP(identifier);

        final otpRecords = await Otp.db.find(
          session,
          where: (t) => t.identifier.equals(identifier.toLowerCase()),
          orderBy: (t) => t.createdAt,
          orderDescending: true,
          limit: 1,
        );

        final otpRecord = otpRecords.first;
        final expiryDuration = otpRecord.expiresAt.difference(now);

        // Should expire in approximately 5 minutes (allow 10 second variance)
        expect(expiryDuration.inSeconds, greaterThan(290)); // 4:50
        expect(expiryDuration.inSeconds, lessThan(310)); // 5:10
      });
    });

    group('OTP Verification Tests - Happy Path', () {
      test('verifyOTP succeeds with correct code', () async {
        final session = await sessionBuilder.build();
        final otpService = OtpService(session);

        const identifier = 'test@example.com';

        final otp = await otpService.createOTP(identifier);
        final result = await otpService.verifyOTP(identifier, otp);

        expect(result.success, isTrue);
        expect(result.message, equals('OTP verified successfully'));

        // Verify OTP is marked as used (one-time use)
        final otpRecords = await Otp.db.find(
          session,
          where: (t) => t.identifier.equals(identifier.toLowerCase()),
          orderBy: (t) => t.createdAt,
          orderDescending: true,
          limit: 1,
        );

        expect(otpRecords.first.used, isTrue,
            reason:
                'OTP should be marked as used after successful verification');
        expect(otpRecords.first.usedAt, isNotNull,
            reason: 'Used timestamp should be set');
      });

      test('verifyOTP is case-insensitive for identifier', () async {
        final session = await sessionBuilder.build();
        final otpService = OtpService(session);

        const email = 'Test@Example.COM';

        final otp = await otpService.createOTP(email);
        final result = await otpService.verifyOTP('test@example.com', otp);

        expect(result.success, isTrue);
      });
    });

    group('OTP Verification Tests - Failure Cases', () {
      test('verifyOTP fails with incorrect code', () async {
        final session = await sessionBuilder.build();
        final otpService = OtpService(session);

        const identifier = 'test@example.com';

        final _ = await otpService.createOTP(identifier);
        const wrongOtp = '000000'; // Incorrect code

        final result = await otpService.verifyOTP(identifier, wrongOtp);

        expect(result.success, isFalse);
        expect(result.message, equals('Invalid OTP code'));
        expect(result.attempts, equals(1),
            reason: 'Should track failed attempt');

        // Verify OTP is NOT marked as used
        final otpRecords = await Otp.db.find(
          session,
          where: (t) => t.identifier.equals(identifier.toLowerCase()),
          orderBy: (t) => t.createdAt,
          orderDescending: true,
          limit: 1,
        );

        expect(otpRecords.first.used, isFalse,
            reason: 'Failed verification should not mark OTP as used');
        expect(otpRecords.first.attempts, equals(1),
            reason: 'Failed attempts should be tracked');
      });

      test('verifyOTP fails when no OTP exists', () async {
        final session = await sessionBuilder.build();
        final otpService = OtpService(session);

        const identifier = 'nonexistent@example.com';
        const code = '123456';

        final result = await otpService.verifyOTP(identifier, code);

        expect(result.success, isFalse);
        expect(result.message, equals('No active OTP found'));
      });

      test('verifyOTP fails with expired OTP', () async {
        final session = await sessionBuilder.build();
        final otpService = OtpService(session);

        const identifier = 'test@example.com';

        final otp = await otpService.createOTP(identifier);

        // Manually expire the OTP by setting expiresAt to past
        final otpRecords = await Otp.db.find(
          session,
          where: (t) => t.identifier.equals(identifier.toLowerCase()),
          orderBy: (t) => t.createdAt,
          orderDescending: true,
          limit: 1,
        );

        final otpRecord = otpRecords.first;
        otpRecord.expiresAt = DateTime.now().subtract(Duration(seconds: 1));
        await Otp.db.updateRow(session, otpRecord);

        // Attempt to verify expired OTP
        final result = await otpService.verifyOTP(identifier, otp);

        expect(result.success, isFalse);
        expect(result.message, equals('OTP has expired'));

        // Verify OTP is marked as used (to prevent further attempts)
        final updatedRecord = await Otp.db.findById(session, otpRecord.id!);
        expect(updatedRecord!.used, isTrue,
            reason: 'Expired OTP should be marked as used');
      });

      test('verifyOTP enforces one-time use', () async {
        final session = await sessionBuilder.build();
        final otpService = OtpService(session);

        const identifier = 'test@example.com';

        final otp = await otpService.createOTP(identifier);

        // First verification succeeds
        final result1 = await otpService.verifyOTP(identifier, otp);
        expect(result1.success, isTrue);

        // Second verification with same OTP should fail
        final result2 = await otpService.verifyOTP(identifier, otp);
        expect(result2.success, isFalse);
        expect(result2.message, equals('No active OTP found'),
            reason: 'OTP should not be reusable');
      });

      test('verifyOTP blocks after max attempts (5 failures)', () async {
        final session = await sessionBuilder.build();
        final otpService = OtpService(session);

        const identifier = 'test@example.com';

        final _ = await otpService.createOTP(identifier);
        const wrongOtp = '000000';

        // Attempt 5 times with wrong code
        for (var i = 1; i <= 5; i++) {
          final result = await otpService.verifyOTP(identifier, wrongOtp);
          expect(result.success, isFalse);

          if (i < 5) {
            expect(result.attempts, equals(i));
          }
        }

        // 6th attempt should be blocked (max attempts exceeded)
        final result6 = await otpService.verifyOTP(identifier, wrongOtp);
        expect(result6.success, isFalse);
        expect(
            result6.message, equals('Maximum verification attempts exceeded'));

        // OTP should be marked as used
        final otpRecords = await Otp.db.find(
          session,
          where: (t) => t.identifier.equals(identifier.toLowerCase()),
        );
        expect(otpRecords.first.used, isTrue,
            reason: 'OTP should be locked after max attempts');
      });

      test('verifyOTP fails even with correct code after max attempts',
          () async {
        final session = await sessionBuilder.build();
        final otpService = OtpService(session);

        const identifier = 'test@example.com';

        final otp = await otpService.createOTP(identifier);
        const wrongOtp = '000000';

        // Attempt 5 times with wrong code
        for (var i = 0; i < 5; i++) {
          await otpService.verifyOTP(identifier, wrongOtp);
        }

        // Now try with CORRECT code - should still fail (max attempts)
        final result = await otpService.verifyOTP(identifier, otp);
        expect(result.success, isFalse);
        expect(
            result.message, equals('Maximum verification attempts exceeded'));
      });
    });

    group('OTP Cleanup Tests', () {
      test('cleanupExpiredOTPs removes only expired records', () async {
        final session = await sessionBuilder.build();
        final otpService = OtpService(session);

        // Create expired OTP
        const expiredIdentifier = 'expired@example.com';
        await otpService.createOTP(expiredIdentifier);

        // Manually expire it
        final expiredRecords = await Otp.db.find(
          session,
          where: (t) => t.identifier.equals(expiredIdentifier),
        );
        final expiredRecord = expiredRecords.first;
        expiredRecord.expiresAt =
            DateTime.now().subtract(Duration(minutes: 10));
        await Otp.db.updateRow(session, expiredRecord);

        // Create valid OTP
        const validIdentifier = 'valid@example.com';
        await otpService.createOTP(validIdentifier);

        // Run cleanup
        await otpService.cleanupExpiredOTPs();

        // Expired should be deleted
        final expiredCheck = await Otp.db.find(
          session,
          where: (t) => t.identifier.equals(expiredIdentifier),
        );
        expect(expiredCheck, isEmpty, reason: 'Expired OTP should be deleted');

        // Valid should still exist
        final validCheck = await Otp.db.find(
          session,
          where: (t) => t.identifier.equals(validIdentifier),
        );
        expect(validCheck, isNotEmpty, reason: 'Valid OTP should remain');
      });
    });

    group('Security Edge Cases', () {
      test('Different identifiers cannot access each others OTPs', () async {
        final session = await sessionBuilder.build();
        final otpService = OtpService(session);

        const identifier1 = 'user1@example.com';
        const identifier2 = 'user2@example.com';

        final otp1 = await otpService.createOTP(identifier1);
        final _ = await otpService.createOTP(identifier2);

        // User2 tries to use User1's OTP
        final result = await otpService.verifyOTP(identifier2, otp1);
        expect(result.success, isFalse,
            reason: 'Should not verify OTP for different identifier');
      });

      test('Whitespace in identifier is trimmed consistently', () async {
        final session = await sessionBuilder.build();
        final otpService = OtpService(session);

        const emailWithSpaces = '  test@example.com  ';
        const emailNormal = 'test@example.com';

        final otp = await otpService.createOTP(emailWithSpaces);
        final result = await otpService.verifyOTP(emailNormal, otp);

        expect(result.success, isTrue,
            reason: 'Whitespace should be trimmed consistently');
      });
    });
  });
}
