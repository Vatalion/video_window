import 'dart:async';
import 'dart:math';
import 'package:collection/collection.dart';

/// Automated payment recovery service with intelligent retry strategies
/// and craft-commerce specific recovery patterns
class PaymentRecoveryService {
  final Map<String, RecoveryAttempt> _activeRecoveries = {};
  final Map<String, PaymentRecoveryConfig> _recoveryConfigs = {};
  final Map<String, RecoveryMetrics> _recoveryMetrics = {};
  final Random _random = Random();

  PaymentRecoveryService() {
    _initializeRecoveryConfigs();
  }

  /// Attempt to recover a failed payment
  Future<RecoveryResult> attemptRecovery({
    required String paymentId,
    required String userId,
    required double amount,
    required String currency,
    required PaymentFailureReason failureReason,
    required String originalPaymentMethod,
    Map<String, dynamic>? transactionData,
    Map<String, dynamic>? userData,
  }) async {
    try {
      // Check if recovery is already in progress
      if (_activeRecoveries.containsKey(paymentId)) {
        return RecoveryResult(
          success: false,
          recoveryStatus: RecoveryStatus.alreadyInProgress,
          message: 'Recovery already in progress for this payment',
          nextRetryTime: _activeRecoveries[paymentId]?.nextAttemptTime,
        );
      }

      // Get recovery configuration for this failure type
      final config = _getRecoveryConfig(failureReason);

      // Create recovery attempt record
      final recoveryAttempt = RecoveryAttempt(
        paymentId: paymentId,
        userId: userId,
        originalAmount: amount,
        currency: currency,
        failureReason: failureReason,
        originalPaymentMethod: originalPaymentMethod,
        config: config,
        transactionData: transactionData ?? {},
        userData: userData ?? {},
      );

      _activeRecoveries[paymentId] = recoveryAttempt;

      // Attempt recovery
      final result = await _executeRecovery(recoveryAttempt);

      // Update metrics
      await _updateRecoveryMetrics(paymentId, result);

      // Clean up if recovery is complete
      if (result.recoveryStatus != RecoveryStatus.retryScheduled) {
        _activeRecoveries.remove(paymentId);
      }

      return result;
    } catch (e) {
      _activeRecoveries.remove(paymentId);
      return RecoveryResult(
        success: false,
        recoveryStatus: RecoveryStatus.error,
        message: 'Recovery attempt failed: $e',
      );
    }
  }

  /// Execute the actual recovery strategy
  Future<RecoveryResult> _executeRecovery(RecoveryAttempt attempt) async {
    switch (attempt.failureReason) {
      case PaymentFailureReason.networkError:
        return await _handleNetworkErrorRecovery(attempt);
      case PaymentFailureReason.insufficientFunds:
        return await _handleInsufficientFundsRecovery(attempt);
      case PaymentFailureReason.cardDeclined:
        return await _handleCardDeclinedRecovery(attempt);
      case PaymentFailureReason.invalidCard:
        return await _handleInvalidCardRecovery(attempt);
      case PaymentFailureReason.fraudDetection:
        return await _handleFraudDetectionRecovery(attempt);
      case PaymentFailureReason.gatewayError:
        return await _handleGatewayErrorRecovery(attempt);
      case PaymentFailureReason.timeout:
        return await _handleTimeoutRecovery(attempt);
      case PaymentFailureReason.rateLimited:
        return await _handleRateLimitedRecovery(attempt);
      default:
        return await _handleGenericErrorRecovery(attempt);
    }
  }

