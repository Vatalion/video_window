import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/security/security_audit_log.dart';
import '../../models/security/security_alert.dart';

class SecurityAuditService {
  static const String _auditLogKey = 'security_audit_logs';
  static const String _maxLogEntries = 'max_log_entries';
  static const int _defaultMaxEntries = 10000;
  static const int _retentionDays = 90;

  final SharedPreferences _prefs;
  final List<SecurityAuditLog> _logs = [];
  final Random _random = Random();

  SecurityAuditService(this._prefs) {
    _loadLogs();
  }

  void _loadLogs() {
    final logsJson = _prefs.getStringList(_auditLogKey) ?? [];
    _logs.addAll(
      logsJson.map((json) => SecurityAuditLog.fromJson(jsonDecode(json))),
    );
  }

  Future<void> _saveLogs() async {
    final maxEntries = _prefs.getInt(_maxLogEntries) ?? _defaultMaxEntries;

    // Apply retention policy
    final cutoffDate = DateTime.now().subtract(Duration(days: _retentionDays));
    _logs.removeWhere((log) => log.timestamp.isBefore(cutoffDate));

    // Limit total entries
    if (_logs.length > maxEntries) {
      _logs.removeRange(0, _logs.length - maxEntries);
    }

    final logsJson = _logs.map((log) => jsonEncode(log.toJson())).toList();
    await _prefs.setStringList(_auditLogKey, logsJson);
  }

  Future<void> logSecurityEvent({
    required String userId,
    required SecurityEventType eventType,
    required String ipAddress,
    required String userAgent,
    required String deviceId,
    double riskScore = 0.0,
    Map<String, dynamic> eventDetails = const {},
    String? sessionId,
  }) async {
    final log = SecurityAuditLog(
      id: _generateId(),
      userId: userId,
      eventType: eventType.name,
      timestamp: DateTime.now(),
      ipAddress: ipAddress,
      userAgent: userAgent,
      deviceId: deviceId,
      riskScore: riskScore,
      eventDetails: _encryptData(eventDetails),
      sessionId: sessionId,
    );

    _logs.add(log);
    await _saveLogs();

    // Check for suspicious activity
    await _analyzeForSuspiciousActivity(log);
  }

  String _generateId() {
    return 'audit_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(10000)}';
  }

  Map<String, dynamic> _encryptData(Map<String, dynamic> data) {
    // Simple encryption for demo purposes
    // In production, use proper encryption libraries
    final jsonString = jsonEncode(data);
    final bytes = utf8.encode(jsonString);
    final hash = sha256.convert(bytes).toString();
    return {
      'encrypted': true,
      'hash': hash,
      'timestamp': DateTime.now().toIso8601String(),
      'original_size': jsonString.length,
    };
  }

  Future<void> _analyzeForSuspiciousActivity(SecurityAuditLog log) async {
    // Simple anomaly detection - can be enhanced with ML models
    final recentLogs = _logs
        .where((l) =>
            l.userId == log.userId &&
            l.timestamp.isAfter(DateTime.now().subtract(const Duration(hours: 1))))
        .toList();

    // Check for multiple failed login attempts
    if (log.eventType == SecurityEventType.login.name) {
      final failedAttempts = recentLogs
          .where((l) => l.eventType == 'failed_login')
          .length;

      if (failedAttempts >= 3) {
        await _createSecurityAlert(
          userId: log.userId,
          alertType: AlertType.multipleFailedAttempts,
          message: 'Multiple failed login attempts detected',
          severity: 0.8,
          alertDetails: {
            'attempts': failedAttempts,
            'time_window': '1 hour',
            'ip_address': log.ipAddress,
          },
        );
      }
    }

    // Check for unusual login locations
    final uniqueLocations = recentLogs
        .map((l) => l.ipAddress)
        .toSet()
        .length;

    if (uniqueLocations >= 3) {
      await _createSecurityAlert(
        userId: log.userId,
        alertType: AlertType.unusualLoginLocation,
        message: 'Login detected from multiple locations',
        severity: 0.7,
        alertDetails: {
          'unique_locations': uniqueLocations,
          'time_window': '1 hour',
        },
      );
    }
  }

  Future<void> _createSecurityAlert({
    required String userId,
    required AlertType alertType,
    required String message,
    required double severity,
    required Map<String, dynamic> alertDetails,
  }) async {
    // This would integrate with a notification service
    debugPrint('Security Alert: $message for user $userId');
  }

  List<SecurityAuditLog> getAuditLogs({
    String? userId,
    SecurityEventType? eventType,
    DateTime? startDate,
    DateTime? endDate,
    double? minRiskScore,
    int limit = 100,
  }) {
    var filteredLogs = _logs;

    if (userId != null) {
      filteredLogs = filteredLogs.where((log) => log.userId == userId).toList();
    }

    if (eventType != null) {
      filteredLogs = filteredLogs.where((log) => log.eventType == eventType.name).toList();
    }

    if (startDate != null) {
      filteredLogs = filteredLogs.where((log) => log.timestamp.isAfter(startDate)).toList();
    }

    if (endDate != null) {
      filteredLogs = filteredLogs.where((log) => log.timestamp.isBefore(endDate)).toList();
    }

    if (minRiskScore != null) {
      filteredLogs = filteredLogs.where((log) => log.riskScore >= minRiskScore).toList();
    }

    // Sort by timestamp descending
    filteredLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return filteredLogs.take(limit).toList();
  }

  Map<String, int> getEventStatistics({String? userId}) {
    final logs = userId != null
        ? _logs.where((log) => log.userId == userId).toList()
        : _logs;

    final stats = <String, int>{};
    for (final log in logs) {
      stats[log.eventType] = (stats[log.eventType] ?? 0) + 1;
    }

    return stats;
  }

  Future<void> clearOldLogs() async {
    final cutoffDate = DateTime.now().subtract(Duration(days: _retentionDays));
    _logs.removeWhere((log) => log.timestamp.isBefore(cutoffDate));
    await _saveLogs();
  }

  Future<void> setMaxLogEntries(int maxEntries) async {
    await _prefs.setInt(_maxLogEntries, maxEntries);
    await _saveLogs();
  }

  int getLogCount({String? userId}) {
    return userId != null
        ? _logs.where((log) => log.userId == userId).length
        : _logs.length;
  }
}