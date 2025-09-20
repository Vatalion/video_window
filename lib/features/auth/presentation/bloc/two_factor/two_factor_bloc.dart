import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:logger/logger.dart';
import '../../../../core/error/failures.dart';
import '../../../domain/models/two_factor_config_model.dart';
import '../../../domain/models/two_factor_verification_model.dart';
import '../../../domain/usecases/get_two_factor_config_usecase.dart';
import '../../../domain/usecases/enable_sms_two_factor_usecase.dart';
import '../../../domain/usecases/enable_totp_two_factor_usecase.dart';
import '../../../domain/usecases/create_sms_verification_usecase.dart';
import '../../../domain/usecases/create_totp_verification_usecase.dart';
import '../../../domain/usecases/verify_sms_code_usecase.dart';
import '../../../domain/usecases/verify_totp_code_usecase.dart';
import '../../../domain/usecases/generate_backup_codes_usecase.dart';
import 'two_factor_event.dart';
import 'two_factor_state.dart';

part 'two_factor_event.dart';
part 'two_factor_state.dart';

class TwoFactorBloc extends Bloc<TwoFactorEvent, TwoFactorState> {
  final GetTwoFactorConfigUseCase getTwoFactorConfig;
  final EnableSmsTwoFactorUseCase enableSmsTwoFactor;
  final EnableTotpTwoFactorUseCase enableTotpTwoFactor;
  final CreateSmsVerificationUseCase createSmsVerification;
  final CreateTotpVerificationUseCase createTotpVerification;
  final VerifySmsCodeUseCase verifySmsCode;
  final VerifyTotpCodeUseCase verifyTotpCode;
  final GenerateBackupCodesUseCase generateBackupCodes;
  final Logger logger;

  TwoFactorBloc({
    required this.getTwoFactorConfig,
    required this.enableSmsTwoFactor,
    required this.enableTotpTwoFactor,
    required this.createSmsVerification,
    required this.createTotpVerification,
    required this.verifySmsCode,
    required this.verifyTotpCode,
    required this.generateBackupCodes,
    required this.logger,
  }) : super(const TwoFactorState()) {
    on<TwoFactorConfigRequested>(_onConfigRequested);
    on<TwoFactorSmsSetupInitiated>(_onSmsSetupInitiated);
    on<TwoFactorTotpSetupInitiated>(_onTotpSetupInitiated);
    on<TwoFactorSmsCodeRequested>(_onSmsCodeRequested);
    on<TwoFactorTotpCodeRequested>(_onTotpCodeRequested);
    on<TwoFactorSmsCodeVerified>(_onSmsCodeVerified);
    on<TwoFactorTotpCodeVerified>(_onTotpCodeVerified);
    on<TwoFactorBackupCodeVerified>(_onBackupCodeVerified);
    on<TwoFactorDisabled>(_onTwoFactorDisabled);
    on<TwoFactorBackupCodesGenerated>(_onBackupCodesGenerated);
    on<TwoFactorBackupCodesRequested>(_onBackupCodesRequested);
    on<TwoFactorGracePeriodStarted>(_onGracePeriodStarted);
    on<TwoFactorGracePeriodChecked>(_onGracePeriodChecked);
    on<TwoFactorAccountLocked>(_onAccountLocked);
    on<TwoFactorAccountUnlocked>(_onAccountUnlocked);
  }

