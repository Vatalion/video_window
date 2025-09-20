
abstract class CheckoutEvent extends Equatable {
  const CheckoutEvent();

  @override
  List<Object> get props => [];
}

// Session Management Events
class CheckoutStarted extends CheckoutEvent {
  final String userId;
  final bool isGuest;

  const CheckoutStarted({
    required this.userId,
    this.isGuest = false,
  });

  @override
  List<Object> get props => [userId, isGuest];
}

class CheckoutSessionLoadRequested extends CheckoutEvent {
  final String sessionId;

  const CheckoutSessionLoadRequested({required this.sessionId});

  @override
  List<Object> get props => [sessionId];
}

class CheckoutSessionResumeRequested extends CheckoutEvent {
  final String sessionId;
  final String userId;

  const CheckoutSessionResumeRequested({
    required this.sessionId,
    required this.userId,
  });

  @override
  List<Object> get props => [sessionId, userId];
}

class CheckoutProgressSaveRequested extends CheckoutEvent {
  final String sessionId;
  final Map<CheckoutStepType, Map<String, dynamic>> stepData;

  const CheckoutProgressSaveRequested({
    required this.sessionId,
    required this.stepData,
  });

  @override
  List<Object> get props => [sessionId, stepData];
}

class CheckoutSessionAbandonmentRequested extends CheckoutEvent {
  final String sessionId;
  final String reason;

  const CheckoutSessionAbandonmentRequested({
    required this.sessionId,
    required this.reason,
  });

  @override
  List<Object> get props => [sessionId, reason];
}

// Step Navigation Events
class CheckoutStepChanged extends CheckoutEvent {
  final CheckoutStepType stepType;
  final String sessionId;

  const CheckoutStepChanged({
    required this.stepType,
    required this.sessionId,
  });

  @override
  List<Object> get props => [stepType, sessionId];
}

class CheckoutStepSubmitted extends CheckoutEvent {
  final CheckoutStepType stepType;
  final Map<String, dynamic> stepData;
  final String sessionId;

  const CheckoutStepSubmitted({
    required this.stepType,
    required this.stepData,
    required this.sessionId,
  });

  @override
  List<Object> get props => [stepType, stepData, sessionId];
}

class CheckoutStepValidationRequested extends CheckoutEvent {
  final CheckoutStepType stepType;
  final CheckoutValidationResult validationResult;
  final String sessionId;

  const CheckoutStepValidationRequested({
    required this.stepType,
    required this.validationResult,
    required this.sessionId,
  });

  @override
  List<Object> get props => [stepType, validationResult, sessionId];
}

// Data Input Events
class CheckoutAddressAdded extends CheckoutEvent {
  final AddressModel address;
  final String sessionId;

  const CheckoutAddressAdded({
    required this.address,
    required this.sessionId,
  });

  @override
  List<Object> get props => [address, sessionId];
}

class CheckoutPaymentMethodSelected extends CheckoutEvent {
  final String paymentMethodId;
  final String sessionId;

  const CheckoutPaymentMethodSelected({
    required this.paymentMethodId,
    required this.sessionId,
  });

  @override
  List<Object> get props => [paymentMethodId, sessionId];
}

class CheckoutCouponApplied extends CheckoutEvent {
  final String couponCode;
  final String sessionId;

  const CheckoutCouponApplied({
    required this.couponCode,
    required this.sessionId,
  });

  @override
  List<Object> get props => [couponCode, sessionId];
}

// Order Summary Events
class CheckoutOrderSummaryRequested extends CheckoutEvent {
  final OrderCalculationRequest request;
  final String sessionId;

  const CheckoutOrderSummaryRequested({
    required this.request,
    required this.sessionId,
  });

  @override
  List<Object> get props => [request, sessionId];
}

class CheckoutOrderSummaryUpdated extends CheckoutEvent {
  final OrderSummaryModel orderSummary;
  final String sessionId;

  const CheckoutOrderSummaryUpdated({
    required this.orderSummary,
    required this.sessionId,
  });

  @override
  List<Object> get props => [orderSummary, sessionId];
}

// Guest Checkout Events
class CheckoutGuestAccountCreationRequested extends CheckoutEvent {
  final String email;
  final String firstName;
  final String lastName;
  final String sessionId;

  const CheckoutGuestAccountCreationRequested({
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.sessionId,
  });

  @override
  List<Object> get props => [email, firstName, lastName, sessionId];
}

class CheckoutGuestToUserConverted extends CheckoutEvent {
  final String email;
  final String password;
  final String sessionId;

  const CheckoutGuestToUserConverted({
    required this.email,
    required this.password,
    required this.sessionId,
  });

  @override
  List<Object> get props => [email, password, sessionId];
}

// Security Events
class CheckoutSecurityValidated extends CheckoutEvent {
  final SecurityContextModel securityContext;
  final String sessionId;

  const CheckoutSecurityValidated({
    required this.securityContext,
    required this.sessionId,
  });

  @override
  List<Object> get props => [securityContext, sessionId];
}

class CheckoutAuthenticationRequested extends CheckoutEvent {
  final CheckoutStepType stepType;
  final String sessionId;

  const CheckoutAuthenticationRequested({
    required this.stepType,
    required this.sessionId,
  });

  @override
  List<Object> get props => [stepType, sessionId];
}

// Completion Events
class CheckoutPaymentProcessed extends CheckoutEvent {
  final String paymentMethodId;
  final double amount;
  final String sessionId;

  const CheckoutPaymentProcessed({
    required this.paymentMethodId,
    required this.amount,
    required this.sessionId,
  });

  @override
  List<Object> get props => [paymentMethodId, amount, sessionId];
}

class CheckoutCompletionRequested extends CheckoutEvent {
  final String paymentMethodId;
  final String sessionId;

  const CheckoutCompletionRequested({
    required this.paymentMethodId,
    required this.sessionId,
  });

  @override
  List<Object> get props => [paymentMethodId, sessionId];
}

// Error Handling Events
class CheckoutErrorHandled extends CheckoutEvent {
  final Failure failure;
  final CheckoutStepType? stepType;

  const CheckoutErrorHandled({
    required this.failure,
    this.stepType,
  });

  @override
  List<Object> get props => [failure, stepType];
}

class CheckoutRetryRequested extends CheckoutEvent {
  final CheckoutStepType stepType;
  final Map<String, dynamic> stepData;
  final String sessionId;

  const CheckoutRetryRequested({
    required this.stepType,
    required this.stepData,
    required this.sessionId,
  });

  @override
  List<Object> get props => [stepType, stepData, sessionId];
}

// Refresh Events
class CheckoutSessionRefreshed extends CheckoutEvent {
  final String sessionId;

  const CheckoutSessionRefreshed({required this.sessionId});

  @override
  List<Object> get props => [sessionId];
}

class CheckoutSavedSessionsLoadRequested extends CheckoutEvent {
  final String userId;

  const CheckoutSavedSessionsLoadRequested({required this.userId});

  @override
  List<Object> get props => [userId];
}

// Utility Events
class CheckoutCleanupRequested extends CheckoutEvent {}

class CheckoutTimedOut extends CheckoutEvent {
  final String sessionId;

  const CheckoutTimedOut({required this.sessionId});

  @override
  List<Object> get props => [sessionId];
}