import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:video_window/core/error/failures.dart';
import 'package:video_window/features/auth/data/services/mfa_service.dart';
import 'package:video_window/features/auth/data/services/security_audit_service.dart';
import 'package:video_window/features/auth/domain/models/mfa_config_model.dart';
import 'package:video_window/features/auth/domain/models/sms_mfa_model.dart';
import 'package:video_window/features/auth/domain/models/totp_model.dart';

part 'mfa_event.dart';
part 'mfa_state.dart';

class MfaBloc extends Bloc<MfaEvent, MfaState> {
  final MfaService _mfaService;
  final SecurityAuditService _securityAuditService;

  MfaBloc(this._mfaService, this._securityAuditService)
    : super(const MfaInitialState()) {
    // MFA Configuration Handlers
    on<MfaLoadConfigEvent>(_onLoadConfig);
    on<MfaGetSecurityStatusEvent>(_onGetSecurityStatus);
    on<MfaLoadSettingsEvent>(_onLoadSettings);
    on<MfaUpdateSettingsEvent>(_onUpdateSettings);

    // SMS MFA Handlers
    on<MfaSendSmsCodeEvent>(_onSendSmsCode);
    on<MfaVerifySmsCodeEvent>(_onVerifySmsCode);
    on<MfaSetupSmsEvent>(_onSetupSms);
    on<MfaDisableSmsEvent>(_onDisableSms);

    // TOTP MFA Handlers
    on<MfaInitiateTotpSetupEvent>(_onInitiateTotpSetup);
    on<MfaVerifyTotpSetupEvent>(_onVerifyTotpSetup);
    on<MfaCompleteTotpSetupEvent>(_onCompleteTotpSetup);
    on<MfaVerifyTotpCodeEvent>(_onVerifyTotpCode);
    on<MfaDisableTotpEvent>(_onDisableTotp);

    // Backup Code Handlers
    on<MfaGenerateBackupCodesEvent>(_onGenerateBackupCodes);
    on<MfaVerifyBackupCodeEvent>(_onVerifyBackupCode);
    on<MfaGetRemainingBackupCodesEvent>(_onGetRemainingBackupCodes);

    // MFA Verification Handlers
    on<MfaVerifyCodeEvent>(_onVerifyCode);

    // Grace Period Handlers
    on<MfaCheckGracePeriodEvent>(_onCheckGracePeriod);
    on<MfaExtendGracePeriodEvent>(_onExtendGracePeriod);
    on<MfaEndGracePeriodEvent>(_onEndGracePeriod);

    // Security Handlers
    on<MfaLockAccountEvent>(_onLockAccount);
    on<MfaUnlockAccountEvent>(_onUnlockAccount);
    on<MfaSetPreferredMethodEvent>(_onSetPreferredMethod);

    // Audit Handlers
    on<MfaLoadAuditLogEvent>(_onLoadAuditLog);
  }

  // MFA Configuration Handlers
  Future<void> _onLoadConfig(
    MfaLoadConfigEvent event,
    Emitter<MfaState> emit,
  ) async {
    emit(const MfaLoadingState());

    final result = await _mfaService.getMfaConfig(event.userId);

    result.fold(
      (failure) => emit(MfaErrorState(message: _mapFailureToMessage(failure))),
      (config) => emit(MfaConfigLoadedState(config: config)),
    );
  }

  Future<void> _onGetSecurityStatus(
    MfaGetSecurityStatusEvent event,
    Emitter<MfaState> emit,
  ) async {
    emit(const MfaLoadingState());

    final result = await _mfaService.getMfaSecurityStatus(event.userId);

    result.fold(
      (failure) => emit(MfaErrorState(message: _mapFailureToMessage(failure))),
      (securityStatus) =>
          emit(MfaSecurityStatusLoadedState(securityStatus: securityStatus)),
    );
  }

