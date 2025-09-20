// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'security_audit_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SecurityAuditLog _$SecurityAuditLogFromJson(Map<String, dynamic> json) =>
    SecurityAuditLog(
      id: json['id'] as String,
      userId: json['userId'] as String,
      eventType: json['eventType'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      ipAddress: json['ipAddress'] as String,
      userAgent: json['userAgent'] as String,
      deviceId: json['deviceId'] as String,
      riskScore: (json['riskScore'] as num).toDouble(),
      eventDetails: json['eventDetails'] as Map<String, dynamic>,
      sessionId: json['sessionId'] as String?,
      encrypted: json['encrypted'] as bool? ?? true,
    );

Map<String, dynamic> _$SecurityAuditLogToJson(SecurityAuditLog instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'eventType': instance.eventType,
      'timestamp': instance.timestamp.toIso8601String(),
      'ipAddress': instance.ipAddress,
      'userAgent': instance.userAgent,
      'deviceId': instance.deviceId,
      'riskScore': instance.riskScore,
      'eventDetails': instance.eventDetails,
      'sessionId': instance.sessionId,
      'encrypted': instance.encrypted,
    };
