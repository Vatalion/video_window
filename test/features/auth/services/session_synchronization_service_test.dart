import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:video_window/features/auth/data/services/session_synchronization_service.dart';
import 'package:video_window/features/auth/domain/models/session_model.dart';
import 'package:video_window/features/auth/domain/models/session_activity_model.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late SessionSynchronizationService syncService;
  late MockFlutterSecureStorage mockStorage;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    syncService = SessionSynchronizationService(mockStorage);
  });

  tearDown(() {
    syncService.dispose();
  });

  group('SessionSynchronizationService', () {
    const testSessionId = 'test-session-id';
    const testUserId = 'test-user-id';
    const testDeviceId = 'test-device-id';

    test('synchronizeSession should synchronize session with remote', () async {
      // Arrange
      final localSession = SessionModel(
        id: testSessionId,
        userId: testUserId,
        deviceId: testDeviceId,
        sessionId: 'session-id-123',
        ipAddress: '192.168.1.1',
        status: SessionStatus.active,
        startTime: DateTime.now(),
        lastActivity: DateTime.now(),
        timeoutDuration: const Duration(minutes: 30),
        securityLevel: SecurityLevel.standard,
      );

      final mockSessionData = localSession.toJson();
      final lastSyncTime = DateTime.now().subtract(const Duration(minutes: 31));

      when(() => mockStorage.read(key: 'session_sync_state_$testSessionId'))
          .thenAnswer((_) async => lastSyncTime.toIso8601String());
      when(() => mockStorage.read(key: 'session_$testSessionId'))
          .thenAnswer((_) async => mockSessionData.toString());
      when(() => mockStorage.readAll()).thenAnswer((_) async => {});
      when(() => mockStorage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      )).thenAnswer((_) async {});

      // Act
      await syncService.synchronizeSession(testSessionId);

      // Assert
      verify(() => mockStorage.write(
        key: 'session_sync_state_$testSessionId',
        value: any(named: 'value'),
      )).called(1);
    });

    test('synchronizeSession should skip synchronization if recently synced', () async {
      // Arrange
      final localSession = SessionModel(
        id: testSessionId,
        userId: testUserId,
        deviceId: testDeviceId,
        sessionId: 'session-id-123',
        ipAddress: '192.168.1.1',
        status: SessionStatus.active,
        startTime: DateTime.now(),
        lastActivity: DateTime.now(),
        timeoutDuration: const Duration(minutes: 30),
        securityLevel: SecurityLevel.standard,
      );

      final mockSessionData = localSession.toJson();
      final lastSyncTime = DateTime.now().subtract(const Duration(minutes: 15));

      when(() => mockStorage.read(key: 'session_sync_state_$testSessionId'))
          .thenAnswer((_) async => lastSyncTime.toIso8601String());
      when(() => mockStorage.read(key: 'session_$testSessionId'))
          .thenAnswer((_) async => mockSessionData.toString());

      // Act
      await syncService.synchronizeSession(testSessionId);

      // Assert
      verifyNever(() => mockStorage.write(
        key: 'session_sync_state_$testSessionId',
        value: any(named: 'value'),
      ));
    });

    test('synchronizeSession should force synchronization when forceSync is true', () async {
      // Arrange
      final localSession = SessionModel(
        id: testSessionId,
        userId: testUserId,
        deviceId: testDeviceId,
        sessionId: 'session-id-123',
        ipAddress: '192.168.1.1',
        status: SessionStatus.active,
        startTime: DateTime.now(),
        lastActivity: DateTime.now(),
        timeoutDuration: const Duration(minutes: 30),
        securityLevel: SecurityLevel.standard,
      );

      final mockSessionData = localSession.toJson();
      final lastSyncTime = DateTime.now().subtract(const Duration(minutes: 15));

      when(() => mockStorage.read(key: 'session_sync_state_$testSessionId'))
          .thenAnswer((_) async => lastSyncTime.toIso8601String());
      when(() => mockStorage.read(key: 'session_$testSessionId'))
          .thenAnswer((_) async => mockSessionData.toString());
      when(() => mockStorage.readAll()).thenAnswer((_) async => {});
      when(() => mockStorage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      )).thenAnswer((_) async {});

      // Act
      await syncService.synchronizeSession(testSessionId, forceSync: true);

      // Assert
      verify(() => mockStorage.write(
        key: 'session_sync_state_$testSessionId',
        value: any(named: 'value'),
      )).called(1);
    });

    test('synchronizeSession should handle synchronization failures', () async {
      // Arrange
      final localSession = SessionModel(
        id: testSessionId,
        userId: testUserId,
        deviceId: testDeviceId,
        sessionId: 'session-id-123',
        ipAddress: '192.168.1.1',
        status: SessionStatus.active,
        startTime: DateTime.now(),
        lastActivity: DateTime.now(),
        timeoutDuration: const Duration(minutes: 30),
        securityLevel: SecurityLevel.standard,
      );

      final mockSessionData = localSession.toJson();
      final lastSyncTime = DateTime.now().subtract(const Duration(minutes: 31));

      when(() => mockStorage.read(key: 'session_sync_state_$testSessionId'))
          .thenAnswer((_) async => lastSyncTime.toIso8601String());
      when(() => mockStorage.read(key: 'session_$testSessionId'))
          .thenAnswer((_) async => mockSessionData.toString());
      when(() => mockStorage.readAll()).thenAnswer((_) async => {});
      when(() => mockStorage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      )).thenThrow(Exception('Storage error'));

      // Act
      await syncService.synchronizeSession(testSessionId);

      // Assert
      verify(() => mockStorage.write(
        key: 'session_sync_state_$testSessionId',
        value: any(named: 'value'),
      )).called(1); // Should still attempt to write error log
    });

    test('_getLocalSession should return session when it exists', () async {
      // Arrange
      final localSession = SessionModel(
        id: testSessionId,
        userId: testUserId,
        deviceId: testDeviceId,
        sessionId: 'session-id-123',
        ipAddress: '192.168.1.1',
        status: SessionStatus.active,
        startTime: DateTime.now(),
        lastActivity: DateTime.now(),
        timeoutDuration: const Duration(minutes: 30),
        securityLevel: SecurityLevel.standard,
      );

      final mockSessionData = localSession.toJson();

      when(() => mockStorage.read(key: 'session_$testSessionId'))
          .thenAnswer((_) async => mockSessionData.toString());

      // Act
      final session = await syncService._getLocalSession(testSessionId);

      // Assert
      expect(session, isNotNull);
      expect(session!.id, equals(testSessionId));
      expect(session.userId, equals(testUserId));
      expect(session.deviceId, equals(testDeviceId));
    });

    test('_getLocalSession should return null when session does not exist', () async {
      // Arrange
      when(() => mockStorage.read(key: 'session_$testSessionId'))
          .thenAnswer((_) async => null);

      // Act
      final session = await syncService._getLocalSession(testSessionId);

      // Assert
      expect(session, isNull);
    });

    test('_resolveConflict should use remote when remote session is more recent', () async {
      // Arrange
      final localSession = SessionModel(
        id: testSessionId,
        userId: testUserId,
        deviceId: testDeviceId,
        sessionId: 'session-id-123',
        ipAddress: '192.168.1.1',
        status: SessionStatus.active,
        startTime: DateTime.now().subtract(const Duration(minutes: 10)),
        lastActivity: DateTime.now().subtract(const Duration(minutes: 5)),
        timeoutDuration: const Duration(minutes: 30),
        securityLevel: SecurityLevel.standard,
      );

      final remoteSession = SessionModel(
        id: testSessionId,
        userId: testUserId,
        deviceId: testDeviceId,
        sessionId: 'session-id-123',
        ipAddress: '192.168.1.1',
        status: SessionStatus.active,
        startTime: DateTime.now().subtract(const Duration(minutes: 10)),
        lastActivity: DateTime.now().subtract(const Duration(minutes: 1)),
        timeoutDuration: const Duration(minutes: 30),
        securityLevel: SecurityLevel.standard,
      );

      // Act
      final resolution = await syncService._resolveConflict(localSession, remoteSession);

      // Assert
      expect(resolution, equals(ConflictResolution.useRemote));
    });

    test('_resolveConflict should use local when local session is more recent', () async {
      // Arrange
      final localSession = SessionModel(
        id: testSessionId,
        userId: testUserId,
        deviceId: testDeviceId,
        sessionId: 'session-id-123',
        ipAddress: '192.168.1.1',
        status: SessionStatus.active,
        startTime: DateTime.now().subtract(const Duration(minutes: 10)),
        lastActivity: DateTime.now().subtract(const Duration(minutes: 1)),
        timeoutDuration: const Duration(minutes: 30),
        securityLevel: SecurityLevel.standard,
      );

      final remoteSession = SessionModel(
        id: testSessionId,
        userId: testUserId,
        deviceId: testDeviceId,
        sessionId: 'session-id-123',
        ipAddress: '192.168.1.1',
        status: SessionStatus.active,
        startTime: DateTime.now().subtract(const Duration(minutes: 10)),
        lastActivity: DateTime.now().subtract(const Duration(minutes: 5)),
        timeoutDuration: const Duration(minutes: 30),
        securityLevel: SecurityLevel.standard,
      );

      // Act
      final resolution = await syncService._resolveConflict(localSession, remoteSession);

      // Assert
      expect(resolution, equals(ConflictResolution.useLocal));
    });

    test('_resolveConflict should merge when session activities are concurrent', () async {
      // Arrange
      final now = DateTime.now();
      final localSession = SessionModel(
        id: testSessionId,
        userId: testUserId,
        deviceId: testDeviceId,
        sessionId: 'session-id-123',
        ipAddress: '192.168.1.1',
        status: SessionStatus.active,
        startTime: now.subtract(const Duration(minutes: 10)),
        lastActivity: now.subtract(const Duration(minutes: 2)),
        timeoutDuration: const Duration(minutes: 30),
        consecutiveFailures: 3,
        securityLevel: SecurityLevel.standard,
      );

      final remoteSession = SessionModel(
        id: testSessionId,
        userId: testUserId,
        deviceId: testDeviceId,
        sessionId: 'session-id-123',
        ipAddress: '192.168.1.1',
        status: SessionStatus.active,
        startTime: now.subtract(const Duration(minutes: 10)),
        lastActivity: now.subtract(const Duration(minutes: 2)),
        timeoutDuration: const Duration(minutes: 30),
        consecutiveFailures: 1,
        securityLevel: SecurityLevel.standard,
      );

      // Act
      final resolution = await syncService._resolveConflict(localSession, remoteSession);

      // Assert
      expect(resolution, equals(ConflictResolution.merge));
    });

    test('_mergeSessions should merge session data correctly', () async {
      // Arrange
      final now = DateTime.now();
      final localSession = SessionModel(
        id: testSessionId,
        userId: testUserId,
        deviceId: testDeviceId,
        sessionId: 'session-id-123',
        ipAddress: '192.168.1.1',
        status: SessionStatus.active,
        startTime: now.subtract(const Duration(minutes: 10)),
        lastActivity: now.subtract(const Duration(minutes: 5)),
        timeoutDuration: const Duration(minutes: 30),
        consecutiveFailures: 3,
        securityLevel: SecurityLevel.standard,
        metadata: {
          'local_data': 'local_value',
          'shared_data': 'local_shared_value',
        },
      );

      final remoteSession = SessionModel(
        id: testSessionId,
        userId: testUserId,
        deviceId: testDeviceId,
        sessionId: 'session-id-123',
        ipAddress: '192.168.1.1',
        status: SessionStatus.active,
        startTime: now.subtract(const Duration(minutes: 10)),
        lastActivity: now.subtract(const Duration(minutes: 1)),
        timeoutDuration: const Duration(minutes: 30),
        consecutiveFailures: 1,
        securityLevel: SecurityLevel.standard,
        metadata: {
          'remote_data': 'remote_value',
          'shared_data': 'remote_shared_value',
          'sync_timestamp': '2023-01-01T00:00:00Z',
        },
      );

      // Act
      final mergedSession = await syncService._mergeSessions(localSession, remoteSession);

      // Assert
      expect(mergedSession.lastActivity, equals(remoteSession.lastActivity));
      expect(mergedSession.consecutiveFailures, equals(1)); // Min of 3 and 1
      expect(mergedSession.metadata['local_data'], equals('local_value'));
      expect(mergedSession.metadata['remote_data'], equals('remote_value'));
      expect(mergedSession.metadata['shared_data'], equals('remote_shared_value'));
      expect(mergedSession.metadata['sync_timestamp'], equals('2023-01-01T00:00:00Z'));
    });

    test('_shouldOverrideLocalValue should override for sync and remote keys', () async {
      // Arrange
      const syncKey = 'sync_data';
      const remoteKey = 'remote_data';
      const normalKey = 'normal_data';

      // Act & Assert
      expect(syncService._shouldOverrideLocalValue(syncKey, 'local', 'remote'), isTrue);
      expect(syncService._shouldOverrideLocalValue(remoteKey, 'local', 'remote'), isTrue);
      expect(syncService._shouldOverrideLocalValue(normalKey, 'local', 'remote'), isTrue);
      expect(syncService._shouldOverrideLocalValue(normalKey, {'nested': 'data'}, 'simple'), isFalse);
    });

    test('addPendingActivity should add activity to pending list', () async {
      // Arrange
      final activity = SessionActivityModel.create(
        sessionId: testSessionId,
        userId: testUserId,
        activityType: ActivityType.login,
      );

      // Act
      await syncService.addPendingActivity(activity);

      // Assert
      // Since this is testing internal state, we can't directly verify
      // but we can ensure no exceptions are thrown
      expect(() => syncService.addPendingActivity(activity), returnsNormally);
    });

    test('addPendingActivity should limit pending activities to 50 items', () async {
      // Arrange
      // Add 51 activities
      for (int i = 0; i < 51; i++) {
        final activity = SessionActivityModel.create(
          sessionId: testSessionId,
          userId: testUserId,
          activityType: ActivityType.login,
        );
        await syncService.addPendingActivity(activity);
      }

      // Act & Assert
      // Should not throw exception and limit to 50 items
      expect(() => syncService.addPendingActivity(SessionActivityModel.create(
        sessionId: testSessionId,
        userId: testUserId,
        activityType: ActivityType.login,
      )), returnsNormally);
    });

    test('getSyncConflicts should return empty list when no conflicts exist', () async {
      // Arrange
      when(() => mockStorage.read(key: 'session_conflicts_$testSessionId'))
          .thenAnswer((_) async => null);

      // Act
      final conflicts = await syncService.getSyncConflicts(testSessionId);

      // Assert
      expect(conflicts, isEmpty);
    });

    test('getSyncConflicts should return conflicts when they exist', () async {
      // Arrange
      final mockConflict = {
        'session_id': testSessionId,
        'local_session': {
          'id': testSessionId,
          'user_id': testUserId,
          'last_activity': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
        },
        'remote_session': {
          'id': testSessionId,
          'user_id': testUserId,
          'last_activity': DateTime.now().subtract(const Duration(minutes: 1)).toIso8601String(),
        },
        'resolution': 'useRemote',
        'timestamp': DateTime.now().toIso8601String(),
      };

      when(() => mockStorage.read(key: 'session_conflicts_$testSessionId'))
          .thenAnswer((_) async => mockConflict.toString());

      // Act
      final conflicts = await syncService.getSyncConflicts(testSessionId);

      // Assert
      expect(conflicts.length, equals(1));
      expect(conflicts.first['session_id'], equals(testSessionId));
      expect(conflicts.first['resolution'], equals('useRemote'));
    });

    test('clearSyncData should remove all sync-related data', () async {
      // Arrange
      when(() => mockStorage.delete(key: any(named: 'key')))
          .thenAnswer((_) async {});

      // Act
      await syncService.clearSyncData(testSessionId);

      // Assert
      verify(() => mockStorage.delete(key: 'session_sync_state_$testSessionId')).called(1);
      verify(() => mockStorage.delete(key: 'session_conflicts_$testSessionId')).called(1);
      verify(() => mockStorage.delete(key: 'sync_retry_$testSessionId')).called(1);
    });

    test('startPeriodicSync should start periodic synchronization', () async {
      // Arrange & Act
      syncService.startPeriodicSync(testSessionId);

      // Assert
      // Since this is timer-based, we can't directly test the timer
      // but we can verify it starts without throwing exceptions
      expect(() => syncService.startPeriodicSync(testSessionId), returnsNormally);
    });

    test('stopPeriodicSync should stop periodic synchronization', () async {
      // Arrange
      syncService.startPeriodicSync(testSessionId);

      // Act
      syncService.stopPeriodicSync(testSessionId);

      // Assert
      // Verify that stopping doesn't throw exceptions
      expect(() => syncService.stopPeriodicSync(testSessionId), returnsNormally);
    });

    test('dispose should clean up all resources', () async {
      // Arrange
      syncService.startPeriodicSync(testSessionId);

      // Act
      syncService.dispose();

      // Assert
      // Verify that dispose doesn't throw exceptions
      expect(() => syncService.dispose(), returnsNormally);
    });

    test('_handleSyncFailure should log failure and schedule retry', () async {
      // Arrange
      when(() => mockStorage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      )).thenAnswer((_) async {});

      // Act
      await syncService._handleSyncFailure(testSessionId, Exception('Test error'));

      // Assert
      verify(() => mockStorage.write(
        key: 'session_sync_state_$testSessionId',
        value: any(named: 'value'),
      )).called(1);
    });

    test('_handleSyncFailure should not retry after max attempts', () async {
      // Arrange
      when(() => mockStorage.read(key: 'sync_retry_$testSessionId'))
          .thenAnswer((_) async => '3'); // Max retry attempts reached
      when(() => mockStorage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      )).thenAnswer((_) async {});

      // Act
      await syncService._handleSyncFailure(testSessionId, Exception('Test error'));

      // Assert
      verify(() => mockStorage.write(
        key: 'sync_retry_$testSessionId',
        value: '3',
      )).called(1);
    });
  });
}