  /// Handle network error recovery
  Future<RecoveryResult> _handleNetworkErrorRecovery(RecoveryAttempt attempt) async {
    if (attempt.attemptCount >= attempt.config.maxAttempts) {
      return RecoveryResult(
        success: false,
        recoveryStatus: RecoveryStatus.maxAttemptsReached,
        message: 'Maximum recovery attempts reached for network error',
        suggestedAction: SuggestedAction.contactSupport,
      );
    }

    // Implement exponential backoff with jitter
    final delay = _calculateExponentialBackoff(attempt.attemptCount);

    // Check if it's a temporary network issue
    final isTemporary = await _isTemporaryNetworkIssue();

    if (isTemporary) {
      // Schedule retry
      final nextAttemptTime = DateTime.now().add(delay);
      attempt.scheduleNextAttempt(nextAttemptTime);

      return RecoveryResult(
        success: false,
        recoveryStatus: RecoveryStatus.retryScheduled,
        message: 'Network error detected - retry scheduled',
        nextRetryTime: nextAttemptTime,
        attemptNumber: attempt.attemptCount + 1,
        suggestedAction: SuggestedAction.waitForRetry,
      );
    } else {
      // Try alternative payment method
      return await _tryAlternativePaymentMethod(attempt);
    }
  }

  /// Handle insufficient funds recovery
  Future<RecoveryResult> _handleInsufficientFundsRecovery(RecoveryAttempt attempt) async {
    // For insufficient funds, we can suggest:
    // 1. Split payment (if amount is large)
    // 2. Alternative payment method
    // 3. Payment plan

    if (attempt.originalAmount > 100) {
      // Suggest split payment
      return RecoveryResult(
        success: false,
        recoveryStatus: RecoveryStatus.requiresUserAction,
        message: 'Insufficient funds - consider split payment or alternative method',
        suggestedAction: SuggestedAction.splitPayment,
        availableAlternatives: await _getSplitPaymentOptions(attempt.originalAmount),
      );
    }

    // Try alternative payment methods
    return await _tryAlternativePaymentMethod(attempt);
  }

  /// Handle card declined recovery
  Future<RecoveryResult> _handleCardDeclinedRecovery(RecoveryAttempt attempt) async {
    if (attempt.attemptCount >= 2) {
      // After 2 declines, suggest alternative payment method
      return await _tryAlternativePaymentMethod(attempt);
    }

    // Check if it's a temporary decline vs permanent
    final isTemporaryDecline = await _isTemporaryDecline(attempt.originalPaymentMethod);

    if (isTemporaryDecline) {
      final delay = Duration(seconds: 30 * attempt.attemptCount);
      final nextAttemptTime = DateTime.now().add(delay);
      attempt.scheduleNextAttempt(nextAttemptTime);

      return RecoveryResult(
        success: false,
        recoveryStatus: RecoveryStatus.retryScheduled,
        message: 'Card temporarily declined - retry scheduled',
        nextRetryTime: nextAttemptTime,
        attemptNumber: attempt.attemptCount + 1,
        suggestedAction: SuggestedAction.waitForRetry,
      );
    } else {
      return await _tryAlternativePaymentMethod(attempt);
    }
  }

  /// Handle invalid card recovery
  Future<RecoveryResult> _handleInvalidCardRecovery(RecoveryAttempt attempt) async {
    // Invalid card cannot be recovered with same method
    return await _tryAlternativePaymentMethod(attempt);
  }

  /// Handle fraud detection recovery
  Future<RecoveryResult> _handleFraudDetectionRecovery(RecoveryAttempt attempt) async {
    // Fraud detection requires manual review
    return RecoveryResult(
      success: false,
      recoveryStatus: RecoveryStatus.requiresManualReview,
      message: 'Payment flagged for fraud - manual review required',
      suggestedAction: SuggestedAction.contactSupport,
      reviewId: await _createFraudReviewTicket(attempt),
    );
  }

  /// Handle gateway error recovery
  Future<RecoveryResult> _handleGatewayErrorRecovery(RecoveryAttempt attempt) async {
    if (attempt.attemptCount >= attempt.config.maxAttempts) {
      // Try alternative gateway
      return await _tryAlternativeGateway(attempt);
    }

    // Retry with different gateway
    final delay = _calculateExponentialBackoff(attempt.attemptCount);
    final nextAttemptTime = DateTime.now().add(delay);
    attempt.scheduleNextAttempt(nextAttemptTime);

    return RecoveryResult(
      success: false,
      recoveryStatus: RecoveryStatus.retryScheduled,
      message: 'Gateway error detected - retry with alternative gateway scheduled',
      nextRetryTime: nextAttemptTime,
      attemptNumber: attempt.attemptCount + 1,
      suggestedAction: SuggestedAction.waitForRetry,
    );
  }

