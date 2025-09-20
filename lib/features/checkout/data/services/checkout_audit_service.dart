import 'package:uuid/uuid.dart';
import 'package:logger/logger.dart';
import '../../domain/models/checkout_security_model.dart';
import '../../domain/models/checkout_session_model.dart';
import '../../domain/models/checkout_validation_model.dart';

class CheckoutAuditService {
  final Logger _logger;
  final String _sessionId;
  final List<AuditLogEntry> _auditLogs;

  CheckoutAuditService({
    required String sessionId,
    Logger? logger,
  })  : _sessionId = sessionId,
        _logger = logger ?? Logger(),
        _auditLogs = [];

  // Audit log entry
  void logEvent({
    required AuditEventType eventType,
    required String description,
    Map<String, dynamic> details = const {},
    AuditSeverity severity = AuditSeverity.info,
    String? userId,
    String? sessionId,
  }) {
    final entry = AuditLogEntry(
      id: const Uuid().v4(),
      sessionId: sessionId ?? _sessionId,
      eventType: eventType,
      description: description,
      timestamp: DateTime.now(),
      severity: severity,
      userId: userId,
      details: details,
    );

    _auditLogs.add(entry);

    // Log to system logger
    _logToSystemLogger(entry);
  }

  // Session lifecycle events
  void logSessionStart({required String userId, bool isGuest = false}) {
    logEvent(
      eventType: AuditEventType.sessionStart,
      description: 'Checkout session started',
      severity: AuditSeverity.info,
      userId: userId,
      details: {
        'isGuest': isGuest,
        'sessionStart': DateTime.now().toIso8601String(),
      },
    );
  }

  void logSessionEnd({required String userId, String? orderId}) {
    logEvent(
      eventType: AuditEventType.sessionEnd,
      description: 'Checkout session ended',
      severity: AuditSeverity.info,
      userId: userId,
      details: {
        'orderId': orderId,
        'sessionEnd': DateTime.now().toIso8601String(),
      },
    );
  }

