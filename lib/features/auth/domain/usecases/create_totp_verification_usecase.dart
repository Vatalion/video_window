import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/two_factor_repository.dart';
import '../models/two_factor_verification_model.dart';

class CreateTotpVerificationUseCase {
  final TwoFactorRepository repository;

  CreateTotpVerificationUseCase(this.repository);

  Future<Either<Failure, TwoFactorVerification>> call({
    required String userId,
    required String sessionId,
  }) async {
    return await repository.createTotpVerification(userId, sessionId);
  }
}
