import 'package:equatable/equatable.dart';
import '../../domain/models/recovery_models.dart';

abstract class RecoveryEvent extends Equatable {
  const RecoveryEvent();

  @override
  List<Object?> get props => [];
}

class EmailRecoveryRequested extends RecoveryEvent {
  final String email;

  const EmailRecoveryRequested(this.email);

  @override
  List<Object?> get props => [email];
}

class PhoneRecoveryRequested extends RecoveryEvent {
  final String phoneNumber;

  const PhoneRecoveryRequested(this.phoneNumber);

  @override
  List<Object?> get props => [phoneNumber];
}

class TokenVerified extends RecoveryEvent {
  final String email;
  final String token;

  const TokenVerified({
    required this.email,
    required this.token,
  });

  @override
  List<Object?> get props => [email, token];
}

class PasswordResetCompleted extends RecoveryEvent {
  final String email;
  final String newPassword;
  final String token;

  const PasswordResetCompleted({
    required this.email,
    required this.newPassword,
    required this.token,
  });

  @override
  List<Object?> get props => [email, newPassword, token];
}

class SecurityQuestionAnswered extends RecoveryEvent {
  final String questionId;
  final String answer;

  const SecurityQuestionAnswered({
    required this.questionId,
    required this.answer,
  });

  @override
  List<Object?> get props => [questionId, answer];
}

class BackupRecoveryMethodSelected extends RecoveryEvent {
  final RecoveryMethod method;

  const BackupRecoveryMethodSelected(this.method);

  @override
  List<Object?> get props => [method];
}

class RecoveryStatusRequested extends RecoveryEvent {
  final String email;

  const RecoveryStatusRequested(this.email);

  @override
  List<Object?> get props => [email];
}

class RecoveryReset extends RecoveryEvent {}

class RecoveryAttemptsLoaded extends RecoveryEvent {
  final String email;

  const RecoveryAttemptsLoaded(this.email);

  @override
  List<Object?> get props => [email];
}