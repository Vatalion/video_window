part of 'mfa_bloc.dart';

abstract class MfaEvent extends Equatable {
  const MfaEvent();

  @override
  List<Object> get props => [];
}

// MFA Configuration Events
class MfaLoadConfigEvent extends MfaEvent {
  final String userId;

  const MfaLoadConfigEvent({required this.userId});

  @override
  List<Object> get props => [userId];
}

class MfaGetSecurityStatusEvent extends MfaEvent {
  final String userId;

  const MfaGetSecurityStatusEvent({required this.userId});

  @override
  List<Object> get props => [userId];
}

class MfaLoadSettingsEvent extends MfaEvent {
  final String userId;

  const MfaLoadSettingsEvent({required this.userId});

  @override
  List<Object> get props => [userId];
}

class MfaUpdateSettingsEvent extends MfaEvent {
  final String userId;
  final Map<String, dynamic> settings;

  const MfaUpdateSettingsEvent({required this.userId, required this.settings});

  @override
  List<Object> get props => [userId, settings];
}

// SMS MFA Events
class MfaSendSmsCodeEvent extends MfaEvent {
  final String userId;
  final String phoneNumber;
  final String countryCode;

  const MfaSendSmsCodeEvent({
    required this.userId,
    required this.phoneNumber,
    required this.countryCode,
  });

  @override
  List<Object> get props => [userId, phoneNumber, countryCode];
}

class MfaVerifySmsCodeEvent extends MfaEvent {
  final String verificationId;
  final String code;

  const MfaVerifySmsCodeEvent({
    required this.verificationId,
    required this.code,
  });

  @override
  List<Object> get props => [verificationId, code];
}

class MfaSetupSmsEvent extends MfaEvent {
  final String userId;
  final String phoneNumber;
  final String countryCode;
  final String verificationId;
  final String verificationCode;

  const MfaSetupSmsEvent({
    required this.userId,
    required this.phoneNumber,
    required this.countryCode,
    required this.verificationId,
    required this.verificationCode,
  });

  @override
  List<Object> get props => [
    userId,
    phoneNumber,
    countryCode,
    verificationId,
    verificationCode,
  ];
}

class MfaDisableSmsEvent extends MfaEvent {
  final String userId;

  const MfaDisableSmsEvent({required this.userId});

  @override
  List<Object> get props => [userId];
}

// TOTP MFA Events
class MfaInitiateTotpSetupEvent extends MfaEvent {
  final String userId;

  const MfaInitiateTotpSetupEvent({required this.userId});

  @override
  List<Object> get props => [userId];
}

class MfaVerifyTotpSetupEvent extends MfaEvent {
  final String setupId;
  final String verificationCode;

  const MfaVerifyTotpSetupEvent({
    required this.setupId,
    required this.verificationCode,
  });

  @override
  List<Object> get props => [setupId, verificationCode];
}

class MfaCompleteTotpSetupEvent extends MfaEvent {
  final String setupId;
  final String userId;
  final String accountName;

  const MfaCompleteTotpSetupEvent({
    required this.setupId,
    required this.userId,
    required this.accountName,
  });

  @override
  List<Object> get props => [setupId, userId, accountName];
}

class MfaVerifyTotpCodeEvent extends MfaEvent {
  final String userId;
  final String code;

  const MfaVerifyTotpCodeEvent({required this.userId, required this.code});

  @override
  List<Object> get props => [userId, code];
}

class MfaDisableTotpEvent extends MfaEvent {
  final String userId;

  const MfaDisableTotpEvent({required this.userId});

  @override
  List<Object> get props => [userId];
}

// Backup Code Events
class MfaGenerateBackupCodesEvent extends MfaEvent {
  final String userId;

  const MfaGenerateBackupCodesEvent({required this.userId});

  @override
  List<Object> get props => [userId];
}

class MfaVerifyBackupCodeEvent extends MfaEvent {
  final String userId;
  final String code;

  const MfaVerifyBackupCodeEvent({required this.userId, required this.code});

  @override
  List<Object> get props => [userId, code];
}

class MfaGetRemainingBackupCodesEvent extends MfaEvent {
  final String userId;

  const MfaGetRemainingBackupCodesEvent({required this.userId});

  @override
  List<Object> get props => [userId];
}

// MFA Verification Events
class MfaVerifyCodeEvent extends MfaEvent {
  final String userId;
  final String code;
  final MfaType? preferredMfaType;

  const MfaVerifyCodeEvent({
    required this.userId,
    required this.code,
    this.preferredMfaType,
  });

  @override
  List<Object> get props => [userId, code];
}

// Grace Period Events
class MfaCheckGracePeriodEvent extends MfaEvent {
  final String userId;

  const MfaCheckGracePeriodEvent({required this.userId});

  @override
  List<Object> get props => [userId];
}

class MfaExtendGracePeriodEvent extends MfaEvent {
  final String userId;
  final Duration duration;

  const MfaExtendGracePeriodEvent({
    required this.userId,
    required this.duration,
  });

  @override
  List<Object> get props => [userId, duration];
}

class MfaEndGracePeriodEvent extends MfaEvent {
  final String userId;

  const MfaEndGracePeriodEvent({required this.userId});

  @override
  List<Object> get props => [userId];
}

// Security Events
class MfaLockAccountEvent extends MfaEvent {
  final String userId;
  final String reason;

  const MfaLockAccountEvent({required this.userId, required this.reason});

  @override
  List<Object> get props => [userId, reason];
}

class MfaUnlockAccountEvent extends MfaEvent {
  final String userId;

  const MfaUnlockAccountEvent({required this.userId});

  @override
  List<Object> get props => [userId];
}

class MfaSetPreferredMethodEvent extends MfaEvent {
  final String userId;
  final MfaType mfaType;

  const MfaSetPreferredMethodEvent({
    required this.userId,
    required this.mfaType,
  });

  @override
  List<Object> get props => [userId, mfaType];
}

// Audit Events
class MfaLoadAuditLogEvent extends MfaEvent {
  final String userId;
  final DateTime? startDate;
  final DateTime? endDate;
  final int limit;

  const MfaLoadAuditLogEvent({
    required this.userId,
    this.startDate,
    this.endDate,
    this.limit = 100,
  });

  @override
  List<Object> get props => [userId, startDate, endDate, limit];
}
