import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import 'package:logger/logger.dart';
import '../../domain/repositories/two_factor_repository.dart';
import '../../domain/models/two_factor_config_model.dart';
import '../../domain/models/two_factor_verification_model.dart';
import '../../domain/models/two_factor_audit_model.dart';
import '../datasources/two_factor_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';
import '../services/sms_service.dart';
import '../services/totp_service.dart';
import '../services/rate_limiting_service.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/network_info.dart';

class TwoFactorRepositoryImpl implements TwoFactorRepository {
  final TwoFactorLocalDataSource localDataSource;
  final AuthRemoteDataSource remoteDataSource;
  final SmsService smsService;
  final TotpService totpService;
  final RateLimitingService rateLimitingService;
  final NetworkInfo networkInfo;
  final Logger logger;
  final Uuid uuid;

  TwoFactorRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.smsService,
    required this.totpService,
    required this.rateLimitingService,
    required this.networkInfo,
    required this.logger,
    required this.uuid,
  });

  @override
  Future<Either<Failure, TwoFactorConfig>> getTwoFactorConfig(
    String userId,
  ) async {
    try {
      if (await networkInfo.isConnected) {
        final remoteConfig = await remoteDataSource.getTwoFactorConfig(userId);
        await localDataSource.cacheTwoFactorConfig(remoteConfig);
        return Right(remoteConfig);
      } else {
        final localConfig = await localDataSource.getCachedTwoFactorConfig(
          userId,
        );
        if (localConfig != null) {
          return Right(localConfig);
        } else {
          return Left(
            NetworkFailure(
              'No internet connection and no cached config available',
            ),
          );
        }
      }
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, TwoFactorConfig>> enableSmsTwoFactor(
    String userId,
    String phoneNumber,
  ) async {
    try {
      if (!await networkInfo.isConnected) {
        return Left(NetworkFailure('No internet connection'));
      }

      final canSendSms = await rateLimitingService.canSendSms(userId);
      if (!canSendSms) {
        return Left(RateLimitFailure('SMS rate limit exceeded'));
      }

      final verificationCode = _generateSmsCode();
      final sent = await smsService.sendVerificationCode(
        phoneNumber,
        verificationCode,
      );

      if (!sent) {
        return Left(ServerFailure('Failed to send verification SMS'));
      }

      await rateLimitingService.recordSmsAttempt(userId);

      final config = TwoFactorConfig(
        id: uuid.v4(),
        userId: userId,
        method: TwoFactorMethod.sms,
        status: TwoFactorStatus.pending,
        phoneNumber: phoneNumber,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updatedConfig = await remoteDataSource.updateTwoFactorConfig(
        config,
      );
      await localDataSource.cacheTwoFactorConfig(updatedConfig);

      await _logAuditEvent(
        TwoFactorAudit(
          id: uuid.v4(),
          userId: userId,
          action: TwoFactorAuditAction.setup,
          status: TwoFactorAuditStatus.success,
          details: 'SMS 2FA setup initiated',
          timestamp: DateTime.now(),
        ),
      );

      return Right(updatedConfig);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, TwoFactorConfig>> enableTotpTwoFactor(
    String userId,
    String totpSecret,
  ) async {
    try {
      if (!await networkInfo.isConnected) {
        return Left(NetworkFailure('No internet connection'));
      }

      final config = TwoFactorConfig(
        id: uuid.v4(),
        userId: userId,
        method: TwoFactorMethod.totp,
        status: TwoFactorStatus.pending,
        totpSecret: totpSecret,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updatedConfig = await remoteDataSource.updateTwoFactorConfig(
        config,
      );
      await localDataSource.cacheTwoFactorConfig(updatedConfig);

      await _logAuditEvent(
        TwoFactorAudit(
          id: uuid.v4(),
          userId: userId,
          action: TwoFactorAuditAction.setup,
          status: TwoFactorAuditStatus.success,
          details: 'TOTP 2FA setup initiated',
          timestamp: DateTime.now(),
        ),
      );

      return Right(updatedConfig);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> disableTwoFactor(String userId) async {
    try {
      if (!await networkInfo.isConnected) {
        return Left(NetworkFailure('No internet connection'));
      }

      await remoteDataSource.disableTwoFactor(userId);
      await localDataSource.clearCachedTwoFactorConfig(userId);

      await _logAuditEvent(
        TwoFactorAudit(
          id: uuid.v4(),
          userId: userId,
          action: TwoFactorAuditAction.disable,
          status: TwoFactorAuditStatus.success,
          details: '2FA disabled',
          timestamp: DateTime.now(),
        ),
      );

      await rateLimitingService.resetRateLimits(userId);

      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, TwoFactorConfig>> updateTwoFactorConfig(
    TwoFactorConfig config,
  ) async {
    try {
      if (!await networkInfo.isConnected) {
        return Left(NetworkFailure('No internet connection'));
      }

      final updatedConfig = await remoteDataSource.updateTwoFactorConfig(
        config,
      );
      await localDataSource.cacheTwoFactorConfig(updatedConfig);
      return Right(updatedConfig);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, TwoFactorVerification>> createSmsVerification(
    String userId,
    String sessionId,
  ) async {
    try {
      if (!await networkInfo.isConnected) {
        return Left(NetworkFailure('No internet connection'));
      }

      final canSendSms = await rateLimitingService.canSendSms(userId);
      if (!canSendSms) {
        return Left(RateLimitFailure('SMS rate limit exceeded'));
      }

      final config = await getTwoFactorConfig(userId);
      return config.fold((failure) => Left(failure), (config) async {
        if (config.method != TwoFactorMethod.sms ||
            config.phoneNumber == null) {
          return Left(InvalidInputFailure('SMS 2FA not configured'));
        }

        final code = _generateSmsCode();
        final sent = await smsService.sendTwoFactorCode(
          config.phoneNumber!,
          code,
        );

        if (!sent) {
          return Left(ServerFailure('Failed to send 2FA SMS'));
        }

        await rateLimitingService.recordSmsAttempt(userId);

        final verification = TwoFactorVerification(
          id: uuid.v4(),
          userId: userId,
          type: TwoFactorVerificationType.login,
          sessionId: sessionId,
          code: code,
          expiresAt: DateTime.now().add(const Duration(minutes: 10)),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await localDataSource.cacheVerificationSession(verification);
        return Right(verification);
      });
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, TwoFactorVerification>> createTotpVerification(
    String userId,
    String sessionId,
  ) async {
    try {
      final config = await getTwoFactorConfig(userId);
      return config.fold((failure) => Left(failure), (config) async {
        if (config.method != TwoFactorMethod.totp ||
            config.totpSecret == null) {
          return Left(InvalidInputFailure('TOTP 2FA not configured'));
        }

        final verification = TwoFactorVerification(
          id: uuid.v4(),
          userId: userId,
          type: TwoFactorVerificationType.login,
          sessionId: sessionId,
          code: '',
          expiresAt: DateTime.now().add(const Duration(minutes: 10)),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await localDataSource.cacheVerificationSession(verification);
        return Right(verification);
      });
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> verifySmsCode(
    String userId,
    String sessionId,
    String code,
  ) async {
    try {
      final canVerify = await rateLimitingService.canAttemptVerification(
        userId,
      );
      if (!canVerify) {
        return Left(RateLimitFailure('Verification rate limit exceeded'));
      }

      final verification = await localDataSource.getCachedVerificationSession(
        sessionId,
      );
      if (verification == null || verification.isExpired) {
        return Left(
          InvalidInputFailure('Invalid or expired verification session'),
        );
      }

      final isValid = verification.code == code;

      if (isValid) {
        await localDataSource.clearVerificationSession(sessionId);
        await rateLimitingService.resetRateLimits(userId);

        await _logAuditEvent(
          TwoFactorAudit(
            id: uuid.v4(),
            userId: userId,
            action: TwoFactorAuditAction.verify,
            status: TwoFactorAuditStatus.success,
            details: 'SMS 2FA verification successful',
            timestamp: DateTime.now(),
          ),
        );
      } else {
        await rateLimitingService.recordVerificationAttempt(userId);
        await _logAuditEvent(
          TwoFactorAudit(
            id: uuid.v4(),
            userId: userId,
            action: TwoFactorAuditAction.failedAttempt,
            status: TwoFactorAuditStatus.failed,
            details: 'SMS 2FA verification failed',
            timestamp: DateTime.now(),
          ),
        );
      }

      return Right(isValid);
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> verifyTotpCode(
    String userId,
    String sessionId,
    String code,
  ) async {
    try {
      final canVerify = await rateLimitingService.canAttemptVerification(
        userId,
      );
      if (!canVerify) {
        return Left(RateLimitFailure('Verification rate limit exceeded'));
      }

      final config = await getTwoFactorConfig(userId);
      return config.fold((failure) => Left(failure), (config) async {
        if (config.method != TwoFactorMethod.totp ||
            config.totpSecret == null) {
          return Left(InvalidInputFailure('TOTP 2FA not configured'));
        }

        final isValid = totpService.verifyCode(config.totpSecret!, code);

        if (isValid) {
          await localDataSource.clearVerificationSession(sessionId);
          await rateLimitingService.resetRateLimits(userId);

          await _logAuditEvent(
            TwoFactorAudit(
              id: uuid.v4(),
              userId: userId,
              action: TwoFactorAuditAction.verify,
              status: TwoFactorAuditStatus.success,
              details: 'TOTP 2FA verification successful',
              timestamp: DateTime.now(),
            ),
          );
        } else {
          await rateLimitingService.recordVerificationAttempt(userId);
          await _logAuditEvent(
            TwoFactorAudit(
              id: uuid.v4(),
              userId: userId,
              action: TwoFactorAuditAction.failedAttempt,
              status: TwoFactorAuditStatus.failed,
              details: 'TOTP 2FA verification failed',
              timestamp: DateTime.now(),
            ),
          );
        }

        return Right(isValid);
      });
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> verifyBackupCode(
    String userId,
    String sessionId,
    String code,
  ) async {
    try {
      final canVerify = await rateLimitingService.canAttemptVerification(
        userId,
      );
      if (!canVerify) {
        return Left(RateLimitFailure('Verification rate limit exceeded'));
      }

      final backupCodes = await localDataSource.getBackupCodes(userId);
      final isValid = backupCodes.contains(code);

      if (isValid) {
        await localDataSource.removeBackupCode(userId, code);
        await localDataSource.clearVerificationSession(sessionId);
        await rateLimitingService.resetRateLimits(userId);

        await _logAuditEvent(
          TwoFactorAudit(
            id: uuid.v4(),
            userId: userId,
            action: TwoFactorAuditAction.verify,
            status: TwoFactorAuditStatus.success,
            details: 'Backup code verification successful',
            timestamp: DateTime.now(),
          ),
        );
      } else {
        await rateLimitingService.recordVerificationAttempt(userId);
        await _logAuditEvent(
          TwoFactorAudit(
            id: uuid.v4(),
            userId: userId,
            action: TwoFactorAuditAction.failedAttempt,
            status: TwoFactorAuditStatus.failed,
            details: 'Backup code verification failed',
            timestamp: DateTime.now(),
          ),
        );
      }

      return Right(isValid);
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> generateBackupCodes(
    String userId,
  ) async {
    try {
      final backupCodes = totpService.generateBackupCodes();
      await localDataSource.storeBackupCodes(userId, backupCodes);

      await _logAuditEvent(
        TwoFactorAudit(
          id: uuid.v4(),
          userId: userId,
          action: TwoFactorAuditAction.regenerateBackupCodes,
          status: TwoFactorAuditStatus.success,
          details: 'Generated ${backupCodes.length} backup codes',
          timestamp: DateTime.now(),
        ),
      );

      return Right(backupCodes);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getBackupCodes(String userId) async {
    try {
      final backupCodes = await localDataSource.getBackupCodes(userId);
      return Right(backupCodes);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> regenerateBackupCodes(String userId) async {
    try {
      final newBackupCodes = totpService.generateBackupCodes();
      await localDataSource.storeBackupCodes(userId, newBackupCodes);

      await _logAuditEvent(
        TwoFactorAudit(
          id: uuid.v4(),
          userId: userId,
          action: TwoFactorAuditAction.regenerateBackupCodes,
          status: TwoFactorAuditStatus.success,
          details: 'Regenerated ${newBackupCodes.length} backup codes',
          timestamp: DateTime.now(),
        ),
      );

      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> startGracePeriod(
    String userId,
    String deviceId,
    Duration duration,
  ) async {
    try {
      final config = await getTwoFactorConfig(userId);
      return config.fold((failure) => Left(failure), (config) async {
        final updatedConfig = config.copyWith(
          isGracePeriodActive: true,
          gracePeriodEndsAt: DateTime.now().add(duration),
        );

        return await updateTwoFactorConfig(updatedConfig);
      });
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isGracePeriodActive(String userId) async {
    try {
      final config = await getTwoFactorConfig(userId);
      return config.fold((failure) => Left(failure), (config) async {
        if (config.isGracePeriodActive && config.gracePeriodEndsAt != null) {
          final isExpired = config.gracePeriodEndsAt!.isBefore(DateTime.now());
          if (isExpired) {
            await endGracePeriod(userId);
            return Right(false);
          }
          return Right(true);
        }
        return Right(false);
      });
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> endGracePeriod(String userId) async {
    try {
      final config = await getTwoFactorConfig(userId);
      return config.fold((failure) => Left(failure), (config) async {
        final updatedConfig = config.copyWith(
          isGracePeriodActive: false,
          gracePeriodEndsAt: null,
        );

        return await updateTwoFactorConfig(updatedConfig);
      });
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TwoFactorAudit>>> getAuditLog(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
    TwoFactorAuditAction? action,
  }) async {
    try {
      final auditLogs = await remoteDataSource.getTwoFactorAuditLog(
        userId,
        startDate: startDate,
        endDate: endDate,
        action: action,
      );
      return Right(auditLogs);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logAuditEvent(TwoFactorAudit audit) async {
    try {
      await remoteDataSource.logTwoFactorAuditEvent(audit);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> lockAccount(
    String userId,
    String reason,
  ) async {
    try {
      await remoteDataSource.lockTwoFactorAccount(userId, reason);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> unlockAccount(String userId) async {
    try {
      await remoteDataSource.unlockTwoFactorAccount(userId);
      await rateLimitingService.resetRateLimits(userId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> canSendSms(String userId) async {
    try {
      final canSend = await rateLimitingService.canSendSms(userId);
      return Right(canSend);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> canAttemptVerification(String userId) async {
    try {
      final canAttempt = await rateLimitingService.canAttemptVerification(
        userId,
      );
      return Right(canAttempt);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> incrementFailedAttempts(String userId) async {
    try {
      await rateLimitingService.recordVerificationAttempt(userId);
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resetFailedAttempts(String userId) async {
    try {
      await rateLimitingService.resetRateLimits(userId);
      return const Right(null);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> generateTotpQrCode(
    String userId,
    String secret,
    String appName,
  ) async {
    try {
      final qrCodeUrl = totpService.generateQrCodeUrl(
        secret: secret,
        userId: userId,
        appName: appName,
      );
      return Right(qrCodeUrl);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> generateTotpSecret() async {
    try {
      final secret = totpService.generateSecret();
      return Right(secret);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> validateTotpCode(
    String secret,
    String code,
  ) async {
    try {
      final isValid = totpService.verifyCode(secret, code);
      return Right(isValid);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  String _generateSmsCode() {
    final random = DateTime.now().millisecondsSinceEpoch % 1000000;
    return random.toString().padLeft(6, '0');
  }

  Future<void> _logAuditEvent(TwoFactorAudit audit) async {
    try {
      await remoteDataSource.logTwoFactorAuditEvent(audit);
    } catch (e) {
      logger.e('Failed to log audit event: ${e.toString()}');
    }
  }
}
