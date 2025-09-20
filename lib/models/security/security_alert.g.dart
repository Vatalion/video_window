// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'security_alert.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SecurityAlert _$SecurityAlertFromJson(Map<String, dynamic> json) =>
    SecurityAlert(
      id: json['id'] as String,
      userId: json['userId'] as String,
      alertType: json['alertType'] as String,
      message: json['message'] as String,
      severity: (json['severity'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      acknowledged: json['acknowledged'] as bool? ?? false,
      acknowledgedAt: json['acknowledgedAt'] == null
          ? null
          : DateTime.parse(json['acknowledgedAt'] as String),
      acknowledgedBy: json['acknowledgedBy'] as String?,
      alertDetails: json['alertDetails'] as Map<String, dynamic>,
      status: $enumDecodeNullable(_$AlertStatusEnumMap, json['status']) ??
          AlertStatus.active,
    );

Map<String, dynamic> _$SecurityAlertToJson(SecurityAlert instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'alertType': instance.alertType,
      'message': instance.message,
      'severity': instance.severity,
      'timestamp': instance.timestamp.toIso8601String(),
      'acknowledged': instance.acknowledged,
      'acknowledgedAt': instance.acknowledgedAt?.toIso8601String(),
      'acknowledgedBy': instance.acknowledgedBy,
      'alertDetails': instance.alertDetails,
      'status': _$AlertStatusEnumMap[instance.status]!,
    };

const _$AlertStatusEnumMap = {
  AlertStatus.active: 'active',
  AlertStatus.resolved: 'resolved',
  AlertStatus.dismissed: 'dismissed',
  AlertStatus.falsePositive: 'falsePositive',
};
