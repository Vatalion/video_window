import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:async';

import '../../domain/usecases/validate_checkout_step_usecase.dart';
import '../../domain/usecases/save_checkout_session_usecase.dart';
import '../../domain/usecases/resume_checkout_session_usecase.dart';
import '../../domain/usecases/complete_checkout_usecase.dart';
import '../../domain/repositories/checkout_repository.dart';
import '../../domain/models/checkout_session_model.dart';
import '../../domain/models/checkout_step_model.dart';
import '../../domain/models/checkout_validation_model.dart';
import '../../domain/models/order_summary_model.dart';
import '../../domain/models/payment_model.dart';
import '../../domain/models/address_model.dart';
import '../../domain/models/checkout_security_model.dart';
import '../../../core/error/failure.dart';

part 'checkout_event.dart';
part 'checkout_state.dart';

class CheckoutBloc extends Bloc<CheckoutEvent, CheckoutState> {
  final CheckoutRepository repository;
  final ValidateCheckoutStepUseCase validateCheckoutStepUseCase;
  final SaveCheckoutSessionUseCase saveCheckoutSessionUseCase;
  final ResumeCheckoutSessionUseCase resumeCheckoutSessionUseCase;
  final CompleteCheckoutUseCase completeCheckoutUseCase;

  CheckoutSessionModel? _currentSession;
  SecurityContextModel? _currentSecurityContext;
  Timer? _sessionTimeoutTimer;

  CheckoutBloc({
    required this.repository,
    required this.validateCheckoutStepUseCase,
    required this.saveCheckoutSessionUseCase,
    required this.resumeCheckoutSessionUseCase,
    required this.completeCheckoutUseCase,
  }) : super(CheckoutInitial()) {
    on<CheckoutStarted>(_onCheckoutStarted);
    on<CheckoutSessionLoaded>(_onCheckoutSessionLoaded);
    on<CheckoutSessionResumed>(_onCheckoutSessionResumed);
    on<CheckoutProgressSaved>(_onCheckoutProgressSaved);
    on<CheckoutSessionAbandoned>(_onCheckoutSessionAbandoned);
    on<CheckoutStepChanged>(_onCheckoutStepChanged);
    on<CheckoutStepSubmitted>(_onCheckoutStepSubmitted);
    on<CheckoutStepValidated>(_onCheckoutStepValidated);
    on<CheckoutAddressAdded>(_onCheckoutAddressAdded);
    on<CheckoutPaymentMethodSelected>(_onCheckoutPaymentMethodSelected);
    on<CheckoutCouponApplied>(_onCheckoutCouponApplied);
    on<CheckoutOrderSummaryRequested>(_onCheckoutOrderSummaryRequested);
    on<CheckoutOrderSummaryUpdated>(_onCheckoutOrderSummaryUpdated);
    on<CheckoutGuestAccountCreated>(_onCheckoutGuestAccountCreated);
    on<CheckoutGuestToUserConverted>(_onCheckoutGuestToUserConverted);
    on<CheckoutSecurityValidated>(_onCheckoutSecurityValidated);
    on<CheckoutAuthenticationRequired>(_onCheckoutAuthenticationRequired);
    on<CheckoutPaymentProcessed>(_onCheckoutPaymentProcessed);
    on<CheckoutCompleted>(_onCheckoutCompleted);
    on<CheckoutErrorHandled>(_onCheckoutErrorHandled);
    on<CheckoutRetryRequested>(_onCheckoutRetryRequested);
    on<CheckoutSessionRefreshed>(_onCheckoutSessionRefreshed);
    on<CheckoutSavedSessionsLoaded>(_onCheckoutSavedSessionsLoaded);
    on<CheckoutCleanupRequested>(_onCheckoutCleanupRequested);
    on<CheckoutTimedOut>(_onCheckoutTimedOut);
  }

  // Session Management
  Future<void> _onCheckoutStarted(
    CheckoutStarted event,
    Emitter<CheckoutState> emit,
  ) async {
    emit(CheckoutLoading());

    final result = await repository.createSession(
      userId: event.userId,
      isGuest: event.isGuest,
    );

    result.fold(
      (failure) => emit(CheckoutError(failure: failure)),
      (session) async {
        _currentSession = session;

        // Get security context
        final securityResult = await repository.getSecurityContext(session.sessionId);
        securityResult.fold(
          (failure) => emit(CheckoutError(failure: failure)),
          (securityContext) {
            _currentSecurityContext = securityContext;
            emit(CheckoutSessionCreated(
              session: session,
              securityContext: securityContext,
            ));
            _startSessionTimeoutTimer();
          },
        );
      },
    );
  }

