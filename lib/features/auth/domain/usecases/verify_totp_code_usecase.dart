import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/two_factor_repository.dart';

class VerifyTotpCodeUseCase {
  final TwoFactorRepository repository;

  VerifyTotpCodeUseCase(this.repository);

  Future<Either<Failure, bool>> call({
    required String userId,
    required String sessionId,
    required String code,
  }) async {
    return await repository.verifyTotpCode(userId, sessionId, code);
  }
}
