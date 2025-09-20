import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/models/recovery_models.dart';
import '../../domain/repositories/recovery_repository.dart';
import 'recovery_event.dart';
import 'recovery_state.dart';

class RecoveryBloc extends Bloc<RecoveryEvent, RecoveryState> {
  final RecoveryRepository recoveryRepository;

  RecoveryBloc({required this.recoveryRepository}) : super(RecoveryInitial()) {
    on<EmailRecoveryRequested>(_onEmailRecoveryRequested);
    on<PhoneRecoveryRequested>(_onPhoneRecoveryRequested);
  on<TokenVerified>(_onTokenVerified);
    on<PasswordResetCompleted>(_onPasswordResetCompleted);
    on<SecurityQuestionAnswered>(_onSecurityQuestionAnswered);
    on<BackupRecoveryMethodSelected>(_onBackupRecoveryMethodSelected);
    on<RecoveryStatusRequested>(_onRecoveryStatusRequested);
    on<RecoveryReset>(_onRecoveryReset);
    on<RecoveryAttemptsLoaded>(_onRecoveryAttemptsLoaded);
  }

  Future<void> _onEmailRecoveryRequested(
    EmailRecoveryRequested event,
    Emitter<RecoveryState> emit,
  ) async {
    emit(RecoveryLoading());
    try {
      final result = await recoveryRepository.requestEmailRecovery(event.email);

      if (result.isAccountLocked) {
        emit(AccountLocked(
          email: event.email,
          lockStatus: result.lockStatus!,
          lockedUntil: result.lockedUntil,
        ));
      } else if (result.success) {
        emit(EmailRecoverySent(
          email: event.email,
          expiresAt: result.expiresAt!,
        ));
      } else {
        emit(RecoveryFailed(
          error: result.error ?? 'Failed to send recovery email',
          errorType: result.errorType ?? RecoveryErrorType.serverError,
        ));
      }
    } catch (e) {
      emit(RecoveryFailed(
        error: 'An unexpected error occurred',
        errorType: RecoveryErrorType.serverError,
      ));
    }
  }

  Future<void> _onPhoneRecoveryRequested(
    PhoneRecoveryRequested event,
    Emitter<RecoveryState> emit,
  ) async {
    emit(RecoveryLoading());
    try {
      final result = await recoveryRepository.requestPhoneRecovery(event.phoneNumber);

      if (result.isAccountLocked) {
        emit(AccountLocked(
          email: '', // Phone-based recovery doesn't require email
          lockStatus: result.lockStatus!,
          lockedUntil: result.lockedUntil,
        ));
      } else if (result.success) {
        emit(PhoneRecoverySent(
          phoneNumber: event.phoneNumber,
          expiresAt: result.expiresAt!,
        ));
      } else {
        emit(RecoveryFailed(
          error: result.error ?? 'Failed to send recovery SMS',
          errorType: result.errorType ?? RecoveryErrorType.serverError,
        ));
      }
    } catch (e) {
      emit(RecoveryFailed(
        error: 'An unexpected error occurred',
        errorType: RecoveryErrorType.serverError,
      ));
    }
  }

  Future<void> _onTokenVerified(
    TokenVerified event,
    Emitter<RecoveryState> emit,
  ) async {
    emit(RecoveryLoading());
    try {
      final isValid = await recoveryRepository.verifyRecoveryToken(
        event.email,
        event.token,
      );

  emit(TokenVerificationResult(email: event.email, isValid: isValid));
    } catch (e) {
      emit(RecoveryFailed(
        error: 'Failed to verify token',
        errorType: RecoveryErrorType.serverError,
      ));
    }
  }