  Future<void> _onCheckoutSessionLoaded(
    CheckoutSessionLoaded event,
    Emitter<CheckoutState> emit,
  ) async {
    emit(CheckoutLoading());

    final result = await repository.getSession(event.sessionId);

    result.fold(
      (failure) => emit(CheckoutError(failure: failure)),
      (session) async {
        _currentSession = session;

        // Get security context
        final securityResult = await repository.getSecurityContext(session.sessionId);
        securityResult.fold(
          (failure) => emit(CheckoutError(failure: failure)),
          (securityContext) {
            _currentSecurityContext = securityContext;
            emit(CheckoutSessionLoaded(
              session: session,
              securityContext: securityContext,
            ));
            _startSessionTimeoutTimer();
          },
        );
      },
    );
  }

  Future<void> _onCheckoutSessionResumed(
    CheckoutSessionResumed event,
    Emitter<CheckoutState> emit,
  ) async {
    emit(CheckoutLoading());

    if (_currentSecurityContext == null) {
      emit(CheckoutError(failure: Failure(
        message: 'Security context not available',
        code: 'SECURITY_CONTEXT_MISSING',
      )));
      return;
    }

    final result = await resumeCheckoutSessionUseCase(
      sessionId: event.sessionId,
      userId: event.userId,
      securityContext: _currentSecurityContext!,
    );

    result.fold(
      (failure) => emit(CheckoutError(failure: failure)),
      (session) {
        _currentSession = session;
        emit(CheckoutSessionResumed(
          session: session,
          securityContext: _currentSecurityContext!,
        ));
        _startSessionTimeoutTimer();
      },
    );
  }

  Future<void> _onCheckoutProgressSaved(
    CheckoutProgressSaved event,
    Emitter<CheckoutState> emit,
  ) async {
    if (_currentSecurityContext == null) {
      emit(CheckoutError(failure: Failure(
        message: 'Security context not available',
        code: 'SECURITY_CONTEXT_MISSING',
      )));
      return;
    }

    final result = await saveCheckoutSessionUseCase(
      sessionId: event.sessionId,
      stepData: event.stepData,
      securityContext: _currentSecurityContext!,
    );

    result.fold(
      (failure) => emit(CheckoutError(failure: failure)),
      (success) {
        if (_currentSession != null) {
          emit(CheckoutProgressSaved(
            session: _currentSession!,
            securityContext: _currentSecurityContext!,
          ));
        }
      },
    );
  }

  Future<void> _onCheckoutSessionAbandoned(
    CheckoutSessionAbandoned event,
    Emitter<CheckoutState> emit,
  ) async {
    if (_currentSession == null) {
      emit(CheckoutError(failure: Failure(
        message: 'No active session',
        code: 'NO_ACTIVE_SESSION',
      )));
      return;
    }

    final result = await repository.abandonSession(event.sessionId);

    result.fold(
      (failure) => emit(CheckoutError(failure: failure)),
      (success) {
        _cancelSessionTimeoutTimer();
        emit(CheckoutSessionAbandoned(
          session: _currentSession!,
          reason: event.reason,
        ));
      },
    );
  }

  // Step Management
  Future<void> _onCheckoutStepChanged(
    CheckoutStepChanged event,
    Emitter<CheckoutState> emit,
  ) async {
    if (_currentSession == null || _currentSecurityContext == null) {
      emit(CheckoutError(failure: Failure(
        message: 'Session or security context not available',
        code: 'SESSION_NOT_AVAILABLE',
      )));
      return;
    }

    emit(CheckoutStepInProgress(
      currentStep: event.stepType,
      session: _currentSession!,
      securityContext: _currentSecurityContext!,
      stepData: {},
    ));
  }

