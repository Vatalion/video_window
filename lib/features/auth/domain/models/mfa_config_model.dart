import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'mfa_config_model.g.dart';

@JsonSerializable()
class MfaConfigModel extends Equatable {
  final String id;
  final String userId;
  final MfaType mfaType;
  final bool isEnabled;
  final bool isPrimary;
  final Map<String, dynamic> config;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MfaConfigModel({
    required this.id,
    required this.userId,
    required this.mfaType,
    this.isEnabled = false,
    this.isPrimary = false,
    this.config = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  factory MfaConfigModel.fromJson(Map<String, dynamic> json) =>
      _$MfaConfigModelFromJson(json);

  Map<String, dynamic> toJson() => _$MfaConfigModelToJson(this);

  MfaConfigModel copyWith({
    String? id,
    String? userId,
    MfaType? mfaType,
    bool? isEnabled,
    bool? isPrimary,
    Map<String, dynamic>? config,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MfaConfigModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      mfaType: mfaType ?? this.mfaType,
      isEnabled: isEnabled ?? this.isEnabled,
      isPrimary: isPrimary ?? this.isPrimary,
      config: config ?? this.config,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object> get props => [
    id,
    userId,
    mfaType,
    isEnabled,
    isPrimary,
    config,
    createdAt,
    updatedAt,
  ];
}

@JsonEnum()
enum MfaType { sms, totp, email, backupCode, securityQuestion }

@JsonEnum()
enum MfaStatus { disabled, enabled, pending, locked }

@JsonSerializable()
class MfaBackupCodeModel extends Equatable {
  final String id;
  final String code;
  final bool isUsed;
  final DateTime createdAt;
  final DateTime? usedAt;

  const MfaBackupCodeModel({
    required this.id,
    required this.code,
    this.isUsed = false,
    required this.createdAt,
    this.usedAt,
  });

  factory MfaBackupCodeModel.fromJson(Map<String, dynamic> json) =>
      _$MfaBackupCodeModelFromJson(json);

  Map<String, dynamic> toJson() => _$MfaBackupCodeModelToJson(this);

  MfaBackupCodeModel copyWith({
    String? id,
    String? code,
    bool? isUsed,
    DateTime? createdAt,
    DateTime? usedAt,
  }) {
    return MfaBackupCodeModel(
      id: id ?? this.id,
      code: code ?? this.code,
      isUsed: isUsed ?? this.isUsed,
      createdAt: createdAt ?? this.createdAt,
      usedAt: usedAt ?? this.usedAt,
    );
  }

  @override
  List<Object?> get props => [id, code, isUsed, createdAt, usedAt];
}

@JsonSerializable()
class MfaVerificationModel extends Equatable {
  final String id;
  final String userId;
  final MfaType mfaType;
  final String challenge;
  final DateTime expiresAt;
  final int attempts;
  final int maxAttempts;
  final bool isVerified;
  final DateTime createdAt;

  const MfaVerificationModel({
    required this.id,
    required this.userId,
    required this.mfaType,
    required this.challenge,
    required this.expiresAt,
    this.attempts = 0,
    this.maxAttempts = 3,
    this.isVerified = false,
    required this.createdAt,
  });

  factory MfaVerificationModel.fromJson(Map<String, dynamic> json) =>
      _$MfaVerificationModelFromJson(json);

  Map<String, dynamic> toJson() => _$MfaVerificationModelToJson(this);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isLocked => attempts >= maxAttempts;

  MfaVerificationModel copyWith({
    String? id,
    String? userId,
    MfaType? mfaType,
    String? challenge,
    DateTime? expiresAt,
    int? attempts,
    int? maxAttempts,
    bool? isVerified,
    DateTime? createdAt,
  }) {
    return MfaVerificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      mfaType: mfaType ?? this.mfaType,
      challenge: challenge ?? this.challenge,
      expiresAt: expiresAt ?? this.expiresAt,
      attempts: attempts ?? this.attempts,
      maxAttempts: maxAttempts ?? this.maxAttempts,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object> get props => [
    id,
    userId,
    mfaType,
    challenge,
    expiresAt,
    attempts,
    maxAttempts,
    isVerified,
    createdAt,
  ];
}

@JsonSerializable()
class MfaAuditModel extends Equatable {
  final String id;
  final String userId;
  final MfaAuditType auditType;
  final MfaType? mfaType;
  final bool wasSuccessful;
  final String? ipAddress;
  final String? userAgent;
  final String? deviceId;
  final String? failureReason;
  final DateTime createdAt;

  const MfaAuditModel({
    required this.id,
    required this.userId,
    required this.auditType,
    this.mfaType,
    this.wasSuccessful = true,
    this.ipAddress,
    this.userAgent,
    this.deviceId,
    this.failureReason,
    required this.createdAt,
  });

  factory MfaAuditModel.fromJson(Map<String, dynamic> json) =>
      _$MfaAuditModelFromJson(json);

  Map<String, dynamic> toJson() => _$MfaAuditModelToJson(this);

  @override
  List<Object?> get props => [
    id,
    userId,
    auditType,
    mfaType,
    wasSuccessful,
    ipAddress,
    userAgent,
    deviceId,
    failureReason,
    createdAt,
  ];
}

@JsonEnum()
enum MfaAuditType {
  setupInitiated,
  setupCompleted,
  setupFailed,
  verificationAttempt,
  verificationSuccess,
  verificationFailed,
  methodDisabled,
  backupCodeGenerated,
  backupCodeUsed,
  recoveryInitiated,
  recoverySuccess,
  recoveryFailed,
  suspiciousActivity,
  accountLocked,
  accountUnlocked,
}
