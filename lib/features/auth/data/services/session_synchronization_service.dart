import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/session_model.dart';
import '../../domain/models/session_activity_model.dart';
import '../../domain/models/device_model.dart';
import '../../../core/errors/exceptions.dart';

class SessionSynchronizationService {
  final FlutterSecureStorage _secureStorage;
  final Map<String, Timer> _syncTimers = {};
  final Map<String, List<SessionActivityModel>> _pendingActivities = {};

  SessionSynchronizationService(this._secureStorage);

  static const String _syncStateKey = 'session_sync_state_';
  static const String _conflictKey = 'session_conflicts_';
  static const Duration _syncInterval = const Duration(seconds: 30);
  static const int _maxRetryAttempts = 3;

  Future<void> synchronizeSession(
    String sessionId, {
    bool forceSync = false,
  }) async {
    try {
      final lastSyncTime = await _getLastSyncTime(sessionId);
      final now = DateTime.now();

      if (!forceSync &&
          lastSyncTime != null &&
          now.difference(lastSyncTime) < _syncInterval) {
        return;
      }

      final localSession = await _getLocalSession(sessionId);
      if (localSession == null) return;

      final remoteSession = await _fetchRemoteSession(sessionId);

      if (remoteSession != null) {
        await _handleSessionConflict(localSession, remoteSession);
      } else {
        await _pushSessionToRemote(localSession);
      }

      await _synchronizePendingActivities(sessionId);
      await _updateLastSyncTime(sessionId);

      await _logSyncActivity(
        sessionId: sessionId,
        userId: localSession.userId,
        success: true,
        syncType: 'full_sync',
      );
    } catch (e) {
      await _handleSyncFailure(sessionId, e);
    }
  }

