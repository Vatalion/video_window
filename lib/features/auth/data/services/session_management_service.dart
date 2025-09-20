import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/session_model.dart';
import '../../domain/models/session_activity_model.dart';
import '../../domain/models/session_token_model.dart';
import '../../domain/models/device_model.dart';
import '../../../core/errors/exceptions.dart';
import 'jwt_token_service.dart';

class SessionManagementService {
  final FlutterSecureStorage _secureStorage;
  final JwtTokenService _jwtTokenService;
  final Map<String, SessionModel> _activeSessions = {};

  SessionManagementService(this._secureStorage, this._jwtTokenService);

  static const String _sessionPrefix = 'session_';
  static const String _currentSessionKey = 'current_session_id';

  Future<SessionModel> createSession({
    required String userId,
    required String deviceId,
    required String ipAddress,
    String? userAgent,
    String? location,
    Duration timeoutDuration = const Duration(minutes: 30),
    SecurityLevel securityLevel = SecurityLevel.standard,
    Map<String, dynamic> metadata = const {},
  }) async {
    final sessionId = _generateSessionId();
    final session = SessionModel.create(
      userId: userId,
      deviceId: deviceId,
      sessionId: sessionId,
      ipAddress: ipAddress,
      userAgent: userAgent,
      location: location,
      timeoutDuration: timeoutDuration,
      securityLevel: securityLevel,
      metadata: metadata,
    );

    await _storeSession(session);
    _activeSessions[sessionId] = session;
    await _setCurrentSessionId(sessionId);

    await _logActivity(
      sessionId: sessionId,
      userId: userId,
      activityType: ActivityType.login,
      description: 'New session created',
      ipAddress: ipAddress,
      userAgent: userAgent,
      location: location,
    );

    return session;
  }

  Future<SessionModel?> getCurrentSession() async {
    try {
      final currentSessionId = await _getCurrentSessionId();
      if (currentSessionId == null) return null;

      return await _getSession(currentSessionId);
    } catch (e) {
      return null;
    }
  }

  Future<List<SessionModel>> getUserSessions(String userId) async {
    final sessions = <SessionModel>[];
    final allKeys = await _secureStorage.readAll();

    for (final key in allKeys.keys) {
      if (key.startsWith(_sessionPrefix)) {
        try {
          final sessionData = allKeys[key];
          if (sessionData != null) {
            final session = SessionModel.fromJson(
              Map<String, dynamic>.from(_decodeSessionData(sessionData)),
            );
            if (session.userId == userId) {
              sessions.add(session);
            }
          }
        } catch (e) {
          continue;
        }
      }
    }

    return sessions.where((session) => !session.isTerminated).toList();
  }

  Future<SessionModel> updateSessionActivity(String sessionId) async {
    final session = await _getSession(sessionId);
    final updatedSession = session.updateActivity();

    await _storeSession(updatedSession);
    _activeSessions[sessionId] = updatedSession;

    return updatedSession;
  }

  Future<SessionModel> terminateSession(String sessionId) async {
    final session = await _getSession(sessionId);
    final terminatedSession = session.terminate();

    await _storeSession(terminatedSession);
    _activeSessions.remove(sessionId);

    if (await _getCurrentSessionId() == sessionId) {
      await _secureStorage.delete(key: _currentSessionKey);
    }

    await _logActivity(
      sessionId: sessionId,
      userId: session.userId,
      activityType: ActivityType.logout,
      description: 'Session terminated',
    );

    return terminatedSession;
  }

  Future<void> terminateAllUserSessions(
    String userId, {
    String? exceptSessionId,
  }) async {
    final sessions = await getUserSessions(userId);

    for (final session in sessions) {
      if (session.id != exceptSessionId) {
        await terminateSession(session.id);
      }
    }
  }

  Future<SessionModel> handleSessionTimeout(String sessionId) async {
    final session = await _getSession(sessionId);
    final timedOutSession = session.expire();

    await _storeSession(timedOutSession);
    _activeSessions.remove(sessionId);

    await _logActivity(
      sessionId: sessionId,
      userId: session.userId,
      activityType: ActivityType.sessionTimeout,
      description: 'Session expired due to inactivity',
      isSecurityEvent: true,
      securityImpact: SecurityImpact.low,
    );

    return timedOutSession;
  }

  Future<SessionModel> handleFailedLogin(String sessionId) async {
    final session = await _getSession(sessionId);
    final updatedSession = session.incrementFailures();

    await _storeSession(updatedSession);

    await _logActivity(
      sessionId: sessionId,
      userId: session.userId,
      activityType: ActivityType.failedLogin,
      description: 'Failed login attempt',
      success: false,
      isSecurityEvent: true,
      securityImpact: updatedSession.isLocked
          ? SecurityImpact.high
          : SecurityImpact.medium,
    );

    if (updatedSession.isLockedDueToFailures) {
      await _logActivity(
        sessionId: sessionId,
        userId: session.userId,
        activityType: ActivityType.accountLock,
        description: 'Account locked due to multiple failed attempts',
        isSecurityEvent: true,
        securityImpact: SecurityImpact.high,
      );
    }

    return updatedSession;
  }

