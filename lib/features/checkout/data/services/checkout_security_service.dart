import 'package:uuid/uuid.dart';
import '../../domain/models/checkout_security_model.dart';
import '../../domain/models/checkout_session_model.dart';
import '../../domain/models/checkout_validation_model.dart';
import 'checkout_encryption_service.dart';

class CheckoutSecurityService {
  final CheckoutEncryptionService _encryptionService;
  final String _deviceId;

  CheckoutSecurityService({
    required CheckoutEncryptionService encryptionService,
    required String deviceId,
  })  : _encryptionService = encryptionService,
        _deviceId = deviceId;

  // Security context management
  SecurityContextModel createSecurityContext({
    required String sessionId,
    required String userId,
    String? ipAddress,
    String? userAgent,
  }) {
    return SecurityContextModel(
      sessionId: sessionId,
      userId: userId,
      deviceFingerprint: _deviceId,
      ipAddress: ipAddress ?? 'unknown',
      userAgent: userAgent ?? 'Flutter App',
      securityLevel: SecurityLevel.standard,
      lastActivity: DateTime.now(),
      riskFactors: {
        'newDevice': false,
        'newLocation': false,
        'highValueTransaction': false,
        'rapidCheckout': false,
        'suspiciousPattern': false,
      },
      recentEvents: [],
    );
  }

  // Risk assessment
  Future<SecurityValidationResult> assessRisk({
    required SecurityContextModel context,
    required CheckoutSessionModel session,
    required double orderValue,
  }) async {
    final violations = <SecurityViolation>[];
    final recommendations = <String, dynamic>{};
    SecurityLevel recommendedLevel = SecurityLevel.standard;

    // Check for high-value transactions
    if (orderValue > 1000.0) {
      context.updateRiskFactor('highValueTransaction', true);
      recommendedLevel = SecurityLevel.high;
      violations.add(SecurityViolation(
        code: 'HIGH_VALUE_TRANSACTION',
        message: 'High-value transaction requires enhanced security',
        severity: SecurityViolationSeverity.high,
        field: 'orderValue',
        actualValue: orderValue,
        expectedValue: 1000.0,
        remediation: 'Enable multi-factor authentication',
      ));
    }

    // Check for rapid checkout patterns
    final sessionDuration = DateTime.now().difference(session.createdAt);
    if (sessionDuration.inMinutes < 2) {
      context.updateRiskFactor('rapidCheckout', true);
      violations.add(SecurityViolation(
        code: 'RAPID_CHECKOUT',
        message: 'Rapid checkout pattern detected',
        severity: SecurityViolationSeverity.medium,
        field: 'sessionDuration',
        actualValue: sessionDuration.inMinutes,
        expectedValue: 2,
        remediation: 'Verify user identity',
      ));
    }

    // Check for suspicious patterns
    if (_hasSuspiciousPattern(session)) {
      context.updateRiskFactor('suspiciousPattern', true);
      violations.add(SecurityViolation(
        code: 'SUSPICIOUS_PATTERN',
        message: 'Suspicious checkout pattern detected',
        severity: SecurityViolationSeverity.high,
        field: 'sessionPattern',
        remediation: 'Manual review required',
      ));
      recommendedLevel = SecurityLevel.maximum;
    }

    // Check for session age
    if (session.isExpired) {
      violations.add(SecurityViolation(
        code: 'SESSION_EXPIRED',
        message: 'Checkout session has expired',
        severity: SecurityViolationSeverity.critical,
        field: 'sessionExpiry',
        remediation: 'Restart checkout process',
      ));
    }

    // Generate recommendations
    recommendations['securityLevel'] = recommendedLevel.name;
    recommendations['requiredActions'] = _getRequiredActions(violations);
    recommendations['riskScore'] = _calculateRiskScore(violations);

    return SecurityValidationResult(
      isValid: violations.isEmpty || !violations.any((v) => v.severity == SecurityViolationSeverity.critical),
      violations: violations,
      recommendedLevel: recommendedLevel,
      recommendations: recommendations,
      validatedAt: DateTime.now(),
    );
  }

  // PCI compliance validation
  List<SecurityViolation> validatePCICompliance(Map<String, dynamic> paymentData) {
    final violations = <SecurityViolation>[];

    // Check for raw card numbers
    if (paymentData.containsKey('cardNumber') && paymentData['cardNumber'] is String) {
      final cardNumber = paymentData['cardNumber'] as String;
      if (!_encryptionService.isValidCreditCard(cardNumber)) {
        violations.add(SecurityViolation(
          code: 'INVALID_CARD_FORMAT',
          message: 'Invalid credit card format',
          severity: SecurityViolationSeverity.critical,
          field: 'cardNumber',
        ));
      }
    }

    // Check for CVV presence (should not be stored)
    if (paymentData.containsKey('cvv')) {
      violations.add(SecurityViolation(
        code: 'CVV_PRESENT',
        message: 'CVV should not be stored',
        severity: SecurityViolationSeverity.critical,
        field: 'cvv',
        remediation: 'Remove CVV from storage immediately',
      ));
    }

    // Check for test data in production
    if (_isTestData(paymentData)) {
      violations.add(SecurityViolation(
        code: 'TEST_DATA_IN_PRODUCTION',
        message: 'Test data detected in payment information',
        severity: SecurityViolationSeverity.critical,
        field: 'paymentData',
        remediation: 'Use real payment data for production transactions',
      ));
    }

    return violations;
  }

