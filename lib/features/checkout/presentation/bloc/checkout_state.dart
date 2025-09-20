
abstract class CheckoutState extends Equatable {
  const CheckoutState();

  @override
  List<Object> get props => [];
}

class CheckoutInitial extends CheckoutState {}

class CheckoutLoading extends CheckoutState {}

class CheckoutSessionCreated extends CheckoutState {
  final CheckoutSessionModel session;
  final SecurityContextModel securityContext;

  const CheckoutSessionCreated({
    required this.session,
    required this.securityContext,
  });

  @override
  List<Object> get props => [session, securityContext];
}

class CheckoutSessionLoaded extends CheckoutState {
  final CheckoutSessionModel session;
  final SecurityContextModel securityContext;

  const CheckoutSessionLoaded({
    required this.session,
    required this.securityContext,
  });

  @override
  List<Object> get props => [session, securityContext];
}

class CheckoutSessionResumed extends CheckoutState {
  final CheckoutSessionModel session;
  final SecurityContextModel securityContext;

  const CheckoutSessionResumed({
    required this.session,
    required this.securityContext,
  });

  @override
  List<Object> get props => [session, securityContext];
}

class CheckoutStepInProgress extends CheckoutState {
  final CheckoutStepType currentStep;
  final CheckoutSessionModel session;
  final SecurityContextModel securityContext;
  final CheckoutValidationResult? validationResult;
  final Map<String, dynamic> stepData;

  const CheckoutStepInProgress({
    required this.currentStep,
    required this.session,
    required this.securityContext,
    this.validationResult,
    required this.stepData,
  });

  @override
  List<Object> get props => [
        currentStep,
        session,
        securityContext,
        validationResult,
        stepData,
      ];
}

class CheckoutStepValidated extends CheckoutState {
  final CheckoutStepType stepType;
  final CheckoutValidationResult validationResult;
  final CheckoutSessionModel session;
  final SecurityContextModel securityContext;

  const CheckoutStepValidated({
    required this.stepType,
    required this.validationResult,
    required this.session,
    required this.securityContext,
  });

  @override
  List<Object> get props => [
        stepType,
        validationResult,
        session,
        securityContext,
      ];
}

class CheckoutStepCompleted extends CheckoutState {
  final CheckoutStepType completedStep;
  final CheckoutStepType currentStep;
  final CheckoutSessionModel session;
  final SecurityContextModel securityContext;
  final Map<String, dynamic> completedStepData;

  const CheckoutStepCompleted({
    required this.completedStep,
    required this.currentStep,
    required this.session,
    required this.securityContext,
    required this.completedStepData,
  });

  @override
  List<Object> get props => [
        completedStep,
        currentStep,
        session,
        securityContext,
        completedStepData,
      ];
}

class CheckoutOrderSummaryLoaded extends CheckoutState {
  final OrderSummaryModel orderSummary;
  final CheckoutSessionModel session;
  final SecurityContextModel securityContext;

  const CheckoutOrderSummaryLoaded({
    required this.orderSummary,
    required this.session,
    required this.securityContext,
  });

  @override
  List<Object> get props => [orderSummary, session, securityContext];
}

class CheckoutPaymentProcessing extends CheckoutState {
  final CheckoutSessionModel session;
  final SecurityContextModel securityContext;
  final String paymentMethodId;
  final double amount;

  const CheckoutPaymentProcessing({
    required this.session,
    required this.securityContext,
    required this.paymentMethodId,
    required this.amount,
  });

  @override
  List<Object> get props => [
        session,
        securityContext,
        paymentMethodId,
        amount,
      ];
}

class CheckoutPaymentSuccess extends CheckoutState {
  final PaymentTransactionModel transaction;
  final CheckoutSessionModel session;
  final SecurityContextModel securityContext;

  const CheckoutPaymentSuccess({
    required this.transaction,
    required this.session,
    required this.securityContext,
  });

