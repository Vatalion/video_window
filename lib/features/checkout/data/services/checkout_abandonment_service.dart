import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../domain/models/checkout_session_model.dart';
import '../../domain/models/checkout_security_model.dart';
import '../datasources/checkout_remote_data_source.dart';
import '../datasources/checkout_local_data_source.dart';
import 'checkout_audit_service.dart';

class CheckoutAbandonmentService {
  final CheckoutRemoteDataSource remoteDataSource;
  final CheckoutLocalDataSource localDataSource;
  final CheckoutAuditService auditService;

  final Map<String, Timer> _sessionTimers = {};
  final Map<String, DateTime> _lastActivity = {};
  final Map<String, Map<String, dynamic>> _sessionData = {};
  final Duration _abandonmentThreshold = const Duration(minutes: 10);
  final Duration _inactivityThreshold = const Duration(minutes: 5);

  CheckoutAbandonmentService({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.auditService,
  });

  // Session monitoring
  void startSessionMonitoring(String sessionId, CheckoutSessionModel session) {
    _lastActivity[sessionId] = DateTime.now();
    _sessionData[sessionId] = {
      'userId': session.userId,
      'isGuest': session.isGuest,
      'currentStep': session.currentStep.name,
      'stepCount': session.completedSteps.length,
      'orderValue': 0.0, // This would be calculated from cart
      'startTime': session.createdAt.toIso8601String(),
      'lastStepTime': DateTime.now().toIso8601String(),
    };

    // Start inactivity timer
    _startInactivityTimer(sessionId);

    // Start abandonment detection timer
    _startAbandonmentTimer(sessionId);
  }

  void updateSessionActivity(String sessionId) {
    _lastActivity[sessionId] = DateTime.now();

    if (_sessionData[sessionId] != null) {
      _sessionData[sessionId]!['lastActivity'] = DateTime.now().toIso8601String();
    }

    // Restart inactivity timer
    _restartInactivityTimer(sessionId);
  }

  void updateStepProgress(String sessionId, CheckoutStepType stepType, Map<String, dynamic> stepData) {
    if (_sessionData[sessionId] != null) {
      _sessionData[sessionId]!['currentStep'] = stepType.name;
      _sessionData[sessionId]!['lastStepTime'] = DateTime.now().toIso8601String();
      _sessionData[sessionId]!['stepData'] = stepData;
      _sessionData[sessionId]!['stepCount'] = (_sessionData[sessionId]!['stepCount'] as int) + 1;
    }

    updateSessionActivity(sessionId);
  }

  void stopSessionMonitoring(String sessionId) {
    _stopInactivityTimer(sessionId);
    _stopAbandonmentTimer(sessionId);
    _lastActivity.remove(sessionId);
    _sessionData.remove(sessionId);
  }

  // Inactivity detection
  void _startInactivityTimer(String sessionId) {
    _sessionTimers['inactivity_$sessionId'] = Timer(
      _inactivityThreshold,
      () => _handleInactivity(sessionId),
    );
  }

  void _restartInactivityTimer(String sessionId) {
    _stopInactivityTimer(sessionId);
    _startInactivityTimer(sessionId);
  }

  void _stopInactivityTimer(String sessionId) {
    _sessionTimers['inactivity_$sessionId']?.cancel();
    _sessionTimers.remove('inactivity_$sessionId');
  }

  Future<void> _handleInactivity(String sessionId) async {
    try {
      // Check if session is actually inactive
      final lastActivity = _lastActivity[sessionId];
      if (lastActivity == null) return;

      final inactivityDuration = DateTime.now().difference(lastActivity);
      if (inactivityDuration >= _inactivityThreshold) {
        await _handleAbandonment(sessionId, 'inactivity');
      }
    } catch (e) {
      // Log error but don't fail
      print('Error handling inactivity: $e');
    }
  }

  // Abandonment detection
  void _startAbandonmentTimer(String sessionId) {
    _sessionTimers['abandonment_$sessionId'] = Timer.periodic(
      const Duration(minutes: 1),
      (timer) => _checkAbandonment(sessionId),
    );
  }

  void _stopAbandonmentTimer(String sessionId) {
    _sessionTimers['abandonment_$sessionId']?.cancel();
    _sessionTimers.remove('abandonment_$sessionId');
  }