  /// Handle timeout recovery
  Future<RecoveryResult> _handleTimeoutRecovery(RecoveryAttempt attempt) async {
    if (attempt.attemptCount >= attempt.config.maxAttempts) {
      return RecoveryResult(
        success: false,
        recoveryStatus: RecoveryStatus.maxAttemptsReached,
        message: 'Maximum recovery attempts reached for timeout',
        suggestedAction: SuggestedAction.contactSupport,
      );
    }

    // Retry with increased timeout
    final delay = Duration(seconds: 15 * attempt.attemptCount);
    final nextAttemptTime = DateTime.now().add(delay);
    attempt.scheduleNextAttempt(nextAttemptTime);

    return RecoveryResult(
      success: false,
      recoveryStatus: RecoveryStatus.retryScheduled,
      message: 'Timeout detected - retry with extended timeout scheduled',
      nextRetryTime: nextAttemptTime,
      attemptNumber: attempt.attemptCount + 1,
      suggestedAction: SuggestedAction.waitForRetry,
    );
  }

  /// Handle rate limited recovery
  Future<RecoveryResult> _handleRateLimitedRecovery(RecoveryAttempt attempt) async {
    // Rate limited - wait for reset time
    final resetTime = await _getRateLimitResetTime();
    final nextAttemptTime = DateTime.now().add(resetTime);
    attempt.scheduleNextAttempt(nextAttemptTime);

    return RecoveryResult(
      success: false,
      recoveryStatus: RecoveryStatus.retryScheduled,
      message: 'Rate limit reached - retry scheduled after reset',
      nextRetryTime: nextAttemptTime,
      attemptNumber: attempt.attemptCount + 1,
      suggestedAction: SuggestedAction.waitForRetry,
    );
  }

  /// Handle generic error recovery
  Future<RecoveryResult> _handleGenericErrorRecovery(RecoveryAttempt attempt) async {
    if (attempt.attemptCount >= attempt.config.maxAttempts) {
      return RecoveryResult(
        success: false,
        recoveryStatus: RecoveryStatus.maxAttemptsReached,
        message: 'Maximum recovery attempts reached',
        suggestedAction: SuggestedAction.contactSupport,
      );
    }

    final delay = _calculateExponentialBackoff(attempt.attemptCount);
    final nextAttemptTime = DateTime.now().add(delay);
    attempt.scheduleNextAttempt(nextAttemptTime);

    return RecoveryResult(
      success: false,
      recoveryStatus: RecoveryStatus.retryScheduled,
      message: 'Payment failed - retry scheduled',
      nextRetryTime: nextAttemptTime,
      attemptNumber: attempt.attemptCount + 1,
      suggestedAction: SuggestedAction.waitForRetry,
    );
  }

  /// Try alternative payment method
  Future<RecoveryResult> _tryAlternativePaymentMethod(RecoveryAttempt attempt) async {
    final alternatives = await _getAvailablePaymentMethods(attempt.userId);

    if (alternatives.isEmpty) {
      return RecoveryResult(
        success: false,
        recoveryStatus: RecoveryStatus.noAlternativesAvailable,
        message: 'No alternative payment methods available',
        suggestedAction: SuggestedAction.addPaymentMethod,
      );
    }

    return RecoveryResult(
      success: false,
      recoveryStatus: RecoveryStatus.requiresUserAction,
      message: 'Please try an alternative payment method',
      suggestedAction: SuggestedAction.tryAlternativeMethod,
      availableAlternatives: alternatives,
    );
  }

