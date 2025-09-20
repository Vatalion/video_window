import 'package:equatable/equatable.dart';

class SecurityAuditLog extends Equatable {
  final String id;
  final String userId;
  final SecurityEventType eventType;
  final String eventDescription;
  final String ipAddress;
  final String userAgent;
  final String? deviceId;
  final int? riskScore;
  final bool wasSuspicious;
  final String? suspicionReason;
  final Map<String, dynamic>? eventData;
  final DateTime createdAt;

  const SecurityAuditLog({
    required this.id,
    required this.userId,
    required this.eventType,
    required this.eventDescription,
    required this.ipAddress,
    required this.userAgent,
    this.deviceId,
    this.riskScore,
    this.wasSuspicious = false,
    this.suspicionReason,
    this.eventData,
    required this.createdAt,
  });

  factory SecurityAuditLog.fromJson(Map<String, dynamic> json) {
    return SecurityAuditLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      eventType: SecurityEventType.values.firstWhere(
        (e) => e.name == json['event_type'],
        orElse: () => SecurityEventType.login,
      ),
      eventDescription: json['event_description'] as String,
      ipAddress: json['ip_address'] as String,
      userAgent: json['user_agent'] as String,
      deviceId: json['device_id'] as String?,
      riskScore: json['risk_score'] as int?,
      wasSuspicious: json['was_suspicious'] as bool,
      suspicionReason: json['suspicion_reason'] as String?,
      eventData: json['event_data'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'event_type': eventType.name,
      'event_description': eventDescription,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'device_id': deviceId,
      'risk_score': riskScore,
      'was_suspicious': wasSuspicious,
      'suspicion_reason': suspicionReason,
      'event_data': eventData,
      'created_at': createdAt.toIso8601String(),
    };
  }

  SecurityAuditLog copyWith({
    String? id,
    String? userId,
    SecurityEventType? eventType,
    String? eventDescription,
    String? ipAddress,
    String? userAgent,
    String? deviceId,
    int? riskScore,
    bool? wasSuspicious,
    String? suspicionReason,
    Map<String, dynamic>? eventData,
    DateTime? createdAt,
  }) {
    return SecurityAuditLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      eventType: eventType ?? this.eventType,
      eventDescription: eventDescription ?? this.eventDescription,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      deviceId: deviceId ?? this.deviceId,
      riskScore: riskScore ?? this.riskScore,
      wasSuspicious: wasSuspicious ?? this.wasSuspicious,
      suspicionReason: suspicionReason ?? this.suspicionReason,
      eventData: eventData ?? this.eventData,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get severity {
    if (riskScore == null) return 'low';
    if (riskScore! >= 80) return 'critical';
    if (riskScore! >= 60) return 'high';
    if (riskScore! >= 40) return 'medium';
    return 'low';
  }

  @override
  List<Object> get props => [
    id,
    userId,
    eventType,
    eventDescription,
    ipAddress,
    userAgent,
    deviceId ?? '',
    riskScore ?? '',
    wasSuspicious,
    suspicionReason ?? '',
    eventData ?? '',
    createdAt,
  ];
}

enum SecurityEventType {
  login,
  logout,
  failedLogin,
  passwordChange,
  passwordReset,
  profileUpdate,
  deviceRegistration,
  deviceRemoval,
  twoFactorEnabled,
  twoFactorDisabled,
  securityQuestionUpdate,
  dataExport,
  dataDeletion,
  accountLockout,
  suspiciousActivity,
  policyViolation,
  complianceCheck,
}

class SecurityAlert extends Equatable {
  final String id;
  final String userId;
  final AlertType alertType;
  final String title;
  final String description;
  final AlertSeverity severity;
  final String? actionRequired;
  final bool isAcknowledged;
  final DateTime? acknowledgedAt;
  final String? acknowledgedBy;
  final DateTime createdAt;
  final DateTime expiresAt;

  const SecurityAlert({
    required this.id,
    required this.userId,
    required this.alertType,
    required this.title,
    required this.description,
    required this.severity,
    this.actionRequired,
    this.isAcknowledged = false,
    this.acknowledgedAt,
    this.acknowledgedBy,
    required this.createdAt,
    required this.expiresAt,
  });

