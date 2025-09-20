import 'package:dartz/dartz.dart';
import 'package:video_window/core/error/failures.dart';
import 'package:video_window/features/auth/domain/models/mfa_config_model.dart';
import 'package:video_window/features/auth/domain/models/sms_mfa_model.dart';
import 'package:video_window/features/auth/domain/models/totp_model.dart';

abstract class MfaRepository {
  // MFA Configuration
  Future<Either<Failure, MfaConfigModel>> getMfaConfig(String userId);
  Future<Either<Failure, List<MfaConfigModel>>> getUserMfaConfigs(
    String userId,
  );
  Future<Either<Failure, MfaConfigModel>> createMfaConfig(
    MfaConfigModel config,
  );
  Future<Either<Failure, MfaConfigModel>> updateMfaConfig(
    MfaConfigModel config,
  );
  Future<Either<Failure, void>> deleteMfaConfig(String configId);
  Future<Either<Failure, bool>> isMfaEnabled(String userId);

  // SMS MFA
  Future<Either<Failure, SmsVerificationModel>> sendSmsVerificationCode({
    required String userId,
    required String phoneNumber,
    required String countryCode,
  });

  Future<Either<Failure, bool>> verifySmsCode({
    required String verificationId,
    required String code,
  });

  Future<Either<Failure, SmsMfaConfigModel>> setupSmsMfa({
    required String userId,
    required String phoneNumber,
    required String countryCode,
    required String verificationId,
    required String verificationCode,
  });

  Future<Either<Failure, bool>> disableSmsMfa(String userId);

  // TOTP MFA
  Future<Either<Failure, TotpSetupModel>> initiateTotpSetup(String userId);
  Future<Either<Failure, bool>> verifyTotpSetup({
    required String setupId,
    required String verificationCode,
  });

  Future<Either<Failure, TotpConfigModel>> completeTotpSetup({
    required String setupId,
    required String userId,
    required String accountName,
  });

  Future<Either<Failure, bool>> verifyTotpCode({
    required String userId,
    required String code,
  });

  Future<Either<Failure, bool>> disableTotpMfa(String userId);

  // Backup Codes
  Future<Either<Failure, List<String>>> generateBackupCodes(String userId);
  Future<Either<Failure, bool>> verifyBackupCode({
    required String userId,
    required String code,
  });

  Future<Either<Failure, List<String>>> getRemainingBackupCodes(String userId);

  // MFA Verification
  Future<Either<Failure, bool>> verifyMfa({
    required String userId,
    required String code,
    MfaType? preferredMfaType,
  });

  Future<Either<Failure, void>> logMfaVerificationAttempt({
    required String userId,
    required MfaType mfaType,
    required bool wasSuccessful,
    String? ipAddress,
    String? userAgent,
    String? failureReason,
  });

  // Grace Period Management
  Future<Either<Failure, bool>> isInGracePeriod(String userId);
  Future<Either<Failure, DateTime>> getGracePeriodExpiry(String userId);
  Future<Either<Failure, void>> extendGracePeriod(
    String userId,
    Duration duration,
  );
  Future<Either<Failure, void>> endGracePeriod(String userId);

  // Security and Recovery
  Future<Either<Failure, void>> lockMfaAccount(String userId, String reason);
  Future<Either<Failure, void>> unlockMfaAccount(String userId);
  Future<Either<Failure, bool>> isMfaAccountLocked(String userId);
  Future<Either<Failure, Map<String, dynamic>>> getMfaSecurityStatus(
    String userId,
  );

  // Audit Logging
  Future<Either<Failure, void>> logMfaEvent({
    required String userId,
    required MfaAuditType auditType,
    MfaType? mfaType,
    bool wasSuccessful = true,
    String? ipAddress,
    String? userAgent,
    String? deviceId,
    String? failureReason,
  });

  Future<Either<Failure, List<MfaAuditModel>>> getMfaAuditLog(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  });

  // Settings and Preferences
  Future<Either<Failure, void>> setPreferredMfaMethod({
    required String userId,
    required MfaType mfaType,
  });

  Future<Either<Failure, MfaType?>> getPreferredMfaMethod(String userId);
  Future<Either<Failure, Map<String, dynamic>>> getMfaSettings(String userId);
  Future<Either<Failure, void>> updateMfaSettings({
    required String userId,
    required Map<String, dynamic> settings,
  });

  // Rate Limiting
  Future<Either<Failure, bool>> canSendSmsCode(String userId);
  Future<Either<Failure, bool>> canAttemptMfaVerification(String userId);
  Future<Either<Failure, Duration>> getNextSmsCodeAvailableTime(String userId);
  Future<Either<Failure, Duration>> getNextMfaAttemptAvailableTime(
    String userId,
  );
}
