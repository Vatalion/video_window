import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

class SessionActivityModel extends Equatable {
  final String id;
  final String sessionId;
  final String userId;
  final ActivityType activityType;
  final String? description;
  final String? ipAddress;
  final String? userAgent;
  final String? location;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
  final bool isSecurityEvent;
  final SecurityImpact securityImpact;
  final String? resourceId;
  final String? resourceType;
  final bool success;
  final String? errorMessage;

  const SessionActivityModel({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.activityType,
    this.description,
    this.ipAddress,
    this.userAgent,
    this.location,
    required this.timestamp,
    this.metadata = const {},
    this.isSecurityEvent = false,
    this.securityImpact = SecurityImpact.none,
    this.resourceId,
    this.resourceType,
    this.success = true,
    this.errorMessage,
  });

  factory SessionActivityModel.fromJson(Map<String, dynamic> json) {
    return SessionActivityModel(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      userId: json['user_id'] as String,
      activityType: ActivityType.values.firstWhere(
        (e) => e.name == json['activity_type'],
        orElse: () => ActivityType.unknown,
      ),
      description: json['description'] as String?,
      ipAddress: json['ip_address'] as String?,
      userAgent: json['user_agent'] as String?,
      location: json['location'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      isSecurityEvent: json['is_security_event'] as bool,
      securityImpact: SecurityImpact.values.firstWhere(
        (e) => e.name == json['security_impact'],
        orElse: () => SecurityImpact.none,
      ),
      resourceId: json['resource_id'] as String?,
      resourceType: json['resource_type'] as String?,
      success: json['success'] as bool,
      errorMessage: json['error_message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'user_id': userId,
      'activity_type': activityType.name,
      'description': description,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'location': location,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
      'is_security_event': isSecurityEvent,
      'security_impact': securityImpact.name,
      'resource_id': resourceId,
      'resource_type': resourceType,
      'success': success,
      'error_message': errorMessage,
    };
  }

  SessionActivityModel copyWith({
    String? id,
    String? sessionId,
    String? userId,
    ActivityType? activityType,
    String? description,
    String? ipAddress,
    String? userAgent,
    String? location,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
    bool? isSecurityEvent,
    SecurityImpact? securityImpact,
    String? resourceId,
    String? resourceType,
    bool? success,
    String? errorMessage,
  }) {
    return SessionActivityModel(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      activityType: activityType ?? this.activityType,
      description: description ?? this.description,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      location: location ?? this.location,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
      isSecurityEvent: isSecurityEvent ?? this.isSecurityEvent,
      securityImpact: securityImpact ?? this.securityImpact,
      resourceId: resourceId ?? this.resourceId,
      resourceType: resourceType ?? this.resourceType,
      success: success ?? this.success,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get isHighRisk => securityImpact == SecurityImpact.high;
  bool get isMediumRisk => securityImpact == SecurityImpact.medium;
  bool get isLowRisk => securityImpact == SecurityImpact.low;
  bool get isSuspicious => isSecurityEvent && !success;

  String get riskLevel => _getRiskLevel();
  String get activityIcon => _getActivityIcon();

  String _getRiskLevel() {
    if (isHighRisk) return 'High';
    if (isMediumRisk) return 'Medium';
    if (isLowRisk) return 'Low';
    return 'None';
  }

  String _getActivityIcon() {
    switch (activityType) {
      case ActivityType.login:
        return '🔐';
      case ActivityType.logout:
        return '🚪';
      case ActivityType.tokenRefresh:
        return '🔄';
      case ActivityType.passwordChange:
        return '🔑';
      case ActivityType.deviceRegistration:
        return '📱';
      case ActivityType.settingsChange:
        return '⚙️';
      case ActivityType.dataAccess:
        return '📊';
      case ActivityType.securityAlert:
        return '⚠️';
      case ActivityType.sessionTimeout:
        return '⏰';
      case ActivityType.failedLogin:
        return '❌';
      case ActivityType.accountLock:
        return '🔒';
      case ActivityType.biometricAuth:
        return '👆';
      case ActivityType.unknown:
        return '❓';
    }
  }

  static SessionActivityModel create({
    required String sessionId,
    required String userId,
    required ActivityType activityType,
    String? description,
    String? ipAddress,
    String? userAgent,
    String? location,
    Map<String, dynamic> metadata = const {},
    bool isSecurityEvent = false,
    SecurityImpact securityImpact = SecurityImpact.none,
    String? resourceId,
    String? resourceType,
    bool success = true,
    String? errorMessage,
  }) {
    return SessionActivityModel(
      id: const Uuid().v4(),
      sessionId: sessionId,
      userId: userId,
      activityType: activityType,
      description: description,
      ipAddress: ipAddress,
      userAgent: userAgent,
      location: location,
      timestamp: DateTime.now(),
      metadata: metadata,
      isSecurityEvent: isSecurityEvent,
      securityImpact: securityImpact,
      resourceId: resourceId,
      resourceType: resourceType,
      success: success,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object> get props => [
    id,
    sessionId,
    userId,
    activityType,
    description ?? '',
    ipAddress ?? '',
    userAgent ?? '',
    location ?? '',
    timestamp,
    metadata,
    isSecurityEvent,
    securityImpact,
    resourceId ?? '',
    resourceType ?? '',
    success,
    errorMessage ?? '',
  ];
}

enum ActivityType {
  login,
  logout,
  tokenRefresh,
  passwordChange,
  deviceRegistration,
  settingsChange,
  dataAccess,
  securityAlert,
  sessionTimeout,
  failedLogin,
  accountLock,
  biometricAuth,
  unknown,
}

enum SecurityImpact { none, low, medium, high }
