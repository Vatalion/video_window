import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Global authentication BLoC
/// Manages authentication state such as:
/// - User login/logout status
/// - Session management
/// - Authentication tokens
/// - User profile data
///
/// This is a foundational structure to be fully implemented in Epic 1 stories

// Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthSignInRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthSignInRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
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

class AuthAuthenticated extends AuthState {
  final String userId;

  const AuthAuthenticated({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(const AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthSignInRequested>(_onSignInRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
  }

  void _onCheckRequested(AuthCheckRequested event, Emitter<AuthState> emit) {
    // TODO: Implement actual session check in Epic 1 stories
    emit(const AuthUnauthenticated());
  }

  void _onSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    // TODO: Implement actual sign in logic in Epic 1 stories
    emit(const AuthLoading());
    // Placeholder - will be replaced with real authentication
    emit(const AuthUnauthenticated());
  }

  void _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) {
    // TODO: Implement actual sign out logic in Epic 1 stories
    emit(const AuthUnauthenticated());
  }
}
