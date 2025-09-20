import '../../domain/models/payment_model.dart';
import '../../domain/models/card_model.dart';
import '../../domain/models/payment_gateway_model.dart';

abstract class PaymentEvent {}

class ProcessPaymentEvent extends PaymentEvent {
  final String userId;
  final String orderId;
  final double amount;
  final String currency;
  final CardInputModel cardInput;
  final bool saveCard;
  final bool isRecurring;

  ProcessPaymentEvent({
    required this.userId,
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.cardInput,
    required this.saveCard,
    required this.isRecurring,
  });
}

class ProcessPaymentWithTokenEvent extends PaymentEvent {
  final String userId;
  final String orderId;
  final double amount;
  final String currency;
  final String paymentToken;
  final bool isRecurring;

  ProcessPaymentWithTokenEvent({
    required this.userId,
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.paymentToken,
    required this.isRecurring,
  });
}

class LoadPaymentEvent extends PaymentEvent {
  final String paymentId;

  LoadPaymentEvent({required this.paymentId});
}

class LoadUserPaymentsEvent extends PaymentEvent {
  final String userId;

  LoadUserPaymentsEvent({required this.userId});
}

class LoadOrderPaymentsEvent extends PaymentEvent {
  final String orderId;

  LoadOrderPaymentsEvent({required this.orderId});
}

class RefundPaymentEvent extends PaymentEvent {
  final String paymentId;
  final double amount;
  final String? reason;

  RefundPaymentEvent({
    required this.paymentId,
    required this.amount,
    this.reason,
  });
}

class CancelPaymentEvent extends PaymentEvent {
  final String paymentId;

  CancelPaymentEvent({required this.paymentId});
}

class LoadPaymentsByStatusEvent extends PaymentEvent {
  final PaymentStatus status;

  LoadPaymentsByStatusEvent({required this.status});
}

class AddCardEvent extends PaymentEvent {
  final String userId;
  final CardInputModel cardInput;
  final bool makeDefault;

  AddCardEvent({
    required this.userId,
    required this.cardInput,
    required this.makeDefault,
  });
}

class LoadUserCardsEvent extends PaymentEvent {
  final String userId;

  LoadUserCardsEvent({required this.userId});
}

class DeleteCardEvent extends PaymentEvent {
  final String cardId;

  DeleteCardEvent({required this.cardId});
}

class SetDefaultCardEvent extends PaymentEvent {
  final String userId;
  final String cardId;

  SetDefaultCardEvent({
    required this.userId,
    required this.cardId,
  });
}

class LoadPaymentGatewaysEvent extends PaymentEvent {}

class AnalyzePaymentRiskEvent extends PaymentEvent {
  final String userId;
  final String paymentId;
  final double amount;
  final String currency;
  final String? ipAddress;
  final String? deviceId;
  final String? userAgent;

  AnalyzePaymentRiskEvent({
    required this.userId,
    required this.paymentId,
    required this.amount,
    required this.currency,
    this.ipAddress,
    this.deviceId,
    this.userAgent,
  });
}

class ProcessRecurringPaymentEvent extends PaymentEvent {
  final String userId;
  final String orderId;
  final double amount;
  final String currency;
  final String subscriptionId;

  ProcessRecurringPaymentEvent({
    required this.userId,
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.subscriptionId,
  });
}

class CancelRecurringPaymentEvent extends PaymentEvent {
  final String subscriptionId;
  final String? reason;

  CancelRecurringPaymentEvent({
    required this.subscriptionId,
    this.reason,
  });
}

class Validate3DSecureEvent extends PaymentEvent {
  final String paymentId;
  final String transactionId;
  final Map<String, dynamic> authData;

  Validate3DSecureEvent({
    required this.paymentId,
    required this.transactionId,
    required this.authData,
  });
}

class ClearPaymentErrorEvent extends PaymentEvent {}

class RefreshPaymentsEvent extends PaymentEvent {}