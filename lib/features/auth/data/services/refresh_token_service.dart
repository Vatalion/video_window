import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/session_token_model.dart';
import '../../domain/models/session_model.dart';
import '../../domain/models/session_activity_model.dart';
import '../../../core/errors/exceptions.dart';
import 'jwt_token_service.dart';
import 'session_management_service.dart';

class RefreshTokenService {
  final FlutterSecureStorage _secureStorage;
  final JwtTokenService _jwtTokenService;
  final SessionManagementService _sessionManagementService;
  final Map<String, Timer> _refreshTimers = {};

  RefreshTokenService(
    this._secureStorage,
    this._jwtTokenService,
    this._sessionManagementService,
  );

  static const String _refreshCountKey = 'refresh_count_';
  static const Duration _refreshBuffer = const Duration(minutes: 5);
  static const int _maxRefreshAttempts = 3;
  static const Duration _refreshBackoff = const Duration(seconds: 30);

  Future<SessionTokenModel> refreshAccessToken({
    required String sessionId,
    bool forceRefresh = false,
  }) async {
    try {
      final currentTokens = await _jwtTokenService.getStoredTokens();
      if (currentTokens == null) {
        throw TokenException('No tokens available for refresh');
      }

      if (!forceRefresh && !currentTokens.needsRefresh) {
        return currentTokens;
      }

      final session = await _sessionManagementService.getSession(sessionId);
      if (!session.isActive) {
        throw SessionException('Cannot refresh tokens for inactive session');
      }

      await _validateRefreshToken(currentTokens);

      final newAccessToken = await _jwtTokenService.generateAccessToken(
        userId: currentTokens.userId,
        deviceId: currentTokens.deviceId,
        payload: {
          'session_id': sessionId,
          'token_version': currentTokens.tokenVersion + 1,
        },
      );

      final newRefreshToken = await _generateRotatedRefreshToken(currentTokens);

      final newTokenModel = SessionTokenModel(
        id: const Uuid().v4(),
        userId: currentTokens.userId,
        deviceId: currentTokens.deviceId,
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
        accessTokenExpiresAt: DateTime.now().add(const Duration(minutes: 30)),
        refreshTokenExpiresAt: currentTokens.refreshTokenExpiresAt,
        issuedAt: DateTime.now(),
        ipAddress: currentTokens.ipAddress,
        userAgent: currentTokens.userAgent,
        tokenVersion: currentTokens.tokenVersion + 1,
      );

      await _jwtTokenService.storeTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
        deviceId: currentTokens.deviceId,
        accessTokenExpiry: newTokenModel.accessTokenExpiresAt,
        refreshTokenExpiry: newTokenModel.refreshTokenExpiresAt,
      );

      await _logRefreshActivity(
        sessionId: sessionId,
        userId: currentTokens.userId,
        success: true,
        oldTokenVersion: currentTokens.tokenVersion,
        newTokenVersion: newTokenModel.tokenVersion,
      );

      await _scheduleNextRefresh(sessionId, newTokenModel);

      return newTokenModel;
    } catch (e) {
      await _handleRefreshFailure(sessionId, e);
      rethrow;
    }
  }

  Future<void> _validateRefreshToken(SessionTokenModel tokens) async {
    if (tokens.isRefreshTokenExpired) {
      throw TokenException('Refresh token has expired');
    }

    final rotationCount = await _getRefreshCount(tokens.id);
    if (rotationCount >= _maxRefreshAttempts) {
      throw TokenException('Maximum refresh attempts exceeded');
    }

    final isValid = await _jwtTokenService.validateToken(tokens.refreshToken);
    if (!isValid) {
      throw TokenException('Invalid refresh token');
    }
  }

  Future<String> _generateRotatedRefreshToken(
    SessionTokenModel currentTokens,
  ) async {
    final rotationCount = await _incrementRefreshCount(currentTokens.id);

    return await _jwtTokenService.generateRefreshToken(
      userId: currentTokens.userId,
      deviceId: currentTokens.deviceId,
      payload: {
        'rotation_count': rotationCount,
        'previous_token_id': currentTokens.id,
        'token_version': currentTokens.tokenVersion + 1,
      },
    );
  }

  Future<int> _getRefreshCount(String tokenId) async {
    final count = await _secureStorage.read(key: _refreshCountKey + tokenId);
    return count != null ? int.parse(count) : 0;
  }

  Future<int> _incrementRefreshCount(String tokenId) async {
    final currentCount = await _getRefreshCount(tokenId);
    final newCount = currentCount + 1;
    await _secureStorage.write(
      key: _refreshCountKey + tokenId,
      value: newCount.toString(),
    );
    return newCount;
  }

  Future<void> _scheduleNextRefresh(
    String sessionId,
    SessionTokenModel tokens,
  ) async {
    _refreshTimers[sessionId]?.cancel();

    final refreshDelay = tokens.accessTokenRemainingTime - _refreshBuffer;
    if (refreshDelay.inSeconds > 0) {
      _refreshTimers[sessionId] = Timer(refreshDelay, () async {
        try {
          await refreshAccessToken(sessionId: sessionId);
        } catch (e) {
          await _handleRefreshFailure(sessionId, e);
        }
      });
    }
  }

  Future<void> _handleRefreshFailure(String sessionId, dynamic error) async {
    await _logRefreshActivity(
      sessionId: sessionId,
      userId: 'unknown',
      success: false,
      error: error.toString(),
    );

    _refreshTimers[sessionId]?.cancel();
    _refreshTimers.remove(sessionId);
  }

  Future<void> _logRefreshActivity({
    required String sessionId,
    required String userId,
    required bool success,
    int? oldTokenVersion,
    int? newTokenVersion,
    String? error,
  }) async {
    final activity = SessionActivityModel.create(
      sessionId: sessionId,
      userId: userId,
      activityType: ActivityType.tokenRefresh,
      description: success
          ? 'Token refresh successful'
          : 'Token refresh failed',
      success: success,
      errorMessage: error,
      metadata: success
          ? {
              'old_token_version': oldTokenVersion,
              'new_token_version': newTokenVersion,
            }
          : null,
      isSecurityEvent: !success,
      securityImpact: success ? SecurityImpact.none : SecurityImpact.medium,
    );

    await _storeActivity(activity);
  }

  Future<void> _storeActivity(SessionActivityModel activity) async {
    final activityKey = 'activity_${activity.id}';
    final activityData = json.encode(activity.toJson());
    await _secureStorage.write(key: activityKey, value: activityData);
  }

  Future<void> startAutoRefresh(String sessionId) async {
    final tokens = await _jwtTokenService.getStoredTokens();
    if (tokens != null && tokens.isValid) {
      await _scheduleNextRefresh(sessionId, tokens);
    }
  }

  Future<void> stopAutoRefresh(String sessionId) async {
    _refreshTimers[sessionId]?.cancel();
    _refreshTimers.remove(sessionId);
  }

  Future<void> revokeRefreshTokens(String userId) async {
    final sessions = await _sessionManagementService.getUserSessions(userId);

    for (final session in sessions) {
      await stopAutoRefresh(session.id);

      final refreshCountKey = _refreshCountKey + session.id;
      await _secureStorage.delete(key: refreshCountKey);
    }

    await _jwtTokenService.clearTokens();
  }

  Future<void> revokeSingleSessionRefresh(String sessionId) async {
    await stopAutoRefresh(sessionId);

    final refreshCountKey = _refreshCountKey + sessionId;
    await _secureStorage.delete(key: refreshCountKey);
  }

  Future<bool> isAutoRefreshActive(String sessionId) async {
    return _refreshTimers[sessionId]?.isActive ?? false;
  }

  Future<Duration> getTimeUntilNextRefresh(String sessionId) async {
    final timer = _refreshTimers[sessionId];
    if (timer == null || !timer.isActive) {
      return Duration.zero;
    }

    final session = await _sessionManagementService.getSession(sessionId);
    final tokens = await _jwtTokenService.getStoredTokens();

    if (tokens == null) {
      return Duration.zero;
    }

    final refreshTime = tokens.accessTokenExpiresAt.subtract(_refreshBuffer);
    final now = DateTime.now();

    return refreshTime.difference(now);
  }

  Future<void> cleanupExpiredRefreshCounters() async {
    final allKeys = await _secureStorage.readAll();
    final now = DateTime.now();

    for (final key in allKeys.keys) {
      if (key.startsWith(_refreshCountKey)) {
        try {
          final tokenId = key.substring(_refreshCountKey.length);
          final tokens = await _jwtTokenService.getStoredTokens();

          if (tokens == null || tokens.isRefreshTokenExpired) {
            await _secureStorage.delete(key: key);
          }
        } catch (e) {
          continue;
        }
      }
    }
  }

  void dispose() {
    for (final timer in _refreshTimers.values) {
      timer.cancel();
    }
    _refreshTimers.clear();
  }
}
