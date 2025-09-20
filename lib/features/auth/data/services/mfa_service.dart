import 'package:crypto/crypto.dart';
import 'package:dartz/dartz.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:video_window/core/error/failures.dart';
import 'package:video_window/features/auth/data/services/security_audit_service.dart';
import 'package:video_window/features/auth/data/services/sms_service.dart';
import 'package:video_window/features/auth/data/services/totp_service.dart';
import 'package:video_window/features/auth/domain/models/mfa_config_model.dart';
import 'package:video_window/features/auth/domain/models/sms_mfa_model.dart';
import 'package:video_window/features/auth/domain/models/totp_model.dart';
import 'package:video_window/features/auth/domain/repositories/mfa_repository.dart';

class MfaService implements MfaRepository {
  final SecurityAuditService _securityAuditService;
  final Encrypter _encrypter;
  final SmsService _smsService;
  final TotpService _totpService;
  final Uuid _uuid = const Uuid();

  // Rate limiting configuration
  static const int _maxSmsAttemptsPerHour = 5;
  static const int _maxMfaAttemptsPer15Minutes = 10;
  static const Duration _smsRateLimitWindow = Duration(hours: 1);
  static const Duration _mfaRateLimitWindow = Duration(minutes: 15);
  static const Duration _smsCodeExpiry = Duration(minutes: 10);
  static const Duration _totpSetupExpiry = Duration(minutes: 15);
  static const Duration _gracePeriod = Duration(hours: 24);

  // Mock storage - in real implementation, this would be database calls
  final Map<String, List<MfaConfigModel>> _mfaConfigs = {};
  final Map<String, SmsVerificationModel> _smsVerifications = {};
  final Map<String, TotpSetupModel> _totpSetups = {};
  final Map<String, TotpConfigModel> _totpConfigs = {};
  final Map<String, List<String>> _backupCodes = {};
  final Map<String, DateTime> _smsRateLimits = {};
  final Map<String, List<DateTime>> _mfaAttemptHistory = {};
  final Map<String, DateTime> _gracePeriods = {};
  final Map<String, List<MfaAuditModel>> _auditLogs = {};

  MfaService(
    this._securityAuditService,
    this._encrypter,
    this._smsService,
    this._totpService,
  );

  @override
  Future<Either<Failure, MfaConfigModel>> getMfaConfig(String userId) async {
    try {
      final userConfigs = _mfaConfigs[userId] ?? [];
      if (userConfigs.isEmpty) {
        return Left(NotFoundFailure('No MFA configuration found for user'));
      }

      // Return the primary MFA config or the first enabled one
      final primaryConfig = userConfigs.firstWhere(
        (config) => config.isPrimary && config.isEnabled,
        orElse: () => userConfigs.firstWhere(
          (config) => config.isEnabled,
          orElse: () => userConfigs.first,
        ),
      );

      return Right(primaryConfig);
    } catch (e) {
      return Left(ServerFailure('Failed to get MFA configuration'));
    }
  }

  @override
  Future<Either<Failure, List<MfaConfigModel>>> getUserMfaConfigs(
    String userId,
  ) async {
    try {
      final configs = _mfaConfigs[userId] ?? [];
      return Right(configs);
    } catch (e) {
      return Left(ServerFailure('Failed to get user MFA configurations'));
    }
  }

