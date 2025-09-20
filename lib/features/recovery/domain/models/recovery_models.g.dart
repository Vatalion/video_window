// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recovery_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecoveryRequest _$RecoveryRequestFromJson(Map<String, dynamic> json) =>
    RecoveryRequest(
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      method: $enumDecode(_$RecoveryMethodEnumMap, json['method']),
      requestedAt: DateTime.parse(json['requestedAt'] as String),
    );

Map<String, dynamic> _$RecoveryRequestToJson(RecoveryRequest instance) =>
    <String, dynamic>{
      'email': instance.email,
      'phoneNumber': instance.phoneNumber,
      'method': _$RecoveryMethodEnumMap[instance.method]!,
      'requestedAt': instance.requestedAt.toIso8601String(),
    };

const _$RecoveryMethodEnumMap = {
  RecoveryMethod.email: 'email',
  RecoveryMethod.phoneNumber: 'phoneNumber',
  RecoveryMethod.backupEmail: 'backupEmail',
  RecoveryMethod.backupPhone: 'backupPhone',
  RecoveryMethod.securityQuestion: 'securityQuestion',
};

RecoveryToken _$RecoveryTokenFromJson(Map<String, dynamic> json) =>
    RecoveryToken(
      id: json['id'] as String,
      tokenHash: json['tokenHash'] as String,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      method: $enumDecode(_$RecoveryMethodEnumMap, json['method']),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      isUsed: json['isUsed'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$RecoveryTokenToJson(RecoveryToken instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tokenHash': instance.tokenHash,
      'email': instance.email,
      'phoneNumber': instance.phoneNumber,
      'method': _$RecoveryMethodEnumMap[instance.method]!,
      'expiresAt': instance.expiresAt.toIso8601String(),
      'isUsed': instance.isUsed,
      'createdAt': instance.createdAt.toIso8601String(),
    };

RecoveryAttempt _$RecoveryAttemptFromJson(Map<String, dynamic> json) =>
    RecoveryAttempt(
      id: json['id'] as String,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      method: $enumDecode(_$RecoveryMethodEnumMap, json['method']),
      ipAddress: json['ipAddress'] as String,
      userAgent: json['userAgent'] as String,
      wasSuccessful: json['wasSuccessful'] as bool,
      attemptedAt: DateTime.parse(json['attemptedAt'] as String),
      failureReason: json['failureReason'] as String?,
    );

Map<String, dynamic> _$RecoveryAttemptToJson(RecoveryAttempt instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'phoneNumber': instance.phoneNumber,
      'method': _$RecoveryMethodEnumMap[instance.method]!,
      'ipAddress': instance.ipAddress,
      'userAgent': instance.userAgent,
      'wasSuccessful': instance.wasSuccessful,
      'attemptedAt': instance.attemptedAt.toIso8601String(),
      'failureReason': instance.failureReason,
    };

SecurityQuestion _$SecurityQuestionFromJson(Map<String, dynamic> json) =>
    SecurityQuestion(
      id: json['id'] as String,
      question: json['question'] as String,
      answerHash: json['answerHash'] as String,
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$SecurityQuestionToJson(SecurityQuestion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'question': instance.question,
      'answerHash': instance.answerHash,
      'isActive': instance.isActive,
      'createdAt': instance.createdAt.toIso8601String(),
    };