  Future<void> _onCheckoutStepSubmitted(
    CheckoutStepSubmitted event,
    Emitter<CheckoutState> emit,
  ) async {
    if (_currentSecurityContext == null) {
      emit(CheckoutError(failure: Failure(
        message: 'Security context not available',
        code: 'SECURITY_CONTEXT_MISSING',
      )));
      return;
    }

    emit(CheckoutLoading());

    final result = await validateCheckoutStepUseCase(
      sessionId: event.sessionId,
      stepType: event.stepType,
      stepData: event.stepData,
      securityContext: _currentSecurityContext!,
    );

    result.fold(
      (failure) => emit(CheckoutError(
        failure: failure,
        stepType: event.stepType,
      )),
      (validationResult) {
        if (validationResult.isValid) {
          // Step is valid, proceed to next step
          final nextStep = _getNextStep(event.stepType);
          if (nextStep != null) {
            add(CheckoutStepChanged(
              stepType: nextStep,
              sessionId: event.sessionId,
            ));
          }
        } else {
          // Step validation failed
          emit(CheckoutValidationError(
            validationResult: validationResult,
            stepType: event.stepType,
            session: _currentSession!,
            securityContext: _currentSecurityContext!,
          ));
        }
      },
    );
  }

  Future<void> _onCheckoutStepValidated(
    CheckoutStepValidated event,
    Emitter<CheckoutState> emit,
  ) async {
    emit(CheckoutStepValidated(
      stepType: event.stepType,
      validationResult: event.validationResult,
      session: _currentSession!,
      securityContext: _currentSecurityContext!,
    ));
  }

  // Data Management
  Future<void> _onCheckoutAddressAdded(
    CheckoutAddressAdded event,
    Emitter<CheckoutState> emit,
  ) async {
    if (_currentSecurityContext == null) {
      emit(CheckoutError(failure: Failure(
        message: 'Security context not available',
        code: 'SECURITY_CONTEXT_MISSING',
      )));
      return;
    }

    final result = await repository.saveAddress(
      address: event.address,
      securityContext: _currentSecurityContext!,
    );

    result.fold(
      (failure) => emit(CheckoutError(failure: failure)),
      (address) {
        // Address saved successfully
        // Update session step data
        if (_currentSession != null) {
          final updatedStepData = Map<String, dynamic>.from(
            _currentSession!.stepData[CheckoutStepType.shippingAddress] ?? {},
          );
          updatedStepData['addressId'] = address.id;

          add(CheckoutProgressSaved(
            sessionId: event.sessionId,
            stepData: {
              CheckoutStepType.shippingAddress: updatedStepData,
            },
          ));
        }
      },
    );
  }

  Future<void> _onCheckoutPaymentMethodSelected(
    CheckoutPaymentMethodSelected event,
    Emitter<CheckoutState> emit,
  ) async {
    if (_currentSession == null) {
      emit(CheckoutError(failure: Failure(
        message: 'No active session',
        code: 'NO_ACTIVE_SESSION',
      )));
      return;
    }

    // Update session with selected payment method
    final updatedSession = _currentSession!.copyWith(
      savedPaymentMethodId: event.paymentMethodId,
    );

    _currentSession = updatedSession;

    // Save progress
    add(CheckoutProgressSaved(
      sessionId: event.sessionId,
      stepData: {
        CheckoutStepType.paymentMethod: {
          'paymentMethodId': event.paymentMethodId,
        },
      },
    ));
  }

  Future<void> _onCheckoutCouponApplied(
    CheckoutCouponApplied event,
    Emitter<CheckoutState> emit,
  ) async {
    if (_currentSession == null) {
      emit(CheckoutError(failure: Failure(
        message: 'No active session',
        code: 'NO_ACTIVE_SESSION',
      )));
      return;
    }

    // Update session with coupon code
    final updatedSession = _currentSession!.copyWith(
      couponCode: event.couponCode,
    );

    _currentSession = updatedSession;

    // Recalculate order summary
    if (_currentSession!.shippingAddressId != null) {
      // This would typically involve getting cart items from cart service
      // For now, we'll just save the coupon code
      add(CheckoutProgressSaved(
        sessionId: event.sessionId,
        stepData: {
          CheckoutStepType.reviewOrder: {
            'couponCode': event.couponCode,
          },
        },
      ));
    }
  }

  // Order Summary
  Future<void> _onCheckoutOrderSummaryRequested(
    CheckoutOrderSummaryRequested event,
    Emitter<CheckoutState> emit,
  ) async {
    final result = await repository.calculateOrderSummary(
      request: event.request,
      sessionId: event.sessionId,
    );

    result.fold(
      (failure) => emit(CheckoutError(failure: failure)),
      (orderSummary) {
        add(CheckoutOrderSummaryUpdated(
          orderSummary: orderSummary,
          sessionId: event.sessionId,
        ));
      },
    );
  }

