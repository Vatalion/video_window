import 'package:dartz/dartz.dart';
import '../models/checkout_session_model.dart';
import '../models/checkout_security_model.dart';
import '../../data/repositories/checkout_repository.dart';
import '../../../core/error/failure.dart';

class ResumeCheckoutSessionUseCase {
  final CheckoutRepository repository;

  ResumeCheckoutSessionUseCase(this.repository);

  Future<Either<Failure, CheckoutSessionModel>> call({
    required String sessionId,
    required String userId,
    required SecurityContextModel securityContext,
  }) async {
    // Get the session
    final sessionResult = await repository.getSession(sessionId);

    if (sessionResult.isLeft()) {
      return Left(sessionResult.fold((l) => l, (r) => null)!);
    }

    final session = sessionResult.getOrElse(() => throw Exception());

    // Validate session ownership and security
    if (session.userId != userId) {
      return Left(PermissionFailure(
        message: 'You do not have permission to access this checkout session',
      ));
    }

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

    // Update security context
    final updatedSecurityContext = securityContext.copyWith(
      lastActivity: DateTime.now(),
    );

    // Validate security context
    final securityResult = await repository.validateSecurityContext(
      sessionId: sessionId,
      context: updatedSecurityContext,
    );

    if (securityResult.isLeft()) {
      return Left(securityResult.fold((l) => l, (r) => null)!);
    }

    final securityValidation = securityResult.getOrElse(() =>
      SecurityValidationResult(
        isValid: false,
        violations: [],
        recommendedLevel: SecurityLevel.standard,
        recommendations: {},
        validatedAt: DateTime.now(),
      )
    );

    if (!securityValidation.isValid) {
      return Left(SecurityFailure(
        message: 'Security validation failed for session resumption',
        details: securityValidation.violations,
      ));
    }

    // Resume session
    final resumeResult = await repository.resumeSession(sessionId);

    if (resumeResult.isLeft()) {
      return Left(resumeResult.fold((l) => l, (r) => null)!);
    }

    // Track session resumption
    await repository.recordSecurityEvent(
      SecurityEventModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sessionId: sessionId,
        type: SecurityEventType.recovery,
        description: 'Checkout session resumed',
        timestamp: DateTime.now(),
        securityLevel: securityValidation.recommendedLevel,
        details: {
          'userId': userId,
          'resumedAt': DateTime.now().toIso8601String(),
        },
      ),
    );

    return resumeResult;
  }
}