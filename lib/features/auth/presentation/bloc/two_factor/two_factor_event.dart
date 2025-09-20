part of 'two_factor_bloc.dart';

abstract class TwoFactorEvent extends Equatable {
  const TwoFactorEvent();

  @override
  List<Object> get props => [];
}

class TwoFactorConfigRequested extends TwoFactorEvent {
  final String userId;

  const TwoFactorConfigRequested(this.userId);

  @override
  List<Object> get props => [userId];
}

class TwoFactorSmsSetupInitiated extends TwoFactorEvent {
  final String userId;
  final String phoneNumber;

  const TwoFactorSmsSetupInitiated({
    required this.userId,
    required this.phoneNumber,
  });

  @override
  List<Object> get props => [userId, phoneNumber];
}

class TwoFactorTotpSetupInitiated extends TwoFactorEvent {
  final String userId;
  final String totpSecret;

  const TwoFactorTotpSetupInitiated({
    required this.userId,
    required this.totpSecret,
  });

  @override
  List<Object> get props => [userId, totpSecret];
}

class TwoFactorSmsCodeRequested extends TwoFactorEvent {
  final String userId;
  final String sessionId;

  const TwoFactorSmsCodeRequested({
    required this.userId,
    required this.sessionId,
  });

  @override
  List<Object> get props => [userId, sessionId];
}

class TwoFactorTotpCodeRequested extends TwoFactorEvent {
  final String userId;
  final String sessionId;

  const TwoFactorTotpCodeRequested({
    required this.userId,
    required this.sessionId,
  });

  @override
  List<Object> get props => [userId, sessionId];
}

class TwoFactorSmsCodeVerified extends TwoFactorEvent {
  final String userId;
  final String sessionId;
  final String code;

  const TwoFactorSmsCodeVerified({
    required this.userId,
    required this.sessionId,
    required this.code,
  });

  @override
  List<Object> get props => [userId, sessionId, code];
}

class TwoFactorTotpCodeVerified extends TwoFactorEvent {
  final String userId;
  final String sessionId;
  final String code;

  const TwoFactorTotpCodeVerified({
    required this.userId,
    required this.sessionId,
    required this.code,
  });

  @override
  List<Object> get props => [userId, sessionId, code];
}

class TwoFactorBackupCodeVerified extends TwoFactorEvent {
  final String userId;
  final String sessionId;
  final String code;

  const TwoFactorBackupCodeVerified({
    required this.userId,
    required this.sessionId,
    required this.code,
  });

  @override
  List<Object> get props => [userId, sessionId, code];
}

class TwoFactorDisabled extends TwoFactorEvent {
  final String userId;

  const TwoFactorDisabled(this.userId);

  @override
  List<Object> get props => [userId];
}

class TwoFactorBackupCodesGenerated extends TwoFactorEvent {
  final String userId;

  const TwoFactorBackupCodesGenerated(this.userId);

  @override
  List<Object> get props => [userId];
}

class TwoFactorBackupCodesRequested extends TwoFactorEvent {
  final String userId;

  const TwoFactorBackupCodesRequested(this.userId);

  @override
  List<Object> get props => [userId];
}

class TwoFactorGracePeriodStarted extends TwoFactorEvent {
  final String userId;
  final String deviceId;
  final Duration duration;

  const TwoFactorGracePeriodStarted({
    required this.userId,
    required this.deviceId,
    required this.duration,
  });

  @override
  List<Object> get props => [userId, deviceId, duration];
}

class TwoFactorGracePeriodChecked extends TwoFactorEvent {
  final String userId;

  const TwoFactorGracePeriodChecked(this.userId);

  @override
  List<Object> get props => [userId];
}

class TwoFactorAccountLocked extends TwoFactorEvent {
  final String userId;
  final String reason;

  const TwoFactorAccountLocked({required this.userId, required this.reason});

  @override
  List<Object> get props => [userId, reason];
}

class TwoFactorAccountUnlocked extends TwoFactorEvent {
  final String userId;

  const TwoFactorAccountUnlocked(this.userId);

  @override
  List<Object> get props => [userId];
}
