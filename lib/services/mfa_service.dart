import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'package:convert/convert.dart';
import '../models/two_factor_configuration.dart';
import '../models/two_factor_verification.dart';

class MfaService {
  static const int _smsCodeLength = 6;
  static const Duration _codeExpiry = Duration(minutes: 10);
  static const Duration _gracePeriod = Duration(hours: 24);
  static const int _maxBackupCodes = 10;
  static const int _maxSmsAttemptsPerHour = 5;
  static const int _maxVerificationAttemptsPer15Minutes = 10;

  // Rate limiting storage (in production, use proper cache/DB)
  final Map<String, List<DateTime>> _smsAttempts = {};
  final Map<String, List<DateTime>> _verificationAttempts = {};

  // In-memory storage for demo (in production, use secure storage)
  final Map<String, TwoFactorConfiguration> _configurations = {};
  final Map<String, TwoFactorVerification> _verifications = {};

  // SMS-based 2FA Implementation
  Future<bool> enableSms2fa(String userId, String phoneNumber) async {
    if (_isRateLimited(userId, 'sms')) {
      throw Exception('Too many SMS attempts. Please try again later.');
    }

    // Verify phone number format (basic validation)
    if (!_isValidPhoneNumber(phoneNumber)) {
      throw Exception('Invalid phone number format');
    }

    final code = _generateSmsCode();
    final verificationId = _generateVerificationId();

    // Store verification
    _verifications[verificationId] = TwoFactorVerification(
      verificationId: verificationId,
      userId: userId,
      verificationType: 'sms',
      code: code,
      expiresAt: DateTime.now().add(_codeExpiry),
      ipAddress: 'device_ip', // In production, get from device
    );

    // Record SMS attempt
    _recordAttempt(userId, 'sms');

    // Send SMS (in production, integrate with SMS service)
    final smsSent = await _sendSmsCode(phoneNumber, code);

    if (smsSent) {
      // Update user configuration
      final existingConfig = _configurations[userId] ??
          TwoFactorConfiguration(userId: userId);

      _configurations[userId] = existingConfig.copyWith(
        phoneNumber: phoneNumber,
        updatedAt: DateTime.now(),
      );

      return true;
    }

    return false;
  }

  // TOTP-based 2FA Implementation
  Future<Map<String, dynamic>> setupTotp2fa(String userId) async {
    final secret = _generateTotpSecret();
    final provisioningUri = _generateTotpProvisioningUri(userId, secret);

    // Store TOTP secret temporarily (not enabled yet)
    final existingConfig = _configurations[userId] ??
        TwoFactorConfiguration(userId: userId);

    _configurations[userId] = existingConfig.copyWith(
      totpSecret: secret,
      updatedAt: DateTime.now(),
    );

    return {
      'secret': secret,
      'provisioningUri': provisioningUri,
      'manualEntryKey': secret,
    };
  }

  Future<bool> verifyTotpSetup(String userId, String totpCode) async {
    if (_isRateLimited(userId, 'verification')) {
      throw Exception('Too many verification attempts. Please try again later.');
    }

    final config = _configurations[userId];
    if (config == null || config.totpSecret == null) {
      throw Exception('TOTP not configured for user');
    }

    _recordAttempt(userId, 'verification');

    final isValid = _validateTotpCode(config.totpSecret!, totpCode);

    if (isValid) {
      // Enable TOTP
      _configurations[userId] = config.copyWith(
        totpEnabled: true,
        updatedAt: DateTime.now(),
      );

      // Generate backup codes
      await _generateBackupCodes(userId);

      return true;
    }

    return false;
  }

  // Verification Methods
  Future<bool> verify2faCode(String userId, String code, {String? verificationType}) async {
    if (_isRateLimited(userId, 'verification')) {
      throw Exception('Too many verification attempts. Please try again later.');
    }

    _recordAttempt(userId, 'verification');

    // Check if user has grace period
    final config = _configurations[userId];
    if (config != null && config.gracePeriodActive) {
      if (DateTime.now().isBefore(config.gracePeriodEnds!)) {
        return true; // Allow access during grace period
      }
    }

    // Try to verify against all active methods
    if (config?.smsEnabled == true && _validateSmsCode(userId, code)) {
      return true;
    }

    if (config?.totpEnabled == true && _validateTotpCode(config!.totpSecret!, code)) {
      return true;
    }

    if (_validateBackupCode(userId, code)) {
      return true;
    }

    return false;
  }

  // Backup Code Management
  Future<List<String>> generateBackupCodes(String userId) async {
    await _generateBackupCodes(userId);
    final config = _configurations[userId];
    return config?.backupCodes ?? [];
  }

  Future<void> regenerateBackupCodes(String userId) async {
    await _generateBackupCodes(userId);
  }

  // 2FA Management
  Future<void> disable2faMethod(String userId, String method) async {
    final config = _configurations[userId];
    if (config == null) return;

    switch (method) {
      case 'sms':
        _configurations[userId] = config.copyWith(
          smsEnabled: false,
          phoneNumber: null,
          updatedAt: DateTime.now(),
        );
        break;
      case 'totp':
        _configurations[userId] = config.copyWith(
          totpEnabled: false,
          totpSecret: null,
          updatedAt: DateTime.now(),
        );
        break;
      case 'all':
        _configurations[userId] = config.copyWith(
          smsEnabled: false,
          totpEnabled: false,
          phoneNumber: null,
          totpSecret: null,
          updatedAt: DateTime.now(),
        );
        break;
    }
  }