  // Session validation
  bool validateSession(CheckoutSessionModel session) {
    // Check if session is expired
    if (session.isExpired) {
      return false;
    }

    // Check if session is abandoned
    if (session.isAbandoned) {
      return false;
    }

    // Check if session version is valid
    if (session.version <= 0) {
      return false;
    }

    // Check security context
    if (session.securityContext['deviceFingerprint'] == null) {
      return false;
    }

    return true;
  }

  // Security event logging
  SecurityEventModel createSecurityEvent({
    required String sessionId,
    required SecurityEventType type,
    required String description,
    SecurityLevel securityLevel = SecurityLevel.standard,
    Map<String, dynamic> details = const {},
  }) {
    return SecurityEventModel(
      id: const Uuid().v4(),
      sessionId: sessionId,
      type: type,
      description: description,
      timestamp: DateTime.now(),
      securityLevel: securityLevel,
      details: details,
    );
  }

  // Session timeout management
  bool isSessionTimedOut(CheckoutSessionModel session, Duration timeout) {
    final lastActivity = session.updatedAt;
    final now = DateTime.now();
    final inactivityDuration = now.difference(lastActivity);

    return inactivityDuration > timeout;
  }

  // Fraud detection patterns
  bool detectFraudPattern({
    required CheckoutSessionModel session,
    required SecurityContextModel securityContext,
    required double orderValue,
  }) {
    // Check for multiple failed payment attempts
    final failedAttempts = securityContext.failedAttempts;
    if (failedAttempts >= 3) {
      return true;
    }

    // Check for unusually large order for new user
    if (orderValue > 500.0 && session.isGuest) {
      return true;
    }

    // Check for suspicious IP changes during session
    if (securityContext.recentEvents.length > 1) {
      final ipAddresses = securityContext.recentEvents
          .map((e) => e.ipAddress)
          .toSet()
          .where((ip) => ip != null && ip != 'unknown')
          .toList();

      if (ipAddresses.length > 1) {
        return true;
      }
    }

    return false;
  }

  // Biometric authentication check
  Future<bool> isBiometricAvailable() async {
    // This would integrate with local_auth package
    // For now, return false as a placeholder
    return false;
  }

  // Device security check
  Future<bool> isDeviceSecure() async {
    // This would check for device security features
    // like screen lock, encryption, etc.
    // For now, return true as a placeholder
    return true;
  }

  // Helper methods
  bool _hasSuspiciousPattern(CheckoutSessionModel session) {
    // Check for unusual step progression
    final stepProgression = session.completedSteps;

    // Check if steps were completed too quickly
    if (stepProgression.length > 3) {
      final duration = DateTime.now().difference(session.createdAt);
      if (duration.inMinutes < 5) {
        return true;
      }
    }

    // Check for missing required steps
    final requiredSteps = CheckoutStepDefinition.getStandardSteps()
        .where((step) => step.isRequired)
        .map((step) => step.type)
        .toList();

    for (final requiredStep in requiredSteps) {
      if (!stepProgression.contains(requiredStep)) {
        return true;
      }
    }

    return false;
  }

  List<String> _getRequiredActions(List<SecurityViolation> violations) {
    final actions = <String>[];

    for (final violation in violations) {
      switch (violation.severity) {
        case SecurityViolationSeverity.critical:
          actions.add('Block transaction');
          actions.add('Manual review required');
          break;
        case SecurityViolationSeverity.high:
          actions.add('Enhanced authentication required');
          actions.add('Additional verification needed');
          break;
        case SecurityViolationSeverity.medium:
          actions.add('Monitor transaction');
          actions.add('User notification required');
          break;
        case SecurityViolationSeverity.low:
          actions.add('Log for review');
          break;
      }
    }

    return actions;
  }

  int _calculateRiskScore(List<SecurityViolation> violations) {
    var score = 0;

    for (final violation in violations) {
      switch (violation.severity) {
        case SecurityViolationSeverity.critical:
          score += 100;
          break;
        case SecurityViolationSeverity.high:
          score += 50;
          break;
        case SecurityViolationSeverity.medium:
          score += 25;
          break;
        case SecurityViolationSeverity.low:
          score += 10;
          break;
      }
    }

    return score;
  }

  bool _isTestData(Map<String, dynamic> data) {
    final testPatterns = [
      'test',
      'demo',
      'sample',
      '4111111111111111', // Test Visa
      '4242424242424242', // Stripe test card
      '5555555555554444', // Test Mastercard
    ];

    final dataString = data.values.join(' ').toLowerCase();
    return testPatterns.any((pattern) => dataString.contains(pattern));
  }

  // Security token validation
  bool validateSecurityToken(String token, String expectedToken) {
    return token == expectedToken;
  }

  // Session hijacking detection
  bool detectSessionHijacking(SecurityContextModel context) {
    // Check for multiple concurrent sessions
    if (context.recentEvents.length > 10) {
      return true;
    }

    // Check for unusual activity patterns
    final recentEvents = context.recentEvents.take(10).toList();
    final eventTypes = recentEvents.map((e) => e.type).toSet();

    if (eventTypes.length > 5) {
      return true;
    }

    return false;
  }
}