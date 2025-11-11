import 'package:serverpod/serverpod.dart';
import '../../services/auth/otp_service.dart';
import '../../services/auth/rate_limit_service.dart';
import '../../services/auth/account_lockout_service.dart';
import '../../services/auth/jwt_service.dart';
import '../../services/auth/social_auth_service.dart';
import '../../services/auth/recovery_service.dart';
import '../../services/email/email_service.dart';
import '../../generated/auth/user.dart';
import '../../generated/auth/session.dart';

/// Authentication endpoint for user identity management
/// Implements Epic 1 - Viewer Authentication with full security controls
class AuthEndpoint extends Endpoint {
  @override
  String get name => 'auth';

  /// Send OTP for email authentication
  /// Rate limited: 3 requests/5min per email
  Future<Map<String, dynamic>> sendOtp(Session session, String email) async {
    try {
      // Validate email format
      if (email.isEmpty || !_isValidEmail(email)) {
        return {
          'success': false,
          'error': 'INVALID_EMAIL',
          'message': 'Invalid email address',
        };
      }

      final normalizedEmail = email.toLowerCase().trim();
      final ipAddress = _getClientIp(session);

      // Check rate limits (Layer 1: per-email, Layer 2: per-IP, Layer 3: global)
      final rateLimitService = RateLimitService(session);
      final rateLimitResult = await rateLimitService.checkRateLimit(
        identifier: normalizedEmail,
        ipAddress: ipAddress,
        action: 'send_otp',
      );

      if (!rateLimitResult.allowed) {
        session.log(
          'Rate limit exceeded for OTP request: $normalizedEmail from $ipAddress',
          level: LogLevel.warning,
        );

        return {
          'success': false,
          'error': 'RATE_LIMIT_EXCEEDED',
          'message': rateLimitResult.reason ?? 'Too many requests',
          'retryAfter': rateLimitResult.retryAfter?.inSeconds ?? 60,
          'resetAt': rateLimitResult.resetAt?.toIso8601String(),
        };
      }

      // Generate OTP
      final otpService = OtpService(session);
      final otp = await otpService.createOTP(normalizedEmail);

      // TODO: Send OTP via email using SendGrid
      // For now, log it (REMOVE IN PRODUCTION!)
      session.log(
        'OTP generated for $normalizedEmail: $otp (DEV ONLY - DO NOT LOG IN PRODUCTION)',
        level: LogLevel.info,
      );

      return {
        'success': true,
        'message': 'OTP sent successfully',
        'expiresIn': 300, // 5 minutes
        'email': normalizedEmail,
        // Include rate limit headers
        'rateLimit': {
          'remaining': rateLimitResult.remaining,
          'resetAt': rateLimitResult.resetAt?.toIso8601String(),
        },
      };
    } catch (e, stackTrace) {
      session.log(
        'Failed to send OTP: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );

      return {
        'success': false,
        'error': 'INTERNAL_ERROR',
        'message': 'Failed to send OTP. Please try again.',
      };
    }
  }

  /// Verify OTP and create authenticated session
  /// Account lockout after failed attempts: 3→5min, 5→30min, 10→1hr, 15→24hr
  Future<Map<String, dynamic>> verifyOtp(
    Session session,
    String email,
    String code, {
    String? deviceId,
  }) async {
    try {
      // Validate inputs
      if (email.isEmpty || !_isValidEmail(email)) {
        return {
          'success': false,
          'error': 'INVALID_EMAIL',
          'message': 'Invalid email address',
        };
      }

      if (code.isEmpty || code.length != 6) {
        return {
          'success': false,
          'error': 'INVALID_CODE',
          'message': 'OTP must be 6 digits',
        };
      }

      final normalizedEmail = email.toLowerCase().trim();
      final ipAddress = _getClientIp(session);

      // Check account lockout status
      final lockoutService = AccountLockoutService(session);
      final lockStatus = await lockoutService.checkLockStatus(
        identifier: normalizedEmail,
        action: 'verify_otp',
      );

      if (lockStatus.isLocked) {
        session.log(
          'Account locked: $normalizedEmail',
          level: LogLevel.warning,
        );

        return {
          'success': false,
          'error': 'ACCOUNT_LOCKED',
          'message': lockStatus.getMessage(),
          'lockedUntil': lockStatus.unlocksAt?.toIso8601String(),
          'remainingSeconds': lockStatus.remainingDuration?.inSeconds,
        };
      }

      // Verify OTP
      final otpService = OtpService(session);
      final verificationResult = await otpService.verifyOTP(
        normalizedEmail,
        code,
      );

      if (!verificationResult.success) {
        // Record failed attempt
        await lockoutService.recordFailedAttempt(
          identifier: normalizedEmail,
          action: 'verify_otp',
        );

        session.log(
          'Failed OTP verification: $normalizedEmail (${verificationResult.message})',
          level: LogLevel.warning,
        );

        return {
          'success': false,
          'error': 'INVALID_CODE',
          'message': verificationResult.message,
          'attemptsRemaining': verificationResult.attempts,
        };
      }

      // OTP verified successfully - clear failed attempts
      await lockoutService.clearFailedAttempts(
        identifier: normalizedEmail,
        action: 'verify_otp',
      );

      // Find or create user
      final user = await _findOrCreateUser(session, normalizedEmail);

      // Generate JWT tokens
      final jwtService = JwtService(session);
      await jwtService.initialize();

      final sessionId = _generateSessionId();
      final actualDeviceId = deviceId ?? _generateDeviceId();

      final accessToken = await jwtService.generateAccessToken(
        userId: user.id!,
        email: user.email!,
        deviceId: actualDeviceId,
        sessionId: sessionId,
      );

      final refreshToken = await jwtService.generateRefreshToken(
        userId: user.id!,
        email: user.email!,
        deviceId: actualDeviceId,
        sessionId: sessionId,
      );

      // Create session record in database
      final userSession = UserSession(
        userId: user.id!,
        accessToken: accessToken,
        refreshToken: refreshToken,
        deviceId: actualDeviceId,
        ipAddress: ipAddress,
        accessTokenExpiry: DateTime.now().add(Duration(minutes: 15)),
        refreshTokenExpiry: DateTime.now().add(Duration(days: 30)),
        isRevoked: false,
        createdAt: DateTime.now(),
        lastUsedAt: DateTime.now(),
      );

      await UserSession.db.insertRow(session, userSession);

      session.log(
        'User authenticated successfully: $normalizedEmail (userId: ${user.id})',
        level: LogLevel.info,
      );

      return {
        'success': true,
        'message': 'Authentication successful',
        'user': {
          'id': user.id,
          'email': user.email,
          'createdAt': user.createdAt.toIso8601String(),
        },
        'tokens': {
          'accessToken': accessToken,
          'refreshToken': refreshToken,
          'expiresIn': 900, // 15 minutes
        },
        'session': {
          'sessionId': sessionId,
          'deviceId': actualDeviceId,
        },
      };
    } catch (e, stackTrace) {
      session.log(
        'Failed to verify OTP: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );

      return {
        'success': false,
        'error': 'INTERNAL_ERROR',
        'message': 'Authentication failed. Please try again.',
      };
    }
  }

  /// Refresh access token using refresh token
  /// Implements token rotation with reuse detection
  Future<Map<String, dynamic>> refresh(
    Session session,
    String refreshToken,
  ) async {
    try {
      if (refreshToken.isEmpty) {
        return {
          'success': false,
          'error': 'INVALID_TOKEN',
          'message': 'Refresh token is required',
        };
      }

      final jwtService = JwtService(session);
      await jwtService.initialize();

      // Rotate refresh token (includes reuse detection)
      final rotationResult = await jwtService.rotateRefreshToken(refreshToken);

      if (rotationResult == null) {
        return {
          'success': false,
          'error': 'INVALID_TOKEN',
          'message': 'Invalid or expired refresh token',
        };
      }

      if (rotationResult.reuseDetected) {
        session.log(
          'SECURITY ALERT: Refresh token reuse detected for user ${rotationResult.userId}',
          level: LogLevel.warning,
        );

        return {
          'success': false,
          'error': 'TOKEN_REUSE_DETECTED',
          'message': 'Security violation detected. Please sign in again.',
        };
      }

      session.log(
        'Token refreshed successfully for user ${rotationResult.userId}',
        level: LogLevel.info,
      );

      return {
        'success': true,
        'message': 'Token refreshed successfully',
        'tokens': {
          'accessToken': rotationResult.accessToken,
          'refreshToken': rotationResult.refreshToken,
          'expiresIn': 900, // 15 minutes
        },
      };
    } catch (e, stackTrace) {
      session.log(
        'Failed to refresh token: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );

      return {
        'success': false,
        'error': 'INTERNAL_ERROR',
        'message': 'Failed to refresh token. Please sign in again.',
      };
    }
  }

  /// Logout and blacklist tokens
  Future<Map<String, dynamic>> logout(
    Session session,
    String accessToken,
    String refreshToken,
  ) async {
    try {
      final jwtService = JwtService(session);
      await jwtService.initialize();

      // Verify and blacklist both tokens
      final accessClaims = await jwtService.verifyAccessToken(accessToken);
      if (accessClaims != null) {
        await jwtService.blacklistToken(
          accessToken,
          accessClaims.expiresAt ?? DateTime.now().add(Duration(minutes: 15)),
        );
      }

      final refreshClaims = await jwtService.verifyRefreshToken(refreshToken);
      if (refreshClaims != null) {
        await jwtService.blacklistToken(
          refreshToken,
          refreshClaims.expiresAt ?? DateTime.now().add(Duration(days: 30)),
        );
      }

      session.log(
        'User logged out successfully',
        level: LogLevel.info,
      );

      return {
        'success': true,
        'message': 'Logged out successfully',
      };
    } catch (e, stackTrace) {
      session.log(
        'Failed to logout: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );

      return {
        'success': false,
        'error': 'INTERNAL_ERROR',
        'message': 'Logout failed. Please try again.',
      };
    }
  }

  /// Verify Apple Sign-In token and create/link account
  /// Implements account reconciliation to prevent duplicates
  Future<Map<String, dynamic>> verifyAppleToken(
    Session session,
    String idToken, {
    String? deviceId,
  }) async {
    try {
      if (idToken.isEmpty) {
        return {
          'success': false,
          'error': 'INVALID_TOKEN',
          'message': 'Apple ID token is required',
        };
      }

      final socialAuthService = SocialAuthService(session);

      // Verify Apple ID token
      final socialAuth = await socialAuthService.verifyAppleToken(idToken);

      if (socialAuth == null) {
        return {
          'success': false,
          'error': 'INVALID_TOKEN',
          'message': 'Failed to verify Apple ID token',
        };
      }

      // Reconcile account (find existing or create new)
      final user = await socialAuthService.reconcileAccount(socialAuth);

      // Generate JWT tokens (same as email OTP flow)
      final jwtService = JwtService(session);
      await jwtService.initialize();

      final sessionId = _generateSessionId();
      final actualDeviceId = deviceId ?? _generateDeviceId();
      final ipAddress = _getClientIp(session);

      final accessToken = await jwtService.generateAccessToken(
        userId: user.id!,
        email: user.email!,
        deviceId: actualDeviceId,
        sessionId: sessionId,
      );

      final refreshToken = await jwtService.generateRefreshToken(
        userId: user.id!,
        email: user.email!,
        deviceId: actualDeviceId,
        sessionId: sessionId,
      );

      // Create session record
      final userSession = UserSession(
        userId: user.id!,
        accessToken: accessToken,
        refreshToken: refreshToken,
        deviceId: actualDeviceId,
        ipAddress: ipAddress,
        accessTokenExpiry: DateTime.now().add(Duration(minutes: 15)),
        refreshTokenExpiry: DateTime.now().add(Duration(days: 30)),
        isRevoked: false,
        createdAt: DateTime.now(),
        lastUsedAt: DateTime.now(),
      );

      await UserSession.db.insertRow(session, userSession);

      session.log(
        'Apple Sign-In successful: ${user.email} (userId: ${user.id})',
        level: LogLevel.info,
      );

      return {
        'success': true,
        'message': 'Apple Sign-In successful',
        'provider': 'apple',
        'user': {
          'id': user.id,
          'email': user.email,
          'createdAt': user.createdAt.toIso8601String(),
        },
        'tokens': {
          'accessToken': accessToken,
          'refreshToken': refreshToken,
          'expiresIn': 900, // 15 minutes
        },
        'session': {
          'sessionId': sessionId,
          'deviceId': actualDeviceId,
        },
      };
    } catch (e, stackTrace) {
      session.log(
        'Failed to verify Apple token: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );

      return {
        'success': false,
        'error': 'INTERNAL_ERROR',
        'message': 'Apple Sign-In failed. Please try again.',
      };
    }
  }

  /// Verify Google Sign-In token and create/link account
  /// Implements account reconciliation to prevent duplicates
  Future<Map<String, dynamic>> verifyGoogleToken(
    Session session,
    String idToken, {
    String? deviceId,
  }) async {
    try {
      if (idToken.isEmpty) {
        return {
          'success': false,
          'error': 'INVALID_TOKEN',
          'message': 'Google ID token is required',
        };
      }

      final socialAuthService = SocialAuthService(session);

      // Verify Google ID token
      final socialAuth = await socialAuthService.verifyGoogleToken(idToken);

      if (socialAuth == null) {
        return {
          'success': false,
          'error': 'INVALID_TOKEN',
          'message': 'Failed to verify Google ID token',
        };
      }

      // Reconcile account (find existing or create new)
      final user = await socialAuthService.reconcileAccount(socialAuth);

      // Generate JWT tokens (same as email OTP flow)
      final jwtService = JwtService(session);
      await jwtService.initialize();

      final sessionId = _generateSessionId();
      final actualDeviceId = deviceId ?? _generateDeviceId();
      final ipAddress = _getClientIp(session);

      final accessToken = await jwtService.generateAccessToken(
        userId: user.id!,
        email: user.email!,
        deviceId: actualDeviceId,
        sessionId: sessionId,
      );

      final refreshToken = await jwtService.generateRefreshToken(
        userId: user.id!,
        email: user.email!,
        deviceId: actualDeviceId,
        sessionId: sessionId,
      );

      // Create session record
      final userSession = UserSession(
        userId: user.id!,
        accessToken: accessToken,
        refreshToken: refreshToken,
        deviceId: actualDeviceId,
        ipAddress: ipAddress,
        accessTokenExpiry: DateTime.now().add(Duration(minutes: 15)),
        refreshTokenExpiry: DateTime.now().add(Duration(days: 30)),
        isRevoked: false,
        createdAt: DateTime.now(),
        lastUsedAt: DateTime.now(),
      );

      await UserSession.db.insertRow(session, userSession);

      session.log(
        'Google Sign-In successful: ${user.email} (userId: ${user.id})',
        level: LogLevel.info,
      );

      return {
        'success': true,
        'message': 'Google Sign-In successful',
        'provider': 'google',
        'user': {
          'id': user.id,
          'email': user.email,
          'createdAt': user.createdAt.toIso8601String(),
        },
        'tokens': {
          'accessToken': accessToken,
          'refreshToken': refreshToken,
          'expiresIn': 900, // 15 minutes
        },
        'session': {
          'sessionId': sessionId,
          'deviceId': actualDeviceId,
        },
      };
    } catch (e, stackTrace) {
      session.log(
        'Failed to verify Google token: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );

      return {
        'success': false,
        'error': 'INTERNAL_ERROR',
        'message': 'Google Sign-In failed. Please try again.',
      };
    }
  }

  // Helper methods

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  String _getClientIp(Session session) {
    // For Serverpod, we'll use a placeholder IP for now
    // In production, this would be extracted from request headers via API gateway
    // TODO: Extract real IP from request context when available
    return '0.0.0.0';
  }

  Future<User> _findOrCreateUser(Session session, String email) async {
    // Try to find existing user
    final existingUsers = await User.db.find(
      session,
      where: (t) => t.email.equals(email),
      limit: 1,
    );

    if (existingUsers.isNotEmpty) {
      return existingUsers.first;
    }

    // Create new user with all required fields
    final newUser = User(
      email: email,
      role: 'viewer', // Default role
      authProvider: 'email',
      isEmailVerified: false, // Will be verified after OTP
      isPhoneVerified: false,
      isActive: true,
      failedAttempts: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return await User.db.insertRow(session, newUser);
  }

  String _generateSessionId() {
    return 'sess_${DateTime.now().millisecondsSinceEpoch}_${_randomString(16)}';
  }

  String _generateDeviceId() {
    return 'dev_${DateTime.now().millisecondsSinceEpoch}_${_randomString(16)}';
  }

  String _randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().microsecondsSinceEpoch;
    return List.generate(length, (i) => chars[(random + i) % chars.length])
        .join();
  }

  /// Send account recovery email
  /// AC1: Issues one-time recovery token with 15-minute expiry
  /// AC2: Email includes device + location metadata
  Future<Map<String, dynamic>> sendRecovery(
    Session session,
    String email, {
    String? deviceInfo,
    String? userAgent,
    String? location,
  }) async {
    try {
      // Validate email format
      if (email.isEmpty || !_isValidEmail(email)) {
        return {
          'success': false,
          'error': 'INVALID_EMAIL',
          'message': 'Invalid email address',
        };
      }

      final normalizedEmail = email.toLowerCase().trim();
      final ipAddress = _getClientIp(session);

      final recoveryService = RecoveryService(session);
      final result = await recoveryService.createRecoveryToken(
        email: normalizedEmail,
        deviceInfo: deviceInfo,
        ipAddress: ipAddress,
        userAgent: userAgent,
        location: location,
      );

      if (!result.success) {
        if (result.error == 'RATE_LIMIT_EXCEEDED') {
          return {
            'success': false,
            'error': 'RATE_LIMIT_EXCEEDED',
            'message': 'Too many recovery requests. Please try again later.',
            'retryAfter': result.retryAfter?.inSeconds ?? 300,
            'resetAt': result.unlocksAt?.toIso8601String(),
          };
        } else if (result.error == 'ACCOUNT_LOCKED') {
          return {
            'success': false,
            'error': 'ACCOUNT_LOCKED',
            'message': 'Account is temporarily locked due to failed attempts.',
            'lockedUntil': result.unlocksAt?.toIso8601String(),
            'remainingSeconds': result.retryAfter?.inSeconds,
          };
        } else {
          return {
            'success': false,
            'error': 'INTERNAL_ERROR',
            'message': 'Failed to send recovery email. Please try again.',
          };
        }
      }

      // If user exists, send recovery email
      if (result.userExists == true && result.token != null) {
        final emailService = EmailService(session);
        final emailSent = await emailService.sendRecoveryEmail(
          to: normalizedEmail,
          token: result.token!,
          deviceInfo: deviceInfo ?? 'Unknown device',
          ipAddress: ipAddress,
          userAgent: userAgent,
          location: location,
        );

        if (!emailSent) {
          session.log(
            'Warning: Recovery email failed to send to $normalizedEmail',
            level: LogLevel.warning,
          );
          // Don't fail the request - security consideration: don't reveal if email exists
        }

        session.log(
          'Recovery email sent to $normalizedEmail (userId: ${result.userId})',
          level: LogLevel.info,
        );

        // Emit analytics event: recovery started
        session.log(
          'ANALYTICS: auth_recovery_started',
          level: LogLevel.info,
        );
      }

      // Always return success (don't reveal if email exists)
      return {
        'success': true,
        'message':
            'If this email is registered, you will receive recovery instructions.',
        'expiresIn': 900, // 15 minutes
      };
    } catch (e, stackTrace) {
      session.log(
        'Failed to send recovery email: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );

      return {
        'success': false,
        'error': 'INTERNAL_ERROR',
        'message': 'Failed to send recovery email. Please try again.',
      };
    }
  }

  /// Verify recovery token and create authenticated session
  /// AC3: Allows re-authentication and forces session rotation
  /// AC4: Brute force protection (3 attempts = 30 min lockout)
  /// AC5: Invalidates all active sessions on success
  Future<Map<String, dynamic>> verifyRecovery(
    Session session,
    String email,
    String token, {
    String? deviceId,
  }) async {
    try {
      // Validate inputs
      if (email.isEmpty || !_isValidEmail(email)) {
        return {
          'success': false,
          'error': 'INVALID_EMAIL',
          'message': 'Invalid email address',
        };
      }

      if (token.isEmpty) {
        return {
          'success': false,
          'error': 'INVALID_TOKEN',
          'message': 'Recovery token is required',
        };
      }

      final normalizedEmail = email.toLowerCase().trim();
      final ipAddress = _getClientIp(session);

      final recoveryService = RecoveryService(session);
      final result = await recoveryService.verifyRecoveryToken(
        email: normalizedEmail,
        token: token,
        ipAddress: ipAddress,
      );

      if (!result.success) {
        if (result.error == 'ACCOUNT_LOCKED') {
          return {
            'success': false,
            'error': 'ACCOUNT_LOCKED',
            'message': 'Account is temporarily locked. Please try again later.',
            'lockedUntil': result.unlocksAt?.toIso8601String(),
            'remainingSeconds': result.remainingDuration?.inSeconds,
          };
        } else if (result.error == 'TOKEN_EXPIRED') {
          return {
            'success': false,
            'error': 'TOKEN_EXPIRED',
            'message': 'Recovery token has expired. Please request a new one.',
          };
        } else if (result.error == 'TOKEN_NOT_FOUND') {
          return {
            'success': false,
            'error': 'TOKEN_NOT_FOUND',
            'message':
                'No active recovery token found. Please request a new one.',
          };
        } else if (result.error == 'MAX_ATTEMPTS_EXCEEDED') {
          return {
            'success': false,
            'error': 'MAX_ATTEMPTS_EXCEEDED',
            'message':
                'Too many failed attempts. Account locked for 30 minutes.',
            'attemptsRemaining': 0,
          };
        } else if (result.error == 'INVALID_TOKEN') {
          return {
            'success': false,
            'error': 'INVALID_TOKEN',
            'message': 'Invalid recovery token.',
            'attemptsRemaining': result.attemptsRemaining,
          };
        } else {
          return {
            'success': false,
            'error': 'INTERNAL_ERROR',
            'message': 'Recovery verification failed. Please try again.',
          };
        }
      }

      // Token verified successfully
      // AC5: Invalidate all active sessions before creating new one
      await recoveryService.invalidateAllSessions(result.userId!);

      // Find user
      final user = await _findOrCreateUser(session, normalizedEmail);

      // Generate new JWT tokens (force re-authentication)
      final jwtService = JwtService(session);
      await jwtService.initialize();

      final sessionId = _generateSessionId();
      final actualDeviceId = deviceId ?? _generateDeviceId();

      final accessToken = await jwtService.generateAccessToken(
        userId: user.id!,
        email: user.email!,
        deviceId: actualDeviceId,
        sessionId: sessionId,
      );

      final refreshToken = await jwtService.generateRefreshToken(
        userId: user.id!,
        email: user.email!,
        deviceId: actualDeviceId,
        sessionId: sessionId,
      );

      // Create new session record
      final userSession = UserSession(
        userId: user.id!,
        accessToken: accessToken,
        refreshToken: refreshToken,
        deviceId: actualDeviceId,
        ipAddress: ipAddress,
        accessTokenExpiry: DateTime.now().add(Duration(minutes: 15)),
        refreshTokenExpiry: DateTime.now().add(Duration(days: 30)),
        isRevoked: false,
        createdAt: DateTime.now(),
        lastUsedAt: DateTime.now(),
      );

      await UserSession.db.insertRow(session, userSession);

      session.log(
        'Account recovered successfully: $normalizedEmail (userId: ${user.id})',
        level: LogLevel.info,
      );

      // Emit analytics event: recovery completed successfully
      session.log(
        'ANALYTICS: auth_recovery_completed',
        level: LogLevel.info,
      );

      return {
        'success': true,
        'message': 'Account recovered successfully',
        'user': {
          'id': user.id,
          'email': user.email,
          'createdAt': user.createdAt.toIso8601String(),
        },
        'tokens': {
          'accessToken': accessToken,
          'refreshToken': refreshToken,
          'expiresIn': 900, // 15 minutes
        },
        'session': {
          'sessionId': sessionId,
          'deviceId': actualDeviceId,
        },
      };
    } catch (e, stackTrace) {
      session.log(
        'Failed to verify recovery token: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );

      return {
        'success': false,
        'error': 'INTERNAL_ERROR',
        'message': 'Recovery verification failed. Please try again.',
      };
    }
  }

  /// Revoke recovery token immediately
  /// AC2: "Not You?" link revokes token and alerts user
  Future<Map<String, dynamic>> revokeRecovery(
    Session session,
    String email,
    String token,
  ) async {
    try {
      // Validate inputs
      if (email.isEmpty || !_isValidEmail(email)) {
        return {
          'success': false,
          'error': 'INVALID_EMAIL',
          'message': 'Invalid email address',
        };
      }

      if (token.isEmpty) {
        return {
          'success': false,
          'error': 'INVALID_TOKEN',
          'message': 'Recovery token is required',
        };
      }

      final normalizedEmail = email.toLowerCase().trim();

      final recoveryService = RecoveryService(session);
      final revoked = await recoveryService.revokeRecoveryToken(
        token: token,
        email: normalizedEmail,
      );

      if (!revoked) {
        return {
          'success': false,
          'error': 'TOKEN_NOT_FOUND',
          'message': 'Recovery token not found or already revoked.',
        };
      }

      session.log(
        'Recovery token revoked by user: $normalizedEmail',
        level: LogLevel.warning,
      );

      // Emit analytics event: recovery revoked (Not You? link)
      session.log(
        'ANALYTICS: auth_recovery_revoked',
        level: LogLevel.info,
      );

      return {
        'success': true,
        'message':
            'Recovery token revoked successfully. A security alert has been sent to your email.',
      };
    } catch (e, stackTrace) {
      session.log(
        'Failed to revoke recovery token: $e',
        level: LogLevel.error,
        exception: e,
        stackTrace: stackTrace,
      );

      return {
        'success': false,
        'error': 'INTERNAL_ERROR',
        'message': 'Failed to revoke token. Please try again.',
      };
    }
  }
}