  @override
  List<Object> get props => [transaction, session, securityContext];
}

class CheckoutCompleted extends CheckoutState {
  final String orderId;
  final CheckoutSessionModel session;
  final SecurityContextModel securityContext;
  final PaymentTransactionModel transaction;

  const CheckoutCompleted({
    required this.orderId,
    required this.session,
    required this.securityContext,
    required this.transaction,
  });

  @override
  List<Object> get props => [orderId, session, securityContext, transaction];
}

class CheckoutGuestAccountCreated extends CheckoutState {
  final String userId;
  final CheckoutSessionModel session;
  final SecurityContextModel securityContext;

  const CheckoutGuestAccountCreated({
    required this.userId,
    required this.session,
    required this.securityContext,
  });

  @override
  List<Object> get props => [userId, session, securityContext];
}

class CheckoutSavedSessionsLoaded extends CheckoutState {
  final List<CheckoutSessionModel> savedSessions;

  const CheckoutSavedSessionsLoaded({required this.savedSessions});

  @override
  List<Object> get props => [savedSessions];
}

class CheckoutError extends CheckoutState {
  final Failure failure;
  final CheckoutStepType? stepType;

  const CheckoutError({
    required this.failure,
    this.stepType,
  });

  @override
  List<Object> get props => [failure, stepType];

  CheckoutError copyWith({
    Failure? failure,
    CheckoutStepType? stepType,
  }) {
    return CheckoutError(
      failure: failure ?? this.failure,
      stepType: stepType ?? this.stepType,
    );
  }
}

class CheckoutValidationError extends CheckoutState {
  final CheckoutValidationResult validationResult;
  final CheckoutStepType stepType;
  final CheckoutSessionModel session;
  final SecurityContextModel securityContext;

  const CheckoutValidationError({
    required this.validationResult,
    required this.stepType,
    required this.session,
    required this.securityContext,
  });

  @override
  List<Object> get props => [
        validationResult,
        stepType,
        session,
        securityContext,
      ];
}

class CheckoutSecurityValidationFailed extends CheckoutState {
  final SecurityValidationResult securityValidation;
  final CheckoutSessionModel session;
  final SecurityContextModel securityContext;

  const CheckoutSecurityValidationFailed({
    required this.securityValidation,
    required this.session,
    required this.securityContext,
  });

  @override
  List<Object> get props => [securityValidation, session, securityContext];
}

class CheckoutAuthenticationRequired extends CheckoutState {
  final CheckoutStepType stepType;
  final CheckoutSessionModel session;
  final SecurityContextModel securityContext;
  final String reason;

  const CheckoutAuthenticationRequired({
    required this.stepType,
    required this.session,
    required this.securityContext,
    required this.reason,
  });

  @override
  List<Object> get props => [
        stepType,
        session,
        securityContext,
        reason,
      ];
}

class CheckoutTimeout extends CheckoutState {
  final String sessionId;
  final DateTime timeoutAt;

  const CheckoutTimeout({
    required this.sessionId,
    required this.timeoutAt,
  });

  @override
  List<Object> get props => [sessionId, timeoutAt];
}

class CheckoutProgressSaved extends CheckoutState {
  final CheckoutSessionModel session;
  final SecurityContextModel securityContext;

  const CheckoutProgressSaved({
    required this.session,
    required this.securityContext,
  });

  @override
  List<Object> get props => [session, securityContext];
}

class CheckoutSessionAbandoned extends CheckoutState {
  final CheckoutSessionModel session;
  final String reason;

  const CheckoutSessionAbandoned({
    required this.session,
    required this.reason,
  });

  @override
  List<Object> get props => [session, reason];
}

class CheckoutSessionCleaned extends CheckoutState {
  final int cleanedCount;

  const CheckoutSessionCleaned({required this.cleanedCount});

  @override
  List<Object> get props => [cleanedCount];
}