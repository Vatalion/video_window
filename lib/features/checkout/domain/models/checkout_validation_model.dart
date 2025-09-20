import 'package:equatable/equatable.dart';

enum ValidationSeverity {
  info,
  warning,
  error,
  critical,
}

enum ValidationType {
  required,
  format,
  length,
  range,
  pattern,
  custom,
  security,
  pci,
}

class ValidationRule extends Equatable {
  final String field;
  final String message;
  final ValidationType type;
  final ValidationSeverity severity;
  final bool isValid;
  final dynamic expectedValue;
  final dynamic actualValue;
  final String? code;

  const ValidationRule({
    required this.field,
    required this.message,
    required this.type,
    required this.severity,
    this.isValid = false,
    this.expectedValue,
    this.actualValue,
    this.code,
  });

  ValidationRule copyWith({
    String? field,
    String? message,
    ValidationType? type,
    ValidationSeverity? severity,
    bool? isValid,
    dynamic expectedValue,
    dynamic actualValue,
    String? code,
  }) {
    return ValidationRule(
      field: field ?? this.field,
      message: message ?? this.message,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      isValid: isValid ?? this.isValid,
      expectedValue: expectedValue ?? this.expectedValue,
      actualValue: actualValue ?? this.actualValue,
      code: code ?? this.code,
    );
  }

  @override
  List<Object?> get props => [
        field,
        message,
        type,
        severity,
        isValid,
        expectedValue,
        actualValue,
        code,
      ];
}

class CheckoutValidationResult extends Equatable {
  final CheckoutStepType step;
  final bool isValid;
  final List<ValidationRule> rules;
  final DateTime validatedAt;
  final String? securityToken;
  final Map<String, dynamic> metadata;

  const CheckoutValidationResult({
    required this.step,
    required this.isValid,
    required this.rules,
    required this.validatedAt,
    this.securityToken,
    this.metadata = const {},
  });

  factory CheckoutValidationResult.success({
    required CheckoutStepType step,
    List<ValidationRule> rules = const [],
    String? securityToken,
    Map<String, dynamic> metadata = const {},
  }) {
    return CheckoutValidationResult(
      step: step,
      isValid: true,
      rules: rules,
      validatedAt: DateTime.now(),
      securityToken: securityToken,
      metadata: metadata,
    );
  }

  factory CheckoutValidationResult.failure({
    required CheckoutStepType step,
    required List<ValidationRule> rules,
    String? securityToken,
    Map<String, dynamic> metadata = const {},
  }) {
    return CheckoutValidationResult(
      step: step,
      isValid: false,
      rules: rules,
      validatedAt: DateTime.now(),
      securityToken: securityToken,
      metadata: metadata,
    );
  }

  List<ValidationRule> get errors => rules.where((r) => !r.isValid).toList();

  List<ValidationRule> get criticalErrors => errors
      .where((r) => r.severity == ValidationSeverity.critical)
      .toList();

  List<ValidationRule> get securityViolations => errors
      .where((r) => r.type == ValidationType.security)
      .toList();

  List<ValidationRule> get pciViolations => errors
      .where((r) => r.type == ValidationType.pci)
      .toList();

  bool get hasCriticalErrors => criticalErrors.isNotEmpty;

  bool get hasSecurityViolations => securityViolations.isNotEmpty;

  bool get hasPciViolations => pciViolations.isNotEmpty;

  CheckoutValidationResult copyWith({
    CheckoutStepType? step,
    bool? isValid,
    List<ValidationRule>? rules,
    DateTime? validatedAt,
    String? securityToken,
    Map<String, dynamic>? metadata,
  }) {
    return CheckoutValidationResult(
      step: step ?? this.step,
      isValid: isValid ?? this.isValid,
      rules: rules ?? this.rules,
      validatedAt: validatedAt ?? this.validatedAt,
      securityToken: securityToken ?? this.securityToken,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        step,
        isValid,
        rules,
        validatedAt,
        securityToken,
        metadata,
      ];
}

class ValidationSecurityContext {
  final String sessionId;
  final String userId;
  final String ipAddress;
  final String userAgent;
  final String deviceFingerprint;
  final DateTime timestamp;
  final String securityLevel;

  const ValidationSecurityContext({
    required this.sessionId,
    required this.userId,
    required this.ipAddress,
    required this.userAgent,
    required this.deviceFingerprint,
    required this.timestamp,
    required this.securityLevel,
  });

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'userId': userId,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'deviceFingerprint': deviceFingerprint,
      'timestamp': timestamp.toIso8601String(),
      'securityLevel': securityLevel,
    };
  }
}