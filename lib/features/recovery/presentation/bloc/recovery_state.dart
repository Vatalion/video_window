import 'package:equatable/equatable.dart';
import '../../domain/models/recovery_models.dart';

abstract class RecoveryState extends Equatable {
  const RecoveryState();

  @override
  List<Object?> get props => [];
}

class RecoveryInitial extends RecoveryState {}

class RecoveryLoading extends RecoveryState {}

class EmailRecoverySent extends RecoveryState {
  final String email;
  final DateTime expiresAt;

  const EmailRecoverySent({
    required this.email,
    required this.expiresAt,
  });

  @override
  List<Object?> get props => [email, expiresAt];
}

class PhoneRecoverySent extends RecoveryState {
  final String phoneNumber;
  final DateTime expiresAt;

  const PhoneRecoverySent({
    required this.phoneNumber,
    required this.expiresAt,
  });

  @override
  List<Object?> get props => [phoneNumber, expiresAt];
}

class TokenVerificationResult extends RecoveryState {
  final String email;
  final bool isValid;

  const TokenVerificationResult({
    required this.email,
    required this.isValid,
  });

  @override
  List<Object?> get props => [email, isValid];
}

class PasswordResetSuccess extends RecoveryState {
  final String email;

  const PasswordResetSuccess(this.email);

  @override
  List<Object?> get props => [email];
}

class SecurityQuestionVerified extends RecoveryState {
  final String questionId;

  const SecurityQuestionVerified(this.questionId);

  @override
  List<Object?> get props => [questionId];
}

class RecoveryFailed extends RecoveryState {
  final String error;
  final RecoveryErrorType errorType;

  const RecoveryFailed({
    required this.error,
    required this.errorType,
  });

  @override
  List<Object?> get props => [error, errorType];
}

class AccountLocked extends RecoveryState {
  final String email;
  final AccountLockStatus lockStatus;
  final DateTime? lockedUntil;

  const AccountLocked({
    required this.email,
    required this.lockStatus,
    this.lockedUntil,
  });

  @override
  List<Object?> get props => [email, lockStatus, lockedUntil];
}

class RecoveryStatusLoaded extends RecoveryState {
  final List<RecoveryMethod> availableMethods;
  final RecoveryStatus currentStatus;

  const RecoveryStatusLoaded({
    required this.availableMethods,
    required this.currentStatus,
  });

  @override
  List<Object?> get props => [availableMethods, currentStatus];
}

class RecoveryAttemptsLoadedState extends RecoveryState {
  final List<RecoveryAttempt> attempts;

  const RecoveryAttemptsLoadedState(this.attempts);

  @override
  List<Object?> get props => [attempts];
}

class SecurityQuestionsLoaded extends RecoveryState {
  final List<SecurityQuestion> questions;

  const SecurityQuestionsLoaded(this.questions);

  @override
  List<Object?> get props => [questions];
}

enum RecoveryErrorType {
  invalidEmail,
  invalidPhoneNumber,
  tokenNotFound,
  tokenExpired,
  tokenAlreadyUsed,
  tooManyAttempts,
  accountLocked,
  networkError,
  serverError,
  invalidSecurityAnswer,
  backupMethodNotAvailable,
}

extension RecoveryErrorTypeExtension on RecoveryErrorType {
  String get message {
    switch (this) {
      case RecoveryErrorType.invalidEmail:
        return 'Invalid email address';
      case RecoveryErrorType.invalidPhoneNumber:
        return 'Invalid phone number';
      case RecoveryErrorType.tokenNotFound:
        return 'Recovery token not found';
      case RecoveryErrorType.tokenExpired:
        return 'Recovery token has expired';
      case RecoveryErrorType.tokenAlreadyUsed:
        return 'Recovery token has already been used';
      case RecoveryErrorType.tooManyAttempts:
        return 'Too many recovery attempts. Please try again later.';
      case RecoveryErrorType.accountLocked:
        return 'Account is temporarily locked due to suspicious activity';
      case RecoveryErrorType.networkError:
        return 'Network error. Please check your connection and try again.';
      case RecoveryErrorType.serverError:
        return 'Server error. Please try again later.';
      case RecoveryErrorType.invalidSecurityAnswer:
        return 'Incorrect security answer';
      case RecoveryErrorType.backupMethodNotAvailable:
        return 'Backup recovery method is not available';
    }
  }
}