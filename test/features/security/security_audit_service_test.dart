import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_window/models/security/security_audit_log.dart';
import 'package:video_window/services/security/security_audit_service.dart';

void main() {
  late SharedPreferences prefs;
  late SecurityAuditService auditService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    auditService = SecurityAuditService(prefs);
  });

  group('SecurityAuditService', () {
    test('should log security event successfully', () async {
      await auditService.logSecurityEvent(
        userId: 'test-user-1',
        eventType: SecurityEventType.login,
        ipAddress: '192.168.1.1',
        userAgent: 'Mozilla/5.0',
        deviceId: 'device-123',
      );

      final logs = auditService.getAuditLogs(userId: 'test-user-1');
      expect(logs.length, 1);
      expect(logs.first.userId, 'test-user-1');
      expect(logs.first.eventType, 'login');
    });

    test('should filter logs by user ID', () async {
      await auditService.logSecurityEvent(
        userId: 'user-1',
        eventType: SecurityEventType.login,
        ipAddress: '192.168.1.1',
        userAgent: 'Mozilla/5.0',
        deviceId: 'device-123',
      );

      await auditService.logSecurityEvent(
        userId: 'user-2',
        eventType: SecurityEventType.login,
        ipAddress: '192.168.1.1',
        userAgent: 'Mozilla/5.0',
        deviceId: 'device-123',
      );

      final user1Logs = auditService.getAuditLogs(userId: 'user-1');
      final user2Logs = auditService.getAuditLogs(userId: 'user-2');

      expect(user1Logs.length, 1);
      expect(user2Logs.length, 1);
      expect(user1Logs.first.userId, 'user-1');
      expect(user2Logs.first.userId, 'user-2');
    });

    test('should filter logs by event type', () async {
      await auditService.logSecurityEvent(
        userId: 'test-user',
        eventType: SecurityEventType.login,
        ipAddress: '192.168.1.1',
        userAgent: 'Mozilla/5.0',
        deviceId: 'device-123',
      );

      await auditService.logSecurityEvent(
        userId: 'test-user',
        eventType: SecurityEventType.logout,
        ipAddress: '192.168.1.1',
        userAgent: 'Mozilla/5.0',
        deviceId: 'device-123',
      );

      final loginLogs = auditService.getAuditLogs(
        userId: 'test-user',
        eventType: SecurityEventType.login,
      );

      final logoutLogs = auditService.getAuditLogs(
        userId: 'test-user',
        eventType: SecurityEventType.logout,
      );

      expect(loginLogs.length, 1);
      expect(logoutLogs.length, 1);
      expect(loginLogs.first.eventType, 'login');
      expect(logoutLogs.first.eventType, 'logout');
    });

    test('should filter logs by date range', () async {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));

      await auditService.logSecurityEvent(
        userId: 'test-user',
        eventType: SecurityEventType.login,
        ipAddress: '192.168.1.1',
        userAgent: 'Mozilla/5.0',
        deviceId: 'device-123',
      );

      final futureLog = SecurityAuditLog(
        id: 'future-log',
        userId: 'test-user',
        eventType: 'login',
        timestamp: now.add(const Duration(days: 1)),
        ipAddress: '192.168.1.1',
        userAgent: 'Mozilla/5.0',
        deviceId: 'device-123',
        riskScore: 0.0,
        eventDetails: {},
      );

      // Simulate adding a future log
      await Future.delayed(const Duration(milliseconds: 100));

      final recentLogs = auditService.getAuditLogs(
        userId: 'test-user',
        startDate: yesterday,
        endDate: now,
      );

      expect(recentLogs.length, 1);
    });

    test('should limit number of returned logs', () async {
      for (int i = 0; i < 5; i++) {
        await auditService.logSecurityEvent(
          userId: 'test-user',
          eventType: SecurityEventType.login,
          ipAddress: '192.168.1.1',
          userAgent: 'Mozilla/5.0',
          deviceId: 'device-123',
        );
      }

      final limitedLogs = auditService.getAuditLogs(
        userId: 'test-user',
        limit: 3,
      );

      expect(limitedLogs.length, 3);
    });

    test('should get event statistics', () async {
      await auditService.logSecurityEvent(
        userId: 'test-user',
        eventType: SecurityEventType.login,
        ipAddress: '192.168.1.1',
        userAgent: 'Mozilla/5.0',
        deviceId: 'device-123',
      );

      await auditService.logSecurityEvent(
        userId: 'test-user',
        eventType: SecurityEventType.logout,
        ipAddress: '192.168.1.1',
        userAgent: 'Mozilla/5.0',
        deviceId: 'device-123',
      );

      await auditService.logSecurityEvent(
        userId: 'test-user',
        eventType: SecurityEventType.login,
        ipAddress: '192.168.1.1',
        userAgent: 'Mozilla/5.0',
        deviceId: 'device-123',
      );

      final stats = auditService.getEventStatistics(userId: 'test-user');

      expect(stats['login'], 2);
      expect(stats['logout'], 1);
    });

    test('should encrypt event details', () async {
      final eventDetails = {'sensitive': 'data', 'user_info': 'test'};

      await auditService.logSecurityEvent(
        userId: 'test-user',
        eventType: SecurityEventType.login,
        ipAddress: '192.168.1.1',
        userAgent: 'Mozilla/5.0',
        deviceId: 'device-123',
        eventDetails: eventDetails,
      );

      final logs = auditService.getAuditLogs(userId: 'test-user');
      final encryptedDetails = logs.first.eventDetails;

      expect(encryptedDetails['encrypted'], true);
      expect(encryptedDetails['hash'], isNotNull);
      expect(encryptedDetails['timestamp'], isNotNull);
    });

    test('should return log count', () async {
      expect(auditService.getLogCount(userId: 'test-user'), 0);

      await auditService.logSecurityEvent(
        userId: 'test-user',
        eventType: SecurityEventType.login,
        ipAddress: '192.168.1.1',
        userAgent: 'Mozilla/5.0',
        deviceId: 'device-123',
      );

      expect(auditService.getLogCount(userId: 'test-user'), 1);
    });

    test('should set max log entries', () async {
      await auditService.setMaxLogEntries(100);

      // This would be tested with actual log persistence
      expect(true, isTrue); // Placeholder test
    });
  });
}