  Future<void> _onCheckoutOrderSummaryUpdated(
    CheckoutOrderSummaryUpdated event,
    Emitter<CheckoutState> emit,
  ) async {
    if (_currentSession == null || _currentSecurityContext == null) {
      emit(CheckoutError(failure: Failure(
        message: 'Session or security context not available',
        code: 'SESSION_NOT_AVAILABLE',
      )));
      return;
    }

    emit(CheckoutOrderSummaryLoaded(
      orderSummary: event.orderSummary,
      session: _currentSession!,
      securityContext: _currentSecurityContext!,
    ));
  }

  // Guest Checkout
  Future<void> _onCheckoutGuestAccountCreated(
    CheckoutGuestAccountCreated event,
    Emitter<CheckoutState> emit,
  ) async {
    final result = await repository.createGuestAccount(
      email: event.email,
      firstName: event.firstName,
      lastName: event.lastName,
      sessionId: event.sessionId,
    );

    result.fold(
      (failure) => emit(CheckoutError(failure: failure)),
      (userId) {
        if (_currentSession != null) {
          // Update session with user ID
          final updatedSession = _currentSession!.copyWith(
            userId: userId,
            isGuest: true,
          );
          _currentSession = updatedSession;

          emit(CheckoutGuestAccountCreated(
            userId: userId,
            session: updatedSession,
            securityContext: _currentSecurityContext!,
          ));
        }
      },
    );
  }

  Future<void> _onCheckoutGuestToUserConverted(
    CheckoutGuestToUserConverted event,
    Emitter<CheckoutState> emit,
  ) async {
    // This would integrate with authentication service to convert guest to full user
    // For now, we'll just emit a success state
    if (_currentSession != null) {
      emit(CheckoutGuestAccountCreated(
        userId: _currentSession!.userId,
        session: _currentSession!,
        securityContext: _currentSecurityContext!,
      ));
    }
  }

  // Security
  Future<void> _onCheckoutSecurityValidated(
    CheckoutSecurityValidated event,
    Emitter<CheckoutState> emit,
  ) async {
    if (_currentSession == null) {
      emit(CheckoutError(failure: Failure(
        message: 'No active session',
        code: 'NO_ACTIVE_SESSION',
      )));
      return;
    }

    final result = await repository.validateSecurityContext(
      sessionId: event.sessionId,
      context: event.securityContext,
    );

    result.fold(
      (failure) => emit(CheckoutError(failure: failure)),
      (securityValidation) {
        _currentSecurityContext = event.securityContext;

        if (securityValidation.isValid) {
          // Security validation passed
          // Continue with current operation
        } else {
          emit(CheckoutSecurityValidationFailed(
            securityValidation: securityValidation,
            session: _currentSession!,
            securityContext: event.securityContext,
          ));
        }
      },
    );
  }

  Future<void> _onCheckoutAuthenticationRequired(
    CheckoutAuthenticationRequired event,
    Emitter<CheckoutState> emit,
  ) async {
    if (_currentSession == null || _currentSecurityContext == null) {
      emit(CheckoutError(failure: Failure(
        message: 'Session or security context not available',
        code: 'SESSION_NOT_AVAILABLE',
      )));
      return;
    }

    emit(CheckoutAuthenticationRequired(
      stepType: event.stepType,
      session: _currentSession!,
      securityContext: _currentSecurityContext!,
      reason: 'Additional authentication required for this step',
    ));
  }

  // Payment Processing
  Future<void> _onCheckoutPaymentProcessed(
    CheckoutPaymentProcessed event,
    Emitter<CheckoutState> emit,
  ) async {
    if (_currentSecurityContext == null) {
      emit(CheckoutError(failure: Failure(
        message: 'Security context not available',
        code: 'SECURITY_CONTEXT_MISSING',
      )));
      return;
    }

    emit(CheckoutPaymentProcessing(
      session: _currentSession!,
      securityContext: _currentSecurityContext!,
      paymentMethodId: event.paymentMethodId,
      amount: event.amount,
    ));

    final result = await repository.processPayment(
      sessionId: event.sessionId,
      paymentMethodId: event.paymentMethodId,
      amount: event.amount,
      securityContext: _currentSecurityContext!,
    );

    result.fold(
      (failure) => emit(CheckoutError(failure: failure)),
      (transaction) {
        emit(CheckoutPaymentSuccess(
          transaction: transaction,
          session: _currentSession!,
          securityContext: _currentSecurityContext!,
        ));
      },
    );
  }

