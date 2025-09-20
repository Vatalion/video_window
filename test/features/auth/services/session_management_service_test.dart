import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:video_window/features/auth/data/services/session_management_service.dart';
import 'package:video_window/features/auth/data/services/jwt_token_service.dart';
import 'package:video_window/features/auth/domain/models/session_model.dart';
import 'package:video_window/features/auth/domain/models/session_activity_model.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

class MockJwtTokenService extends Mock implements JwtTokenService {}

void main() {
  late SessionManagementService sessionService;
  late MockFlutterSecureStorage mockStorage;
  late MockJwtTokenService mockJwtService;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    mockJwtService = MockJwtTokenService();
    sessionService = SessionManagementService(mockStorage, mockJwtService);
  });

  group('SessionManagementService', () {
    const testUserId = 'test-user-id';
    const testDeviceId = 'test-device-id';
    const testIpAddress = '192.168.1.1';
    const testUserAgent = 'Test User Agent';
    const testLocation = 'Test Location';

    test('createSession should create and store a new session', () async {
      // Arrange
      when(() => mockStorage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      )).thenAnswer((_) async {});

      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);

      // Act
      final session = await sessionService.createSession(
        userId: testUserId,
        deviceId: testDeviceId,
        ipAddress: testIpAddress,
        userAgent: testUserAgent,
        location: testLocation,
      );

      // Assert
      expect(session.userId, equals(testUserId));
      expect(session.deviceId, equals(testDeviceId));
      expect(session.ipAddress, equals(testIpAddress));
      expect(session.userAgent, equals(testUserAgent));
      expect(session.location, equals(testLocation));
      expect(session.status, equals(SessionStatus.active));
      expect(session.isTimeout, isFalse);
      expect(session.consecutiveFailures, equals(0));
      expect(session.isLocked, isFalse);
    });

    test('getCurrentSession should return current session when it exists', () async {
      // Arrange
      const currentSessionId = 'current-session-id';
      final mockSessionData = {
        'id': 'test-session-id',
        'user_id': testUserId,
        'device_id': testDeviceId,
        'session_id': 'session-id-123',
        'ip_address': testIpAddress,
        'user_agent': testUserAgent,
        'location': testLocation,
        'status': 'active',
        'start_time': DateTime.now().toIso8601String(),
        'end_time': null,
        'last_activity': DateTime.now().toIso8601String(),
        'timeout_minutes': 30,
        'is_persistent': false,
        'session_fingerprint': null,
        'metadata': {},
        'consecutive_failures': 0,
        'is_locked': false,
        'locked_until': null,
        'security_level': 'standard',
      };

      when(() => mockStorage.read(key: 'current_session_id'))
          .thenAnswer((_) async => currentSessionId);
      when(() => mockStorage.read(key: 'session_$currentSessionId'))
          .thenAnswer((_) async => mockSessionData.toString());

      // Act
      final session = await sessionService.getCurrentSession();

      // Assert
      expect(session, isNotNull);
      expect(session!.userId, equals(testUserId));
      expect(session.deviceId, equals(testDeviceId));
    });

    test('getCurrentSession should return null when no current session exists', () async {
      // Arrange
      when(() => mockStorage.read(key: 'current_session_id'))
          .thenAnswer((_) async => null);

      // Act
      final session = await sessionService.getCurrentSession();

      // Assert
      expect(session, isNull);
    });

    test('getUserSessions should return all active sessions for a user', () async {
      // Arrange
      final mockSessionData1 = {
        'id': 'session-1',
        'user_id': testUserId,
        'device_id': testDeviceId,
        'session_id': 'session-id-1',
        'ip_address': testIpAddress,
        'status': 'active',
        'start_time': DateTime.now().toIso8601String(),
        'last_activity': DateTime.now().toIso8601String(),
        'timeout_minutes': 30,
        'is_persistent': false,
        'metadata': {},
        'consecutive_failures': 0,
        'is_locked': false,
        'security_level': 'standard',
      };

      final mockSessionData2 = {
        'id': 'session-2',
        'user_id': 'other-user-id',
        'device_id': testDeviceId,
        'session_id': 'session-id-2',
        'ip_address': testIpAddress,
        'status': 'active',
        'start_time': DateTime.now().toIso8601String(),
        'last_activity': DateTime.now().toIso8601String(),
        'timeout_minutes': 30,
        'is_persistent': false,
        'metadata': {},
        'consecutive_failures': 0,
        'is_locked': false,
        'security_level': 'standard',
      };

      when(() => mockStorage.readAll()).thenAnswer((_) async => {
        'session_session-1': mockSessionData1.toString(),
        'session_session-2': mockSessionData2.toString(),
      });

      // Act
      final sessions = await sessionService.getUserSessions(testUserId);

      // Assert
      expect(sessions.length, equals(1));
      expect(sessions.first.userId, equals(testUserId));
    });

    test('updateSessionActivity should update last activity timestamp', () async {
      // Arrange
      const sessionId = 'test-session-id';
      final initialTime = DateTime.now().subtract(const Duration(minutes: 5));

      final mockSessionData = {
        'id': sessionId,
        'user_id': testUserId,
        'device_id': testDeviceId,
        'session_id': 'session-id-123',
        'ip_address': testIpAddress,
        'status': 'active',
        'start_time': initialTime.toIso8601String(),
        'last_activity': initialTime.toIso8601String(),
        'timeout_minutes': 30,
        'is_persistent': false,
        'metadata': {},
        'consecutive_failures': 0,
        'is_locked': false,
        'security_level': 'standard',
      };

      when(() => mockStorage.read(key: 'session_$sessionId'))
          .thenAnswer((_) async => mockSessionData.toString());
      when(() => mockStorage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      )).thenAnswer((_) async {});

      // Act
      final updatedSession = await sessionService.updateSessionActivity(sessionId);

      // Assert
      expect(updatedSession.lastActivity.isAfter(initialTime), isTrue);
    });

    test('terminateSession should mark session as terminated', () async {
      // Arrange
      const sessionId = 'test-session-id';

      final mockSessionData = {
        'id': sessionId,
        'user_id': testUserId,
        'device_id': testDeviceId,
        'session_id': 'session-id-123',
        'ip_address': testIpAddress,
        'status': 'active',
        'start_time': DateTime.now().toIso8601String(),
        'last_activity': DateTime.now().toIso8601String(),
        'timeout_minutes': 30,
        'is_persistent': false,
        'metadata': {},
        'consecutive_failures': 0,
        'is_locked': false,
        'security_level': 'standard',
      };

      when(() => mockStorage.read(key: 'session_$sessionId'))
          .thenAnswer((_) async => mockSessionData.toString());
      when(() => mockStorage.read(key: 'current_session_id'))
          .thenAnswer((_) async => sessionId);
      when(() => mockStorage.delete(key: any(named: 'key')))
          .thenAnswer((_) async {});
      when(() => mockStorage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      )).thenAnswer((_) async {});

      // Act
      final terminatedSession = await sessionService.terminateSession(sessionId);

      // Assert
      expect(terminatedSession.status, equals(SessionStatus.terminated));
      expect(terminatedSession.endTime, isNotNull);
    });

    test('handleFailedLogin should increment consecutive failures', () async {
      // Arrange
      const sessionId = 'test-session-id';

      final mockSessionData = {
        'id': sessionId,
        'user_id': testUserId,
        'device_id': testDeviceId,
        'session_id': 'session-id-123',
        'ip_address': testIpAddress,
        'status': 'active',
        'start_time': DateTime.now().toIso8601String(),
        'last_activity': DateTime.now().toIso8601String(),
        'timeout_minutes': 30,
        'is_persistent': false,
        'metadata': {},
        'consecutive_failures': 2,
        'is_locked': false,
        'security_level': 'standard',
      };

      when(() => mockStorage.read(key: 'session_$sessionId'))
          .thenAnswer((_) async => mockSessionData.toString());
      when(() => mockStorage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      )).thenAnswer((_) async {});

      // Act
      final updatedSession = await sessionService.handleFailedLogin(sessionId);

      // Assert
      expect(updatedSession.consecutiveFailures, equals(3));
    });

    test('handleFailedLogin should lock session after 5 failures', () async {
      // Arrange
      const sessionId = 'test-session-id';

      final mockSessionData = {
        'id': sessionId,
        'user_id': testUserId,
        'device_id': testDeviceId,
        'session_id': 'session-id-123',
        'ip_address': testIpAddress,
        'status': 'active',
        'start_time': DateTime.now().toIso8601String(),
        'last_activity': DateTime.now().toIso8601String(),
        'timeout_minutes': 30,
        'is_persistent': false,
        'metadata': {},
        'consecutive_failures': 4,
        'is_locked': false,
        'security_level': 'standard',
      };

      when(() => mockStorage.read(key: 'session_$sessionId'))
          .thenAnswer((_) async => mockSessionData.toString());
      when(() => mockStorage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      )).thenAnswer((_) async {});

      // Act
      final updatedSession = await sessionService.handleFailedLogin(sessionId);

      // Assert
      expect(updatedSession.consecutiveFailures, equals(5));
      expect(updatedSession.isLocked, isTrue);
      expect(updatedSession.lockedUntil, isNotNull);
    });

    test('resetSessionFailures should reset consecutive failures to 0', () async {
      // Arrange
      const sessionId = 'test-session-id';

      final mockSessionData = {
        'id': sessionId,
        'user_id': testUserId,
        'device_id': testDeviceId,
        'session_id': 'session-id-123',
        'ip_address': testIpAddress,
        'status': 'active',
        'start_time': DateTime.now().toIso8601String(),
        'last_activity': DateTime.now().toIso8601String(),
        'timeout_minutes': 30,
        'is_persistent': false,
        'metadata': {},
        'consecutive_failures': 3,
        'is_locked': true,
        'locked_until': DateTime.now().add(const Duration(minutes: 30)).toIso8601String(),
        'security_level': 'standard',
      };

      when(() => mockStorage.read(key: 'session_$sessionId'))
          .thenAnswer((_) async => mockSessionData.toString());
      when(() => mockStorage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      )).thenAnswer((_) async {});

      // Act
      final resetSession = await sessionService.resetSessionFailures(sessionId);

      // Assert
      expect(resetSession.consecutiveFailures, equals(0));
      expect(resetSession.isLocked, isFalse);
      expect(resetSession.lockedUntil, isNull);
    });

    test('isSessionValid should return true for active, non-timeout session', () async {
      // Arrange
      const sessionId = 'test-session-id';

      final mockSessionData = {
        'id': sessionId,
        'user_id': testUserId,
        'device_id': testDeviceId,
        'session_id': 'session-id-123',
        'ip_address': testIpAddress,
        'status': 'active',
        'start_time': DateTime.now().toIso8601String(),
        'last_activity': DateTime.now().toIso8601String(),
        'timeout_minutes': 30,
        'is_persistent': false,
        'metadata': {},
        'consecutive_failures': 0,
        'is_locked': false,
        'security_level': 'standard',
      };

      when(() => mockStorage.read(key: 'session_$sessionId'))
          .thenAnswer((_) async => mockSessionData.toString());

      // Act
      final isValid = await sessionService.isSessionValid(sessionId);

      // Assert
      expect(isValid, isTrue);
    });

    test('isSessionValid should return false for terminated session', () async {
      // Arrange
      const sessionId = 'test-session-id';

      final mockSessionData = {
        'id': sessionId,
        'user_id': testUserId,
        'device_id': testDeviceId,
        'session_id': 'session-id-123',
        'ip_address': testIpAddress,
        'status': 'terminated',
        'start_time': DateTime.now().toIso8601String(),
        'last_activity': DateTime.now().toIso8601String(),
        'timeout_minutes': 30,
        'is_persistent': false,
        'metadata': {},
        'consecutive_failures': 0,
        'is_locked': false,
        'security_level': 'standard',
      };

      when(() => mockStorage.read(key: 'session_$sessionId'))
          .thenAnswer((_) async => mockSessionData.toString());

      // Act
      final isValid = await sessionService.isSessionValid(sessionId);

      // Assert
      expect(isValid, isFalse);
    });

    test('getSessionActivities should return activities for a session', () async {
      // Arrange
      const sessionId = 'test-session-id';
      final mockActivityData = {
        'id': 'activity-1',
        'session_id': sessionId,
        'user_id': testUserId,
        'activity_type': 'login',
        'timestamp': DateTime.now().toIso8601String(),
        'metadata': {},
        'is_security_event': false,
        'security_impact': 'none',
        'success': true,
      };

      when(() => mockStorage.readAll()).thenAnswer((_) async => {
        'activity_activity-1': mockActivityData.toString(),
      });

      // Act
      final activities = await sessionService.getSessionActivities(sessionId);

      // Assert
      expect(activities.length, equals(1));
      expect(activities.first.sessionId, equals(sessionId));
    });

    test('cleanupExpiredSessions should remove expired sessions', () async {
      // Arrange
      const sessionId = 'expired-session-id';
      final expiredTime = DateTime.now().subtract(const Duration(days: 1));

      final mockSessionData = {
        'id': sessionId,
        'user_id': testUserId,
        'device_id': testDeviceId,
        'session_id': 'session-id-123',
        'ip_address': testIpAddress,
        'status': 'expired',
        'start_time': expiredTime.toIso8601String(),
        'end_time': expiredTime.toIso8601String(),
        'last_activity': expiredTime.toIso8601String(),
        'timeout_minutes': 30,
        'is_persistent': false,
        'metadata': {},
        'consecutive_failures': 0,
        'is_locked': false,
        'security_level': 'standard',
      };

      when(() => mockStorage.readAll()).thenAnswer((_) async => {
        'session_$sessionId': mockSessionData.toString(),
      });
      when(() => mockStorage.delete(key: any(named: 'key')))
          .thenAnswer((_) async {});

      // Act
      await sessionService.cleanupExpiredSessions();

      // Assert
      verify(() => mockStorage.delete(key: 'session_$sessionId')).called(1);
    });
  });
}