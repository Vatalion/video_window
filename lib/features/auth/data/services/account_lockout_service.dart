import 'package:flutter/foundation.dart';
import '../../domain/models/login_attempt_model.dart';

class AccountLockoutService {
  static const int _maxFailedAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 30);
  static const Duration _attemptWindow = Duration(minutes: 15);

  final Map<String, List<LoginAttemptModel>> _recentAttempts = {};
  final Map<String, DateTime> _lockedAccounts = {};

  bool isAccountLocked(String identifier) {
    final lockTime = _lockedAccounts[identifier];
    if (lockTime == null) return false;

    return DateTime.now().difference(lockTime) < _lockoutDuration;
  }

  DateTime? getLockoutEndTime(String identifier) {
    final lockTime = _lockedAccounts[identifier];
    if (lockTime == null) return null;

    final endTime = lockTime.add(_lockoutDuration);
    return endTime.isAfter(DateTime.now()) ? endTime : null;
  }

  int getRemainingFailedAttempts(String identifier) {
    if (isAccountLocked(identifier)) return 0;

    final attempts = _recentAttempts[identifier] ?? [];
    final recentFailedAttempts = attempts
        .where(
          (attempt) =>
              !attempt.wasSuccessful &&
              DateTime.now().difference(attempt.attemptTime) < _attemptWindow,
        )
        .length;

    return _maxFailedAttempts - recentFailedAttempts;
  }

  Future<void> recordLoginAttempt({
    required String? email,
    required String? phone,
    required String ipAddress,
    required String userAgent,
    required bool wasSuccessful,
    String? failureReason,
    String? userId,
  }) async {
    final identifier = email ?? phone ?? userId;
    if (identifier == null) return;

    final attempt = LoginAttemptModel(
      id: _generateId(),
      email: email,
      phone: phone,
      ipAddress: ipAddress,
      userAgent: userAgent,
      wasSuccessful: wasSuccessful,
      attemptTime: DateTime.now(),
      failureReason: failureReason,
      userId: userId,
    );

    if (!_recentAttempts.containsKey(identifier)) {
      _recentAttempts[identifier] = [];
    }

    _recentAttempts[identifier]!.add(attempt);

    if (!wasSuccessful) {
      await _checkAndApplyLockout(identifier);
    } else {
      await _clearFailedAttempts(identifier);
    }

    await _cleanupOldAttempts();
  }

  Future<void> _checkAndApplyLockout(String identifier) async {
    final attempts = _recentAttempts[identifier] ?? [];
    final recentFailedAttempts = attempts
        .where(
          (attempt) =>
              !attempt.wasSuccessful &&
              DateTime.now().difference(attempt.attemptTime) < _attemptWindow,
        )
        .toList();

    if (recentFailedAttempts.length >= _maxFailedAttempts) {
      _lockedAccounts[identifier] = DateTime.now();

      if (kDebugMode) {
        print(
          'Account locked for identifier: $identifier after ${recentFailedAttempts.length} failed attempts',
        );
      }
    }
  }

  Future<void> _clearFailedAttempts(String identifier) async {
    if (_recentAttempts.containsKey(identifier)) {
      _recentAttempts[identifier]!.removeWhere(
        (attempt) => !attempt.wasSuccessful,
      );
    }
    _lockedAccounts.remove(identifier);
  }

  Future<void> _cleanupOldAttempts() async {
    final cutoffTime = DateTime.now().subtract(_attemptWindow);

    for (final identifier in _recentAttempts.keys.toList()) {
      _recentAttempts[identifier]!.removeWhere(
        (attempt) => attempt.attemptTime.isBefore(cutoffTime),
      );

      if (_recentAttempts[identifier]!.isEmpty) {
        _recentAttempts.remove(identifier);
      }
    }

    for (final identifier in _lockedAccounts.keys.toList()) {
      final lockTime = _lockedAccounts[identifier]!;
      if (DateTime.now().difference(lockTime) >= _lockoutDuration) {
        _lockedAccounts.remove(identifier);
      }
    }
  }

  Future<void> unlockAccount(String identifier) async {
    _lockedAccounts.remove(identifier);
    await _clearFailedAttempts(identifier);
  }

  String _generateId() {
    return 'attempt_${DateTime.now().millisecondsSinceEpoch}_${_randomString(8)}';
  }

  String _randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().millisecond;
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (i) => chars.codeUnitAt((random + i) % chars.length),
      ),
    );
  }

  Map<String, dynamic> getAccountStatus(String identifier) {
    final isLocked = isAccountLocked(identifier);
    final lockEndTime = getLockoutEndTime(identifier);
    final remainingAttempts = getRemainingFailedAttempts(identifier);
    final attempts = _recentAttempts[identifier] ?? [];
    final recentFailedAttempts = attempts
        .where(
          (attempt) =>
              !attempt.wasSuccessful &&
              DateTime.now().difference(attempt.attemptTime) < _attemptWindow,
        )
        .length;

    return {
      'is_locked': isLocked,
      'lock_end_time': lockEndTime?.toIso8601String(),
      'remaining_attempts': remainingAttempts,
      'recent_failed_attempts': recentFailedAttempts,
      'max_failed_attempts': _maxFailedAttempts,
      'lockout_duration_minutes': _lockoutDuration.inMinutes,
    };
  }
}
