import 'dart:math';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart';
import '../../generated/auth/recovery_token.dart';
import '../../generated/auth/user.dart';
import '../../generated/auth/session.dart';
import 'rate_limit_service.dart';
import 'account_lockout_service.dart';

/// Secure account recovery service
/// Implements AC1-AC5: One-time recovery tokens with brute force protection
class RecoveryService {
  static const int _tokenLength = 32; // 32 hex characters = 128 bits
  static const Duration _validityPeriod = Duration(minutes: 15); // AC1
  static const int _maxAttempts = 3; // AC4

  final Session session;

  RecoveryService(this.session);

  /// Generate a cryptographically secure recovery token
  /// Uses Random.secure() for cryptographic security
  String generateSecureToken() {
    final random = Random.secure();
    final bytes = List.generate(_tokenLength, (_) => random.nextInt(256));
    final token = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    session.log('Recovery token generated', level: LogLevel.debug);
    return token;
  }

  /// Generate user-specific salt for token hashing
  /// Each user gets unique salt to prevent rainbow table attacks
  Future<String> _generateUserSpecificSalt(String identifier) async {
    final random = Random.secure();
    final saltBytes = List.generate(32, (_) => random.nextInt(256)); // 32 bytes
    final salt = base64Encode(saltBytes);

    session.log(
      'Generated salt for identifier',
      level: LogLevel.debug,
    );
    return salt;
  }

