import 'package:serverpod/serverpod.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Repository for managing refresh tokens with rotation and reuse detection
/// Implements SEC-003 refresh token security requirements:
/// - Hashed token storage
/// - Reuse detection and account lockout
/// - Device fingerprinting
/// - Token blacklisting
class RefreshTokenRepository {
  final Session session;

  RefreshTokenRepository(this.session);

  /// Store a new refresh token with hashed value
  /// Returns the token ID for tracking
  Future<int?> storeRefreshToken({
    required int userId,
    required String tokenHash,
    required String jti,
    required DateTime expiresAt,
    String? deviceId,
    String? deviceFingerprint,
    String? ipAddress,
    String? userAgent,
  }) async {
    try {
      final now = DateTime.now();

      final result = await session.db.query(
        '''
        INSERT INTO refresh_tokens (
          user_id, token_hash, jti, expires_at, 
          device_id, device_fingerprint, ip_address, user_agent,
          rotation_count, last_used_at, created_at, updated_at, revoked
        ) VALUES (
          @userId, @tokenHash, @jti, @expiresAt,
          @deviceId, @deviceFingerprint, @ipAddress, @userAgent,
          0, @now, @now, @now, false
        ) RETURNING id
        ''',
        {
          'userId': userId,
          'tokenHash': tokenHash,
          'jti': jti,
          'expiresAt': expiresAt.toUtc(),
          'deviceId': deviceId,
          'deviceFingerprint': deviceFingerprint,
          'ipAddress': ipAddress,
          'userAgent': userAgent,
          'now': now.toUtc(),
        },
      );

      if (result.isEmpty) return null;

      final id = result.first.toColumnMap()['id'] as int;

      session.log(
        'Stored refresh token: jti=$jti, userId=$userId',
        level: LogLevel.debug,
      );

      return id;
    } catch (e, stackTrace) {
      session.log(
        'Failed to store refresh token: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Verify refresh token and check for reuse
  /// Returns token metadata if valid, null if invalid or reused
  Future<RefreshTokenMetadata?> verifyAndConsumeToken({
    required String jti,
    required String tokenHash,
  }) async {
    try {
      // Find the refresh token by JTI
      final result = await session.db.query(
        '''
        SELECT id, user_id, token_hash, rotation_count, last_used_at, 
               expires_at, revoked, device_id, device_fingerprint
        FROM refresh_tokens
        WHERE jti = @jti
        LIMIT 1
        ''',
        {'jti': jti},
      );

      if (result.isEmpty) {
        session.log(
          'Refresh token not found: jti=$jti',
          level: LogLevel.warning,
        );
        return null;
      }

      final row = result.first.toColumnMap();
      final storedHash = row['token_hash'] as String;
      final revoked = row['revoked'] as bool;
      final expiresAt = row['expires_at'] as DateTime;
      final lastUsedAt = row['last_used_at'] as DateTime?;

      // Check if token is revoked
      if (revoked) {
        session.log(
          'Refresh token is revoked: jti=$jti',
          level: LogLevel.warning,
        );
        return null;
      }

      // Check if token is expired
      if (expiresAt.isBefore(DateTime.now().toUtc())) {
        session.log(
          'Refresh token is expired: jti=$jti',
          level: LogLevel.warning,
        );
        await _revokeToken(jti);
        return null;
      }

      // Verify token hash matches
      if (storedHash != tokenHash) {
        session.log(
          'Refresh token hash mismatch: jti=$jti',
          level: LogLevel.warning,
        );
        return null;
      }

      // CRITICAL: Detect reuse - if last_used_at is set, this token was already used
      if (lastUsedAt != null) {
        session.log(
          'SECURITY ALERT: Refresh token reuse detected: jti=$jti, userId=${row['user_id']}',
          level: LogLevel.error,
        );

        // Emit security event for token reuse
        await _emitTokenReuseEvent(row['user_id'] as int, jti);

        // Revoke this token and potentially all tokens for this user
        await _handleTokenReuse(row['user_id'] as int, jti);

        return null;
      }

      // Mark token as used by setting last_used_at
      await session.db.query(
        '''
        UPDATE refresh_tokens
        SET last_used_at = @now, updated_at = @now
        WHERE jti = @jti
        ''',
        {
          'jti': jti,
          'now': DateTime.now().toUtc(),
        },
      );

      return RefreshTokenMetadata(
        id: row['id'] as int,
        userId: row['user_id'] as int,
        rotationCount: row['rotation_count'] as int,
        deviceId: row['device_id'] as String?,
        deviceFingerprint: row['device_fingerprint'] as String?,
      );
    } catch (e, stackTrace) {
      session.log(
        'Failed to verify refresh token: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Revoke a refresh token by JTI
  Future<void> _revokeToken(String jti) async {
    try {
      await session.db.query(
        '''
        UPDATE refresh_tokens
        SET revoked = true, updated_at = @now
        WHERE jti = @jti
        ''',
        {
          'jti': jti,
          'now': DateTime.now().toUtc(),
        },
      );

      session.log('Revoked refresh token: jti=$jti', level: LogLevel.info);
    } catch (e, stackTrace) {
      session.log(
        'Failed to revoke token: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Revoke a specific refresh token (for logout)
  Future<void> revokeRefreshToken(String jti) async {
    await _revokeToken(jti);

    // Emit revocation event
    await _emitTokenRevokedEvent(jti);
  }

  /// Revoke all refresh tokens for a user (for security incidents)
  Future<void> revokeAllUserTokens(int userId) async {
    try {
      await session.db.query(
        '''
        UPDATE refresh_tokens
        SET revoked = true, updated_at = @now
        WHERE user_id = @userId AND revoked = false
        ''',
        {
          'userId': userId,
          'now': DateTime.now().toUtc(),
        },
      );

      session.log(
        'Revoked all refresh tokens for user: userId=$userId',
        level: LogLevel.warning,
      );

      // Emit security event
      await _emitAllTokensRevokedEvent(userId);
    } catch (e, stackTrace) {
      session.log(
        'Failed to revoke all user tokens: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Handle token reuse detection - revoke all tokens and lock account
  Future<void> _handleTokenReuse(int userId, String jti) async {
    try {
      // Revoke all refresh tokens for this user
      await revokeAllUserTokens(userId);

      // Lock the user account for security
      await session.db.query(
        '''
        UPDATE users
        SET is_active = false, failed_attempts = 999, updated_at = @now
        WHERE id = @userId
        ''',
        {
          'userId': userId,
          'now': DateTime.now().toUtc(),
        },
      );

      session.log(
        'SECURITY: Account locked due to token reuse: userId=$userId',
        level: LogLevel.error,
      );
    } catch (e, stackTrace) {
      session.log(
        'Failed to handle token reuse: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Clean up expired tokens (run periodically)
  Future<void> cleanupExpiredTokens() async {
    try {
      final result = await session.db.query(
        '''
        DELETE FROM refresh_tokens
        WHERE expires_at < @now
        RETURNING id
        ''',
        {'now': DateTime.now().toUtc()},
      );

      session.log(
        'Cleaned up ${result.length} expired refresh tokens',
        level: LogLevel.info,
      );
    } catch (e, stackTrace) {
      session.log(
        'Failed to cleanup expired tokens: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Emit security event for token rotation
  Future<void> _emitTokenRotatedEvent(
      int userId, String oldJti, String newJti) async {
    try {
      await session.db.query(
        '''
        INSERT INTO security_events (
          event_type, user_id, severity, metadata, created_at
        ) VALUES (
          'auth.session.rotated', @userId, 'info', @metadata, @now
        )
        ''',
        {
          'userId': userId,
          'metadata': jsonEncode({
            'old_jti': oldJti,
            'new_jti': newJti,
            'timestamp': DateTime.now().toUtc().toIso8601String(),
          }),
          'now': DateTime.now().toUtc(),
        },
      );
    } catch (e) {
      session.log('Failed to emit token rotated event: $e',
          level: LogLevel.warning);
    }
  }

  /// Emit security event for token reuse detection
  Future<void> _emitTokenReuseEvent(int userId, String jti) async {
    try {
      await session.db.query(
        '''
        INSERT INTO security_events (
          event_type, user_id, severity, metadata, created_at
        ) VALUES (
          'auth.session.reuse_detected', @userId, 'critical', @metadata, @now
        )
        ''',
        {
          'userId': userId,
          'metadata': jsonEncode({
            'jti': jti,
            'timestamp': DateTime.now().toUtc().toIso8601String(),
            'action': 'account_locked',
          }),
          'now': DateTime.now().toUtc(),
        },
      );
    } catch (e) {
      session.log('Failed to emit token reuse event: $e',
          level: LogLevel.warning);
    }
  }

  /// Emit security event for token revocation
  Future<void> _emitTokenRevokedEvent(String jti) async {
    try {
      await session.db.query(
        '''
        INSERT INTO security_events (
          event_type, severity, metadata, created_at
        ) VALUES (
          'auth.session.revoked', 'info', @metadata, @now
        )
        ''',
        {
          'metadata': jsonEncode({
            'jti': jti,
            'timestamp': DateTime.now().toUtc().toIso8601String(),
          }),
          'now': DateTime.now().toUtc(),
        },
      );
    } catch (e) {
      session.log('Failed to emit token revoked event: $e',
          level: LogLevel.warning);
    }
  }

  /// Emit security event for all tokens revoked
  Future<void> _emitAllTokensRevokedEvent(int userId) async {
    try {
      await session.db.query(
        '''
        INSERT INTO security_events (
          event_type, user_id, severity, metadata, created_at
        ) VALUES (
          'auth.session.all_revoked', @userId, 'warning', @metadata, @now
        )
        ''',
        {
          'userId': userId,
          'metadata': jsonEncode({
            'timestamp': DateTime.now().toUtc().toIso8601String(),
            'reason': 'security_incident',
          }),
          'now': DateTime.now().toUtc(),
        },
      );
    } catch (e) {
      session.log('Failed to emit all tokens revoked event: $e',
          level: LogLevel.warning);
    }
  }

  /// Hash a refresh token for storage
  static String hashToken(String token) {
    final bytes = utf8.encode(token);
    return sha256.convert(bytes).toString();
  }
}

/// Metadata for a refresh token
class RefreshTokenMetadata {
  final int id;
  final int userId;
  final int rotationCount;
  final String? deviceId;
  final String? deviceFingerprint;

  RefreshTokenMetadata({
    required this.id,
    required this.userId,
    required this.rotationCount,
    this.deviceId,
    this.deviceFingerprint,
  });
}