  factory SecurityAlert.fromJson(Map<String, dynamic> json) {
    return SecurityAlert(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      alertType: AlertType.values.firstWhere(
        (e) => e.name == json['alert_type'],
        orElse: () => AlertType.suspiciousLogin,
      ),
      title: json['title'] as String,
      description: json['description'] as String,
      severity: AlertSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => AlertSeverity.medium,
      ),
      actionRequired: json['action_required'] as String?,
      isAcknowledged: json['is_acknowledged'] as bool,
      acknowledgedAt: json['acknowledged_at'] != null
          ? DateTime.parse(json['acknowledged_at'] as String)
          : null,
      acknowledgedBy: json['acknowledged_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'alert_type': alertType.name,
      'title': title,
      'description': description,
      'severity': severity.name,
      'action_required': actionRequired,
      'is_acknowledged': isAcknowledged,
      'acknowledged_at': acknowledgedAt?.toIso8601String(),
      'acknowledged_by': acknowledgedBy,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isActive => !isAcknowledged && !isExpired;

  @override
  List<Object> get props => [
    id,
    userId,
    alertType,
    title,
    description,
    severity,
    actionRequired ?? '',
    isAcknowledged,
    acknowledgedAt ?? '',
    acknowledgedBy ?? '',
    createdAt,
    expiresAt,
  ];
}

enum AlertType {
  suspiciousLogin,
  multipleFailedAttempts,
  unusualLocation,
  deviceMismatch,
  passwordCompromise,
  dataBreach,
  policyViolation,
  complianceIssue,
  systemAnomaly,
}

enum AlertSeverity { low, medium, high, critical }

class SecurityMetrics extends Equatable {
  final String userId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int totalEvents;
  final int suspiciousEvents;
  final int criticalAlerts;
  final int highRiskEvents;
  final double averageRiskScore;
  final Map<String, int> eventTypeDistribution;
  final List<String> topRiskFactors;
  final DateTime lastSecurityScan;

  const SecurityMetrics({
    required this.userId,
    required this.periodStart,
    required this.periodEnd,
    required this.totalEvents,
    required this.suspiciousEvents,
    required this.criticalAlerts,
    required this.highRiskEvents,
    required this.averageRiskScore,
    required this.eventTypeDistribution,
    required this.topRiskFactors,
    required this.lastSecurityScan,
  });

  factory SecurityMetrics.fromJson(Map<String, dynamic> json) {
    return SecurityMetrics(
      userId: json['user_id'] as String,
      periodStart: DateTime.parse(json['period_start'] as String),
      periodEnd: DateTime.parse(json['period_end'] as String),
      totalEvents: json['total_events'] as int,
      suspiciousEvents: json['suspicious_events'] as int,
      criticalAlerts: json['critical_alerts'] as int,
      highRiskEvents: json['high_risk_events'] as int,
      averageRiskScore: (json['average_risk_score'] as num).toDouble(),
      eventTypeDistribution: Map<String, int>.from(
        json['event_type_distribution'] as Map<String, dynamic>,
      ),
      topRiskFactors: List<String>.from(json['top_risk_factors'] as List),
      lastSecurityScan: DateTime.parse(json['last_security_scan'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'period_start': periodStart.toIso8601String(),
      'period_end': periodEnd.toIso8601String(),
      'total_events': totalEvents,
      'suspicious_events': suspiciousEvents,
      'critical_alerts': criticalAlerts,
      'high_risk_events': highRiskEvents,
      'average_risk_score': averageRiskScore,
      'event_type_distribution': eventTypeDistribution,
      'top_risk_factors': topRiskFactors,
      'last_security_scan': lastSecurityScan.toIso8601String(),
    };
  }

  double get securityScore {
    if (totalEvents == 0) return 100.0;

    final baseScore = 100.0;
    final suspiciousPenalty = (suspiciousEvents / totalEvents) * 30;
    final criticalPenalty = (criticalAlerts / totalEvents) * 40;
    final highRiskPenalty = (highRiskEvents / totalEvents) * 20;

    return (baseScore - suspiciousPenalty - criticalPenalty - highRiskPenalty)
        .clamp(0, 100);
  }

  String get securityStatus {
    final score = securityScore;
    if (score >= 90) return 'Excellent';
    if (score >= 75) return 'Good';
    if (score >= 60) return 'Fair';
    if (score >= 40) return 'Poor';
    return 'Critical';
  }

  @override
  List<Object> get props => [
    userId,
    periodStart,
    periodEnd,
    totalEvents,
    suspiciousEvents,
    criticalAlerts,
    highRiskEvents,
    averageRiskScore,
    eventTypeDistribution,
    topRiskFactors,
    lastSecurityScan,
  ];
}