  Future<void> _onLoadSettings(
    MfaLoadSettingsEvent event,
    Emitter<MfaState> emit,
  ) async {
    emit(const MfaLoadingState());

    final result = await _mfaService.getMfaSettings(event.userId);

    result.fold(
      (failure) => emit(MfaErrorState(message: _mapFailureToMessage(failure))),
      (settings) => emit(MfaSettingsLoadedState(settings: settings)),
    );
  }

  Future<void> _onUpdateSettings(
    MfaUpdateSettingsEvent event,
    Emitter<MfaState> emit,
  ) async {
    emit(const MfaLoadingState());

    final result = await _mfaService.updateMfaSettings(
      userId: event.userId,
      settings: event.settings,
    );

    result.fold(
      (failure) => emit(MfaErrorState(message: _mapFailureToMessage(failure))),
      (_) => emit(const MfaSettingsUpdatedState()),
    );
  }

  // SMS MFA Handlers
  Future<void> _onSendSmsCode(
    MfaSendSmsCodeEvent event,
    Emitter<MfaState> emit,
  ) async {
    emit(const MfaLoadingState());

    final result = await _mfaService.sendSmsVerificationCode(
      userId: event.userId,
      phoneNumber: event.phoneNumber,
      countryCode: event.countryCode,
    );

    result.fold(
      (failure) => emit(MfaErrorState(message: _mapFailureToMessage(failure))),
      (verification) => emit(MfaSmsCodeSentState(verification: verification)),
    );
  }

  Future<void> _onVerifySmsCode(
    MfaVerifySmsCodeEvent event,
    Emitter<MfaState> emit,
  ) async {
    emit(const MfaLoadingState());

    final result = await _mfaService.verifySmsCode(
      verificationId: event.verificationId,
      code: event.code,
    );

    result.fold(
      (failure) => emit(MfaErrorState(message: _mapFailureToMessage(failure))),
      (_) => emit(const MfaSmsCodeVerifiedState()),
    );
  }

  Future<void> _onSetupSms(
    MfaSetupSmsEvent event,
    Emitter<MfaState> emit,
  ) async {
    emit(const MfaLoadingState());

    final result = await _mfaService.setupSmsMfa(
      userId: event.userId,
      phoneNumber: event.phoneNumber,
      countryCode: event.countryCode,
      verificationId: event.verificationId,
      verificationCode: event.verificationCode,
    );

    result.fold(
      (failure) => emit(MfaErrorState(message: _mapFailureToMessage(failure))),
      (smsConfig) => emit(MfaSmsSetupCompleteState(smsConfig: smsConfig)),
    );
  }

  Future<void> _onDisableSms(
    MfaDisableSmsEvent event,
    Emitter<MfaState> emit,
  ) async {
    emit(const MfaLoadingState());

    final result = await _mfaService.disableSmsMfa(event.userId);

    result.fold(
      (failure) => emit(MfaErrorState(message: _mapFailureToMessage(failure))),
      (_) => emit(const MfaSmsDisabledState()),
    );
  }

  // TOTP MFA Handlers
  Future<void> _onInitiateTotpSetup(
    MfaInitiateTotpSetupEvent event,
    Emitter<MfaState> emit,
  ) async {
    emit(const MfaLoadingState());

    final result = await _mfaService.initiateTotpSetup(event.userId);

    result.fold(
      (failure) => emit(MfaErrorState(message: _mapFailureToMessage(failure))),
      (setup) => emit(MfaTotpSetupInitiatedState(setup: setup)),
    );
  }

  Future<void> _onVerifyTotpSetup(
    MfaVerifyTotpSetupEvent event,
    Emitter<MfaState> emit,
  ) async {
    emit(const MfaLoadingState());

    final result = await _mfaService.verifyTotpSetup(
      setupId: event.setupId,
      verificationCode: event.verificationCode,
    );

    result.fold(
      (failure) => emit(MfaErrorState(message: _mapFailureToMessage(failure))),
      (_) => emit(const MfaTotpSetupVerifiedState()),
    );
  }

