part of 'mfa_bloc.dart';

abstract class MfaState extends Equatable {
  const MfaState();

  @override
  List<Object> get props => [];
}

class MfaInitialState extends MfaState {
  const MfaInitialState();
}

class MfaLoadingState extends MfaState {
  const MfaLoadingState();
}

class MfaErrorState extends MfaState {
  final String message;

  const MfaErrorState({required this.message});

  @override
  List<Object> get props => [message];
}

// MFA Configuration States
class MfaConfigLoadedState extends MfaState {
  final MfaConfigModel config;

  const MfaConfigLoadedState({required this.config});

  @override
  List<Object> get props => [config];
}

class MfaConfigsLoadedState extends MfaState {
  final List<MfaConfigModel> configs;

  const MfaConfigsLoadedState({required this.configs});

  @override
  List<Object> get props => [configs];
}

class MfaSecurityStatusLoadedState extends MfaState {
  final Map<String, dynamic> securityStatus;

  const MfaSecurityStatusLoadedState({required this.securityStatus});

  @override
  List<Object> get props => [securityStatus];
}

class MfaSettingsLoadedState extends MfaState {
  final Map<String, dynamic> settings;

  const MfaSettingsLoadedState({required this.settings});

  @override
  List<Object> get props => [settings];
}

class MfaSettingsUpdatedState extends MfaState {
  const MfaSettingsUpdatedState();
}

// SMS MFA States
class MfaSmsCodeSentState extends MfaState {
  final SmsVerificationModel verification;

  const MfaSmsCodeSentState({required this.verification});

  @override
  List<Object> get props => [verification];
}

class MfaSmsCodeVerifiedState extends MfaState {
  const MfaSmsCodeVerifiedState();
}

class MfaSmsSetupCompleteState extends MfaState {
  final SmsMfaConfigModel smsConfig;

  const MfaSmsSetupCompleteState({required this.smsConfig});

  @override
  List<Object> get props => [smsConfig];
}

class MfaSmsDisabledState extends MfaState {
  const MfaSmsDisabledState();
}

// TOTP MFA States
class MfaTotpSetupInitiatedState extends MfaState {
  final TotpSetupModel setup;

  const MfaTotpSetupInitiatedState({required this.setup});

  @override
  List<Object> get props => [setup];
}

class MfaTotpSetupVerifiedState extends MfaState {
  const MfaTotpSetupVerifiedState();
}

class MfaTotpSetupCompleteState extends MfaState {
  final TotpConfigModel totpConfig;

  const MfaTotpSetupCompleteState({required this.totpConfig});

  @override
  List<Object> get props => [totpConfig];
}

class MfaTotpCodeVerifiedState extends MfaState {
  const MfaTotpCodeVerifiedState();
}

class MfaTotpDisabledState extends MfaState {
  const MfaTotpDisabledState();
}

// Backup Code States
class MfaBackupCodesGeneratedState extends MfaState {
  final List<String> codes;

  const MfaBackupCodesGeneratedState({required this.codes});

  @override
  List<Object> get props => [codes];
}

class MfaBackupCodeVerifiedState extends MfaState {
  const MfaBackupCodeVerifiedState();
}

class MfaRemainingBackupCodesLoadedState extends MfaState {
  final List<String> codes;

  const MfaRemainingBackupCodesLoadedState({required this.codes});

  @override
  List<Object> get props => [codes];
}

// MFA Verification States
class MfaCodeVerifiedState extends MfaState {
  const MfaCodeVerifiedState();
}

// Grace Period States
class MfaGracePeriodCheckedState extends MfaState {
  final bool isInGracePeriod;
  final DateTime? gracePeriodExpiry;

  const MfaGracePeriodCheckedState({
    required this.isInGracePeriod,
    this.gracePeriodExpiry,
  });

  @override
  List<Object> get props => [isInGracePeriod, gracePeriodExpiry ?? ''];
}

class MfaGracePeriodExtendedState extends MfaState {
  const MfaGracePeriodExtendedState();
}

class MfaGracePeriodEndedState extends MfaState {
  const MfaGracePeriodEndedState();
}

// Security States
class MfaAccountLockedState extends MfaState {
  const MfaAccountLockedState();
}

class MfaAccountUnlockedState extends MfaState {
  const MfaAccountUnlockedState();
}

class MfaPreferredMethodSetState extends MfaState {
  const MfaPreferredMethodSetState();
}

// Audit States
class MfaAuditLogLoadedState extends MfaState {
  final List<MfaAuditModel> auditLog;

  const MfaAuditLogLoadedState({required this.auditLog});

  @override
  List<Object> get props => [auditLog];
}
