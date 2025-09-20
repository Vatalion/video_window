import 'package:dartz/dartz.dart';
import '../models/checkout_session_model.dart';
import '../models/checkout_validation_model.dart';
import '../models/checkout_security_model.dart';
import '../../data/repositories/checkout_repository.dart';

class ValidateCheckoutStepUseCase {
  final CheckoutRepository repository;

  ValidateCheckoutStepUseCase(this.repository);

  Future<Either<Failure, CheckoutValidationResult>> call({
    required String sessionId,
    required CheckoutStepType stepType,
    required Map<String, dynamic> stepData,
    required SecurityContextModel securityContext,
  }) async {
    return await repository.validateCheckoutStep(
      sessionId: sessionId,
      stepType: stepType,
      stepData: stepData,
      securityContext: securityContext,
    );
  }
}

class Failure {
  final String message;
  final String code;
  final dynamic details;

  Failure({
    required this.message,
    required this.code,
    this.details,
  });
}