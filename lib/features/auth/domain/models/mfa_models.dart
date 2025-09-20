import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

enum MfaMethod { none, sms, totp, backupCode }

enum MfaStatus { disabled, enabled, pending, locked }

class TwoFactorAuthConfig extends Equatable {
  final String id;
  final String userId;
  final MfaMethod method;
  final MfaStatus status;
  final String? phoneNumber;
  final String? totpSecret;
  final bool isBackupCodeEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastUsedAt;
  final int failedAttempts;
  final DateTime? lockedUntil;

  const TwoFactorAuthConfig({
    required this.id,
    required this.userId,
    required this.method,
    required this.status,
    this.phoneNumber,
    this.totpSecret,
    required this.isBackupCodeEnabled,
    required this.createdAt,
    required this.updatedAt,
    this.lastUsedAt,
    required this.failedAttempts,
    this.lockedUntil,
  });

  factory TwoFactorAuthConfig.fromJson(Map<String, dynamic> json) {
    return TwoFactorAuthConfig(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      method: MfaMethod.values.firstWhere(
        (e) => e.name == json['method'],
        orElse: () => MfaMethod.none,
      ),
      status: MfaStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MfaStatus.disabled,
      ),
      phoneNumber: json['phone_number'] as String?,
      totpSecret: json['totp_secret'] as String?,
      isBackupCodeEnabled: json['is_backup_code_enabled'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      lastUsedAt: json['last_used_at'] != null
          ? DateTime.parse(json['last_used_at'] as String)
          : null,
      failedAttempts: json['failed_attempts'] as int,
      lockedUntil: json['locked_until'] != null
          ? DateTime.parse(json['locked_until'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'method': method.name,
      'status': status.name,
      'phone_number': phoneNumber,
      'totp_secret': totpSecret,
      'is_backup_code_enabled': isBackupCodeEnabled,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_used_at': lastUsedAt?.toIso8601String(),
      'failed_attempts': failedAttempts,
      'locked_until': lockedUntil?.toIso8601String(),
    };
  }

  TwoFactorAuthConfig copyWith({
    String? id,
    String? userId,
    MfaMethod? method,
    MfaStatus? status,
    String? phoneNumber,
    String? totpSecret,
    bool? isBackupCodeEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastUsedAt,
    int? failedAttempts,
    DateTime? lockedUntil,
  }) {
    return TwoFactorAuthConfig(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      method: method ?? this.method,
      status: status ?? this.status,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      totpSecret: totpSecret ?? this.totpSecret,
      isBackupCodeEnabled: isBackupCodeEnabled ?? this.isBackupCodeEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockedUntil: lockedUntil ?? this.lockedUntil,
    );
  }

  bool get isLocked =>
      lockedUntil != null && lockedUntil!.isAfter(DateTime.now());
  bool get isEnabled => status == MfaStatus.enabled;
  bool get canAttempt => !isLocked && failedAttempts < 10;

  @override
  List<Object> get props => [
    id,
    userId,
    method,
    status,
    phoneNumber ?? '',
    totpSecret ?? '',
    isBackupCodeEnabled,
    createdAt,
    updatedAt,
    failedAttempts,
  ];

  factory TwoFactorAuthConfig.empty() {
    return TwoFactorAuthConfig(
      id: '',
      userId: '',
      method: MfaMethod.none,
      status: MfaStatus.disabled,
      isBackupCodeEnabled: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      failedAttempts: 0,
    );
  }
}

class BackupCode extends Equatable {
  final String id;
  final String userId;
  final String code;
  final bool isUsed;
  final DateTime createdAt;
  final DateTime? usedAt;

  const BackupCode({
    required this.id,
    required this.userId,
    required this.code,
    required this.isUsed,
    required this.createdAt,
    this.usedAt,
  });

  factory BackupCode.fromJson(Map<String, dynamic> json) {
    return BackupCode(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      code: json['code'] as String,
      isUsed: json['is_used'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      usedAt: json['used_at'] != null
          ? DateTime.parse(json['used_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'code': code,
      'is_used': isUsed,
      'created_at': createdAt.toIso8601String(),
      'used_at': usedAt?.toIso8601String(),
    };
  }

  BackupCode copyWith({
    String? id,
    String? userId,
    String? code,
    bool? isUsed,
    DateTime? createdAt,
    DateTime? usedAt,
  }) {
    return BackupCode(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      code: code ?? this.code,
      isUsed: isUsed ?? this.isUsed,
      createdAt: createdAt ?? this.createdAt,
      usedAt: usedAt ?? this.usedAt,
    );
  }

  @override
  List<Object> get props => [id, userId, code, isUsed, createdAt];
}

class MfaVerificationResult extends Equatable {
  final bool success;
  final String? message;
  final MfaMethod method;
  final DateTime verifiedAt;
  final String? deviceId;
  final bool requiresBackupCodeSetup;

  const MfaVerificationResult({
    required this.success,
    this.message,
    required this.method,
    required this.verifiedAt,
    this.deviceId,
    required this.requiresBackupCodeSetup,
  });

  factory MfaVerificationResult.success({
    required MfaMethod method,
    String? deviceId,
    bool requiresBackupCodeSetup = false,
  }) {
    return MfaVerificationResult(
      success: true,
      method: method,
      verifiedAt: DateTime.now(),
      deviceId: deviceId,
      requiresBackupCodeSetup: requiresBackupCodeSetup,
    );
  }

  factory MfaVerificationResult.failure({
    required String message,
    required MfaMethod method,
  }) {
    return MfaVerificationResult(
      success: false,
      message: message,
      method: method,
      verifiedAt: DateTime.now(),
      requiresBackupCodeSetup: false,
    );
  }

  @override
  List<Object> get props => [
    success,
    method,
    verifiedAt,
    requiresBackupCodeSetup,
  ];
}

class TotpSetupData extends Equatable {
  final String secret;
  final String qrCodeUrl;
  final String manualEntryKey;
  final String backupCodes;

  const TotpSetupData({
    required this.secret,
    required this.qrCodeUrl,
    required this.manualEntryKey,
    required this.backupCodes,
  });

  @override
  List<Object> get props => [secret, qrCodeUrl, manualEntryKey, backupCodes];
}

class MfaGracePeriod extends Equatable {
  final String userId;
  final String deviceId;
  final DateTime startedAt;
  final DateTime expiresAt;
  final bool isActive;

  const MfaGracePeriod({
    required this.userId,
    required this.deviceId,
    required this.startedAt,
    required this.expiresAt,
    required this.isActive,
  });

  factory MfaGracePeriod.fromJson(Map<String, dynamic> json) {
    return MfaGracePeriod(
      userId: json['user_id'] as String,
      deviceId: json['device_id'] as String,
      startedAt: DateTime.parse(json['started_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      isActive: json['is_active'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'device_id': deviceId,
      'started_at': startedAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'is_active': isActive,
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => isActive && !isExpired;

  @override
  List<Object> get props => [userId, deviceId, startedAt, expiresAt, isActive];
}