  Future<void> _onPasswordResetCompleted(
    PasswordResetCompleted event,
    Emitter<RecoveryState> emit,
  ) async {
    emit(RecoveryLoading());
    try {
      final result = await recoveryRepository.resetPassword(
        event.email,
        event.newPassword,
        event.token,
      );

      if (result.success) {
        emit(PasswordResetSuccess(event.email));
      } else {
        emit(RecoveryFailed(
          error: result.error ?? 'Failed to reset password',
          errorType: result.errorType ?? RecoveryErrorType.serverError,
        ));
      }
    } catch (e) {
      emit(RecoveryFailed(
        error: 'An unexpected error occurred',
        errorType: RecoveryErrorType.serverError,
      ));
    }
  }

  Future<void> _onSecurityQuestionAnswered(
    SecurityQuestionAnswered event,
    Emitter<RecoveryState> emit,
  ) async {
    emit(RecoveryLoading());
    try {
      final isCorrect = await recoveryRepository.verifySecurityQuestion(
        event.questionId,
        event.answer,
      );

      if (isCorrect) {
        emit(SecurityQuestionVerified(event.questionId));
      } else {
        emit(RecoveryFailed(
          error: 'Incorrect security answer',
          errorType: RecoveryErrorType.invalidSecurityAnswer,
        ));
      }
    } catch (e) {
      emit(RecoveryFailed(
        error: 'Failed to verify security answer',
        errorType: RecoveryErrorType.serverError,
      ));
    }
  }

  Future<void> _onBackupRecoveryMethodSelected(
    BackupRecoveryMethodSelected event,
    Emitter<RecoveryState> emit,
  ) async {
    emit(RecoveryLoading());
    try {
      final result = await recoveryRepository.initiateBackupRecovery(event.method);

      if (result.success) {
        // Handle different backup methods
        switch (event.method) {
          case RecoveryMethod.backupEmail:
            emit(EmailRecoverySent(
              email: result.email!,
              expiresAt: result.expiresAt!,
            ));
            break;
          case RecoveryMethod.backupPhone:
            emit(PhoneRecoverySent(
              phoneNumber: result.phoneNumber!,
              expiresAt: result.expiresAt!,
            ));
            break;
          case RecoveryMethod.securityQuestion:
            final questions = await recoveryRepository.getSecurityQuestions();
            emit(SecurityQuestionsLoaded(questions));
            break;
          default:
            emit(RecoveryFailed(
              error: 'Unsupported backup method',
              errorType: RecoveryErrorType.backupMethodNotAvailable,
            ));
        }
      } else {
        emit(RecoveryFailed(
          error: result.error ?? 'Backup recovery method not available',
          errorType: result.errorType ?? RecoveryErrorType.backupMethodNotAvailable,
        ));
      }
    } catch (e) {
      emit(RecoveryFailed(
        error: 'An unexpected error occurred',
        errorType: RecoveryErrorType.serverError,
      ));
    }
  }

  Future<void> _onRecoveryStatusRequested(
    RecoveryStatusRequested event,
    Emitter<RecoveryState> emit,
  ) async {
    emit(RecoveryLoading());
    try {
      final status = await recoveryRepository.getRecoveryStatus(event.email);
      emit(RecoveryStatusLoaded(
        availableMethods: status.availableMethods,
        currentStatus: status.currentStatus,
      ));
    } catch (e) {
      emit(RecoveryFailed(
        error: 'Failed to get recovery status',
        errorType: RecoveryErrorType.serverError,
      ));
    }
  }

  Future<void> _onRecoveryAttemptsLoaded(
    RecoveryAttemptsLoaded event,
    Emitter<RecoveryState> emit,
  ) async {
    emit(RecoveryLoading());
    try {
      final attempts = await recoveryRepository.getRecoveryAttempts(event.email);
  emit(RecoveryAttemptsLoadedState(attempts));
    } catch (e) {
      emit(RecoveryFailed(
        error: 'Failed to load recovery attempts',
        errorType: RecoveryErrorType.serverError,
      ));
    }
  }

  void _onRecoveryReset(
    RecoveryReset event,
    Emitter<RecoveryState> emit,
  ) {
    emit(RecoveryInitial());
  }
}

// State class defined in recovery_state.dart