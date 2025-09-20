import 'package:flutter/material.dart';
import '../../models/security/security_alert.dart';

class SecurityNotificationService {
  final List<Function(SecurityAlert)> _alertListeners = [];
  final List<SecurityAlert> _activeAlerts = [];

  void addAlertListener(Function(SecurityAlert) listener) {
    _alertListeners.add(listener);
  }

  void removeAlertListener(Function(SecurityAlert) listener) {
    _alertListeners.remove(listener);
  }

  Future<void> sendSecurityAlert(SecurityAlert alert) async {
    _activeAlerts.add(alert);

    // Notify all listeners
    for (final listener in _alertListeners) {
      try {
        listener(alert);
      } catch (e) {
        debugPrint('Error notifying alert listener: $e');
      }
    }

    // Send email notification
    await _sendEmailNotification(alert);

    // Send push notification
    await _sendPushNotification(alert);
  }

  Future<void> _sendEmailNotification(SecurityAlert alert) async {
    // In production, integrate with email service
    debugPrint('📧 Email Alert: ${alert.message} for user ${alert.userId}');

    // Simulate email sending
    await Future.delayed(const Duration(milliseconds: 100));
  }

  Future<void> _sendPushNotification(SecurityAlert alert) async {
    // In production, integrate with push notification service
    debugPrint('📱 Push Alert: ${alert.message} for user ${alert.userId}');

    // Simulate push notification
    await Future.delayed(const Duration(milliseconds: 100));
  }

  List<SecurityAlert> getActiveAlerts({String? userId}) {
    return userId != null
        ? _activeAlerts.where((alert) => alert.userId == userId).toList()
        : List.from(_activeAlerts);
  }

  Future<void> acknowledgeAlert(String alertId, String acknowledgedBy) async {
    final alert = _activeAlerts.firstWhere(
      (a) => a.id == alertId,
      orElse: () => throw Exception('Alert not found'),
    );

    alert.acknowledge(acknowledgedBy);

    // Remove from active alerts
    _activeAlerts.removeWhere((a) => a.id == alertId);
  }

  Future<void> dismissAlert(String alertId, String dismissedBy) async {
    final alert = _activeAlerts.firstWhere(
      (a) => a.id == alertId,
      orElse: () => throw Exception('Alert not found'),
    );

    alert.status = AlertStatus.dismissed;
    _activeAlerts.removeWhere((a) => a.id == alertId);
  }

  Future<void> markAsFalsePositive(String alertId, String markedBy) async {
    final alert = _activeAlerts.firstWhere(
      (a) => a.id == alertId,
      orElse: () => throw Exception('Alert not found'),
    );

    alert.status = AlertStatus.falsePositive;
    _activeAlerts.removeWhere((a) => a.id == alertId);
  }
}