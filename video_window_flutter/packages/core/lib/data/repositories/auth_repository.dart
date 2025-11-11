import 'package:video_window_client/video_window_client.dart';

/// Repository for authentication operations
/// Communicates with Serverpod backend auth endpoints
class AuthRepository {
  final Client _client;

  AuthRepository({required Client client}) : _client = client;

  /// Send OTP to email address
  /// Returns success status and rate limit information
  Future<SendOtpResult> sendOtp(String email) async {
    try {
      final result = await _client.auth.sendOtp(email);

      if (result['success'] == true) {
        return SendOtpResult.success(
          email: result['email'] as String,
          expiresIn: result['expiresIn'] as int,
          rateLimit: result['rateLimit'] != null
              ? RateLimitInfo.fromJson(
                  result['rateLimit'] as Map<String, dynamic>)
              : null,
        );
      } else {
        return SendOtpResult.failure(
          error: result['error'] as String? ?? 'UNKNOWN_ERROR',
          message: result['message'] as String? ?? 'Failed to send OTP',
          retryAfter: result['retryAfter'] as int?,
        );
      }
    } catch (e) {
      return SendOtpResult.failure(
        error: 'NETWORK_ERROR',
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  /// Verify OTP and authenticate user
  /// Returns tokens and user information on success
  Future<VerifyOtpResult> verifyOtp({
    required String email,
    required String code,
    String? deviceId,
  }) async {
    try {
      final result = await _client.auth.verifyOtp(
        email,
        code,
        deviceId: deviceId,
      );

      if (result['success'] == true) {
        return VerifyOtpResult.success(
          user: AuthUser.fromJson(result['user'] as Map<String, dynamic>),
          tokens: AuthTokens.fromJson(result['tokens'] as Map<String, dynamic>),
          session:
              SessionInfo.fromJson(result['session'] as Map<String, dynamic>),
        );
      } else {
        return VerifyOtpResult.failure(
          error: result['error'] as String? ?? 'UNKNOWN_ERROR',
          message: result['message'] as String? ?? 'Failed to verify OTP',
          attemptsRemaining: result['attemptsRemaining'] as int?,
          lockedUntil: result['lockedUntil'] as String?,
        );
      }
    } catch (e) {
      return VerifyOtpResult.failure(
        error: 'NETWORK_ERROR',
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  /// Refresh access token using refresh token
  Future<RefreshTokenResult> refreshToken(String refreshToken) async {
    try {
      final result = await _client.auth.refresh(refreshToken);

      if (result['success'] == true) {
        return RefreshTokenResult.success(
          tokens: AuthTokens.fromJson(result['tokens'] as Map<String, dynamic>),
        );
      } else {
        return RefreshTokenResult.failure(
          error: result['error'] as String? ?? 'UNKNOWN_ERROR',
          message: result['message'] as String? ?? 'Failed to refresh token',
        );
      }
    } catch (e) {
      return RefreshTokenResult.failure(
        error: 'NETWORK_ERROR',
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  /// Logout and invalidate tokens
  Future<LogoutResult> logout({
    required String accessToken,
    required String refreshToken,
  }) async {
    try {
      final result = await _client.auth.logout(accessToken, refreshToken);

      if (result['success'] == true) {
        return LogoutResult.success();
      } else {
        return LogoutResult.failure(
          error: result['error'] as String? ?? 'UNKNOWN_ERROR',
          message: result['message'] as String? ?? 'Failed to logout',
        );
      }
    } catch (e) {
      return LogoutResult.failure(
        error: 'NETWORK_ERROR',
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  /// Verify Apple Sign-In token and authenticate user
  /// Returns tokens and user information on success
  Future<VerifyOtpResult> verifyAppleToken({
    required String idToken,
    String? deviceId,
  }) async {
    try {
      final result = await _client.auth.verifyAppleToken(
        idToken,
        deviceId: deviceId,
      );

      if (result['success'] == true) {
        return VerifyOtpResult.success(
          user: AuthUser.fromJson(result['user'] as Map<String, dynamic>),
          tokens: AuthTokens.fromJson(result['tokens'] as Map<String, dynamic>),
          session:
              SessionInfo.fromJson(result['session'] as Map<String, dynamic>),
        );
      } else {
        return VerifyOtpResult.failure(
          error: result['error'] as String? ?? 'UNKNOWN_ERROR',
          message:
              result['message'] as String? ?? 'Failed to verify Apple Sign-In',
        );
      }
    } catch (e) {
      return VerifyOtpResult.failure(
        error: 'NETWORK_ERROR',
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  /// Verify Google Sign-In token and authenticate user
  /// Returns tokens and user information on success
  Future<VerifyOtpResult> verifyGoogleToken({
    required String idToken,
    String? deviceId,
  }) async {
    try {
      final result = await _client.auth.verifyGoogleToken(
        idToken,
        deviceId: deviceId,
      );

      if (result['success'] == true) {
        return VerifyOtpResult.success(
          user: AuthUser.fromJson(result['user'] as Map<String, dynamic>),
          tokens: AuthTokens.fromJson(result['tokens'] as Map<String, dynamic>),
          session:
              SessionInfo.fromJson(result['session'] as Map<String, dynamic>),
        );
      } else {
        return VerifyOtpResult.failure(
          error: result['error'] as String? ?? 'UNKNOWN_ERROR',
          message:
              result['message'] as String? ?? 'Failed to verify Google Sign-In',
        );
      }
    } catch (e) {
      return VerifyOtpResult.failure(
        error: 'NETWORK_ERROR',
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  /// Send recovery token to email address
  /// Story 1-4: Account Recovery
  Future<Map<String, dynamic>> sendRecovery({
    required String email,
  }) async {
    try {
      final result = await _client.auth.sendRecovery(
        email,
        deviceInfo: null,
        userAgent: null,
        location: null,
      );
      return result;
    } catch (e) {
      return {
        'success': false,
        'error': 'NETWORK_ERROR',
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Verify recovery token and authenticate user
  /// Story 1-4: Account Recovery
  Future<Map<String, dynamic>> verifyRecovery({
    required String email,
    required String token,
  }) async {
    try {
      final result = await _client.auth.verifyRecovery(
        email,
        token,
        deviceId: null,
      );
      return result;
    } catch (e) {
      return {
        'success': false,
        'error': 'NETWORK_ERROR',
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Revoke recovery token
  /// Story 1-4: Account Recovery - "Not You?" link
  Future<Map<String, dynamic>> revokeRecovery({
    required String email,
    required String token,
  }) async {
    try {
      final result = await _client.auth.revokeRecovery(email, token);
      return result;
    } catch (e) {
      return {
        'success': false,
        'error': 'NETWORK_ERROR',
        'message': 'Network error: ${e.toString()}',
      };
    }
  }
}

// Result classes

class SendOtpResult {
  final bool success;
  final String? email;
  final int? expiresIn;
  final RateLimitInfo? rateLimit;
  final String? error;
  final String? message;
  final int? retryAfter;

  SendOtpResult._({
    required this.success,
    this.email,
    this.expiresIn,
    this.rateLimit,
    this.error,
    this.message,
    this.retryAfter,
  });

  factory SendOtpResult.success({
    required String email,
    required int expiresIn,
    RateLimitInfo? rateLimit,
  }) {
    return SendOtpResult._(
      success: true,
      email: email,
      expiresIn: expiresIn,
      rateLimit: rateLimit,
    );
  }

  factory SendOtpResult.failure({
    required String error,
    required String message,
    int? retryAfter,
  }) {
    return SendOtpResult._(
      success: false,
      error: error,
      message: message,
      retryAfter: retryAfter,
    );
  }
}

class VerifyOtpResult {
  final bool success;
  final AuthUser? user;
  final AuthTokens? tokens;
  final SessionInfo? session;
  final String? error;
  final String? message;
  final int? attemptsRemaining;
  final String? lockedUntil;

  VerifyOtpResult._({
    required this.success,
    this.user,
    this.tokens,
    this.session,
    this.error,
    this.message,
    this.attemptsRemaining,
    this.lockedUntil,
  });

  factory VerifyOtpResult.success({
    required AuthUser user,
    required AuthTokens tokens,
    required SessionInfo session,
  }) {
    return VerifyOtpResult._(
      success: true,
      user: user,
      tokens: tokens,
      session: session,
    );
  }

  factory VerifyOtpResult.failure({
    required String error,
    required String message,
    int? attemptsRemaining,
    String? lockedUntil,
  }) {
    return VerifyOtpResult._(
      success: false,
      error: error,
      message: message,
      attemptsRemaining: attemptsRemaining,
      lockedUntil: lockedUntil,
    );
  }
}

class RefreshTokenResult {
  final bool success;
  final AuthTokens? tokens;
  final String? error;
  final String? message;

  RefreshTokenResult._({
    required this.success,
    this.tokens,
    this.error,
    this.message,
  });

  factory RefreshTokenResult.success({required AuthTokens tokens}) {
    return RefreshTokenResult._(
      success: true,
      tokens: tokens,
    );
  }

  factory RefreshTokenResult.failure({
    required String error,
    required String message,
  }) {
    return RefreshTokenResult._(
      success: false,
      error: error,
      message: message,
    );
  }
}

class LogoutResult {
  final bool success;
  final String? error;
  final String? message;

  LogoutResult._({
    required this.success,
    this.error,
    this.message,
  });

  factory LogoutResult.success() {
    return LogoutResult._(success: true);
  }

  factory LogoutResult.failure({
    required String error,
    required String message,
  }) {
    return LogoutResult._(
      success: false,
      error: error,
      message: message,
    );
  }
}

// Data classes

class AuthUser {
  final int id;
  final String email;
  final String createdAt;

  AuthUser({
    required this.id,
    required this.email,
    required this.createdAt,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as int,
      email: json['email'] as String,
      createdAt: json['createdAt'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'createdAt': createdAt,
    };
  }
}

class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresIn: json['expiresIn'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresIn': expiresIn,
    };
  }
}

class SessionInfo {
  final String sessionId;
  final String deviceId;

  SessionInfo({
    required this.sessionId,
    required this.deviceId,
  });

  factory SessionInfo.fromJson(Map<String, dynamic> json) {
    return SessionInfo(
      sessionId: json['sessionId'] as String,
      deviceId: json['deviceId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'deviceId': deviceId,
    };
  }
}

class RateLimitInfo {
  final int? remaining;
  final String? resetAt;

  RateLimitInfo({
    this.remaining,
    this.resetAt,
  });

  factory RateLimitInfo.fromJson(Map<String, dynamic> json) {
    return RateLimitInfo(
      remaining: json['remaining'] as int?,
      resetAt: json['resetAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'remaining': remaining,
      'resetAt': resetAt,
    };
  }
}