  Future<void> _checkAbandonment(String sessionId) async {
    try {
      final sessionData = _sessionData[sessionId];
      if (sessionData == null) return;

      final startTime = DateTime.parse(sessionData['startTime']);
      final sessionDuration = DateTime.now().difference(startTime);

      // Check for long-running sessions
      if (sessionDuration >= _abandonmentThreshold) {
        final abandonmentReason = _analyzeAbandonmentReason(sessionId, sessionData);
        await _handleAbandonment(sessionId, abandonmentReason);
      }

      // Check for suspicious patterns
      if (_detectSuspiciousPattern(sessionData)) {
        await _handleSuspiciousActivity(sessionId);
      }
    } catch (e) {
      // Log error but don't fail
      print('Error checking abandonment: $e');
    }
  }

  String _analyzeAbandonmentReason(String sessionId, Map<String, dynamic> sessionData) {
    final startTime = DateTime.parse(sessionData['startTime']);
    final lastStepTime = DateTime.parse(sessionData['lastStepTime']);
    final sessionDuration = DateTime.now().difference(startTime);
    final stepInactivity = DateTime.now().difference(lastStepTime);

    // Check for specific abandonment patterns
    if (stepInactivity.inMinutes >= 15) {
      return 'extended_step_inactivity';
    }

    if (sessionData['stepCount'] == 0) {
      return 'no_progress_made';
    }

    if (sessionData['currentStep'] == 'paymentMethod') {
      return 'payment_step_abandonment';
    }

    if (sessionData['currentStep'] == 'shippingAddress') {
      return 'shipping_step_abandonment';
    }

    // Default reason
    return 'general_inactivity';
  }

  bool _detectSuspiciousPattern(Map<String, dynamic> sessionData) {
    final stepCount = sessionData['stepCount'] as int;
    final startTime = DateTime.parse(sessionData['startTime']);
    final sessionDuration = DateTime.now().difference(startTime);

    // Check for rapid step progression followed by abandonment
    if (stepCount > 3 && sessionDuration.inMinutes < 3) {
      return true;
    }

    // Check for repeated step switching
    if (sessionData.containsKey('stepSwitches')) {
      final stepSwitches = sessionData['stepSwitches'] as int;
      if (stepSwitches > 5) {
        return true;
      }
    }

    return false;
  }

  Future<void> _handleAbandonment(String sessionId, String reason) async {
    try {
      // Stop monitoring
      stopSessionMonitoring(sessionId);

      // Get session data for analytics
      final sessionData = _sessionData[sessionId];
      if (sessionData != null) {
        // Track abandonment analytics
        await _trackAbandonmentAnalytics(sessionId, reason, sessionData);

        // Log abandonment event
        auditService.logSessionAbandonment(
          userId: sessionData['userId'],
          reason: reason,
          lastStep: _parseStepType(sessionData['currentStep']),
        );

        // Trigger abandonment recovery if applicable
        if (_shouldTriggerRecovery(sessionData, reason)) {
          await _triggerRecoveryMechanism(sessionId, sessionData);
        }
      }

      // Mark session as abandoned remotely
      await remoteDataSource.trackAbandonment(
        sessionId: sessionId,
        reason: reason,
      );
    } catch (e) {
      // Log error but don't fail
      print('Error handling abandonment: $e');
    }
  }

  Future<void> _handleSuspiciousActivity(String sessionId) async {
    try {
      final sessionData = _sessionData[sessionId];
      if (sessionData != null) {
        // Log security event
        auditService.logSecurityEvent(
          securityEventType: SecurityEventType.abandonment,
          description: 'Suspicious checkout activity detected',
          userId: sessionData['userId'],
          details: {
            'sessionId': sessionId,
            'reason': 'suspicious_pattern',
            'sessionData': sessionData,
          },
          severity: AuditSeverity.warning,
        );

        // Could trigger additional security measures
        // like session lockout or manual review
      }
    } catch (e) {
      print('Error handling suspicious activity: $e');
    }
  }

  bool _shouldTriggerRecovery(Map<String, dynamic> sessionData, String reason) {
    // Only trigger recovery for certain types of abandonment
    final recoverableReasons = [
      'inactivity',
      'general_inactivity',
      'extended_step_inactivity',
    ];

    if (!recoverableReasons.contains(reason)) {
      return false;
    }

    // Only trigger if user made some progress
    final stepCount = sessionData['stepCount'] as int;
    return stepCount > 0;
  }

  Future<void> _triggerRecoveryMechanism(String sessionId, Map<String, dynamic> sessionData) async {
    try {
      // Schedule recovery notification
      await _scheduleRecoveryNotification(sessionId, sessionData);

      // Store recovery data
      await _storeRecoveryData(sessionId, sessionData);

      // Log recovery initiation
      auditService.logSessionRecovery(
        userId: sessionData['userId'],
        recoveryMethod: 'automated',
        successful: false, // Not yet successful
      );
    } catch (e) {
      print('Error triggering recovery mechanism: $e');
    }
  }