  Future<void> _onCompleteTotpSetup(
    MfaCompleteTotpSetupEvent event,
    Emitter<MfaState> emit,
  ) async {
    emit(const MfaLoadingState());

    final result = await _mfaService.completeTotpSetup(
      setupId: event.setupId,
      userId: event.userId,
      accountName: event.accountName,
    );

    result.fold(
      (failure) => emit(MfaErrorState(message: _mapFailureToMessage(failure))),
      (totpConfig) => emit(MfaTotpSetupCompleteState(totpConfig: totpConfig)),
    );
  }

  Future<void> _onVerifyTotpCode(
    MfaVerifyTotpCodeEvent event,
    Emitter<MfaState> emit,
  ) async {
    emit(const MfaLoadingState());

    final result = await _mfaService.verifyTotpCode(
      userId: event.userId,
      code: event.code,
    );

    result.fold(
      (failure) => emit(MfaErrorState(message: _mapFailureToMessage(failure))),
      (_) => emit(const MfaTotpCodeVerifiedState()),
    );
  }

  Future<void> _onDisableTotp(
    MfaDisableTotpEvent event,
    Emitter<MfaState> emit,
  ) async {
    emit(const MfaLoadingState());

    final result = await _mfaService.disableTotpMfa(event.userId);

    result.fold(
      (failure) => emit(MfaErrorState(message: _mapFailureToMessage(failure))),
      (_) => emit(const MfaTotpDisabledState()),
    );
  }

  // Backup Code Handlers
  Future<void> _onGenerateBackupCodes(
    MfaGenerateBackupCodesEvent event,
    Emitter<MfaState> emit,
  ) async {
    emit(const MfaLoadingState());

    final result = await _mfaService.generateBackupCodes(event.userId);

    result.fold(
      (failure) => emit(MfaErrorState(message: _mapFailureToMessage(failure))),
      (codes) => emit(MfaBackupCodesGeneratedState(codes: codes)),
    );
  }

  Future<void> _onVerifyBackupCode(
    MfaVerifyBackupCodeEvent event,
    Emitter<MfaState> emit,
  ) async {
    emit(const MfaLoadingState());

    final result = await _mfaService.verifyBackupCode(
      userId: event.userId,
      code: event.code,
    );

    result.fold(
      (failure) => emit(MfaErrorState(message: _mapFailureToMessage(failure))),
      (_) => emit(const MfaBackupCodeVerifiedState()),
    );
  }

  Future<void> _onGetRemainingBackupCodes(
    MfaGetRemainingBackupCodesEvent event,
    Emitter<MfaState> emit,
  ) async {
    emit(const MfaLoadingState());

    final result = await _mfaService.getRemainingBackupCodes(event.userId);

    result.fold(
      (failure) => emit(MfaErrorState(message: _mapFailureToMessage(failure))),
      (codes) => emit(MfaRemainingBackupCodesLoadedState(codes: codes)),
    );
  }

  // MFA Verification Handlers
  Future<void> _onVerifyCode(
    MfaVerifyCodeEvent event,
    Emitter<MfaState> emit,
  ) async {
    emit(const MfaLoadingState());

    final result = await _mfaService.verifyMfa(
      userId: event.userId,
      code: event.code,
      preferredMfaType: event.preferredMfaType,
    );

    result.fold(
      (failure) => emit(MfaErrorState(message: _mapFailureToMessage(failure))),
      (_) => emit(const MfaCodeVerifiedState()),
    );
  }