  void logSessionAbandonment({
    required String userId,
    required String reason,
    CheckoutStepType? lastStep,
  }) {
    logEvent(
      eventType: AuditEventType.sessionAbandonment,
      description: 'Checkout session abandoned',
      severity: AuditSeverity.warning,
      userId: userId,
      details: {
        'reason': reason,
        'lastStep': lastStep?.name,
        'abandonedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  // Step progression events
  void logStepStart({
    required CheckoutStepType stepType,
    required String userId,
  }) {
    logEvent(
      eventType: AuditEventType.stepStart,
      description: 'Checkout step started: ${stepType.name}',
      severity: AuditSeverity.info,
      userId: userId,
      details: {
        'stepType': stepType.name,
        'stepStart': DateTime.now().toIso8601String(),
      },
    );
  }

  void logStepCompletion({
    required CheckoutStepType stepType,
    required String userId,
    required Duration duration,
    CheckoutValidationResult? validationResult,
  }) {
    logEvent(
      eventType: AuditEventType.stepCompletion,
      description: 'Checkout step completed: ${stepType.name}',
      severity: AuditSeverity.info,
      userId: userId,
      details: {
        'stepType': stepType.name,
        'duration': duration.inMilliseconds,
        'validationResult': validationResult?.toJson(),
        'stepEnd': DateTime.now().toIso8601String(),
      },
    );
  }

  void logStepFailure({
    required CheckoutStepType stepType,
    required String userId,
    required String error,
    CheckoutValidationResult? validationResult,
  }) {
    logEvent(
      eventType: AuditEventType.stepFailure,
      description: 'Checkout step failed: ${stepType.name}',
      severity: AuditSeverity.error,
      userId: userId,
      details: {
        'stepType': stepType.name,
        'error': error,
        'validationResult': validationResult?.toJson(),
        'failedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  // Security events
  void logSecurityEvent({
    required SecurityEventType securityEventType,
    required String description,
    required String userId,
    Map<String, dynamic> details = const {},
    AuditSeverity severity = AuditSeverity.warning,
  }) {
    logEvent(
      eventType: AuditEventType.securityEvent,
      description: description,
      severity: severity,
      userId: userId,
      details: {
        'securityEventType': securityEventType.name,
        ...details,
      },
    );
  }

  void logAuthenticationFailure({
    required String userId,
    required String reason,
    String? ipAddress,
    String? userAgent,
  }) {
    logEvent(
      eventType: AuditEventType.authenticationFailure,
      description: 'Authentication failure during checkout',
      severity: AuditSeverity.error,
      userId: userId,
      details: {
        'reason': reason,
        'ipAddress': ipAddress,
        'userAgent': userAgent,
      },
    );
  }

  void logAuthorizationFailure({
    required String userId,
    required String resource,
    required String action,
  }) {
    logEvent(
      eventType: AuditEventType.authorizationFailure,
      description: 'Authorization failure during checkout',
      severity: AuditSeverity.error,
      userId: userId,
      details: {
        'resource': resource,
        'action': action,
      },
    );
  }

  // Payment events
  void logPaymentAttempt({
    required String userId,
    required double amount,
    required String paymentMethodId,
    required String paymentMethodType,
  }) {
    logEvent(
      eventType: AuditEventType.paymentAttempt,
      description: 'Payment attempt initiated',
      severity: AuditSeverity.info,
      userId: userId,
      details: {
        'amount': amount,
        'paymentMethodId': paymentMethodId,
        'paymentMethodType': paymentMethodType,
      },
    );
  }

  void logPaymentSuccess({
    required String userId,
    required double amount,
    required String transactionId,
    required String paymentMethodId,
  }) {
    logEvent(
      eventType: AuditEventType.paymentSuccess,
      description: 'Payment successful',
      severity: AuditSeverity.info,
      userId: userId,
      details: {
        'amount': amount,
        'transactionId': transactionId,
        'paymentMethodId': paymentMethodId,
      },
    );
  }

  void logPaymentFailure({
    required String userId,
    required double amount,
    required String paymentMethodId,
    required String errorCode,
    required String errorMessage,
  }) {
    logEvent(
      eventType: AuditEventType.paymentFailure,
      description: 'Payment failed',
      severity: AuditSeverity.error,
      userId: userId,
      details: {
        'amount': amount,
        'paymentMethodId': paymentMethodId,
        'errorCode': errorCode,
        'errorMessage': errorMessage,
      },
    );
  }

  // Data events
  void logDataAccess({
    required String userId,
    required String dataType,
    required String action,
    Map<String, dynamic> details = const {},
  }) {
    logEvent(
      eventType: AuditEventType.dataAccess,
      description: 'Data access event',
      severity: AuditSeverity.info,
      userId: userId,
      details: {
        'dataType': dataType,
        'action': action,
        ...details,
      },
    );
  }

  void logDataModification({
    required String userId,
    required String dataType,
    required String action,
    Map<String, dynamic> oldValues,
    Map<String, dynamic> newValues,
  }) {
    logEvent(
      eventType: AuditEventType.dataModification,
      description: 'Data modification event',
      severity: AuditSeverity.info,
      userId: userId,
      details: {
        'dataType': dataType,
        'action': action,
        'oldValues': oldValues,
        'newValues': newValues,
      },
    );
  }

  // Validation events
  void logValidationSuccess({
    required String userId,
    required CheckoutStepType stepType,
    CheckoutValidationResult? validationResult,
  }) {
    logEvent(
      eventType: AuditEventType.validationSuccess,
      description: 'Validation successful for step: ${stepType.name}',
      severity: AuditSeverity.info,
      userId: userId,
      details: {
        'stepType': stepType.name,
        'validationResult': validationResult?.toJson(),
      },
    );
  }

  void logValidationFailure({
    required String userId,
    required CheckoutStepType stepType,
    required List<ValidationRule> failedRules,
  }) {
    logEvent(
      eventType: AuditEventType.validationFailure,
      description: 'Validation failed for step: ${stepType.name}',
      severity: AuditSeverity.warning,
      userId: userId,
      details: {
        'stepType': stepType.name,
        'failedRules': failedRules.map((r) => r.toJson()).toList(),
      },
    );
  }

  // Error events
  void logError({
    required String userId,
    required String errorType,
    required String errorMessage,
    StackTrace? stackTrace,
    Map<String, dynamic> context = const {},
  }) {
    logEvent(
      eventType: AuditEventType.error,
      description: 'Error occurred during checkout',
      severity: AuditSeverity.error,
      userId: userId,
      details: {
        'errorType': errorType,
        'errorMessage': errorMessage,
        'stackTrace': stackTrace?.toString(),
        'context': context,
      },
    );
  }

  // Performance events
  void logPerformanceMetric({
    required String metricName,
    required double value,
    String? unit,
    Map<String, dynamic> tags = const {},
  }) {
    logEvent(
      eventType: AuditEventType.performanceMetric,
      description: 'Performance metric recorded',
      severity: AuditSeverity.info,
      details: {
        'metricName': metricName,
        'value': value,
        'unit': unit,
        'tags': tags,
      },
    );
  }

  // Session recovery events
  void logSessionRecovery({
    required String userId,
    required String recoveryMethod,
    required bool successful,
  }) {
    logEvent(
      eventType: AuditEventType.sessionRecovery,
      description: 'Session recovery attempt',
      severity: successful ? AuditSeverity.info : AuditSeverity.warning,
      userId: userId,
      details: {
        'recoveryMethod': recoveryMethod,
        'successful': successful,
      },
    );
  }

  // Get audit logs
  List<AuditLogEntry> getAuditLogs({
    DateTime? startTime,
    DateTime? endTime,
    AuditEventType? eventType,
    AuditSeverity? minSeverity,
  }) {
    var filteredLogs = List<AuditLogEntry>.from(_auditLogs);

    if (startTime != null) {
      filteredLogs = filteredLogs.where((log) => log.timestamp.isAfter(startTime)).toList();
    }

    if (endTime != null) {
      filteredLogs = filteredLogs.where((log) => log.timestamp.isBefore(endTime)).toList();
    }

    if (eventType != null) {
      filteredLogs = filteredLogs.where((log) => log.eventType == eventType).toList();
    }

    if (minSeverity != null) {
      filteredLogs = filteredLogs.where((log) => log.severity.index >= minSeverity.index).toList();
    }

    return filteredLogs;
  }

  // Export audit logs
  Map<String, dynamic> exportAuditLogs() {
    return {
      'sessionId': _sessionId,
      'exportedAt': DateTime.now().toIso8601String(),
      'totalEntries': _auditLogs.length,
      'logs': _auditLogs.map((log) => log.toJson()).toList(),
    };
  }

  // Clear audit logs
  void clearAuditLogs() {
    _auditLogs.clear();
  }

  // Get audit statistics
  Map<String, dynamic> getAuditStatistics() {
    final eventCounts = <AuditEventType, int>{};
    final severityCounts = <AuditSeverity, int>{};

    for (final log in _auditLogs) {
      eventCounts[log.eventType] = (eventCounts[log.eventType] ?? 0) + 1;
      severityCounts[log.severity] = (severityCounts[log.severity] ?? 0) + 1;
    }

    return {
      'totalEvents': _auditLogs.length,
      'eventCounts': eventCounts.map((k, v) => MapEntry(k.name, v)),
      'severityCounts': severityCounts.map((k, v) => MapEntry(k.name, v)),
      'firstEvent': _auditLogs.isNotEmpty ? _auditLogs.first.timestamp.toIso8601String() : null,
      'lastEvent': _auditLogs.isNotEmpty ? _auditLogs.last.timestamp.toIso8601String() : null,
    };
  }

  void _logToSystemLogger(AuditLogEntry entry) {
    final message = '[${entry.severity.name.toUpperCase()}] ${entry.eventType.name}: ${entry.description}';

    switch (entry.severity) {
      case AuditSeverity.debug:
        _logger.d(message, error: entry.details);
        break;
      case AuditSeverity.info:
        _logger.i(message, error: entry.details);
        break;
      case AuditSeverity.warning:
        _logger.w(message, error: entry.details);
        break;
      case AuditSeverity.error:
        _logger.e(message, error: entry.details);
        break;
      case AuditSeverity.critical:
        _logger.f(message, error: entry.details);
        break;
    }
  }
}

enum AuditEventType {
  sessionStart,
  sessionEnd,
  sessionAbandonment,
  sessionRecovery,
  stepStart,
  stepCompletion,
  stepFailure,
  securityEvent,
  authenticationFailure,
  authorizationFailure,
  paymentAttempt,
  paymentSuccess,
  paymentFailure,
  dataAccess,
  dataModification,
  validationSuccess,
  validationFailure,
  error,
  performanceMetric,
}

enum AuditSeverity {
  debug,
  info,
  warning,
  error,
  critical,
}

class AuditLogEntry {
  final String id;
  final String sessionId;
  final AuditEventType eventType;
  final String description;
  final DateTime timestamp;
  final AuditSeverity severity;
  final String? userId;
  final Map<String, dynamic> details;

  AuditLogEntry({
    required this.id,
    required this.sessionId,
    required this.eventType,
    required this.description,
    required this.timestamp,
    required this.severity,
    this.userId,
    this.details = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'eventType': eventType.name,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'severity': severity.name,
      'userId': userId,
      'details': details,
    };
  }
}