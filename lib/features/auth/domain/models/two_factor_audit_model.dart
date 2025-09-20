import 'package:equatable/equatable.dart';

enum TwoFactorAuditAction {
  setup,
  verify,
  disable,
  regenerateBackupCodes,
  methodChange,
  failedAttempt,
  recovery,
  gracePeriodStart,
  gracePeriodEnd,
}

enum TwoFactorAuditStatus { success, failed, blocked, expired }

class TwoFactorAudit extends Equatable {
  final String id;
  final String userId;
  final TwoFactorAuditAction action;
  final TwoFactorAuditStatus status;
  final String? details;
  final String? deviceId;
  final String? ipAddress;
  final String? userAgent;
  final String? errorCode;
  final DateTime timestamp;

  const TwoFactorAudit({
    required this.id,
    required this.userId,
    required this.action,
    required this.status,
    this.details,
    this.deviceId,
    this.ipAddress,
    this.userAgent,
    this.errorCode,
    required this.timestamp,
  });

  TwoFactorAudit copyWith({
    String? id,
    String? userId,
    TwoFactorAuditAction? action,
    TwoFactorAuditStatus? status,
    String? details,
    String? deviceId,
    String? ipAddress,
    String? userAgent,
    String? errorCode,
    DateTime? timestamp,
  }) {
    return TwoFactorAudit(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      action: action ?? this.action,
      status: status ?? this.status,
      details: details ?? this.details,
      deviceId: deviceId ?? this.deviceId,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      errorCode: errorCode ?? this.errorCode,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    action,
    status,
    details,
    deviceId,
    ipAddress,
    userAgent,
    errorCode,
    timestamp,
  ];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'action': action.name,
      'status': status.name,
      'details': details,
      'deviceId': deviceId,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'errorCode': errorCode,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory TwoFactorAudit.fromJson(Map<String, dynamic> json) {
    return TwoFactorAudit(
      id: json['id'] as String,
      userId: json['userId'] as String,
      action: TwoFactorAuditAction.values.byName(json['action'] as String),
      status: TwoFactorAuditStatus.values.byName(json['status'] as String),
      details: json['details'] as String?,
      deviceId: json['deviceId'] as String?,
      ipAddress: json['ipAddress'] as String?,
      userAgent: json['userAgent'] as String?,
      errorCode: json['errorCode'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