  // Grace Period Handlers
  Future<void> _onCheckGracePeriod(
    MfaCheckGracePeriodEvent event,
    Emitter<MfaState> emit,
  ) async {
    emit(const MfaLoadingState());

    final graceResult = await _mfaService.isInGracePeriod(event.userId);
    final expiryResult = await _mfaService.getGracePeriodExpiry(event.userId);

    graceResult.fold(
      (failure) => emit(MfaErrorState(message: _mapFailureToMessage(failure))),
      (isInGrace) {
        expiryResult.fold(
          (failure) =>
              emit(MfaErrorState(message: _mapFailureToMessage(failure))),
          (expiry) => emit(
            MfaGracePeriodCheckedState(
              isInGracePeriod: isInGrace,
              gracePeriodExpiry: isInGrace ? expiry : null,
            ),
          ),
        );
      },
    );
  }

  Future<void> _onExtendGracePeriod(
    MfaExtendGracePeriodEvent event,
    Emitter<MfaState> emit,
  ) async {
    emit(const MfaLoadingState());

    final result = await _mfaService.extendGracePeriod(
      event.userId,
      event.duration,
    );

    result.fold(
      (failure) => emit(MfaErrorState(message: _mapFailureToMessage(failure))),
      (_) => emit(const MfaGracePeriodExtendedState()),
    );
  }

  Future<void> _onEndGracePeriod(
    MfaEndGracePeriodEvent event,
    Emitter<MfaState> emit,
  ) async {
    emit(const MfaLoadingState());

    final result = await _mfaService.endGracePeriod(event.userId);

    result.fold(
      (failure) => emit(MfaErrorState(message: _mapFailureToMessage(failure))),
      (_) => emit(const MfaGracePeriodEndedState()),
    );
  }

  // Security Handlers
  Future<void> _onLockAccount(
    MfaLockAccountEvent event,
    Emitter<MfaState> emit,
  ) async {
    emit(const MfaLoadingState());

    final result = await _mfaService.lockMfaAccount(event.userId, event.reason);

    result.fold(
      (failure) => emit(MfaErrorState(message: _mapFailureToMessage(failure))),
      (_) => emit(const MfaAccountLockedState()),
    );
  }

  Future<void> _onUnlockAccount(
    MfaUnlockAccountEvent event,
    Emitter<MfaState> emit,
  ) async {
    emit(const MfaLoadingState());

    final result = await _mfaService.unlockMfaAccount(event.userId);

    result.fold(
      (failure) => emit(MfaErrorState(message: _mapFailureToMessage(failure))),
      (_) => emit(const MfaAccountUnlockedState()),
    );
  }

  Future<void> _onSetPreferredMethod(
    MfaSetPreferredMethodEvent event,
    Emitter<MfaState> emit,
  ) async {
    emit(const MfaLoadingState());

    final result = await _mfaService.setPreferredMfaMethod(
      userId: event.userId,
      mfaType: event.mfaType,
    );

    result.fold(
      (failure) => emit(MfaErrorState(message: _mapFailureToMessage(failure))),
      (_) => emit(const MfaPreferredMethodSetState()),
    );
  }

  // Audit Handlers
  Future<void> _onLoadAuditLog(
    MfaLoadAuditLogEvent event,
    Emitter<MfaState> emit,
  ) async {
    emit(const MfaLoadingState());

    final result = await _mfaService.getMfaAuditLog(
      event.userId,
      startDate: event.startDate,
      endDate: event.endDate,
      limit: event.limit,
    );

    result.fold(
      (failure) => emit(MfaErrorState(message: _mapFailureToMessage(failure))),
      (auditLog) => emit(MfaAuditLogLoadedState(auditLog: auditLog)),
    );
  }

  // Helper method to map failures to user-friendly messages
  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return 'Server error occurred. Please try again.';
      case NetworkFailure:
        return 'Network error occurred. Please check your connection.';
      case ValidationFailure:
        return (failure as ValidationFailure).message;
      case AuthenticationFailure:
        return 'Authentication failed. Please log in again.';
      case AuthorizationFailure:
        return 'You are not authorized to perform this action.';
      case NotFoundFailure:
        return 'Resource not found.';
      case RateLimitFailure:
        return (failure as RateLimitFailure).message;
      default:
        return 'An unexpected error occurred.';
    }
  }
}
