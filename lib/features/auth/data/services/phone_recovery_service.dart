import 'dart:math';
import 'package:flutter/material.dart';
import '../../domain/models/recovery_token_model.dart';
import '../../domain/models/recovery_attempt_model.dart';

class PhoneRecoveryService {
  static const int _verificationCodeLength = 6;
  static const Duration _codeExpiration = Duration(minutes: 10);
  static const int _maxAttempts = 3;
  static const Duration _rateLimitDuration = Duration(minutes: 5);

  final String _smsServiceUrl;
  final String _apiKey;

  PhoneRecoveryService({required String smsServiceUrl, required String apiKey})
    : _smsServiceUrl = smsServiceUrl,
      _apiKey = apiKey;

  Future<RecoveryTokenModel> createPhoneRecoveryCode({
    required String userId,
    required String phoneNumber,
    required String ipAddress,
    required String userAgent,
  }) async {
    // Check rate limiting
    if (await _isRateLimited(userId)) {
      throw Exception('Too many attempts. Please try again later.');
    }

    // Generate verification code
    final code = _generateVerificationCode();
    final codeHash = _hashCode(code);

    // Create recovery token
    final recoveryToken = RecoveryTokenModel(
      id: _generateId(),
      userId: userId,
      type: RecoveryTokenType.phone,
      token: codeHash,
      phoneNumber: phoneNumber,
      expiresAt: DateTime.now().add(_codeExpiration),
      isUsed: false,
      attemptsRemaining: _maxAttempts,
      ipAddress: ipAddress,
      userAgent: userAgent,
      createdAt: DateTime.now(),
    );

    // Store token in database (mock implementation)
    await _storeRecoveryToken(recoveryToken);

    // Log the attempt
    await _logRecoveryAttempt(
      userId: userId,
      type: RecoveryAttemptType.phone,
      identifier: phoneNumber,
      wasSuccessful: true,
      ipAddress: ipAddress,
      userAgent: userAgent,
    );

    // Send SMS
    await _sendVerificationSMS(phoneNumber, code);

    return recoveryToken;
  }

  Future<bool> verifyPhoneCode({
    required String userId,
    required String phoneNumber,
    required String code,
    required String ipAddress,
    required String userAgent,
  }) async {
    // Check if user is locked out
    if (await _isUserLockedOut(userId)) {
      return false;
    }

    // Get token from database
    final storedToken = await _getRecoveryToken(userId, phoneNumber);
    if (storedToken == null || !storedToken.isValid) {
      await _logRecoveryAttempt(
        userId: userId,
        type: RecoveryAttemptType.phone,
        identifier: phoneNumber,
        wasSuccessful: false,
        failureReason: 'Invalid or expired code',
        ipAddress: ipAddress,
        userAgent: userAgent,
        wasSuspicious: true,
        suspicionReason: 'Invalid verification code attempt',
      );
      return false;
    }

    // Verify code
    final codeHash = _hashCode(code);
    if (storedToken.token != codeHash) {
      await _decrementAttempts(storedToken.id);
      await _logRecoveryAttempt(
        userId: userId,
        type: RecoveryAttemptType.phone,
        identifier: phoneNumber,
        wasSuccessful: false,
        failureReason: 'Incorrect code',
        ipAddress: ipAddress,
        userAgent: userAgent,
      );
      return false;
    }

    // Mark token as used
    await _markTokenAsUsed(storedToken.id);

    // Log successful verification
    await _logRecoveryAttempt(
      userId: userId,
      type: RecoveryAttemptType.phone,
      identifier: phoneNumber,
      wasSuccessful: true,
      ipAddress: ipAddress,
      userAgent: userAgent,
    );

    return true;
  }

  String _generateVerificationCode() {
    final random = Random.secure();
    return List<int>.generate(
      _verificationCodeLength,
      (i) => random.nextInt(10),
    ).join('');
  }

  String _hashCode(String code) {
    // In production, use a proper hashing algorithm
    return code.hashCode.toString();
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  Future<void> _storeRecoveryToken(RecoveryTokenModel token) async {
    // Mock implementation
    debugPrint('Storing phone recovery token for user: ${token.userId}');
  }

  Future<RecoveryTokenModel?> _getRecoveryToken(
    String userId,
    String phoneNumber,
  ) async {
    // Mock implementation
    debugPrint('Retrieving phone recovery token for user: $userId');
    return null;
  }

  Future<void> _sendVerificationSMS(String phoneNumber, String code) async {
    // Mock implementation
    final message =
        'Your recovery code is: $code. This code expires in 10 minutes.';
    debugPrint('Sending SMS to $phoneNumber: $message');
  }

  Future<void> _logRecoveryAttempt({
    required String userId,
    required RecoveryAttemptType type,
    String? identifier,
    required bool wasSuccessful,
    String? failureReason,
    required String ipAddress,
    required String userAgent,
    String? deviceId,
    bool wasSuspicious = false,
    String? suspicionReason,
  }) async {
    final attempt = RecoveryAttemptModel(
      id: _generateId(),
      userId: userId,
      type: type,
      identifier: identifier,
      wasSuccessful: wasSuccessful,
      failureReason: failureReason,
      ipAddress: ipAddress,
      userAgent: userAgent,
      deviceId: deviceId,
      wasSuspicious: wasSuspicious,
      suspicionReason: suspicionReason,
      createdAt: DateTime.now(),
    );

    // Mock implementation
    debugPrint('Logging phone recovery attempt: ${attempt.toJson()}');
  }

  Future<bool> _isRateLimited(String userId) async {
    // Mock implementation - check rate limiting
    return false;
  }

  Future<bool> _isUserLockedOut(String userId) async {
    // Mock implementation - check if user is locked out
    return false;
  }

  Future<void> _decrementAttempts(String tokenId) async {
    // Mock implementation - decrement remaining attempts
    debugPrint('Decrementing attempts for token: $tokenId');
  }

  Future<void> _markTokenAsUsed(String tokenId) async {
    // Mock implementation - mark token as used
    debugPrint('Marking token as used: $tokenId');
  }
}
