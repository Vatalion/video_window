import 'package:equatable/equatable.dart';
import '../../domain/models/payment_model.dart';
import '../../domain/models/card_model.dart';
import '../../domain/models/payment_gateway_model.dart';
import '../../domain/models/fraud_detection_model.dart';

abstract class PaymentState extends Equatable {
  const PaymentState();

  @override
  List<Object?> get props => [];
}

class PaymentInitial extends PaymentState {}

class PaymentLoading extends PaymentState {}

class PaymentOperationSuccess extends PaymentState {
  final PaymentModel payment;

  const PaymentOperationSuccess({required this.payment});

  @override
  List<Object> get props => [payment];
}

class PaymentLoaded extends PaymentState {
  final PaymentModel payment;

  const PaymentLoaded({required this.payment});

  @override
  List<Object> get props => [payment];
}

class PaymentsLoaded extends PaymentState {
  final List<PaymentModel> payments;

  const PaymentsLoaded({required this.payments});

  @override
  List<Object> get props => [payments];
}

class CardOperationSuccess extends PaymentState {
  final CardModel card;

  const CardOperationSuccess({required this.card});

  @override
  List<Object> get props => [card];
}

class CardsLoaded extends PaymentState {
  final List<CardModel> cards;

  const CardsLoaded({required this.cards});

  @override
  List<Object> get props => [cards];
}

class PaymentGatewaysLoaded extends PaymentState {
  final List<PaymentGatewayModel> gateways;

  const PaymentGatewaysLoaded({required this.gateways});

  @override
  List<Object> get props => [gateways];
}

class FraudAnalysisComplete extends PaymentState {
  final FraudDetectionModel fraudDetection;

  const FraudAnalysisComplete({required this.fraudDetection});

  @override
  List<Object> get props => [fraudDetection];
}

class PaymentError extends PaymentState {
  final String message;

  const PaymentError({required this.message});

  @override
  List<Object> get props => [message];
}

class PaymentValidationError extends PaymentState {
  final List<String> errors;

  const PaymentValidationError({required this.errors});

  @override
  List<Object> get props => [errors];
}

class PaymentGatewayError extends PaymentState {
  final String message;
  final String? errorCode;

  const PaymentGatewayError({
    required this.message,
    this.errorCode,
  });

  @override
  List<Object?> get props => [message, errorCode];
}

class FraudRiskError extends PaymentState {
  final String message;
  final FraudRiskLevel riskLevel;

  const FraudRiskError({
    required this.message,
    required this.riskLevel,
  });

  @override
  List<Object> get props => [message, riskLevel];
}

class ThreeDSecureRequired extends PaymentState {
  final String paymentId;
  final String transactionId;
  final Map<String, dynamic> authData;

  const ThreeDSecureRequired({
    required this.paymentId,
    required this.transactionId,
    required this.authData,
  });

  @override
  List<Object> get props => [paymentId, transactionId, authData];
}

class PaymentProcessing extends PaymentState {
  final String paymentId;
  final double progress;

  const PaymentProcessing({
    required this.paymentId,
    required this.progress,
  });

  @override
  List<Object> get props => [paymentId, progress];
}

class CardProcessing extends PaymentState {
  final String cardId;
  final double progress;

  const CardProcessing({
    required this.cardId,
    required this.progress,
  });

  @override
  List<Object> get props => [cardId, progress];
}