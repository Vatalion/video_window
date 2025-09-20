import 'dart:async';
import '../models/payment_model.dart';

abstract class PaymentSecurityRepository {
  Future<String> generatePaymentToken({
    required String cardNumber,
    required String expiryMonth,
    required String expiryYear,
    required String cvv,
  });

  Future<bool> validatePaymentToken(String token);
  Future<String> refreshPaymentToken(String token);
  Future<bool> revokePaymentToken(String token);

  Future<String> encryptCardData(Map<String, dynamic> cardData);
  Future<Map<String, dynamic>> decryptCardData(String encryptedData);

  Future<bool> validatePCICompliance();
  Future<Map<String, dynamic>> getPCIComplianceReport();

  Future<bool> logSecurityEvent({
    required String eventType,
    required String paymentId,
    required String userId,
    Map<String, dynamic>? metadata,
  });

  Future<List<Map<String, dynamic>>> getSecurityLogs({
    String? userId,
    String? paymentId,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<bool> performFraudCheck({
    required String paymentId,
    required String userId,
    required double amount,
    required String currency,
    String? ipAddress,
    String? deviceId,
  });

  Future<Map<String, dynamic>> getRiskAssessment({
    required String paymentId,
    required String userId,
  });

  Future<bool> blockPayment(String paymentId, String reason);
  Future<bool> unblockPayment(String paymentId);

  Future<String> generateSecurePaymentIntent({
    required double amount,
    required String currency,
    required String userId,
    Map<String, dynamic>? metadata,
  });

  Future<bool> validateSecurePaymentIntent({
    required String intentId,
    required String userId,
  });

  Future<bool> verify3DSecure({
    required String paymentId,
    required String transactionId,
    required Map<String, dynamic> authData,
  });

  Future<Map<String, dynamic>> get3DSecureAuthentication({
    required String paymentId,
    required String transactionId,
  });

  Future<String> generateSecureClientToken({
    required String userId,
    PaymentGatewayType gatewayType,
  });

  Future<bool> validateSecureClientToken(String token);

  Stream<Map<String, dynamic>> getSecurityAlerts();
  Future<List<Map<String, dynamic>>> getBlockedPayments();
}