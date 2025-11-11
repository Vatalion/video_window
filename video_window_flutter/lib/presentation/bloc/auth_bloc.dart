import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../src/services/secure_token_storage.dart';
import 'package:core/data/repositories/auth_repository.dart';
import 'package:core/data/services/auth/session_service.dart';

/// Global authentication BLoC
/// Manages authentication state including:
/// - User login/logout status
/// - Session management
/// - Authentication tokens
/// - User profile data
///
/// Implements OTP-based email authentication flow

// Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthOtpSendRequested extends AuthEvent {
  final String email;

  const AuthOtpSendRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

class AuthOtpVerifyRequested extends AuthEvent {
  final String email;
  final String code;

  const AuthOtpVerifyRequested({
    required this.email,
    required this.code,
  });

  @override
  List<Object?> get props => [email, code];
}

class AuthRefreshRequested extends AuthEvent {
  const AuthRefreshRequested();
}

class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

class AuthAppleSignInRequested extends AuthEvent {
  final String idToken;

  const AuthAppleSignInRequested({required this.idToken});

  @override
  List<Object?> get props => [idToken];
}

class AuthGoogleSignInRequested extends AuthEvent {
  final String idToken;

  const AuthGoogleSignInRequested({required this.idToken});

  @override
  List<Object?> get props => [idToken];
}

// States
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthOtpSent extends AuthState {
  final String email;
  final int expiresIn;
  final int? remainingAttempts;

  const AuthOtpSent({
    required this.email,
    required this.expiresIn,
    this.remainingAttempts,
  });

  @override
  List<Object?> get props => [email, expiresIn, remainingAttempts];
}

class AuthAuthenticated extends AuthState {
  final AuthUser user;

  const AuthAuthenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  final String? errorCode;
  final int? retryAfter;

  const AuthError({
    required this.message,
    this.errorCode,
    this.retryAfter,
  });

  @override
  List<Object?> get props => [message, errorCode, retryAfter];
}

class AuthAccountLocked extends AuthState {
  final String message;
  final String? lockedUntil;

  const AuthAccountLocked({
    required this.message,
    this.lockedUntil,
  });

  @override
  List<Object?> get props => [message, lockedUntil];
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final SecureTokenStorage _tokenStorage;
  final SessionService? _sessionService; // Optional for backward compatibility

