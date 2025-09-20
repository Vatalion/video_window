import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/security/account_protection.dart';
import '../../models/security/security_audit_log.dart';
import 'security_audit_service.dart';

class AccountProtectionService {
  static const String _protectionKey = 'account_protection_';
  static const int _defaultMaxAttempts = 5;
  static const int _defaultLockoutDuration = 30;

  final SharedPreferences _prefs;
  final SecurityAuditService _auditService;
  final Map<String, AccountProtection> _protectionCache = {};

  AccountProtectionService(this._prefs, this._auditService);

  Future<AccountProtection> getAccountProtection(String userId) async {
    if (_protectionCache.containsKey(userId)) {
      return _protectionCache[userId]!;
    }

    final protectionJson = _prefs.getString('$_protectionKey$userId');
    AccountProtection protection;

    if (protectionJson != null) {
      protection = AccountProtection.fromJson(jsonDecode(protectionJson));
    } else {
      protection = AccountProtection(
        userId: userId,
        maxFailedAttempts: _defaultMaxAttempts,
        lockoutDurationMinutes: _defaultLockoutDuration,
      );
    }

    _protectionCache[userId] = protection;
    return protection;
  }

  Future<void> _saveAccountProtection(AccountProtection protection) async {
    final protectionJson = jsonEncode(protection.toJson());
    await _prefs.setString('$_protectionKey${protection.userId}', protectionJson);
    _protectionCache[protection.userId] = protection;
  }

  Future<bool> canAttemptLogin(String userId) async {
    final protection = await getAccountProtection(userId);
    return !protection.isAccountLocked();
  }

  Future<String?> attemptLogin(
    String userId,
    String ipAddress,
    String userAgent,
    String deviceId, {
    String? sessionId,
  }) async {
    final protection = await getAccountProtection(userId);

    if (protection.isAccountLocked()) {
      final remainingTime = protection.lockedUntil!.difference(DateTime.now());
      return 'Account locked. Try again in ${remainingTime.inMinutes} minutes.';
    }

    // Log the attempt
    await _auditService.logSecurityEvent(
      userId: userId,
      eventType: SecurityEventType.login,
      ipAddress: ipAddress,
      userAgent: userAgent,
      deviceId: deviceId,
      sessionId: sessionId,
    );

    return null; // No error, login can proceed
  }

  Future<void> recordSuccessfulLogin(
    String userId,
    String ipAddress,
    String userAgent,
    String deviceId, {
    String? sessionId,
  }) async {
    final protection = await getAccountProtection(userId);
    protection.resetFailedAttempts();
    await _saveAccountProtection(protection);

    await _auditService.logSecurityEvent(
      userId: userId,
      eventType: SecurityEventType.login,
      ipAddress: ipAddress,
      userAgent: userAgent,
      deviceId: deviceId,
      sessionId: sessionId,
    );
  }

  Future<void> recordFailedLoginAttempt(
    String userId,
    String ipAddress,
    String userAgent,
    String deviceId, {
    String? sessionId,
  }) async {
    final protection = await getAccountProtection(userId);
    protection.recordFailedAttempt(ipAddress, userAgent);
    await _saveAccountProtection(protection);

    await _auditService.logSecurityEvent(
      userId: userId,
      eventType: SecurityEventType.failedLogin,
      ipAddress: ipAddress,
      userAgent: userAgent,
      deviceId: deviceId,
      sessionId: sessionId,
      riskScore: 0.5,
      eventDetails: {
        'failed_attempts': protection.failedAttempts,
        'max_attempts': protection.maxFailedAttempts,
      },
    );

    if (protection.isAccountLocked()) {
      await _auditService.logSecurityEvent(
        userId: userId,
        eventType: SecurityEventType.accountLockout,
        ipAddress: ipAddress,
        userAgent: userAgent,
        deviceId: deviceId,
        sessionId: sessionId,
        riskScore: 0.9,
        eventDetails: {
          'lockout_duration': protection.lockoutDurationMinutes,
          'failed_attempts': protection.failedAttempts,
        },
      );
    }
  }

  Future<void> setPasswordStrengthRequirements({
    int minLength = 8,
    bool requireUppercase = true,
    bool requireLowercase = true,
    bool requireNumbers = true,
    bool requireSpecialChars = true,
  }) async {
    await _prefs.setString('password_requirements', jsonEncode({
      'min_length': minLength,
      'require_uppercase': requireUppercase,
      'require_lowercase': requireLowercase,
      'require_numbers': requireNumbers,
      'require_special_chars': requireSpecialChars,
    }));
  }

