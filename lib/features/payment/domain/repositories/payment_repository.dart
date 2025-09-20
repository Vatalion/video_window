import 'dart:async';
import '../models/payment_model.dart';
import '../models/card_model.dart';
import '../models/payment_gateway_model.dart';
import '../models/fraud_detection_model.dart';

abstract class PaymentRepository {
  Future<PaymentModel> processPayment({
    required String userId,
    required String orderId,
    required double amount,
    required String currency,
    required CardInputModel cardInput,
    bool saveCard = false,
    bool isRecurring = false,
  });

  Future<PaymentModel> processPaymentWithToken({
    required String userId,
    required String orderId,
    required double amount,
    required String currency,
    required String paymentToken,
    bool isRecurring = false,
  });

  Future<PaymentModel> getPaymentById(String paymentId);
  Future<List<PaymentModel>> getPaymentsByUserId(String userId);
  Future<List<PaymentModel>> getPaymentsByOrderId(String orderId);

  Future<PaymentModel> refundPayment({
    required String paymentId,
    required double amount,
    String? reason,
  });

  Future<PaymentModel> cancelPayment(String paymentId);
  Future<List<PaymentModel>> getPaymentsByStatus(PaymentStatus status);
  Future<List<PaymentModel>> getPaymentsByDateRange(DateTime start, DateTime end);

  Future<CardModel> addCard({
    required String userId,
    required CardInputModel cardInput,
    bool makeDefault = false,
  });

  Future<List<CardModel>> getUserCards(String userId);
  Future<CardModel> getCardById(String cardId);
  Future<CardModel> updateCard({
    required String cardId,
    bool? isDefault,
  });

  Future<bool> deleteCard(String cardId);
  Future<CardModel> setDefaultCard({
    required String userId,
    required String cardId,
  });

  Future<PaymentGatewayModel> getPaymentGateway(PaymentGatewayType type);
  Future<List<PaymentGatewayModel>> getActivePaymentGateways();
  Future<PaymentGatewayModel> getDefaultPaymentGateway();

  Future<FraudDetectionModel> analyzePaymentRisk({
    required String userId,
    required String paymentId,
    required double amount,
    required String currency,
    String? ipAddress,
    String? deviceId,
    String? userAgent,
  });

  Future<TransactionVelocityData> getTransactionVelocity(String userId);
  Future<FraudDetectionModel> getFraudDetectionByPaymentId(String paymentId);

  Future<bool> validate3DSecure({
    required String paymentId,
    required String transactionId,
    required Map<String, dynamic> authData,
  });

  Future<PaymentModel> processRecurringPayment({
    required String userId,
    required String orderId,
    required double amount,
    required String currency,
    required String subscriptionId,
  });

  Future<PaymentModel> cancelRecurringPayment({
    required String subscriptionId,
    String? reason,
  });

  Stream<PaymentModel> getPaymentStatusUpdates(String paymentId);
  Stream<List<PaymentModel>> getUserPaymentUpdates(String userId);
}