  Future<SessionModel?> _getLocalSession(String sessionId) async {
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

  Future<SessionModel?> _fetchRemoteSession(String sessionId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _handleSessionConflict(
    SessionModel localSession,
    SessionModel remoteSession,
  ) async {
    final conflictResolution = await _resolveConflict(
      localSession,
      remoteSession,
    );

    if (conflictResolution == ConflictResolution.useRemote) {
      await _updateLocalSession(remoteSession);
    } else if (conflictResolution == ConflictResolution.useLocal) {
      await _pushSessionToRemote(localSession);
    } else {
      final mergedSession = await _mergeSessions(localSession, remoteSession);
      await _updateLocalSession(mergedSession);
      await _pushSessionToRemote(mergedSession);
    }

    await _recordConflict(
      sessionId,
      localSession,
      remoteSession,
      conflictResolution,
    );
  }

  Future<ConflictResolution> _resolveConflict(
    SessionModel local,
    SessionModel remote,
  ) async {
    if (remote.lastActivity.isAfter(local.lastActivity)) {
      return ConflictResolution.useRemote;
    } else if (local.lastActivity.isAfter(remote.lastActivity)) {
      return ConflictResolution.useLocal;
    } else {
      return ConflictResolution.merge;
    }
  }

  Future<SessionModel> _mergeSessions(
    SessionModel local,
    SessionModel remote,
  ) async {
    final mergedSession = local.copyWith(
      lastActivity: remote.lastActivity.isAfter(local.lastActivity)
          ? remote.lastActivity
          : local.lastActivity,
      consecutiveFailures: min(
        local.consecutiveFailures,
        remote.consecutiveFailures,
      ),
      metadata: _mergeMetadata(local.metadata, remote.metadata),
    );

    return mergedSession;
  }

  Map<String, dynamic> _mergeMetadata(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) {
    final merged = Map<String, dynamic>.from(local);

    for (final key in remote.keys) {
      if (!merged.containsKey(key) ||
          _shouldOverrideLocalValue(key, local[key], remote[key])) {
        merged[key] = remote[key];
      }
    }

    return merged;
  }

  bool _shouldOverrideLocalValue(
    String key,
    dynamic localValue,
    dynamic remoteValue,
  ) {
    if (key.startsWith('sync_')) return true;
    if (key.startsWith('remote_')) return true;

    if (remoteValue is Map && localValue is Map) {
      return false;
    }

    return true;
  }

  Future<void> _updateLocalSession(SessionModel session) async {
    final sessionKey = 'session_${session.id}';
    await _secureStorage.write(
      key: sessionKey,
      value: json.encode(session.toJson()),
    );
  }

  Future<void> _pushSessionToRemote(SessionModel session) async {
    try {
      await Future.delayed(const Duration(milliseconds: 50));
    } catch (e) {
      throw SyncException('Failed to push session to remote: ${e.toString()}');
    }
  }

  Future<void> _synchronizePendingActivities(String sessionId) async {
    final pending = _pendingActivities[sessionId] ?? [];
    if (pending.isEmpty) return;

    final successfulActivities = <SessionActivityModel>[];
    final failedActivities = <SessionActivityModel>[];

    for (final activity in pending) {
      try {
        await _pushActivityToRemote(activity);
        successfulActivities.add(activity);
      } catch (e) {
        failedActivities.add(activity);
      }
    }

    _pendingActivities[sessionId] = failedActivities;

    for (final activity in successfulActivities) {
      await _markActivityAsSynced(activity.id);
    }
  }

  Future<void> _pushActivityToRemote(SessionActivityModel activity) async {
    try {
      await Future.delayed(const Duration(milliseconds: 30));
    } catch (e) {
      throw SyncException('Failed to sync activity: ${e.toString()}');
    }
  }

  Future<void> _markActivityAsSynced(String activityId) async {
    final syncedKey = 'activity_synced_$activityId';
    await _secureStorage.write(
      key: syncedKey,
      value: DateTime.now().toIso8601String(),
    );
  }

  Future<void> _recordConflict(
    String sessionId,
    SessionModel localSession,
    SessionModel remoteSession,
    ConflictResolution resolution,
  ) async {
    final conflictData = {
      'session_id': sessionId,
      'local_session': localSession.toJson(),
      'remote_session': remoteSession.toJson(),
      'resolution': resolution.name,
      'timestamp': DateTime.now().toIso8601String(),
    };

    final conflictKey = _conflictKey + sessionId;
    await _secureStorage.write(
      key: conflictKey,
      value: json.encode(conflictData),
    );
  }

  Future<void> _updateLastSyncTime(String sessionId) async {
    final syncKey = _syncStateKey + sessionId;
    await _secureStorage.write(
      key: syncKey,
      value: DateTime.now().toIso8601String(),
    );
  }

  Future<DateTime?> _getLastSyncTime(String sessionId) async {
    final syncKey = _syncStateKey + sessionId;
    final syncData = await _secureStorage.read(key: syncKey);

    if (syncData == null) return null;

    try {
      return DateTime.parse(syncData);
    } catch (e) {
      return null;
    }
  }

  Future<void> _logSyncActivity({
    required String sessionId,
    required String userId,
    required bool success,
    required String syncType,
    String? error,
  }) async {
    final activity = SessionActivityModel.create(
      sessionId: sessionId,
      userId: userId,
      activityType: ActivityType.settingsChange,
      description: 'Session $syncType ${success ? 'successful' : 'failed'}',
      success: success,
      errorMessage: error,
      metadata: {
        'sync_type': syncType,
        'sync_timestamp': DateTime.now().toIso8601String(),
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

  Future<void> _handleSyncFailure(String sessionId, dynamic error) async {
    await _logSyncActivity(
      sessionId: sessionId,
      userId: 'unknown',
      success: false,
      syncType: 'sync_error',
      error: error.toString(),
    );

    final retryCount = await _getSyncRetryCount(sessionId);
    if (retryCount < _maxRetryAttempts) {
      await _incrementSyncRetryCount(sessionId);
      await _scheduleRetrySync(sessionId);
    }
  }

  Future<int> _getSyncRetryCount(String sessionId) async {
    final retryKey = 'sync_retry_$sessionId';
    final retryData = await _secureStorage.read(key: retryKey);
    return retryData != null ? int.parse(retryData) : 0;
  }

  Future<void> _incrementSyncRetryCount(String sessionId) async {
    final retryKey = 'sync_retry_$sessionId';
    final currentCount = await _getSyncRetryCount(sessionId);
    await _secureStorage.write(
      key: retryKey,
      value: (currentCount + 1).toString(),
    );
  }

  Future<void> _scheduleRetrySync(String sessionId) async {
    final delay = Duration(
      seconds: pow(2, await _getSyncRetryCount(sessionId)) as int,
    );

    _syncTimers[sessionId]?.cancel();
    _syncTimers[sessionId] = Timer(delay, () async {
      await synchronizeSession(sessionId);
    });
  }

  void startPeriodicSync(String sessionId) {
    _syncTimers[sessionId]?.cancel();
    _syncTimers[sessionId] = Timer.periodic(_syncInterval, (timer) async {
      await synchronizeSession(sessionId);
    });
  }

  void stopPeriodicSync(String sessionId) {
    _syncTimers[sessionId]?.cancel();
    _syncTimers.remove(sessionId);
  }

  Future<void> addPendingActivity(SessionActivityModel activity) async {
    if (!_pendingActivities.containsKey(activity.sessionId)) {
      _pendingActivities[activity.sessionId] = [];
    }

    _pendingActivities[activity.sessionId]!.add(activity);

    if (_pendingActivities[activity.sessionId]!.length > 50) {
      _pendingActivities[activity.sessionId]!.removeAt(0);
    }
  }

  Future<List<Map<String, dynamic>>> getSyncConflicts(String sessionId) async {
    final conflictKey = _conflictKey + sessionId;
    final conflictData = await _secureStorage.read(key: conflictKey);

    if (conflictData != null) {
      return [Map<String, dynamic>.from(json.decode(conflictData))];
    }

    return [];
  }

  Future<void> clearSyncData(String sessionId) async {
    await _secureStorage.delete(key: _syncStateKey + sessionId);
    await _secureStorage.delete(key: _conflictKey + sessionId);
    await _secureStorage.delete(key: 'sync_retry_$sessionId');
    _pendingActivities.remove(sessionId);
    stopPeriodicSync(sessionId);
  }

  void dispose() {
    for (final timer in _syncTimers.values) {
      timer.cancel();
    }
    _syncTimers.clear();
    _pendingActivities.clear();
  }
}

enum ConflictResolution { useLocal, useRemote, merge }
