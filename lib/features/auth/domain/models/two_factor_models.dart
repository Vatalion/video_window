import 'package:equatable/equatable.dart';
import 'auth_enums.dart';

class TwoFactorConfig {
  final String id;
  final String userId;
  final bool isEnabled;
  final TwoFactorType primaryMethod;
  final List<TwoFactorType> enabledMethods;
  final DateTime? setupAt;
  final DateTime? lastUsedAt;
  final int failedAttempts;
  final bool isLocked;

  const TwoFactorConfig({
    required this.id,
    required this.userId,
    required this.isEnabled,
    required this.primaryMethod,
    required this.enabledMethods,
    this.setupAt,
    this.lastUsedAt,
    this.failedAttempts = 0,
    this.isLocked = false,
  });

  factory TwoFactorConfig.fromJson(Map<String, dynamic> json) {
    return TwoFactorConfig(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      isEnabled: json['is_enabled'] as bool,
      primaryMethod: TwoFactorType.values.firstWhere(
        (e) => e.name == json['primary_method'],
        orElse: () => TwoFactorType.sms,
      ),
      enabledMethods: (json['enabled_methods'] as List<dynamic>)
          .map(
            (e) => TwoFactorType.values.firstWhere(
              (t) => t.name == e,
              orElse: () => TwoFactorType.sms,
            ),
          )
          .toList(),
      setupAt: json['setup_at'] != null
          ? DateTime.parse(json['setup_at'] as String)
          : null,
      lastUsedAt: json['last_used_at'] != null
          ? DateTime.parse(json['last_used_at'] as String)
          : null,
      failedAttempts: json['failed_attempts'] as int? ?? 0,
      isLocked: json['is_locked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'is_enabled': isEnabled,
      'primary_method': primaryMethod.name,
      'enabled_methods': enabledMethods.map((e) => e.name).toList(),
      'setup_at': setupAt?.toIso8601String(),
      'last_used_at': lastUsedAt?.toIso8601String(),
      'failed_attempts': failedAttempts,
      'is_locked': isLocked,
    };
  }
}

class TwoFactorVerification {
  final String id;
  final String userId;
  final TwoFactorType method;
  final String code;
  final DateTime expiresAt;
  final bool isUsed;
  final DateTime createdAt;

  const TwoFactorVerification({
    required this.id,
    required this.userId,
    required this.method,
    required this.code,
    required this.expiresAt,
    required this.isUsed,
    required this.createdAt,
  });

  factory TwoFactorVerification.fromJson(Map<String, dynamic> json) {
    return TwoFactorVerification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      method: TwoFactorType.values.firstWhere(
        (e) => e.name == json['method'],
        orElse: () => TwoFactorType.sms,
      ),
      code: json['code'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      isUsed: json['is_used'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'method': method.name,
      'code': code,
      'expires_at': expiresAt.toIso8601String(),
      'is_used': isUsed,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

enum TwoFactorAuditAction {
  enabled,
  disabled,
  verificationSuccess,
  verificationFailure,
  methodChanged,
  backupGenerated,
  lockout,
}

class TwoFactorAudit {
  final String id;
  final String userId;
  final TwoFactorAuditAction action;
  final String? details;
  final String ipAddress;
  final String? userAgent;
  final DateTime timestamp;
  final bool wasSuccessful;

  const TwoFactorAudit({
    required this.id,
    required this.userId,
    required this.action,
    this.details,
    required this.ipAddress,
    this.userAgent,
    required this.timestamp,
    required this.wasSuccessful,
  });

  factory TwoFactorAudit.fromJson(Map<String, dynamic> json) {
    return TwoFactorAudit(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      action: TwoFactorAuditAction.values.firstWhere(
        (e) => e.name == json['action'],
        orElse: () => TwoFactorAuditAction.verificationSuccess,
      ),
      details: json['details'] as String?,
      ipAddress: json['ip_address'] as String,
      userAgent: json['user_agent'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      wasSuccessful: json['was_successful'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'action': action.name,
      'details': details,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'timestamp': timestamp.toIso8601String(),
      'was_successful': wasSuccessful,
    };
  }
}