  Future<void> _onConfigRequested(
    TwoFactorConfigRequested event,
    Emitter<TwoFactorState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    final result = await getTwoFactorConfig(event.userId);

    result.fold(
      (failure) {
        logger.e('Failed to get 2FA config: ${failure.message}');
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: _mapFailureToMessage(failure),
          ),
        );
      },
      (config) {
        logger.i('Retrieved 2FA config for user: ${event.userId}');
        emit(
          state.copyWith(
            isLoading: false,
            config: config,
            isGracePeriodActive: config.isGracePeriodActive,
          ),
        );
      },
    );
  }

  Future<void> _onSmsSetupInitiated(
    TwoFactorSmsSetupInitiated event,
    Emitter<TwoFactorState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    final result = await enableSmsTwoFactor(
      userId: event.userId,
      phoneNumber: event.phoneNumber,
    );

    result.fold(
      (failure) {
        logger.e('Failed to initiate SMS 2FA setup: ${failure.message}');
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: _mapFailureToMessage(failure),
          ),
        );
      },
      (config) {
        logger.i('SMS 2FA setup initiated for user: ${event.userId}');
        emit(
          state.copyWith(
            isLoading: false,
            config: config,
            successMessage:
                'SMS verification code sent to ${event.phoneNumber}',
          ),
        );
      },
    );
  }

  Future<void> _onTotpSetupInitiated(
    TwoFactorTotpSetupInitiated event,
    Emitter<TwoFactorState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    final result = await enableTotpTwoFactor(
      userId: event.userId,
      totpSecret: event.totpSecret,
    );

    result.fold(
      (failure) {
        logger.e('Failed to initiate TOTP 2FA setup: ${failure.message}');
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: _mapFailureToMessage(failure),
          ),
        );
      },
      (config) {
        logger.i('TOTP 2FA setup initiated for user: ${event.userId}');
        emit(
          state.copyWith(
            isLoading: false,
            config: config,
            successMessage:
                'TOTP setup initiated. Please scan QR code with authenticator app.',
          ),
        );
      },
    );
  }

  Future<void> _onSmsCodeRequested(
    TwoFactorSmsCodeRequested event,
    Emitter<TwoFactorState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    final result = await createSmsVerification(
      userId: event.userId,
      sessionId: event.sessionId,
    );

    result.fold(
      (failure) {
        logger.e('Failed to request SMS verification code: ${failure.message}');
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: _mapFailureToMessage(failure),
          ),
        );
      },
      (verification) {
        logger.i('SMS verification code requested for user: ${event.userId}');
        emit(
          state.copyWith(
            isLoading: false,
            currentVerification: verification,
            successMessage: 'SMS verification code sent',
          ),
        );
      },
    );
  }

  Future<void> _onTotpCodeRequested(
    TwoFactorTotpCodeRequested event,
    Emitter<TwoFactorState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    final result = await createTotpVerification(
      userId: event.userId,
      sessionId: event.sessionId,
    );

    result.fold(
      (failure) {
        logger.e('Failed to request TOTP verification: ${failure.message}');
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: _mapFailureToMessage(failure),
          ),
        );
      },
      (verification) {
        logger.i('TOTP verification requested for user: ${event.userId}');
        emit(
          state.copyWith(
            isLoading: false,
            currentVerification: verification,
            successMessage: 'Please enter TOTP code from authenticator app',
          ),
        );
      },
    );
  }

  Future<void> _onSmsCodeVerified(
    TwoFactorSmsCodeVerified event,
    Emitter<TwoFactorState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    final result = await verifySmsCode(
      userId: event.userId,
      sessionId: event.sessionId,
      code: event.code,
    );

    result.fold(
      (failure) {
        logger.e('Failed to verify SMS code: ${failure.message}');
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: _mapFailureToMessage(failure),
          ),
        );
      },
      (isValid) {
        if (isValid) {
          logger.i('SMS code verified successfully for user: ${event.userId}');
          emit(
            state.copyWith(
              isLoading: false,
              currentVerification: null,
              successMessage: 'SMS code verified successfully',
            ),
          );
        } else {
          logger.w('Invalid SMS code for user: ${event.userId}');
          emit(
            state.copyWith(
              isLoading: false,
              errorMessage: 'Invalid verification code. Please try again.',
            ),
          );
        }
      },
    );
  }

  Future<void> _onTotpCodeVerified(
    TwoFactorTotpCodeVerified event,
    Emitter<TwoFactorState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    final result = await verifyTotpCode(
      userId: event.userId,
      sessionId: event.sessionId,
      code: event.code,
    );

    result.fold(
      (failure) {
        logger.e('Failed to verify TOTP code: ${failure.message}');
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: _mapFailureToMessage(failure),
          ),
        );
      },
      (isValid) {
        if (isValid) {
          logger.i('TOTP code verified successfully for user: ${event.userId}');
          emit(
            state.copyWith(
              isLoading: false,
              currentVerification: null,
              successMessage: 'TOTP code verified successfully',
            ),
          );
        } else {
          logger.w('Invalid TOTP code for user: ${event.userId}');
          emit(
            state.copyWith(
              isLoading: false,
              errorMessage: 'Invalid TOTP code. Please try again.',
            ),
          );
        }
      },
    );
  }

  Future<void> _onBackupCodeVerified(
    TwoFactorBackupCodeVerified event,
    Emitter<TwoFactorState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    final result = await verifySmsCode(
      userId: event.userId,
      sessionId: event.sessionId,
      code: event.code,
    );

    result.fold(
      (failure) {
        logger.e('Failed to verify backup code: ${failure.message}');
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: _mapFailureToMessage(failure),
          ),
        );
      },
      (isValid) {
        if (isValid) {
          logger.i(
            'Backup code verified successfully for user: ${event.userId}',
          );
          emit(
            state.copyWith(
              isLoading: false,
              currentVerification: null,
              successMessage: 'Backup code verified successfully',
            ),
          );
        } else {
          logger.w('Invalid backup code for user: ${event.userId}');
          emit(
            state.copyWith(
              isLoading: false,
              errorMessage: 'Invalid backup code. Please try again.',
            ),
          );
        }
      },
    );
  }

  Future<void> _onTwoFactorDisabled(
    TwoFactorDisabled event,
    Emitter<TwoFactorState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    // Implementation would go here
    logger.i('2FA disabled for user: ${event.userId}');
    emit(
      state.copyWith(
        isLoading: false,
        successMessage: 'Two-factor authentication disabled',
      ),
    );
  }

  Future<void> _onBackupCodesGenerated(
    TwoFactorBackupCodesGenerated event,
    Emitter<TwoFactorState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    final result = await generateBackupCodes(event.userId);

    result.fold(
      (failure) {
        logger.e('Failed to generate backup codes: ${failure.message}');
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: _mapFailureToMessage(failure),
          ),
        );
      },
      (backupCodes) {
        logger.i('Backup codes generated for user: ${event.userId}');
        emit(
          state.copyWith(
            isLoading: false,
            backupCodes: backupCodes,
            successMessage: 'Backup codes generated successfully',
          ),
        );
      },
    );
  }

  Future<void> _onBackupCodesRequested(
    TwoFactorBackupCodesRequested event,
    Emitter<TwoFactorState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    // Implementation would go here
    logger.i('Backup codes requested for user: ${event.userId}');
    emit(
      state.copyWith(
        isLoading: false,
        successMessage: 'Backup codes retrieved',
      ),
    );
  }

  Future<void> _onGracePeriodStarted(
    TwoFactorGracePeriodStarted event,
    Emitter<TwoFactorState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    // Implementation would go here
    logger.i('Grace period started for user: ${event.userId}');
    emit(
      state.copyWith(
        isLoading: false,
        isGracePeriodActive: true,
        successMessage: 'Grace period started',
      ),
    );
  }

  Future<void> _onGracePeriodChecked(
    TwoFactorGracePeriodChecked event,
    Emitter<TwoFactorState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    // Implementation would go here
    logger.i('Grace period checked for user: ${event.userId}');
    emit(state.copyWith(isLoading: false, isGracePeriodActive: false));
  }

  Future<void> _onAccountLocked(
    TwoFactorAccountLocked event,
    Emitter<TwoFactorState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    // Implementation would go here
    logger.i('Account locked for user: ${event.userId}');
    emit(
      state.copyWith(
        isLoading: false,
        isAccountLocked: true,
        successMessage: 'Account locked due to suspicious activity',
      ),
    );
  }

  Future<void> _onAccountUnlocked(
    TwoFactorAccountUnlocked event,
    Emitter<TwoFactorState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    // Implementation would go here
    logger.i('Account unlocked for user: ${event.userId}');
    emit(
      state.copyWith(
        isLoading: false,
        isAccountLocked: false,
        successMessage: 'Account unlocked',
      ),
    );
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return 'Server error occurred';
      case NetworkFailure:
        return 'No internet connection';
      case CacheFailure:
        return 'Cache error occurred';
      case InvalidInputFailure:
        return 'Invalid input provided';
      case RateLimitFailure:
        return 'Too many attempts. Please try again later.';
      default:
        return 'An unexpected error occurred';
    }
  }
}