  AuthBloc({
    required AuthRepository authRepository,
    required SecureTokenStorage tokenStorage,
    SessionService? sessionService,
  })  : _authRepository = authRepository,
        _tokenStorage = tokenStorage,
        _sessionService = sessionService,
        super(const AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthOtpSendRequested>(_onOtpSendRequested);
    on<AuthOtpVerifyRequested>(_onOtpVerifyRequested);
    on<AuthRefreshRequested>(_onRefreshRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<AuthAppleSignInRequested>(_onAppleSignInRequested);
    on<AuthGoogleSignInRequested>(_onGoogleSignInRequested);

    // Initialize session service if provided (Story 1-3)
    if (_sessionService != null) {
      _initializeSessionService();
    }
  }

  /// Initialize session service and resume refresh schedule
  Future<void> _initializeSessionService() async {
    try {
      final hasSession = await _sessionService!.initialize();
      if (hasSession) {
        // Session service will handle automatic refresh
        debugPrint('Session service initialized with active session');
      }
    } catch (e) {
      debugPrint('Failed to initialize session service: $e');
    }
  }

  @override
  Future<void> close() {
    _sessionService?.dispose();
    return super.close();
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _tokenStorage.initialize();

      final isAuthenticated = await _tokenStorage.isAuthenticated();

      if (isAuthenticated) {
        final session = await _tokenStorage.getAuthSession();
        if (session != null) {
          // TODO: Verify token with backend
          // For now, assume valid if exists
          emit(AuthAuthenticated(
            user: AuthUser(
              id: session.userId,
              email: '', // Would need to fetch or store email
              createdAt: DateTime.now().toIso8601String(),
            ),
          ));
          return;
        }
      }

      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(message: 'Failed to check authentication: $e'));
    }
  }

  Future<void> _onOtpSendRequested(
    AuthOtpSendRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final result = await _authRepository.sendOtp(event.email);

      if (result.success) {
        emit(AuthOtpSent(
          email: result.email!,
          expiresIn: result.expiresIn!,
          remainingAttempts: result.rateLimit?.remaining,
        ));
      } else {
        if (result.error == 'RATE_LIMIT_EXCEEDED') {
          emit(AuthError(
            message: result.message!,
            errorCode: result.error,
            retryAfter: result.retryAfter,
          ));
        } else {
          emit(AuthError(
            message: result.message ?? 'Failed to send OTP',
            errorCode: result.error,
          ));
        }
      }
    } catch (e) {
      emit(AuthError(message: 'Failed to send OTP: $e'));
    }
  }

  Future<void> _onOtpVerifyRequested(
    AuthOtpVerifyRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final result = await _authRepository.verifyOtp(
        email: event.email,
        code: event.code,
      );

      if (result.success) {
        // Store tokens securely
        await _tokenStorage.saveAuthSession(
          accessToken: result.tokens!.accessToken,
          refreshToken: result.tokens!.refreshToken,
          userId: result.user!.id,
          deviceId: result.session!.deviceId,
          sessionId: result.session!.sessionId,
        );

        // Start session refresh scheduler (Story 1-3)
        await _sessionService?.storeSession(
          accessToken: result.tokens!.accessToken,
          refreshToken: result.tokens!.refreshToken,
          expiresIn: result.tokens!.expiresIn,
        );

        emit(AuthAuthenticated(user: result.user!));
      } else {
        if (result.error == 'ACCOUNT_LOCKED') {
          emit(AuthAccountLocked(
            message: result.message!,
            lockedUntil: result.lockedUntil,
          ));
        } else {
          emit(AuthError(
            message: result.message ?? 'Failed to verify OTP',
            errorCode: result.error,
          ));
        }
      }
    } catch (e) {
      emit(AuthError(message: 'Failed to verify OTP: $e'));
    }
  }

  Future<void> _onRefreshRequested(
    AuthRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final refreshToken = await _tokenStorage.getRefreshToken();

      if (refreshToken == null) {
        emit(const AuthUnauthenticated());
        return;
      }

      final result = await _authRepository.refreshToken(refreshToken);

      if (result.success) {
        // Update stored tokens
        final userId = await _tokenStorage.getUserId();
        final deviceId = await _tokenStorage.getDeviceId();
        final sessionId = await _tokenStorage.getSessionId();

        await _tokenStorage.saveAuthSession(
          accessToken: result.tokens!.accessToken,
          refreshToken: result.tokens!.refreshToken,
          userId: userId!,
          deviceId: deviceId,
          sessionId: sessionId,
        );

        // Keep current authenticated state
        if (state is AuthAuthenticated) {
          // No state change needed, tokens refreshed in background
        }
      } else {
        // Refresh failed - user needs to re-authenticate
        await _tokenStorage.clearSession();
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError(message: 'Failed to refresh token: $e'));
    }
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      // Stop session refresh scheduler and revoke tokens (Story 1-3)
      await _sessionService?.forceLogout();

      // Also clear token storage (for backward compatibility)
      await _tokenStorage.clearSession();

      emit(const AuthUnauthenticated());
    } catch (e) {
      // Even if backend call fails, clear local storage
      await _tokenStorage.clearSession();
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onAppleSignInRequested(
    AuthAppleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final result = await _authRepository.verifyAppleToken(
        idToken: event.idToken,
      );

      if (result.success) {
        // Store tokens securely
        await _tokenStorage.saveAuthSession(
          accessToken: result.tokens!.accessToken,
          refreshToken: result.tokens!.refreshToken,
          userId: result.user!.id,
          deviceId: result.session!.deviceId,
          sessionId: result.session!.sessionId,
        );

        // Start session refresh scheduler (Story 1-3)
        await _sessionService?.storeSession(
          accessToken: result.tokens!.accessToken,
          refreshToken: result.tokens!.refreshToken,
          expiresIn: result.tokens!.expiresIn,
        );

        emit(AuthAuthenticated(user: result.user!));
      } else {
        emit(AuthError(
          message: result.message ?? 'Failed to sign in with Apple',
          errorCode: result.error,
        ));
      }
    } catch (e) {
      emit(AuthError(message: 'Failed to sign in with Apple: $e'));
    }
  }

  Future<void> _onGoogleSignInRequested(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final result = await _authRepository.verifyGoogleToken(
        idToken: event.idToken,
      );

      if (result.success) {
        // Store tokens securely
        await _tokenStorage.saveAuthSession(
          accessToken: result.tokens!.accessToken,
          refreshToken: result.tokens!.refreshToken,
          userId: result.user!.id,
          deviceId: result.session!.deviceId,
          sessionId: result.session!.sessionId,
        );

        // Start session refresh scheduler (Story 1-3)
        await _sessionService?.storeSession(
          accessToken: result.tokens!.accessToken,
          refreshToken: result.tokens!.refreshToken,
          expiresIn: result.tokens!.expiresIn,
        );

        emit(AuthAuthenticated(user: result.user!));
      } else {
        emit(AuthError(
          message: result.message ?? 'Failed to sign in with Google',
          errorCode: result.error,
        ));
      }
    } catch (e) {
      emit(AuthError(message: 'Failed to sign in with Google: $e'));
    }
  }
}
