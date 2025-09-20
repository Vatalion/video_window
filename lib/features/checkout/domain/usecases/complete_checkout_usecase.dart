import 'package:dartz/dartz.dart';
import '../models/checkout_session_model.dart';
import '../models/payment_model.dart';
import '../models/order_summary_model.dart';
import '../models/checkout_security_model.dart';
import '../../data/repositories/checkout_repository.dart';
import '../../../core/error/failure.dart';

class CompleteCheckoutUseCase {
  final CheckoutRepository repository;

  CompleteCheckoutUseCase(this.repository);

  Future<Either<Failure, String>> call({
    required String sessionId,
    required String paymentMethodId,
    required SecurityContextModel securityContext,
  }) async {
    // Get the session
    final sessionResult = await repository.getSession(sessionId);

    if (sessionResult.isLeft()) {
      return Left(sessionResult.fold((l) => l, (r) => null)!);
    }

    final session = sessionResult.getOrElse(() => throw Exception());

    // Validate session state
    if (session.isExpired) {
      return Left(ValidationFailure(
        message: 'Checkout session has expired',
      ));
    }

    if (session.isAbandoned) {
      return Left(ValidationFailure(
        message: 'Checkout session has been abandoned',
      ));
    }

    // Check if all required steps are completed
    final requiredSteps = CheckoutStepDefinition.getStandardSteps()
        .where((step) => step.isRequired)
        .map((step) => step.type)
        .toList();

    for (final stepType in requiredSteps) {
      if (!session.completedSteps.contains(stepType)) {
        return Left(ValidationFailure(
          message: 'Required checkout step ${stepType.name} is not completed',
        ));
      }
    }

    // Get order summary
    final orderSummaryResult = await repository.getOrderSummary(sessionId);

    if (orderSummaryResult.isLeft()) {
      return Left(orderSummaryResult.fold((l) => l, (r) => null)!);
    }

    final orderSummary = orderSummaryResult.getOrElse(() => throw Exception());

    // Validate order summary
    final orderValidation = orderSummary.validate();
    if (orderValidation.any((r) => !r.isValid &&
        r.severity == ValidationSeverity.critical)) {
      return Left(ValidationFailure(
        message: 'Order validation failed',
        details: orderValidation.where((r) => !r.isValid).toList(),
      ));
    }

    // Validate payment method
    final paymentValidationResult = await repository.validatePaymentMethod(
      paymentMethodId: paymentMethodId,
      securityContext: securityContext,
    );

    if (paymentValidationResult.isLeft()) {
      return Left(paymentValidationResult.fold((l) => l, (r) => null)!);
    }

    final isPaymentMethodValid = paymentValidationResult.getOrElse(() => false);

    if (!isPaymentMethodValid) {
      return Left(ValidationFailure(
        message: 'Invalid payment method',
      ));
    }

    // Enhanced security validation for final checkout
    final finalSecurityResult = await repository.validateSecurityContext(
      sessionId: sessionId,
      context: securityContext.copyWith(
        securityLevel: SecurityLevel.maximum,
      ),
    );

    if (finalSecurityResult.isLeft()) {
      return Left(finalSecurityResult.fold((l) => l, (r) => null)!);
    }

    final finalSecurityValidation = finalSecurityResult.getOrElse(() =>
      SecurityValidationResult(
        isValid: false,
        violations: [],
        recommendedLevel: SecurityLevel.standard,
        recommendations: {},
        validatedAt: DateTime.now(),
      )
    );

    if (!finalSecurityValidation.isValid) {
      return Left(SecurityFailure(
        message: 'Security validation failed for checkout completion',
        details: finalSecurityValidation.violations,
      ));
    }

    // Process payment
    final paymentResult = await repository.processPayment(
      sessionId: sessionId,
      paymentMethodId: paymentMethodId,
      amount: orderSummary.total,
      securityContext: securityContext,
    );

    if (paymentResult.isLeft()) {
      return Left(paymentResult.fold((l) => l, (r) => null)!);
    }

    final paymentTransaction = paymentResult.getOrElse(() => throw Exception());

    if (paymentTransaction.status != PaymentStatus.succeeded) {
      return Left(ValidationFailure(
        message: 'Payment failed',
        details: {
          'status': paymentTransaction.status.name,
          'errorCode': paymentTransaction.errorCode,
          'errorMessage': paymentTransaction.errorMessage,
        },
      ));
    }

    // Complete checkout
    final completionResult = await repository.completeCheckout(
      sessionId: sessionId,
      paymentMethodId: paymentMethodId,
      securityContext: securityContext,
    );

    if (completionResult.isLeft()) {
      return Left(completionResult.fold((l) => l, (r) => null)!);
    }

    final orderId = completionResult.getOrElse(() => throw Exception());

    // Record successful completion
    await repository.recordSecurityEvent(
      SecurityEventModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sessionId: sessionId,
        type: SecurityEventType.sessionEnd,
        description: 'Checkout completed successfully',
        timestamp: DateTime.now(),
        securityLevel: SecurityLevel.maximum,
        details: {
          'orderId': orderId,
          'paymentTransactionId': paymentTransaction.id,
          'totalAmount': orderSummary.total,
          'completedAt': DateTime.now().toIso8601String(),
        },
      ),
    );

    return Right(orderId);
  }
}