  Map<String, dynamic> getPasswordStrengthRequirements() {
    final requirementsJson = _prefs.getString('password_requirements');
    if (requirementsJson != null) {
      return jsonDecode(requirementsJson);
    }

    return {
      'min_length': 8,
      'require_uppercase': true,
      'require_lowercase': true,
      'require_numbers': true,
      'require_special_chars': true,
    };
  }

  String validatePasswordStrength(String password) {
    final requirements = getPasswordStrengthRequirements();
    final errors = <String>[];

    if (password.length < requirements['min_length']) {
      errors.add('Password must be at least ${requirements['min_length']} characters long');
    }

    if (requirements['require_uppercase'] && !password.contains(RegExp(r'[A-Z]'))) {
      errors.add('Password must contain at least one uppercase letter');
    }

    if (requirements['require_lowercase'] && !password.contains(RegExp(r'[a-z]'))) {
      errors.add('Password must contain at least one lowercase letter');
    }

    if (requirements['require_numbers'] && !password.contains(RegExp(r'[0-9]'))) {
      errors.add('Password must contain at least one number');
    }

    if (requirements['require_special_chars'] && !password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      errors.add('Password must contain at least one special character');
    }

    return errors.isEmpty ? 'Password is strong' : errors.join('. ');
  }

  Future<void> setSecurityQuestion(
    String userId,
    String question,
    String answer,
  ) async {
    final protection = await getAccountProtection(userId);
    protection.securityQuestion = SecurityQuestion(
      question: question,
      encryptedAnswer: _encryptAnswer(answer),
      lastUpdated: DateTime.now(),
    );
    await _saveAccountProtection(protection);

    await _auditService.logSecurityEvent(
      userId: userId,
      eventType: SecurityEventType.securityQuestionChange,
      ipAddress: 'system',
      userAgent: 'system',
      deviceId: 'system',
      eventDetails: {'question_set': true},
    );
  }

  String _encryptAnswer(String answer) {
    // Simple encryption - in production use proper encryption
    return answer.split('').reversed.join();
  }

  Future<bool> verifySecurityQuestion(String userId, String answer) async {
    final protection = await getAccountProtection(userId);
    if (protection.securityQuestion == null) {
      return false;
    }

    final decryptedAnswer = _decryptAnswer(protection.securityQuestion!.encryptedAnswer);
    return decryptedAnswer.toLowerCase() == answer.toLowerCase();
  }

  String _decryptAnswer(String encryptedAnswer) {
    // Simple decryption - in production use proper decryption
    return encryptedAnswer.split('').reversed.join();
  }

  Future<void> unlockAccount(String userId) async {
    final protection = await getAccountProtection(userId);
    protection.unlockAccount();
    await _saveAccountProtection(protection);

    await _auditService.logSecurityEvent(
      userId: userId,
      eventType: SecurityEventType.accountLockout,
      ipAddress: 'system',
      userAgent: 'system',
      deviceId: 'system',
      eventDetails: {'account_unlocked': true},
    );
  }

  Future<void> requirePasswordReset(String userId) async {
    final protection = await getAccountProtection(userId);
    protection.requiresPasswordReset = true;
    await _saveAccountProtection(protection);

    await _auditService.logSecurityEvent(
      userId: userId,
      eventType: SecurityEventType.passwordReset,
      ipAddress: 'system',
      userAgent: 'system',
      deviceId: 'system',
      eventDetails: {'password_reset_required': true},
    );
  }

  Future<void> recordPasswordChange(String userId) async {
    final protection = await getAccountProtection(userId);
    protection.lastPasswordChange = DateTime.now();
    protection.requiresPasswordReset = false;
    await _saveAccountProtection(protection);

    await _auditService.logSecurityEvent(
      userId: userId,
      eventType: SecurityEventType.passwordChange,
      ipAddress: 'system',
      userAgent: 'system',
      deviceId: 'system',
    );
  }

  Future<void> setTwoFactorAuth(String userId, bool enabled) async {
    final protection = await getAccountProtection(userId);
    protection.twoFactorEnabled = enabled;
    await _saveAccountProtection(protection);

    await _auditService.logSecurityEvent(
      userId: userId,
      eventType: SecurityEventType.twoFactorAuth,
      ipAddress: 'system',
      userAgent: 'system',
      deviceId: 'system',
      eventDetails: {'two_factor_enabled': enabled},
    );
  }
}