  // Completion
  Future<void> _onCheckoutCompleted(
    CheckoutCompleted event,
    Emitter<CheckoutState> emit,
  ) async {
    if (_currentSecurityContext == null) {
      emit(CheckoutError(failure: Failure(
        message: 'Security context not available',
        code: 'SECURITY_CONTEXT_MISSING',
      )));
      return;
    }

    emit(CheckoutLoading());

    final result = await completeCheckoutUseCase(
      sessionId: event.sessionId,
      paymentMethodId: event.paymentMethodId,
      securityContext: _currentSecurityContext!,
    );

    result.fold(
      (failure) => emit(CheckoutError(failure: failure)),
      (orderId) {
        if (_currentSession != null) {
          // Get the successful transaction
          // This would typically be retrieved from the payment processing step
          final transaction = PaymentTransactionModel(
            id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
            sessionId: event.sessionId,
            paymentMethodId: event.paymentMethodId,
            amount: 0.0, // This would be from order summary
            currency: 'USD',
            transactionId: 'txn_${DateTime.now().millisecondsSinceEpoch}',
            status: PaymentStatus.succeeded,
            createdAt: DateTime.now(),
            processedAt: DateTime.now(),
          );

          _cancelSessionTimeoutTimer();
          emit(CheckoutCompleted(
            orderId: orderId,
            session: _currentSession!,
            securityContext: _currentSecurityContext!,
            transaction: transaction,
          ));
        }
      },
    );
  }

  // Error Handling
  Future<void> _onCheckoutErrorHandled(
    CheckoutErrorHandled event,
    Emitter<CheckoutState> emit,
  ) async {
    // Log the error or handle it appropriately
    // For now, just re-emit the error state
    emit(CheckoutError(failure: event.failure, stepType: event.stepType));
  }

  Future<void> _onCheckoutRetryRequested(
    CheckoutRetryRequested event,
    Emitter<CheckoutState> emit,
  ) async {
    // Retry the failed step submission
    add(CheckoutStepSubmitted(
      stepType: event.stepType,
      stepData: event.stepData,
      sessionId: event.sessionId,
    ));
  }

  // Utility
  Future<void> _onCheckoutSessionRefreshed(
    CheckoutSessionRefreshed event,
    Emitter<CheckoutState> emit,
  ) async {
    if (_currentSession != null) {
      add(CheckoutSessionLoaded(sessionId: event.sessionId));
    }
  }

  Future<void> _onCheckoutSavedSessionsLoaded(
    CheckoutSavedSessionsLoaded event,
    Emitter<CheckoutState> emit,
  ) async {
    final result = await repository.getSavedSessions(event.userId);

    result.fold(
      (failure) => emit(CheckoutError(failure: failure)),
      (savedSessions) {
        emit(CheckoutSavedSessionsLoaded(savedSessions: savedSessions));
      },
    );
  }

  Future<void> _onCheckoutCleanupRequested(
    CheckoutCleanupRequested event,
    Emitter<CheckoutState> emit,
  ) async {
    final result = await repository.cleanupExpiredSessions();

    result.fold(
      (failure) => emit(CheckoutError(failure: failure)),
      (success) {
        emit(CheckoutSessionCleaned(cleanedCount: 0)); // Would get actual count from service
      },
    );
  }

  Future<void> _onCheckoutTimedOut(
    CheckoutTimedOut event,
    Emitter<CheckoutState> emit,
  ) async {
    _cancelSessionTimeoutTimer();
    emit(CheckoutTimeout(
      sessionId: event.sessionId,
      timeoutAt: DateTime.now(),
    ));
  }

  // Helper Methods
  CheckoutStepType? _getNextStep(CheckoutStepType currentStep) {
    final steps = CheckoutStepDefinition.getStandardSteps();
    final currentIndex = steps.indexWhere((step) => step.type == currentStep);

    if (currentIndex != -1 && currentIndex < steps.length - 1) {
      return steps[currentIndex + 1].type;
    }

    return null;
  }

  void _startSessionTimeoutTimer() {
    _cancelSessionTimeoutTimer();

    if (_currentSession != null) {
      final timeoutDuration = _currentSession!.expiresAt.difference(DateTime.now());

      if (timeoutDuration.inSeconds > 0) {
        _sessionTimeoutTimer = Timer(timeoutDuration, () {
          add(CheckoutTimedOut(sessionId: _currentSession!.sessionId));
        });
      }
    }
  }

  void _cancelSessionTimeoutTimer() {
    _sessionTimeoutTimer?.cancel();
    _sessionTimeoutTimer = null;
  }

  @override
  Future<void> close() {
    _cancelSessionTimeoutTimer();
    return super.close();
  }
}