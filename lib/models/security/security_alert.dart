import 'package:json_annotation/json_annotation.dart';

part 'security_alert.g.dart';

@JsonSerializable()
class SecurityAlert {
  final String id;
  final String userId;
  final String alertType;
  final String message;
  final double severity;
  final DateTime timestamp;
  final bool acknowledged;
  final DateTime? acknowledgedAt;
  final String? acknowledgedBy;
  final Map<String, dynamic> alertDetails;
  final AlertStatus status;

  SecurityAlert({
    required this.id,
    required this.userId,
    required this.alertType,
    required this.message,
    required this.severity,
    required this.timestamp,
    this.acknowledged = false,
    this.acknowledgedAt,
    this.acknowledgedBy,
    required this.alertDetails,
    this.status = AlertStatus.active,
  });

  factory SecurityAlert.fromJson(Map<String, dynamic> json) =>
      _$SecurityAlertFromJson(json);

  Map<String, dynamic> toJson() => _$SecurityAlertToJson(this);

  SecurityAlert copyWith({
    String? id,
    String? userId,
    String? alertType,
    String? message,
    double? severity,
    DateTime? timestamp,
    bool? acknowledged,
    DateTime? acknowledgedAt,
    String? acknowledgedBy,
    Map<String, dynamic>? alertDetails,
    AlertStatus? status,
  }) {
    return SecurityAlert(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      alertType: alertType ?? this.alertType,
      message: message ?? this.message,
      severity: severity ?? this.severity,
      timestamp: timestamp ?? this.timestamp,
      acknowledged: acknowledged ?? this.acknowledged,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      acknowledgedBy: acknowledgedBy ?? this.acknowledgedBy,
      alertDetails: alertDetails ?? this.alertDetails,
      status: status ?? this.status,
    );
  }

  void acknowledge(String acknowledgedBy) {
    this.acknowledged = true;
    this.acknowledgedAt = DateTime.now();
    this.acknowledgedBy = acknowledgedBy;
    this.status = AlertStatus.resolved;
  }
}

enum AlertStatus {
  active,
  resolved,
  dismissed,
  falsePositive,
}

enum AlertType {
  unusualLoginLocation,
  multipleFailedAttempts,
  suspiciousDevice,
  passwordStrengthWeak,
  unusualActivityPattern,
  sessionAnomaly,
  bruteForceAttack,
  dataExfiltrationAttempt,
}