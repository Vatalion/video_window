import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/session_model.dart';
import '../../domain/models/session_activity_model.dart';
import '../../domain/models/device_model.dart';
import '../../../core/errors/exceptions.dart';

class SessionMonitoringService {
  final FlutterSecureStorage _secureStorage;
  final Map<String, Timer> _monitoringTimers = {};
  final Map<String, List<SessionActivityModel>> _recentActivities = {};

  SessionMonitoringService(this._secureStorage);

  static const String _monitoringKey = 'session_monitoring_';
  static const String _alertsKey = 'session_alerts_';
  static const Duration _monitoringInterval = const Duration(minutes: 5);
  static const Duration _suspiciousActivityWindow = const Duration(hours: 1);
  static const int _maxRecentActivities = 100;

  Future<void> startMonitoring(String sessionId) async {
    _monitoringTimers[sessionId]?.cancel();
    _monitoringTimers[sessionId] = Timer.periodic(_monitoringInterval, (
      timer,
    ) async {
      await _performHealthCheck(sessionId);
    });
  }

  Future<void> stopMonitoring(String sessionId) async {
    _monitoringTimers[sessionId]?.cancel();
    _monitoringTimers.remove(sessionId);
    _recentActivities.remove(sessionId);
  }

  Future<void> _performHealthCheck(String sessionId) async {
    try {
      final session = await _getSession(sessionId);
      if (session == null) return;

      await _checkForSuspiciousActivity(sessionId);
      await _validateSessionIntegrity(session);
      await _checkForResourceAbuse(sessionId);
      await _cleanupOldMonitoringData(sessionId);

      await _logMonitoringActivity(
        sessionId: sessionId,
        userId: session.userId,
        checkType: 'health_check',
        success: true,
      );
    } catch (e) {
      await _handleMonitoringFailure(sessionId, e);
    }
  }

  Future<void> _checkForSuspiciousActivity(String sessionId) async {
    final activities = await _getRecentActivities(sessionId);
    if (activities.isEmpty) return;

    final now = DateTime.now();
    final recentActivities = activities
        .where((a) => now.difference(a.timestamp) < _suspiciousActivityWindow)
        .toList();

    await _detectFailedLoginAttempts(sessionId, recentActivities);
    await _detectUnusualActivityPatterns(sessionId, recentActivities);
    await _detectMultipleDeviceAccess(sessionId, recentActivities);
  }

  Future<void> _detectFailedLoginAttempts(
    String sessionId,
    List<SessionActivityModel> activities,
  ) async {
    final failedAttempts = activities
        .where(
          (a) =>
              a.activityType == ActivityType.failedLogin && a.success == false,
        )
        .toList();

    if (failedAttempts.length >= 3) {
      await _createSecurityAlert(
        sessionId: sessionId,
        alertType: 'multiple_failed_logins',
        severity: 'high',
        message: 'Multiple failed login attempts detected',
        metadata: {
          'failed_attempts': failedAttempts.length,
          'time_window': _suspiciousActivityWindow.inMinutes,
        },
      );
    }
  }

  Future<void> _detectUnusualActivityPatterns(
    String sessionId,
    List<SessionActivityModel> activities,
  ) async {
    final activityTypes = activities.map((a) => a.activityType).toSet();
    final highRiskActivities = activities
        .where((a) => a.isSecurityEvent)
        .length;

    if (highRiskActivities >= 2) {
      await _createSecurityAlert(
        sessionId: sessionId,
        alertType: 'unusual_activity_pattern',
        severity: 'medium',
        message: 'Unusual activity pattern detected',
        metadata: {
          'high_risk_activities': highRiskActivities,
          'activity_types': activityTypes.map((e) => e.name).toList(),
        },
      );
    }
  }

  Future<void> _detectMultipleDeviceAccess(
    String sessionId,
    List<SessionActivityModel> activities,
  ) async {
    final uniqueDevices = activities.map((a) => a.ipAddress).toSet();

    if (uniqueDevices.length >= 3) {
      await _createSecurityAlert(
        sessionId: sessionId,
        alertType: 'multiple_device_access',
        severity: 'medium',
        message: 'Access from multiple devices detected',
        metadata: {
          'unique_devices': uniqueDevices.length,
          'device_ips': uniqueDevices.toList(),
        },
      );
    }
  }