  /// Try alternative payment gateway
  Future<RecoveryResult> _tryAlternativeGateway(RecoveryAttempt attempt) async {
    final alternativeGateways = await _getAlternativeGateways();

    if (alternativeGateways.isEmpty) {
      return RecoveryResult(
        success: false,
        recoveryStatus: RecoveryStatus.noAlternativesAvailable,
        message: 'No alternative gateways available',
        suggestedAction: SuggestedAction.contactSupport,
      );
    }

    return RecoveryResult(
      success: false,
      recoveryStatus: RecoveryStatus.requiresUserAction,
      message: 'Please try with alternative payment gateway',
      suggestedAction: SuggestedAction.tryAlternativeGateway,
      availableAlternatives: alternativeGateways,
    );
  }

  // Helper methods for recovery logic

  Duration _calculateExponentialBackoff(int attemptCount) {
    final baseDelay = const Duration(seconds: 5);
    final maxDelay = const Duration(minutes: 30);
    final multiplier = min(6, attemptCount); // Cap at 6 to avoid excessive delays
    final jitter = _random.nextDouble() * 0.3; // Add jitter to avoid thundering herd

    final delay = Duration(
      milliseconds: (baseDelay.inMilliseconds * pow(2, multiplier) * (1 + jitter)).round(),
    );

    return delay > maxDelay ? maxDelay : delay;
  }

  PaymentRecoveryConfig _getRecoveryConfig(PaymentFailureReason reason) {
    return _recoveryConfigs[reason.name] ?? _recoveryConfigs['default']!;
  }

  Future<bool> _isTemporaryNetworkIssue() async {
    // Simulate network check
    return _random.nextDouble() > 0.3; // 70% chance it's temporary
  }

  Future<bool> _isTemporaryDecline(String paymentMethod) async {
    // Simulate decline analysis
    return _random.nextDouble() > 0.6; // 40% chance it's temporary
  }

  Future<String> _createFraudReviewTicket(RecoveryAttempt attempt) async {
    // Simulate creating fraud review ticket
    return 'fraud_review_${attempt.paymentId}_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<Duration> _getRateLimitResetTime() async {
    // Simulate rate limit reset time
    return Duration(seconds: 30 + _random.nextInt(60));
  }

  Future<List<PaymentMethodOption>> _getAvailablePaymentMethods(String userId) async {
    // Simulate getting available payment methods
    return [
      PaymentMethodOption(
        type: 'credit_card',
        displayName: 'Credit/Debit Card',
        lastFour: '**** 4242',
        isDefault: true,
      ),
      PaymentMethodOption(
        type: 'paypal',
        displayName: 'PayPal',
        email: 'user@example.com',
      ),
    ];
  }

  Future<List<SplitPaymentOption>> _getSplitPaymentOptions(double amount) async {
    // Simulate split payment options
    return [
      SplitPaymentOption(
        amount: amount / 2,
        method: 'credit_card',
        description: 'Split payment into 2 equal parts',
      ),
      SplitPaymentOption(
        amount: amount / 3,
        method: 'credit_card',
        description: 'Split payment into 3 equal parts',
      ),
    ];
  }

  Future<List<GatewayOption>> _getAlternativeGateways() async {
    // Simulate alternative gateways
    return [
      GatewayOption(
        name: 'Stripe',
        reliability: 0.99,
        fees: 0.029,
      ),
      GatewayOption(
        name: 'PayPal',
        reliability: 0.98,
        fees: 0.029,
      ),
      GatewayOption(
        name: 'Braintree',
        reliability: 0.97,
        fees: 0.029,
      ),
    ];
  }

  Future<void> _updateRecoveryMetrics(String paymentId, RecoveryResult result) async {
    if (!_recoveryMetrics.containsKey(paymentId)) {
      _recoveryMetrics[paymentId] = RecoveryMetrics(paymentId: paymentId);
    }

    final metrics = _recoveryMetrics[paymentId]!;
    metrics.recordAttempt(result);
  }

