import '../../domain/models/recovery_models.dart';

abstract class RecoveryRemoteDataSource {
  // Token management
  Future<void> storeRecoveryToken(RecoveryToken token);
  Future<RecoveryToken?> getRecoveryToken(String email, String token);
  Future<void> markTokenAsUsed(String email, String token);

  // Password reset
  Future<void> resetUserPassword(String email, String newPassword);

  // Security questions
  Future<SecurityQuestion?> getSecurityQuestion(String questionId);
  Future<List<SecurityQuestion>> getSecurityQuestions();
  Future<void> saveSecurityQuestion(SecurityQuestion question);

  // Backup recovery
  Future<BackupRecoveryInfo?> getBackupRecoveryInfo(RecoveryMethod method);

  // Recovery status and monitoring
  Future<List<RecoveryMethod>> getAvailableRecoveryMethods(String email);
  Future<RecoveryAttempt?> getLastRecoveryAttempt(String email);
  Future<List<RecoveryAttempt>> getFailedRecoveryAttempts(String email);
  Future<List<RecoveryAttempt>> getRecoveryAttempts(String email);
  Future<List<RecoveryAttempt>> getRecentRecoveryAttempts(
    String email,
    Duration duration,
  );
  Future<void> logRecoveryAttempt(RecoveryAttempt attempt);

  // Account lock management
  Future<AccountLockStatus> getAccountLockStatus(String email);
  Future<void> lockAccount(String email, AccountLockStatus status, DateTime? lockedUntil);
  Future<void> unlockAccount(String email);

  // Security notifications
  Future<void> sendSecurityNotification(String email, String message);
}

class BackupRecoveryInfo {
  final String email;
  final String? phoneNumber;

  BackupRecoveryInfo({
    required this.email,
    this.phoneNumber,
  });
}