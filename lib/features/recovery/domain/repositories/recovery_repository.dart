import '../models/recovery_models.dart';

abstract class RecoveryRepository {
  // Email-based recovery
  Future<RecoveryResult> requestEmailRecovery(String email);

  // Phone-based recovery
  Future<RecoveryResult> requestPhoneRecovery(String phoneNumber);

  // Token verification
  Future<bool> verifyRecoveryToken(String email, String token);

  // Password reset
  Future<RecoveryResult> resetPassword(
    String email,
    String newPassword,
    String token,
  );

  // Security questions
  Future<bool> verifySecurityQuestion(String questionId, String answer);
  Future<List<SecurityQuestion>> getSecurityQuestions();
  Future<bool> setSecurityQuestion(String question, String answer);

  // Backup recovery methods
  Future<RecoveryResult> initiateBackupRecovery(RecoveryMethod method);

  // Recovery status and monitoring
  Future<RecoveryStatusInfo> getRecoveryStatus(String email);
  Future<List<RecoveryAttempt>> getRecoveryAttempts(String email);
  Future<void> logRecoveryAttempt(RecoveryAttempt attempt);

  // Account lock management
  Future<bool> isAccountLocked(String email);
  Future<AccountLockStatus> getAccountLockStatus(String email);
  Future<void> lockAccount(String email, {AccountLockStatus? status});
  Future<void> unlockAccount(String email);

  // Security monitoring
  Future<bool> isSuspiciousActivity(String email, String ipAddress);
  Future<void> sendSecurityNotification(String email, String message);
}

class RecoveryResult {
  final bool success;
  final String? error;
  final RecoveryErrorType? errorType;
  final bool isAccountLocked;
  final AccountLockStatus? lockStatus;
  final DateTime? lockedUntil;
  final DateTime? expiresAt;
  final String? email;
  final String? phoneNumber;

  RecoveryResult({
    required this.success,
    this.error,
    this.errorType,
    this.isAccountLocked = false,
    this.lockStatus,
    this.lockedUntil,
    this.expiresAt,
    this.email,
    this.phoneNumber,
  });
}

class RecoveryStatusInfo {
  final List<RecoveryMethod> availableMethods;
  final RecoveryStatus currentStatus;
  final DateTime? lastRecoveryAttempt;
  final int failedAttempts;

  RecoveryStatusInfo({
    required this.availableMethods,
    required this.currentStatus,
    this.lastRecoveryAttempt,
    this.failedAttempts = 0,
  });
}