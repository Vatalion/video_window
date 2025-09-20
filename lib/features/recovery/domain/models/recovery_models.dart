import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'recovery_models.g.dart';

@JsonSerializable()
class RecoveryRequest extends Equatable {
  final String email;
  final String? phoneNumber;
  final RecoveryMethod method;
  final DateTime requestedAt;

  const RecoveryRequest({
    required this.email,
    this.phoneNumber,
    required this.method,
    required this.requestedAt,
  });

  factory RecoveryRequest.fromJson(Map<String, dynamic> json) =>
      _$RecoveryRequestFromJson(json);
  Map<String, dynamic> toJson() => _$RecoveryRequestToJson(this);

  @override
  List<Object?> get props => [email, phoneNumber, method, requestedAt];
}

@JsonSerializable()
class RecoveryToken extends Equatable {
  final String id;
  final String tokenHash;
  final String email;
  final String? phoneNumber;
  final RecoveryMethod method;
  final DateTime expiresAt;
  final bool isUsed;
  final DateTime createdAt;

  const RecoveryToken({
    required this.id,
    required this.tokenHash,
    required this.email,
    this.phoneNumber,
    required this.method,
    required this.expiresAt,
    required this.isUsed,
    required this.createdAt,
  });

  factory RecoveryToken.fromJson(Map<String, dynamic> json) =>
      _$RecoveryTokenFromJson(json);
  Map<String, dynamic> toJson() => _$RecoveryTokenToJson(this);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => !isUsed && !isExpired;

  @override
  List<Object?> get props => [
        id,
        tokenHash,
        email,
        phoneNumber,
        method,
        expiresAt,
        isUsed,
        createdAt,
      ];
}

@JsonSerializable()
class RecoveryAttempt extends Equatable {
  final String id;
  final String email;
  final String? phoneNumber;
  final RecoveryMethod method;
  final String ipAddress;
  final String userAgent;
  final bool wasSuccessful;
  final DateTime attemptedAt;
  final String? failureReason;

  const RecoveryAttempt({
    required this.id,
    required this.email,
    this.phoneNumber,
    required this.method,
    required this.ipAddress,
    required this.userAgent,
    required this.wasSuccessful,
    required this.attemptedAt,
    this.failureReason,
  });

  factory RecoveryAttempt.fromJson(Map<String, dynamic> json) =>
      _$RecoveryAttemptFromJson(json);
  Map<String, dynamic> toJson() => _$RecoveryAttemptToJson(this);

  @override
  List<Object?> get props => [
        id,
        email,
        phoneNumber,
        method,
        ipAddress,
        userAgent,
        wasSuccessful,
        attemptedAt,
        failureReason,
      ];
}

@JsonSerializable()
class SecurityQuestion extends Equatable {
  final String id;
  final String question;
  final String answerHash;
  final bool isActive;
  final DateTime createdAt;

  const SecurityQuestion({
    required this.id,
    required this.question,
    required this.answerHash,
    required this.isActive,
    required this.createdAt,
  });

  factory SecurityQuestion.fromJson(Map<String, dynamic> json) =>
      _$SecurityQuestionFromJson(json);
  Map<String, dynamic> toJson() => _$SecurityQuestionToJson(this);

  @override
  List<Object?> get props => [id, question, answerHash, isActive, createdAt];
}

enum RecoveryMethod {
  email,
  phoneNumber,
  backupEmail,
  backupPhone,
  securityQuestion,
}

extension RecoveryMethodExtension on RecoveryMethod {
  String get displayName {
    switch (this) {
      case RecoveryMethod.email:
        return 'Email';
      case RecoveryMethod.phoneNumber:
        return 'Phone Number';
      case RecoveryMethod.backupEmail:
        return 'Backup Email';
      case RecoveryMethod.backupPhone:
        return 'Backup Phone';
      case RecoveryMethod.securityQuestion:
        return 'Security Question';
    }
  }

  String get description {
    switch (this) {
      case RecoveryMethod.email:
        return 'Send recovery link to your email address';
      case RecoveryMethod.phoneNumber:
        return 'Send verification code to your phone';
      case RecoveryMethod.backupEmail:
        return 'Send recovery link to your backup email';
      case RecoveryMethod.backupPhone:
        return 'Send verification code to your backup phone';
      case RecoveryMethod.securityQuestion:
        return 'Answer security questions to verify your identity';
    }
  }
}

enum RecoveryStatus {
  pending,
  sent,
  verified,
  completed,
  failed,
  expired,
}

enum AccountLockStatus {
  unlocked,
  lockedTemporary,
  lockedPermanent,
}