import 'package:core/data/repositories/auth_repository.dart';

/// Account Recovery Use Case
/// Handles account recovery flow:
/// 1. Send recovery token request
/// 2. Verify recovery token
/// 3. Handle session rotation after successful recovery
///
/// AC3: Recovery use case with success/failure handling
class AccountRecoveryUseCase {
  final AuthRepository _authRepository;

  AccountRecoveryUseCase(this._authRepository);

  /// Send recovery token to user's email
  /// Returns success even if email doesn't exist (security consideration)
  Future<RecoveryRequestResult> sendRecoveryToken({
    required String email,
  }) async {
    try {
      // Call server endpoint to send recovery email
      final response = await _authRepository.sendRecovery(
        email: email,
      );

      if (response['success'] == true) {
        return RecoveryRequestResult.success(
          message: response['message'] as String? ?? 'Recovery email sent',
        );
      } else {
        return RecoveryRequestResult.failure(
          error: response['error'] as String? ?? 'UNKNOWN_ERROR',
          message:
              response['message'] as String? ?? 'Failed to send recovery email',
          retryAfter: response['retryAfter'] as int?,
        );
      }
    } catch (e) {
      return RecoveryRequestResult.failure(
        error: 'NETWORK_ERROR',
        message: 'Network error. Please check your connection.',
      );
    }
  }

  /// Verify recovery token and authenticate user
  /// AC5: Forces session rotation and invalidates all existing sessions
  Future<RecoveryVerificationResult> verifyRecoveryToken({
    required String email,
    required String token,
  }) async {
    try {
      // Call server endpoint to verify recovery token
      final response = await _authRepository.verifyRecovery(
        email: email,
        token: token,
      );

      if (response['success'] == true) {
        final tokens = response['tokens'] as Map<String, dynamic>;
        final user = response['user'] as Map<String, dynamic>;

        return RecoveryVerificationResult.success(
          accessToken: tokens['accessToken'] as String,
          refreshToken: tokens['refreshToken'] as String,
          userId: user['id'] as int,
          email: user['email'] as String,
        );
      } else {
        return RecoveryVerificationResult.failure(
          error: response['error'] as String? ?? 'UNKNOWN_ERROR',
          message: response['message'] as String? ??
              'Failed to verify recovery token',
          attemptsRemaining: response['attemptsRemaining'] as int?,
          retryAfter: response['remainingSeconds'] as int?,
        );
      }
    } catch (e) {
      return RecoveryVerificationResult.failure(
        error: 'NETWORK_ERROR',
        message: 'Network error. Please check your connection.',
      );
    }
  }

  /// Revoke a recovery token
  /// AC2: "Not You?" functionality
  Future<bool> revokeRecoveryToken({
    required String email,
    required String token,
  }) async {
    try {
      final response = await _authRepository.revokeRecovery(
        email: email,
        token: token,
      );

      return response['success'] == true;
    } catch (e) {
      return false;
    }
  }
}

/// Result of recovery token request
class RecoveryRequestResult {
  final bool success;
  final String message;
  final String? error;
  final int? retryAfter;

  RecoveryRequestResult._({
    required this.success,
    required this.message,
    this.error,
    this.retryAfter,
  });

  factory RecoveryRequestResult.success({required String message}) {
    return RecoveryRequestResult._(
      success: true,
      message: message,
    );
  }

  factory RecoveryRequestResult.failure({
    required String error,
    required String message,
    int? retryAfter,
  }) {
    return RecoveryRequestResult._(
      success: false,
      message: message,
      error: error,
      retryAfter: retryAfter,
    );
  }
}

/// Result of recovery token verification
class RecoveryVerificationResult {
  final bool success;
  final String? accessToken;
  final String? refreshToken;
  final int? userId;
  final String? email;
  final String? error;
  final String? message;
  final int? attemptsRemaining;
  final int? retryAfter;

  RecoveryVerificationResult._({
    required this.success,
    this.accessToken,
    this.refreshToken,
    this.userId,
    this.email,
    this.error,
    this.message,
    this.attemptsRemaining,
    this.retryAfter,
  });

  factory RecoveryVerificationResult.success({
    required String accessToken,
    required String refreshToken,
    required int userId,
    required String email,
  }) {
    return RecoveryVerificationResult._(
      success: true,
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: userId,
      email: email,
    );
  }

  factory RecoveryVerificationResult.failure({
    required String error,
    required String message,
    int? attemptsRemaining,
    int? retryAfter,
  }) {
    return RecoveryVerificationResult._(
      success: false,
      error: error,
      message: message,
      attemptsRemaining: attemptsRemaining,
      retryAfter: retryAfter,
    );
  }
}
