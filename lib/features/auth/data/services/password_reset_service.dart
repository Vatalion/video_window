import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import '../../domain/models/recovery_token_model.dart';
import '../../domain/models/recovery_attempt_model.dart';

class PasswordResetService {
  static const int _tokenLength = 32;
  static const Duration _tokenExpiration = Duration(minutes: 15);
  static const int _maxAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 15);

  final String _emailServiceUrl;
  final String _encryptionKey;

  PasswordResetService({
    required String emailServiceUrl,
    required String encryptionKey,
  }) : _emailServiceUrl = emailServiceUrl,
       _encryptionKey = encryptionKey;

  Future<RecoveryTokenModel> createEmailResetToken({
    required String userId,
    required String email,
    required String ipAddress,
    required String userAgent,
  }) async {
    // Generate secure random token
    final token = _generateSecureToken();
    final tokenHash = _hashToken(token);

    // Create recovery token
    final recoveryToken = RecoveryTokenModel(
      id: _generateId(),
      userId: userId,
      type: RecoveryTokenType.email,
      token: tokenHash,
      email: email,
      expiresAt: DateTime.now().add(_tokenExpiration),
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
      type: RecoveryAttemptType.email,
      identifier: email,
      wasSuccessful: true,
      ipAddress: ipAddress,
      userAgent: userAgent,
    );

    // Send email
    await _sendResetEmail(email, token, userId);

    return recoveryToken;
  }

  Future<bool> validateResetToken({
    required String userId,
    required String token,
    required String ipAddress,
    required String userAgent,
  }) async {
    // Check if user is locked out
    if (await _isUserLockedOut(userId)) {
      return false;
    }

    // Get token from database
    final storedToken = await _getRecoveryToken(userId, token);
    if (storedToken == null || !storedToken.isValid) {
      await _logRecoveryAttempt(
        userId: userId,
        type: RecoveryAttemptType.email,
        wasSuccessful: false,
        failureReason: 'Invalid or expired token',
        ipAddress: ipAddress,
        userAgent: userAgent,
        wasSuspicious: true,
        suspicionReason: 'Invalid token attempt',
      );
      return false;
    }

    return true;
  }

  Future<bool> resetPassword({
    required String userId,
    required String token,
    required String newPassword,
    required String ipAddress,
    required String userAgent,
  }) async {
    // Validate token
    if (!await validateResetToken(
      userId: userId,
      token: token,
      ipAddress: ipAddress,
      userAgent: userAgent,
    )) {
      return false;
    }

    // Update password (mock implementation)
    await _updateUserPassword(userId, newPassword);

    // Mark token as used
    await _markTokenAsUsed(userId, token);

    // Log successful reset
    await _logRecoveryAttempt(
      userId: userId,
      type: RecoveryAttemptType.email,
      wasSuccessful: true,
      ipAddress: ipAddress,
      userAgent: userAgent,
    );

    return true;
  }

  String _generateSecureToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(_tokenLength, (i) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  String _hashToken(String token) {
    final bytes = utf8.encode(token + _encryptionKey);
    return sha256.convert(bytes).toString();
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        _generateSecureToken().substring(0, 8);
  }

  Future<void> _storeRecoveryToken(RecoveryTokenModel token) async {
    // Mock implementation - in real app, this would store to database
    debugPrint('Storing recovery token for user: ${token.userId}');
  }

  Future<RecoveryTokenModel?> _getRecoveryToken(
    String userId,
    String token,
  ) async {
    // Mock implementation - in real app, this would retrieve from database
    debugPrint('Retrieving recovery token for user: $userId');
    return null;
  }

  Future<void> _sendResetEmail(
    String email,
    String token,
    String userId,
  ) async {
    // Mock implementation - in real app, this would send email
    final resetLink =
        'https://app.example.com/reset-password?token=$token&userId=$userId';
    debugPrint('Sending reset email to $email with link: $resetLink');
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

    // Mock implementation - in real app, this would store to database
    debugPrint('Logging recovery attempt: ${attempt.toJson()}');
  }

  Future<bool> _isUserLockedOut(String userId) async {
    // Mock implementation - check if user has too many failed attempts
    return false;
  }

  Future<void> _updateUserPassword(String userId, String newPassword) async {
    // Mock implementation - update user password
    debugPrint('Updating password for user: $userId');
  }

  Future<void> _markTokenAsUsed(String userId, String token) async {
    // Mock implementation - mark token as used
    debugPrint('Marking token as used for user: $userId');
  }
}
