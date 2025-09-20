import 'package:dartz/dartz.dart';
import '../models/checkout_session_model.dart';
import '../models/checkout_security_model.dart';
import '../../data/repositories/checkout_repository.dart';
import '../../../core/error/failure.dart';

class SaveCheckoutSessionUseCase {
  final CheckoutRepository repository;

  SaveCheckoutSessionUseCase(this.repository);

  Future<Either<Failure, bool>> call({
    required String sessionId,
    required Map<CheckoutStepType, Map<String, dynamic>> stepData,
    required SecurityContextModel securityContext,
  }) async {
    // First validate security context
    final securityResult = await repository.validateSecurityContext(
      sessionId: sessionId,
      context: securityContext,
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
        message: 'Security validation failed',
        details: securityValidation.violations,
      ));
    }

    // Save session progress
    return await repository.saveSessionProgress(
      sessionId: sessionId,
      stepData: stepData,
    );
  }
}