import 'package:flutter/material.dart';
import '../../domain/models/recovery_attempt_model.dart';

class RecoverySecurityService {
  static const int _maxAttemptsPerWindow = 5;
  static const Duration _attemptWindow = Duration(minutes: 15);
  static const int _suspiciousThreshold = 3;

  Future<bool> checkSuspiciousActivity({
    required String userId,
    required String ipAddress,
    required String userAgent,
  }) async {
    // Get recent attempts
    final recentAttempts = await _getRecentAttempts(userId, _attemptWindow);

    // Check for too many attempts
    if (recentAttempts.length >= _maxAttemptsPerWindow) {
      await _lockUserAccount(userId, 'Too many recovery attempts');
      return true;
    }

    // Check for suspicious patterns
    final suspiciousScore = _calculateSuspiciousScore(
      recentAttempts,
      ipAddress,
      userAgent,
    );

    if (suspiciousScore >= _suspiciousThreshold) {
      await _flagSuspiciousActivity(userId, suspiciousScore);
      return true;
    }

    return false;
  }

  Future<void> logSecurityEvent({
    required String userId,
    required RecoveryAttemptType type,
    required String ipAddress,
    required String userAgent,
    String? deviceId,
    String? identifier,
    bool wasSuccessful = true,
    String? failureReason,
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

    await _storeRecoveryAttempt(attempt);

    // Check for suspicious activity
    if (!wasSuccessful) {
      await checkSuspiciousActivity(
        userId: userId,
        ipAddress: ipAddress,
        userAgent: userAgent,
      );
    }

    // Send notification for security events
    if (wasSuspicious || !wasSuccessful) {
      await _sendSecurityNotification(userId, attempt);
    }
  }

  Future<bool> isAccountLocked(String userId) async {
    // Mock implementation - check if account is locked
    final lockInfo = await _getAccountLockInfo(userId);
    if (lockInfo == null) return false;

    // Check if lock has expired
    if (lockInfo['expires_at'] != null) {
      final expiresAt = DateTime.parse(lockInfo['expires_at']);
      if (DateTime.now().isAfter(expiresAt)) {
        await _unlockAccount(userId);
        return false;
      }
    }

    return true;
  }

  Future<int> getRemainingAttempts(String userId) async {
    final recentAttempts = await _getRecentAttempts(userId, _attemptWindow);
    final failedAttempts = recentAttempts.where((a) => !a.wasSuccessful).length;
    return (_maxAttemptsPerWindow - failedAttempts).clamp(
      0,
      _maxAttemptsPerWindow,
    );
  }

  Future<Map<String, dynamic>> getRecoveryStats(String userId) async {
    final allAttempts = await _getAllRecoveryAttempts(userId);
    final recentAttempts = await _getRecentAttempts(
      userId,
      const Duration(days: 30),
    );

    return {
      'total_attempts': allAttempts.length,
      'successful_attempts': allAttempts.where((a) => a.wasSuccessful).length,
      'recent_attempts': recentAttempts.length,
      'suspicious_attempts': recentAttempts
          .where((a) => a.wasSuspicious)
          .length,
      'unique_ips': recentAttempts.map((a) => a.ipAddress).toSet().length,
      'last_attempt': recentAttempts.isNotEmpty
          ? recentAttempts.first.createdAt
          : null,
    };
  }

  Future<void> sendSecurityAlert({
    required String userId,
    required String message,
    required String ipAddress,
    required String userAgent,
  }) async {
    await logSecurityEvent(
      userId: userId,
      type: RecoveryAttemptType.accountLockout,
      ipAddress: ipAddress,
      userAgent: userAgent,
      wasSuccessful: false,
      failureReason: message,
      wasSuspicious: true,
      suspicionReason: 'Security alert triggered',
    );

    // Send immediate notification
    await _sendSecurityNotification(userId, null, customMessage: message);
  }

  int _calculateSuspiciousScore(
    List<RecoveryAttemptModel> attempts,
    String currentIp,
    String currentUserAgent,
  ) {
    int score = 0;

    // Check for multiple IPs
    final uniqueIps = attempts.map((a) => a.ipAddress).toSet();
    if (uniqueIps.length > 2) score += 2;

    // Check for rapid attempts
    if (attempts.length >= 3) {
      final timeDiff = attempts.first.createdAt.difference(
        attempts.last.createdAt,
      );
      if (timeDiff.inMinutes < 5) score += 2;
    }

    // Check for IP mismatch
    if (!uniqueIps.contains(currentIp) && attempts.isNotEmpty) {
      score += 1;
    }

    // Check for failed attempts
    final failedAttempts = attempts.where((a) => !a.wasSuccessful).length;
    score += (failedAttempts ~/ 2);

    return score;
  }

  Future<void> _lockUserAccount(String userId, String reason) async {
    // Mock implementation - lock user account
    final lockInfo = {
      'user_id': userId,
      'locked_at': DateTime.now().toIso8601String(),
      'expires_at': DateTime.now()
          .add(const Duration(hours: 1))
          .toIso8601String(),
      'reason': reason,
    };

    await _storeAccountLock(lockInfo);
    debugPrint('Account locked for user $userId: $reason');

    await _sendSecurityNotification(
      userId,
      null,
      customMessage:
          'Your account has been temporarily locked due to suspicious activity.',
    );
  }

  Future<void> _unlockAccount(String userId) async {
    // Mock implementation - unlock user account
    await _removeAccountLock(userId);
    debugPrint('Account unlocked for user $userId');
  }

  Future<void> _flagSuspiciousActivity(String userId, int score) async {
    // Mock implementation - flag suspicious activity
    debugPrint('Suspicious activity flagged for user $userId (score: $score)');
  }

  Future<void> _sendSecurityNotification(
    String userId,
    RecoveryAttemptModel? attempt, {
    String? customMessage,
  }) async {
    // Mock implementation - send security notification
    String message =
        customMessage ??
        'Security alert: ${attempt?.type.name} attempt ${attempt?.wasSuccessful == true ? 'successful' : 'failed'}';

    debugPrint('Sending security notification to user $userId: $message');
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  Future<List<RecoveryAttemptModel>> _getRecentAttempts(
    String userId,
    Duration window,
  ) async {
    // Mock implementation - get recent attempts
    final cutoff = DateTime.now().subtract(window);
    debugPrint('Getting recent attempts for user $userId since $cutoff');
    return [];
  }

  Future<List<RecoveryAttemptModel>> _getAllRecoveryAttempts(
    String userId,
  ) async {
    // Mock implementation - get all attempts
    debugPrint('Getting all recovery attempts for user $userId');
    return [];
  }

  Future<void> _storeRecoveryAttempt(RecoveryAttemptModel attempt) async {
    // Mock implementation - store attempt
    debugPrint('Storing recovery attempt: ${attempt.toJson()}');
  }

  Future<Map<String, dynamic>?> _getAccountLockInfo(String userId) async {
    // Mock implementation - get account lock info
    return null;
  }

  Future<void> _storeAccountLock(Map<String, dynamic> lockInfo) async {
    // Mock implementation - store account lock
  }

  Future<void> _removeAccountLock(String userId) async {
    // Mock implementation - remove account lock
  }
}
