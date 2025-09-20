// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_protection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AccountProtection _$AccountProtectionFromJson(Map<String, dynamic> json) =>
    AccountProtection(
      userId: json['userId'] as String,
      isLocked: json['isLocked'] as bool? ?? false,
      lockedUntil: json['lockedUntil'] == null
          ? null
          : DateTime.parse(json['lockedUntil'] as String),
      failedAttempts: (json['failedAttempts'] as num?)?.toInt() ?? 0,
      lastFailedAttempt: json['lastFailedAttempt'] == null
          ? null
          : DateTime.parse(json['lastFailedAttempt'] as String),
      maxFailedAttempts: (json['maxFailedAttempts'] as num?)?.toInt() ?? 5,
      lockoutDurationMinutes:
          (json['lockoutDurationMinutes'] as num?)?.toInt() ?? 30,
      requiresPasswordReset: json['requiresPasswordReset'] as bool? ?? false,
      failedAttemptsHistory: (json['failedAttemptsHistory'] as List<dynamic>?)
              ?.map(
                  (e) => FailedLoginAttempt.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      securityQuestion: json['securityQuestion'] == null
          ? null
          : SecurityQuestion.fromJson(
              json['securityQuestion'] as Map<String, dynamic>),
      lastPasswordChange: json['lastPasswordChange'] == null
          ? null
          : DateTime.parse(json['lastPasswordChange'] as String),
      twoFactorEnabled: json['twoFactorEnabled'] as bool? ?? false,
    );

Map<String, dynamic> _$AccountProtectionToJson(AccountProtection instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'isLocked': instance.isLocked,
      'lockedUntil': instance.lockedUntil?.toIso8601String(),
      'failedAttempts': instance.failedAttempts,
      'lastFailedAttempt': instance.lastFailedAttempt?.toIso8601String(),
      'maxFailedAttempts': instance.maxFailedAttempts,
      'lockoutDurationMinutes': instance.lockoutDurationMinutes,
      'requiresPasswordReset': instance.requiresPasswordReset,
      'failedAttemptsHistory': instance.failedAttemptsHistory,
      'securityQuestion': instance.securityQuestion,
      'lastPasswordChange': instance.lastPasswordChange?.toIso8601String(),
      'twoFactorEnabled': instance.twoFactorEnabled,
    };

FailedLoginAttempt _$FailedLoginAttemptFromJson(Map<String, dynamic> json) =>
    FailedLoginAttempt(
      timestamp: DateTime.parse(json['timestamp'] as String),
      ipAddress: json['ipAddress'] as String,
      userAgent: json['userAgent'] as String,
    );

Map<String, dynamic> _$FailedLoginAttemptToJson(FailedLoginAttempt instance) =>
    <String, dynamic>{
      'timestamp': instance.timestamp.toIso8601String(),
      'ipAddress': instance.ipAddress,
      'userAgent': instance.userAgent,
    };

SecurityQuestion _$SecurityQuestionFromJson(Map<String, dynamic> json) =>
    SecurityQuestion(
      question: json['question'] as String,
      encryptedAnswer: json['encryptedAnswer'] as String,
      lastUpdated: json['lastUpdated'] == null
          ? null
          : DateTime.parse(json['lastUpdated'] as String),
    );

Map<String, dynamic> _$SecurityQuestionToJson(SecurityQuestion instance) =>
    <String, dynamic>{
      'question': instance.question,
      'encryptedAnswer': instance.encryptedAnswer,
      'lastUpdated': instance.lastUpdated?.toIso8601String(),
    };