  Future<void> _validateSessionIntegrity(SessionModel session) async {
    if (session.isLockedDueToFailures) {
      await _createSecurityAlert(
        sessionId: session.id,
        alertType: 'session_locked',
        severity: 'high',
        message: 'Session locked due to multiple failures',
        metadata: {
          'consecutive_failures': session.consecutiveFailures,
          'locked_until': session.lockedUntil?.toIso8601String(),
        },
      );
    }

    if (session.isTimeout) {
      await _createSecurityAlert(
        sessionId: session.id,
        alertType: 'session_timeout',
        severity: 'low',
        message: 'Session timed out due to inactivity',
        metadata: {
          'timeout_duration': session.timeoutDuration.inMinutes,
          'last_activity': session.lastActivity.toIso8601String(),
        },
      );
    }
  }

  Future<void> _checkForResourceAbuse(String sessionId) async {
    final activities = await _getRecentActivities(sessionId);
    final now = DateTime.now();
    final recentActivities = activities
        .where((a) => now.difference(a.timestamp) < const Duration(minutes: 15))
        .toList();

    final dataAccessCount = recentActivities
        .where((a) => a.activityType == ActivityType.dataAccess)
        .length;
    final settingsChangeCount = recentActivities
        .where((a) => a.activityType == ActivityType.settingsChange)
        .length;

    if (dataAccessCount > 20) {
      await _createSecurityAlert(
        sessionId: sessionId,
        alertType: 'excessive_data_access',
        severity: 'medium',
        message: 'Excessive data access detected',
        metadata: {
          'access_count': dataAccessCount,
          'time_window': '15 minutes',
        },
      );
    }

    if (settingsChangeCount > 10) {
      await _createSecurityAlert(
        sessionId: sessionId,
        alertType: 'excessive_settings_changes',
        severity: 'medium',
        message: 'Excessive settings changes detected',
        metadata: {
          'change_count': settingsChangeCount,
          'time_window': '15 minutes',
        },
      );
    }
  }

  Future<void> _createSecurityAlert({
    required String sessionId,
    required String alertType,
    required String severity,
    required String message,
    Map<String, dynamic> metadata = const {},
  }) async {
    final alert = {
      'id': const Uuid().v4(),
      'session_id': sessionId,
      'alert_type': alertType,
      'severity': severity,
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
      'metadata': metadata,
      'resolved': false,
    };

    final alertKey = 'alert_${alert['id']}';
    await _secureStorage.write(key: alertKey, value: json.encode(alert));

    await _triggerAlertActions(sessionId, alertType, severity, message);
  }

  Future<void> _triggerAlertActions(
    String sessionId,
    String alertType,
    String severity,
    String message,
  ) async {
    switch (severity) {
      case 'high':
        await _handleHighSeverityAlert(sessionId, alertType);
        break;
      case 'medium':
        await _handleMediumSeverityAlert(sessionId, alertType);
        break;
      case 'low':
        await _handleLowSeverityAlert(sessionId, alertType);
        break;
    }
  }

  Future<void> _handleHighSeverityAlert(
    String sessionId,
    String alertType,
  ) async {
    switch (alertType) {
      case 'multiple_failed_logins':
      case 'session_locked':
        await _terminateSessionIfNecessary(sessionId);
        break;
    }
  }

  Future<void> _handleMediumSeverityAlert(
    String sessionId,
    String alertType,
  ) async {
    await _logSecurityEvent(sessionId, alertType, 'medium');
  }

  Future<void> _handleLowSeverityAlert(
    String sessionId,
    String alertType,
  ) async {
    await _logSecurityEvent(sessionId, alertType, 'low');
  }

  Future<void> _terminateSessionIfNecessary(String sessionId) async {
    final session = await _getSession(sessionId);
    if (session != null &&
        (session.isLockedDueToFailures || session.consecutiveFailures >= 5)) {
      await _updateSessionStatus(sessionId, SessionStatus.suspended);
    }
  }

  Future<void> _updateSessionStatus(
    String sessionId,
    SessionStatus status,
  ) async {
    final session = await _getSession(sessionId);
    if (session != null) {
      final updatedSession = session.copyWith(status: status);
      await _storeSession(updatedSession);
    }
  }

  Future<void> _logSecurityEvent(
    String sessionId,
    String alertType,
    String severity,
  ) async {
    final session = await _getSession(sessionId);
    if (session != null) {
      await _logActivity(
        sessionId: sessionId,
        userId: session.userId,
        activityType: ActivityType.securityAlert,
        description: 'Security alert: $alertType ($severity)',
        isSecurityEvent: true,
        securityImpact: _getSecurityImpact(severity),
      );
    }
  }

  SecurityImpact _getSecurityImpact(String severity) {
    switch (severity) {
      case 'high':
        return SecurityImpact.high;
      case 'medium':
        return SecurityImpact.medium;
      case 'low':
        return SecurityImpact.low;
      default:
        return SecurityImpact.none;
    }
  }

