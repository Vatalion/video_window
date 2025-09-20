import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'checkout_security_model.g.dart';

enum SecurityLevel {
  low,
  standard,
  high,
  maximum,
}

enum SecurityEventType {
  sessionStart,
  stepTransition,
  validationError,
  securityViolation,
  paymentAttempt,
  authenticationRequired,
  sessionEnd,
  abandonment,
  recovery,
}

@JsonSerializable()
class SecurityContextModel extends Equatable {
  final String sessionId;
  final String userId;
  final String deviceFingerprint;
  final String ipAddress;
  final String userAgent;
  final SecurityLevel securityLevel;
  final DateTime lastActivity;
  final int failedAttempts;
  final bool isLocked;
  final DateTime? lockedUntil;
  final Map<String, dynamic> riskFactors;
  final List<SecurityEventModel> recentEvents;
  final Map<String, dynamic> metadata;

  const SecurityContextModel({
    required this.sessionId,
    required this.userId,
    required this.deviceFingerprint,
    required this.ipAddress,
    required this.userAgent,
    required this.securityLevel,
    required this.lastActivity,
    this.failedAttempts = 0,
    this.isLocked = false,
    this.lockedUntil,
    this.riskFactors = const {},
    this.recentEvents = const [],
    this.metadata = const {},
  });

  factory SecurityContextModel.fromJson(Map<String, dynamic> json) =>
      _$SecurityContextModelFromJson(json);

  Map<String, dynamic> toJson() => _$SecurityContextModelToJson(this);

  SecurityContextModel copyWith({
    String? sessionId,
    String? userId,
    String? deviceFingerprint,
    String? ipAddress,
    String? userAgent,
    SecurityLevel? securityLevel,
    DateTime? lastActivity,
    int? failedAttempts,
    bool? isLocked,
    DateTime? lockedUntil,
    Map<String, dynamic>? riskFactors,
    List<SecurityEventModel>? recentEvents,
    Map<String, dynamic>? metadata,
  }) {
    return SecurityContextModel(
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      deviceFingerprint: deviceFingerprint ?? this.deviceFingerprint,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      securityLevel: securityLevel ?? this.securityLevel,
      lastActivity: lastActivity ?? DateTime.now(),
      failedAttempts: failedAttempts ?? this.failedAttempts,
      isLocked: isLocked ?? this.isLocked,
      lockedUntil: lockedUntil ?? this.lockedUntil,
      riskFactors: riskFactors ?? this.riskFactors,
      recentEvents: recentEvents ?? this.recentEvents,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isLockedNow => isLocked &&
      (lockedUntil == null || DateTime.now().isBefore(lockedUntil));

  bool get hasHighRisk => riskFactors['highRisk'] == true;

  bool get requiresMFA => securityLevel == SecurityLevel.high ||
      securityLevel == SecurityLevel.maximum;

  void recordEvent(SecurityEventModel event) {
    recentEvents.add(event);
    if (recentEvents.length > 100) {
      recentEvents.removeAt(0);
    }
  }

  void updateRiskFactor(String factor, bool value) {
    riskFactors[factor] = value;
  }

  @override
  List<Object?> get props => [
        sessionId,
        userId,
        deviceFingerprint,
        ipAddress,
        userAgent,
        securityLevel,
        lastActivity,
        failedAttempts,
        isLocked,
        lockedUntil,
        riskFactors,
        recentEvents,
        metadata,
      ];
}

@JsonSerializable()
class SecurityEventModel extends Equatable {
  final String id;
  final String sessionId;
  final SecurityEventType type;
  final String description;
  final DateTime timestamp;
  final String? ipAddress;
  final String? userAgent;
  final Map<String, dynamic> details;
  final SecurityLevel securityLevel;
  final bool isSuspicious;

  const SecurityEventModel({
    required this.id,
    required this.sessionId,
    required this.type,
    required this.description,
    required this.timestamp,
    this.ipAddress,
    this.userAgent,
    this.details = const {},
    required this.securityLevel,
    this.isSuspicious = false,
  });

  factory SecurityEventModel.fromJson(Map<String, dynamic> json) =>
      _$SecurityEventModelFromJson(json);

  Map<String, dynamic> toJson() => _$SecurityEventModelToJson(this);

  SecurityEventModel copyWith({
    String? id,
    String? sessionId,
    SecurityEventType? type,
    String? description,
    DateTime? timestamp,
    String? ipAddress,
    String? userAgent,
    Map<String, dynamic>? details,
    SecurityLevel? securityLevel,
    bool? isSuspicious,
  }) {
    return SecurityEventModel(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      type: type ?? this.type,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      details: details ?? this.details,
      securityLevel: securityLevel ?? this.securityLevel,
      isSuspicious: isSuspicious ?? this.isSuspicious,
    );
  }

  @override
  List<Object?> get props => [
        id,
        sessionId,
        type,
        description,
        timestamp,
        ipAddress,
        userAgent,
        details,
        securityLevel,
        isSuspicious,
      ];
}

@JsonSerializable()
class SecurityValidationResult extends Equatable {
  final bool isValid;
  final List<SecurityViolation> violations;
  final SecurityLevel recommendedLevel;
  final Map<String, dynamic> recommendations;
  final DateTime validatedAt;

  const SecurityValidationResult({
    required this.isValid,
    required this.violations,
    required this.recommendedLevel,
    required this.recommendations,
    required this.validatedAt,
  });

  factory SecurityValidationResult.fromJson(Map<String, dynamic> json) =>
      _$SecurityValidationResultFromJson(json);

  Map<String, dynamic> toJson() => _$SecurityValidationResultToJson(this);

  SecurityValidationResult copyWith({
    bool? isValid,
    List<SecurityViolation>? violations,
    SecurityLevel? recommendedLevel,
    Map<String, dynamic>? recommendations,
    DateTime? validatedAt,
  }) {
    return SecurityValidationResult(
      isValid: isValid ?? this.isValid,
      violations: violations ?? this.violations,
      recommendedLevel: recommendedLevel ?? this.recommendedLevel,
      recommendations: recommendations ?? this.recommendations,
      validatedAt: validatedAt ?? this.validatedAt,
    );
  }

  bool get hasCriticalViolations => violations
      .any((v) => v.severity == SecurityViolationSeverity.critical);

  bool get hasHighRiskViolations => violations
      .any((v) => v.severity == SecurityViolationSeverity.high);

  @override
  List<Object?> get props => [
        isValid,
        violations,
        recommendedLevel,
        recommendations,
        validatedAt,
      ];
}

@JsonSerializable()
class SecurityViolation extends Equatable {
  final String code;
  final String message;
  final SecurityViolationSeverity severity;
  final String field;
  final dynamic actualValue;
  final dynamic expectedValue;
  final String? remediation;

  const SecurityViolation({
    required this.code,
    required this.message,
    required this.severity,
    required this.field,
    this.actualValue,
    this.expectedValue,
    this.remediation,
  });

  factory SecurityViolation.fromJson(Map<String, dynamic> json) =>
      _$SecurityViolationFromJson(json);

  Map<String, dynamic> toJson() => _$SecurityViolationToJson(this);

  @override
  List<Object?> get props => [
        code,
        message,
        severity,
        field,
        actualValue,
        expectedValue,
        remediation,
      ];
}

enum SecurityViolationSeverity {
  low,
  medium,
  high,
  critical,
}