  // Grace Period Management
  Future<void> enableGracePeriod(String userId) async {
    final config = _configurations[userId] ??
        TwoFactorConfiguration(userId: userId);

    _configurations[userId] = config.copyWith(
      gracePeriodActive: true,
      gracePeriodEnds: DateTime.now().add(_gracePeriod),
      updatedAt: DateTime.now(),
    );
  }

  // Configuration Retrieval
  Future<TwoFactorConfiguration?> getConfiguration(String userId) async {
    return _configurations[userId];
  }

  // Private Helper Methods
  String _generateSmsCode() {
    final random = Random.secure();
    final code = List.generate(_smsCodeLength, (i) => random.nextInt(10))
        .join('');
    return code;
  }

  String _generateVerificationId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
           Random.secure().nextInt(10000).toString();
  }

  String _generateTotpSecret() {
    final random = Random.secure();
    final bytes = List.generate(20, (i) => random.nextInt(256));
    return base64Encode(bytes).substring(0, 20).toUpperCase();
  }

  String _generateTotpProvisioningUri(String userId, String secret) {
    // Format: otpauth://totp/ISSUER:USER?secret=SECRET&issuer=ISSUER
    final issuer = Uri.encodeComponent('VideoWindow App');
    final user = Uri.encodeComponent(userId);
    final encodedSecret = secret.replaceAll('=', '');
    return 'otpauth://totp/$issuer:$user?secret=$encodedSecret&issuer=$issuer';
  }

  bool _isValidPhoneNumber(String phoneNumber) {
    // Basic phone number validation
    return RegExp(r'^\+?[1-9]\d{1,14}$').hasMatch(phoneNumber);
  }

  Future<bool> _sendSmsCode(String phoneNumber, String code) async {
    // In production, integrate with actual SMS service
    // For demo, simulate SMS sending
    print('SMS sent to $phoneNumber with code: $code');
    return true;
  }

  bool _validateSmsCode(String userId, String code) {
    final userVerifications = _verifications.values
        .where((v) => v.userId == userId && v.verificationType == 'sms');

    for (final verification in userVerifications) {
      if (verification.isValid && verification.code == code) {
        // Remove the verification as it's been used
        _verifications.remove(verification.verificationId);
        return true;
      }
    }
    return false;
  }

  bool _validateTotpCode(String secret, String code) {
    try {
      final now = DateTime.now();
      final timeStep = now.millisecondsSinceEpoch ~/ 30000; // 30-second steps

      // Check current and adjacent time steps for clock drift
      for (int offset = -1; offset <= 1; offset++) {
        final adjustedTimeStep = timeStep + offset;
        final expectedCode = _generateTotpCode(secret, adjustedTimeStep);

        if (expectedCode == code) {
          return true;
        }
      }
    } catch (e) {
      // Invalid code format
    }
    return false;
  }

  String _generateTotpCode(String secret, int timeStep) {
    final key = utf8.encode(secret);
    final timeBytes = _intToBytes(timeStep);

    final hmac = Hmac(sha1, key);
    final digest = hmac.convert(timeBytes);

    final offset = digest.bytes[digest.bytes.length - 1] & 0x0F;
    final codeBytes = digest.bytes.skip(offset).take(4).toList();
    final code = (codeBytes[0] & 0x7F) << 24 |
                 (codeBytes[1] & 0xFF) << 16 |
                 (codeBytes[2] & 0xFF) << 8 |
                 (codeBytes[3] & 0xFF);

    return (code % 1000000).toString().padLeft(6, '0');
  }

  List<int> _intToBytes(int value) {
    final bytes = List.filled(8, 0);
    for (int i = 7; i >= 0; i--) {
      bytes[i] = value & 0xFF;
      value >>= 8;
    }
    return bytes;
  }

  bool _validateBackupCode(String userId, String code) {
    final config = _configurations[userId];
    if (config?.backupCodes == null) return false;

    final backupCodes = config!.backupCodes!;
    if (backupCodes.contains(code)) {
      // Remove used backup code
      backupCodes.remove(code);
      _configurations[userId] = config.copyWith(
        backupCodes: backupCodes,
        updatedAt: DateTime.now(),
      );
      return true;
    }
    return false;
  }

  Future<void> _generateBackupCodes(String userId) async {
    final random = Random.secure();
    final codes = <String>[];

    for (int i = 0; i < _maxBackupCodes; i++) {
      final code = List.generate(8, (i) => random.nextInt(10)).join('');
      codes.add(code);
    }

    final config = _configurations[userId] ??
        TwoFactorConfiguration(userId: userId);

    _configurations[userId] = config.copyWith(
      backupCodes: codes,
      updatedAt: DateTime.now(),
    );
  }

  bool _isRateLimited(String userId, String type) {
    final Map<String, List<DateTime>> attempts =
        type == 'sms' ? _smsAttempts : _verificationAttempts;

    final userAttempts = attempts[userId] ?? [];
    final now = DateTime.now();

    // Remove old attempts
    userAttempts.removeWhere((attempt) =>
        now.difference(attempt) > const Duration(hours: 1));

    final maxAttempts = type == 'sms'
        ? _maxSmsAttemptsPerHour
        : _maxVerificationAttemptsPer15Minutes;

    return userAttempts.length >= maxAttempts;
  }

  void _recordAttempt(String userId, String type) {
    final Map<String, List<DateTime>> attempts =
        type == 'sms' ? _smsAttempts : _verificationAttempts;

    if (!attempts.containsKey(userId)) {
      attempts[userId] = [];
    }
    attempts[userId]!.add(DateTime.now());
  }
}