  /// Hash token with SHA-256 and user-specific salt
  /// SECURITY CRITICAL: Never store plaintext tokens
  String hashToken(String token, String salt) {
    final bytes = utf8.encode(token + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Create and send a recovery token for the given email
  /// Returns the plaintext token (to be sent via email)
  /// Stores only the hashed version in database
  /// AC1: One-time token with 15-minute expiry
  /// AC2: Includes device + location metadata
  Future<RecoveryTokenResult> createRecoveryToken({
    required String email,
    String? deviceInfo,
    required String ipAddress,
    String? userAgent,
    String? location,
  }) async {
    try {
      final normalizedEmail = email.toLowerCase().trim();

      // Check rate limits (3 per 24 hours per user, 10 per IP) - AC security
      final rateLimitService = RateLimitService(session);
      final rateLimitResult = await rateLimitService.checkRateLimit(
        identifier: normalizedEmail,
        ipAddress: ipAddress,
        action: 'recovery_send',
      );

      if (!rateLimitResult.allowed) {
        session.log(
          'Rate limit exceeded for recovery request: $normalizedEmail from $ipAddress',
          level: LogLevel.warning,
        );

        return RecoveryTokenResult.rateLimitExceeded(
          retryAfter: rateLimitResult.retryAfter,
        );
      }

      // Check account lockout status - AC4
      final lockoutService = AccountLockoutService(session);
      final lockStatus = await lockoutService.checkLockStatus(
        identifier: normalizedEmail,
        action: 'recovery_verify',
      );

      if (lockStatus.isLocked) {
        session.log(
          'Account locked for recovery: $normalizedEmail',
          level: LogLevel.warning,
        );

        return RecoveryTokenResult.accountLocked(
          remainingDuration: lockStatus.remainingDuration,
          unlocksAt: lockStatus.unlocksAt,
        );
      }

      // Find user by email
      final users = await User.db.find(
        session,
        where: (t) => t.email.equals(normalizedEmail),
        limit: 1,
      );

      if (users.isEmpty) {
        // For security, don't reveal if email exists
        session.log(
          'Recovery requested for non-existent email: $normalizedEmail',
          level: LogLevel.info,
        );
        // Return success but don't actually send anything
        return RecoveryTokenResult.success(
          token: '', // Don't send token for non-existent user
          userExists: false,
        );
      }

      final user = users.first;

      // Generate cryptographically secure token
      final token = generateSecureToken();

      // Generate user-specific salt
      final salt = await _generateUserSpecificSalt(normalizedEmail);

      // Hash the token
      final tokenHash = hashToken(token, salt);

      // Calculate expiry time (15 minutes from now) - AC1
      final expiresAt = DateTime.now().add(_validityPeriod);

      // Invalidate any existing tokens for this user
      await _invalidateExistingTokens(user.id!);

      // Store recovery token record with hash only (never plaintext)
      final recoveryToken = RecoveryToken(
        userId: user.id!,
        email: normalizedEmail,
        tokenHash: tokenHash,
        salt: salt,
        deviceInfo: deviceInfo,
        ipAddress: ipAddress,
        userAgent: userAgent,
        location: location,
        attempts: 0,
        used: false,
        revoked: false,
        expiresAt: expiresAt,
        createdAt: DateTime.now(),
      );

      await RecoveryToken.db.insertRow(session, recoveryToken);

      session.log(
        'Recovery token created for user ${user.id} (hash stored)',
        level: LogLevel.info,
      );

      // Return plaintext token for sending via email (not stored anywhere)
      return RecoveryTokenResult.success(
        token: token,
        userExists: true,
        userId: user.id,
        expiresAt: expiresAt,
      );
    } catch (e, stackTrace) {
      session.log(
        'Failed to create recovery token: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      return RecoveryTokenResult.error();
    }
  }

  /// Verify a recovery token for the given email
  /// AC3: Allows re-authentication and forces session rotation
  /// AC4: Implements brute force protection (3 attempts = 30 min lockout)
  Future<RecoveryVerificationResult> verifyRecoveryToken({
    required String email,
    required String token,
    required String ipAddress,
  }) async {
    try {
      final normalizedEmail = email.toLowerCase().trim();

      // Check account lockout status first - AC4
      final lockoutService = AccountLockoutService(session);
      final lockStatus = await lockoutService.checkLockStatus(
        identifier: normalizedEmail,
        action: 'recovery_verify',
      );

      if (lockStatus.isLocked) {
        session.log(
          'Account locked for recovery verification: $normalizedEmail',
          level: LogLevel.warning,
        );

        return RecoveryVerificationResult.accountLocked(
          remainingDuration: lockStatus.remainingDuration,
          unlocksAt: lockStatus.unlocksAt,
        );
      }

      // Find the most recent recovery token for this email
      final recoveryTokens = await RecoveryToken.db.find(
        session,
        where: (t) =>
            t.email.equals(normalizedEmail) &
            t.used.equals(false) &
            t.revoked.equals(false),
        orderBy: (t) => t.createdAt,
        orderDescending: true,
        limit: 1,
      );

      if (recoveryTokens.isEmpty) {
        session.log(
          'Recovery verification failed: No active token found for $normalizedEmail',
          level: LogLevel.warning,
        );

        // Record failed attempt for brute force protection
        await lockoutService.recordFailedAttempt(
          identifier: normalizedEmail,
          action: 'recovery_verify',
        );

        return RecoveryVerificationResult.notFound();
      }

      final recoveryToken = recoveryTokens.first;

      // Check if token has expired - AC1
      if (DateTime.now().isAfter(recoveryToken.expiresAt)) {
        session.log(
          'Recovery verification failed: Token expired for $normalizedEmail',
          level: LogLevel.warning,
        );

        // Mark as used to prevent further attempts
        await _markTokenAsUsed(recoveryToken.id!);

        return RecoveryVerificationResult.expired();
      }

      // Check if max attempts exceeded - AC4
      if (recoveryToken.attempts >= _maxAttempts) {
        session.log(
          'Recovery verification failed: Max attempts exceeded for $normalizedEmail',
          level: LogLevel.warning,
        );

        // Mark as used and lock account
        await _markTokenAsUsed(recoveryToken.id!);
        await lockoutService.recordFailedAttempt(
          identifier: normalizedEmail,
          action: 'recovery_verify',
        );

        // Emit security alert - AC4
        await _emitSecurityAlert(
          userId: recoveryToken.userId,
          email: normalizedEmail,
          reason: 'Max recovery attempts exceeded',
          ipAddress: ipAddress,
        );

        return RecoveryVerificationResult.maxAttemptsExceeded();
      }

      // Verify the token hash
      final providedHash = hashToken(token, recoveryToken.salt);
      final isValid = providedHash == recoveryToken.tokenHash;

      if (isValid) {
        // SUCCESS: Mark token as used immediately (one-time use enforcement)
        await _markTokenAsUsed(recoveryToken.id!);

        // Clear any failed attempts
        await lockoutService.clearFailedAttempts(
          identifier: normalizedEmail,
          action: 'recovery_verify',
        );

        session.log(
          'Recovery token verified successfully for user ${recoveryToken.userId}',
          level: LogLevel.info,
        );

        return RecoveryVerificationResult.success(
          userId: recoveryToken.userId,
          email: normalizedEmail,
        );
      } else {
        // FAILURE: Increment attempt counter and record failed attempt
        await _incrementAttempts(recoveryToken.id!);

        // Record failed attempt for progressive lockout - AC4
        await lockoutService.recordFailedAttempt(
          identifier: normalizedEmail,
          action: 'recovery_verify',
        );

        session.log(
          'Recovery verification failed: Invalid token for $normalizedEmail (attempt ${recoveryToken.attempts + 1}/$_maxAttempts)',
          level: LogLevel.warning,
        );

        // Check if this failure triggers a lockout
        final attemptsRemaining = _maxAttempts - (recoveryToken.attempts + 1);
        if (attemptsRemaining == 0) {
          // Emit security alert - AC4
          await _emitSecurityAlert(
            userId: recoveryToken.userId,
            email: normalizedEmail,
            reason: 'Account locked due to failed recovery attempts',
            ipAddress: ipAddress,
          );
        }

        return RecoveryVerificationResult.invalid(
          attemptsRemaining: attemptsRemaining,
        );
      }
    } catch (e, stackTrace) {
      session.log(
        'Recovery verification error: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      return RecoveryVerificationResult.error();
    }
  }

  /// Revoke a recovery token immediately
  /// AC2: "Not You?" link revokes token immediately
  Future<bool> revokeRecoveryToken({
    required String token,
    required String email,
  }) async {
    try {
      final normalizedEmail = email.toLowerCase().trim();

      // Find the token
      final recoveryTokens = await RecoveryToken.db.find(
        session,
        where: (t) =>
            t.email.equals(normalizedEmail) &
            t.used.equals(false) &
            t.revoked.equals(false),
        orderBy: (t) => t.createdAt,
        orderDescending: true,
        limit: 1,
      );

      if (recoveryTokens.isEmpty) {
        return false;
      }

      final recoveryToken = recoveryTokens.first;

      // Verify token matches before revoking
      final providedHash = hashToken(token, recoveryToken.salt);
      if (providedHash != recoveryToken.tokenHash) {
        return false;
      }

      // Mark as revoked
      recoveryToken.revoked = true;
      recoveryToken.revokedAt = DateTime.now();
      await RecoveryToken.db.updateRow(session, recoveryToken);

      // Emit security alert
      await _emitSecurityAlert(
        userId: recoveryToken.userId,
        email: normalizedEmail,
        reason: 'Recovery token revoked by user',
        ipAddress: recoveryToken.ipAddress,
      );

      session.log(
        'Recovery token revoked for user ${recoveryToken.userId}',
        level: LogLevel.warning,
      );

      return true;
    } catch (e, stackTrace) {
      session.log(
        'Failed to revoke recovery token: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Invalidate all active sessions and refresh tokens for a user
  /// AC5: Successful recovery must invalidate all active sessions
  Future<void> invalidateAllSessions(int userId) async {
    try {
      // Find all active sessions for the user
      final sessions = await UserSession.db.find(
        session,
        where: (t) => t.userId.equals(userId) & t.isRevoked.equals(false),
      );

      // Revoke all sessions
      for (final userSession in sessions) {
        userSession.isRevoked = true;
        await UserSession.db.updateRow(session, userSession);
      }

      session.log(
        'Invalidated ${sessions.length} sessions for user $userId',
        level: LogLevel.info,
      );
    } catch (e, stackTrace) {
      session.log(
        'Failed to invalidate sessions: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Invalidate all existing recovery tokens for a user
  /// Called before creating a new token to prevent multiple active tokens
  Future<void> _invalidateExistingTokens(int userId) async {
    try {
      // Find all unused, non-revoked tokens for this user
      final existingTokens = await RecoveryToken.db.find(
        session,
        where: (t) =>
            t.userId.equals(userId) &
            t.used.equals(false) &
            t.revoked.equals(false),
      );

      // Mark all as used
      for (final token in existingTokens) {
        await _markTokenAsUsed(token.id!);
      }

      if (existingTokens.isNotEmpty) {
        session.log(
          'Invalidated ${existingTokens.length} existing recovery token(s) for user $userId',
          level: LogLevel.debug,
        );
      }
    } catch (e) {
      session.log(
        'Failed to invalidate existing tokens: $e',
        level: LogLevel.error,
        exception: e,
      );
    }
  }

  /// Mark a recovery token as used (one-time use enforcement)
  Future<void> _markTokenAsUsed(int tokenId) async {
    try {
      final token = await RecoveryToken.db.findById(session, tokenId);
      if (token != null) {
        token.used = true;
        token.usedAt = DateTime.now();
        await RecoveryToken.db.updateRow(session, token);
      }
    } catch (e) {
      session.log(
        'Failed to mark token as used: $e',
        level: LogLevel.error,
        exception: e,
      );
    }
  }

  /// Increment attempt counter for failed verification
  Future<void> _incrementAttempts(int tokenId) async {
    try {
      final token = await RecoveryToken.db.findById(session, tokenId);
      if (token != null) {
        token.attempts++;
        await RecoveryToken.db.updateRow(session, token);
      }
    } catch (e) {
      session.log(
        'Failed to increment attempts: $e',
        level: LogLevel.error,
        exception: e,
      );
    }
  }

  /// Emit security alert to monitoring system
  /// AC4: Alert security monitoring on lockout
  Future<void> _emitSecurityAlert({
    required int userId,
    required String email,
    required String reason,
    required String ipAddress,
  }) async {
    try {
      // TODO: Integrate with actual security monitoring system
      // For now, just log with high severity
      session.log(
        'SECURITY ALERT: $reason - User $userId ($email) from IP $ipAddress',
        level: LogLevel.warning,
      );

      // TODO: Emit to security.alerts topic for real-time monitoring
      // await pubsub.publish('security.alerts', {
      //   'type': 'account_recovery_alert',
      //   'userId': userId,
      //   'email': email,
      //   'reason': reason,
      //   'ipAddress': ipAddress,
      //   'timestamp': DateTime.now().toIso8601String(),
      // });
    } catch (e) {
      session.log(
        'Failed to emit security alert: $e',
        level: LogLevel.error,
        exception: e,
      );
    }
  }

  /// Clean up expired recovery tokens (maintenance task)
  /// Should be called periodically to prevent database bloat
  Future<void> cleanupExpiredTokens() async {
    try {
      final now = DateTime.now();
      final expiredTokens = await RecoveryToken.db.find(
        session,
        where: (t) => t.expiresAt < now,
      );

      for (final token in expiredTokens) {
        await RecoveryToken.db.deleteRow(session, token);
      }

      if (expiredTokens.isNotEmpty) {
        session.log(
          'Cleaned up ${expiredTokens.length} expired recovery token(s)',
          level: LogLevel.info,
        );
      }
    } catch (e) {
      session.log(
        'Failed to cleanup expired tokens: $e',
        level: LogLevel.error,
        exception: e,
      );
    }
  }
}

/// Result of recovery token creation
class RecoveryTokenResult {
  final bool success;
  final String? token;
  final bool? userExists;
  final int? userId;
  final DateTime? expiresAt;
  final String? error;
  final Duration? retryAfter;
  final DateTime? unlocksAt;

  RecoveryTokenResult._({
    required this.success,
    this.token,
    this.userExists,
    this.userId,
    this.expiresAt,
    this.error,
    this.retryAfter,
    this.unlocksAt,
  });

  factory RecoveryTokenResult.success({
    required String token,
    required bool userExists,
    int? userId,
    DateTime? expiresAt,
  }) {
    return RecoveryTokenResult._(
      success: true,
      token: token,
      userExists: userExists,
      userId: userId,
      expiresAt: expiresAt,
    );
  }

  factory RecoveryTokenResult.rateLimitExceeded({Duration? retryAfter}) {
    return RecoveryTokenResult._(
      success: false,
      error: 'RATE_LIMIT_EXCEEDED',
      retryAfter: retryAfter,
    );
  }

  factory RecoveryTokenResult.accountLocked({
    Duration? remainingDuration,
    DateTime? unlocksAt,
  }) {
    return RecoveryTokenResult._(
      success: false,
      error: 'ACCOUNT_LOCKED',
      retryAfter: remainingDuration,
      unlocksAt: unlocksAt,
    );
  }

  factory RecoveryTokenResult.error() {
    return RecoveryTokenResult._(
      success: false,
      error: 'INTERNAL_ERROR',
    );
  }
}

/// Result of recovery token verification
class RecoveryVerificationResult {
  final bool success;
  final int? userId;
  final String? email;
  final String? error;
  final int? attemptsRemaining;
  final Duration? remainingDuration;
  final DateTime? unlocksAt;

  RecoveryVerificationResult._({
    required this.success,
    this.userId,
    this.email,
    this.error,
    this.attemptsRemaining,
    this.remainingDuration,
    this.unlocksAt,
  });

  factory RecoveryVerificationResult.success({
    required int userId,
    required String email,
  }) {
    return RecoveryVerificationResult._(
      success: true,
      userId: userId,
      email: email,
    );
  }

  factory RecoveryVerificationResult.invalid({required int attemptsRemaining}) {
    return RecoveryVerificationResult._(
      success: false,
      error: 'INVALID_TOKEN',
      attemptsRemaining: attemptsRemaining,
    );
  }

  factory RecoveryVerificationResult.expired() {
    return RecoveryVerificationResult._(
      success: false,
      error: 'TOKEN_EXPIRED',
    );
  }

  factory RecoveryVerificationResult.notFound() {
    return RecoveryVerificationResult._(
      success: false,
      error: 'TOKEN_NOT_FOUND',
    );
  }

  factory RecoveryVerificationResult.maxAttemptsExceeded() {
    return RecoveryVerificationResult._(
      success: false,
      error: 'MAX_ATTEMPTS_EXCEEDED',
      attemptsRemaining: 0,
    );
  }

  factory RecoveryVerificationResult.accountLocked({
    Duration? remainingDuration,
    DateTime? unlocksAt,
  }) {
    return RecoveryVerificationResult._(
      success: false,
      error: 'ACCOUNT_LOCKED',
      remainingDuration: remainingDuration,
      unlocksAt: unlocksAt,
    );
  }

  factory RecoveryVerificationResult.error() {
    return RecoveryVerificationResult._(
      success: false,
      error: 'INTERNAL_ERROR',
    );
  }
}
