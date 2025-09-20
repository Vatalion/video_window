import 'dart:async';
import '../../domain/models/payment_model.dart';
import '../../domain/models/card_model.dart';
import '../../domain/models/payment_gateway_model.dart';
import '../../domain/models/fraud_detection_model.dart';
import '../../domain/repositories/payment_repository.dart';
import '../datasources/payment_remote_data_source.dart';
import '../datasources/payment_local_data_source.dart';
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../services/payment_recovery_service.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentRemoteDataSource remoteDataSource;
  final PaymentLocalDataSource localDataSource;
  final PaymentRecoveryService recoveryService;
  final int maxRetryAttempts;

  PaymentRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.recoveryService,
    this.maxRetryAttempts = 3,
  });

  @override
  Future<PaymentModel> processPayment({
    required String userId,
    required String orderId,
    required double amount,
    required String currency,
    required CardInputModel cardInput,
    bool saveCard = false,
    bool isRecurring = false,
  }) async {
    int attempt = 0;
    Exception? lastException;

    while (attempt < maxRetryAttempts) {
      try {
        final payment = await remoteDataSource.processPayment(
          userId: userId,
          orderId: orderId,
          amount: amount,
          currency: currency,
          cardInput: cardInput,
          saveCard: saveCard,
          isRecurring: isRecurring,
        );

        await localDataSource.cachePayment(payment);
        return payment;
      } on NetworkException catch (e) {
        lastException = e;
        attempt++;
        if (attempt < maxRetryAttempts) {
          await _handleNetworkError(e, attempt, orderId);
        } else {
          // Attempt recovery
          final recoveryResult = await recoveryService.attemptRecovery(
            paymentId: orderId,
            userId: userId,
            amount: amount,
            currency: currency,
            failureReason: PaymentFailureReason.networkError,
            originalPaymentMethod: 'credit_card',
          );
          throw PaymentException('Payment failed after recovery: ${recoveryResult.message}');
        }
      } on ServerException catch (e) {
        lastException = e;
        attempt++;
        if (attempt < maxRetryAttempts) {
          await _handleServerError(e, attempt);
        } else {
          throw PaymentException('Payment failed after multiple attempts: ${e.message}');
        }
      } on ValidationException catch (e) {
        // Validation errors don't benefit from retries
        throw PaymentException('Payment validation failed: ${e.message}');
      } catch (e) {
        lastException = Exception(e);
        attempt++;
        if (attempt < maxRetryAttempts) {
          await _handleGenericError(e, attempt);
        } else {
          throw PaymentException('Payment failed unexpectedly: $e');
        }
      }
    }

    throw lastException ?? PaymentException('Unknown payment processing error');
  }

  @override
  Future<PaymentModel> processPaymentWithToken({
    required String userId,
    required String orderId,
    required double amount,
    required String currency,
    required String paymentToken,
    bool isRecurring = false,
  }) async {
    try {
      final payment = await remoteDataSource.processPaymentWithToken(
        userId: userId,
        orderId: orderId,
        amount: amount,
        currency: currency,
        paymentToken: paymentToken,
        isRecurring: isRecurring,
      );

      await localDataSource.cachePayment(payment);
      return payment;
    } catch (e) {
      throw Exception('Failed to process payment with token: $e');
    }
  }

  @override
  Future<PaymentModel> getPaymentById(String paymentId) async {
    try {
      return await remoteDataSource.getPaymentById(paymentId);
    } catch (e) {
      final cachedPayments = await localDataSource.getCachedPayments();
      final cachedPayment = cachedPayments.where((p) => p.id == paymentId).firstOrNull;

      if (cachedPayment != null) {
        return cachedPayment;
      }

      throw Exception('Failed to get payment: $e');
    }
  }

  @override
  Future<List<PaymentModel>> getPaymentsByUserId(String userId) async {
    try {
      return await remoteDataSource.getPaymentsByUserId(userId);
    } catch (e) {
      final cachedPayments = await localDataSource.getCachedPayments();
      final userPayments = cachedPayments.where((p) => p.userId == userId).toList();

      if (userPayments.isNotEmpty) {
        return userPayments;
      }

      throw Exception('Failed to get user payments: $e');
    }
  }

  @override
  Future<List<PaymentModel>> getPaymentsByOrderId(String orderId) async {
    try {
      final cachedPayments = await localDataSource.getCachedPayments();
      return cachedPayments.where((p) => p.orderId == orderId).toList();
    } catch (e) {
      throw Exception('Failed to get order payments: $e');
    }
  }

  @override
  Future<PaymentModel> refundPayment({
    required String paymentId,
    required double amount,
    String? reason,
  }) async {
    try {
      final payment = await getPaymentById(paymentId);
      final refundedPayment = payment.copyWith(
        status: PaymentStatus.refunded,
        updatedAt: DateTime.now(),
      );

      await localDataSource.cachePayment(refundedPayment);
      return refundedPayment;
    } catch (e) {
      throw Exception('Failed to refund payment: $e');
    }
  }

  @override
  Future<PaymentModel> cancelPayment(String paymentId) async {
    try {
      final payment = await getPaymentById(paymentId);
      final cancelledPayment = payment.copyWith(
        status: PaymentStatus.cancelled,
        updatedAt: DateTime.now(),
      );

      await localDataSource.cachePayment(cancelledPayment);
      return cancelledPayment;
    } catch (e) {
      throw Exception('Failed to cancel payment: $e');
    }
  }

  @override
  Future<List<PaymentModel>> getPaymentsByStatus(PaymentStatus status) async {
    try {
      final cachedPayments = await localDataSource.getCachedPayments();
      return cachedPayments.where((p) => p.status == status).toList();
    } catch (e) {
      throw Exception('Failed to get payments by status: $e');
    }
  }

  @override
  Future<List<PaymentModel>> getPaymentsByDateRange(DateTime start, DateTime end) async {
    try {
      final cachedPayments = await localDataSource.getCachedPayments();
      return cachedPayments
          .where((p) => p.createdAt.isAfter(start) && p.createdAt.isBefore(end))
          .toList();
    } catch (e) {
      throw Exception('Failed to get payments by date range: $e');
    }
  }

  @override
  Future<CardModel> addCard({
    required String userId,
    required CardInputModel cardInput,
    bool makeDefault = false,
  }) async {
    try {
      final card = await remoteDataSource.addCard(
        userId: userId,
        cardInput: cardInput,
        makeDefault: makeDefault,
      );

      await localDataSource.cacheCard(card);
      return card;
    } catch (e) {
      throw Exception('Failed to add card: $e');
    }
  }

  @override
  Future<List<CardModel>> getUserCards(String userId) async {
    try {
      return await remoteDataSource.getUserCards(userId);
    } catch (e) {
      final cachedCards = await localDataSource.getCachedCards();
      final userCards = cachedCards.where((c) => c.userId == userId).toList();

      if (userCards.isNotEmpty) {
        return userCards;
      }

      throw Exception('Failed to get user cards: $e');
    }
  }

  @override
  Future<CardModel> getCardById(String cardId) async {
    try {
      final cachedCards = await localDataSource.getCachedCards();
      final card = cachedCards.where((c) => c.id == cardId).firstOrNull;

      if (card != null) {
        return card;
      }

      throw Exception('Card not found');
    } catch (e) {
      throw Exception('Failed to get card: $e');
    }
  }

  @override
  Future<CardModel> updateCard({
    required String cardId,
    bool? isDefault,
  }) async {
    try {
      final card = await getCardById(cardId);
      final updatedCard = card.copyWith(
        isDefault: isDefault ?? card.isDefault,
        updatedAt: DateTime.now(),
      );

      await localDataSource.cacheCard(updatedCard);
      return updatedCard;
    } catch (e) {
      throw Exception('Failed to update card: $e');
    }
  }

  @override
  Future<bool> deleteCard(String cardId) async {
    try {
      await localDataSource.removeCachedCard(cardId);
      return true;
    } catch (e) {
      throw Exception('Failed to delete card: $e');
    }
  }

  @override
  Future<CardModel> setDefaultCard({
    required String userId,
    required String cardId,
  }) async {
    try {
      await localDataSource.setDefaultCard(cardId);
      final cards = await getUserCards(userId);
      return cards.where((c) => c.id == cardId).first;
    } catch (e) {
      throw Exception('Failed to set default card: $e');
    }
  }

  @override
  Future<PaymentGatewayModel> getPaymentGateway(PaymentGatewayType type) async {
    try {
      final gateways = await getActivePaymentGateways();
      return gateways.where((g) => g.type == type).first;
    } catch (e) {
      throw Exception('Failed to get payment gateway: $e');
    }
  }

  @override
  Future<List<PaymentGatewayModel>> getActivePaymentGateways() async {
    try {
      return await localDataSource.getCachedPaymentGateways();
    } catch (e) {
      throw Exception('Failed to get active payment gateways: $e');
    }
  }

  @override
  Future<PaymentGatewayModel> getDefaultPaymentGateway() async {
    try {
      final gateways = await getActivePaymentGateways();
      return gateways.where((g) => g.isDefault).first;
    } catch (e) {
      throw Exception('Failed to get default payment gateway: $e');
    }
  }

  @override
  Future<FraudDetectionModel> analyzePaymentRisk({
    required String userId,
    required String paymentId,
    required double amount,
    required String currency,
    String? ipAddress,
    String? deviceId,
    String? userAgent,
  }) async {
    try {
      return await remoteDataSource.analyzePaymentRisk(
        userId: userId,
        paymentId: paymentId,
        amount: amount,
        currency: currency,
        ipAddress: ipAddress,
        deviceId: deviceId,
        userAgent: userAgent,
      );
    } catch (e) {
      throw Exception('Failed to analyze payment risk: $e');
    }
  }

  @override
  Future<TransactionVelocityData> getTransactionVelocity(String userId) async {
    try {
      return TransactionVelocityData(
        userId: userId,
        ipAddress: '127.0.0.1',
        deviceId: 'device-123',
        transactionsLastHour: 0,
        transactionsLast24Hours: 0,
        transactionsLast7Days: 0,
        totalAmountLastHour: 0.0,
        totalAmountLast24Hours: 0.0,
        totalAmountLast7Days: 0.0,
        lastTransactionTime: DateTime.now(),
        failedAttemptsLastHour: 0,
      );
    } catch (e) {
      throw Exception('Failed to get transaction velocity: $e');
    }
  }

  @override
  Future<FraudDetectionModel> getFraudDetectionByPaymentId(String paymentId) async {
    try {
      return FraudDetectionModel(
        id: 'fraud-123',
        paymentId: paymentId,
        userId: 'user-123',
        riskLevel: FraudRiskLevel.low,
        riskScore: 0.1,
        failedChecks: [],
        riskFactors: [],
        ipAddress: '127.0.0.1',
        deviceId: 'device-123',
        userAgent: 'Flutter App',
        analysisData: {},
        requiresManualReview: false,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to get fraud detection: $e');
    }
  }

  @override
  Future<bool> validate3DSecure({
    required String paymentId,
    required String transactionId,
    required Map<String, dynamic> authData,
  }) async {
    try {
      return true;
    } catch (e) {
      throw Exception('Failed to validate 3D Secure: $e');
    }
  }

  @override
  Future<PaymentModel> processRecurringPayment({
    required String userId,
    required String orderId,
    required double amount,
    required String currency,
    required String subscriptionId,
  }) async {
    try {
      return PaymentModel(
        id: 'payment-123',
        userId: userId,
        orderId: orderId,
        amount: amount,
        currency: currency,
        status: PaymentStatus.succeeded,
        riskLevel: FraudRiskLevel.low,
        isRecurring: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        processedAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to process recurring payment: $e');
    }
  }

  @override
  Future<PaymentModel> cancelRecurringPayment({
    required String subscriptionId,
    String? reason,
  }) async {
    try {
      return PaymentModel(
        id: 'payment-123',
        userId: 'user-123',
        orderId: 'order-123',
        amount: 0.0,
        currency: 'USD',
        status: PaymentStatus.cancelled,
        riskLevel: FraudRiskLevel.low,
        isRecurring: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to cancel recurring payment: $e');
    }
  }

  @override
  Stream<PaymentModel> getPaymentStatusUpdates(String paymentId) {
    return Stream.periodic(
      const Duration(seconds: 5),
      (_) => PaymentModel(
        id: paymentId,
        userId: 'user-123',
        orderId: 'order-123',
        amount: 100.0,
        currency: 'USD',
        status: PaymentStatus.succeeded,
        riskLevel: FraudRiskLevel.low,
        isRecurring: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        processedAt: DateTime.now(),
      ),
    );
  }

  @override
  Stream<List<PaymentModel>> getUserPaymentUpdates(String userId) {
    return Stream.periodic(
      const Duration(seconds: 10),
      (_) => [
        PaymentModel(
          id: 'payment-123',
          userId: userId,
          orderId: 'order-123',
          amount: 100.0,
          currency: 'USD',
          status: PaymentStatus.succeeded,
          riskLevel: FraudRiskLevel.low,
          isRecurring: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          processedAt: DateTime.now(),
        ),
      ],
    );
  }

  // Helper methods for error handling and retry logic

  Future<void> _handleNetworkError(NetworkException error, int attempt, String orderId) async {
    final delay = _calculateExponentialBackoff(attempt);

    // Log the error for monitoring
    await _logPaymentError(
      orderId: orderId,
      errorType: 'network_error',
      errorMessage: error.message,
      attempt: attempt,
    );

    // Wait before retry
    await Future.delayed(delay);
  }

  Future<void> _handleServerError(ServerException error, int attempt) async {
    final delay = _calculateExponentialBackoff(attempt);

    // Log the error for monitoring
    await _logPaymentError(
      orderId: 'unknown',
      errorType: 'server_error',
      errorMessage: error.message,
      attempt: attempt,
    );

    // Wait before retry
    await Future.delayed(delay);
  }

  Future<void> _handleGenericError(dynamic error, int attempt) async {
    final delay = _calculateExponentialBackoff(attempt);

    // Log the error for monitoring
    await _logPaymentError(
      orderId: 'unknown',
      errorType: 'generic_error',
      errorMessage: error.toString(),
      attempt: attempt,
    );

    // Wait before retry
    await Future.delayed(delay);
  }

  Duration _calculateExponentialBackoff(int attempt) {
    const baseDelay = Duration(seconds: 1);
    const maxDelay = Duration(seconds: 30);
    final multiplier = attempt - 1;

    if (multiplier <= 0) {
      return baseDelay;
    }

    final delay = Duration(
      milliseconds: (baseDelay.inMilliseconds * (1 << multiplier)).clamp(
        baseDelay.inMilliseconds,
        maxDelay.inMilliseconds,
      ),
    );

    // Add jitter to prevent thundering herd
    final jitter = Duration(milliseconds: (delay.inMilliseconds * 0.1).round());
    return delay + jitter;
  }

  Future<void> _logPaymentError({
    required String orderId,
    required String errorType,
    required String errorMessage,
    required int attempt,
  }) async {
    try {
      // Log error to monitoring system
      final errorLog = {
        'order_id': orderId,
        'error_type': errorType,
        'error_message': errorMessage,
        'attempt': attempt,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // This would typically be sent to a logging service
      print('Payment Error Log: $errorLog');
    } catch (e) {
      // Don't let logging errors affect payment processing
      print('Failed to log payment error: $e');
    }
  }

  Future<void> _handlePaymentFailure({
    required String userId,
    required String orderId,
    required double amount,
    required String currency,
    required PaymentFailureReason failureReason,
    required String errorMessage,
    String? originalPaymentMethod,
  }) async {
    try {
      // Attempt automated recovery
      final recoveryResult = await recoveryService.attemptRecovery(
        paymentId: orderId,
        userId: userId,
        amount: amount,
        currency: currency,
        failureReason: failureReason,
        originalPaymentMethod: originalPaymentMethod ?? 'credit_card',
      );

      // Log recovery attempt
      await _logRecoveryAttempt(
        orderId: orderId,
        failureReason: failureReason,
        recoveryResult: recoveryResult,
      );

      // If recovery is scheduled, set up monitoring
      if (recoveryResult.recoveryStatus == RecoveryStatus.retryScheduled) {
        await _scheduleRecoveryMonitoring(orderId, recoveryResult.nextRetryTime!);
      }
    } catch (e) {
      print('Failed to handle payment failure: $e');
    }
  }

  Future<void> _logRecoveryAttempt({
    required String orderId,
    required PaymentFailureReason failureReason,
    required RecoveryResult recoveryResult,
  }) async {
    try {
      final recoveryLog = {
        'order_id': orderId,
        'failure_reason': failureReason.name,
        'recovery_status': recoveryResult.recoveryStatus.name,
        'recovery_message': recoveryResult.message,
        'timestamp': DateTime.now().toIso8601String(),
      };

      print('Payment Recovery Log: $recoveryLog');
    } catch (e) {
      print('Failed to log recovery attempt: $e');
    }
  }

  Future<void> _scheduleRecoveryMonitoring(String orderId, DateTime retryTime) async {
    try {
      // This would typically integrate with a background task system
      print('Scheduled recovery monitoring for order $orderId at $retryTime');
    } catch (e) {
      print('Failed to schedule recovery monitoring: $e');
    }
  }

  // Additional error handling methods

  Future<bool> _isRecoverableError(Exception error) async {
    // Determine if an error is recoverable
    if (error is NetworkException) {
      return true; // Network errors are usually recoverable
    }

    if (error is ServerException) {
      return error.isRetryable;
    }

    return false;
  }

  Future<PaymentFailureReason> _determineFailureReason(Exception error) async {
    if (error is NetworkException) {
      return PaymentFailureReason.networkError;
    }

    if (error is ServerException) {
      switch (error.statusCode) {
        case 400:
          return PaymentFailureReason.invalidCard;
        case 402:
          return PaymentFailureReason.insufficientFunds;
        case 429:
          return PaymentFailureReason.rateLimited;
        case 500:
        case 502:
        case 503:
        case 504:
          return PaymentFailureReason.gatewayError;
        default:
          return PaymentFailureReason.unknown;
      }
    }

    return PaymentFailureReason.unknown;
  }

  Future<Map<String, dynamic>> _getErrorContext(Exception error) async {
    return {
      'error_type': error.runtimeType.toString(),
      'error_message': error.toString(),
      'timestamp': DateTime.now().toIso8601String(),
      'user_agent': 'Flutter App',
    };
  }
}