  Future<SessionModel> resetSessionFailures(String sessionId) async {
    final session = await _getSession(sessionId);
    final resetSession = session.resetFailures();

    await _storeSession(resetSession);

    return resetSession;
  }

  Future<void> checkAndHandleTimeouts() async {
    final now = DateTime.now();
    final sessionsToTimeout = <String>[];

    for (final sessionId in _activeSessions.keys) {
      final session = _activeSessions[sessionId];
      if (session != null &&
          now.difference(session.lastActivity) > session.timeoutDuration) {
        sessionsToTimeout.add(sessionId);
      }
    }

    for (final sessionId in sessionsToTimeout) {
      await handleSessionTimeout(sessionId);
    }
  }

  Future<bool> isSessionValid(String sessionId) async {
    try {
      final session = await _getSession(sessionId);
      return session.isActive && !session.isTimeout;
    } catch (e) {
      return false;
    }
  }

  Future<SessionModel> getSession(String sessionId) async {
    return await _getSession(sessionId);
  }

  Future<Duration> getSessionRemainingTime(String sessionId) async {
    final session = await _getSession(sessionId);
    return session.remainingTime;
  }

  Future<void> _storeSession(SessionModel session) async {
    final sessionData = _encodeSessionData(session.toJson());
    await _secureStorage.write(
      key: _sessionPrefix + session.id,
      value: sessionData,
    );
  }

  Future<SessionModel> _getSession(String sessionId) async {
    final sessionData = await _secureStorage.read(
      key: _sessionPrefix + sessionId,
    );
    if (sessionData == null) {
      throw SessionException('Session not found: $sessionId');
    }

    return SessionModel.fromJson(
      Map<String, dynamic>.from(_decodeSessionData(sessionData)),
    );
  }

  Future<void> _setCurrentSessionId(String sessionId) async {
    await _secureStorage.write(key: _currentSessionKey, value: sessionId);
  }

  Future<String?> _getCurrentSessionId() async {
    return await _secureStorage.read(key: _currentSessionKey);
  }

  Future<void> _logActivity({
    required String sessionId,
    required String userId,
    required ActivityType activityType,
    String? description,
    String? ipAddress,
    String? userAgent,
    String? location,
    bool isSecurityEvent = false,
    SecurityImpact securityImpact = SecurityImpact.none,
    bool success = true,
    String? errorMessage,
  }) async {
    final activity = SessionActivityModel.create(
      sessionId: sessionId,
      userId: userId,
      activityType: activityType,
      description: description,
      ipAddress: ipAddress,
      userAgent: userAgent,
      location: location,
      isSecurityEvent: isSecurityEvent,
      securityImpact: securityImpact,
      success: success,
      errorMessage: errorMessage,
    );

    await _storeActivity(activity);
  }

  Future<void> _storeActivity(SessionActivityModel activity) async {
    final activityKey = 'activity_${activity.id}';
    final activityData = _encodeSessionData(activity.toJson());
    await _secureStorage.write(key: activityKey, value: activityData);
  }

  String _generateSessionId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (i) => random.nextInt(256));
    return base64.encode(bytes);
  }

  String _encodeSessionData(Map<String, dynamic> data) {
    return json.encode(data);
  }

  Map<String, dynamic> _decodeSessionData(String data) {
    return Map<String, dynamic>.from(json.decode(data));
  }

  void startTimeoutMonitoring() {
    Timer.periodic(const Duration(minutes: 1), (timer) async {
      await checkAndHandleTimeouts();
    });
  }

  Future<List<SessionActivityModel>> getSessionActivities(
    String sessionId,
  ) async {
    final activities = <SessionActivityModel>[];
    final allKeys = await _secureStorage.readAll();

    for (final key in allKeys.keys) {
      if (key.startsWith('activity_')) {
        try {
          final activityData = allKeys[key];
          if (activityData != null) {
            final activity = SessionActivityModel.fromJson(
              Map<String, dynamic>.from(_decodeSessionData(activityData)),
            );
            if (activity.sessionId == sessionId) {
              activities.add(activity);
            }
          }
        } catch (e) {
          continue;
        }
      }
    }

    return activities..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> cleanupExpiredSessions() async {
    final now = DateTime.now();
    final allKeys = await _secureStorage.readAll();

    for (final key in allKeys.keys) {
      if (key.startsWith(_sessionPrefix)) {
        try {
          final sessionData = allKeys[key];
          if (sessionData != null) {
            final session = SessionModel.fromJson(
              Map<String, dynamic>.from(_decodeSessionData(sessionData)),
            );
            if (session.isExpired ||
                (session.endTime != null && session.endTime!.isBefore(now))) {
              await _secureStorage.delete(key: key);
            }
          }
        } catch (e) {
          continue;
        }
      }
    }
  }
}
