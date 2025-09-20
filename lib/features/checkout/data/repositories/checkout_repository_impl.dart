import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../domain/repositories/checkout_repository.dart';
import '../../domain/models/checkout_session_model.dart';
import '../../domain/models/checkout_validation_model.dart';
import '../../domain/models/order_summary_model.dart';
import '../../domain/models/payment_model.dart';
import '../../domain/models/address_model.dart';
import '../../domain/models/checkout_security_model.dart';
import '../../domain/usecases/validate_checkout_step_usecase.dart';
import '../datasources/checkout_remote_data_source.dart';
import '../datasources/checkout_local_data_source.dart';
import '../services/checkout_security_service.dart';
import '../services/checkout_encryption_service.dart';
import '../services/checkout_audit_service.dart';
import '../../../core/error/failure.dart';

class CheckoutRepositoryImpl implements CheckoutRepository {
  final CheckoutRemoteDataSource remoteDataSource;
  final CheckoutLocalDataSource localDataSource;
  final CheckoutSecurityService securityService;
  final CheckoutEncryptionService encryptionService;
  final CheckoutAuditService auditService;

  CheckoutRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.securityService,
    required this.encryptionService,
    required this.auditService,
  });

  // Session Management
  @override
  Future<Either<Failure, CheckoutSessionModel>> createSession({
    required String userId,
    bool isGuest = false,
  }) async {
    try {
      // Create security context
      final deviceFingerprint = await localDataSource.getDeviceFingerprint();
      final securityContext = securityService.createSecurityContext(
        sessionId: const Uuid().v4(),
        userId: userId,
      );

      // Create session remotely
      final remoteResult = await remoteDataSource.createSession(
        userId: userId,
        isGuest: isGuest,
      );

      if (remoteResult.isLeft()) {
        return Left(remoteResult.fold((l) => l, (r) => null)!);
      }

      final sessionData = remoteResult.getOrElse(() => throw Exception());
      final session = CheckoutSessionModel.fromJson(sessionData);

      // Save security context locally
      await localDataSource.saveSecurityContext(securityContext);

      // Save session locally
      await localDataSource.saveSession(session);

      // Generate and save session token
      final sessionToken = encryptionService.generateSecureToken();
      await localDataSource.saveSessionToken(session.sessionId, sessionToken);

      // Log session start
      auditService.logSessionStart(userId: userId, isGuest: isGuest);

      return Right(session);
    } catch (e) {
      return Left(ServerFailure(
        message: 'Failed to create checkout session',
        details: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, CheckoutSessionModel>> getSession(String sessionId) async {
    try {
      // Try to get from local cache first
      final localSession = await localDataSource.getSession(sessionId);
      if (localSession != null && localSession.isValid) {
        return Right(localSession);
      }

      // If not in cache or invalid, get from remote
      final remoteResult = await remoteDataSource.getSession(sessionId);

      if (remoteResult.isLeft()) {
        return Left(remoteResult.fold((l) => l, (r) => null)!);
      }

      final sessionData = remoteResult.getOrElse(() => throw Exception());
      final session = CheckoutSessionModel.fromJson(sessionData);

      // Cache the session locally
      await localDataSource.saveSession(session);

      return Right(session);
    } catch (e) {
      return Left(ServerFailure(
        message: 'Failed to retrieve checkout session',
        details: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, CheckoutSessionModel>> updateSession({
    required String sessionId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      // Update remotely
      final remoteResult = await remoteDataSource.updateSession(
        sessionId: sessionId,
        updates: updates,
      );

      if (remoteResult.isLeft()) {
        return Left(remoteResult.fold((l) => l, (r) => null)!);
      }

      // Get updated session
      final sessionResult = await getSession(sessionId);

      if (sessionResult.isLeft()) {
        return Left(sessionResult.fold((l) => l, (r) => null)!);
      }

      final session = sessionResult.getOrElse(() => throw Exception());

      // Update security context
      final securityContext = await localDataSource.getSecurityContext(sessionId);
      if (securityContext != null) {
        final updatedContext = securityContext.copyWith(
          lastActivity: DateTime.now(),
        );
        await localDataSource.saveSecurityContext(updatedContext);
      }

      return Right(session);
    } catch (e) {
      return Left(ServerFailure(
        message: 'Failed to update checkout session',
        details: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, bool>> saveSessionProgress({
    required String sessionId,
    required Map<CheckoutStepType, Map<String, dynamic>> stepData,
  }) async {
    try {
      // Convert step data to serializable format
      final serializableStepData = stepData.map(
        (key, value) => MapEntry(key.name, value),
      );

      // Save progress remotely
      final remoteResult = await remoteDataSource.saveSessionProgress(
        sessionId: sessionId,
        stepData: serializableStepData,
      );

      if (remoteResult.isLeft()) {
        return Left(remoteResult.fold((l) => l, (r) => null)!);
      }

      // Update local session
      final sessionResult = await getSession(sessionId);

      if (sessionResult.isRight()) {
        final session = sessionResult.getOrElse(() => throw Exception());
        final updatedSession = session.copyWith(
          stepData: stepData,
          updatedAt: DateTime.now(),
        );
        await localDataSource.saveSession(updatedSession);
      }

      // Log data modification
      auditService.logDataModification(
        userId: 'unknown', // Should be passed from caller
        dataType: 'checkoutProgress',
        action: 'save',
        oldValues: {},
        newValues: serializableStepData,
      );

      return Right(true);
    } catch (e) {
      return Left(ServerFailure(
        message: 'Failed to save session progress',
        details: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, CheckoutSessionModel>> resumeSession(String sessionId) async {
    try {
      // Resume session remotely
      final remoteResult = await remoteDataSource.resumeSession(sessionId);

      if (remoteResult.isLeft()) {
        return Left(remoteResult.fold((l) => l, (r) => null)!);
      }

      // Get updated session
      final sessionResult = await getSession(sessionId);

      if (sessionResult.isLeft()) {
        return Left(sessionResult.fold((l) => l, (r) => null)!);
      }

      final session = sessionResult.getOrElse(() => throw Exception());

      // Update security context
      final securityContext = await localDataSource.getSecurityContext(sessionId);
      if (securityContext != null) {
        final updatedContext = securityContext.copyWith(
          lastActivity: DateTime.now(),
        );
        await localDataSource.saveSecurityContext(updatedContext);
      }

      // Log session recovery
      auditService.logSessionRecovery(
        userId: session.userId,
        recoveryMethod: 'manual',
        successful: true,
      );

      return Right(session);
    } catch (e) {
      return Left(ServerFailure(
        message: 'Failed to resume checkout session',
        details: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, bool>> abandonSession(String sessionId) async {
    try {
      // Get session before abandoning
      final sessionResult = await getSession(sessionId);

      String? userId;
      if (sessionResult.isRight()) {
        final session = sessionResult.getOrElse(() => throw Exception());
        userId = session.userId;
      }

      // Abandon remotely
      final remoteResult = await remoteDataSource.abandonSession(sessionId);

      if (remoteResult.isLeft()) {
        return Left(remoteResult.fold((l) => l, (r) => null)!);
      }

      // Update local session
      if (sessionResult.isRight()) {
        final session = sessionResult.getOrElse(() => throw Exception());
        final updatedSession = session.copyWith(
          isAbandoned: true,
          abandonedAt: DateTime.now(),
        );
        await localDataSource.saveSession(updatedSession);
      }

      // Log abandonment
      if (userId != null) {
        auditService.logSessionAbandonment(
          userId: userId,
          reason: 'user_initiated',
        );
      }

      return Right(true);
    } catch (e) {
      return Left(ServerFailure(
        message: 'Failed to abandon checkout session',
        details: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, List<CheckoutSessionModel>>> getSavedSessions(String userId) async {
    try {
      final sessions = await localDataSource.getUserSessions(userId);
      return Right(sessions);
    } catch (e) {
      return Left(CacheFailure(
        message: 'Failed to retrieve saved sessions',
        details: e.toString(),
      ));
    }
  }

  // Step Validation
  @override
  Future<Either<Failure, CheckoutValidationResult>> validateCheckoutStep({
    required String sessionId,
    required CheckoutStepType stepType,
    required Map<String, dynamic> stepData,
    required SecurityContextModel securityContext,
  }) async {
    try {
      // Validate step remotely
      final remoteResult = await remoteDataSource.validateCheckoutStep(
        sessionId: sessionId,
        stepType: stepType.name,
        stepData: stepData,
        securityContext: securityContext.toJson(),
      );

      if (remoteResult.isLeft()) {
        return Left(remoteResult.fold((l) => l, (r) => null)!);
      }

      final validationResultData = remoteResult.getOrElse(() => throw Exception());
      final validationResult = CheckoutValidationResult.fromJson(validationResultData);

      // Log validation result
      if (validationResult.isValid) {
        auditService.logValidationSuccess(
          userId: securityContext.userId,
          stepType: stepType,
          validationResult: validationResult,
        );
      } else {
        auditService.logValidationFailure(
          userId: securityContext.userId,
          stepType: stepType,
          failedRules: validationResult.errors,
        );
      }

      return Right(validationResult);
    } catch (e) {
      return Left(ServerFailure(
        message: 'Failed to validate checkout step',
        details: e.toString(),
      ));
    }
  }

  // Order Summary
  @override
  Future<Either<Failure, OrderSummaryModel>> calculateOrderSummary({
    required OrderCalculationRequest request,
    required String sessionId,
  }) async {
    try {
      // Calculate remotely
      final remoteResult = await remoteDataSource.calculateOrderSummary(
        request: request.toJson(),
        sessionId: sessionId,
      );

      if (remoteResult.isLeft()) {
        return Left(remoteResult.fold((l) => l, (r) => null)!);
      }

      final summaryData = remoteResult.getOrElse(() => throw Exception());
      final orderSummary = OrderSummaryModel.fromJson(summaryData);

      // Cache locally
      await localDataSource.cacheOrderSummary(sessionId, summaryData);

      return Right(orderSummary);
    } catch (e) {
      return Left(ServerFailure(
        message: 'Failed to calculate order summary',
        details: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, OrderSummaryModel>> getOrderSummary(String sessionId) async {
    try {
      // Try cache first
      final cachedSummary = await localDataSource.getCachedOrderSummary(sessionId);
      if (cachedSummary != null) {
        return Right(OrderSummaryModel.fromJson(cachedSummary));
      }

      // If not in cache, recalculate
      // This would require getting the current order items from cart service
      // For now, return an error
      return Left(CacheFailure(
        message: 'Order summary not found in cache',
      ));
    } catch (e) {
      return Left(ServerFailure(
        message: 'Failed to retrieve order summary',
        details: e.toString(),
      ));
    }
  }

  // Payment Processing
  @override
  Future<Either<Failure, PaymentTransactionModel>> processPayment({
    required String sessionId,
    required String paymentMethodId,
    required double amount,
    required SecurityContextModel securityContext,
  }) async {
    try {
      // Validate security context first
      final riskAssessment = await securityService.assessRisk(
        context: securityContext,
        session: await getSession(sessionId).then((result) =>
          result.getOrElse(() => throw Exception())),
        orderValue: amount,
      );

      if (!riskAssessment.isValid) {
        return Left(SecurityFailure(
          message: 'Security validation failed for payment processing',
          details: riskAssessment.violations,
        ));
      }

      // Log payment attempt
      auditService.logPaymentAttempt(
        userId: securityContext.userId,
        amount: amount,
        paymentMethodId: paymentMethodId,
        paymentMethodType: 'unknown', // Should be determined from payment method
      );

      // Process payment remotely
      final remoteResult = await remoteDataSource.processPayment(
        sessionId: sessionId,
        paymentMethodId: paymentMethodId,
        amount: amount,
        securityContext: securityContext.toJson(),
      );

      if (remoteResult.isLeft()) {
        final error = remoteResult.fold((l) => l, (r) => null)!;
        auditService.logPaymentFailure(
          userId: securityContext.userId,
          amount: amount,
          paymentMethodId: paymentMethodId,
          errorCode: error.code,
          errorMessage: error.message,
        );
        return Left(error);
      }

      final transactionData = remoteResult.getOrElse(() => throw Exception());
      final transaction = PaymentTransactionModel.fromJson(transactionData);

      // Log payment success
      if (transaction.status == PaymentStatus.succeeded) {
        auditService.logPaymentSuccess(
          userId: securityContext.userId,
          amount: amount,
          transactionId: transaction.transactionId,
          paymentMethodId: paymentMethodId,
        );
      }

      return Right(transaction);
    } catch (e) {
      return Left(ServerFailure(
        message: 'Failed to process payment',
        details: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, bool>> validatePaymentMethod({
    required String paymentMethodId,
    required SecurityContextModel securityContext,
  }) async {
    try {
      final remoteResult = await remoteDataSource.validatePaymentMethod(
        paymentMethodId: paymentMethodId,
        securityContext: securityContext.toJson(),
      );

      return remoteResult;
    } catch (e) {
      return Left(ServerFailure(
        message: 'Failed to validate payment method',
        details: e.toString(),
      ));
    }
  }

  // Address Management
  @override
  Future<Either<Failure, AddressModel>> saveAddress({
    required AddressModel address,
    required SecurityContextModel securityContext,
  }) async {
    try {
      // Validate address
      final validationRules = address.validate();
      if (validationRules.any((r) => !r.isValid && r.severity == ValidationSeverity.error)) {
        return Left(ValidationFailure(
          message: 'Address validation failed',
          details: validationRules.where((r) => !r.isValid).toList(),
        ));
      }

      // Save address remotely
      final remoteResult = await remoteDataSource.saveAddress(
        address: address.toJson(),
        securityContext: securityContext.toJson(),
      );

      if (remoteResult.isLeft()) {
        return Left(remoteResult.fold((l) => l, (r) => null)!);
      }

      final addressData = remoteResult.getOrElse(() => throw Exception());
      final savedAddress = AddressModel.fromJson(addressData);

      // Log data modification
      auditService.logDataModification(
        userId: securityContext.userId,
        dataType: 'address',
        action: 'save',
        oldValues: {},
        newValues: addressData,
      );

      return Right(savedAddress);
    } catch (e) {
      return Left(ServerFailure(
        message: 'Failed to save address',
        details: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, List<AddressModel>>> getUserAddresses(String userId) async {
    try {
      final remoteResult = await remoteDataSource.getUserAddresses(userId);

      if (remoteResult.isLeft()) {
        return Left(remoteResult.fold((l) => l, (r) => null)!);
      }

      final addressesData = remoteResult.getOrElse(() => throw Exception());
      final addresses = addressesData
          .map((data) => AddressModel.fromJson(data))
          .toList();

      return Right(addresses);
    } catch (e) {
      return Left(ServerFailure(
        message: 'Failed to retrieve user addresses',
        details: e.toString(),
      ));
    }
  }

  // Security Management
  @override
  Future<Either<Failure, SecurityContextModel>> getSecurityContext(String sessionId) async {
    try {
      final context = await localDataSource.getSecurityContext(sessionId);
      if (context != null) {
        return Right(context);
      } else {
        return Left(NotFoundFailure(
          message: 'Security context not found',
        ));
      }
    } catch (e) {
      return Left(CacheFailure(
        message: 'Failed to retrieve security context',
        details: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, SecurityValidationResult>> validateSecurityContext({
    required String sessionId,
    required SecurityContextModel context,
  }) async {
    try {
      final remoteResult = await remoteDataSource.validateSecurityContext(
        sessionId: sessionId,
        context: context.toJson(),
      );

      if (remoteResult.isLeft()) {
        return Left(remoteResult.fold((l) => l, (r) => null)!);
      }

      final validationResultData = remoteResult.getOrElse(() => throw Exception());
      final validationResult = SecurityValidationResult.fromJson(validationResultData);

      return Right(validationResult);
    } catch (e) {
      return Left(ServerFailure(
        message: 'Failed to validate security context',
        details: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, bool>> recordSecurityEvent({
    required SecurityEventModel event,
  }) async {
    try {
      final remoteResult = await remoteDataSource.recordSecurityEvent(
        event: event.toJson(),
      );

      if (remoteResult.isLeft()) {
        return Left(remoteResult.fold((l) => l, (r) => null)!);
      }

      // Log security event to audit service
      auditService.logSecurityEvent(
        securityEventType: event.type,
        description: event.description,
        userId: 'unknown', // Should be extracted from event
        details: event.details,
      );

      return Right(true);
    } catch (e) {
      return Left(ServerFailure(
        message: 'Failed to record security event',
        details: e.toString(),
      ));
    }
  }

  // Order Completion
  @override
  Future<Either<Failure, String>> completeCheckout({
    required String sessionId,
    required String paymentMethodId,
    required SecurityContextModel securityContext,
  }) async {
    try {
      // Complete checkout remotely
      final remoteResult = await remoteDataSource.completeCheckout(
        sessionId: sessionId,
        paymentMethodId: paymentMethodId,
        securityContext: securityContext.toJson(),
      );

      if (remoteResult.isLeft()) {
        return Left(remoteResult.fold((l) => l, (r) => null)!);
      }

      final orderId = remoteResult.getOrElse(() => throw Exception());

      // Log session end
      auditService.logSessionEnd(
        userId: securityContext.userId,
        orderId: orderId,
      );

      // Clean up local data
      await localDataSource.removeSession(sessionId);

      return Right(orderId);
    } catch (e) {
      return Left(ServerFailure(
        message: 'Failed to complete checkout',
        details: e.toString(),
      ));
    }
  }

  // Guest Checkout
  @override
  Future<Either<Failure, String>> createGuestAccount({
    required String email,
    required String firstName,
    required String lastName,
    required String sessionId,
  }) async {
    try {
      final remoteResult = await remoteDataSource.createGuestAccount(
        email: email,
        firstName: firstName,
        lastName: lastName,
        sessionId: sessionId,
      );

      return remoteResult;
    } catch (e) {
      return Left(ServerFailure(
        message: 'Failed to create guest account',
        details: e.toString(),
      ));
    }
  }

  // Analytics and Tracking
  @override
  Future<Either<Failure, bool>> trackCheckoutAbandonment({
    required String sessionId,
    required String reason,
  }) async {
    try {
      final remoteResult = await remoteDataSource.trackAbandonment(
        sessionId: sessionId,
        reason: reason,
      );

      return remoteResult;
    } catch (e) {
      return Left(ServerFailure(
        message: 'Failed to track checkout abandonment',
        details: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, bool>> trackStepCompletion({
    required String sessionId,
    required CheckoutStepType stepType,
    required Duration timeSpent,
  }) async {
    try {
      final remoteResult = await remoteDataSource.trackStepCompletion(
        sessionId: sessionId,
        stepType: stepType.name,
        timeSpentSeconds: timeSpent.inSeconds,
      );

      return remoteResult;
    } catch (e) {
      return Left(ServerFailure(
        message: 'Failed to track step completion',
        details: e.toString(),
      ));
    }
  }

  // Session Cleanup
  @override
  Future<Either<Failure, bool>> cleanupExpiredSessions() async {
    try {
      await localDataSource.cleanupExpiredSessions();
      return Right(true);
    } catch (e) {
      return Left(CacheFailure(
        message: 'Failed to cleanup expired sessions',
        details: e.toString(),
      ));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteSession(String sessionId) async {
    try {
      await localDataSource.removeSession(sessionId);
      return Right(true);
    } catch (e) {
      return Left(CacheFailure(
        message: 'Failed to delete session',
        details: e.toString(),
      ));
    }
  }
}