  Future<void> _logActivity({
    required String sessionId,
    required String userId,
    required ActivityType activityType,
    String? description,
    bool isSecurityEvent = false,
    SecurityImpact securityImpact = SecurityImpact.none,
  }) async {
    final activity = SessionActivityModel.create(
      sessionId: sessionId,
      userId: userId,
      activityType: activityType,
      description: description,
      isSecurityEvent: isSecurityEvent,
      securityImpact: securityImpact,
    );

    await _storeActivity(activity);
  }

  Future<void> _logMonitoringActivity({
    required String sessionId,
    required String userId,
    required String checkType,
    required bool success,
    String? error,
  }) async {
    final activity = SessionActivityModel.create(
      sessionId: sessionId,
      userId: userId,
      activityType: ActivityType.settingsChange,
      description: 'Monitoring check: $checkType',
      success: success,
      errorMessage: error,
      metadata: {
        'check_type': checkType,
        'monitoring_timestamp': DateTime.now().toIso8601String(),
      },
    );

    await _storeActivity(activity);
  }

  Future<void> _storeActivity(SessionActivityModel activity) async {
    final activityKey = 'activity_${activity.id}';
    await _secureStorage.write(
      key: activityKey,
      value: json.encode(activity.toJson()),
    );
  }

  Future<void> _handleMonitoringFailure(String sessionId, dynamic error) async {
    await _logMonitoringActivity(
      sessionId: sessionId,
      userId: 'unknown',
      checkType: 'health_check',
      success: false,
      error: error.toString(),
    );
  }

  Future<SessionModel?> _getSession(String sessionId) async {
    final sessionKey = 'session_$sessionId';
    final sessionData = await _secureStorage.read(key: sessionKey);

    if (sessionData == null) return null;

    try {
      return SessionModel.fromJson(
        Map<String, dynamic>.from(json.decode(sessionData)),
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> _storeSession(SessionModel session) async {
    final sessionKey = 'session_${session.id}';
    await _secureStorage.write(
      key: sessionKey,
      value: json.encode(session.toJson()),
    );
  }

  Future<List<SessionActivityModel>> _getRecentActivities(
    String sessionId,
  ) async {
    if (!_recentActivities.containsKey(sessionId)) {
      _recentActivities[sessionId] = [];
    }

    return _recentActivities[sessionId]!;
  }

  Future<void> _cleanupOldMonitoringData(String sessionId) async {
    final activities = await _getRecentActivities(sessionId);
    final now = DateTime.now();

    _recentActivities[sessionId] = activities
        .where((a) => now.difference(a.timestamp) < const Duration(hours: 24))
        .toList();

    if (_recentActivities[sessionId]!.length > _maxRecentActivities) {
      _recentActivities[sessionId] = _recentActivities[sessionId]!
          .take(_maxRecentActivities)
          .toList();
    }

    await _cleanupOldAlerts(sessionId);
  }

  Future<void> _cleanupOldAlerts(String sessionId) async {
    final allKeys = await _secureStorage.readAll();
    final now = DateTime.now();

    for (final key in allKeys.keys) {
      if (key.startsWith('alert_')) {
        try {
          final alertData = allKeys[key];
          if (alertData != null) {
            final alert = json.decode(alertData);
            final timestamp = DateTime.parse(alert['timestamp']);

            if (now.difference(timestamp) > const Duration(days: 7)) {
              await _secureStorage.delete(key: key);
            }
          }
        } catch (e) {
          continue;
        }
      }
    }
  }

  Future<List<Map<String, dynamic>>> getSecurityAlerts(String sessionId) async {
    final alerts = <Map<String, dynamic>>[];
    final allKeys = await _secureStorage.readAll();

    for (final key in allKeys.keys) {
      if (key.startsWith('alert_')) {
        try {
          final alertData = allKeys[key];
          if (alertData != null) {
            final alert = json.decode(alertData);
            if (alert['session_id'] == sessionId) {
              alerts.add(Map<String, dynamic>.from(alert));
            }
          }
        } catch (e) {
          continue;
        }
      }
    }

    return alerts..sort(
      (a, b) => DateTime.parse(
        b['timestamp'],
      ).compareTo(DateTime.parse(a['timestamp'])),
    );
  }

  Future<void> clearMonitoringData(String sessionId) async {
    await stopMonitoring(sessionId);
    await _cleanupOldAlerts(sessionId);
    await _secureStorage.delete(key: _monitoringKey + sessionId);
  }

  void dispose() {
    for (final timer in _monitoringTimers.values) {
      timer.cancel();
    }
    _monitoringTimers.clear();
    _recentActivities.clear();
  }
}
