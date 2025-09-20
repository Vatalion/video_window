import 'package:equatable/equatable.dart';

enum TwoFactorMethod { none, sms, totp }

enum TwoFactorStatus { disabled, enabled, pending, locked }

class TwoFactorConfig extends Equatable {
  final String id;
  final String userId;
  final TwoFactorMethod method;
  final TwoFactorStatus status;
  final String? phoneNumber;
  final String? totpSecret;
  final DateTime? enabledAt;
  final DateTime? lastVerifiedAt;
  final int failedAttempts;
  final bool isGracePeriodActive;
  final DateTime? gracePeriodEndsAt;
  final List<String> backupCodes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TwoFactorConfig({
    required this.id,
    required this.userId,
    required this.method,
    required this.status,
    this.phoneNumber,
    this.totpSecret,
    this.enabledAt,
    this.lastVerifiedAt,
    this.failedAttempts = 0,
    this.isGracePeriodActive = false,
    this.gracePeriodEndsAt,
    this.backupCodes = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  TwoFactorConfig copyWith({
    String? id,
    String? userId,
    TwoFactorMethod? method,
    TwoFactorStatus? status,
    String? phoneNumber,
    String? totpSecret,
    DateTime? enabledAt,
    DateTime? lastVerifiedAt,
    int? failedAttempts,
    bool? isGracePeriodActive,
    DateTime? gracePeriodEndsAt,
    List<String>? backupCodes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TwoFactorConfig(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      method: method ?? this.method,
      status: status ?? this.status,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      totpSecret: totpSecret ?? this.totpSecret,
      enabledAt: enabledAt ?? this.enabledAt,
      lastVerifiedAt: lastVerifiedAt ?? this.lastVerifiedAt,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      isGracePeriodActive: isGracePeriodActive ?? this.isGracePeriodActive,
      gracePeriodEndsAt: gracePeriodEndsAt ?? this.gracePeriodEndsAt,
      backupCodes: backupCodes ?? this.backupCodes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    method,
    status,
    phoneNumber,
    totpSecret,
    enabledAt,
    lastVerifiedAt,
    failedAttempts,
    isGracePeriodActive,
    gracePeriodEndsAt,
    backupCodes,
    createdAt,
    updatedAt,
  ];

  bool get isEnabled => status == TwoFactorStatus.enabled;
  bool get isDisabled => status == TwoFactorStatus.disabled;
  bool get isPending => status == TwoFactorStatus.pending;
  bool get isLocked => status == TwoFactorStatus.locked;
  bool get canAttempt => failedAttempts < 5 && !isLocked;
  bool get isGracePeriodExpired =>
      isGracePeriodActive &&
      gracePeriodEndsAt != null &&
      gracePeriodEndsAt!.isBefore(DateTime.now());

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'method': method.name,
      'status': status.name,
      'phoneNumber': phoneNumber,
      'totpSecret': totpSecret,
      'enabledAt': enabledAt?.toIso8601String(),
      'lastVerifiedAt': lastVerifiedAt?.toIso8601String(),
      'failedAttempts': failedAttempts,
      'isGracePeriodActive': isGracePeriodActive,
      'gracePeriodEndsAt': gracePeriodEndsAt?.toIso8601String(),
      'backupCodes': backupCodes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory TwoFactorConfig.fromJson(Map<String, dynamic> json) {
    return TwoFactorConfig(
      id: json['id'] as String,
      userId: json['userId'] as String,
      method: TwoFactorMethod.values.byName(json['method'] as String),
      status: TwoFactorStatus.values.byName(json['status'] as String),
      phoneNumber: json['phoneNumber'] as String?,
      totpSecret: json['totpSecret'] as String?,
      enabledAt: json['enabledAt'] != null
          ? DateTime.parse(json['enabledAt'] as String)
          : null,
      lastVerifiedAt: json['lastVerifiedAt'] != null
          ? DateTime.parse(json['lastVerifiedAt'] as String)
          : null,
      failedAttempts: json['failedAttempts'] as int? ?? 0,
      isGracePeriodActive: json['isGracePeriodActive'] as bool? ?? false,
      gracePeriodEndsAt: json['gracePeriodEndsAt'] != null
          ? DateTime.parse(json['gracePeriodEndsAt'] as String)
          : null,
      backupCodes: List<String>.from(json['backupCodes'] as List? ?? []),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
