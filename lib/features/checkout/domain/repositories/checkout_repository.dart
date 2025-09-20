import 'package:dartz/dartz.dart';
import '../models/checkout_session_model.dart';
import '../models/checkout_validation_model.dart';
import '../models/order_summary_model.dart';
import '../models/payment_model.dart';
import '../models/address_model.dart';
import '../models/checkout_security_model.dart';
import '../../../core/error/failure.dart';

abstract class CheckoutRepository {
  // Session Management
  Future<Either<Failure, CheckoutSessionModel>> createSession({
    required String userId,
    bool isGuest = false,
  });

  Future<Either<Failure, CheckoutSessionModel>> getSession(String sessionId);

  Future<Either<Failure, CheckoutSessionModel>> updateSession({
    required String sessionId,
    required Map<String, dynamic> updates,
  });

  Future<Either<Failure, bool>> saveSessionProgress({
    required String sessionId,
    required Map<CheckoutStepType, Map<String, dynamic>> stepData,
  });

  Future<Either<Failure, CheckoutSessionModel>> resumeSession(String sessionId);

  Future<Either<Failure, bool>> abandonSession(String sessionId);

  Future<Either<Failure, List<CheckoutSessionModel>>> getSavedSessions(String userId);

  // Step Validation
  Future<Either<Failure, CheckoutValidationResult>> validateCheckoutStep({
    required String sessionId,
    required CheckoutStepType stepType,
    required Map<String, dynamic> stepData,
    required SecurityContextModel securityContext,
  });

  // Order Summary
  Future<Either<Failure, OrderSummaryModel>> calculateOrderSummary({
    required OrderCalculationRequest request,
    required String sessionId,
  });

  Future<Either<Failure, OrderSummaryModel>> getOrderSummary(String sessionId);

  // Payment Processing
  Future<Either<Failure, PaymentTransactionModel>> processPayment({
    required String sessionId,
    required String paymentMethodId,
    required double amount,
    required SecurityContextModel securityContext,
  });

  Future<Either<Failure, bool>> validatePaymentMethod({
    required String paymentMethodId,
    required SecurityContextModel securityContext,
  });

  // Address Management
  Future<Either<Failure, AddressModel>> saveAddress({
    required AddressModel address,
    required SecurityContextModel securityContext,
  });

  Future<Either<Failure, List<AddressModel>>> getUserAddresses(String userId);

  // Security Management
  Future<Either<Failure, SecurityContextModel>> getSecurityContext(String sessionId);

  Future<Either<Failure, SecurityValidationResult>> validateSecurityContext({
    required String sessionId,
    required SecurityContextModel context,
  });

  Future<Either<Failure, bool>> recordSecurityEvent({
    required SecurityEventModel event,
  });

  // Order Completion
  Future<Either<Failure, String>> completeCheckout({
    required String sessionId,
    required String paymentMethodId,
    required SecurityContextModel securityContext,
  });

  // Guest Checkout
  Future<Either<Failure, String>> createGuestAccount({
    required String email,
    required String firstName,
    required String lastName,
    required String sessionId,
  });

  // Analytics and Tracking
  Future<Either<Failure, bool>> trackCheckoutAbandonment({
    required String sessionId,
    required String reason,
  });

  Future<Either<Failure, bool>> trackStepCompletion({
    required String sessionId,
    required CheckoutStepType stepType,
    required Duration timeSpent,
  });

  // Session Cleanup
  Future<Either<Failure, bool>> cleanupExpiredSessions();

  Future<Either<Failure, bool>> deleteSession(String sessionId);
}