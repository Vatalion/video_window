import 'package:json_annotation/json_annotation.dart';

part 'account_protection.g.dart';

@JsonSerializable()
class AccountProtection {
  final String userId;
  final bool isLocked;
  final DateTime? lockedUntil;
  final int failedAttempts;
  final DateTime? lastFailedAttempt;
  final int maxFailedAttempts;
  final int lockoutDurationMinutes;
  final bool requiresPasswordReset;
  final List<FailedLoginAttempt> failedAttemptsHistory;
  final SecurityQuestion? securityQuestion;
  final DateTime? lastPasswordChange;
  final bool twoFactorEnabled;

  AccountProtection({
    required this.userId,
    this.isLocked = false,
    this.lockedUntil,
    this.failedAttempts = 0,
    this.lastFailedAttempt,
    this.maxFailedAttempts = 5,
    this.lockoutDurationMinutes = 30,
    this.requiresPasswordReset = false,
    this.failedAttemptsHistory = const [],
    this.securityQuestion,
    this.lastPasswordChange,
    this.twoFactorEnabled = false,
  });

  factory AccountProtection.fromJson(Map<String, dynamic> json) =>
      _$AccountProtectionFromJson(json);

  Map<String, dynamic> toJson() => _$AccountProtectionToJson(this);

  AccountProtection copyWith({
    String? userId,
    bool? isLocked,
    DateTime? lockedUntil,
    int? failedAttempts,
    DateTime? lastFailedAttempt,
    int? maxFailedAttempts,
    int? lockoutDurationMinutes,
    bool? requiresPasswordReset,
    List<FailedLoginAttempt>? failedAttemptsHistory,
    SecurityQuestion? securityQuestion,
    DateTime? lastPasswordChange,
    bool? twoFactorEnabled,
  }) {
    return AccountProtection(
      userId: userId ?? this.userId,
      isLocked: isLocked ?? this.isLocked,
      lockedUntil: lockedUntil ?? this.lockedUntil,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lastFailedAttempt: lastFailedAttempt ?? this.lastFailedAttempt,
      maxFailedAttempts: maxFailedAttempts ?? this.maxFailedAttempts,
      lockoutDurationMinutes: lockoutDurationMinutes ?? this.lockoutDurationMinutes,
      requiresPasswordReset: requiresPasswordReset ?? this.requiresPasswordReset,
      failedAttemptsHistory: failedAttemptsHistory ?? this.failedAttemptsHistory,
      securityQuestion: securityQuestion ?? this.securityQuestion,
      lastPasswordChange: lastPasswordChange ?? this.lastPasswordChange,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
    );
  }

  bool isAccountLocked() {
    if (!isLocked) return false;
    if (lockedUntil == null) return true;
    return DateTime.now().isBefore(lockedUntil!);
  }

  void recordFailedAttempt(String ipAddress, String userAgent) {
    final attempt = FailedLoginAttempt(
      timestamp: DateTime.now(),
      ipAddress: ipAddress,
      userAgent: userAgent,
    );

    failedAttemptsHistory.add(attempt);
    failedAttempts++;
    lastFailedAttempt = DateTime.now();

    if (failedAttempts >= maxFailedAttempts) {
      lockAccount();
    }
  }

  void lockAccount() {
    isLocked = true;
    lockedUntil = DateTime.now().add(Duration(minutes: lockoutDurationMinutes));
  }

  void unlockAccount() {
    isLocked = false;
    lockedUntil = null;
    failedAttempts = 0;
  }

  void resetFailedAttempts() {
    failedAttempts = 0;
    lastFailedAttempt = null;
  }
}

@JsonSerializable()
class FailedLoginAttempt {
  final DateTime timestamp;
  final String ipAddress;
  final String userAgent;

  FailedLoginAttempt({
    required this.timestamp,
    required this.ipAddress,
    required this.userAgent,
  });

  factory FailedLoginAttempt.fromJson(Map<String, dynamic> json) =>
      _$FailedLoginAttemptFromJson(json);

  Map<String, dynamic> toJson() => _$FailedLoginAttemptToJson(this);
}

@JsonSerializable()
class SecurityQuestion {
  final String question;
  final String encryptedAnswer;
  final DateTime? lastUpdated;

  SecurityQuestion({
    required this.question,
    required this.encryptedAnswer,
    this.lastUpdated,
  });

  factory SecurityQuestion.fromJson(Map<String, dynamic> json) =>
      _$SecurityQuestionFromJson(json);

  Map<String, dynamic> toJson() => _$SecurityQuestionToJson(this);
}