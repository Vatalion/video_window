import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/two_factor_repository.dart';

class VerifySmsCodeUseCase {
  final TwoFactorRepository repository;

  VerifySmsCodeUseCase(this.repository);

  Future<Either<Failure, bool>> call({
    required String userId,
    required String sessionId,
    required String code,
  }) async {
    return await repository.verifySmsCode(userId, sessionId, code);
  }
}