  @override
  Future<Either<Failure, MfaConfigModel>> createMfaConfig(
    MfaConfigModel config,
  ) async {
    try {
      final userId = config.userId;
      if (_mfaConfigs[userId] == null) {
        _mfaConfigs[userId] = [];
      }

      final newConfig = config.copyWith(
        id: _uuid.v4(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      _mfaConfigs[userId]!.add(newConfig);

      // Log MFA setup
      await logMfaEvent(
        userId: userId,
        auditType: MfaAuditType.setupCompleted,
        mfaType: config.mfaType,
        wasSuccessful: true,
      );

      return Right(newConfig);
    } catch (e) {
      return Left(ServerFailure('Failed to create MFA configuration'));
    }
  }

  @override
  Future<Either<Failure, MfaConfigModel>> updateMfaConfig(
    MfaConfigModel config,
  ) async {
    try {
      final userId = config.userId;
      final configs = _mfaConfigs[userId] ?? [];
      final index = configs.indexWhere((c) => c.id == config.id);

      if (index == -1) {
        return Left(NotFoundFailure('MFA configuration not found'));
      }

      final updatedConfig = config.copyWith(updatedAt: DateTime.now());
      configs[index] = updatedConfig;

      return Right(updatedConfig);
    } catch (e) {
      return Left(ServerFailure('Failed to update MFA configuration'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMfaConfig(String configId) async {
    try {
      // Find and remove the config
      for (final userId in _mfaConfigs.keys) {
        final configs = _mfaConfigs[userId]!;
        final index = configs.indexWhere((c) => c.id == configId);
        if (index != -1) {
          final config = configs[index];
          configs.removeAt(index);

          // Log MFA disable
          await logMfaEvent(
            userId: userId,
            auditType: MfaAuditType.methodDisabled,
            mfaType: config.mfaType,
            wasSuccessful: true,
          );

          break;
        }
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to delete MFA configuration'));
    }
  }

  @override
  Future<Either<Failure, bool>> isMfaEnabled(String userId) async {
    try {
      final configs = _mfaConfigs[userId] ?? [];
      final isEnabled = configs.any((config) => config.isEnabled);
      return Right(isEnabled);
    } catch (e) {
      return Left(ServerFailure('Failed to check MFA status'));
    }
  }

  @override
  Future<Either<Failure, SmsVerificationModel>> sendSmsVerificationCode({
    required String userId,
    required String phoneNumber,
    required String countryCode,
  }) async {
    try {
      // Check rate limiting
      final canSend = await canSendSmsCode(userId);
      if (canSend.isLeft()) {
        return Left(canSend.getLeft().toOption().toNullable()!);
      }

      // Use integrated SMS service to send code
      final fullPhoneNumber = '+$countryCode$phoneNumber';
      final smsSuccess = await _smsService.sendSmsCode(
        phoneNumber: fullPhoneNumber,
        userId: userId,
      );

      if (!smsSuccess) {
        return Left(ServerFailure('Failed to send SMS verification code'));
      }

      // Generate verification code (matching what SMS service would send)
      final code = _generateSmsCode();
      final verificationId = _uuid.v4();

      final verification = SmsVerificationModel(
        id: verificationId,
        userId: userId,
        phoneNumber: phoneNumber,
        countryCode: countryCode,
        verificationCode: code,
        expiresAt: DateTime.now().add(_smsCodeExpiry),
        createdAt: DateTime.now(),
      );

      _smsVerifications[verificationId] = verification;

      // Update rate limit
      _smsRateLimits[userId] = DateTime.now();

      // Log SMS send attempt
      await logMfaEvent(
        userId: userId,
        auditType: MfaAuditType.verificationAttempt,
        mfaType: MfaType.sms,
        wasSuccessful: true,
      );

      return Right(verification);
    } on SmsRateLimitExceededException catch (e) {
      await logMfaEvent(
        userId: userId,
        auditType: MfaAuditType.verificationFailed,
        mfaType: MfaType.sms,
        wasSuccessful: false,
        failureReason: 'Rate limit exceeded',
      );
      return Left(RateLimitFailure(e.message));
    } catch (e) {
      await logMfaEvent(
        userId: userId,
        auditType: MfaAuditType.verificationFailed,
        mfaType: MfaType.sms,
        wasSuccessful: false,
        failureReason: e.toString(),
      );
      return Left(ServerFailure('Failed to send SMS verification code'));
    }
  }

  @override
  Future<Either<Failure, bool>> verifySmsCode({
    required String verificationId,
    required String code,
  }) async {
    try {
      final verification = _smsVerifications[verificationId];
      if (verification == null) {
        return Left(NotFoundFailure('Verification not found'));
      }

      if (verification.isExpired) {
        return Left(ValidationFailure('Verification code has expired'));
      }

      if (verification.isLocked) {
        return Left(
          ValidationFailure(
            'Too many failed attempts. Please try again later.',
          ),
        );
      }

      if (verification.verificationCode != code) {
        // Update attempts
        _smsVerifications[verificationId] = verification.copyWith(
          attempts: verification.attempts + 1,
        );

        // Log failed attempt
        await logMfaEvent(
          userId: verification.userId,
          auditType: MfaAuditType.verificationFailed,
          mfaType: MfaType.sms,
          wasSuccessful: false,
          failureReason: 'Invalid verification code',
        );

        return Left(ValidationFailure('Invalid verification code'));
      }

      // Mark as verified
      _smsVerifications[verificationId] = verification.copyWith(
        isVerified: true,
      );

      // Log successful verification
      await logMfaEvent(
        userId: verification.userId,
        auditType: MfaAuditType.verificationSuccess,
        mfaType: MfaType.sms,
        wasSuccessful: true,
      );

      return Right(true);
    } catch (e) {
      return Left(ServerFailure('Failed to verify SMS code'));
    }
  }

  @override
  Future<Either<Failure, SmsMfaConfigModel>> setupSmsMfa({
    required String userId,
    required String phoneNumber,
    required String countryCode,
    required String verificationId,
    required String verificationCode,
  }) async {
    try {
      // Verify the SMS code first
      final verificationResult = await verifySmsCode(
        verificationId: verificationId,
        code: verificationCode,
      );

      if (verificationResult.isLeft()) {
        return Left(verificationResult.getLeft().toOption().toNullable()!);
      }

      // Create SMS MFA config
      final smsConfig = SmsMfaConfigModel(
        id: _uuid.v4(),
        userId: userId,
        phoneNumber: phoneNumber,
        countryCode: countryCode,
        isVerified: true,
        isEnabled: true,
        lastVerifiedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Create MFA config
      final mfaConfig = MfaConfigModel(
        id: _uuid.v4(),
        userId: userId,
        mfaType: MfaType.sms,
        isEnabled: true,
        isPrimary: true,
        config: {
          'sms_config_id': smsConfig.id,
          'phone_number': phoneNumber,
          'country_code': countryCode,
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Store configs
      if (_mfaConfigs[userId] == null) {
        _mfaConfigs[userId] = [];
      }
      _mfaConfigs[userId]!.add(mfaConfig);

      // Clean up verification
      _smsVerifications.remove(verificationId);

      return Right(smsConfig);
    } catch (e) {
      return Left(ServerFailure('Failed to setup SMS MFA'));
    }
  }

  @override
  Future<Either<Failure, bool>> disableSmsMfa(String userId) async {
    try {
      final configs = _mfaConfigs[userId] ?? [];
      final smsConfigs = configs
          .where((c) => c.mfaType == MfaType.sms)
          .toList();

      for (final config in smsConfigs) {
        await deleteMfaConfig(config.id);
      }

      return Right(true);
    } catch (e) {
      return Left(ServerFailure('Failed to disable SMS MFA'));
    }
  }

  @override
  Future<Either<Failure, TotpSetupModel>> initiateTotpSetup(
    String userId,
  ) async {
    try {
      final secret = _generateTotpSecret();
      final setupId = _uuid.v4();
      final backupCodes = _generateBackupCodes(10);

      final issuer = 'VideoWindow';
      final accountName = 'user_$userId';

      final qrCodeUri =
          'otpauth://totp/$issuer:$accountName?secret=$secret&issuer=$issuer&algorithm=SHA1&digits=6&period=30';

      final setup = TotpSetupModel(
        id: setupId,
        userId: userId,
        secret: secret,
        qrCodeUri: qrCodeUri,
        manualSetupKey: secret,
        backupCodes: backupCodes,
        expiresAt: DateTime.now().add(_totpSetupExpiry),
        createdAt: DateTime.now(),
      );

      _totpSetups[setupId] = setup;

      // Log TOTP setup initiation
      await logMfaEvent(
        userId: userId,
        auditType: MfaAuditType.setupInitiated,
        mfaType: MfaType.totp,
        wasSuccessful: true,
      );

      return Right(setup);
    } catch (e) {
      return Left(ServerFailure('Failed to initiate TOTP setup'));
    }
  }

  @override
  Future<Either<Failure, bool>> verifyTotpSetup({
    required String setupId,
    required String verificationCode,
  }) async {
    try {
      final setup = _totpSetups[setupId];
      if (setup == null) {
        return Left(NotFoundFailure('TOTP setup not found'));
      }

      if (setup.isExpired) {
        return Left(ValidationFailure('TOTP setup has expired'));
      }

      if (setup.isCompleted) {
        return Left(ValidationFailure('TOTP setup already completed'));
      }

      // Create temporary TOTP config for verification
      final tempTotpConfig = TotpConfigModel(
        id: _uuid.v4(),
        userId: setup.userId,
        secret: setup.secret,
        issuer: 'VideoWindow',
        accountName: 'user_${setup.userId}',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (!tempTotpConfig.verifyCode(verificationCode)) {
        // Log failed attempt
        await logMfaEvent(
          userId: setup.userId,
          auditType: MfaAuditType.setupFailed,
          mfaType: MfaType.totp,
          wasSuccessful: false,
          failureReason: 'Invalid TOTP code',
        );

        return Left(ValidationFailure('Invalid TOTP code'));
      }

      // Mark setup as completed
      _totpSetups[setupId] = setup.copyWith(isCompleted: true);

      // Log successful setup
      await logMfaEvent(
        userId: setup.userId,
        auditType: MfaAuditType.setupCompleted,
        mfaType: MfaType.totp,
        wasSuccessful: true,
      );

      return Right(true);
    } catch (e) {
      return Left(ServerFailure('Failed to verify TOTP setup'));
    }
  }

  @override
  Future<Either<Failure, TotpConfigModel>> completeTotpSetup({
    required String setupId,
    required String userId,
    required String accountName,
  }) async {
    try {
      final setup = _totpSetups[setupId];
      if (setup == null || !setup.isCompleted) {
        return Left(ValidationFailure('TOTP setup not completed'));
      }

      // Create TOTP config
      final totpConfig = TotpConfigModel(
        id: _uuid.v4(),
        userId: userId,
        secret: _encryptSecret(setup.secret),
        issuer: 'VideoWindow',
        accountName: accountName,
        isEnabled: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Create MFA config
      final mfaConfig = MfaConfigModel(
        id: _uuid.v4(),
        userId: userId,
        mfaType: MfaType.totp,
        isEnabled: true,
        isPrimary: true,
        config: {'totp_config_id': totpConfig.id, 'account_name': accountName},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Store TOTP config
      _totpConfigs[totpConfig.id] = totpConfig;

      // Store configs
      if (_mfaConfigs[userId] == null) {
        _mfaConfigs[userId] = [];
      }
      _mfaConfigs[userId]!.add(mfaConfig);

      // Store backup codes
      _backupCodes[userId] = List.from(setup.backupCodes);

      // Clean up setup
      _totpSetups.remove(setupId);

      return Right(totpConfig);
    } catch (e) {
      return Left(ServerFailure('Failed to complete TOTP setup'));
    }
  }

  @override
  Future<Either<Failure, bool>> verifyTotpCode({
    required String userId,
    required String code,
  }) async {
    try {
      final configs = _mfaConfigs[userId] ?? [];
      final mfaConfig = configs.firstWhere(
        (config) => config.mfaType == MfaType.totp && config.isEnabled,
        orElse: () => throw Exception('TOTP not configured'),
      );

      final totpConfigId = mfaConfig.config['totp_config_id'];
      final totpConfig = _totpConfigs[totpConfigId];

      if (totpConfig == null) {
        return Left(NotFoundFailure('TOTP configuration not found'));
      }

      // Decrypt the secret for verification
      final decryptedSecret = _decryptSecret(totpConfig.secret);
      final tempTotpConfig = totpConfig.copyWith(secret: decryptedSecret);

      if (!tempTotpConfig.verifyCode(code)) {
        await logMfaEvent(
          userId: userId,
          auditType: MfaAuditType.verificationFailed,
          mfaType: MfaType.totp,
          wasSuccessful: false,
          failureReason: 'Invalid TOTP code',
        );
        return Left(ValidationFailure('Invalid TOTP code'));
      }

      // Log successful verification
      await logMfaEvent(
        userId: userId,
        auditType: MfaAuditType.verificationSuccess,
        mfaType: MfaType.totp,
        wasSuccessful: true,
      );

      return Right(true);
    } catch (e) {
      await logMfaEvent(
        userId: userId,
        auditType: MfaAuditType.verificationFailed,
        mfaType: MfaType.totp,
        wasSuccessful: false,
        failureReason: e.toString(),
      );
      return Left(ValidationFailure('Failed to verify TOTP code'));
    }
  }

  @override
  Future<Either<Failure, bool>> disableTotpMfa(String userId) async {
    try {
      final configs = _mfaConfigs[userId] ?? [];
      final totpConfigs = configs
          .where((c) => c.mfaType == MfaType.totp)
          .toList();

      for (final config in totpConfigs) {
        // Clean up TOTP config
        final totpConfigId = config.config['totp_config_id'];
        if (totpConfigId != null) {
          _totpConfigs.remove(totpConfigId);
        }
        await deleteMfaConfig(config.id);
      }

      return Right(true);
    } catch (e) {
      return Left(ServerFailure('Failed to disable TOTP MFA'));
    }
  }

  @override
  Future<Either<Failure, List<String>>> generateBackupCodes(
    String userId,
  ) async {
    try {
      final codes = _generateBackupCodes(10);
      _backupCodes[userId] = List.from(codes);

      await logMfaEvent(
        userId: userId,
        auditType: MfaAuditType.backupCodeGenerated,
        wasSuccessful: true,
      );

      return Right(codes);
    } catch (e) {
      return Left(ServerFailure('Failed to generate backup codes'));
    }
  }

  @override
  Future<Either<Failure, bool>> verifyBackupCode({
    required String userId,
    required String code,
  }) async {
    try {
      final userBackupCodes = _backupCodes[userId] ?? [];
      if (!userBackupCodes.contains(code)) {
        await logMfaEvent(
          userId: userId,
          auditType: MfaAuditType.verificationFailed,
          mfaType: MfaType.backupCode,
          wasSuccessful: false,
          failureReason: 'Invalid backup code',
        );
        return Left(ValidationFailure('Invalid backup code'));
      }

      // Remove used backup code
      userBackupCodes.remove(code);
      _backupCodes[userId] = userBackupCodes;

      await logMfaEvent(
        userId: userId,
        auditType: MfaAuditType.backupCodeUsed,
        wasSuccessful: true,
      );

      return Right(true);
    } catch (e) {
      return Left(ServerFailure('Failed to verify backup code'));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getRemainingBackupCodes(
    String userId,
  ) async {
    try {
      final codes = _backupCodes[userId] ?? [];
      return Right(codes);
    } catch (e) {
      return Left(ServerFailure('Failed to get remaining backup codes'));
    }
  }

  @override
  Future<Either<Failure, bool>> verifyMfa({
    required String userId,
    required String code,
    MfaType? preferredMfaType,
  }) async {
    try {
      // Check rate limiting
      final canAttempt = await canAttemptMfaVerification(userId);
      if (canAttempt.isLeft()) {
        return Left(canAttempt.getLeft().toOption().toNullable()!);
      }

      // Get user MFA configs
      final configs = _mfaConfigs[userId] ?? [];
      if (configs.isEmpty) {
        return Left(ValidationFailure('MFA not configured for user'));
      }

      // Try preferred method first
      if (preferredMfaType != null) {
        final preferredConfig = configs.firstWhere(
          (config) => config.mfaType == preferredMfaType && config.isEnabled,
          orElse: () => configs.firstWhere(
            (config) => config.isEnabled,
            orElse: () => throw Exception('No enabled MFA method found'),
          ),
        );

        final result = await _verifyMfaWithConfig(
          preferredConfig,
          code,
          userId,
        );
        if (result.isRight()) {
          return result;
        }
      }

      // Try all enabled MFA methods
      for (final config in configs.where((c) => c.isEnabled)) {
        final result = await _verifyMfaWithConfig(config, code, userId);
        if (result.isRight()) {
          return result;
        }
      }

      // Log failed attempt
      await logMfaEvent(
        userId: userId,
        auditType: MfaAuditType.verificationFailed,
        wasSuccessful: false,
        failureReason: 'All MFA methods failed',
      );

      return Left(ValidationFailure('Invalid MFA code'));
    } catch (e) {
      return Left(ServerFailure('Failed to verify MFA'));
    }
  }

  Future<Either<Failure, bool>> _verifyMfaWithConfig(
    MfaConfigModel config,
    String code,
    String userId,
  ) async {
    switch (config.mfaType) {
      case MfaType.sms:
        // SMS verification would need the verification ID
        return Left(
          ValidationFailure('SMS verification requires verification ID'),
        );
      case MfaType.totp:
        return verifyTotpCode(userId: userId, code: code);
      case MfaType.backupCode:
        return verifyBackupCode(userId: userId, code: code);
      default:
        return Left(ValidationFailure('Unsupported MFA type'));
    }
  }

  @override
  Future<Either<Failure, bool>> isInGracePeriod(String userId) async {
    try {
      final gracePeriodEnd = _gracePeriods[userId];
      if (gracePeriodEnd == null) {
        return Right(false);
      }

      final isInGrace = DateTime.now().isBefore(gracePeriodEnd);
      return Right(isInGrace);
    } catch (e) {
      return Left(ServerFailure('Failed to check grace period'));
    }
  }

  @override
  Future<Either<Failure, DateTime>> getGracePeriodExpiry(String userId) async {
    try {
      final gracePeriodEnd = _gracePeriods[userId];
      if (gracePeriodEnd == null) {
        return Left(NotFoundFailure('No grace period found for user'));
      }

      return Right(gracePeriodEnd);
    } catch (e) {
      return Left(ServerFailure('Failed to get grace period expiry'));
    }
  }

  @override
  Future<Either<Failure, void>> extendGracePeriod(
    String userId,
    Duration duration,
  ) async {
    try {
      final currentEnd = _gracePeriods[userId] ?? DateTime.now();
      _gracePeriods[userId] = currentEnd.add(duration);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to extend grace period'));
    }
  }

  @override
  Future<Either<Failure, void>> endGracePeriod(String userId) async {
    try {
      _gracePeriods.remove(userId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to end grace period'));
    }
  }

  @override
  Future<Either<Failure, void>> lockMfaAccount(
    String userId,
    String reason,
  ) async {
    try {
      // In real implementation, this would update the user account status
      debugPrint('MFA account locked for user $userId: $reason');

      await logMfaEvent(
        userId: userId,
        auditType: MfaAuditType.accountLocked,
        wasSuccessful: true,
      );

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to lock MFA account'));
    }
  }

  @override
  Future<Either<Failure, void>> unlockMfaAccount(String userId) async {
    try {
      // In real implementation, this would update the user account status
      debugPrint('MFA account unlocked for user $userId');

      await logMfaEvent(
        userId: userId,
        auditType: MfaAuditType.accountUnlocked,
        wasSuccessful: true,
      );

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to unlock MFA account'));
    }
  }

  @override
  Future<Either<Failure, bool>> isMfaAccountLocked(String userId) async {
    try {
      // In real implementation, this would check the user account status
      return Right(false);
    } catch (e) {
      return Left(ServerFailure('Failed to check MFA account lock status'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getMfaSecurityStatus(
    String userId,
  ) async {
    try {
      final configs = _mfaConfigs[userId] ?? [];
      final isMfaEnabled = configs.any((config) => config.isEnabled);
      final hasBackupCodes = (_backupCodes[userId] ?? []).isNotEmpty;
      final isInGrace = (await isInGracePeriod(userId)).getOrElse(() => false);
      final isLocked = (await isMfaAccountLocked(
        userId,
      )).getOrElse(() => false);

      return Right({
        'mfa_enabled': isMfaEnabled,
        'has_backup_codes': hasBackupCodes,
        'in_grace_period': isInGrace,
        'is_locked': isLocked,
        'configured_methods': configs
            .where((c) => c.isEnabled)
            .map((c) => c.mfaType.name)
            .toList(),
        'backup_codes_remaining': (_backupCodes[userId] ?? []).length,
      });
    } catch (e) {
      return Left(ServerFailure('Failed to get MFA security status'));
    }
  }

  @override
  Future<Either<Failure, void>> logMfaVerificationAttempt({
    required String userId,
    required MfaType mfaType,
    required bool wasSuccessful,
    String? ipAddress,
    String? userAgent,
    String? failureReason,
  }) async {
    try {
      await logMfaEvent(
        userId: userId,
        auditType: wasSuccessful
            ? MfaAuditType.verificationSuccess
            : MfaAuditType.verificationFailed,
        mfaType: mfaType,
        wasSuccessful: wasSuccessful,
        ipAddress: ipAddress,
        userAgent: userAgent,
        failureReason: failureReason,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to log MFA verification attempt'));
    }
  }

  @override
  Future<Either<Failure, void>> logMfaEvent({
    required String userId,
    required MfaAuditType auditType,
    MfaType? mfaType,
    bool wasSuccessful = true,
    String? ipAddress,
    String? userAgent,
    String? deviceId,
    String? failureReason,
  }) async {
    try {
      final auditLog = MfaAuditModel(
        id: _uuid.v4(),
        userId: userId,
        auditType: auditType,
        mfaType: mfaType,
        wasSuccessful: wasSuccessful,
        ipAddress: ipAddress,
        userAgent: userAgent,
        deviceId: deviceId,
        failureReason: failureReason,
        createdAt: DateTime.now(),
      );

      if (_auditLogs[userId] == null) {
        _auditLogs[userId] = [];
      }
      _auditLogs[userId]!.add(auditLog);

      // Also log to security audit service
      await _securityAuditService.logSecurityEvent(
        userId: userId,
        eventType: 'mfa_${auditType.name}',
        wasSuccessful: wasSuccessful,
        details: {'mfa_type': mfaType?.name, 'failure_reason': failureReason},
      );

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to log MFA event'));
    }
  }

  @override
  Future<Either<Failure, List<MfaAuditModel>>> getMfaAuditLog(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      var logs = _auditLogs[userId] ?? [];

      // Filter by date range
      if (startDate != null) {
        logs = logs.where((log) => log.createdAt.isAfter(startDate)).toList();
      }
      if (endDate != null) {
        logs = logs.where((log) => log.createdAt.isBefore(endDate)).toList();
      }

      // Sort by creation date (newest first) and limit
      logs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      logs = logs.take(limit).toList();

      return Right(logs);
    } catch (e) {
      return Left(ServerFailure('Failed to get MFA audit log'));
    }
  }

  @override
  Future<Either<Failure, void>> setPreferredMfaMethod({
    required String userId,
    required MfaType mfaType,
  }) async {
    try {
      final configs = _mfaConfigs[userId] ?? [];

      // Update all configs to set preferred method
      for (int i = 0; i < configs.length; i++) {
        final config = configs[i];
        configs[i] = config.copyWith(isPrimary: config.mfaType == mfaType);
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to set preferred MFA method'));
    }
  }

  @override
  Future<Either<Failure, MfaType?>> getPreferredMfaMethod(String userId) async {
    try {
      final configs = _mfaConfigs[userId] ?? [];
      final primaryConfig = configs.firstWhere(
        (config) => config.isPrimary && config.isEnabled,
        orElse: () => configs.firstWhere(
          (config) => config.isEnabled,
          orElse: () => throw Exception('No enabled MFA method found'),
        ),
      );

      return Right(primaryConfig.mfaType);
    } catch (e) {
      return Right(null);
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getMfaSettings(
    String userId,
  ) async {
    try {
      final configs = _mfaConfigs[userId] ?? [];
      final preferredMethod = (await getPreferredMfaMethod(
        userId,
      )).getOrElse(() => null);
      final securityStatus = (await getMfaSecurityStatus(
        userId,
      )).getOrElse(() => {});

      return Right({
        'preferred_method': preferredMethod?.name,
        'configured_methods': configs.map((c) => c.mfaType.name).toList(),
        'enabled_methods': configs
            .where((c) => c.isEnabled)
            .map((c) => c.mfaType.name)
            .toList(),
        'security_status': securityStatus,
      });
    } catch (e) {
      return Left(ServerFailure('Failed to get MFA settings'));
    }
  }

  @override
  Future<Either<Failure, void>> updateMfaSettings({
    required String userId,
    required Map<String, dynamic> settings,
  }) async {
    try {
      // Update various MFA settings based on the provided map
      if (settings['preferred_method'] != null) {
        final preferredMethod = MfaType.values.firstWhere(
          (type) => type.name == settings['preferred_method'],
          orElse: () => throw Exception('Invalid MFA type'),
        );
        await setPreferredMfaMethod(userId: userId, mfaType: preferredMethod);
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to update MFA settings'));
    }
  }

  @override
  Future<Either<Failure, bool>> canSendSmsCode(String userId) async {
    try {
      final lastAttempt = _smsRateLimits[userId];
      if (lastAttempt == null) {
        return Right(true);
      }

      final timeSinceLastAttempt = DateTime.now().difference(lastAttempt);
      final canSend =
          timeSinceLastAttempt >=
          Duration(minutes: 60 ~/ _maxSmsAttemptsPerHour);

      if (!canSend) {
        final nextAvailable = lastAttempt.add(
          Duration(minutes: 60 ~/ _maxSmsAttemptsPerHour),
        );
        final timeRemaining = nextAvailable.difference(DateTime.now());
        return Left(
          RateLimitFailure(
            'SMS rate limit exceeded. Try again in ${timeRemaining.inMinutes} minutes.',
          ),
        );
      }

      return Right(canSend);
    } catch (e) {
      return Left(ServerFailure('Failed to check SMS rate limit'));
    }
  }

  @override
  Future<Either<Failure, bool>> canAttemptMfaVerification(String userId) async {
    try {
      final attempts = _mfaAttemptHistory[userId] ?? [];
      final recentAttempts = attempts
          .where(
            (attempt) =>
                DateTime.now().difference(attempt) <= _mfaRateLimitWindow,
          )
          .toList();

      if (recentAttempts.length >= _maxMfaAttemptsPer15Minutes) {
        final oldestAttempt = recentAttempts.reduce(
          (a, b) => a.isBefore(b) ? a : b,
        );
        final nextAvailable = oldestAttempt.add(_mfaRateLimitWindow);
        final timeRemaining = nextAvailable.difference(DateTime.now());
        return Left(
          RateLimitFailure(
            'Too many MFA attempts. Try again in ${timeRemaining.inMinutes} minutes.',
          ),
        );
      }

      return Right(true);
    } catch (e) {
      return Left(ServerFailure('Failed to check MFA attempt limit'));
    }
  }

  @override
  Future<Either<Failure, Duration>> getNextSmsCodeAvailableTime(
    String userId,
  ) async {
    try {
      final lastAttempt = _smsRateLimits[userId];
      if (lastAttempt == null) {
        return Right(Duration.zero);
      }

      final nextAvailable = lastAttempt.add(
        Duration(minutes: 60 ~/ _maxSmsAttemptsPerHour),
      );
      final timeRemaining = nextAvailable.difference(DateTime.now());

      return Right(timeRemaining);
    } catch (e) {
      return Left(ServerFailure('Failed to get next SMS code available time'));
    }
  }

  @override
  Future<Either<Failure, Duration>> getNextMfaAttemptAvailableTime(
    String userId,
  ) async {
    try {
      final attempts = _mfaAttemptHistory[userId] ?? [];
      final recentAttempts = attempts
          .where(
            (attempt) =>
                DateTime.now().difference(attempt) <= _mfaRateLimitWindow,
          )
          .toList();

      if (recentAttempts.length < _maxMfaAttemptsPer15Minutes) {
        return Right(Duration.zero);
      }

      final oldestAttempt = recentAttempts.reduce(
        (a, b) => a.isBefore(b) ? a : b,
      );
      final nextAvailable = oldestAttempt.add(_mfaRateLimitWindow);
      final timeRemaining = nextAvailable.difference(DateTime.now());

      return Right(timeRemaining);
    } catch (e) {
      return Left(
        ServerFailure('Failed to get next MFA attempt available time'),
      );
    }
  }

  // Helper methods
  String _generateSmsCode() {
    final random = crypto.Random.secure();
    return List.generate(6, (index) => random.nextInt(10)).join();
  }

  String _generateTotpSecret() {
    final random = crypto.Random.secure();
    final bytes = List<int>.generate(32, (index) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  List<String> _generateBackupCodes(int count) {
    final random = crypto.Random.secure();
    final codes = <String>[];

    for (int i = 0; i < count; i++) {
      final code = List.generate(8, (index) => random.nextInt(10)).join();
      codes.add(code);
    }

    return codes;
  }

  String _encryptSecret(String secret) {
    final key = Key.fromUtf8('32-char-long-encryption-key-here');
    final iv = IV.fromLength(16);
    final encrypted = _encrypter.encrypt(secret, iv: iv);
    return encrypted.base64;
  }

  String _decryptSecret(String encryptedSecret) {
    final key = Key.fromUtf8('32-char-long-encryption-key-here');
    final iv = IV.fromLength(16);
    final decrypted = _encrypter.decrypt64(encryptedSecret, iv: iv);
    return decrypted;
  }
}