  void _initializeRecoveryConfigs() {
    _recoveryConfigs.addAll({
      'networkError': PaymentRecoveryConfig(
        maxAttempts: 5,
        baseDelay: const Duration(seconds: 5),
        maxDelay: const Duration(minutes: 30),
        enableExponentialBackoff: true,
        enableAlternativeMethods: true,
      ),
      'insufficientFunds': PaymentRecoveryConfig(
        maxAttempts: 2,
        baseDelay: const Duration(seconds: 10),
        maxDelay: const Duration(minutes: 5),
        enableExponentialBackoff: false,
        enableAlternativeMethods: true,
        enableSplitPayment: true,
      ),
      'cardDeclined': PaymentRecoveryConfig(
        maxAttempts: 3,
        baseDelay: const Duration(seconds: 30),
        maxDelay: const Duration(minutes: 10),
        enableExponentialBackoff: true,
        enableAlternativeMethods: true,
      ),
      'invalidCard': PaymentRecoveryConfig(
        maxAttempts: 1,
        baseDelay: const Duration(seconds: 0),
        maxDelay: const Duration(seconds: 0),
        enableExponentialBackoff: false,
        enableAlternativeMethods: true,
      ),
      'fraudDetection': PaymentRecoveryConfig(
        maxAttempts: 1,
        baseDelay: const Duration(seconds: 0),
        maxDelay: const Duration(seconds: 0),
        enableExponentialBackoff: false,
        enableAlternativeMethods: false,
        requireManualReview: true,
      ),
      'gatewayError': PaymentRecoveryConfig(
        maxAttempts: 4,
        baseDelay: const Duration(seconds: 10),
        maxDelay: const Duration(minutes: 15),
        enableExponentialBackoff: true,
        enableAlternativeGateways: true,
      ),
      'timeout': PaymentRecoveryConfig(
        maxAttempts: 3,
        baseDelay: const Duration(seconds: 15),
        maxDelay: const Duration(minutes: 10),
        enableExponentialBackoff: true,
        enableExtendedTimeouts: true,
      ),
      'rateLimited': PaymentRecoveryConfig(
        maxAttempts: 3,
        baseDelay: const Duration(seconds: 30),
        maxDelay: const Duration(minutes: 5),
        enableExponentialBackoff: false,
        respectRateLimits: true,
      ),
      'default': PaymentRecoveryConfig(
        maxAttempts: 3,
        baseDelay: const Duration(seconds: 10),
        maxDelay: const Duration(minutes: 5),
        enableExponentialBackoff: true,
      ),
    });
  }

  /// Get recovery metrics for a payment
  RecoveryMetrics? getRecoveryMetrics(String paymentId) {
    return _recoveryMetrics[paymentId];
  }

  /// Get all active recovery attempts
  List<RecoveryAttempt> getActiveRecoveries() {
    return _activeRecoveries.values.toList();
  }

  /// Cancel an active recovery
  bool cancelRecovery(String paymentId) {
    return _activeRecoveries.remove(paymentId) != null;
  }

  /// Get recovery statistics
  Map<String, dynamic> getRecoveryStatistics() {
    final totalAttempts = _recoveryMetrics.values.fold(0, (sum, metrics) => sum + metrics.totalAttempts);
    final successfulRecoveries = _recoveryMetrics.values.where((m) => m.successfulRecovery).length;
    final failureRate = totalAttempts > 0 ? (totalAttempts - successfulRecoveries) / totalAttempts : 0.0;

    return {
      'total_attempts': totalAttempts,
      'successful_recoveries': successfulRecoveries,
      'failure_rate': failureRate,
      'active_recoveries': _activeRecoveries.length,
    };
  }
}

// Data models for payment recovery

enum PaymentFailureReason {
  networkError,
  insufficientFunds,
  cardDeclined,
  invalidCard,
  fraudDetection,
  gatewayError,
  timeout,
  rateLimited,
  unknown,
}

enum RecoveryStatus {
  success,
  failed,
  retryScheduled,
  requiresUserAction,
  requiresManualReview,
  maxAttemptsReached,
  alreadyInProgress,
  noAlternativesAvailable,
  error,
}

enum SuggestedAction {
  waitForRetry,
  tryAlternativeMethod,
  tryAlternativeGateway,
  splitPayment,
  addPaymentMethod,
  contactSupport,
}

