import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../models/two_factor_config_model.dart';
import '../models/two_factor_verification_model.dart';
import '../models/two_factor_audit_model.dart';

abstract class TwoFactorRepository {
  // Configuration Management
  Future<Either<Failure, TwoFactorConfig>> getTwoFactorConfig(String userId);
  Future<Either<Failure, TwoFactorConfig>> enableSmsTwoFactor(
    String userId,
    String phoneNumber,
  );
  Future<Either<Failure, TwoFactorConfig>> enableTotpTwoFactor(
    String userId,
    String totpSecret,
  );
  Future<Either<Failure, void>> disableTwoFactor(String userId);
  Future<Either<Failure, TwoFactorConfig>> updateTwoFactorConfig(
    TwoFactorConfig config,
  );

  // Verification Flow
  Future<Either<Failure, TwoFactorVerification>> createSmsVerification(
    String userId,
    String sessionId,
  );
  Future<Either<Failure, TwoFactorVerification>> createTotpVerification(
    String userId,
    String sessionId,
  );
  Future<Either<Failure, bool>> verifySmsCode(
    String userId,
    String sessionId,
    String code,
  );
  Future<Either<Failure, bool>> verifyTotpCode(
    String userId,
    String sessionId,
    String code,
  );
  Future<Either<Failure, bool>> verifyBackupCode(
    String userId,
    String sessionId,
    String code,
  );

  // Backup Code Management
  Future<Either<Failure, List<String>>> generateBackupCodes(String userId);
  Future<Either<Failure, List<String>>> getBackupCodes(String userId);
  Future<Either<Failure, void>> regenerateBackupCodes(String userId);

  // Grace Period Management
  Future<Either<Failure, void>> startGracePeriod(
    String userId,
    String deviceId,
    Duration duration,
  );
  Future<Either<Failure, bool>> isGracePeriodActive(String userId);
  Future<Either<Failure, void>> endGracePeriod(String userId);

  // Security & Audit
  Future<Either<Failure, List<TwoFactorAudit>>> getAuditLog(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
    TwoFactorAuditAction? action,
  });
  Future<Either<Failure, void>> logAuditEvent(TwoFactorAudit audit);
  Future<Either<Failure, void>> lockAccount(String userId, String reason);
  Future<Either<Failure, void>> unlockAccount(String userId);

  // Rate Limiting
  Future<Either<Failure, bool>> canSendSms(String userId);
  Future<Either<Failure, bool>> canAttemptVerification(String userId);
  Future<Either<Failure, void>> incrementFailedAttempts(String userId);
  Future<Either<Failure, void>> resetFailedAttempts(String userId);

  // QR Code Generation
  Future<Either<Failure, String>> generateTotpQrCode(
    String userId,
    String secret,
    String appName,
  );
  Future<Either<Failure, String>> generateTotpSecret();

  // TOTP Validation
  Future<Either<Failure, bool>> validateTotpCode(String secret, String code);
}
