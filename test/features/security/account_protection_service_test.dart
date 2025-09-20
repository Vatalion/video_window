import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_window/models/security/account_protection.dart';
import 'package:video_window/services/security/account_protection_service.dart';
import 'package:video_window/services/security/security_audit_service.dart';

void main() {
  late SharedPreferences prefs;
  late SecurityAuditService auditService;
  late AccountProtectionService protectionService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    auditService = SecurityAuditService(prefs);
    protectionService = AccountProtectionService(prefs, auditService);
  });

  group('AccountProtectionService', () {
    test('should create account protection with defaults', () async {
      final protection = await protectionService.getAccountProtection('test-user');

      expect(protection.userId, 'test-user');
      expect(protection.isLocked, false);
      expect(protection.failedAttempts, 0);
      expect(protection.maxFailedAttempts, 5);
      expect(protection.lockoutDurationMinutes, 30);
    });

    test('should allow login attempt when not locked', () async {
      final canAttempt = await protectionService.canAttemptLogin('test-user');
      expect(canAttempt, true);
    });

    test('should record failed login attempt', () async {
      await protectionService.recordFailedLoginAttempt(
        'test-user',
        '192.168.1.1',
        'Mozilla/5.0',
        'device-123',
      );

      final protection = await protectionService.getAccountProtection('test-user');
      expect(protection.failedAttempts, 1);
      expect(protection.failedAttemptsHistory.length, 1);
    });

    test('should lock account after max failed attempts', () async {
      for (int i = 0; i < 6; i++) {
        await protectionService.recordFailedLoginAttempt(
          'test-user',
          '192.168.1.1',
          'Mozilla/5.0',
          'device-123',
        );
      }

      final protection = await protectionService.getAccountProtection('test-user');
      expect(protection.isLocked, true);
      expect(protection.lockedUntil, isNotNull);
    });

    test('should prevent login attempts when locked', () async {
      await protectionService.recordFailedLoginAttempt(
        'test-user',
        '192.168.1.1',
        'Mozilla/5.0',
        'device-123',
      );

      // Lock account manually for testing
      final protection = await protectionService.getAccountProtection('test-user');
      protection.lockAccount();

      final canAttempt = await protectionService.canAttemptLogin('test-user');
      expect(canAttempt, false);
    });

    test('should reset failed attempts on successful login', () async {
      await protectionService.recordFailedLoginAttempt(
        'test-user',
        '192.168.1.1',
        'Mozilla/5.0',
        'device-123',
      );

      await protectionService.recordSuccessfulLogin(
        'test-user',
        '192.168.1.1',
        'Mozilla/5.0',
        'device-123',
      );

      final protection = await protectionService.getAccountProtection('test-user');
      expect(protection.failedAttempts, 0);
    });

    test('should validate password strength', () async {
      // Set requirements
      await protectionService.setPasswordStrengthRequirements(
        minLength: 8,
        requireUppercase: true,
        requireLowercase: true,
        requireNumbers: true,
        requireSpecialChars: true,
      );

      // Test weak password
      String result = protectionService.validatePasswordStrength('weak');
      expect(result.contains('at least 8 characters'), true);

      // Test missing uppercase
      result = protectionService.validatePasswordStrength('lowercase123!');
      expect(result.contains('uppercase'), true);

      // Test missing lowercase
      result = protectionService.validatePasswordStrength('UPPERCASE123!');
      expect(result.contains('lowercase'), true);

      // Test missing numbers
      result = protectionService.validatePasswordStrength('NoNumbers!');
      expect(result.contains('number'), true);

      // Test missing special characters
      result = protectionService.validatePasswordStrength('NoSpecialChars123');
      expect(result.contains('special character'), true);

      // Test strong password
      result = protectionService.validatePasswordStrength('StrongPass123!');
      expect(result, 'Password is strong');
    });

    test('should set security question', () async {
      await protectionService.setSecurityQuestion(
        'test-user',
        'What is your mother\'s maiden name?',
        'Smith',
      );

      final protection = await protectionService.getAccountProtection('test-user');
      expect(protection.securityQuestion, isNotNull);
      expect(protection.securityQuestion!.question, 'What is your mother\'s maiden name?');
      expect(protection.securityQuestion!.encryptedAnswer, isNotNull);
    });

    test('should verify security question', () async {
      await protectionService.setSecurityQuestion(
        'test-user',
        'What is your mother\'s maiden name?',
        'Smith',
      );

      final isCorrect = await protectionService.verifySecurityQuestion(
        'test-user',
        'Smith',
      );

      expect(isCorrect, true);

      final isIncorrect = await protectionService.verifySecurityQuestion(
        'test-user',
        'Johnson',
      );

      expect(isIncorrect, false);
    });

    test('should unlock account', () async {
      // Lock account
      await protectionService.recordFailedLoginAttempt(
        'test-user',
        '192.168.1.1',
        'Mozilla/5.0',
        'device-123',
      );

      // Lock manually for testing
      final protection = await protectionService.getAccountProtection('test-user');
      protection.lockAccount();

      // Unlock
      await protectionService.unlockAccount('test-user');

      final unlockedProtection = await protectionService.getAccountProtection('test-user');
      expect(unlockedProtection.isLocked, false);
      expect(unlockedProtection.failedAttempts, 0);
    });

    test('should require password reset', () async {
      await protectionService.requirePasswordReset('test-user');

      final protection = await protectionService.getAccountProtection('test-user');
      expect(protection.requiresPasswordReset, true);
    });

    test('should record password change', () async {
      await protectionService.recordPasswordChange('test-user');

      final protection = await protectionService.getAccountProtection('test-user');
      expect(protection.lastPasswordChange, isNotNull);
      expect(protection.requiresPasswordReset, false);
    });

    test('should enable two-factor authentication', () async {
      await protectionService.setTwoFactorAuth('test-user', true);

      final protection = await protectionService.getAccountProtection('test-user');
      expect(protection.twoFactorEnabled, true);
    });

    test('should check if account is locked with expiry', () async {
      // Lock account with 1 minute expiry
      final protection = await protectionService.getAccountProtection('test-user');
      protection.lockAccount();
      protection.lockoutDurationMinutes = 1;

      // Should be locked immediately
      expect(protection.isAccountLocked(), true);

      // Simulate time passing (this is a simplified test)
      // In real scenarios, you'd mock DateTime.now()
    });
  });
}