class RecoveryResult {
  final bool success;
  final RecoveryStatus recoveryStatus;
  final String message;
  final DateTime? nextRetryTime;
  final int? attemptNumber;
  final SuggestedAction? suggestedAction;
  final List<PaymentMethodOption>? availableAlternatives;
  final String? reviewId;

  RecoveryResult({
    required this.success,
    required this.recoveryStatus,
    required this.message,
    this.nextRetryTime,
    this.attemptNumber,
    this.suggestedAction,
    this.availableAlternatives,
    this.reviewId,
  });
}

class RecoveryAttempt {
  final String paymentId;
  final String userId;
  final double originalAmount;
  final String currency;
  final PaymentFailureReason failureReason;
  final String originalPaymentMethod;
  final PaymentRecoveryConfig config;
  final Map<String, dynamic> transactionData;
  final Map<String, dynamic> userData;

  int attemptCount = 0;
  DateTime? nextAttemptTime;
  DateTime lastAttemptTime = DateTime.now();
  List<RecoveryStatus> attemptHistory = [];

  RecoveryAttempt({
    required this.paymentId,
    required this.userId,
    required this.originalAmount,
    required this.currency,
    required this.failureReason,
    required this.originalPaymentMethod,
    required this.config,
    required this.transactionData,
    required this.userData,
  });

  void scheduleNextAttempt(DateTime nextTime) {
    attemptCount++;
    nextAttemptTime = nextTime;
    lastAttemptTime = DateTime.now();
  }

  void recordAttempt(RecoveryStatus status) {
    attemptHistory.add(status);
    attemptCount++;
  }
}

class PaymentRecoveryConfig {
  final int maxAttempts;
  final Duration baseDelay;
  final Duration maxDelay;
  final bool enableExponentialBackoff;
  final bool enableAlternativeMethods;
  final bool enableAlternativeGateways;
  final bool enableSplitPayment;
  final bool enableExtendedTimeouts;
  final bool respectRateLimits;
  final bool requireManualReview;

  PaymentRecoveryConfig({
    required this.maxAttempts,
    required this.baseDelay,
    required this.maxDelay,
    this.enableExponentialBackoff = false,
    this.enableAlternativeMethods = false,
    this.enableAlternativeGateways = false,
    this.enableSplitPayment = false,
    this.enableExtendedTimeouts = false,
    this.respectRateLimits = false,
    this.requireManualReview = false,
  });
}

class PaymentMethodOption {
  final String type;
  final String displayName;
  final String? lastFour;
  final String? email;
  final bool isDefault;

  PaymentMethodOption({
    required this.type,
    required this.displayName,
    this.lastFour,
    this.email,
    this.isDefault = false,
  });
}

class SplitPaymentOption {
  final double amount;
  final String method;
  final String description;

  SplitPaymentOption({
    required this.amount,
    required this.method,
    required this.description,
  });
}

class GatewayOption {
  final String name;
  final double reliability;
  final double fees;

  GatewayOption({
    required this.name,
    required this.reliability,
    required this.fees,
  });
}

class RecoveryMetrics {
  final String paymentId;
  int totalAttempts = 0;
  int successfulRecovery = 0;
  DateTime firstAttempt = DateTime.now();
  DateTime? lastAttempt;
  final List<Duration> recoveryTimes = [];

  RecoveryMetrics({required this.paymentId});

  void recordAttempt(RecoveryResult result) {
    totalAttempts++;
    lastAttempt = DateTime.now();

    if (result.success) {
      successfulRecovery++;
    }

    if (result.nextRetryTime != null) {
      final recoveryTime = result.nextRetryTime!.difference(DateTime.now());
      recoveryTimes.add(recoveryTime);
    }
  }

  double get successRate => totalAttempts > 0 ? successfulRecovery / totalAttempts : 0.0;
  Duration get averageRecoveryTime {
    if (recoveryTimes.isEmpty) return Duration.zero;
    final totalMs = recoveryTimes.fold(0, (sum, duration) => sum + duration.inMilliseconds);
    return Duration(milliseconds: totalMs ~/ recoveryTimes.length);
  }
}