  Future<void> _scheduleRecoveryNotification(String sessionId, Map<String, dynamic> sessionData) async {
    // This would integrate with a notification service
    // For now, we'll just log the intent
    print('Scheduling recovery notification for session: $sessionId');
  }

  Future<void> _storeRecoveryData(String sessionId, Map<String, dynamic> sessionData) async {
    // Store recovery data locally for later use
    final recoveryData = {
      'sessionId': sessionId,
      'userId': sessionData['userId'],
      'recoveryToken': const Uuid().v4(),
      'timestamp': DateTime.now().toIso8601String(),
      'sessionData': sessionData,
      'recoveryAttempts': 0,
    };

    // This would be stored in a secure local database
    print('Storing recovery data: $recoveryData');
  }

  Future<void> _trackAbandonmentAnalytics(
    String sessionId,
    String reason,
    Map<String, dynamic> sessionData,
  ) async {
    try {
      final analyticsData = {
        'sessionId': sessionId,
        'reason': reason,
        'userId': sessionData['userId'],
        'isGuest': sessionData['isGuest'],
        'sessionDuration': DateTime.now().difference(DateTime.parse(sessionData['startTime'])).inSeconds,
        'stepsCompleted': sessionData['stepCount'],
        'currentStep': sessionData['currentStep'],
        'orderValue': sessionData['orderValue'],
        'timestamp': DateTime.now().toIso8601String(),
      };

      // This would be sent to analytics service
      print('Abandonment analytics: $analyticsData');
    } catch (e) {
      print('Error tracking abandonment analytics: $e');
    }
  }

  // Recovery methods
  Future<bool> attemptSessionRecovery(String sessionId, String recoveryToken) async {
    try {
      // Verify recovery token
      final isValid = await _verifyRecoveryToken(sessionId, recoveryToken);
      if (!isValid) {
        return false;
      }

      // Get session data
      final sessionData = await _getRecoveryData(sessionId);
      if (sessionData == null) {
        return false;
      }

      // Attempt to resume session
      final result = await remoteDataSource.resumeSession(sessionId);

      if (result.isRight()) {
        // Log successful recovery
        auditService.logSessionRecovery(
          userId: sessionData['userId'],
          recoveryMethod: 'token_based',
          successful: true,
        );

        // Clear recovery data
        await _clearRecoveryData(sessionId);

        return true;
      }

      return false;
    } catch (e) {
      print('Error attempting session recovery: $e');
      return false;
    }
  }

  Future<bool> _verifyRecoveryToken(String sessionId, String recoveryToken) async {
    // This would verify the recovery token against stored data
    // For now, return true as a placeholder
    return true;
  }

  Future<Map<String, dynamic>?> _getRecoveryData(String sessionId) async {
    // This would retrieve recovery data from secure storage
    // For now, return null as a placeholder
    return null;
  }

  Future<void> _clearRecoveryData(String sessionId) async {
    // This would clear recovery data from secure storage
    print('Clearing recovery data for session: $sessionId');
  }

  // Cleanup methods
  Future<void> cleanupExpiredRecoveryData() async {
    try {
      final cutoffTime = DateTime.now().subtract(const Duration(days: 7));
      // This would clean up recovery data older than 7 days
      print('Cleaning up recovery data older than: $cutoffTime');
    } catch (e) {
      print('Error cleaning up recovery data: $e');
    }
  }

  // Utility methods
  CheckoutStepType? _parseStepType(String stepName) {
    try {
      return CheckoutStepType.values.byName(stepName);
    } catch (e) {
      return null;
    }
  }

  // Get abandonment statistics
  Map<String, dynamic> getAbandonmentStats() {
    final totalSessions = _sessionData.length;
    final activeSessions = _lastActivity.length;
    final abandonedSessions = _sessionTimers.length - activeSessions;

    return {
      'totalSessions': totalSessions,
      'activeSessions': activeSessions,
      'abandonedSessions': abandonedSessions,
      'abandonmentRate': totalSessions > 0 ? (abandonedSessions / totalSessions) * 100 : 0.0,
    };
  }

  // Force abandonment for testing
  Future<void> forceAbandonment(String sessionId, String reason) async {
    await _handleAbandonment(sessionId, reason);
  }

  void dispose() {
    // Clean up all timers
    for (final timer in _sessionTimers.values) {
      timer.cancel();
    }
    _sessionTimers.clear();
    _lastActivity.clear();
    _sessionData.clear();
  }
}