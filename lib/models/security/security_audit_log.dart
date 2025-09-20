import 'package:json_annotation/json_annotation.dart';

part 'security_audit_log.g.dart';

@JsonSerializable()
class SecurityAuditLog {
  final String id;
  final String userId;
  final String eventType;
  final DateTime timestamp;
  final String ipAddress;
  final String userAgent;
  final String deviceId;
  final double riskScore;
  final Map<String, dynamic> eventDetails;
  final String? sessionId;
  final bool encrypted;

  SecurityAuditLog({
    required this.id,
    required this.userId,
    required this.eventType,
    required this.timestamp,
    required this.ipAddress,
    required this.userAgent,
    required this.deviceId,
    required this.riskScore,
    required this.eventDetails,
    this.sessionId,
    this.encrypted = true,
  });

  factory SecurityAuditLog.fromJson(Map<String, dynamic> json) =>
      _$SecurityAuditLogFromJson(json);

  Map<String, dynamic> toJson() => _$SecurityAuditLogToJson(this);

  SecurityAuditLog copyWith({
    String? id,
    String? userId,
    String? eventType,
    DateTime? timestamp,
    String? ipAddress,
    String? userAgent,
    String? deviceId,
    double? riskScore,
    Map<String, dynamic>? eventDetails,
    String? sessionId,
    bool? encrypted,
  }) {
    return SecurityAuditLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      eventType: eventType ?? this.eventType,
      timestamp: timestamp ?? this.timestamp,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      deviceId: deviceId ?? this.deviceId,
      riskScore: riskScore ?? this.riskScore,
      eventDetails: eventDetails ?? this.eventDetails,
      sessionId: sessionId ?? this.sessionId,
      encrypted: encrypted ?? this.encrypted,
    );
  }
}

enum SecurityEventType {
  login,
  logout,
  passwordChange,
  accountLockout,
  suspiciousActivity,
  sessionTimeout,
  deviceNew,
  passwordReset,
  twoFactorAuth,
  securityQuestionChange,
}